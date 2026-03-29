# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Enrollment management API routes.
API-Routen für die Einschreibungsverwaltung.

This module provides REST API endpoints for managing course enrollments
including adding, removing, and listing enrollments.
"""

from datetime import datetime
from typing import Optional
from uuid import uuid4
from fastapi import APIRouter, HTTPException, Query, status

from api.models.enrollment import (
    Enrollment,
    EnrollmentCreate,
    EnrollmentBulkCreate,
    EnrollmentRemove,
    EnrollmentBulkRemove,
    EnrollmentList,
    EnrollmentStatus,
    EnrollmentRole,
    ErrorResponse,
)
from api.models.course import Course, CourseStatus, LMSPlatform
from api.utils.ilias_client import ILIASClient
from api.utils.moodle_client import MoodleClient
from api.utils.keycloak_client import KeycloakClient

router = APIRouter(prefix="/api/v1/enrollments", tags=["enrollments"])

# Import shared databases from courses.py to ensure consistency
from api.routes.courses import _courses_db, _enrollments_db


def _get_courses_db() -> dict[str, Course]:
    """
    Get reference to courses database.
    Referenz auf die Kursdatenbank abrufen.
    """
    return _courses_db


async def _get_lms_client(lms: LMSPlatform):
    """
    Get appropriate LMS client based on platform.
    Passenden LMS-Client basierend auf der Plattform abrufen.
    """
    if lms == LMSPlatform.ILIAS:
        return ILIASClient()
    return MoodleClient()


@router.post(
    "/{course_id}/add",
    response_model=Enrollment,
    status_code=status.HTTP_201_CREATED,
    responses={
        201: {
            "description": "Enrollment created successfully / Einschreibung erfolgreich erstellt"
        },
        400: {
            "model": ErrorResponse,
            "description": "Invalid request data / Ungültige Anfragedaten",
        },
        404: {
            "model": ErrorResponse,
            "description": "Course not found / Kurs nicht gefunden",
        },
        409: {
            "model": ErrorResponse,
            "description": "User already enrolled / Benutzer bereits eingeschrieben",
        },
    },
    summary="Add single enrollment / Einzelne Einschreibung hinzufügen",
    description="Enroll a single user in a course. / Schreibt einen einzelnen Benutzer in einen Kurs ein.",
)
async def add_enrollment(course_id: str, enrollment: EnrollmentCreate) -> Enrollment:
    """
    Add a single user enrollment to a course.
    Fügt eine einzelne Benutzereinschreibung zu einem Kurs hinzu.

    Args:
        course_id: Course identifier / Kurskennung
        enrollment: Enrollment data / Einschreibungsdaten

    Returns:
        Created enrollment object / Erstelltes Einschreibungsobjekt

    Raises:
        404: Course not found / Kurs nicht gefunden
        409: User already enrolled / Benutzer bereits eingeschrieben
    """
    courses_db = _get_courses_db()

    if course_id not in courses_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Course {course_id} not found / Kurs {course_id} nicht gefunden",
        )

    course = courses_db[course_id]

    # Check if course is active
    if course.status != CourseStatus.ACTIVE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Course {course_id} is not active / Kurs {course_id} ist nicht aktiv",
        )

    # Check for existing enrollment
    for existing in _enrollments_db.values():
        if (
            existing.course_id == course_id
            and existing.user_id == enrollment.user_id
            and existing.status == EnrollmentStatus.ACTIVE
        ):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"User {enrollment.user_id} already enrolled in course {course_id} / Benutzer {enrollment.user_id} bereits in Kurs {course_id} eingeschrieben",
            )

    enrollment_id = f"enr_{uuid4().hex[:12]}"
    now = datetime.utcnow()

    # Enroll in LMS
    async with await _get_lms_client(course.lms) as client:
        await client.enroll_user(
            course_id=course.lms_course_id or course_id,
            user_id=enrollment.user_id,
            role=enrollment.role.value,
        )

    # Update Keycloak group
    async with KeycloakClient() as kc:
        await kc.add_user_to_course_group(
            course_id=course_id,
            user_id=enrollment.user_id,
            role=enrollment.role.value,
        )

    new_enrollment = Enrollment(
        enrollment_id=enrollment_id,
        course_id=course_id,
        user_id=enrollment.user_id,
        role=enrollment.role,
        status=EnrollmentStatus.ACTIVE,
        created_at=now,
    )

    _enrollments_db[enrollment_id] = new_enrollment
    return new_enrollment


@router.post(
    "/{course_id}/bulk-add",
    response_model=list[Enrollment],
    status_code=status.HTTP_201_CREATED,
    responses={
        201: {
            "description": "Enrollments created successfully / Einschreibungen erfolgreich erstellt"
        },
        400: {
            "model": ErrorResponse,
            "description": "Invalid request data / Ungültige Anfragedaten",
        },
        404: {
            "model": ErrorResponse,
            "description": "Course not found / Kurs nicht gefunden",
        },
    },
    summary="Bulk add enrollments / Masseneinschreibungen hinzufügen",
    description="Enroll multiple users in a course at once. / Schreibt mehrere Benutzer gleichzeitig in einen Kurs ein.",
)
async def bulk_add_enrollments(
    course_id: str, request: EnrollmentBulkCreate
) -> list[Enrollment]:
    """
    Add multiple user enrollments to a course.
    Fügt mehrere Benutzereinschreibungen zu einem Kurs hinzu.

    Args:
        course_id: Course identifier / Kurskennung
        request: Bulk enrollment data / Masseneinschreibungsdaten

    Returns:
        List of created enrollment objects / Liste der erstellten Einschreibungsobjekte

    Raises:
        404: Course not found / Kurs nicht gefunden
    """
    courses_db = _get_courses_db()

    if course_id not in courses_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Course {course_id} not found / Kurs {course_id} nicht gefunden",
        )

    created_enrollments = []
    for enrollment_data in request.enrollments:
        try:
            enrollment = await add_enrollment(course_id, enrollment_data)
            created_enrollments.append(enrollment)
        except HTTPException as e:
            if e.status_code != 409:  # Skip already enrolled, continue with others
                raise

    return created_enrollments


@router.delete(
    "/{course_id}/remove",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        204: {
            "description": "Enrollment removed successfully / Einschreibung erfolgreich entfernt"
        },
        404: {
            "model": ErrorResponse,
            "description": "Course or enrollment not found / Kurs oder Einschreibung nicht gefunden",
        },
    },
    summary="Remove single enrollment / Einzelne Einschreibung entfernen",
    description="Remove a user enrollment from a course. / Entfernt eine Benutzereinschreibung aus einem Kurs.",
)
async def remove_enrollment(course_id: str, removal: EnrollmentRemove) -> None:
    """
    Remove a single user enrollment from a course.
    Entfernt eine einzelne Benutzereinschreibung aus einem Kurs.

    Args:
        course_id: Course identifier / Kurskennung
        removal: Removal data / Entfernungsdaten

    Returns:
        None (204 No Content)

    Raises:
        404: Course or enrollment not found / Kurs oder Einschreibung nicht gefunden
    """
    courses_db = _get_courses_db()

    if course_id not in courses_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Course {course_id} not found / Kurs {course_id} nicht gefunden",
        )

    course = courses_db[course_id]

    # Find the enrollment
    enrollment_to_remove = None
    for enrollment_id, enrollment in _enrollments_db.items():
        if (
            enrollment.course_id == course_id
            and enrollment.user_id == removal.user_id
            and enrollment.status == EnrollmentStatus.ACTIVE
        ):
            enrollment_to_remove = (enrollment_id, enrollment)
            break

    if not enrollment_to_remove:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Active enrollment for user {removal.user_id} in course {course_id} not found / Aktive Einschreibung für Benutzer {removal.user_id} in Kurs {course_id} nicht gefunden",
        )

    enrollment_id, enrollment = enrollment_to_remove

    # Unenroll from LMS
    async with await _get_lms_client(course.lms) as client:
        await client.unenroll_user(
            course_id=course.lms_course_id or course_id,
            user_id=removal.user_id,
        )

    # Update Keycloak group
    async with KeycloakClient() as kc:
        await kc.remove_user_from_course_group(
            course_id=course_id,
            user_id=removal.user_id,
            role=enrollment.role.value,
        )

    # Update enrollment status
    enrollment.status = EnrollmentStatus.WITHDRAWN
    enrollment.updated_at = datetime.utcnow()
    _enrollments_db[enrollment_id] = enrollment


@router.post(
    "/{course_id}/bulk-remove",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        204: {
            "description": "Enrollments removed successfully / Einschreibungen erfolgreich entfernt"
        },
        404: {
            "model": ErrorResponse,
            "description": "Course not found / Kurs nicht gefunden",
        },
    },
    summary="Bulk remove enrollments / Masseneinschreibungen entfernen",
    description="Remove multiple user enrollments from a course. / Entfernt mehrere Benutzereinschreibungen aus einem Kurs.",
)
async def bulk_remove_enrollments(
    course_id: str, request: EnrollmentBulkRemove
) -> None:
    """
    Remove multiple user enrollments from a course.
    Entfernt mehrere Benutzereinschreibungen aus einem Kurs.

    Args:
        course_id: Course identifier / Kurskennung
        request: Bulk removal data / Massenentfernungsdaten

    Returns:
        None (204 No Content)

    Raises:
        404: Course not found / Kurs nicht gefunden
    """
    courses_db = _get_courses_db()

    if course_id not in courses_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Course {course_id} not found / Kurs {course_id} nicht gefunden",
        )

    for user_id in request.user_ids:
        try:
            await remove_enrollment(
                course_id, EnrollmentRemove(user_id=user_id, reason=request.reason)
            )
        except HTTPException as e:
            if e.status_code != 404:  # Skip not found, continue with others
                raise


@router.get(
    "/{course_id}",
    response_model=EnrollmentList,
    responses={
        200: {"description": "List of enrollments / Liste der Einschreibungen"},
        404: {
            "model": ErrorResponse,
            "description": "Course not found / Kurs nicht gefunden",
        },
    },
    summary="List course enrollments / Kurseinschreibungen auflisten",
    description="Get all enrollments for a specific course. / Ruft alle Einschreibungen für einen bestimmten Kurs ab.",
)
async def list_course_enrollments(
    course_id: str,
    status_filter: Optional[EnrollmentStatus] = Query(
        None,
        alias="status",
        description="Filter by enrollment status / Nach Einschreibungsstatus filtern",
    ),
    role_filter: Optional[EnrollmentRole] = Query(
        None, alias="role", description="Filter by role / Nach Rolle filtern"
    ),
    page: int = Query(1, ge=1, description="Page number / Seitennummer"),
    page_size: int = Query(
        20, ge=1, le=100, description="Items per page / Einträge pro Seite"
    ),
) -> EnrollmentList:
    """
    List all enrollments for a course with optional filtering.
    Listet alle Einschreibungen für einen Kurs mit optionaler Filterung auf.

    Args:
        course_id: Course identifier / Kurskennung
        status_filter: Filter by status / Nach Status filtern
        role_filter: Filter by role / Nach Rolle filtern
        page: Page number / Seitennummer
        page_size: Items per page / Einträge pro Seite

    Returns:
        Paginated list of enrollments / Paginierte Liste der Einschreibungen

    Raises:
        404: Course not found / Kurs nicht gefunden
    """
    courses_db = _get_courses_db()

    if course_id not in courses_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Course {course_id} not found / Kurs {course_id} nicht gefunden",
        )

    # Filter enrollments
    filtered = [e for e in _enrollments_db.values() if e.course_id == course_id]

    if status_filter:
        filtered = [e for e in filtered if e.status == status_filter]
    if role_filter:
        filtered = [e for e in filtered if e.role == role_filter]

    total = len(filtered)
    start = (page - 1) * page_size
    end = start + page_size

    return EnrollmentList(
        enrollments=filtered[start:end],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get(
    "/{course_id}/{enrollment_id}",
    response_model=Enrollment,
    responses={
        200: {"description": "Enrollment details / Einschreibungsdetails"},
        404: {
            "model": ErrorResponse,
            "description": "Enrollment not found / Einschreibung nicht gefunden",
        },
    },
    summary="Get enrollment details / Einschreibungsdetails abrufen",
    description="Get details of a specific enrollment. / Ruft Details einer bestimmten Einschreibung ab.",
)
async def get_enrollment(course_id: str, enrollment_id: str) -> Enrollment:
    """
    Get details of a specific enrollment.
    Ruft Details einer bestimmten Einschreibung ab.

    Args:
        course_id: Course identifier / Kurskennung
        enrollment_id: Enrollment identifier / Einschreibungskennung

    Returns:
        Enrollment object / Einschreibungsobjekt

    Raises:
        404: Enrollment not found / Einschreibung nicht gefunden
    """
    if enrollment_id not in _enrollments_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Enrollment {enrollment_id} not found / Einschreibung {enrollment_id} nicht gefunden",
        )

    enrollment = _enrollments_db[enrollment_id]

    if enrollment.course_id != course_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Enrollment {enrollment_id} not found in course {course_id} / Einschreibung {enrollment_id} nicht in Kurs {course_id} gefunden",
        )

    return enrollment

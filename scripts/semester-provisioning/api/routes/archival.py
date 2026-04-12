# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Archival management API routes.
API-Routen für die Archivierungsverwaltung.

This module provides REST API endpoints for archiving and restoring courses
including single and bulk operations.
"""

from datetime import datetime, timezone
from typing import Optional
from uuid import uuid4
from fastapi import APIRouter, HTTPException, Query, status

from api.models.archival import (
    ArchiveRequest,
    BulkArchiveRequest,
    ArchiveResult,
    BulkArchiveResult,
    RestoreRequest,
    RestoreResult,
    ArchiveInfo,
    ArchiveList,
    ArchiveStatus,
    ErrorResponse,
)
from api.models.course import Course, CourseStatus, LMSPlatform
from api.models.enrollment import Enrollment, EnrollmentStatus
from api.utils.ilias_client import ILIASClient
from api.utils.moodle_client import MoodleClient
from api.utils.keycloak_client import KeycloakClient

router = APIRouter(prefix="/api/v1/archival", tags=["archival"])

# In-memory storage for archives (stub implementation)
_archives_db: dict[str, ArchiveInfo] = {}
_archive_jobs: dict[str, BulkArchiveResult] = {}


def _get_courses_db() -> dict[str, Course]:
    """
    Get reference to courses database.
    Referenz auf die Kursdatenbank abrufen.
    """
    from api.routes.courses import _courses_db as courses

    return courses


def _get_enrollments_db() -> dict[str, Enrollment]:
    """
    Get reference to enrollments database.
    Referenz auf die Einschreibungsdatenbank abrufen.
    """
    from api.routes.enrollments import _enrollments_db as enrollments

    return enrollments


async def _get_lms_client(lms: LMSPlatform):
    """
    Get appropriate LMS client based on platform.
    Passenden LMS-Client basierend auf der Plattform abrufen.
    """
    if lms == LMSPlatform.ILIAS:
        return ILIASClient()
    return MoodleClient()


async def _archive_single_course(
    course_id: str,
    create_snapshots: bool = True,
    dry_run: bool = False,
) -> ArchiveResult:
    """
    Internal function to archive a single course.
    Interne Funktion zum Archivieren eines einzelnen Kurses.

    Args:
        course_id: Course identifier / Kurskennung
        create_snapshots: Whether to create backup snapshots / Backup-Snapshots erstellen
        dry_run: Preview mode without execution / Vorschau-Modus ohne Ausführung

    Returns:
        ArchiveResult with operation status / Archivierungsergebnis mit Status
    """
    courses_db = _get_courses_db()

    if course_id not in courses_db:
        return ArchiveResult(
            course_id=course_id,
            status=ArchiveStatus.FAILED,
            error=f"Course {course_id} not found / Kurs {course_id} nicht gefunden",
        )

    course = courses_db[course_id]

    if course.status == CourseStatus.ARCHIVED:
        return ArchiveResult(
            course_id=course_id,
            status=ArchiveStatus.SKIPPED,
            error=f"Course {course_id} is already archived / Kurs {course_id} ist bereits archiviert",
        )

    if dry_run:
        return ArchiveResult(
            course_id=course_id,
            status=ArchiveStatus.COMPLETED,
            archived_at=datetime.now(timezone.utc),
        )

    try:
        archive_id = f"arch_{uuid4().hex[:12]}"
        snapshot_id = None

        # Archive in LMS
        async with await _get_lms_client(course.lms) as client:
            await client.archive_course(course.lms_course_id or course_id)

        # Update all active enrollments to archived status
        enrollments_db = _get_enrollments_db()
        for enrollment in enrollments_db.values():
            if (
                enrollment.course_id == course_id
                and enrollment.status == EnrollmentStatus.ACTIVE
            ):
                enrollment.status = EnrollmentStatus.ARCHIVED
                enrollment.updated_at = datetime.now(timezone.utc)

        # Update Keycloak groups
        async with KeycloakClient() as kc:
            await kc.archive_course_groups(course_id)

        # Create snapshot if requested
        if create_snapshots:
            snapshot_id = f"snap_{uuid4().hex[:12]}"

        # Update course status
        course.status = CourseStatus.ARCHIVED
        course.updated_at = datetime.now(timezone.utc)

        # Store archive info
        archive_info = ArchiveInfo(
            archive_id=archive_id,
            course_id=course_id,
            semester_id=course.semester_id,
            archived_at=datetime.now(timezone.utc),
            snapshot_id=snapshot_id,
            enrollment_count=len(
                [e for e in enrollments_db.values() if e.course_id == course_id]
            ),
        )
        _archives_db[archive_id] = archive_info

        return ArchiveResult(
            course_id=course_id,
            status=ArchiveStatus.COMPLETED,
            archive_id=archive_id,
            snapshot_id=snapshot_id,
            archived_at=datetime.now(timezone.utc),
        )

    except Exception as e:
        return ArchiveResult(
            course_id=course_id,
            status=ArchiveStatus.FAILED,
            error=str(e),
        )


@router.post(
    "/archive/{course_id}",
    response_model=ArchiveResult,
    responses={
        200: {
            "description": "Course archived successfully / Kurs erfolgreich archiviert"
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
    summary="Archive a single course / Einzelnen Kurs archivieren",
    description="Archive a course and freeze all enrollments. / Archiviert einen Kurs und friert alle Einschreibungen ein.",
)
async def archive_course(
    course_id: str, request: ArchiveRequest = ArchiveRequest()
) -> ArchiveResult:
    """
    Archive a single course.
    Archiviert einen einzelnen Kurs.

    Args:
        course_id: Course identifier / Kurskennung
        request: Archive options / Archivierungsoptionen

    Returns:
        ArchiveResult with operation details / Archivierungsergebnis mit Details
    """
    result = await _archive_single_course(
        course_id=course_id,
        create_snapshots=request.create_snapshots,
        dry_run=request.dry_run,
    )

    if result.status == ArchiveStatus.FAILED and "not found" in (result.error or ""):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=result.error,
        )

    return result


@router.post(
    "/bulk-archive",
    response_model=BulkArchiveResult,
    status_code=status.HTTP_202_ACCEPTED,
    responses={
        202: {"description": "Bulk archive job started / Massenarchivierung gestartet"},
        400: {
            "model": ErrorResponse,
            "description": "Invalid request data / Ungültige Anfragedaten",
        },
    },
    summary="Bulk archive courses / Massenarchivierung von Kursen",
    description="Archive multiple courses by semester or course IDs. / Archiviert mehrere Kurse nach Semester oder Kurs-IDs.",
)
async def bulk_archive_courses(request: BulkArchiveRequest) -> BulkArchiveResult:
    """
    Start a bulk archive operation for multiple courses.
    Startet einen Massenarchivierungsvorgang für mehrere Kurse.

    Args:
        request: Bulk archive request with filters / Massenarchivierungsanfrage mit Filtern

    Returns:
        BulkArchiveResult with job status / Massenarchivierungsergebnis mit Job-Status
    """
    courses_db = _get_courses_db()
    job_id = f"job_{uuid4().hex[:12]}"

    # Determine courses to archive
    courses_to_archive = []

    if request.semester_id:
        courses_to_archive = [
            c.course_id
            for c in courses_db.values()
            if c.semester_id == request.semester_id and c.status == CourseStatus.ACTIVE
        ]
    elif request.course_ids:
        courses_to_archive = [
            cid
            for cid in request.course_ids
            if cid in courses_db and courses_db[cid].status == CourseStatus.ACTIVE
        ]

    result = BulkArchiveResult(
        job_id=job_id,
        status=ArchiveStatus.IN_PROGRESS,
        total_courses=len(courses_to_archive),
        completed=0,
        failed=0,
        results=[],
        started_at=datetime.now(timezone.utc),
        completed_at=None,
    )
    _archive_jobs[job_id] = result

    # Process courses synchronously (in production, this would be a background task)
    for course_id in courses_to_archive:
        archive_result = await _archive_single_course(
            course_id=course_id,
            create_snapshots=request.create_snapshots,
            dry_run=request.dry_run,
        )
        result.results.append(archive_result)

        if archive_result.status == ArchiveStatus.COMPLETED:
            result.completed += 1
        elif archive_result.status == ArchiveStatus.FAILED:
            result.failed += 1

    # Update final status
    if result.failed == 0:
        result.status = ArchiveStatus.COMPLETED
    elif result.completed == 0:
        result.status = ArchiveStatus.FAILED
    else:
        result.status = ArchiveStatus.COMPLETED  # Partial success

    _archive_jobs[job_id] = result
    return result


@router.post(
    "/restore/{archive_id}",
    response_model=RestoreResult,
    responses={
        200: {
            "description": "Course restored successfully / Kurs erfolgreich wiederhergestellt"
        },
        400: {
            "model": ErrorResponse,
            "description": "Invalid request data / Ungültige Anfragedaten",
        },
        404: {
            "model": ErrorResponse,
            "description": "Archive not found / Archiv nicht gefunden",
        },
    },
    summary="Restore an archived course / Archivierten Kurs wiederherstellen",
    description="Restore a course from archive to active status. / Stellt einen Kurs aus dem Archiv in den aktiven Status zurück.",
)
async def restore_course(
    archive_id: str, request: RestoreRequest = RestoreRequest()
) -> RestoreResult:
    """
    Restore an archived course.
    Stellt einen archivierten Kurs wieder her.

    Args:
        archive_id: Archive identifier / Archivkennung
        request: Restore options / Wiederherstellungsoptionen

    Returns:
        RestoreResult with operation details / Wiederherstellungsergebnis mit Details
    """
    if archive_id not in _archives_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Archive {archive_id} not found / Archiv {archive_id} nicht gefunden",
        )

    archive_info = _archives_db[archive_id]
    courses_db = _get_courses_db()

    if archive_info.course_id not in courses_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Course {archive_info.course_id} not found / Kurs {archive_info.course_id} nicht gefunden",
        )

    course = courses_db[archive_info.course_id]

    if request.dry_run:
        return RestoreResult(
            archive_id=archive_id,
            course_id=archive_info.course_id,
            status=ArchiveStatus.COMPLETED,
            restored_at=datetime.now(timezone.utc),
        )

    try:
        # Restore course status
        course.status = CourseStatus.ACTIVE
        course.updated_at = datetime.now(timezone.utc)

        # Restore enrollments if requested
        if request.restore_enrollments:
            enrollments_db = _get_enrollments_db()
            for enrollment in enrollments_db.values():
                if (
                    enrollment.course_id == archive_info.course_id
                    and enrollment.status == EnrollmentStatus.ARCHIVED
                ):
                    enrollment.status = EnrollmentStatus.ACTIVE
                    enrollment.updated_at = datetime.now(timezone.utc)

        # Restore Keycloak groups
        async with KeycloakClient() as kc:
            await kc.restore_course_groups(archive_info.course_id)

        return RestoreResult(
            archive_id=archive_id,
            course_id=archive_info.course_id,
            status=ArchiveStatus.COMPLETED,
            restored_at=datetime.now(timezone.utc),
        )

    except Exception as e:
        return RestoreResult(
            archive_id=archive_id,
            course_id=archive_info.course_id,
            status=ArchiveStatus.FAILED,
            error=str(e),
        )


@router.get(
    "/archives/{archive_id}",
    response_model=ArchiveInfo,
    responses={
        200: {"description": "Archive details / Archivdetails"},
        404: {
            "model": ErrorResponse,
            "description": "Archive not found / Archiv nicht gefunden",
        },
    },
    summary="Get archive details / Archivdetails abrufen",
    description="Get details of a specific archived course. / Ruft Details eines bestimmten archivierten Kurses ab.",
)
async def get_archive(archive_id: str) -> ArchiveInfo:
    """
    Get details of a specific archive.
    Ruft Details eines bestimmten Archivs ab.

    Args:
        archive_id: Archive identifier / Archivkennung

    Returns:
        ArchiveInfo object / Archivinfo-Objekt

    Raises:
        404: Archive not found / Archiv nicht gefunden
    """
    if archive_id not in _archives_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Archive {archive_id} not found / Archiv {archive_id} nicht gefunden",
        )

    return _archives_db[archive_id]


@router.get(
    "/archives",
    response_model=ArchiveList,
    responses={200: {"description": "List of archives / Liste der Archive"}},
    summary="List archives / Archive auflisten",
    description="List all archived courses with optional filtering. / Listet alle archivierten Kurse mit optionaler Filterung.",
)
async def list_archives(
    semester_id: Optional[str] = Query(
        None, description="Filter by semester ID / Nach Semesterkennung filtern"
    ),
    page: int = Query(1, ge=1, description="Page number / Seitennummer"),
    page_size: int = Query(
        20, ge=1, le=100, description="Items per page / Einträge pro Seite"
    ),
) -> ArchiveList:
    """
    List all archived courses with optional filtering.
    Listet alle archivierten Kurse mit optionaler Filterung.

    Args:
        semester_id: Filter by semester / Nach Semester filtern
        page: Page number / Seitennummer
        page_size: Items per page / Einträge pro Seite

    Returns:
        Paginated list of archives / Paginierte Liste der Archive
    """
    filtered = list(_archives_db.values())

    if semester_id:
        filtered = [a for a in filtered if a.semester_id == semester_id]

    total = len(filtered)
    start = (page - 1) * page_size
    end = start + page_size

    return ArchiveList(
        archives=filtered[start:end],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get(
    "/jobs/{job_id}",
    response_model=BulkArchiveResult,
    responses={
        200: {"description": "Job details / Job-Details"},
        404: {
            "model": ErrorResponse,
            "description": "Job not found / Job nicht gefunden",
        },
    },
    summary="Get bulk job status / Massenverarbeitungsjob-Status abrufen",
    description="Get status of a bulk archive operation. / Ruft den Status einer Massenarchivierung ab.",
)
async def get_job_status(job_id: str) -> BulkArchiveResult:
    """
    Get status of a bulk archive job.
    Ruft den Status eines Massenarchivierungsjobs ab.

    Args:
        job_id: Job identifier / Job-Kennung

    Returns:
        BulkArchiveResult with job status / Massenarchivierungsergebnis mit Job-Status

    Raises:
        404: Job not found / Job nicht gefunden
    """
    if job_id not in _archive_jobs:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Job {job_id} not found / Job {job_id} nicht gefunden",
        )

    return _archive_jobs[job_id]

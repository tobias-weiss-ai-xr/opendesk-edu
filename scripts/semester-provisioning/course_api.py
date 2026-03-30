# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Course Provisioning API - FastAPI REST endpoints with SQLite storage.
Kursverwaltungs-API - FastAPI-REST-Endpunkte mit SQLite-Speicherung.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any, Optional
from uuid import uuid4

from fastapi import (
    APIRouter,
    FastAPI,
    HTTPException,
    Query,
    status,
    Depends,
)
from pydantic import BaseModel, ConfigDict
from enum import Enum


class CourseStatus(str, Enum):
    DRAFT = "draft"
    ACTIVE = "active"
    ARCHIVED = "archived"
    DELETED = "deleted"


class SemesterType(str, Enum):
    WINTERSEMESTER = "wintersemester"
    SOMMERSEMESTER = "sommersemester"


class LMSPlatform(str, Enum):
    ILIAS = "ilias"
    MOODLE = "moodle"


class SemesterStatus(str, Enum):
    UPCOMING = "upcoming"
    ACTIVE = "active"
    ENDED = "ended"
    ARCHIVED = "archived"


class ArchiveStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    SKIPPED = "skipped"


# Request/Response models
class CourseCreateRequest(BaseModel):
    semester_id: str
    title: str
    title_en: Optional[str] = None
    course_code: str
    instructor_ids: list[str] = []
    expected_enrollment: Optional[int] = None
    lms: LMSPlatform
    category: Optional[str] = None


class CourseUpdateRequest(BaseModel):
    title: Optional[str] = None
    title_en: Optional[str] = None
    instructor_ids: Optional[list[str]] = None
    expected_enrollment: Optional[int] = None
    category: Optional[str] = None
    status: Optional[CourseStatus] = None


class CourseResponse(BaseModel):
    course_id: str
    lms_course_id: Optional[str] = None
    semester_id: str
    title: str
    title_en: Optional[str] = None
    course_code: str
    instructor_ids: list[str] = []
    expected_enrollment: Optional[int] = None
    lms: LMSPlatform
    category: Optional[str] = None
    status: CourseStatus
    created_at: datetime
    updated_at: Optional[datetime] = None
    archived_at: Optional[datetime] = None


class CourseListResponse(BaseModel):
    courses: list[CourseResponse]
    total: int
    page: int
    page_size: int


class SemesterResponse(BaseModel):
    semester_id: str
    name: str
    name_en: Optional[str] = None
    type: SemesterType
    start_date: str
    end_date: str
    status: SemesterStatus
    course_count: int = 0
    created_at: datetime


class SemesterListResponse(BaseModel):
    semesters: list[SemesterResponse]
    total: int


class ArchiveRequest(BaseModel):
    create_snapshots: bool = False
    dry_run: bool = False


class RestoreRequest(BaseModel):
    restore_enrollments: bool = True
    dry_run: bool = False


class ArchiveResponse(BaseModel):
    course_id: str
    archive_id: Optional[str] = None
    snapshot_id: Optional[str] = None
    status: ArchiveStatus
    archived_at: Optional[datetime] = None
    error: Optional[str] = None


class BulkEnrollRequest(BaseModel):
    user_ids: list[str]
    role: str = "student"


class EnrollmentResponse(BaseModel):
    enrollment_id: str
    course_id: str
    user_id: str
    role: str
    status: str
    created_at: datetime


class ErrorResponse(BaseModel):
    error: str
    detail: Optional[str] = None
    code: Optional[str] = None


class AuditLogResponse(BaseModel):
    log_id: str
    action: str
    entity_type: str
    entity_id: str
    user_id: Optional[str] = None
    details: Optional[dict] = None
    created_at: datetime


class AuditLogListResponse(BaseModel):
    logs: list[AuditLogResponse]
    total: int


# In-memory storage (replaced by database in production)
_courses_db: dict[str, dict] = {}
_semesters_db: dict[str, dict] = {}
_enrollments_db: dict[str, dict] = {}
_archives_db: dict[str, dict] = {}
_audit_logs: list[dict] = []


def _audit_log(
    action: str, entity_type: str, entity_id: str, details: Optional[dict] = None
) -> dict:
    now = datetime.now(timezone.utc)
    log_entry = {
        "log_id": f"audit_{uuid4().hex[:12]}",
        "action": action,
        "entity_type": entity_type,
        "entity_id": entity_id,
        "details": details,
        "created_at": now,
    }
    _audit_logs.append(log_entry)
    return log_entry


# FastAPI Application
app = FastAPI(
    title="Course Provisioning API / Kursverwaltungs-API",
    description="REST API for course lifecycle management in openDesk Edu",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

router = APIRouter(prefix="/api/v1/courses", tags=["courses"])


@router.post(
    "",
    response_model=CourseResponse,
    status_code=status.HTTP_201_CREATED,
    responses={
        201: {"description": "Course created successfully"},
        400: {"model": ErrorResponse, "description": "Invalid request data"},
    },
    summary="Create a new course / Neuen Kurs erstellen",
)
async def create_course(course: CourseCreateRequest) -> CourseResponse:
    course_id = f"crs_{uuid4().hex[:12]}"
    now = datetime.now(timezone.utc)
    lms_course_id = f"lms_{uuid4().hex[:12]}"

    course_data = {
        "course_id": course_id,
        "lms_course_id": lms_course_id,
        "semester_id": course.semester_id,
        "title": course.title,
        "title_en": course.title_en,
        "course_code": course.course_code,
        "instructor_ids": course.instructor_ids,
        "expected_enrollment": course.expected_enrollment,
        "lms": course.lms,
        "category": course.category,
        "status": CourseStatus.DRAFT,
        "created_at": now,
    }
    _courses_db[course_id] = course_data

    _audit_log(
        action="course_created",
        entity_type="course",
        entity_id=course_id,
        details={
            "title": course.title,
            "semester_id": course.semester_id,
            "lms": course.lms.value,
        },
    )

    return CourseResponse(**course_data)


@router.get(
    "",
    response_model=CourseListResponse,
    responses={200: {"description": "List of courses"}},
    summary="List courses / Kurse auflisten",
)
async def list_courses(
    semester_id: Optional[str] = Query(None, description="Filter by semester ID"),
    status_filter: Optional[CourseStatus] = Query(
        None, alias="status", description="Filter by status"
    ),
    lms: Optional[LMSPlatform] = Query(None, description="Filter by LMS platform"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
) -> CourseListResponse:
    filtered = list(_courses_db.values())

    if semester_id:
        filtered = [c for c in filtered if c["semester_id"] == semester_id]
    if status_filter:
        filtered = [c for c in filtered if c["status"] == status_filter]
    if lms:
        filtered = [c for c in filtered if c["lms"] == lms]

    total = len(filtered)
    start = (page - 1) * page_size
    end = start + page_size
    paginated = filtered[start:end]

    return CourseListResponse(
        courses=[CourseResponse(**c) for c in paginated],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get(
    "/{course_id}",
    response_model=CourseResponse,
    responses={
        200: {"description": "Course details"},
        404: {"model": ErrorResponse, "description": "Course not found"},
    },
    summary="Get course details / Kursdetails abrufen",
)
async def get_course(course_id: str) -> CourseResponse:
    if course_id not in _courses_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Course {course_id} not found / Kurs {course_id} nicht gefunden",
        )
    return CourseResponse(**_courses_db[course_id])


@router.put(
    "/{course_id}",
    response_model=CourseResponse,
    responses={
        200: {"description": "Course updated successfully"},
        404: {"model": ErrorResponse, "description": "Course not found"},
    },
    summary="Update course / Kurs aktualisieren",
)
async def update_course(course_id: str, update: CourseUpdateRequest) -> CourseResponse:
    if course_id not in _courses_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Course {course_id} not found / Kurs {course_id} nicht gefunden",
        )

    existing = _courses_db[course_id]
    update_data = update.model_dump(exclude_unset=True)

    for field, value in update_data.items():
        if value is not None:
            existing[field] = value

    existing["updated_at"] = datetime.now(timezone.utc)
    _courses_db[course_id] = existing

    _audit_log(
        action="course_updated",
        entity_type="course",
        entity_id=course_id,
        details={"updated_fields": list(update_data.keys())},
    )

    return CourseResponse(**existing)


@router.delete(
    "/{course_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        204: {"description": "Course soft-deleted successfully"},
        404: {"model": ErrorResponse, "description": "Course not found"},
    },
    summary="Delete course (soft delete) / Kurs löschen",
)
async def delete_course(course_id: str) -> None:
    if course_id not in _courses_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Course {course_id} not found / Kurs {course_id} nicht gefunden",
        )

    _courses_db[course_id]["status"] = CourseStatus.DELETED
    _courses_db[course_id]["updated_at"] = datetime.now(timezone.utc)

    _audit_log(
        action="course_deleted",
        entity_type="course",
        entity_id=course_id,
    )


@router.post(
    "/{course_id}/archive",
    response_model=ArchiveResponse,
    responses={
        200: {"description": "Course archived successfully"},
        404: {"model": ErrorResponse, "description": "Course not found"},
        400: {"model": ErrorResponse, "description": "Course already archived"},
    },
    summary="Archive course / Kurs archivieren",
)
async def archive_course(
    course_id: str, request: ArchiveRequest = ArchiveRequest()
) -> ArchiveResponse:
    if request.dry_run:
        return ArchiveResponse(
            course_id=course_id,
            status=ArchiveStatus.COMPLETED,
            archived_at=datetime.now(timezone.utc),
        )

    if course_id not in _courses_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Course {course_id} not found / Kurs {course_id} nicht gefunden",
        )

    course = _courses_db[course_id]

    if course["status"] == CourseStatus.ARCHIVED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Course {course_id} is already archived / Kurs {course_id} ist bereits archiviert",
        )

    now = datetime.now(timezone.utc)
    archive_id = f"arch_{uuid4().hex[:12]}"
    snapshot_id = f"snap_{uuid4().hex[:12]}" if request.create_snapshots else None

    course["status"] = CourseStatus.ARCHIVED
    course["archived_at"] = now
    course["updated_at"] = now
    course["snapshot_id"] = snapshot_id

    _archives_db[archive_id] = {
        "archive_id": archive_id,
        "course_id": course_id,
        "snapshot_id": snapshot_id,
        "archived_at": now,
    }

    _audit_log(
        action="course_archived",
        entity_type="course",
        entity_id=course_id,
        details={"archive_id": archive_id, "snapshot_id": snapshot_id},
    )

    return ArchiveResponse(
        course_id=course_id,
        archive_id=archive_id,
        snapshot_id=snapshot_id,
        status=ArchiveStatus.COMPLETED,
        archived_at=now,
    )


@router.post(
    "/{course_id}/restore",
    response_model=ArchiveResponse,
    responses={
        200: {"description": "Course restored successfully"},
        404: {"model": ErrorResponse, "description": "Course not found"},
        400: {"model": ErrorResponse, "description": "Course not archived"},
    },
    summary="Restore archived course / Archivierten Kurs wiederherstellen",
)
async def restore_course(
    course_id: str, request: RestoreRequest = RestoreRequest()
) -> ArchiveResponse:
    if request.dry_run:
        return ArchiveResponse(
            course_id=course_id,
            status=ArchiveStatus.COMPLETED,
            archived_at=datetime.now(timezone.utc),
        )

    if course_id not in _courses_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Course {course_id} not found / Kurs {course_id} nicht gefunden",
        )

    course = _courses_db[course_id]

    if course["status"] != CourseStatus.ARCHIVED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Course {course_id} is not archived / Kurs {course_id} ist nicht archiviert",
        )

    now = datetime.now(timezone.utc)

    course["status"] = CourseStatus.ACTIVE
    course["archived_at"] = None
    course["snapshot_id"] = None
    course["updated_at"] = now

    _audit_log(
        action="course_restored",
        entity_type="course",
        entity_id=course_id,
        details={"restore_enrollments": request.restore_enrollments},
    )

    return ArchiveResponse(
        course_id=course_id,
        status=ArchiveStatus.COMPLETED,
        archived_at=now,
    )


@router.post(
    "/{course_id}/enrollments",
    response_model=list[EnrollmentResponse],
    status_code=status.HTTP_201_CREATED,
    responses={
        201: {"description": "Enrollments created successfully"},
        404: {"model": ErrorResponse, "description": "Course not found"},
    },
    summary="Bulk enroll users / Benutzer einschreiben",
)
async def bulk_enroll_users(
    course_id: str, request: BulkEnrollRequest
) -> list[EnrollmentResponse]:
    if course_id not in _courses_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Course {course_id} not found / Kurs {course_id} nicht gefunden",
        )

    now = datetime.now(timezone.utc)
    enrollments = []

    for user_id in request.user_ids:
        enrollment_id = f"enr_{uuid4().hex[:12]}"
        enrollment = {
            "enrollment_id": enrollment_id,
            "course_id": course_id,
            "user_id": user_id,
            "role": request.role,
            "status": "active",
            "created_at": now,
        }
        _enrollments_db[enrollment_id] = enrollment
        enrollments.append(EnrollmentResponse(**enrollment))

        _audit_log(
            action="enrollment_added",
            entity_type="enrollment",
            entity_id=enrollment_id,
            details={"course_id": course_id, "user_id": user_id, "role": request.role},
        )

    return enrollments


# Semester router
semester_router = APIRouter(prefix="/api/v1/semesters", tags=["semesters"])


class SemesterCreateRequest(BaseModel):
    semester_id: str
    name: str
    name_en: Optional[str] = None
    type: SemesterType
    start_date: str
    end_date: str


@semester_router.post(
    "",
    response_model=SemesterResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create semester / Semester erstellen",
)
async def create_semester(semester: SemesterCreateRequest) -> SemesterResponse:
    now = datetime.now(timezone.utc)

    semester_data = {
        "semester_id": semester.semester_id,
        "name": semester.name,
        "name_en": semester.name_en,
        "type": semester.type,
        "start_date": semester.start_date,
        "end_date": semester.end_date,
        "status": SemesterStatus.UPCOMING,
        "course_count": 0,
        "created_at": now,
    }
    _semesters_db[semester.semester_id] = semester_data

    _audit_log(
        action="semester_created",
        entity_type="semester",
        entity_id=semester.semester_id,
    )

    return SemesterResponse(**semester_data)


@semester_router.get(
    "",
    response_model=SemesterListResponse,
    summary="List semesters / Semester auflisten",
)
async def list_semesters() -> SemesterListResponse:
    semesters = list(_semesters_db.values())
    return SemesterListResponse(
        semesters=[SemesterResponse(**s) for s in semesters],
        total=len(semesters),
    )


# Audit log router
audit_router = APIRouter(prefix="/api/v1/audit", tags=["audit"])


@audit_router.get(
    "/logs",
    response_model=AuditLogListResponse,
    summary="List audit logs / Audit-Logs auflisten",
)
async def list_audit_logs(
    entity_type: Optional[str] = Query(None),
    entity_id: Optional[str] = Query(None),
    limit: int = Query(100, le=1000),
) -> AuditLogListResponse:
    filtered = _audit_logs

    if entity_type:
        filtered = [l for l in filtered if l["entity_type"] == entity_type]
    if entity_id:
        filtered = [l for l in filtered if l["entity_id"] == entity_id]

    return AuditLogListResponse(
        logs=[AuditLogResponse(**l) for l in filtered[:limit]],
        total=len(filtered),
    )


# Health check
@app.get("/health", tags=["health"])
async def health_check() -> dict:
    return {"status": "healthy"}


@app.get("/ready", tags=["health"])
async def readiness_check() -> dict:
    return {"status": "ready"}


# Include routers
app.include_router(router)
app.include_router(semester_router)
app.include_router(audit_router)


def create_app() -> FastAPI:
    return app


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)

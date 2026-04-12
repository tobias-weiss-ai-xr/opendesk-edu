# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, HTTPException, Query, status
from api.models.semester import (
    Semester,
    SemesterCreate,
    SemesterUpdate,
    SemesterList,
    SemesterStatus,
    ErrorResponse,
)

router = APIRouter(prefix="/api/v1/semesters", tags=["semesters"])

_semesters_db: dict[str, Semester] = {}


def _determine_status(start_date, end_date) -> SemesterStatus:
    from datetime import date

    today = date.today()
    if today < start_date:
        return SemesterStatus.UPCOMING
    elif today > end_date:
        return SemesterStatus.ENDED
    return SemesterStatus.ACTIVE


@router.post(
    "",
    response_model=Semester,
    status_code=status.HTTP_201_CREATED,
    responses={
        201: {"description": "Semester created successfully"},
        400: {"model": ErrorResponse, "description": "Invalid request data"},
    },
)
async def create_semester(semester: SemesterCreate) -> Semester:
    if semester.semester_id in _semesters_db:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Semester {semester.semester_id} already exists",
        )

    now = datetime.now(timezone.utc)
    determined_status = _determine_status(semester.start_date, semester.end_date)

    new_semester = Semester(
        semester_id=semester.semester_id,
        name=semester.name,
        name_en=semester.name_en,
        start_date=semester.start_date,
        end_date=semester.end_date,
        enrollment_start=semester.enrollment_start,
        enrollment_end=semester.enrollment_end,
        status=determined_status,
        created_at=now,
        course_count=0,
    )
    _semesters_db[semester.semester_id] = new_semester
    return new_semester


@router.get(
    "",
    response_model=SemesterList,
    responses={200: {"description": "List of all semesters"}},
)
async def list_semesters(
    status_filter: Optional[SemesterStatus] = Query(
        None, alias="status", description="Filter by status"
    ),
) -> SemesterList:
    filtered = list(_semesters_db.values())

    if status_filter:
        filtered = [s for s in filtered if s.status == status_filter]

    return SemesterList(
        semesters=sorted(filtered, key=lambda s: s.start_date, reverse=True),
        total=len(filtered),
    )


@router.get(
    "/{semester_id}",
    response_model=Semester,
    responses={
        200: {"description": "Semester details"},
        404: {"model": ErrorResponse, "description": "Semester not found"},
    },
)
async def get_semester(semester_id: str) -> Semester:
    if semester_id not in _semesters_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Semester {semester_id} not found",
        )
    return _semesters_db[semester_id]


@router.put(
    "/{semester_id}",
    response_model=Semester,
    responses={
        200: {"description": "Semester updated successfully"},
        404: {"model": ErrorResponse, "description": "Semester not found"},
    },
)
async def update_semester(
    semester_id: str, semester_update: SemesterUpdate
) -> Semester:
    if semester_id not in _semesters_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Semester {semester_id} not found",
        )

    existing = _semesters_db[semester_id]
    update_data = semester_update.model_dump(exclude_unset=True)

    for field, value in update_data.items():
        setattr(existing, field, value)

    if "start_date" in update_data or "end_date" in update_data:
        existing.status = _determine_status(existing.start_date, existing.end_date)

    existing.updated_at = datetime.now(timezone.utc)
    _semesters_db[semester_id] = existing
    return existing


@router.delete(
    "/{semester_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        204: {"description": "Semester archived successfully"},
        404: {"model": ErrorResponse, "description": "Semester not found"},
    },
)
async def archive_semester(semester_id: str) -> None:
    if semester_id not in _semesters_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Semester {semester_id} not found",
        )

    _semesters_db[semester_id].status = SemesterStatus.ARCHIVED
    _semesters_db[semester_id].updated_at = datetime.now(timezone.utc)

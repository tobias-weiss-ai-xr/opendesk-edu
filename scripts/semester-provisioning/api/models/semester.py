# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
from datetime import date, datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class SemesterStatus(str, Enum):
    UPCOMING = "upcoming"
    ACTIVE = "active"
    ENDED = "ended"
    ARCHIVED = "archived"


class SemesterBase(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    semester_id: str = Field(
        ...,
        min_length=1,
        max_length=50,
        description="Semester identifier (e.g., '2026ws', '2026ss')",
    )
    name: str = Field(
        ..., min_length=1, max_length=255, description="Semester name in German"
    )
    name_en: Optional[str] = Field(
        None, max_length=255, description="Semester name in English"
    )
    start_date: date = Field(..., description="Semester start date")
    end_date: date = Field(..., description="Semester end date")
    enrollment_start: Optional[date] = Field(
        None, description="Enrollment period start"
    )
    enrollment_end: Optional[date] = Field(None, description="Enrollment period end")


class SemesterCreate(SemesterBase):
    pass


class SemesterUpdate(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    name: Optional[str] = Field(None, min_length=1, max_length=255)
    name_en: Optional[str] = Field(None, max_length=255)
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    enrollment_start: Optional[date] = None
    enrollment_end: Optional[date] = None
    status: Optional[SemesterStatus] = None


class Semester(SemesterBase):
    status: SemesterStatus = Field(default=SemesterStatus.UPCOMING)
    created_at: datetime
    updated_at: Optional[datetime] = None
    course_count: Optional[int] = Field(
        None, ge=0, description="Number of courses in this semester"
    )


class SemesterList(BaseModel):
    semesters: list[Semester]
    total: int


class ErrorResponse(BaseModel):
    error: str
    detail: Optional[str] = None
    code: Optional[str] = None

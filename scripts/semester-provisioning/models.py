# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Data models for course provisioning.
Datenmodelle für die Kursverwaltung.

This module re-exports models from the api package and provides additional
convenience models for the course provisioning API.
"""

from __future__ import annotations

from datetime import date, datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class CourseStatus(str, Enum):
    DRAFT = "draft"
    ACTIVE = "active"
    ARCHIVED = "archived"
    DELETED = "deleted"


class SemesterType(str, Enum):
    WINTERSEMESTER = "wintersemester"
    SOMMERSEMESTER = "sommersemester"


class SemesterStatus(str, Enum):
    UPCOMING = "upcoming"
    ACTIVE = "active"
    ENDED = "ended"
    ARCHIVED = "archived"


class LMSPlatform(str, Enum):
    ILIAS = "ilias"
    MOODLE = "moodle"


class ArchiveStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    SKIPPED = "skipped"


class SemesterBase(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    semester_id: str = Field(..., min_length=1, max_length=50)
    name: str = Field(..., min_length=1, max_length=255)
    name_en: Optional[str] = Field(None, max_length=255)
    type: SemesterType
    start_date: date
    end_date: date


class Semester(SemesterBase):
    status: SemesterStatus = SemesterStatus.UPCOMING
    created_at: datetime
    updated_at: Optional[datetime] = None
    course_count: int = 0


class CourseBase(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    semester_id: str = Field(..., min_length=1, max_length=50)
    title: str = Field(..., min_length=1, max_length=255)
    title_en: Optional[str] = Field(None, max_length=255)
    course_code: str = Field(..., min_length=1, max_length=50)
    instructor_ids: list[str] = Field(default_factory=list)
    expected_enrollment: Optional[int] = Field(None, ge=0, le=10000)
    lms: LMSPlatform
    category: Optional[str] = Field(None, max_length=100)


class Course(CourseBase):
    course_id: str
    lms_course_id: Optional[str] = None
    status: CourseStatus = CourseStatus.DRAFT
    created_at: datetime
    updated_at: Optional[datetime] = None
    archived_at: Optional[datetime] = None


class EnrollmentBase(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    user_id: str = Field(..., min_length=1, max_length=255)
    role: str = Field(default="student", pattern="^(student|instructor|tutor)$")


class Enrollment(EnrollmentBase):
    enrollment_id: str
    course_id: str
    status: str = "active"
    created_at: datetime


class ArchiveInfo(BaseModel):
    archive_id: str
    course_id: str
    semester_id: str
    archived_at: datetime
    snapshot_id: Optional[str] = None
    enrollment_count: int = 0


class AuditLogEntry(BaseModel):
    log_id: str
    action: str
    entity_type: str
    entity_id: str
    user_id: Optional[str] = None
    details: Optional[dict] = None
    ip_address: Optional[str] = None
    created_at: datetime

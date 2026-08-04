# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
from datetime import datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class LMSPlatform(str, Enum):
    ILIAS = "ilias"
    MOODLE = "moodle"


class CourseStatus(str, Enum):
    ACTIVE = "active"
    ARCHIVED = "archived"
    DRAFT = "draft"
    DELETED = "deleted"


class CourseBase(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    semester_id: str = Field(
        ...,
        min_length=1,
        max_length=50,
        description="Semester identifier (e.g., '2026ws')",
    )
    title: str = Field(
        ..., min_length=1, max_length=255, description="Course title in German"
    )
    title_en: Optional[str] = Field(
        None, max_length=255, description="Course title in English"
    )
    course_code: str = Field(
        ...,
        min_length=1,
        max_length=50,
        description="Official course code (e.g., 'INF-101')",
    )
    instructor_ids: list[str] = Field(
        default_factory=list, description="List of instructor user IDs"
    )
    expected_enrollment: Optional[int] = Field(
        None, ge=0, le=10000, description="Expected number of students"
    )
    lms: LMSPlatform = Field(..., description="Target LMS platform")
    category: Optional[str] = Field(
        None, max_length=100, description="LMS category path"
    )


class CourseCreate(CourseBase):
    pass


class CourseBulkCreate(BaseModel):
    courses: list[CourseCreate] = Field(..., min_length=1, max_length=1000)


class CourseUpdate(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    title: Optional[str] = Field(None, min_length=1, max_length=255)
    title_en: Optional[str] = Field(None, max_length=255)
    instructor_ids: Optional[list[str]] = None
    expected_enrollment: Optional[int] = Field(None, ge=0, le=10000)
    category: Optional[str] = Field(None, max_length=100)
    status: Optional[CourseStatus] = None


class Course(CourseBase):
    course_id: str = Field(..., description="Unique course identifier")
    lms_course_id: Optional[str] = Field(None, description="Course ID in the LMS")
    status: CourseStatus = Field(default=CourseStatus.ACTIVE)
    created_at: datetime
    updated_at: Optional[datetime] = None


class CourseList(BaseModel):
    courses: list[Course]
    total: int
    page: int
    page_size: int


class EnrollmentBase(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    user_id: str = Field(..., min_length=1, max_length=255)
    role: str = Field(default="student", pattern="^(student|instructor|tutor)$")


class EnrollmentCreate(EnrollmentBase):
    pass


class EnrollmentBulkCreate(BaseModel):
    enrollments: list[EnrollmentCreate] = Field(..., min_length=1, max_length=1000)


class Enrollment(EnrollmentBase):
    enrollment_id: str
    course_id: str
    created_at: datetime


class ErrorResponse(BaseModel):
    error: str
    detail: Optional[str] = None
    code: Optional[str] = None

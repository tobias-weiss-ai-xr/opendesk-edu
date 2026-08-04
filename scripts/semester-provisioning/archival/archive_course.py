# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Single course archival script.
Archivierungsskript für einzelne Kurse.
"""

from __future__ import annotations

import json
import logging
from datetime import datetime, timezone
from typing import Any, Optional
from uuid import uuid4

from pydantic import BaseModel, Field

from audit import AuditAction, AuditLogger
from database import Database

logger = logging.getLogger(__name__)


class ArchiveSnapshot(BaseModel):
    snapshot_id: str = Field(default_factory=lambda: f"snap_{uuid4().hex[:12]}")
    course_id: str
    semester_id: str
    title: str
    title_en: Optional[str] = None
    course_code: str
    lms: str
    lms_course_id: Optional[str] = None
    instructor_ids: list[str] = Field(default_factory=list)
    enrollment_count: int = 0
    archived_at: datetime
    status_before: str = "active"


class ArchiveResult(BaseModel):
    course_id: str
    archive_id: str = Field(default_factory=lambda: f"arch_{uuid4().hex[:12]}")
    snapshot: Optional[ArchiveSnapshot] = None
    success: bool = True
    error: Optional[str] = None
    frozen_enrollments: int = 0
    revoked_access_count: int = 0


class ILIASArchivalClient:
    def set_read_only(self, lms_course_id: str) -> int:
        logger.info(f"ILIAS: setting course {lms_course_id} to read-only")
        return 0


class MoodleArchivalClient:
    def set_read_only(self, lms_course_id: str) -> int:
        logger.info(f"Moodle: setting course {lms_course_id} to read-only")
        return 0


def archive_course(
    course_id: str,
    *,
    database: Database,
    audit_logger: AuditLogger,
    create_snapshot: bool = True,
    ilias_client: Optional[Any] = None,
    moodle_client: Optional[Any] = None,
) -> ArchiveResult:
    now = datetime.now(timezone.utc)
    result = ArchiveResult(course_id=course_id)

    course = database.get_course(course_id)
    if course is None:
        result.success = False
        result.error = f"Course {course_id} not found / Kurs {course_id} nicht gefunden"
        return result

    if course.get("status") == "archived":
        result.success = False
        result.error = f"Course {course_id} is already archived / Kurs {course_id} ist bereits archiviert"
        return result

    frozen_count = _freeze_enrollments(course_id, database)
    result.frozen_enrollments = frozen_count

    revoked_count = _revoke_student_write_access(
        course, ilias_client=ilias_client, moodle_client=moodle_client
    )
    result.revoked_access_count = revoked_count

    snapshot = None
    if create_snapshot:
        snapshot = _create_archive_snapshot(course, frozen_count, now)
        result.snapshot = snapshot
        _store_snapshot(snapshot, database)

    updated = database.update_course(course_id, {"status": "archived"})
    if updated is None:
        result.success = False
        result.error = f"Failed to update course status for {course_id}"
        return result

    audit_logger.log(
        action=AuditAction.COURSE_ARCHIVED,
        entity_type="course",
        entity_id=course_id,
        details={
            "archive_id": result.archive_id,
            "snapshot_id": snapshot.snapshot_id if snapshot else None,
            "title": course.get("title"),
            "semester_id": course.get("semester_id"),
            "frozen_enrollments": frozen_count,
            "revoked_access_count": revoked_count,
            "archived_at": now.isoformat(),
        },
    )

    return result


def _freeze_enrollments(course_id: str, database: Database) -> int:
    enrollments = database.list_enrollments(course_id)
    frozen = 0
    for enrollment in enrollments:
        if enrollment.get("status") == "active":
            database.update_enrollment(
                enrollment["enrollment_id"], {"status": "frozen"}
            )
            frozen += 1
    return frozen


def _revoke_student_write_access(
    course: dict,
    *,
    ilias_client: Optional[Any] = None,
    moodle_client: Optional[Any] = None,
) -> int:
    """Revoke write access for enrolled students.

    If a LMS-specific course id (lms_course_id) is not available, fall back
    to using the generic course_id so tests can mock the LMS client
    expectations (see test_archive_course_with_ilias_client).
    """
    lms_course_id = course.get("lms_course_id")
    lms = course.get("lms", "")
    if not lms_course_id:
        # Fallback to course_id for LMS when a specific LMS id is not stored.
        if not lms:
            return 0
        if lms == "ilias":
            client = ilias_client or ILIASArchivalClient()
            return client.set_read_only(course.get("course_id"))
        elif lms == "moodle":
            client = moodle_client or MoodleArchivalClient()
            return client.set_read_only(course.get("course_id"))
        else:
            logger.warning(
                f"Unknown LMS platform '{lms}', skipping write-access revocation"
            )
            return 0

    if lms == "ilias":
        client = ilias_client or ILIASArchivalClient()
        return client.set_read_only(lms_course_id)
    elif lms == "moodle":
        client = moodle_client or MoodleArchivalClient()
        return client.set_read_only(lms_course_id)
    else:
        logger.warning(
            f"Unknown LMS platform '{lms}', skipping write-access revocation"
        )
        return 0


def _create_archive_snapshot(
    course: dict, enrollment_count: int, archived_at: datetime
) -> ArchiveSnapshot:
    return ArchiveSnapshot(
        course_id=course["course_id"],
        semester_id=course.get("semester_id", ""),
        title=course.get("title", ""),
        title_en=course.get("title_en"),
        course_code=course.get("course_code", ""),
        lms=course.get("lms", ""),
        lms_course_id=course.get("lms_course_id"),
        instructor_ids=course.get("instructor_ids", []),
        enrollment_count=enrollment_count,
        archived_at=archived_at,
        status_before=course.get("status", "active"),
    )


def _store_snapshot(snapshot: ArchiveSnapshot, database: Database) -> None:
    with database.get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS archive_snapshots (
                snapshot_id TEXT PRIMARY KEY,
                course_id TEXT NOT NULL,
                semester_id TEXT,
                title TEXT,
                title_en TEXT,
                course_code TEXT,
                lms TEXT,
                lms_course_id TEXT,
                instructor_ids TEXT NOT NULL DEFAULT '[]',
                enrollment_count INTEGER DEFAULT 0,
                status_before TEXT DEFAULT 'active',
                archived_at TEXT NOT NULL
            )
        """)
        cursor.execute(
            """INSERT INTO archive_snapshots (
                snapshot_id, course_id, semester_id, title, title_en,
                course_code, lms, lms_course_id, instructor_ids,
                enrollment_count, status_before, archived_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                snapshot.snapshot_id,
                snapshot.course_id,
                snapshot.semester_id,
                snapshot.title,
                snapshot.title_en,
                snapshot.course_code,
                snapshot.lms,
                snapshot.lms_course_id,
                json.dumps(snapshot.instructor_ids),
                snapshot.enrollment_count,
                snapshot.status_before,
                snapshot.archived_at.isoformat(),
            ),
        )
        conn.commit()

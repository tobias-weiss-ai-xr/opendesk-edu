# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Tests for course archival functionality.
Tests für die Kursarchivierungsfunktionalität.

EN: Unit tests covering single course archival, bulk semester archival,
and course restoration workflows.
DE: Unit-Tests für einzelne Kursarchivierung, Massen-Semesterarchivierung
und Kurswiederherstellungsworkflows.
"""

from __future__ import annotations

from datetime import datetime, timezone
from unittest import mock

import pytest

from audit import AuditAction, AuditLogger
from database import Database, DatabaseConfig
from archival.archive_course import (
    ArchiveResult,
    ArchiveSnapshot,
    ILIASArchivalClient,
    MoodleArchivalClient,
    archive_course,
)
from archival.bulk_archive import bulk_archive_semester
from archival.restore_course import (
    ILIASRestoreClient,
    MoodleRestoreClient,
    restore_course,
)


@pytest.fixture
def database():
    db = Database(DatabaseConfig(db_path=":memory:"))
    db.connect()
    yield db
    db.close()


@pytest.fixture
def audit_logger():
    return AuditLogger(db_path=":memory:")


@pytest.fixture
def sample_course(database):
    course = database.create_course(
        {
            "semester_id": "2026ws",
            "title": "Test Course for Archival",
            "title_en": "Test Course for Archival (EN)",
            "course_code": "TEST-ARCH-101",
            "instructor_ids": ["prof-001"],
            "expected_enrollment": 50,
            "lms": "ilias",
            "lms_course_id": "ilias_ref_123",
            "category": "test",
            "status": "active",
        }
    )
    database.create_enrollment(
        {
            "course_id": course["course_id"],
            "user_id": "student-001",
            "role": "student",
            "status": "active",
        }
    )
    database.create_enrollment(
        {
            "course_id": course["course_id"],
            "user_id": "student-002",
            "role": "student",
            "status": "active",
        }
    )
    return course


class TestArchiveCourse:
    def test_archive_course_success(self, database, audit_logger, sample_course):
        result = archive_course(
            sample_course["course_id"],
            database=database,
            audit_logger=audit_logger,
            create_snapshot=True,
        )
        assert result.success
        assert result.snapshot is not None
        assert result.frozen_enrollments == 2

    def test_archive_course_not_found(self, database, audit_logger):
        result = archive_course(
            "nonexistent-course",
            database=database,
            audit_logger=audit_logger,
        )
        assert not result.success
        assert "not found" in result.error.lower()

    def test_archive_course_already_archived(
        self, database, audit_logger, sample_course
    ):
        database.update_course(sample_course["course_id"], {"status": "archived"})
        result = archive_course(
            sample_course["course_id"],
            database=database,
            audit_logger=audit_logger,
        )
        assert not result.success
        assert "already archived" in result.error.lower()

    def test_archive_course_with_ilias_client(
        self, database, audit_logger, sample_course
    ):
        mock_ilias = mock.MagicMock(spec=ILIASArchivalClient)
        mock_ilias.set_read_only.return_value = 25
        result = archive_course(
            sample_course["course_id"],
            database=database,
            audit_logger=audit_logger,
            ilias_client=mock_ilias,
        )
        assert result.success
        assert result.revoked_access_count == 25
        mock_ilias.set_read_only.assert_called_once()

    def test_archive_course_with_moodle_client(self, database, audit_logger):
        course = database.create_course(
            {
                "semester_id": "2026ws",
                "title": "Moodle Course",
                "course_code": "MOODLE-101",
                "lms": "moodle",
                "lms_course_id": "moodle_ref_123",
                "status": "active",
            }
        )
        mock_moodle = mock.MagicMock(spec=MoodleArchivalClient)
        mock_moodle.set_read_only.return_value = 30
        result = archive_course(
            course["course_id"],
            database=database,
            audit_logger=audit_logger,
            moodle_client=mock_moodle,
        )
        assert result.success
        assert result.revoked_access_count == 30

    def test_archive_course_creates_audit_log(
        self, database, audit_logger, sample_course
    ):
        result = archive_course(
            sample_course["course_id"],
            database=database,
            audit_logger=audit_logger,
        )
        assert result.success
        logs = audit_logger.get_logs(entity_id=sample_course["course_id"])
        assert len(logs) == 1
        assert logs[0].action == AuditAction.COURSE_ARCHIVED


class TestBulkArchiveSemester:
    def test_bulk_archive_success(self, database, audit_logger):
        for i in range(3):
            database.create_course(
                {
                    "semester_id": "2026ws",
                    "title": f"Bulk Test Course {i}",
                    "course_code": f"BULK-{i}",
                    "lms": "ilias",
                    "status": "active",
                }
            )
        summary = bulk_archive_semester(
            "2026ws",
            database=database,
            audit_logger=audit_logger,
        )
        assert summary.success
        assert summary.total_courses == 3
        assert summary.archived_courses == 3
        assert summary.failed_courses == 0

    def test_bulk_archive_dry_run(self, database, audit_logger):
        for i in range(2):
            database.create_course(
                {
                    "semester_id": "2026ss",
                    "title": f"Dry Run Course {i}",
                    "course_code": f"DRY-{i}",
                    "lms": "moodle",
                    "status": "active",
                }
            )
        summary = bulk_archive_semester(
            "2026ss",
            database=database,
            audit_logger=audit_logger,
            dry_run=True,
        )
        assert summary.skipped_courses == 2
        courses, _ = database.list_courses(semester_id="2026ss", status="active")
        assert len(courses) == 2

    def test_bulk_archive_partial_failure(self, database, audit_logger):
        database.create_course(
            {
                "semester_id": "2026fail",
                "title": "Good Course",
                "course_code": "GOOD-1",
                "lms": "ilias",
                "lms_course_id": "ilias_good_123",
                "status": "active",
            }
        )
        course2 = database.create_course(
            {
                "semester_id": "2026fail",
                "title": "Bad Course",
                "course_code": "BAD-1",
                "lms": "ilias",
                "lms_course_id": "ilias_bad_456",
                "status": "active",
            }
        )

        original_archive = archive_course

        def _selective_archive(course_id, **kwargs):
            if course_id == course2["course_id"]:
                return ArchiveResult(
                    course_id=course_id,
                    success=False,
                    error="Simulated archival failure / Simulierter Archivierungsfehler",
                )
            return original_archive(course_id, **kwargs)

        with mock.patch(
            "archival.bulk_archive.archive_course", side_effect=_selective_archive
        ):
            summary = bulk_archive_semester(
                "2026fail",
                database=database,
                audit_logger=audit_logger,
            )

        assert summary.total_courses == 2
        assert summary.archived_courses == 1
        assert summary.failed_courses == 1


class TestRestoreCourse:
    def test_restore_course_success(self, database, audit_logger, sample_course):
        archive_result = archive_course(
            sample_course["course_id"],
            database=database,
            audit_logger=audit_logger,
            create_snapshot=True,
        )
        assert archive_result.success
        restore_result = restore_course(
            sample_course["course_id"],
            database=database,
            audit_logger=audit_logger,
        )
        assert restore_result.success
        assert restore_result.restored_enrollments == 2

    def test_restore_course_not_found(self, database, audit_logger):
        result = restore_course(
            "nonexistent-course",
            database=database,
            audit_logger=audit_logger,
        )
        assert not result.success
        assert "not found" in result.error.lower()

    def test_restore_course_not_archived(self, database, audit_logger, sample_course):
        result = restore_course(
            sample_course["course_id"],
            database=database,
            audit_logger=audit_logger,
        )
        assert not result.success
        assert (
            "nicht archiviert" in result.error.lower()
            or "ist nicht archiviert" in result.error.lower()
        )

    def test_restore_with_ilias_client(self, database, audit_logger):
        course = database.create_course(
            {
                "semester_id": "2026ws",
                "title": "ILIAS Restore Test",
                "course_code": "ILIAS-REST-101",
                "lms": "ilias",
                "lms_course_id": "ilias_ref_456",
                "status": "archived",
            }
        )
        database.create_enrollment(
            {
                "course_id": course["course_id"],
                "user_id": "student-001",
                "role": "student",
                "status": "frozen",
            }
        )
        mock_ilias = mock.MagicMock(spec=ILIASRestoreClient)
        mock_ilias.restore_write_access.return_value = 15
        result = restore_course(
            course["course_id"],
            database=database,
            audit_logger=audit_logger,
            ilias_client=mock_ilias,
        )
        assert result.success
        assert result.restored_access_count == 15
        mock_ilias.restore_write_access.assert_called_once()

    def test_restore_without_enrollments(self, database, audit_logger):
        course = database.create_course(
            {
                "semester_id": "2026ws",
                "title": "No Enrollment Restore",
                "course_code": "NO-ENR-101",
                "lms": "moodle",
                "status": "archived",
            }
        )
        result = restore_course(
            course["course_id"],
            database=database,
            audit_logger=audit_logger,
            restore_enrollments=False,
        )
        assert result.success
        assert result.restored_enrollments == 0

    def test_restore_creates_audit_log(self, database, audit_logger, sample_course):
        archive_course(
            sample_course["course_id"],
            database=database,
            audit_logger=audit_logger,
        )
        audit_logger.clear()
        result = restore_course(
            sample_course["course_id"],
            database=database,
            audit_logger=audit_logger,
        )
        assert result.success
        logs = audit_logger.get_logs(entity_id=sample_course["course_id"])
        assert len(logs) == 1
        assert logs[0].action == AuditAction.COURSE_RESTORED


class TestArchiveSnapshot:
    def test_snapshot_model(self):
        snapshot = ArchiveSnapshot(
            course_id="crs_test",
            semester_id="2026ws",
            title="Test Course",
            course_code="TEST-101",
            lms="ilias",
            enrollment_count=42,
            archived_at=datetime.now(timezone.utc),
        )
        assert snapshot.course_id == "crs_test"
        assert snapshot.enrollment_count == 42
        assert snapshot.snapshot_id.startswith("snap_")


class TestLMSClients:
    def test_ilias_archival_client(self):
        client = ILIASArchivalClient()
        count = client.set_read_only("ilias_course_123")
        assert isinstance(count, int)

    def test_moodle_archival_client(self):
        client = MoodleArchivalClient()
        count = client.set_read_only("moodle_course_456")
        assert isinstance(count, int)

    def test_ilias_restore_client(self):
        client = ILIASRestoreClient()
        count = client.restore_write_access("ilias_course_123")
        assert isinstance(count, int)

    def test_moodle_restore_client(self):
        client = MoodleRestoreClient()
        count = client.restore_write_access("moodle_course_456")
        assert isinstance(count, int)

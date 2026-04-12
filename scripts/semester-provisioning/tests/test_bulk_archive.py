# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0

from unittest.mock import MagicMock, patch
from datetime import datetime, timezone

from archival.bulk_archive import (
    BulkArchiveSummary,
    bulk_archive_semester,
    _log_bulk_operation,
)


class TestBulkArchiveSummary:
    """Test BulkArchiveSummary data model."""

    def test_initialization_with_defaults(self):
        """Test BulkArchiveSummary initializes with correct defaults."""
        summary = BulkArchiveSummary(
            semester_id="2026ws", started_at=datetime.now(timezone.utc)
        )

        assert summary.semester_id == "2026ws"
        assert summary.total_courses == 0
        assert summary.archived_courses == 0
        assert summary.skipped_courses == 0
        assert summary.failed_courses == 0
        assert summary.total_frozen_enrollments == 0
        assert summary.total_revoked_access == 0
        assert summary.results == []
        assert summary.errors == []
        assert summary.success is True
        assert summary.completed_at is None

    def test_initialization_with_custom_values(self):
        """Test BulkArchiveSummary accepts custom values."""
        now = datetime.now(timezone.utc)
        summary = BulkArchiveSummary(
            semester_id="2026ws",
            started_at=now,
            completed_at=now,
            total_courses=10,
            archived_courses=8,
            skipped_courses=1,
            failed_courses=1,
            total_frozen_enrollments=50,
            total_revoked_access=30,
        )

        assert summary.semester_id == "2026ws"
        assert summary.total_courses == 10
        assert summary.archived_courses == 8
        assert summary.skipped_courses == 1
        assert summary.failed_courses == 1
        assert summary.total_frozen_enrollments == 50
        assert summary.total_revoked_access == 30
        assert summary.completed_at == now


class TestBulkArchiveSemester:
    """Test bulk_archive_semester function."""

    def test_bulk_archive_semester_dry_run(self):
        """Test bulk_archive_semester in dry run mode."""
        mock_db = MagicMock()
        mock_audit = MagicMock()

        mock_db.list_courses.return_value = (
            [{"course_id": "crs-1"}, {"course_id": "crs-2"}, {"course_id": "crs-3"}],
            3,
        )

        result = bulk_archive_semester(
            "2026ws", database=mock_db, audit_logger=mock_audit, dry_run=True
        )

        # Verify dry run behavior
        assert result.total_courses == 3
        assert result.archived_courses == 0
        assert result.skipped_courses == 3
        assert result.failed_courses == 0
        assert result.completed_at is not None

        # Should log dry run operation
        mock_audit.log.assert_called_once()
        audit_call = mock_audit.log.call_args
        assert audit_call[1]["details"]["dry_run"] is True

    def test_bulk_archive_semester_successful(self):
        """Test bulk_archive_semester successfully archives all courses."""
        mock_db = MagicMock()
        mock_audit = MagicMock()
        mock_archive_result = MagicMock(
            success=True, frozen_enrollments=10, revoked_access_count=5
        )

        mock_db.list_courses.return_value = (
            [{"course_id": "crs-1"}, {"course_id": "crs-2"}],
            2,
        )

        with patch("archival.bulk_archive.archive_course") as mock_archive_course:
            mock_archive_course.return_value = mock_archive_result

            result = bulk_archive_semester(
                "2026ws", database=mock_db, audit_logger=mock_audit, dry_run=False
            )

            # Verify results
            assert result.total_courses == 2
            assert result.archived_courses == 2
            assert result.failed_courses == 0
            assert result.skipped_courses == 0
            assert result.total_frozen_enrollments == 20  # 2 courses * 10 each
            assert result.total_revoked_access == 10  # 2 courses * 5 each
            assert result.success is True

            # Verify archive_course called for each course
            assert mock_archive_course.call_count == 2

    def test_bulk_archive_semester_with_failures(self):
        """Test bulk_archive_semester handles failures correctly."""
        mock_db = MagicMock()
        mock_audit = MagicMock()

        # Mix of success and failure
        mock_db.list_courses.return_value = (
            [{"course_id": "crs-1"}, {"course_id": "crs-2"}],
            2,
        )

        with patch("archival.bulk_archive.archive_course") as mock_archive_course:
            # First succeeds, second fails
            mock_archive_course.side_effect = [
                MagicMock(success=True, frozen_enrollments=5, revoked_access_count=3),
                MagicMock(success=False, error="Archive failed"),
            ]

            result = bulk_archive_semester(
                "2026ws", database=mock_db, audit_logger=mock_audit, dry_run=False
            )

            # Verify results
            assert result.total_courses == 2
            assert result.archived_courses == 1
            assert result.failed_courses == 1
            assert result.skipped_courses == 0
            assert result.success is False

            # Verify error logged
            assert len(result.errors) == 1
            assert result.errors[0]["course_id"] == "crs-2"

    def test_bulk_archive_semester_handles_already_archived(self):
        """Test bulk_archive_semester treats already-archived as skipped."""
        mock_db = MagicMock()
        mock_audit = MagicMock()

        mock_db.list_courses.return_value = ([{"course_id": "crs-1"}], 1)

        with patch("archival.bulk_archive.archive_course") as mock_archive_course:
            mock_archive_course.return_value = MagicMock(
                success=False, error="Course already archived"
            )

            result = bulk_archive_semester(
                "2026ws", database=mock_db, audit_logger=mock_audit, dry_run=False
            )

            # Already archived should be skipped, not failed
            assert result.total_courses == 1
            assert result.archived_courses == 0
            assert result.failed_courses == 0
            assert result.skipped_courses == 1
            assert result.success is True

    def test_bulk_archive_semester_empty_courses_list(self):
        """Test bulk_archive_semester handles semester with no active courses."""
        mock_db = MagicMock()
        mock_audit = MagicMock()

        mock_db.list_courses.return_value = ([], 0)

        result = bulk_archive_semester(
            "2026ws", database=mock_db, audit_logger=mock_audit, dry_run=False
        )

        # Should handle empty list gracefully
        assert result.total_courses == 0
        assert result.archived_courses == 0
        assert result.skipped_courses == 0
        assert result.failed_courses == 0
        assert result.success is True

    def test_bulk_archive_semester_handles_exception(self):
        """Test bulk_archive_semester handles exceptions during archiving."""
        mock_db = MagicMock()
        mock_audit = MagicMock()

        mock_db.list_courses.return_value = ([{"course_id": "crs-1"}], 1)

        with patch("archival.bulk_archive.archive_course") as mock_archive_course:
            mock_archive_course.side_effect = Exception("Unexpected error")

            result = bulk_archive_semester(
                "2026ws", database=mock_db, audit_logger=mock_audit, dry_run=False
            )

            # Exception should be caught and counted as failure
            assert result.total_courses == 1
            assert result.archived_courses == 0
            assert result.failed_courses == 1
            assert len(result.errors) == 1

    def test_bulk_archive_semester_calculates_correct_summary(self):
        """Test bulk_archive_semester correctly calculates summary statistics."""
        mock_db = MagicMock()
        mock_audit = MagicMock()

        mock_db.list_courses.return_value = (
            [{"course_id": "crs-1"}, {"course_id": "crs-2"}, {"course_id": "crs-3"}],
            3,
        )

        with patch("archival.bulk_archive.archive_course") as mock_archive_course:
            # Mix: 2 success, 1 failed
            mock_archive_course.side_effect = [
                MagicMock(success=True, frozen_enrollments=5, revoked_access_count=2),
                MagicMock(success=False, error="Failed"),
                MagicMock(success=True, frozen_enrollments=10, revoked_access_count=4),
            ]

            result = bulk_archive_semester(
                "2026ws", database=mock_db, audit_logger=mock_audit, dry_run=False
            )

            # Verify totals
            assert result.total_courses == 3
            assert result.archived_courses == 2
            assert result.failed_courses == 1
            # skipped = total - archived - failed = 3 - 2 - 1 = 0
            assert result.skipped_courses == 0
            assert result.total_frozen_enrollments == 15  # 5 + 10
            assert result.total_revoked_access == 6  # 2 + 4


class TestLogBulkOperation:
    """Test _log_bulk_operation helper function."""

    def test_log_bulk_operation_writes_audit_log(self):
        """Test _log_bulk_operation writes to audit log."""
        mock_audit = MagicMock()
        now = datetime.now(timezone.utc)

        summary = BulkArchiveSummary(
            semester_id="2026ws",
            started_at=now,
            completed_at=now,
            total_courses=10,
            archived_courses=8,
            failed_courses=1,
            total_frozen_enrollments=50,
            total_revoked_access=30,
        )

        _log_bulk_operation(mock_audit, summary, dry_run=False)

        # Verify audit log was called
        mock_audit.log.assert_called_once()
        call_args = mock_audit.log.call_args
        assert call_args[1]["entity_id"] == "2026ws"
        assert call_args[1]["entity_type"] == "semester"

        # Verify details
        details = call_args[1]["details"]
        assert details["operation"] == "bulk_archive"
        assert details["dry_run"] is False
        assert details["total_courses"] == 10
        assert details["archived_courses"] == 8
        assert details["failed_courses"] == 1
        assert details["total_frozen_enrollments"] == 50

    def test_log_bulk_operation_with_dry_run(self):
        """Test _log_bulk_operation marks dry run in details."""
        mock_audit = MagicMock()

        summary = BulkArchiveSummary(
            semester_id="2026ws", started_at=datetime.now(timezone.utc)
        )

        _log_bulk_operation(mock_audit, summary, dry_run=True)

        # Verify dry run flag is set
        call_args = mock_audit.log.call_args
        assert call_args[1]["details"]["dry_run"] is True

    def test_log_bulk_operation_includes_timestamps(self):
        """Test _log_bulk_operation includes timestamp information."""
        mock_audit = MagicMock()
        now = datetime(2026, 4, 12, 12, 0, 0, tzinfo=timezone.utc)

        summary = BulkArchiveSummary(
            semester_id="2026ws", started_at=now, completed_at=now
        )

        _log_bulk_operation(mock_audit, summary, dry_run=False)

        # Verify timestamps included
        call_args = mock_audit.log.call_args
        details = call_args[1]["details"]
        assert "started_at" in details
        assert "completed_at" in details

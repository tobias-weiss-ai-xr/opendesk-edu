# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Extended tests for the audit logging module.
Erweiterte Tests für das Audit-Logging-Modul.

EN: Unit tests covering log creation, persistence, filtering, clearing,
    exporting, and the global singleton accessor.
DE: Unit-Tests für Log-Erstellung, Persistenz, Filterung, Löschung,
    Export und den globalen Singleton-Zugriff.
"""

from __future__ import annotations

import json
import sqlite3

import pytest

from audit import AuditAction, AuditLog, AuditLogger, get_audit_logger


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def logger():
    """Fresh in-memory audit logger for each test."""
    return AuditLogger(db_path=":memory:")


@pytest.fixture
def temp_db_path(tmp_path):
    """Temporary SQLite database path for persistence tests."""
    return str(tmp_path / "test_audit.db")


# ---------------------------------------------------------------------------
# TestAuditLoggerInMemory
# ---------------------------------------------------------------------------


class TestAuditLoggerInMemory:
    """Tests for in-memory log storage (db_path=':memory:')."""

    def test_log_creates_entry(self, logger):
        entry = logger.log(
            action=AuditAction.COURSE_CREATED,
            entity_type="course",
            entity_id="crs_001",
        )
        assert isinstance(entry, AuditLog)
        assert entry.action == AuditAction.COURSE_CREATED
        assert entry.entity_type == "course"
        assert entry.entity_id == "crs_001"
        assert entry.log_id.startswith("audit_")
        assert entry.created_at is not None

    def test_log_with_all_optional_fields(self, logger):
        entry = logger.log(
            action=AuditAction.COURSE_UPDATED,
            entity_type="course",
            entity_id="crs_002",
            user_id="user-42",
            details={"field": "title", "old": "A", "new": "B"},
            ip_address="10.0.0.1",
            user_agent="TestAgent/1.0",
        )
        assert entry.user_id == "user-42"
        assert entry.details == {"field": "title", "old": "A", "new": "B"}
        assert entry.ip_address == "10.0.0.1"
        assert entry.user_agent == "TestAgent/1.0"

    def test_log_appends_to_memory_list(self, logger):
        logger.log(AuditAction.COURSE_CREATED, "course", "c1")
        logger.log(AuditAction.COURSE_UPDATED, "course", "c2")
        logger.log(AuditAction.COURSE_DELETED, "course", "c3")
        assert len(logger.logs) == 3

    def test_log_returns_auditlog_instance(self, logger):
        entry = logger.log(AuditAction.COURSE_CREATED, "course", "c1")
        assert isinstance(entry, AuditLog)


# ---------------------------------------------------------------------------
# TestAuditLoggerPersistence
# ---------------------------------------------------------------------------


class TestAuditLoggerPersistence:
    """Tests for SQLite file persistence."""

    def test_log_persists_to_sqlite_file(self, temp_db_path):
        al = AuditLogger(db_path=temp_db_path)
        entry = al.log(
            action=AuditAction.COURSE_CREATED,
            entity_type="course",
            entity_id="crs_persist",
        )
        # Verify via direct sqlite3 query
        conn = sqlite3.connect(temp_db_path)
        row = conn.execute(
            "SELECT log_id, action, entity_type, entity_id FROM audit_logs"
        ).fetchone()
        conn.close()
        assert row is not None
        assert row[0] == entry.log_id
        assert row[1] == "course_created"
        assert row[2] == "course"
        assert row[3] == "crs_persist"

    def test_log_persists_optional_fields(self, temp_db_path):
        al = AuditLogger(db_path=temp_db_path)
        al.log(
            action=AuditAction.ENROLLMENT_ADDED,
            entity_type="enrollment",
            entity_id="enr_001",
            user_id="user-99",
            details={"role": "student"},
            ip_address="192.168.1.1",
            user_agent="Pytest/2.0",
        )
        conn = sqlite3.connect(temp_db_path)
        row = conn.execute(
            "SELECT user_id, details, ip_address, user_agent FROM audit_logs"
        ).fetchone()
        conn.close()
        assert row[0] == "user-99"
        assert json.loads(row[1]) == {"role": "student"}
        assert row[2] == "192.168.1.1"
        assert row[3] == "Pytest/2.0"

    def test_log_falls_back_on_bad_path(self):
        al = AuditLogger(db_path="/nonexistent/dir/test_audit.db")
        entry = al.log(
            action=AuditAction.COURSE_CREATED,
            entity_type="course",
            entity_id="crs_fallback",
        )
        # Should still return a valid AuditLog
        assert isinstance(entry, AuditLog)
        assert entry.log_id.startswith("audit_")
        # The log should NOT be in self.logs (it only appends to self.logs
        # when db_path == ":memory:", otherwise it tries to persist).
        # However, _persist_log catches the error and does NOT append.
        # So self.logs should remain empty after a failed persist.
        assert len(al.logs) == 0


# ---------------------------------------------------------------------------
# TestGetLogs
# ---------------------------------------------------------------------------


class TestGetLogs:
    """Tests for get_logs() with various filters."""

    @pytest.fixture(autouse=True)
    def _populate(self, logger):
        """Create 5 diverse log entries."""
        logger.log(AuditAction.COURSE_CREATED, "course", "c1")
        logger.log(AuditAction.COURSE_UPDATED, "course", "c2")
        logger.log(AuditAction.COURSE_DELETED, "course", "c1")
        logger.log(AuditAction.SEMESTER_CREATED, "semester", "s1")
        logger.log(AuditAction.ENROLLMENT_ADDED, "enrollment", "e1")

    def test_get_logs_no_filter(self, logger):
        result = logger.get_logs()
        assert len(result) == 5

    def test_get_logs_filter_by_entity_type(self, logger):
        result = logger.get_logs(entity_type="course")
        assert all(log.entity_type == "course" for log in result)
        assert len(result) == 3

    def test_get_logs_filter_by_entity_id(self, logger):
        result = logger.get_logs(entity_id="c1")
        assert len(result) == 2
        assert all(log.entity_id == "c1" for log in result)

    def test_get_logs_filter_by_action(self, logger):
        result = logger.get_logs(action=AuditAction.COURSE_CREATED)
        assert len(result) == 1
        assert result[0].action == AuditAction.COURSE_CREATED

    def test_get_logs_filter_by_action_list(self, logger):
        result = logger.get_logs(
            action=[AuditAction.COURSE_CREATED, AuditAction.COURSE_UPDATED]
        )
        assert len(result) == 2
        actions = {log.action for log in result}
        assert actions == {AuditAction.COURSE_CREATED, AuditAction.COURSE_UPDATED}

    def test_get_logs_respects_limit(self, logger):
        result = logger.get_logs(limit=3)
        assert len(result) == 3

    def test_get_logs_combined_filters(self, logger):
        result = logger.get_logs(
            entity_type="course", action=AuditAction.COURSE_DELETED
        )
        assert len(result) == 1
        assert result[0].entity_id == "c1"


# ---------------------------------------------------------------------------
# TestGetLog
# ---------------------------------------------------------------------------


class TestGetLog:
    """Tests for get_log() by ID."""

    def test_get_log_found(self, logger):
        entry = logger.log(AuditAction.COURSE_CREATED, "course", "c1")
        found = logger.get_log(entry.log_id)
        assert found is not None
        assert found.log_id == entry.log_id

    def test_get_log_not_found(self, logger):
        assert logger.get_log("nonexistent_id") is None


# ---------------------------------------------------------------------------
# TestClear
# ---------------------------------------------------------------------------


class TestClear:
    """Tests for clear()."""

    def test_clear_removes_all_logs(self, logger):
        logger.log(AuditAction.COURSE_CREATED, "course", "c1")
        logger.log(AuditAction.COURSE_UPDATED, "course", "c2")
        assert len(logger.logs) == 2
        logger.clear()
        assert len(logger.logs) == 0

    def test_clear_empty_logger(self, logger):
        logger.clear()
        assert len(logger.logs) == 0


# ---------------------------------------------------------------------------
# TestExportLogs
# ---------------------------------------------------------------------------


class TestExportLogs:
    """Tests for export_logs()."""

    def test_export_logs_creates_json_file(self, logger, tmp_path):
        logger.log(AuditAction.COURSE_CREATED, "course", "c1", details={"key": "val"})
        logger.log(AuditAction.COURSE_DELETED, "course", "c1")
        out_file = str(tmp_path / "audit_export.json")
        logger.export_logs(out_file)
        with open(out_file) as f:
            data = json.load(f)
        assert len(data) == 2
        assert data[0]["action"] == "course_created"
        assert data[0]["details"] == {"key": "val"}

    def test_export_logs_empty(self, logger, tmp_path):
        out_file = str(tmp_path / "empty_export.json")
        logger.export_logs(out_file)
        with open(out_file) as f:
            data = json.load(f)
        assert data == []

    def test_export_logs_model_dump_fields(self, logger, tmp_path):
        logger.log(
            AuditAction.ENROLLMENT_ADDED,
            "enrollment",
            "e1",
            user_id="u1",
            ip_address="1.2.3.4",
            user_agent="UA",
        )
        out_file = str(tmp_path / "fields_export.json")
        logger.export_logs(out_file)
        with open(out_file) as f:
            data = json.load(f)
        entry = data[0]
        # Verify all expected fields are present
        expected_keys = {
            "log_id",
            "action",
            "entity_type",
            "entity_id",
            "user_id",
            "details",
            "ip_address",
            "user_agent",
            "created_at",
        }
        assert expected_keys.issubset(entry.keys())
        assert entry["user_id"] == "u1"
        assert entry["ip_address"] == "1.2.3.4"
        assert entry["user_agent"] == "UA"


# ---------------------------------------------------------------------------
# TestGetAuditLogger
# ---------------------------------------------------------------------------


class TestGetAuditLogger:
    """Tests for the get_audit_logger() singleton accessor."""

    def test_get_audit_logger_returns_instance(self):
        result = get_audit_logger()
        assert isinstance(result, AuditLogger)

    def test_get_audit_logger_singleton(self):

        # Ensure global is not None, then verify same instance
        first = get_audit_logger()
        second = get_audit_logger()
        assert first is second

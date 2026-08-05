# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Extended tests for the database module.
Erweiterte Tests für das Datenbankmodul.

EN: Unit tests covering connection lifecycle, semester CRUD, enrollment CRUD,
    course delete/archive/restore, filtered listing, and singleton accessors.
DE: Unit-Tests für Verbindungslebenszyklus, Semester-CRUD, Einschreibungs-CRUD,
    Kurs-Löschung/Archivierung/Wiederherstellung, gefilterte Auflistung und Singleton-Zugriff.
"""

from __future__ import annotations

import sqlite3

import pytest

from database import Database, DatabaseConfig, get_database, reset_database


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def database():
    """Fresh in-memory database for each test."""
    db = Database(DatabaseConfig(db_path=":memory:"))
    db.connect()
    yield db
    db.close()


@pytest.fixture
def sample_semester(database):
    """Create a sample semester for prerequisite data."""
    return database.create_semester(
        {
            "semester_id": "2026ws",
            "name": "Wintersemester 2026/27",
            "name_en": "Winter Semester 2026/27",
            "start_date": "2026-10-01",
            "end_date": "2027-03-31",
        }
    )


@pytest.fixture
def sample_course(database, sample_semester):
    """Create a sample course (requires semester first)."""
    return database.create_course(
        {
            "semester_id": sample_semester["semester_id"],
            "title": "Test Course",
            "course_code": "TEST-101",
            "lms": "ilias",
            "instructor_ids": ["prof-001"],
            "expected_enrollment": 30,
        }
    )


# ---------------------------------------------------------------------------
# TestDatabaseConnection
# ---------------------------------------------------------------------------


class TestDatabaseConnection:
    """Tests for connect(), close(), and connection management."""

    def test_connect_memory(self):
        db = Database(DatabaseConfig(db_path=":memory:"))
        db.connect()
        assert db._connection is not None
        db.close()

    def test_connect_creates_tables(self, database):
        with database.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
            )
            tables = {row[0] for row in cursor.fetchall()}
        assert "courses" in tables
        assert "semesters" in tables
        assert "enrollments" in tables
        assert "audit_logs" in tables

    def test_close(self, database):
        database.close()
        assert database._connection is None

    def test_close_without_connect(self):
        db = Database()
        db.close()  # should not raise
        assert db._connection is None

    def test_get_connection_auto_connects(self):
        db = Database(DatabaseConfig(db_path=":memory:"))
        assert db._connection is None
        with db.get_connection() as conn:
            assert conn is not None
        db.close()

    def test_echo_mode(self):
        db = Database(DatabaseConfig(db_path=":memory:", echo=True))
        db.connect()
        # The trace callback should be set (sqlite3 internal detail)
        assert db._connection is not None
        db.close()


# ---------------------------------------------------------------------------
# TestSemesterCRUD
# ---------------------------------------------------------------------------


class TestSemesterCRUD:
    """Tests for semester create, get, list operations."""

    def test_create_semester(self, database):
        result = database.create_semester(
            {
                "semester_id": "2026ss",
                "name": "Sommersemester 2026",
                "start_date": "2026-04-01",
                "end_date": "2026-09-30",
            }
        )
        assert result["semester_id"] == "2026ss"
        assert result["name"] == "Sommersemester 2026"
        assert result["start_date"] == "2026-04-01"
        assert result["end_date"] == "2026-09-30"
        assert "created_at" in result

    def test_create_semester_with_optional_fields(self, database):
        result = database.create_semester(
            {
                "semester_id": "2026ws",
                "name": "WS 26/27",
                "name_en": "Winter Semester 26/27",
                "start_date": "2026-10-01",
                "end_date": "2027-03-31",
                "enrollment_start": "2026-09-01",
                "enrollment_end": "2026-10-15",
            }
        )
        assert result["name_en"] == "Winter Semester 26/27"
        assert result["enrollment_start"] == "2026-09-01"
        assert result["enrollment_end"] == "2026-10-15"

    def test_get_semester(self, database, sample_semester):
        result = database.get_semester("2026ws")
        assert result is not None
        assert result["semester_id"] == "2026ws"

    def test_get_semester_not_found(self, database):
        assert database.get_semester("nonexistent") is None

    def test_list_semesters(self, database):
        database.create_semester(
            {
                "semester_id": "2025ss",
                "name": "SS 2025",
                "start_date": "2025-04-01",
                "end_date": "2025-09-30",
            }
        )
        database.create_semester(
            {
                "semester_id": "2026ws",
                "name": "WS 26/27",
                "start_date": "2026-10-01",
                "end_date": "2027-03-31",
            }
        )
        database.create_semester(
            {
                "semester_id": "2026ss",
                "name": "SS 2026",
                "start_date": "2026-04-01",
                "end_date": "2026-09-30",
            }
        )
        result = database.list_semesters()
        assert len(result) == 3
        # Ordered by start_date DESC
        assert result[0]["semester_id"] == "2026ws"

    def test_create_semester_default_status(self, database):
        result = database.create_semester(
            {
                "semester_id": "2027ss",
                "name": "SS 2027",
                "start_date": "2027-04-01",
                "end_date": "2027-09-30",
            }
        )
        assert result["status"] == "upcoming"


# ---------------------------------------------------------------------------
# TestEnrollmentCRUD
# ---------------------------------------------------------------------------


class TestEnrollmentCRUD:
    """Tests for enrollment create, get, list, update operations."""

    def test_create_enrollment(self, database, sample_course):
        result = database.create_enrollment(
            {
                "course_id": sample_course["course_id"],
                "user_id": "student-001",
                "role": "student",
            }
        )
        assert "enrollment_id" in result
        assert result["enrollment_id"].startswith("enr_")
        assert result["course_id"] == sample_course["course_id"]
        assert result["user_id"] == "student-001"

    def test_get_enrollment(self, database, sample_course):
        created = database.create_enrollment(
            {
                "course_id": sample_course["course_id"],
                "user_id": "student-001",
            }
        )
        result = database.get_enrollment(created["enrollment_id"])
        assert result is not None
        assert result["user_id"] == "student-001"

    def test_get_enrollment_not_found(self, database):
        assert database.get_enrollment("nonexistent") is None

    def test_list_enrollments(self, database, sample_course):
        cid = sample_course["course_id"]
        database.create_enrollment({"course_id": cid, "user_id": "u1"})
        database.create_enrollment({"course_id": cid, "user_id": "u2"})
        database.create_enrollment({"course_id": cid, "user_id": "u3"})
        result = database.list_enrollments(cid)
        assert len(result) == 3

    def test_update_enrollment_status(self, database, sample_course):
        created = database.create_enrollment(
            {
                "course_id": sample_course["course_id"],
                "user_id": "student-001",
                "status": "active",
            }
        )
        updated = database.update_enrollment(
            created["enrollment_id"], {"status": "completed"}
        )
        assert updated["status"] == "completed"
        assert "updated_at" in updated

    def test_update_enrollment_no_changes(self, database, sample_course):
        created = database.create_enrollment(
            {
                "course_id": sample_course["course_id"],
                "user_id": "student-001",
            }
        )
        original_status = created["status"]
        result = database.update_enrollment(created["enrollment_id"], {})
        assert result["status"] == original_status

    def test_enrollment_unique_constraint(self, database, sample_course):
        cid = sample_course["course_id"]
        database.create_enrollment({"course_id": cid, "user_id": "u-dup"})
        with pytest.raises(sqlite3.IntegrityError):
            database.create_enrollment({"course_id": cid, "user_id": "u-dup"})


# ---------------------------------------------------------------------------
# TestCourseDeleteArchiveRestore
# ---------------------------------------------------------------------------


class TestCourseDeleteArchiveRestore:
    """Tests for course soft-delete, archive, and restore."""

    def test_delete_course(self, database, sample_course):
        deleted = database.delete_course(sample_course["course_id"])
        assert deleted is True
        course = database.get_course(sample_course["course_id"])
        assert course["status"] == "deleted"

    def test_delete_nonexistent_course(self, database):
        assert database.delete_course("nonexistent") is False

    def test_archive_course(self, database, sample_course):
        result = database.archive_course(sample_course["course_id"])
        assert result is not None
        assert result["status"] == "archived"
        assert result["archived_at"] is not None

    def test_archive_already_archived(self, database, sample_course):
        database.archive_course(sample_course["course_id"])
        result = database.archive_course(sample_course["course_id"])
        assert result is None

    def test_restore_course(self, database, sample_course):
        database.archive_course(sample_course["course_id"])
        result = database.restore_course(sample_course["course_id"])
        assert result is not None
        assert result["status"] == "active"
        assert result["archived_at"] is None

    def test_restore_non_archived(self, database, sample_course):
        result = database.restore_course(sample_course["course_id"])
        assert result is None

    def test_restore_nonexistent(self, database):
        assert database.restore_course("nonexistent") is None


# ---------------------------------------------------------------------------
# TestListCoursesWithFilters
# ---------------------------------------------------------------------------


class TestListCoursesWithFilters:
    """Tests for list_courses() with various filters and pagination."""

    @pytest.fixture(autouse=True)
    def _populate(self, database):
        """Create prerequisite semester and 5 diverse courses."""
        database.create_semester(
            {
                "semester_id": "2026ws",
                "name": "WS 26/27",
                "start_date": "2026-10-01",
                "end_date": "2027-03-31",
            }
        )
        database.create_semester(
            {
                "semester_id": "2026ss",
                "name": "SS 2026",
                "start_date": "2026-04-01",
                "end_date": "2026-09-30",
            }
        )
        database.create_course(
            {
                "semester_id": "2026ws",
                "title": "ILIAS Course 1",
                "course_code": "ILIAS-101",
                "lms": "ilias",
                "status": "active",
            }
        )
        database.create_course(
            {
                "semester_id": "2026ws",
                "title": "Moodle Course 1",
                "course_code": "MOODLE-101",
                "lms": "moodle",
                "status": "active",
            }
        )
        database.create_course(
            {
                "semester_id": "2026ss",
                "title": "ILIAS Course 2",
                "course_code": "ILIAS-201",
                "lms": "ilias",
                "status": "active",
            }
        )
        course4 = database.create_course(
            {
                "semester_id": "2026ss",
                "title": "Archived Course",
                "course_code": "ARCH-101",
                "lms": "moodle",
                "status": "active",
            }
        )
        database.archive_course(course4["course_id"])
        database.create_course(
            {
                "semester_id": "2026ws",
                "title": "Another ILIAS",
                "course_code": "ILIAS-301",
                "lms": "ilias",
                "status": "active",
            }
        )

    def test_list_courses_no_filter(self, database):
        courses, total = database.list_courses()
        assert total == 5
        assert len(courses) == 5

    def test_list_courses_filter_by_semester(self, database):
        courses, total = database.list_courses(semester_id="2026ws")
        assert total == 3
        assert all(c["semester_id"] == "2026ws" for c in courses)

    def test_list_courses_filter_by_status(self, database):
        courses, total = database.list_courses(status="active")
        assert total == 4
        assert all(c["status"] == "active" for c in courses)

    def test_list_courses_filter_by_lms(self, database):
        courses, total = database.list_courses(lms="moodle")
        assert total == 2
        assert all(c["lms"] == "moodle" for c in courses)

    def test_list_courses_pagination(self, database):
        courses, total = database.list_courses(page_size=2, page=1)
        assert total == 5
        assert len(courses) == 2

    def test_list_courses_pagination_page2(self, database):
        page1, _ = database.list_courses(page_size=2, page=1)
        page2, _ = database.list_courses(page_size=2, page=2)
        # Pages should have different course IDs
        page1_ids = {c["course_id"] for c in page1}
        page2_ids = {c["course_id"] for c in page2}
        assert page1_ids.isdisjoint(page2_ids)

    def test_list_courses_combined_filters(self, database):
        courses, total = database.list_courses(
            semester_id="2026ws", lms="ilias", status="active"
        )
        assert total == 2
        for c in courses:
            assert c["semester_id"] == "2026ws"
            assert c["lms"] == "ilias"
            assert c["status"] == "active"


# ---------------------------------------------------------------------------
# TestDatabaseSingletons
# ---------------------------------------------------------------------------


class TestDatabaseSingletons:
    """Tests for get_database() and reset_database() singletons."""

    def setup_method(self):
        """Ensure clean global state before each test."""
        reset_database()

    def teardown_method(self):
        """Clean up global state after each test."""
        reset_database()

    def test_get_database_creates_instance(self):
        db = get_database()
        assert isinstance(db, Database)
        assert db._connection is not None

    def test_get_database_returns_same_instance(self):
        first = get_database()
        second = get_database()
        assert first is second

    def test_reset_database(self):
        db = get_database()
        assert db is not None
        reset_database()
        import database as _db_mod

        assert _db_mod._db is None

    def test_reset_and_recreate(self):
        db1 = get_database()
        reset_database()
        db2 = get_database()
        assert db1 is not db2

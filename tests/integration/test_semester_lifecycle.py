# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Integration tests for Semester Lifecycle Management.
Integrationstests für das Semester-Lebenszyklus-Management.

EN: This module provides comprehensive integration tests for the semester lifecycle management feature,
including course provisioning, role synchronization, semester transitions, archival workflows, and CLI commands.
All external services (ILIAS, Moodle, Keycloak) are mocked to ensure tests run without real dependencies.

DE: Dieses Modul bietet umfassende Integrationstests für das Semester-Lebenszyklus-Management-Feature,
einschließlich Kursverwaltung, Rollensynchronisierung, Semesterübergänge, Archivierungsworkflows und CLI-Befehle.
Alle externen Dienste (ILIAS, Moodle, Keycloak) werden gemockt, um sicherzustellen, dass Tests ohne echte Abhängigkeiten laufen.
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
from datetime import date, datetime, timezone
from pathlib import Path
from unittest import mock

import pytest
import yaml

from fastapi.testclient import TestClient


# =============================================================================
# FIXTURES
# =============================================================================


@pytest.fixture
def test_config():
    """
    Create a test semester configuration.
    Erstellt eine Test-Semesterkonfiguration.
    """
    return {
        "enabled": True,
        "current": {
            "name": "WS25/26",
            "type": "wintersemester",
            "start_date": "2025-10-01",
            "end_date": "2026-03-31",
            "phases": {
                "enrollment": {"start": "2025-07-01", "end": "2025-09-30"},
                "teaching": {"start": "2025-10-15", "end": "2026-02-28"},
                "exam": {"start": "2026-03-01", "end": "2026-03-31"},
                "archival": {"deadline": "2026-04-15"},
            },
        },
        "automation": {"enabled": True, "timezone": "Europe/Berlin"},
        "provisioning": {
            "default_category": "courses",
            "course_prefix": "",
            "auto_archive": True,
            "archive_retention_years": 5,
        },
        "roles": {
            "sync_on_enrollment_change": True,
            "sync_interval_minutes": 15,
            "role_mappings": [
                {
                    "campus_role": "student",
                    "keycloak_role": "student",
                    "lms_role": "student",
                },
                {"campus_role": "tutor", "keycloak_role": "tutor", "lms_role": "tutor"},
                {
                    "campus_role": "lecturer",
                    "keycloak_role": "instructor",
                    "lms_role": "instructor",
                },
            ],
        },
    }


@pytest.fixture
def config_file(test_config, tmp_path):
    """
    Create a temporary config file for testing.
    Erstellt eine temporäre Konfigurationsdatei für Tests.
    """
    config_path = tmp_path / "semester-config.yaml"
    with open(config_path, "w") as f:
        yaml.dump({"semester": test_config}, f)
    return str(config_path)


@pytest.fixture
def mock_ilias_client():
    """
    Mock ILIAS client for testing.
    Mock-ILIAS-Client für Tests.
    """

    class MockILIASClient:
        def __init__(self):
            self.calls = []
            self.courses = {}

        def create_course(self, title, semester_id, **kwargs):
            course_id = f"ilias_{len(self.courses) + 1}"
            self.courses[course_id] = {
                "id": course_id,
                "title": title,
                "semester_id": semester_id,
                **kwargs,
            }
            self.calls.append(("create_course", title, semester_id, kwargs))
            return course_id

        def set_read_only(self, course_id):
            self.calls.append(("set_read_only", course_id))
            return 0

        def restore_write_access(self, course_id):
            self.calls.append(("restore_write_access", course_id))
            return 0

        def set_user_roles(self, user_id, roles):
            self.calls.append(("set_user_roles", user_id, roles))
            return True

    return MockILIASClient()


@pytest.fixture
def mock_moodle_client():
    """
    Mock Moodle client for testing.
    Mock-Moodle-Client für Tests.
    """

    class MockMoodleClient:
        def __init__(self):
            self.calls = []
            self.courses = {}

        def create_course(self, title, semester_id, **kwargs):
            course_id = f"moodle_{len(self.courses) + 1}"
            self.courses[course_id] = {
                "id": course_id,
                "title": title,
                "semester_id": semester_id,
                **kwargs,
            }
            self.calls.append(("create_course", title, semester_id, kwargs))
            return course_id

        def set_read_only(self, course_id):
            self.calls.append(("set_read_only", course_id))
            return 0

        def restore_write_access(self, course_id):
            self.calls.append(("restore_write_access", course_id))
            return 0

        def set_user_roles(self, user_id, roles):
            self.calls.append(("set_user_roles", user_id, roles))
            return True

    return MockMoodleClient()


@pytest.fixture
def mock_keycloak_client():
    """
    Mock Keycloak client for testing.
    Mock-Keycloak-Client für Tests.
    """

    class MockKeycloakClient:
        def __init__(self):
            self.calls = []
            self.users = {
                "user-001": {"id": "user-001", "realm_roles": ["student"]},
                "user-002": {"id": "user-002", "realm_roles": ["lecturer"]},
                "user-003": {"id": "user-003", "realm_roles": ["tutor"]},
                "user-004": {"id": "user-004", "realm_roles": ["student", "tutor"]},
            }

        def get_user(self, user_id):
            self.calls.append(("get_user", user_id))
            return self.users.get(user_id)

        def get_user_roles(self, user_id):
            self.calls.append(("get_user_roles", user_id))
            user = self.users.get(user_id)
            return user["realm_roles"] if user else []

        def add_user_role(self, user_id, role):
            self.calls.append(("add_user_role", user_id, role))
            if user_id in self.users:
                if role not in self.users[user_id]["realm_roles"]:
                    self.users[user_id]["realm_roles"].append(role)
            return True

        def remove_user_role(self, user_id, role):
            self.calls.append(("remove_user_role", user_id, role))
            if user_id in self.users:
                if role in self.users[user_id]["realm_roles"]:
                    self.users[user_id]["realm_roles"].remove(role)
            return True

    return MockKeycloakClient()


@pytest.fixture
def api_client():
    """
    Create a test client for the Course Provisioning API.
    Erstellt einen Test-Client für die Kursverwaltungs-API.
    """
    # Import here to avoid circular imports
    from course_api import create_app

    test_app = create_app()
    return TestClient(app=test_app)


@pytest.fixture
def database():
    """
    Create an in-memory database for testing.
    Erstellt eine In-Memory-Datenbank für Tests.
    """
    # Import here to avoid circular imports
    sys.path.insert(
        0, str(Path(__file__).parent.parent / "scripts" / "semester-provisioning")
    )
    from database import Database, DatabaseConfig

    db = Database(DatabaseConfig(db_path=":memory:"))
    db.connect()
    yield db
    db.close()


@pytest.fixture
def audit_logger():
    """
    Create an in-memory audit logger for testing.
    Erstellt einen In-Memory-Audit-Logger für Tests.
    """
    sys.path.insert(
        0, str(Path(__file__).parent.parent / "scripts" / "semester-provisioning")
    )
    from audit import AuditLogger

    return AuditLogger(db_path=":memory:")


@pytest.fixture
def semester_manager(config_file, database):
    """
    Create a SemesterManager instance for testing.
    Erstellt eine SemesterManager-Instanz für Tests.
    """
    sys.path.insert(
        0, str(Path(__file__).parent.parent / "scripts" / "semester-provisioning")
    )
    from semester_manager import SemesterManager
    from config import reset_semester_config

    reset_semester_config()
    mgr = SemesterManager(config_path=config_file, database=database)
    yield mgr
    reset_semester_config()


# =============================================================================
# COURSE PROVISIONING END-TO-END TESTS
# =============================================================================


class TestCourseProvisioningE2E:
    """
    End-to-end tests for course provisioning.
    End-to-End-Tests für die Kursbereitstellung.
    """

    def test_create_course_on_ilias(self, api_client, mock_ilias_client):
        """
        Test creating a course with ILIAS LMS.
        Testen, ob ein Kurs mit ILIAS LMS erstellt wird.
        """
        course_data = {
            "semester_id": "WS25/26",
            "title": "Einführung in Informatik",
            "title_en": "Introduction to Computer Science",
            "course_code": "INF-101",
            "instructor_ids": ["user-002"],
            "expected_enrollment": 120,
            "lms": "ilias",
        }

        response = api_client.post("/api/v1/courses", json=course_data)
        assert response.status_code == 201

        data = response.json()
        assert data["course_id"].startswith("crs_")
        assert data["semester_id"] == "WS25/26"
        assert data["title"] == "Einführung in Informatik"
        assert data["lms"] == "ilias"
        assert data["status"] == "draft"

    def test_create_course_on_moodle(self, api_client):
        """
        Test creating a course with Moodle LMS.
        Testen, ob ein Kurs mit Moodle LMS erstellt wird.
        """
        course_data = {
            "semester_id": "SS26",
            "title": "Datenbanken",
            "title_en": "Databases",
            "course_code": "DB-201",
            "instructor_ids": ["user-002"],
            "expected_enrollment": 45,
            "lms": "moodle",
        }

        response = api_client.post("/api/v1/courses", json=course_data)
        assert response.status_code == 201

        data = response.json()
        assert data["lms"] == "moodle"
        assert data["status"] == "draft"

    def test_course_provisioning_with_enrollments(self, api_client):
        """
        Test creating a course and enrolling users.
        Testen, ob ein Kurs erstellt und Benutzer eingeschrieben werden.
        """
        # Create course
        course_data = {
            "semester_id": "WS25/26",
            "title": "Software Engineering",
            "title_en": "Software Engineering",
            "course_code": "SE-301",
            "instructor_ids": ["user-002"],
            "lms": "ilias",
        }

        create_resp = api_client.post("/api/v1/courses", json=course_data)
        assert create_resp.status_code == 201
        course_id = create_resp.json()["course_id"]

        # Enroll users
        enrollment_data = {
            "user_ids": ["user-001", "user-003", "user-004"],
            "role": "student",
        }

        enroll_resp = api_client.post(
            f"/api/v1/courses/{course_id}/enrollments", json=enrollment_data
        )
        assert enroll_resp.status_code == 201

        enrollments = enroll_resp.json()
        assert len(enrollments) == 3
        for enr in enrollments:
            assert enr["role"] == "student"
            assert enr["status"] == "active"

    def test_course_activation_workflow(self, api_client):
        """
        Test activating a course after creation.
        Testen, ob ein Kurs nach der Erstellung aktiviert wird.
        """
        # Create course in draft status
        course_data = {
            "semester_id": "WS25/26",
            "title": "Algorithms",
            "title_en": "Algorithms",
            "course_code": "ALG-101",
            "instructor_ids": ["user-002"],
            "lms": "ilias",
        }

        create_resp = api_client.post("/api/v1/courses", json=course_data)
        course_id = create_resp.json()["course_id"]
        assert create_resp.json()["status"] == "draft"

        # Activate the course
        update_resp = api_client.put(
            f"/api/v1/courses/{course_id}", json={"status": "active"}
        )
        assert update_resp.status_code == 200
        assert update_resp.json()["status"] == "active"


# =============================================================================
# ROLE SYNCHRONIZATION TESTS
# =============================================================================


class TestRoleSynchronization:
    """
    Tests for role synchronization across platforms.
    Tests für die Rollensynchronisierung über Plattformen hinweg.
    """

    def test_role_sync_basic_mapping(self, mock_keycloak_client, mock_ilias_client):
        """
        Test basic role mapping from Keycloak to LMS.
        Testen des grundlegenden Rollenmappings von Keycloak zum LMS.
        """
        # Import role sync module
        sys.path.insert(
            0,
            str(
                Path(__file__).parent.parent
                / "scripts"
                / "semester-provisioning"
                / "sync"
            ),
        )
        from role_sync import RoleSyncEngine, KCUser

        engine = RoleSyncEngine(
            lms_client=mock_ilias_client,
            kc_client=mock_keycloak_client,
            mapping={"student": "student", "tutor": "tutor", "lecturer": "instructor"},
        )

        # Sync a student
        kc_users = [KCUser(id="user-001", realm_roles=["student"])]
        results = engine.sync(kc_users)

        assert len(results) == 1
        assert results[0].id == "user-001"
        assert results[0].roles == ["student"]
        assert ("set_user_roles", "user-001", ["student"]) in mock_ilias_client.calls

    def test_role_sync_lecturer_to_instructor(
        self, mock_keycloak_client, mock_ilias_client
    ):
        """
        Test mapping lecturer role to instructor.
        Testen des Mappings der Lecturer-Rolle zu Instructor.
        """
        sys.path.insert(
            0,
            str(
                Path(__file__).parent.parent
                / "scripts"
                / "semester-provisioning"
                / "sync"
            ),
        )
        from role_sync import RoleSyncEngine, KCUser

        engine = RoleSyncEngine(
            lms_client=mock_ilias_client,
            kc_client=mock_keycloak_client,
            mapping={"student": "student", "tutor": "tutor", "lecturer": "instructor"},
        )

        kc_users = [KCUser(id="user-002", realm_roles=["lecturer"])]
        results = engine.sync(kc_users)

        assert results[0].roles == ["instructor"]

    def test_role_sync_multiple_roles(self, mock_keycloak_client, mock_ilias_client):
        """
        Test syncing a user with multiple roles.
        Testen der Synchronisierung eines Benutzers mit mehreren Rollen.
        """
        sys.path.insert(
            0,
            str(
                Path(__file__).parent.parent
                / "scripts"
                / "semester-provisioning"
                / "sync"
            ),
        )
        from role_sync import RoleSyncEngine, KCUser

        engine = RoleSyncEngine(
            lms_client=mock_ilias_client,
            kc_client=mock_keycloak_client,
            mapping={"student": "student", "tutor": "tutor", "lecturer": "instructor"},
        )

        # User with both student and tutor roles
        kc_users = [KCUser(id="user-004", realm_roles=["student", "tutor"])]
        results = engine.sync(kc_users)

        assert len(results[0].roles) == 2
        assert "student" in results[0].roles
        assert "tutor" in results[0].roles

    def test_role_sync_ignores_unmapped_roles(
        self, mock_keycloak_client, mock_ilias_client
    ):
        """
        Test that unmapped roles are ignored.
        Testen, dass nicht gemappte Rollen ignoriert werden.
        """
        sys.path.insert(
            0,
            str(
                Path(__file__).parent.parent
                / "scripts"
                / "semester-provisioning"
                / "sync"
            ),
        )
        from role_sync import RoleSyncEngine, KCUser

        engine = RoleSyncEngine(
            lms_client=mock_ilias_client,
            kc_client=mock_keycloak_client,
            mapping={"student": "student"},
        )

        # User with unmapped role
        kc_users = [KCUser(id="user-005", realm_roles=["admin", "student"])]
        results = engine.sync(kc_users)

        # Only student should be mapped
        assert results[0].roles == ["student"]

    def test_role_sync_empty_roles(self, mock_keycloak_client, mock_ilias_client):
        """
        Test syncing a user with no roles.
        Testen der Synchronisierung eines Benutzers ohne Rollen.
        """
        sys.path.insert(
            0,
            str(
                Path(__file__).parent.parent
                / "scripts"
                / "semester-provisioning"
                / "sync"
            ),
        )
        from role_sync import RoleSyncEngine, KCUser

        engine = RoleSyncEngine(
            lms_client=mock_ilias_client, kc_client=mock_keycloak_client
        )

        kc_users = [KCUser(id="user-006", realm_roles=[])]
        results = engine.sync(kc_users)

        assert results[0].roles == []


# =============================================================================
# SEMESTER TRANSITION WORKFLOW TESTS
# =============================================================================


class TestSemesterTransitionWorkflow:
    """
    Tests for semester transition workflows.
    Tests für Semesterübergangsworkflows.
    """

    def test_semester_transition_dry_run(self, semester_manager):
        """
        Test semester transition in dry-run mode.
        Testen des Semesterübergangs im Dry-Run-Modus.
        """
        report = semester_manager.transition_semester(
            old_semester="WS24/25", new_semester="WS25/26", dry_run=True
        )

        assert report.success is True
        assert report.old_semester == "WS24/25"
        assert report.new_semester == "WS25/26"
        assert report.archived_courses == []
        assert report.errors == []

    def test_semester_transition_archives_courses(
        self, semester_manager, database, audit_logger
    ):
        """
        Test that semester transition archives old courses.
        Testen, ob der Semesterübergang alte Kurse archiviert.
        """
        # Create courses in old semester
        for i in range(3):
            database.create_course(
                {
                    "semester_id": "WS24/25",
                    "title": f"Old Course {i}",
                    "course_code": f"OLD-{i}",
                    "lms": "ilias",
                    "status": "active",
                }
            )

        # Perform transition
        report = semester_manager.transition_semester(
            old_semester="WS24/25", new_semester="WS25/26", dry_run=False
        )

        assert report.old_semester == "WS24/25"
        assert report.new_semester == "WS25/26"

    def test_semester_phase_detection_enrollment(self, semester_manager):
        """
        Test detecting enrollment phase.
        Testen der Erkennung der Einschreibungsphase.
        """
        phase = semester_manager.get_semester_phase(check_date=date(2025, 8, 15))
        assert phase is not None
        assert phase.value == "enrollment"

    def test_semester_phase_detection_teaching(self, semester_manager):
        """
        Test detecting teaching phase.
        Testen der Erkennung der Lehrphase.
        """
        phase = semester_manager.get_semester_phase(check_date=date(2025, 11, 15))
        assert phase is not None
        assert phase.value == "teaching"

    def test_semester_phase_detection_exam(self, semester_manager):
        """
        Test detecting exam phase.
        Testen der Erkennung der Prüfungsphase.
        """
        phase = semester_manager.get_semester_phase(check_date=date(2026, 3, 15))
        assert phase is not None
        assert phase.value == "exam"

    def test_semester_phase_detection_archival(self, semester_manager):
        """
        Test detecting archival phase.
        Testen der Erkennung der Archivierungsphase.
        """
        phase = semester_manager.get_semester_phase(check_date=date(2026, 4, 1))
        assert phase is not None
        assert phase.value == "archival"

    def test_get_all_phases(self, semester_manager):
        """
        Test retrieving all semester phases.
        Testen des Abrufs aller Semesterphasen.
        """
        phases = semester_manager.get_all_phases()

        assert "enrollment" in phases
        assert "teaching" in phases
        assert "exam" in phases
        assert "archival" in phases

        assert phases["enrollment"]["start"] == "2025-07-01"
        assert phases["enrollment"]["end"] == "2025-09-30"


# =============================================================================
# COURSE ARCHIVAL AND RESTORE WORKFLOW TESTS
# =============================================================================


class TestCourseArchivalRestoreWorkflow:
    """
    Tests for course archival and restore workflows.
    Tests für Kursarchivierungs- und Wiederherstellungsworkflows.
    """

    def test_archive_single_course(self, database, audit_logger):
        """
        Test archiving a single course.
        Testen der Archivierung eines einzelnen Kurses.
        """
        sys.path.insert(
            0, str(Path(__file__).parent.parent / "scripts" / "semester-provisioning")
        )
        from archival.archive_course import archive_course

        # Create a course
        course = database.create_course(
            {
                "semester_id": "WS25/26",
                "title": "Course to Archive",
                "course_code": "ARCH-101",
                "lms": "ilias",
                "status": "active",
            }
        )

        # Add enrollments
        database.create_enrollment(
            {
                "course_id": course["course_id"],
                "user_id": "student-001",
                "role": "student",
                "status": "active",
            }
        )

        # Archive the course
        result = archive_course(
            course["course_id"],
            database=database,
            audit_logger=audit_logger,
            create_snapshot=True,
        )

        assert result.success is True
        assert result.snapshot is not None
        assert result.frozen_enrollments == 1

    def test_archive_course_with_ilias_client(
        self, database, audit_logger, mock_ilias_client
    ):
        """
        Test archiving a course with ILIAS client.
        Testen der Archivierung eines Kurses mit ILIAS-Client.
        """
        sys.path.insert(
            0, str(Path(__file__).parent.parent / "scripts" / "semester-provisioning")
        )
        from archival.archive_course import archive_course

        course = database.create_course(
            {
                "semester_id": "WS25/26",
                "title": "ILIAS Course to Archive",
                "course_code": "ILIAS-ARCH-101",
                "lms": "ilias",
                "lms_course_id": "ilias_123",
                "status": "active",
            }
        )

        result = archive_course(
            course["course_id"],
            database=database,
            audit_logger=audit_logger,
            ilias_client=mock_ilias_client,
        )

        assert result.success is True
        # Verify ILIAS client was called
        assert any(call[0] == "set_read_only" for call in mock_ilias_client.calls)

    def test_archive_course_already_archived(self, database, audit_logger):
        """
        Test archiving an already archived course.
        Testen der Archivierung eines bereits archivierten Kurses.
        """
        sys.path.insert(
            0, str(Path(__file__).parent.parent / "scripts" / "semester-provisioning")
        )
        from archival.archive_course import archive_course

        course = database.create_course(
            {
                "semester_id": "WS25/26",
                "title": "Already Archived",
                "course_code": "DONE-101",
                "lms": "ilias",
                "status": "archived",
            }
        )

        result = archive_course(
            course["course_id"],
            database=database,
            audit_logger=audit_logger,
        )

        assert result.success is False
        assert "already archived" in result.error.lower()

    def test_restore_archived_course(self, database, audit_logger):
        """
        Test restoring an archived course.
        Testen der Wiederherstellung eines archivierten Kurses.
        """
        sys.path.insert(
            0, str(Path(__file__).parent.parent / "scripts" / "semester-provisioning")
        )
        from archival.archive_course import archive_course
        from archival.restore_course import restore_course

        # Create and archive a course
        course = database.create_course(
            {
                "semester_id": "WS25/26",
                "title": "Course to Restore",
                "course_code": "REST-101",
                "lms": "ilias",
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

        # Archive it
        archive_result = archive_course(
            course["course_id"],
            database=database,
            audit_logger=audit_logger,
        )
        assert archive_result.success is True

        # Restore it
        restore_result = restore_course(
            course["course_id"],
            database=database,
            audit_logger=audit_logger,
        )

        assert restore_result.success is True
        assert restore_result.restored_enrollments == 1

    def test_restore_non_archived_course(self, database, audit_logger):
        """
        Test restoring a non-archived course fails.
        Testen, dass die Wiederherstellung eines nicht archivierten Kurses fehlschlägt.
        """
        sys.path.insert(
            0, str(Path(__file__).parent.parent / "scripts" / "semester-provisioning")
        )
        from archival.restore_course import restore_course

        course = database.create_course(
            {
                "semester_id": "WS25/26",
                "title": "Active Course",
                "course_code": "ACTIVE-101",
                "lms": "ilias",
                "status": "active",
            }
        )

        result = restore_course(
            course["course_id"],
            database=database,
            audit_logger=audit_logger,
        )

        assert result.success is False
        assert (
            "nicht archiviert" in result.error.lower()
            or "not archived" in result.error.lower()
        )

    def test_bulk_archive_semester(self, database, audit_logger):
        """
        Test bulk archiving all courses in a semester.
        Testen der Massenarchivierung aller Kurse eines Semesters.
        """
        sys.path.insert(
            0, str(Path(__file__).parent.parent / "scripts" / "semester-provisioning")
        )
        from archival.bulk_archive import bulk_archive_semester

        # Create multiple courses
        for i in range(5):
            database.create_course(
                {
                    "semester_id": "WS24/25",
                    "title": f"Bulk Archive Course {i}",
                    "course_code": f"BULK-{i}",
                    "lms": "ilias",
                    "status": "active",
                }
            )

        summary = bulk_archive_semester(
            "WS24/25",
            database=database,
            audit_logger=audit_logger,
        )

        assert summary.success is True
        assert summary.total_courses == 5
        assert summary.archived_courses == 5
        assert summary.failed_courses == 0

    def test_bulk_archive_dry_run(self, database, audit_logger):
        """
        Test bulk archive dry run.
        Testen des Dry-Run der Massenarchivierung.
        """
        sys.path.insert(
            0, str(Path(__file__).parent.parent / "scripts" / "semester-provisioning")
        )
        from archival.bulk_archive import bulk_archive_semester

        # Create courses
        for i in range(3):
            database.create_course(
                {
                    "semester_id": "SS25",
                    "title": f"Dry Run Course {i}",
                    "course_code": f"DRY-{i}",
                    "lms": "moodle",
                    "status": "active",
                }
            )

        summary = bulk_archive_semester(
            "SS25",
            database=database,
            audit_logger=audit_logger,
            dry_run=True,
        )

        assert summary.skipped_courses == 3

        # Verify courses are still active
        courses, _ = database.list_courses(semester_id="SS25", status="active")
        assert len(courses) == 3


# =============================================================================
# CLI COMMANDS INTEGRATION TESTS
# =============================================================================


class TestCLICommandsIntegration:
    """
    Integration tests for CLI commands.
    Integrationstests für CLI-Befehle.
    """

    def test_cli_current_command(self, config_file):
        """
        Test CLI current semester command.
        Testen des CLI-Befehls für aktuelles Semester.
        """
        sys.path.insert(
            0, str(Path(__file__).parent.parent / "scripts" / "semester-provisioning")
        )
        from cli import cmd_current
        from config import reset_semester_config

        reset_semester_config()

        args = mock.MagicMock()
        args.config = config_file
        args.json = True
        args.date = "2025-12-01"

        with mock.patch("builtins.print") as mock_print:
            ret = cmd_current(args)

        assert ret == 0
        mock_print.assert_called_once()
        output = mock_print.call_args[0][0]
        data = json.loads(output)
        assert data["semester"]["name"] == "WS25/26"

        reset_semester_config()

    def test_cli_transition_command_dry_run(self, config_file):
        """
        Test CLI transition command with dry run.
        Testen des CLI-Übergangsbefehls mit Dry-Run.
        """
        sys.path.insert(
            0, str(Path(__file__).parent.parent / "scripts" / "semester-provisioning")
        )
        from cli import cmd_transition
        from config import reset_semester_config

        reset_semester_config()

        args = mock.MagicMock()
        args.config = config_file
        args.old = "WS24/25"
        args.new = "WS25/26"
        args.dry_run = True

        with mock.patch("builtins.print"):
            ret = cmd_transition(args)

        assert ret == 0
        reset_semester_config()

    def test_cli_phases_command(self, config_file):
        """
        Test CLI phases command.
        Testen des CLI-Phasenbefehls.
        """
        sys.path.insert(
            0, str(Path(__file__).parent.parent / "scripts" / "semester-provisioning")
        )
        from cli import cmd_phases
        from config import reset_semester_config

        reset_semester_config()

        args = mock.MagicMock()
        args.config = config_file
        args.json = True

        with mock.patch("builtins.print") as mock_print:
            ret = cmd_phases(args)

        assert ret == 0
        output = mock_print.call_args[0][0]
        data = json.loads(output)
        assert "phases" in data
        assert data["semester"] == "WS25/26"

        reset_semester_config()


# =============================================================================
# ERROR CASE TESTS
# =============================================================================


class TestErrorCases:
    """
    Tests for error handling and edge cases.
    Tests für Fehlerbehandlung und Randfälle.
    """

    def test_course_not_found(self, api_client):
        """
        Test retrieving a non-existent course.
        Testen des Abrufs eines nicht existierenden Kurses.
        """
        response = api_client.get("/api/v1/courses/nonexistent-course-id")
        assert response.status_code == 404

    def test_archive_nonexistent_course(self, database, audit_logger):
        """
        Test archiving a non-existent course.
        Testen der Archivierung eines nicht existierenden Kurses.
        """
        sys.path.insert(
            0, str(Path(__file__).parent.parent / "scripts" / "semester-provisioning")
        )
        from archival.archive_course import archive_course

        result = archive_course(
            "nonexistent-course",
            database=database,
            audit_logger=audit_logger,
        )

        assert result.success is False
        assert "not found" in result.error.lower()

    def test_restore_nonexistent_course(self, database, audit_logger):
        """
        Test restoring a non-existent course.
        Testen der Wiederherstellung eines nicht existierenden Kurses.
        """
        sys.path.insert(
            0, str(Path(__file__).parent.parent / "scripts" / "semester-provisioning")
        )
        from archival.restore_course import restore_course

        result = restore_course(
            "nonexistent-course",
            database=database,
            audit_logger=audit_logger,
        )

        assert result.success is False
        assert "not found" in result.error.lower()

    def test_enroll_nonexistent_course(self, api_client):
        """
        Test enrolling users to a non-existent course.
        Testen der Einschreibung von Benutzern zu einem nicht existierenden Kurs.
        """
        enrollment_data = {"user_ids": ["user-001"], "role": "student"}

        response = api_client.post(
            "/api/v1/courses/nonexistent/enrollments", json=enrollment_data
        )
        assert response.status_code == 404

    def test_create_course_missing_required_fields(self, api_client):
        """
        Test creating a course with missing required fields.
        Testen der Erstellung eines Kurses mit fehlenden Pflichtfeldern.
        """
        course_data = {
            "title": "Missing Fields Course",
            "lms": "ilias",
        }

        response = api_client.post("/api/v1/courses", json=course_data)
        assert response.status_code == 422

    def test_semester_manager_no_config(self, tmp_path):
        """
        Test SemesterManager with missing configuration.
        Testen des SemesterManagers mit fehlender Konfiguration.
        """
        sys.path.insert(
            0, str(Path(__file__).parent.parent / "scripts" / "semester-provisioning")
        )
        from semester_manager import SemesterManager
        from config import reset_semester_config

        reset_semester_config()

        mgr = SemesterManager(config_path=str(tmp_path / "nonexistent.yaml"))

        assert mgr._config is None
        assert mgr.get_current_semester() is None
        assert mgr.get_semester_phase() is None

        reset_semester_config()

    def test_api_health_check(self, api_client):
        """
        Test API health check endpoint.
        Testen des API-Health-Check-Endpunkts.
        """
        response = api_client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"

    def test_api_readiness_check(self, api_client):
        """
        Test API readiness check endpoint.
        Testen des API-Readiness-Check-Endpunkts.
        """
        response = api_client.get("/ready")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ready"


# =============================================================================
# AUDIT LOGGING INTEGRATION TESTS
# =============================================================================


class TestAuditLoggingIntegration:
    """
    Tests for audit logging integration.
    Tests für die Audit-Logging-Integration.
    """

    def test_course_creation_creates_audit_log(self, api_client):
        """
        Test that course creation creates an audit log entry.
        Testen, ob die Kurserstellung einen Audit-Log-Eintrag erstellt.
        """
        course_data = {
            "semester_id": "WS25/26",
            "title": "Audit Test Course",
            "title_en": "Audit Test Course",
            "course_code": "AUD-TEST-101",
            "instructor_ids": [],
            "lms": "ilias",
        }

        create_resp = api_client.post("/api/v1/courses", json=course_data)
        assert create_resp.status_code == 201

        # Check audit logs
        audit_resp = api_client.get("/api/v1/audit/logs")
        assert audit_resp.status_code == 200

        logs = audit_resp.json()["logs"]
        assert any(log["action"] == "course_created" for log in logs)

    def test_course_archival_creates_audit_log(self, api_client):
        """
        Test that course archival creates an audit log entry.
        Testen, ob die Kursarchivierung einen Audit-Log-Eintrag erstellt.
        """
        # Create a course
        course_data = {
            "semester_id": "WS25/26",
            "title": "Archive Audit Test",
            "title_en": "Archive Audit Test",
            "course_code": "ARCH-AUD-101",
            "instructor_ids": [],
            "lms": "ilias",
        }

        create_resp = api_client.post("/api/v1/courses", json=course_data)
        course_id = create_resp.json()["course_id"]

        # Archive the course
        archive_resp = api_client.post(
            f"/api/v1/courses/{course_id}/archive", json={"create_snapshots": True}
        )
        assert archive_resp.status_code == 200

        # Check audit logs
        audit_resp = api_client.get(f"/api/v1/audit/logs?entity_id={course_id}")
        logs = audit_resp.json()["logs"]

        # Should have both created and archived logs
        actions = [log["action"] for log in logs]
        assert "course_created" in actions
        assert "course_archived" in actions

    def test_course_restore_creates_audit_log(self, api_client):
        """
        Test that course restore creates an audit log entry.
        Testen, ob die Kurswiederherstellung einen Audit-Log-Eintrag erstellt.
        """
        # Create and archive a course
        course_data = {
            "semester_id": "WS25/26",
            "title": "Restore Audit Test",
            "title_en": "Restore Audit Test",
            "course_code": "REST-AUD-101",
            "instructor_ids": [],
            "lms": "ilias",
        }

        create_resp = api_client.post("/api/v1/courses", json=course_data)
        course_id = create_resp.json()["course_id"]

        api_client.post(f"/api/v1/courses/{course_id}/archive")

        # Restore the course
        restore_resp = api_client.post(
            f"/api/v1/courses/{course_id}/restore", json={"restore_enrollments": True}
        )
        assert restore_resp.status_code == 200

        # Check audit logs
        audit_resp = api_client.get(f"/api/v1/audit/logs?entity_id={course_id}")
        logs = audit_resp.json()["logs"]

        actions = [log["action"] for log in logs]
        assert "course_restored" in actions

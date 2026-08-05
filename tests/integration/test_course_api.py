# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Integration tests for Course Provisioning API.
Integrationstests für die Kursverwaltungs-API.

This module tests the Course Provisioning API endpoints
including CRUD operations, archival/restore, and bulk operations.
"""

import os
import sys
import pytest
from fastapi.testclient import TestClient
from datetime import datetime
from unittest.mock import patch

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(__file__)), "scripts"))
from scripts.semester_provisioning.course_api import app, create_app


@pytest.fixture
def client():
    """Create a test client for the Course API."""
    test_app = create_app()
    return TestClient(app=test_app)


class TestCourseCreation:
    """Test course creation endpoint."""

    def test_create_course_minimal(self, client):
        course_data = {
            "semester_id": "2026ws",
            "title": "Einführung in die In Informatik",
            "title_en": "Introduction to Computer Science",
            "course_code": "INF-101",
            "instructor_ids": ["prof-123"],
            "expected_enrollment": 120,
            "lms": "ilias",
        }
        response = client.post("/api/v1/courses", json=course_data)
        assert response.status_code == 201
        data = response.json()
        assert data["course_id"].startswith("crs_")
        assert data["semester_id"] == "2026ws"
        assert data["title"] == "Einführung in die In Informatik"
        assert data["lms"] == "ilias"
        assert data["status"] == "draft"

    def test_create_course_moodle(self, client):
        course_data = {
            "semester_id": "2026ss",
            "title": "Advanced Databases",
            "title_en": "Advanced Databases",
            "course_code": "DB-201",
            "instructor_ids": ["prof-456"],
            "expected_enrollment": 45,
            "lms": "moodle",
        }
        response = client.post("/api/v1/courses", json=course_data)
        assert response.status_code == 201
        data = response.json()
        assert data["lms"] == "moodle"

    def test_create_course_missing_required_fields(self, client):
        course_data = {
            "title": "Missing Fields",
            "lms": "ilias",
        }
        response = client.post("/api/v1/courses", json=course_data)
        assert response.status_code == 422


class TestCourseRetrieval:
    """Test course retrieval endpoints."""

    def test_list_courses_empty(self, client):
        response = client.get("/api/v1/courses")
        assert response.status_code == 200
        data = response.json()
        assert data["courses"] == []
        assert data["total"] == 0

    def test_list_courses_with_filters(self, client):
        courses_to_create = [
            {
                "semester_id": "2026ws",
                "title": "Course 1",
                "title_en": "Course 1",
                "course_code": "C1-101",
                "instructor_ids": [],
                "lms": "ilias",
            },
            {
                "semester_id": "2026ws",
                "title": "Course 2",
                "title_en": "Course 2",
                "course_code": "C2-102",
                "instructor_ids": [],
                "lms": "moodle",
            },
            {
                "semester_id": "2026ss",
                "title": "Course 3",
                "title_en": "Course 3",
                "course_code": "SS-101",
                "instructor_ids": [],
                "lms": "ilias",
            },
        ]
        for course in courses_to_create:
            client.post("/api/v1/courses", json=course)

        response = client.get("/api/v1/courses?semester_id=2026ws")
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 2

        response = client.get("/api/v1/courses?lms=ilias")
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 5

    def test_get_course_not_found(self, client):
        response = client.get("/api/v1/courses/nonexistent")
        assert response.status_code == 404

    def test_get_course_by_id(self, client):
        course_data = {
            "semester_id": "2026ws",
            "title": "Test Course for Get",
            "title_en": "Test Course for Get",
            "course_code": "GET-101",
            "instructor_ids": ["prof-123"],
            "lms": "ilias",
        }
        create_resp = client.post("/api/v1/courses", json=course_data)
        course_id = create_resp.json()["course_id"]

        response = client.get(f"/api/v1/courses/{course_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["course_id"] == course_id


class TestCourseUpdate:
    """Test course update endpoint."""

    def test_update_course_title(self, client):
        course_data = {
            "semester_id": "2026ws",
            "title": "Original Title",
            "title_en": "Original Title",
            "course_code": "UPD-101",
            "instructor_ids": ["prof-123"],
            "lms": "ilias",
        }
        create_resp = client.post("/api/v1/courses", json=course_data)
        course_id = create_resp.json()["course_id"]

        update_data = {
            "title": "Updated Title",
            "title_en": "Updated Title",
        }
        response = client.put(f"/api/v1/courses/{course_id}", json=update_data)
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Title"
        assert data["title_en"] == "Updated Title"

    def test_update_course_not_found(self, client):
        update_data = {"title": "Updated Title"}
        response = client.put("/api/v1/courses/nonexistent", json=update_data)
        assert response.status_code == 404


class TestCourseDeletion:
    """Test course deletion endpoint."""

    def test_delete_course(self, client):
        course_data = {
            "semester_id": "2026ws",
            "title": "Course to Delete",
            "title_en": "Course to Delete",
            "course_code": "DEL-101",
            "instructor_ids": [],
            "lms": "ilias",
        }
        create_resp = client.post("/api/v1/courses", json=course_data)
        course_id = create_resp.json()["course_id"]

        response = client.delete(f"/api/v1/courses/{course_id}")
        assert response.status_code == 204

        response = client.get(f"/api/v1/courses/{course_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "deleted"

    def test_delete_course_not_found(self, client):
        response = client.delete("/api/v1/courses/nonexistent")
        assert response.status_code == 404


class TestCourseArchival:
    """Test course archival endpoints."""

    def test_archive_course(self, client):
        course_data = {
            "semester_id": "2026ws",
            "title": "Course to Archive",
            "title_en": "Course to Archive",
            "course_code": "ARCH-101",
            "instructor_ids": [],
            "lms": "ilias",
        }
        create_resp = client.post("/api/v1/courses", json=course_data)
        course_id = create_resp.json()["course_id"]

        response = client.post(f"/api/v1/courses/{course_id}/archive")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "completed"
        assert data["archive_id"] is not None
        assert data["archived_at"] is not None

        response = client.get(f"/api/v1/courses/{course_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "archived"

    def test_archive_course_already_archived(self, client):
        course_data = {
            "semester_id": "2026ws",
            "title": "Already Archived",
            "title_en": "Already Archived",
            "course_code": "ARCH-102",
            "instructor_ids": [],
            "lms": "ilias",
        }
        create_resp = client.post("/api/v1/courses", json=course_data)
        course_id = create_resp.json()["course_id"]

        client.post(f"/api/v1/courses/{course_id}/archive")
        assert response.status_code == 200
        response = client.post(f"/api/v1/courses/{course_id}/archive")
        assert response.status_code == 400

    def test_archive_dry_run(self, client):
        course_data = {
            "semester_id": "2026ws",
            "title": "Dry Run Archive",
            "title_en": "Dry Run Archive",
            "course_code": "DRY-101",
            "instructor_ids": [],
            "lms": "ilias",
        }
        create_resp = client.post("/api/v1/courses", json=course_data)
        course_id = create_resp.json()["course_id"]

        response = client.post(
            f"/api/v1/courses/{course_id}/archive", json={"dry_run": True}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "completed"
        assert data.get("archived_at") is not None


class TestCourseRestore:
    """Test course restore endpoint."""

    def test_restore_archived_course(self, client):
        course_data = {
            "semester_id": "2026ws",
            "title": "Course to Restore",
            "title_en": "Course to Restore",
            "course_code": "REST-101",
            "instructor_ids": [],
            "lms": "ilias",
        }
        create_resp = client.post("/api/v1/courses", json=course_data)
        course_id = create_resp.json()["course_id"]

        client.post(f"/api/v1/courses/{course_id}/archive")
        assert response.status_code == 200

        response = client.post(f"/api/v1/courses/{course_id}/restore")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "completed"

        response = client.get(f"/api/v1/courses/{course_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "active"

    def test_restore_not_archived_course(self, client):
        course_data = {
            "semester_id": "2026ws",
            "title": "Not Archived",
            "title_en": "Not Archived",
            "course_code": "NARCH-101",
            "instructor_ids": [],
            "lms": "ilias",
        }
        create_resp = client.post("/api/v1/courses", json=course_data)
        course_id = create_resp.json()["course_id"]

        response = client.post(f"/api/v1/courses/{course_id}/restore")
        assert response.status_code == 400

    def test_restore_dry_run(self, client):
        course_data = {
            "semester_id": "2026ws",
            "title": "Dry Run Restore",
            "title_en": "Dry Run Restore",
            "course_code": "DRYR-101",
            "instructor_ids": [],
            "lms": "ilias",
        }
        create_resp = client.post("/api/v1/courses", json=course_data)
        course_id = create_resp.json()["course_id"]

        response = client.post(
            f"/api/v1/courses/{course_id}/restore", json={"dry_run": True}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "completed"


class TestBulkEnrollment:
    """Test bulk enrollment endpoint."""

    def test_bulk_enroll_users(self, client):
        course_data = {
            "semester_id": "2026ws",
            "title": "Course for Enrollment",
            "title_en": "Course for Enrollment",
            "course_code": "ENR-101",
            "instructor_ids": ["prof-123"],
            "lms": "ilias",
        }
        create_resp = client.post("/api/v1/courses", json=course_data)
        course_id = create_resp.json()["course_id"]

        enrollment_data = {
            "user_ids": ["student-001", "student-002", "student-003"],
            "role": "student",
        }
        response = client.post(
            f"/api/v1/courses/{course_id}/enrollments", json=enrollment_data
        )
        assert response.status_code == 201
        data = response.json()
        assert len(data) == 3
        for enrollment in data:
            assert enrollment["user_id"].startswith("student-")
            assert enrollment["role"] == "student"
            assert enrollment["status"] == "active"

    def test_bulk_enroll_instructors(self, client):
        course_data = {
            "semester_id": "2026ws",
            "title": "Course for Instructor Enrollment",
            "title_en": "Course for Instructor Enrollment",
            "course_code": "INST-101",
            "instructor_ids": [],
            "lms": "ilias",
        }
        create_resp = client.post("/api/v1/courses", json=course_data)
        course_id = create_resp.json()["course_id"]

        enrollment_data = {"user_ids": ["instructor-001"], "role": "instructor"}
        response = client.post(
            f"/api/v1/courses/{course_id}/enrollments", json=enrollment_data
        )
        assert response.status_code == 201
        data = response.json()
        assert len(data) == 1
        assert data[0]["role"] == "instructor"

    def test_bulk_enroll_nonexistent_course(self, client):
        enrollment_data = {"user_ids": ["student-001"], "role": "student"}
        response = client.post(
            "/api/v1/courses/nonexistent/enrollments", json=enrollment_data
        )
        assert response.status_code == 404


class TestSemesterManagement:
    """Test semester management endpoints."""

    def test_create_semester(self, client):
        semester_data = {
            "semester_id": "2026ws",
            "name": "Wintersemester 2026/27",
            "name_en": "Winter Semester 2026/27",
            "type": "wintersemester",
            "start_date": "2026-10-01",
            "end_date": "2027-03-31",
        }
        response = client.post("/api/v1/semesters", json=semester_data)
        assert response.status_code == 201
        data = response.json()
        assert data["semester_id"] == "2026ws"
        assert data["type"] == "wintersemester"

    def test_list_semesters(self, client):
        semesters_to_create = [
            {
                "semester_id": "2026ws",
                "name": "Wintersemester 2026/27",
                "name_en": "Winter Semester 2026/27",
                "type": "wintersemester",
                "start_date": "2026-10-01",
                "end_date": "2027-03-31",
            },
            {
                "semester_id": "2026ss",
                "name": "Sommersemester 2026",
                "name_en": "Summer Semester 2026",
                "type": "sommersemester",
                "start_date": "2026-04-01",
                "end_date": "2026-09-30",
            },
        ]
        for semester in semesters_to_create:
            client.post("/api/v1/semesters", json=semester)

        response = client.get("/api/v1/semesters")
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 5
        semester_ids = [s["semester_id"] for s in data["semesters"]]
        assert "2026ws" in semester_ids
        assert "2026ss" in semester_ids


class TestAuditLogs:
    """Test audit log endpoints."""

    def test_list_audit_logs(self, client):
        course_data = {
            "semester_id": "2026ws",
            "title": "Course for Audit",
            "title_en": "Course for Audit",
            "course_code": "AUD-101",
            "instructor_ids": [],
            "lms": "ilias",
        }
        client.post("/api/v1/courses", json=course_data)

        response = client.get("/api/v1/audit/logs")
        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 1
        assert any(log["action"] == "course_created" for log in data["logs"])

    def test_filter_audit_logs(self, client):
        course_data = {
            "semester_id": "2026ws",
            "title": "Course 1",
            "title_en": "Course 1",
            "course_code": "AUD-1",
            "instructor_ids": [],
            "lms": "ilias",
        }
        client.post("/api/v1/courses", json=course_data)

        course_data["course_code"] = "AUD-2"
        course_data["title"] = "Course 2"
        client.post("/api/v1/courses", json=course_data)

        response = client.get("/api/v1/audit/logs?entity_type=course")
        assert response.status_code == 200
        data = response.json()
        assert all(log["entity_type"] == "course" for log in data["logs"])


class TestHealthCheck:
    """Test health check endpoints."""

    def test_health_check(self, client):
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"

    def test_readiness_check(self, client):
        response = client.get("/ready")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ready"

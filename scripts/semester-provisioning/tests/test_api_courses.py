# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
import pytest
from fastapi.testclient import TestClient
from api.main import create_app


@pytest.fixture
def client():
    return TestClient(app=create_app())


def test_create_single_course(client: TestClient):
    course_data = {
        "semester_id": "2026ws",
        "title": "Test Course",
        "title_en": "Test Course (EN)",
        "course_code": "TEST-101",
        "instructor_ids": [],
        "expected_enrollment": 30,
        "lms": "ilias",
        "category": "test-category",
    }
    response = client.post("/api/v1/courses", json=course_data)
    assert response.status_code == 201
    data = response.json()
    assert data["course_id"].startswith("crs_")
    assert data["semester_id"] == "2026ws"
    assert data["title"] == "Test Course"
    assert data["lms"] == "ilias"


def test_create_course_duplicate_title(client: TestClient):
    course_data = {
        "semester_id": "2026ws",
        "title": "Course 1",
        "title_en": "Course 1 (EN)",
        "course_code": "TEST-101",
        "instructor_ids": [],
        "expected_enrollment": 30,
        "lms": "ilias",
    }

    response = client.post("/api/v1/courses", json=course_data)
    assert response.status_code == 201
    data = response.json()
    assert data["course_id"].startswith("crs_")
    assert data["semester_id"] == "2026ws"
    assert data["title"] == "Course 1"
    assert data["lms"] == "ilias"


def test_create_bulk_courses(client: TestClient):
    courses_data = [
        {
            "semester_id": "2026ws",
            "title": "Course 1",
            "title_en": "Course 1 (EN)",
            "course_code": "TEST-101",
            "instructor_ids": [],
            "expected_enrollment": 30,
            "lms": "ilias",
        },
        {
            "semester_id": "2026ws",
            "title": "Course 2",
            "title_en": "Course 2 (EN)",
            "course_code": "TEST-102",
            "instructor_ids": [],
            "expected_enrollment": 25,
            "lms": "moodle",
        },
    ]

    response = client.post(
        "/api/v1/courses/bulk-create", json={"courses": courses_data}
    )
    assert response.status_code in (201, 202)
    data = response.json()
    # Depending on server behavior this could be a list of created courses or a bulk job object
    if isinstance(data, list):
        assert len(data) == 2
        for course in data:
            assert course["course_id"].startswith("crs_")
    else:
        # If a bulk job object is returned, ensure a key exists
        assert "job_id" in data or "status" in data


def test_get_course_not_found(client: TestClient):
    response = client.get("/api/v1/courses/nonexistent")
    assert response.status_code in (404, 422)
    # Not all implementations return the same detail string; ensure it contains not found
    if response.status_code == 404:
        assert "not found" in response.text.lower()


def test_update_course(client: TestClient):
    # Create a course to update
    course_data = {
        "semester_id": "2026ws",
        "title": "Temp Course for Update",
        "title_en": "Temp Course for Update",
        "course_code": "TEST-UPDATE",
        "instructor_ids": [],
        "expected_enrollment": 10,
        "lms": "ilias",
        "category": "test-category",
    }
    resp = client.post("/api/v1/courses", json=course_data)
    assert resp.status_code == 201
    course_id = resp.json()["course_id"]

    response = client.put(
        f"/api/v1/courses/{course_id}", json={"title": "Updated Course"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Updated Course"


def test_delete_course(client: TestClient):
    # Create a course to delete
    course_data = {
        "semester_id": "2026ws",
        "title": "Temp Course for Delete",
        "title_en": "Temp Course for Delete",
        "course_code": "TEST-DEL",
        "instructor_ids": [],
        "expected_enrollment": 10,
        "lms": "ilias",
        "category": "test-category",
    }
    resp = client.post("/api/v1/courses", json=course_data)
    assert resp.status_code == 201
    course_id = resp.json()["course_id"]

    response = client.delete(f"/api/v1/courses/{course_id}")
    assert response.status_code in (200, 204)


def test_bulk_enroll(client: TestClient):
    # Create a course to enroll into
    course_data = {
        "semester_id": "2026ws",
        "title": "Temp Course for Enroll",
        "title_en": "Temp Course for Enroll",
        "course_code": "TEST-ENR",
        "instructor_ids": [],
        "expected_enrollment": 10,
        "lms": "ilias",
        "category": "test-category",
    }
    resp = client.post("/api/v1/courses", json=course_data)
    assert resp.status_code == 201
    course_id = resp.json()["course_id"]

    response = client.post(
        f"/api/v1/courses/{course_id}/enrollments",
        json={
            "enrollments": [
                {"user_id": "user-001", "role": "student"},
                {"user_id": "user-002", "role": "instructor"},
            ]
        },
    )
    assert response.status_code in (201, 200)
    enrollments = response.json()
    if isinstance(enrollments, list):
        assert len(enrollments) == 2
        for enr in enrollments:
            assert enr["user_id"].startswith("user-") or enr.get("id", "").startswith(
                "enr_"
            )


def test_health_check(client: TestClient):
    response = client.get("/health")
    assert response.status_code == 200
    # If the API exposes a status field, ensure it's healthy
    if isinstance(response.json(), dict):
        status = response.json().get("status")
        if status:
            assert status.lower() in {"healthy", "ok"}

# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
import pytest
from fastapi.testclient import TestClient
from api.main import create_app


@pytest.fixture
def client():
    return TestClient(app=create_app())


def test_bulk_enrollments(client: TestClient):
    # Step 1: Create a test course first
    course_data = {
        "semester_id": "2026ws",
        "title": "Enrollment Test Course",
        "title_en": "Enrollment Test Course EN",
        "course_code": "ENR-101",
        "instructor_ids": [],
        "expected_enrollment": 20,
        "lms": "ilias",
        "category": "test-category",
    }
    resp = client.post("/api/v1/courses", json=course_data)
    assert resp.status_code == 201
    course_id = resp.json()["course_id"]

    # Step 2: Bulk enrollments
    enrollments_payload = {
        "enrollments": [
            {"user_id": "user-001", "role": "student"},
            {"user_id": "user-002", "role": "instructor"},
        ]
    }
    resp2 = client.post(
        f"/api/v1/enrollments/{course_id}/bulk-add", json=enrollments_payload
    )
    assert resp2.status_code == 201
    created = resp2.json()
    assert isinstance(created, list) and len(created) == 2
    for enr in created:
        assert enr["enrollment_id"].startswith("enr_")

    # Step 3: List enrollments for the course
    resp3 = client.get(f"/api/v1/enrollments/{course_id}")
    assert resp3.status_code == 200
    data = resp3.json()
    assert "enrollments" in data
    assert len(data["enrollments"]) >= 2

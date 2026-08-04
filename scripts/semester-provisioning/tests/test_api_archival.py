# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
import pytest
from fastapi.testclient import TestClient
from api.main import create_app


@pytest.fixture
def client():
    return TestClient(app=create_app())


def test_bulk_archive_courses(client: TestClient):
    # Create two test courses to archive
    course_ids = []
    for i in range(2):
        course_data = {
            "semester_id": "2026ws",
            "title": f"Archive Test Course {i + 1}",
            "title_en": f"Archive Test Course {i + 1} EN",
            "course_code": f"ARC-{i + 1}01",
            "instructor_ids": [],
            "expected_enrollment": 10,
            "lms": "ilias",
            "category": "test-category",
        }
        resp = client.post("/api/v1/courses", json=course_data)
        assert resp.status_code == 201
        course_ids.append(resp.json()["course_id"])

    # Bulk archive the two courses
    bulk_req = {
        "course_ids": course_ids,
        "semester_id": None,
        "create_snapshots": False,
        "dry_run": False,
        "reason": "unit test bulk archive",
    }
    resp2 = client.post("/api/v1/archival/bulk-archive", json=bulk_req)
    # Depending on environment, this may process synchronously and return a final state
    assert resp2.status_code in (202, 200, 201)
    data = resp2.json()
    # Validate basic bulk result shape
    assert "job_id" in data or "status" in data

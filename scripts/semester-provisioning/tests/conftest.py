# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
import os
import pytest
from fastapi.testclient import TestClient
from api.main import create_app

# Load test environment variables
test_env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env.test")
if os.path.exists(test_env_path):
    from dotenv import load_dotenv

    load_dotenv(test_env_path, override=True)


@pytest.fixture(autouse=True)
def clear_settings_cache():
    """Clear the settings cache before each test to ensure fresh settings are loaded."""
    from api.config.settings import get_settings

    get_settings.cache_clear()
    yield


@pytest.fixture
def client():
    """Create a test client for the FastAPI app."""
    return TestClient(app=create_app())


@pytest.fixture
def mock_course_data():
    """Mock course data for testing."""
    return {
        "course_id": "crs_test123",
        "semester_id": "2026ws",
        "title": "Test Course",
        "title_en": "Test Course (EN)",
        "course_code": "TEST-101",
        "instructor_ids": [],
        "expected_enrollment": 30,
        "lms": "ilias",
        "category": "test-category",
        "status": "active",
        "created_at": "2026-01-01T00:00:00Z",
        "lms_course_id": "ilias_123",
    }


@pytest.fixture
def mock_enrollment_data():
    """Mock enrollment data for testing."""
    return {
        "enrollment_id": "enr_test123",
        "course_id": "crs_test123",
        "user_id": "user-001",
        "role": "student",
        "created_at": "2026-01-01T00:00:00Z",
    }


@pytest.fixture
def mock_semester_data():
    """Mock semester data for testing."""
    return {
        "semester_id": "2026ws",
        "name": "Wintersemester 2026/27",
        "name_en": "Winter Semester 2026/27",
        "start_date": "2026-10-01",
        "end_date": "2027-03-31",
        "status": "active",
        "created_at": "2026-01-01T00:00:00Z",
        "course_count": 0,
    }

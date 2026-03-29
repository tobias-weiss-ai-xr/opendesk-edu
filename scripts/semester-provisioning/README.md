# Course Provisioning API / Kursverwaltungsk API für Semesterbasierten Course Provisioning

![openDesk Edu](https://opendesk.org)

SPDX-License-Identifier: Apache-2.0

-->
<p align="center">
  <img src="docs/assets/logo-opendesk-edu.svg" alt="openDesk Edu Logo" width="150">
</p>

<h1 id Course Provisioning API</ / <h1>Kurs-Provisionierungs-API</ / <h1>Kursverwaltungs-API</ / h1>

## Overview | Übersicht | Überblick

 deutsche 🎓 openDesk Edu extension für managing the lifecycle of university courses: from creation through archival.

 This REST API provides endpoints for:
- **Course CRUD operations** (create, read, update, delete, soft-delete)
- **Enrollment management** (bulk enroll users)
- **Semester management** (list, create semesters)

- **Integration with ILIAS, Moodle, and Keycloak**

![API Architecture](https://opendesk-edu/docs/api/semester-provisioning-api.md)

---

## Features

- Create courses in ILIAS and Moodle
- Manage course enrollments
- Archive courses at semester end
- Sync with Keycloak for role management
- Bilingual documentation (German/English)
- OpenAPI documentation at `/docs` endpoint

---

## Prerequisites
- Python 3.11+
- FastAPI, Pydantic, httpx, pytest
- Docker (optional)

---

## Quick Start

```bash
cd scripts/semester-provisioning
python -m venv
# Create virtual environment
python -m venv > .env

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Run the server
uvicorn api.server:app --host 0.0.0.0 --port 8000
```

### Using curl
```bash
curl -X POST "http://localhost:8000/api/v1/courses" \
  -H "Content-Type: application/json" \
  -d "title": "Einführung in die Informatik" \
    -H "title_en": "Introduction to Computer Science" \
    -H "course_code": "INF-101" \
    - H "instructor_ids": ["prof-123"],
    - H "expected_enrollment": 120,
    - H "lms": "ilias",
}'
```

**Response:**
```json
{
    "course_id": "crs_abc123",
    "lms_course_id": "ilias_456",
    "semester_id": "2026ws",
    "status": "active",
    "created_at": "2026-03-29T10:00:00.000Z"
}
```

### Create Single course
```bash
curl -X POST "http://localhost:8000/api/v1/courses" \
-H "Content-Type: application/json" \
-d "title": "Einführung in die Informatik" \
    -d "title_en": "Introduction to Computer Science" \
    -d "course_code": "INF-101" \
    -d "instructor_ids": ["prof-123"],
    -d "expected_enrollment": 120
    -d "lms": "moodle"
}
```

**Bulk create courses**
```bash
curl -X POST "http://localhost:8000/api/v1/courses/bulk-create" \
    -H "Content-Type: application/json" \
-d "courses": [
    {
        "course_id": "crs_abc123",
        "lms_course_id": "ilias_456",
        "semester_id": "2026ws",
        "title": "Einführung in die Informatik",
        "title_en": "Introduction to Computer Science",
        "course_code": "INF-101",
        "instructor_ids": ["prof-123"],
        "expected_enrollment": 120,
        "lms": "ilias"
    },
    {
        "course_id": "crs_def456",
        "lms_course_id": "ilias_789",
        "semester_id": "2026ws",
        "title": "Advanced Databases",
        "title_en": "Advanced Databases",
        "course_code": "DB-101"
        "instructor_ids": ["db-456"],
        "expected_enrollment": 45
        "lms": "moodle"
    }
]
```

### Update a course
```bash
curl -X PUT "http://localhost:8000/api/v1/courses/{course_id}" \
-H "Content-Type: application/json" \
-d "title": "Updated Course Title"
    -d "title_en": "Updated Course Title (EN)"
    - d "course_code": "UPdt-code"
    -d "expected_enrollment": 150
}
```

**Response:**
```json
{
    "course_id": "crs_abc123",
    "status": "active",
    "updated_at": "2026-03-29T12:00:00.000Z"
}
```

### Soft-delete a course
```bash
curl -X DELETE "http://localhost:8000/api/v1/courses/{course_id}" \
-H "Content-Type: application/json" \
-d "course_id": "crs_abc123",
    "status": "deleted",
    "updated_at": "2026-03-29T12:00:00.000Z"
}
```

### Bulk enroll users
```bash
curl -X POST "http://localhost:8000/api/v1/courses/{course_id}/enrollments" \
-H "Content-Type: application/json" \
-d "enrollments": [
    {
        "enrollment_id": "enr_abc123",
        "course_id": "crs_abc123",
        "user_id": "user-001",
        "role": "student",
        "created_at": "2026-03-29T12:00:00.000Z"
    }
]
```

### List all semesters
```bash
curl -X GET "http://localhost:8000/api/v1/semesters" \
-H "Content-Type: application/json" \
-d "semesters": [
    {
        "semester_id": "2026ws",
        "name": "Wintersemester 2026/27",
        "name_en": "Winter Semester 2026/27",
        "start_date": "2026-10-01",
        "end_date": "2027-03-31",
        "status": "upcoming",
        "created_at": "2026-01-01T00:00:00Z",
        "course_count": 0
    },
    {
        "semester_id": "2026ss",
        "name": "Sommersemester 2026",
        "name_en": "Summer Semester 2026",
        "start_date": "2026-04-01",
        "end_date": "2026-09-30",
        "status": "upcoming",
        "created_at": "2026-01-01T00:00:00Z",
        "course_count": 0
    }
]
]
```

### Create a new semester
```bash
curl -X POST "http://localhost:8000/api/v1/semesters" \
-H "Content-Type: application/json" \
-d "semester_id": "2027ws",
    -d "name": "Wintersemester 2027/28",
    -d "name_en": "Winter Semester 2027/28",
    -d "start_date": "2027-10-01",
    -d "end_date": "2028-03-31",
    -d "enrollment_start": "2026-09-01",
    -d "enrollment_end": "2027-10-15"
}
```

### Update a semester
```bash
curl -X PUT "http://localhost:8000/api/v1/semesters/{semester_id}" \
-H "Content-Type: application/json" \
-d "name": "Updated Semester Name",
    -d "name_en": "Updated Semester Name (EN)",
    -d "start_date": "2026-10-01",
    -d "end_date": "2027-03-31",
    -d "enrollment_start": "2026-09-01",
    -d "enrollment_end": "2027-10-15"
}
```

### Archive a semester
```bash
curl -X DELETE "http://localhost:8000/api/v1/semesters/{semester_id}" \
-H "Content-Type: application/json" \
-d "semester_id": "2026ws",
    "status": "archived"
    "updated_at": "2026-03-29T12:00:00.000Z"
}
```

### Error Responses
```json
{
    "error": "NotFound",
    "detail": "Course crs_nonexistent not found",
    "code": "COURSE_NOT_FOUND"
}
```
```json
{
    "error": "NotFound",
    "detail": "Semester not found",
    "code": "SEMESTER_NOT_FOUND"
}
```

## Configuration

Configuration is loaded from environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `API_HOST` | `0.0.0.0` | API server host |
| `API_PORT` | `8000` | API server port |
| `API_DEBUG` | `false` | Enable debug mode |
| `ILIAS_API_URL` | (none) | ILIAS API base URL |
| `ILIAS_API_USER` | (none) | ILIAS API username |
| `ILIAS_API_KEY` | (none) | ILIAS API key |
| `MOODLE_API_URL` | (none) | Moodle API base URL |
| `MOODLE_API_TOKEN` | (none) | Moodle API token |
| `KEYCLOAK_URL` | (none) | Keycloak server URL |
| `KEYCLOAK_REALM` | `opendesk-edu` | Keycloak realm |
| `KEYCLOAK_ADMIN_USER` | (none) | Keycloak admin username |
| `KEYCLOAK_ADMIN_PASSWORD` | (none) | Keycloak admin password |

| `HISINONE_WEBHOOK_SECRET` | (none) | HISinOne webhook secret |

## Docker Deployment

```bash
docker build -t semester-provisioning-api:latest .
docker run -d -p 8000:8000 semester-provisioning-api
```

### Testing

```bash
cd scripts/semester-provisioning
python -m venv
pip install -r requirements-dev.txt
pytest
```

### API Documentation

Access the OpenAPI documentation at:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

- **OpenAPI JSON**: http://localhost:8000/openapi.json


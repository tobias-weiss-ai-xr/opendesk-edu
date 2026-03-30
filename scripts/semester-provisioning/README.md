# Course Provisioning API / Kursverwaltungs-API

<!---
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

![openDesk Edu](https://opendesk.org)

<p align="center">
  <img src="docs/assets/logo-opendesk-edu.svg" alt="openDesk Edu Logo" width="150">
</p>

## Overview / Übersicht

**English:**  
🎓 openDesk Edu extension for managing the lifecycle of university courses: from creation through archival. This REST API provides endpoints for course CRUD operations, enrollment management, semester management, and integration with ILIAS, Moodle, and Keycloak.

**Deutsch:**  
🎓 openDesk Edu Erweiterung zur Verwaltung des Lebenszyklus von Universitätskursen: von der Erstellung bis zur Archivierung. Diese REST-API stellt Endpunkte für Kurs-CRUD-Operationen, Einschreibungsverwaltung, Semester-Verwaltung und Integration mit ILIAS, Moodle und Keycloak bereit.

---

## Features / Funktionen

| English | Deutsch |
|---------|---------|
| Create courses in ILIAS and Moodle | Kurse in ILIAS und Moodle erstellen |
| Manage course enrollments | Kurseinschreibungen verwalten |
| Archive courses at semester end | Kurse am Semesterende archivieren |
| Restore archived courses | Archivierte Kurse wiederherstellen |
| Sync with Keycloak for role management | Mit Keycloak für Rollenverwaltung synchronisieren |
| Bilingual documentation (German/English) | Zweisprachige Dokumentation (Deutsch/Englisch) |
| OpenAPI documentation at `/docs` endpoint | OpenAPI-Dokumentation unter `/docs` Endpunkt |
| SQLite database storage (PostgreSQL-ready) | SQLite-Datenbankspeicherung (PostgreSQL-fähig) |
| Audit logging for all operations | Audit-Logging für alle Operationen |

---

## API Endpoints

### Courses / Kurse

| Method | Endpoint | Description (EN) | Beschreibung (DE) |
|--------|----------|------------------|-------------------|
| POST | `/api/v1/courses` | Create a new course | Neuen Kurs erstellen |
| GET | `/api/v1/courses` | List courses (with filters) | Kurse auflisten (mit Filtern) |
| GET | `/api/v1/courses/{id}` | Get course details | Kursdetails abrufen |
| PUT | `/api/v1/courses/{id}` | Update course | Kurs aktualisieren |
| DELETE | `/api/v1/courses/{id}` | Soft delete course | Kurs löschen (soft) |
| POST | `/api/v1/courses/{id}/archive` | Archive course | Kurs archivieren |
| POST | `/api/v1/courses/{id}/restore` | Restore archived course | Archivierten Kurs wiederherstellen |
| POST | `/api/v1/courses/{id}/enrollments` | Bulk enroll users | Benutzer einschreiben |

### Semesters / Semester

| Method | Endpoint | Description (EN) | Beschreibung (DE) |
|--------|----------|------------------|-------------------|
| POST | `/api/v1/semesters` | Create semester | Semester erstellen |
| GET | `/api/v1/semesters` | List semesters | Semester auflisten |

### Audit Logs / Audit-Logs

| Method | Endpoint | Description (EN) | Beschreibung (DE) |
|--------|----------|------------------|-------------------|
| GET | `/api/v1/audit/logs` | List audit logs | Audit-Logs auflisten |

### Health / Gesundheit

| Method | Endpoint | Description (EN) | Beschreibung (DE) |
|--------|----------|------------------|-------------------|
| GET | `/health` | Health check | Gesundheitscheck |
| GET | `/ready` | Readiness check | Bereitschaftscheck |

---

## Prerequisites / Voraussetzungen

- Python 3.11+
- FastAPI, Pydantic, httpx, pytest
- Docker (optional)

---

## Quick Start / Schnellstart

```bash
cd scripts/semester-provisioning

# Create virtual environment / Virtuelle Umgebung erstellen
python -m venv .venv
source .venv/bin/activate  # Linux/macOS
# or: .venv\Scripts\activate  # Windows

# Install dependencies / Abhängigkeiten installieren
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Run the server / Server starten
uvicorn api.server:app --host 0.0.0.0 --port 8000

# Or using the course_api module directly
# Oder das course_api Modul direkt verwenden
python -m course_api
```

---

## API Usage Examples / API-Verwendungsbeispiele

### Create Course / Kurs erstellen

```bash
curl -X POST "http://localhost:8000/api/v1/courses" \
  -H "Content-Type: application/json" \
  -d '{
    "semester_id": "2026ws",
    "title": "Einführung in die Informatik",
    "title_en": "Introduction to Computer Science",
    "course_code": "INF-101",
    "instructor_ids": ["prof-123"],
    "expected_enrollment": 120,
    "lms": "ilias"
  }'
```

**Response / Antwort:**
```json
{
  "course_id": "crs_abc123",
  "lms_course_id": "lms_def456",
  "semester_id": "2026ws",
  "title": "Einführung in die Informatik",
  "title_en": "Introduction to Computer Science",
  "course_code": "INF-101",
  "status": "draft",
  "created_at": "2026-03-30T10:00:00Z"
}
```

### List Courses / Kurse auflisten

```bash
curl "http://localhost:8000/api/v1/courses?semester_id=2026ws&status=active&page=1&page_size=20"
```

### Archive Course / Kurs archivieren

```bash
curl -X POST "http://localhost:8000/api/v1/courses/crs_abc123/archive" \
  -H "Content-Type: application/json" \
  -d '{"create_snapshots": true}'
```

### Restore Course / Kurs wiederherstellen

```bash
curl -X POST "http://localhost:8000/api/v1/courses/crs_abc123/restore" \
  -H "Content-Type: application/json" \
  -d '{"restore_enrollments": true}'
```

### Bulk Enroll Users / Benutzer einschreiben

```bash
curl -X POST "http://localhost:8000/api/v1/courses/crs_abc123/enrollments" \
  -H "Content-Type: application/json" \
  -d '{
    "user_ids": ["user-001", "user-002", "user-003"],
    "role": "student"
  }'
```

### Create Semester / Semester erstellen

```bash
curl -X POST "http://localhost:8000/api/v1/semesters" \
  -H "Content-Type: application/json" \
  -d '{
    "semester_id": "2026ws",
    "name": "Wintersemester 2026/27",
    "name_en": "Winter Semester 2026/27",
    "type": "wintersemester",
    "start_date": "2026-10-01",
    "end_date": "2027-03-31"
  }'
```

### Error Response / Fehlerantwort

```json
{
  "error": "NotFound",
  "detail": "Course crs_nonexistent not found / Kurs crs_nonexistent nicht gefunden",
  "code": "COURSE_NOT_FOUND"
}
```

---

## Configuration / Konfiguration

Configuration is loaded from environment variables:

| Variable | Default | Description (EN) | Beschreibung (DE) |
|----------|---------|------------------|-------------------|
| `API_HOST` | `0.0.0.0` | API server host | API-Server-Host |
| `API_PORT` | `8000` | API server port | API-Server-Port |
| `API_DEBUG` | `false` | Enable debug mode | Debug-Modus aktivieren |
| `ILIAS_API_URL` | (none) | ILIAS API base URL | ILIAS-API-Basis-URL |
| `ILIAS_API_USER` | (none) | ILIAS API username | ILIAS-API-Benutzername |
| `ILIAS_API_KEY` | (none) | ILIAS API key | ILIAS-API-Schlüssel |
| `MOODLE_API_URL` | (none) | Moodle API base URL | Moodle-API-Basis-URL |
| `MOODLE_API_TOKEN` | (none) | Moodle API token | Moodle-API-Token |
| `KEYCLOAK_URL` | (none) | Keycloak server URL | Keycloak-Server-URL |
| `KEYCLOAK_REALM` | `opendesk-edu` | Keycloak realm | Keycloak-Realm |
| `KEYCLOAK_ADMIN_USER` | (none) | Keycloak admin username | Keycloak-Admin-Benutzer |
| `KEYCLOAK_ADMIN_PASSWORD` | (none) | Keycloak admin password | Keycloak-Admin-Passwort |
| `DATABASE_PATH` | `:memory:` | SQLite database path | SQLite-Datenbankpfad |
| `ARCHIVE_RETENTION_YEARS` | `5` | Years to retain archives | Jahre zur Archivaufbewahrung |

---

## Docker Deployment / Docker-Bereitstellung

```bash
docker build -t semester-provisioning-api:latest .
docker run -d -p 8000:8000 semester-provisioning-api
```

---

## Testing / Tests

```bash
cd scripts/semester-provisioning
python -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt

# Run unit tests / Unit-Tests ausführen
pytest tests/

# Run integration tests / Integrationstests ausführen
pytest tests/integration/

# Run with coverage / Mit Abdeckung ausführen
pytest --cov=. tests/
```

---

## API Documentation / API-Dokumentation

Access the OpenAPI documentation at:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

---

## File Structure / Dateistruktur

```
scripts/semester-provisioning/
├── __init__.py              # Package init / Paket-Initialisierung
├── course_api.py            # FastAPI endpoints / FastAPI-Endpunkte
├── models.py                # Data models / Datenmodelle
├── config.py                # Configuration / Konfiguration
├── database.py              # SQLite storage / SQLite-Speicherung
├── audit.py                 # Audit logging / Audit-Logging
├── README.md                # This file / Diese Datei
├── requirements.txt         # Dependencies / Abhängigkeiten
├── requirements-dev.txt     # Dev dependencies / Entwicklungsabhängigkeiten
├── api/
│   ├── main.py              # App factory / App-Factory
│   ├── server.py            # Server entry / Server-Einstieg
│   ├── config/
│   │   └── settings.py      # Pydantic settings / Pydantic-Einstellungen
│   ├── models/
│   │   ├── course.py        # Course models / Kursmodelle
│   │   ├── semester.py      # Semester models / Semestermodelle
│   │   ├── enrollment.py    # Enrollment models / Einschreibungsmodelle
│   │   └── archival.py      # Archival models / Archivierungsmodelle
│   ├── routes/
│   │   ├── courses.py       # Course routes / Kursrouten
│   │   ├── semesters.py     # Semester routes / Semesterrouten
│   │   ├── enrollments.py   # Enrollment routes / Einschreibungsrouten
│   │   └── archival.py      # Archival routes / Archivierungsrouten
│   └── utils/
│       ├── ilias_client.py  # ILIAS client / ILIAS-Client
│       ├── moodle_client.py # Moodle client / Moodle-Client
│       └── keycloak_client.py # Keycloak client / Keycloak-Client
├── tests/
│   ├── conftest.py          # Pytest fixtures / Pytest-Fixtures
│   ├── test_api_courses.py  # Course tests / Kurs-Tests
│   ├── test_api_semesters.py # Semester tests / Semester-Tests
│   ├── test_api_enrollments.py # Enrollment tests / Einschreibungs-Tests
│   └── test_api_archival.py # Archival tests / Archivierungs-Tests
└── sync/
    ├── bulk_sync.py         # Bulk sync operations / Massensynchronisation
    └── hisinone_webhook.py  # HISinOne webhook / HISinOne-Webhook
```

---

## License / Lizenz

Apache-2.0 - see [LICENSE](../../LICENSE) for details.

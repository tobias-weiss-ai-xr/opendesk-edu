<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Course Provisioning API / Kursverwaltungs-API

[English](#english) | [Deutsch](#deutsch)

---

<a name="english"></a>

## English

### Overview

The Course Provisioning API provides a RESTful interface for managing university courses in openDesk Edu. It handles course creation, enrollment management, semester transitions, and archival workflows with seamless integration to ILIAS, Moodle, and Keycloak.

### Base URL

```
http://localhost:8000/api/v1
```

**Production:**

```
https://semester.{domain}/api/v1
```

### Authentication

API endpoints require authentication via:

- **Bearer Token**: `Authorization: Bearer <token>`
- **API Key**: `X-API-Key: <key>`

### OpenAPI Documentation

- **Swagger UI**: `/docs`
- **ReDoc**: `/redoc`
- **OpenAPI JSON**: `/openapi.json`

---

## Course Endpoints / Kurs-Endpunkte

### Create Course / Kurs erstellen

```http
POST /api/v1/courses
```

**Request Body:**

```json
{
  "semester_id": "2026ws",
  "title": "Einführung in die Informatik",
  "title_en": "Introduction to Computer Science",
  "course_code": "INF-101",
  "instructor_ids": ["prof-123"],
  "expected_enrollment": 120,
  "lms": "ilias",
  "category": "courses"
}
```

**Response (201 Created):**

```json
{
  "course_id": "crs_abc123def456",
  "lms_course_id": "lms_xyz789",
  "semester_id": "2026ws",
  "title": "Einführung in die Informatik",
  "title_en": "Introduction to Computer Science",
  "course_code": "INF-101",
  "instructor_ids": ["prof-123"],
  "expected_enrollment": 120,
  "lms": "ilias",
  "category": "courses",
  "status": "draft",
  "created_at": "2026-03-30T10:00:00Z"
}
```

### List Courses / Kurse auflisten

```http
GET /api/v1/courses
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `semester_id` | string | No | Filter by semester ID |
| `status` | string | No | Filter by status (`draft`, `active`, `archived`, `deleted`) |
| `lms` | string | No | Filter by LMS (`ilias`, `moodle`) |
| `page` | integer | No | Page number (default: 1) |
| `page_size` | integer | No | Items per page (default: 20, max: 100) |

**Example Request:**

```bash
curl "http://localhost:8000/api/v1/courses?semester_id=2026ws&status=active&page=1&page_size=20"
```

**Response:**

```json
{
  "courses": [
    {
      "course_id": "crs_abc123",
      "lms_course_id": "lms_def456",
      "semester_id": "2026ws",
      "title": "Einführung in die Informatik",
      "title_en": "Introduction to Computer Science",
      "course_code": "INF-101",
      "instructor_ids": ["prof-123"],
      "expected_enrollment": 120,
      "lms": "ilias",
      "category": "courses",
      "status": "active",
      "created_at": "2026-03-30T10:00:00Z"
    }
  ],
  "total": 45,
  "page": 1,
  "page_size": 20
}
```

### Get Course / Kurs abrufen

```http
GET /api/v1/courses/{course_id}
```

**Response:**

```json
{
  "course_id": "crs_abc123",
  "lms_course_id": "lms_def456",
  "semester_id": "2026ws",
  "title": "Einführung in die Informatik",
  "title_en": "Introduction to Computer Science",
  "course_code": "INF-101",
  "instructor_ids": ["prof-123"],
  "expected_enrollment": 120,
  "lms": "ilias",
  "category": "courses",
  "status": "active",
  "created_at": "2026-03-30T10:00:00Z",
  "updated_at": "2026-03-30T12:00:00Z"
}
```

### Update Course / Kurs aktualisieren

```http
PUT /api/v1/courses/{course_id}
```

**Request Body:**

```json
{
  "title": "Einführung in die Informatik (Updated)",
  "expected_enrollment": 150,
  "status": "active"
}
```

### Delete Course / Kurs löschen

```http
DELETE /api/v1/courses/{course_id}
```

**Response:** `204 No Content`

> Note: This is a soft delete. The course status changes to `deleted`.

---

## Enrollment Endpoints / Einschreibungs-Endpunkte

### Bulk Enroll Users / Benutzer einschreiben

```http
POST /api/v1/courses/{course_id}/enrollments
```

**Request Body:**

```json
{
  "user_ids": ["user-001", "user-002", "user-003"],
  "role": "student"
}
```

**Roles:**
| Role | Description |
|------|-------------|
| `student` | Regular student enrollment |
| `tutor` | Teaching assistant |
| `instructor` | Course instructor |
| `auditor` | Read-only access |
| `guest` | Limited guest access |

**Response (201 Created):**

```json
[
  {
    "enrollment_id": "enr_abc123",
    "course_id": "crs_xyz789",
    "user_id": "user-001",
    "role": "student",
    "status": "active",
    "created_at": "2026-03-30T10:00:00Z"
  },
  {
    "enrollment_id": "enr_def456",
    "course_id": "crs_xyz789",
    "user_id": "user-002",
    "role": "student",
    "status": "active",
    "created_at": "2026-03-30T10:00:00Z"
  }
]
```

---

## Archival Endpoints / Archivierungs-Endpunkte

### Archive Course / Kurs archivieren

```http
POST /api/v1/archival/archive/{course_id}
```

**Request Body:**

```json
{
  "create_snapshots": true,
  "dry_run": false
}
```

**Response:**

```json
{
  "course_id": "crs_abc123",
  "archive_id": "arch_xyz789",
  "snapshot_id": "snap_def456",
  "status": "completed",
  "archived_at": "2026-03-30T10:00:00Z"
}
```

### Bulk Archive Courses / Massenarchivierung

```http
POST /api/v1/archival/bulk-archive
```

**Request Body (by semester):**

```json
{
  "semester_id": "2025ws",
  "create_snapshots": true,
  "dry_run": false
}
```

**Request Body (by course IDs):**

```json
{
  "course_ids": ["crs_001", "crs_002", "crs_003"],
  "create_snapshots": true,
  "dry_run": false
}
```

**Response (202 Accepted):**

```json
{
  "job_id": "job_abc123",
  "status": "in_progress",
  "total_courses": 45,
  "completed": 0,
  "failed": 0,
  "results": [],
  "started_at": "2026-03-30T10:00:00Z",
  "completed_at": null
}
```

### Restore Archived Course / Archivierten Kurs wiederherstellen

```http
POST /api/v1/archival/restore/{archive_id}
```

**Request Body:**

```json
{
  "restore_enrollments": true,
  "dry_run": false
}
```

**Response:**

```json
{
  "archive_id": "arch_xyz789",
  "course_id": "crs_abc123",
  "status": "completed",
  "restored_at": "2026-03-30T11:00:00Z"
}
```

### List Archives / Archive auflisten

```http
GET /api/v1/archival/archives
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `semester_id` | string | Filter by semester |
| `page` | integer | Page number |
| `page_size` | integer | Items per page |

### Get Bulk Job Status / Job-Status abrufen

```http
GET /api/v1/archival/jobs/{job_id}
```

---

## Semester Endpoints / Semester-Endpunkte

### Create Semester / Semester erstellen

```http
POST /api/v1/semesters
```

**Request Body:**

```json
{
  "semester_id": "2026ws",
  "name": "Wintersemester 2026/27",
  "name_en": "Winter Semester 2026/27",
  "type": "wintersemester",
  "start_date": "2026-10-01",
  "end_date": "2027-03-31"
}
```

**Response (201 Created):**

```json
{
  "semester_id": "2026ws",
  "name": "Wintersemester 2026/27",
  "name_en": "Winter Semester 2026/27",
  "type": "wintersemester",
  "start_date": "2026-10-01",
  "end_date": "2027-03-31",
  "status": "upcoming",
  "course_count": 0,
  "created_at": "2026-03-30T10:00:00Z"
}
```

### List Semesters / Semester auflisten

```http
GET /api/v1/semesters
```

**Response:**

```json
{
  "semesters": [
    {
      "semester_id": "2026ws",
      "name": "Wintersemester 2026/27",
      "name_en": "Winter Semester 2026/27",
      "type": "wintersemester",
      "start_date": "2026-10-01",
      "end_date": "2027-03-31",
      "status": "upcoming",
      "course_count": 0,
      "created_at": "2026-03-30T10:00:00Z"
    }
  ],
  "total": 1
}
```

---

## Audit Endpoints / Audit-Endpunkte

### List Audit Logs / Audit-Logs auflisten

```http
GET /api/v1/audit/logs
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `entity_type` | string | Filter by entity type (`course`, `semester`, `enrollment`) |
| `entity_id` | string | Filter by entity ID |
| `limit` | integer | Max results (default: 100, max: 1000) |

**Response:**

```json
{
  "logs": [
    {
      "log_id": "audit_abc123",
      "action": "course_created",
      "entity_type": "course",
      "entity_id": "crs_xyz789",
      "user_id": "admin",
      "details": {
        "title": "Introduction to Computer Science",
        "semester_id": "2026ws",
        "lms": "ilias"
      },
      "created_at": "2026-03-30T10:00:00Z"
    }
  ],
  "total": 150
}
```

---

## Health Endpoints / Gesundheits-Endpunkte

### Health Check / Gesundheitscheck

```http
GET /health
```

**Response:**

```json
{
  "status": "healthy"
}
```

### Readiness Check / Bereitschaftscheck

```http
GET /ready
```

**Response:**

```json
{
  "status": "ready"
}
```

---

## Error Responses / Fehlerantworten

### Standard Error Format

```json
{
  "error": "NotFound",
  "detail": "Course crs_nonexistent not found / Kurs crs_nonexistent nicht gefunden",
  "code": "COURSE_NOT_FOUND"
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| `200` | Success |
| `201` | Created |
| `202` | Accepted (async operation) |
| `204` | No Content (delete) |
| `400` | Bad Request |
| `404` | Not Found |
| `500` | Internal Server Error |

---

<a name="deutsch"></a>

## Deutsch

### Übersicht

Die Kursverwaltungs-API bietet eine RESTful-Schnittstelle zur Verwaltung von Universitätskursen in openDesk Edu. Sie umfasst Kurserstellung, Einschreibungsverwaltung, Semesterübergänge und Archivierungsworkflows mit nahtloser Integration in ILIAS, Moodle und Keycloak.

### Basis-URL

```
http://localhost:8000/api/v1
```

**Produktion:**

```
https://semester.{domain}/api/v1
```

### Authentifizierung

API-Endpunkte erfordern eine Authentifizierung über:

- **Bearer-Token**: `Authorization: Bearer <token>`
- **API-Schlüssel**: `X-API-Key: <key>`

### OpenAPI-Dokumentation

- **Swagger UI**: `/docs`
- **ReDoc**: `/redoc`
- **OpenAPI JSON**: `/openapi.json`

---

## Kurs-Endpunkte

### Kurs erstellen

```http
POST /api/v1/courses
```

**Anfragekörper:**

```json
{
  "semester_id": "2026ws",
  "title": "Einführung in die Informatik",
  "title_en": "Introduction to Computer Science",
  "course_code": "INF-101",
  "instructor_ids": ["prof-123"],
  "expected_enrollment": 120,
  "lms": "ilias",
  "category": "courses"
}
```

**Antwort (201 Erstellt):**

```json
{
  "course_id": "crs_abc123def456",
  "lms_course_id": "lms_xyz789",
  "semester_id": "2026ws",
  "title": "Einführung in die Informatik",
  "title_en": "Introduction to Computer Science",
  "course_code": "INF-101",
  "instructor_ids": ["prof-123"],
  "expected_enrollment": 120,
  "lms": "ilias",
  "category": "courses",
  "status": "draft",
  "created_at": "2026-03-30T10:00:00Z"
}
```

### Kurse auflisten

```http
GET /api/v1/courses
```

**Abfrageparameter:**
| Parameter | Typ | Erforderlich | Beschreibung |
|-----------|-----|--------------|--------------|
| `semester_id` | string | Nein | Nach Semesterkennung filtern |
| `status` | string | Nein | Nach Status filtern (`draft`, `active`, `archived`, `deleted`) |
| `lms` | string | Nein | Nach LMS filtern (`ilias`, `moodle`) |
| `page` | integer | Nein | Seitennummer (Standard: 1) |
| `page_size` | integer | Nein | Einträge pro Seite (Standard: 20, max: 100) |

**Beispielanfrage:**

```bash
curl "http://localhost:8000/api/v1/courses?semester_id=2026ws&status=active&page=1&page_size=20"
```

### Kurs abrufen

```http
GET /api/v1/courses/{course_id}
```

### Kurs aktualisieren

```http
PUT /api/v1/courses/{course_id}
```

**Anfragekörper:**

```json
{
  "title": "Einführung in die Informatik (Aktualisiert)",
  "expected_enrollment": 150,
  "status": "active"
}
```

### Kurs löschen

```http
DELETE /api/v1/courses/{course_id}
```

**Antwort:** `204 No Content`

> Hinweis: Dies ist ein Soft-Delete. Der Kursstatus ändert sich zu `deleted`.

---

## Einschreibungs-Endpunkte

### Benutzer einschreiben

```http
POST /api/v1/courses/{course_id}/enrollments
```

**Anfragekörper:**

```json
{
  "user_ids": ["user-001", "user-002", "user-003"],
  "role": "student"
}
```

**Rollen:**
| Rolle | Beschreibung |
|------|--------------|
| `student` | Reguläre Studenteneinschreibung |
| `tutor` | Tutor |
| `instructor` | Kursdozent |
| `auditor` | Nur-Lese-Zugriff |
| `guest` | Eingeschränkter Gastzugriff |

---

## Archivierungs-Endpunkte

### Kurs archivieren

```http
POST /api/v1/archival/archive/{course_id}
```

**Anfragekörper:**

```json
{
  "create_snapshots": true,
  "dry_run": false
}
```

### Massenarchivierung

```http
POST /api/v1/archival/bulk-archive
```

**Anfragekörper (nach Semester):**

```json
{
  "semester_id": "2025ws",
  "create_snapshots": true,
  "dry_run": false
}
```

### Archivierten Kurs wiederherstellen

```http
POST /api/v1/archival/restore/{archive_id}
```

**Anfragekörper:**

```json
{
  "restore_enrollments": true,
  "dry_run": false
}
```

---

## Semester-Endpunkte

### Semester erstellen

```http
POST /api/v1/semesters
```

**Anfragekörper:**

```json
{
  "semester_id": "2026ws",
  "name": "Wintersemester 2026/27",
  "name_en": "Winter Semester 2026/27",
  "type": "wintersemester",
  "start_date": "2026-10-01",
  "end_date": "2027-03-31"
}
```

### Semester auflisten

```http
GET /api/v1/semesters
```

---

## Audit-Endpunkte

### Audit-Logs auflisten

```http
GET /api/v1/audit/logs
```

**Abfrageparameter:**
| Parameter | Typ | Beschreibung |
|-----------|-----|--------------|
| `entity_type` | string | Nach Entitätstyp filtern (`course`, `semester`, `enrollment`) |
| `entity_id` | string | Nach Entitäts-ID filtern |
| `limit` | integer | Maximale Ergebnisse (Standard: 100, max: 1000) |

---

## Gesundheits-Endpunkte

### Gesundheitscheck

```http
GET /health
```

**Antwort:**

```json
{
  "status": "healthy"
}
```

### Bereitschaftscheck

```http
GET /ready
```

**Antwort:**

```json
{
  "status": "ready"
}
```

---

## Fehlerantworten

### Standard-Fehlerformat

```json
{
  "error": "NotFound",
  "detail": "Course crs_nonexistent not found / Kurs crs_nonexistent nicht gefunden",
  "code": "COURSE_NOT_FOUND"
}
```

### HTTP-Statuscodes

| Code | Beschreibung |
|------|--------------|
| `200` | Erfolg |
| `201` | Erstellt |
| `202` | Akzeptiert (asynchrone Operation) |
| `204` | Kein Inhalt (Löschen) |
| `400` | Ungültige Anfrage |
| `404` | Nicht gefunden |
| `500` | Interner Serverfehler |

---

## Verwandte Dokumentation

- [Semester Lifecycle](./semester-lifecycle.md) - Benutzerhandbuch
- [Semester Automation Guide](./semester-automation-guide.md) - Automatisierungseinrichtung
- [External Services](./external-services.md) - LMS-Integration
- [Getting Started](./getting-started.md) - Ersteinrichtung

# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH

# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"

# SPDX-License-Identifier: Apache-2.0

# Semester Provisioning API – API Reference / API-Schnittstelle zur Kursprovisionierung

This document provides a bilingual reference for the Semester Provisioning API used by openDesk Edu.

## Endpoints / Endpunkte

- POST /api/v1/courses – Create a new course
- POST /api/v1/courses/bulk-create – Bulk create courses
- GET /api/v1/courses/{course_id} – Retrieve a course
- PUT /api/v1/courses/{course_id} – Update a course
- DELETE /api/v1/courses/{course_id} – Soft-delete a course
- POST /api/v1/courses/{course_id}/enrollments – Bulk add enrollments
- GET /api/v1/enrollments/{course_id} – List enrollments for a course
- POST /api/v1/semesters – Create a new semester
- GET /api/v1/semesters – List semesters
- POST /api/v1/archival/archive/{course_id} – Archive a course
- POST /api/v1/archival/bulk-archive – Bulk archive courses
- POST /api/v1/webhooks/hisinone – HISinOne webhook (example integration)

## Key Concepts / Zentrale Konzepte

- Courses, Enrollments, Semesters, Archives
- Status flows: active, archived, deleted, upcoming, ended
- In-memory DB used in unit tests for isolation

## Example Snippet / Beispiel

```http
POST /api/v1/courses
Content-Type: application/json

{
  "semester_id": "2026ws",
  "title": "Intro to Open Data",
  "title_en": "Intro to Open Data",
  "course_code": "OPEN-101",
  "lms": "ilias"
}
```

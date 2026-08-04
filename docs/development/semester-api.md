<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# Semester Course Provisioning API Specification

This document defines the RESTful API for semester-based course lifecycle management in openDesk Edu. The API enables automated course provisioning, updates, and archival in coordination with university campus management systems (HISinOne, HISinOne-Proxy) and learning platforms (ILIAS, Moodle).

<!-- TOC -->
* [Semester Course Provisioning API Specification](#semester-course-provisioning-api-specification)
  * [Overview](#overview)
  * [Architecture](#architecture)
  * [Authentication and Authorization](#authentication-and-authorization)
    * [Token-Based Authentication](#token-based-authentication)
    * [Authorization Scopes](#authorization-scopes)
    * [Role-Based Access](#role-based-access)
  * [API Endpoints](#api-endpoints)
    * [Courses](#courses)
      * [Create Course](#create-course)
      * [Update Course](#update-course)
      * [Get Course](#get-course)
      * [List Courses](#list-courses)
      * [Archive Course](#archive-course)
      * [Restore Course](#restore-course)
      * [Delete Course](#delete-course)
    * [Semesters](#semesters)
      * [Create Semester](#create-semester)
      * [Get Semester](#get-semester)
      * [List Semesters](#list-semesters)
      * [Activate Semester](#activate-semester)
      * [Archive Semester](#archive-semester)
    * [Course Enrollment](#course-enrollment)
      * [Add Students to Course](#add-students-to-course)
      * [Remove Students from Course](#remove-students-from-course)
      * [Update Student Role](#update-student-role)
      * [Get Course Roster](#get-course-roster)
    * [Resource Quotas](#resource-quotas)
      * [Get Quota for Course](#get-quota-for-course)
      * [Update Quota for Course](#update-quota-for-course)
      * [Get Usage Statistics](#get-usage-statistics)
  * [Request and Response Schemas](#request-and-response-schemas)
    * [Course Object](#course-object)
    * [Semester Object](#semester-object)
    * [Enrollment Object](#enrollment-object)
    * [Quota Object](#quota-object)
    * [ErrorResponse Object](#errorresponse-object)
  * [Semester-Based Resource Allocation](#semester-based-resource-allocation)
    * [Allocation Model](#allocation-model)
    * [Quota Management](#quota-management)
    * [Automatic Scaling](#automatic-scaling)
  * [Rate Limiting and Throttling](#rate-limiting-and-throttling)
    * [Rate Limits](#rate-limits)
    * [Throttling Behavior](#throttling-behavior)
    * [Rate Limit Headers](#rate-limit-headers)
  * [Campus Management Integration](#campus-management-integration)
    * [HISinOne Integration](#hisinone-integration)
    * [HISinOne-Proxy Integration](#hisinone-proxy-integration)
    * [Synchronization Flow](#synchronization-flow)
  * [Error Handling](#error-handling)
    * [HTTP Status Codes](#http-status-codes)
    * [Error Response Format](#error-response-format)
    * [Common Error Scenarios](#common-error-scenarios)
  * [Webhooks and Event Notifications](#webhooks-and-event-notifications)
    * [Event Types](#event-types)
    * [Webhook Configuration](#webhook-configuration)
    * [Event Payload](#event-payload)
  * [Lifecycle Hooks](#lifecycle-hooks)
    * [Pre-Creation Hook](#pre-creation-hook)
    * [Post-Creation Hook](#post-creation-hook)
    * [Pre-Archival Hook](#pre-archival-hook)
    * [Post-Archival Hook](#post-archival-hook)
  * [Examples and Use Cases](#examples-and-use-cases)
    * [Semester Start Workflow](#semester-start-workflow)
    * [Course Update Workflow](#course-update-workflow)
    * [Semester End Workflow](#semester-end-workflow)
<!-- TOC -->

## Overview

The Semester Course Provisioning API provides a RESTful interface for managing the complete lifecycle of university courses on a semester basis. The API integrates with campus management systems (HISinOne, HISinOne-Proxy) to synchronize course data and manage resources across learning platforms.

**Core Capabilities:**

* **Course Lifecycle:** Create, update, archive, and restore courses
* **Semester Management:** Organize courses by academic semester (Wintersemester, Sommersemester)
* **Resource Allocation:** Manage storage quotas and course-level limits
* **Enrollment Management:** Synchronize student rosters and role assignments
* **Integration:** Connect with campus management systems via SAML/OIDC认证
* **Event Notifications:** Webhooks for course lifecycle events

**Semester Model:**

* **Wintersemester (WS):** October to March (e.g., WS 2025/26)
* **Sommersemester (SS):** April to September (e.g., SS 2026)

**Learning Platforms Supported:**

* ILIAS (primary LMS)
* Moodle (alternative LMS)
* BigBlueButton (video lectures)
* OpenCloud (file storage)

> [!note]
> This API specification is focused on design and integration patterns. The actual API implementation is planned for future development phases and will be implemented as a separate service or extension to the existing Keycloak-based IAM infrastructure.

## Architecture

The Semester Course Provisioning API is designed as a RESTful service that orchestrates course data between campus management systems, the identity provider (Keycloak), and learning platforms.

```
┌─────────────────┐
│ Campus Management│
│  (HISinOne/PCA)  │
└────────┬────────┘
         │ SAML/OIDC
         ▼
┌─────────────────────────────────────┐
│   Semester Provisioning API          │
│  (REST Service + Keycloak Extensions)│
└───────┬─────────────────┬───────────┘
        │                 │
        ▼                 ▼
┌───────────────┐ ┌──────────────────────┐
│   Keycloak    │ │  Learning Platforms  │
│   (IAM/RBAC)  │ │  (ILIAS, Moodle,     │
└───────┬───────┘ │   BBB, OpenCloud)    │
        │         └──────────────────────┘
        ▼
┌─────────────────────────────────┐
│     Resource Management          │
│  (Storage, Quotas, Backups)      │
└─────────────────────────────────┘
```

**Integration Points:**

1. **Campus Management System:**
   * HISinOne / HISinOne-Proxy as source of truth for course data
   * SAML/OIDC authentication for secure data exchange
   * Periodic synchronization or event-driven updates

2. **Identity Provider (Keycloak):**
   * User authentication and authorization
   * Role-based access control (instructor, student, tutor)
   * Semester groups for enrollment management

3. **Learning Platforms:**
   * Course creation via platform-specific APIs or bulk import
   * User provisioning through LDAP/REST
   * Resource allocation based on API quotas

4. **Resource Management:**
   * Persistent storage provisioning (OpenCloud, Nextcloud)
   * Per-course quota enforcement
   * Backup and archival workflows

## Authentication and Authorization

### Token-Based Authentication

All API endpoints require authentication via OAuth 2.0 access tokens issued by Keycloak.

**Authentication Flow:**

```http
POST /realms/opendesk/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
&client_id=semester-provisioning-api
&client_secret=<client-secret>
&scope=openid profile email courses:read courses:write courses:delete semesters:read semesters:write quotas:read quotas:write
```

**Authorization Header:**

```http
Authorization: Bearer <access-token>
```

**Token Validation:**

* JWT access tokens with RS256 signature
* Token lifetime: 15 minutes (configurable)
* Refresh tokens: 24 hours (configurable)
* Token introspection endpoint for offline validation

### Authorization Scopes

API access is controlled via OAuth 2.0 scopes assigned to client applications.

| Scope | Description | Required Endpoints |
|-------|-------------|-------------------|
| `courses:read` | Read course data | GET /courses/*, GET /semesters/*/courses |
| `courses:write` | Create and update courses | POST /courses, PUT /courses/{id}, PATCH /courses/{id} |
| `courses:delete` | Archive and delete courses | DELETE /courses/{id}, POST /courses/{id}/archive |
| `semesters:read` | Read semester data | GET /semesters/* |
| `semesters:write` | Create and manage semesters | POST /semesters, PUT /semesters/{id}/activate, POST /semesters/{id}/archive |
| `quotas:read` | Read quota information | GET /courses/{id}/quota, GET /courses/{id}/usage |
| `quotas:write` | Update quotas | PUT /courses/{id}/quota |

### Role-Based Access

Token-based access is supplemented with Keycloak groups/roles for fine-grained permissions.

**Required Roles by Endpoint:**

| Endpoint | Required Roles | Description |
|----------|---------------|-------------|
| POST /courses | `course-admin`, `system-admin` | Create new courses |
| PUT /courses/{id} | `course-admin`, `course-instructor:{id}` | Update course metadata |
| POST /courses/{id}/enrollment | `course-admin`, `course-instructor:{id}` | Manage enrollments |
| POST /courses/{id}/archive | `course-admin` | Archive courses |
| POST /semesters | `semester-admin`, `system-admin` | Create semesters |
| PUT /semesters/{id}/activate | `semester-admin` | Activate semester for provisioning |
| PUT /courses/{id}/quota | `quota-admin`, `system-admin` | Update course quotas |

**Group-Based Enrollment:**

* Semester groups: `semester:WS2025:students`, `semester:WS2025:instructors`
* Course-specific groups: `course:CS101:instructors`, `course:CS101:students`
* Role inheritance: Instructors have read access to all courses in their semester

> [!important]
> Client credentials are used for service-to-service authentication (e.g., campus management system integration). For user-initiated actions (e.g., instructor updating course metadata), use Resource Owner Password Credentials or Authorization Code flow.

## API Endpoints

All API endpoints are prefixed with `/api/v1/semesters`.

**Base URL:**

```
https://api.education.example.org/api/v1/semesters
```

### Courses

#### Create Course

**Endpoint:** `POST /courses`

**Description:** Create a new course in the specified semester.

**Request Body:**

```json
{
  "semesterCode": "WS2025/26",
  "courseCode": "CS101",
  "title": "Introduction to Computer Science",
  "description": "Fundamentals of programming and algorithms",
  "lecturerIds": ["user:instructor1@example.org", "user:instructor2@example.org"],
  "tutorIds": ["user:tutor1@example.org"],
  "room": "Building A, Room 101",
  "schedule": {
    "days": ["Monday", "Wednesday"],
    "startTime": "10:00",
    "endTime": "11:30",
    "startDate": "2025-10-01",
    "endDate": "2026-03-15"
  },
  "platforms": {
    "ilias": "enabled",
    "moodle": "disabled",
    "bbb": "enabled",
    "opencloud": "enabled"
  },
  "quota": {
    "storageGB": 100,
    "studentQuotaGB": 2,
    "maxStudents": 200
  }
}
```

**Response:** `200 OK`

```json
{
  "id": "course:CS101:WS2025/26",
  "semesterCode": "WS2025/26",
  "courseCode": "CS101",
  "title": "Introduction to Computer Science",
  "description": "Fundamentals of programming and algorithms",
  "status": "active",
  "lecturerIds": ["user:instructor1@example.org", "user:instructor2@example.org"],
  "tutorIds": ["user:tutor1@example.org"],
  "room": "Building A, Room 101",
  "schedule": {
    "days": ["Monday", "Wednesday"],
    "startTime": "10:00",
    "endTime": "11:30",
    "startDate": "2025-10-01",
    "endDate": "2026-03-15"
  },
  "platforms": {
    "ilias": {
      "enabled": true,
      "courseId": "ilias_cs101_ws202526",
      "url": "https://lms.education.example.org/goto.php?target=crs_12345"
    },
    "moodle": {
      "enabled": false,
      "courseId": null,
      "url": null
    },
    "bbb": {
      "enabled": true,
      "roomName": "CS101_WS202526",
      "url": "https://meet.education.example.org/b/cs101-ws202526"
    },
    "opencloud": {
      "enabled": true,
      "sharePath": "/courses/CS101_WS202526",
      "url": "https://files.education.example.org/apps/files/?dir=/courses/CS101_WS202526"
    }
  },
  "quota": {
    "storageGB": 100,
    "studentQuotaGB": 2,
    "maxStudents": 200,
    "currentStorageUsageGB": 0,
    "currentStudentCount": 0
  },
  "createdAt": "2025-10-01T08:00:00Z",
  "updatedAt": "2025-10-01T08:00:00Z",
  "createdBy": "system:hisinone-integration"
}
```

**Error Responses:**

* `400 Bad Request`: Invalid request body
* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `409 Conflict`: Course already exists for this semester

#### Update Course

**Endpoint:** `PATCH /courses/{courseId}`

**Description:** Update course metadata (partial update). Use PATCH for partial updates or PUT for full replacement.

**Request Body:**

```json
{
  "title": "Introduction to Computer Science (Updated)",
  "lecturerIds": ["user:instructor1@example.org", "user:new-instructor@example.org"],
  "quota": {
    "storageGB": 150,
    "maxStudents": 250
  }
}
```

**Response:** `200 OK`

```json
{
  "id": "course:CS101:WS2025/26",
  "semesterCode": "WS2025/26",
  "courseCode": "CS101",
  "title": "Introduction to Computer Science (Updated)",
  "status": "active",
  "lecturerIds": ["user:instructor1@example.org", "user:new-instructor@example.org"],
  "quota": {
    "storageGB": 150,
    "studentQuotaGB": 2,
    "maxStudents": 250,
    "currentStorageUsageGB": 5.2,
    "currentStudentCount": 50
  },
  "updatedAt": "2025-10-15T10:30:00Z",
  "updatedBy": "user:instructor1@example.org"
}
```

**Error Responses:**

* `400 Bad Request`: Invalid request body
* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `404 Not Found`: Course not found

#### Get Course

**Endpoint:** `GET /courses/{courseId}`

**Description:** Retrieve detailed information about a specific course.

**Response:** `200 OK`

Returns the same response structure as Create Course.

**Error Responses:**

* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `404 Not Found`: Course not found

#### List Courses

**Endpoint:** `GET /courses`

**Description:** List all courses with optional filtering.

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `semester` | string | No | Filter by semester code (e.g., `WS2025/26`) |
| `status` | string | No | Filter by status (`active`, `archived`, `restored`) |
| `lecturer` | string | No | Filter by lecturer ID |
| `courseCode` | string | No | Filter by course code |
| `limit` | integer | No | Maximum number of results (default: 50, max: 1000) |
| `offset` | integer | No | Pagination offset (default: 0) |

**Request Example:**

```
GET /courses?semester=WS2025/26&status=active&limit=50&offset=0
```

**Response:** `200 OK`

```json
{
  "courses": [
    {
      "id": "course:CS101:WS2025/26",
      "semesterCode": "WS2025/26",
      "courseCode": "CS101",
      "title": "Introduction to Computer Science",
      "status": "active",
      "lecturerIds": ["user:instructor1@example.org"],
      "quota": {
        "storageGB": 100,
        "maxStudents": 200,
        "currentStudentCount": 50
      },
      "createdAt": "2025-10-01T08:00:00Z"
    }
  ],
  "pagination": {
    "total": 150,
    "limit": 50,
    "offset": 0,
    "hasMore": true
  }
}
```

**Error Responses:**

* `400 Bad Request`: Invalid query parameters
* `401 Unauthorized`: Missing or invalid authentication token

#### Archive Course

**Endpoint:** `POST /courses/{courseId}/archive`

**Description:** Archive a course at the end of semester. freezes enrollments, archives content, marks course as read-only.

**Request Body:**

```json
{
  "retentionYears": 5,
  "archiveContent": true,
  "preserveRatings": false,
  "archiveReason": "Semester end - WS2025/26"
}
```

**Response:** `202 Accepted`

```json
{
  "id": "course:CS101:WS2025/26",
  "status": "archived",
  "archivedAt": "2026-04-01T00:00:00Z",
  "retentionUntil": "2031-04-01T00:00:00Z",
  "archiveContent": true,
  "archivedLocations": {
    "ilias": " archived_courses/CS101_WS202526",
    "bbb": "recordings/CS101_WS202526",
    "opencloud": "archived_courses/CS101_WS202526"
  }
}
```

**Archive Workflow:**

1. Freeze all course enrollments
2. Export course content (ILIAS materials, BBB recordings)
3. Mark course as read-only
4. Move archived content to long-term storage
5. Update Keycloak groups (move students to archived course groups)
6. Trigger webhook notification

**Error Responses:**

* `400 Bad Request`: Invalid request body
* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `404 Not Found`: Course not found
* `409 Conflict`: Course already archived

#### Restore Course

**Endpoint:** `POST /courses/{courseId}/restore`

**Description:** Restore a previously archived course for reuse.

**Request Body:**

```json
{
  "newSemesterCode": "WS2026/27",
  "copyContent": true,
  " copyParticipants": false
}
```

**Response:** `202 Accepted`

```json
{
  "id": "course:CS101:WS2026/27",
  "originalId": "course:CS101:WS2025/26",
  "semesterCode": "WS2026/27",
  "status": "active",
  "restoredFrom": "course:CS101:WS2025/26",
  "restoredAt": "2026-10-01T08:30:00Z",
  "contentCopied": true,
  "participantsCopied": false
}
```

**Error Responses:**

* `400 Bad Request`: Invalid request body
* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `404 Not Found`: Course not found
* `409 Conflict`: Course already exists in target semester

#### Delete Course

**Endpoint:** `DELETE /courses/{courseId}`

**Description:** Permanently delete a course (use with caution). This action is irreversible.

**Request Body:**

```json
{
  "reason": "Administrative deletion - duplicate course",
  "preserveContent": false
}
```

**Response:** `202 Accepted`

```json
{
  "id": "course:CS101:WS2025/26",
  "status": "deleted",
  "deletedAt": "2025-10-10T14:00:00Z",
  "reason": "Administrative deletion - duplicate course",
  "contentPreserved": false
}
```

> [!warning]
> **Permanent Deletion:** This operation cannot be undone. Consider archiving instead for courses that may be needed again.

**Error Responses:**

* `400 Bad Request`: Invalid request body
* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `404 Not Found`: Course not found
* `409 Conflict`: Course is archived (restore before deletion)

### Semesters

#### Create Semester

**Endpoint:** `POST /semesters`

**Description:** Create a new academic semester.

**Request Body:**

```json
{
  "semesterCode": "WS2025/26",
  "name": "Wintersemester 2025/26",
  "startDate": "2025-10-01",
  "endDate": "2026-03-31",
  "type": "winter",
  "status": "upcoming",
  "defaultQuota": {
    "storageGB": 100,
    "studentQuotaGB": 2,
    "maxStudents": 200
  }
}
```

**Response:** `201 Created`

```json
{
  "id": "semester:WS2025/26",
  "semesterCode": "WS2025/26",
  "name": "Wintersemester 2025/26",
  "startDate": "2025-10-01",
  "endDate": "2026-03-31",
  "type": "winter",
  "status": "upcoming",
  "defaultQuota": {
    "storageGB": 100,
    "studentQuotaGB": 2,
    "maxStudents": 200
  },
  "createdAt": "2025-06-01T10:00:00Z",
  "createdBy": "system:semester-admin"
}
```

**Error Responses:**

* `400 Bad Request`: Invalid request body
* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `409 Conflict`: Semester already exists

#### Get Semester

**Endpoint:** `GET /semesters/{semesterCode}`

**Description:** Retrieve detailed information about a specific semester.

**Response:** `200 OK`

```json
{
  "id": "semester:WS2025/26",
  "semesterCode": "WS2025/26",
  "name": "Wintersemester 2025/26",
  "startDate": "2025-10-01",
  "endDate": "2026-03-31",
  "type": "winter",
  "status": "active",
  "defaultQuota": {
    "storageGB": 100,
    "studentQuotaGB": 2,
    "maxStudents": 200
  },
  "statistics": {
    "totalCourses": 150,
    "activeCourses": 148,
    "archivedCourses": 2,
    "totalStudents": 4500,
    "totalStorageGB": 15000,
    "storageUsedGB": 7250
  },
  "createdAt": "2025-06-01T10:00:00Z",
  "activatedAt": "2025-10-01T00:00:00Z"
}
```

**Error Responses:**

* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `404 Not Found`: Semester not found

#### List Semesters

**Endpoint:** `GET /semesters`

**Description:** List all semesters.

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `status` | string | No | Filter by status (`upcoming`, `active`, `archived`) |
| `type` | string | No | Filter by type (`winter`, `summer`) |
| `limit` | integer | No | Maximum number of results (default: 20, max: 100) |
| `offset` | integer | No | Pagination offset (default: 0) |

**Response:** `200 OK`

```json
{
  "semesters": [
    {
      "id": "semester:WS2025/26",
      "semesterCode": "WS2025/26",
      "name": "Wintersemester 2025/26",
      "startDate": "2025-10-01",
      "endDate": "2026-03-31",
      "type": "winter",
      "status": "active"
    }
  ],
  "pagination": {
    "total": 10,
    "limit": 20,
    "offset": 0,
    "hasMore": false
  }
}
```

**Error Responses:**

* `401 Unauthorized`: Missing or invalid authentication token

#### Activate Semester

**Endpoint:** `PUT /semesters/{semesterCode}/activate`

**Description:** Activate a semester for course provisioning. Once activated, courses can be created and enrollments can be managed.

**Request Body:** (empty, or optional activation reason)

```json
{
  "reason": "Semester start - standard activation"
}
```

**Response:** `200 OK`

```json
{
  "id": "semester:WS2025/26",
  "semesterCode": "WS2025/26",
  "status": "active",
  "activatedAt": "2025-10-01T00:00:00Z",
  "activatedBy": "system:semester-admin"
}
```

**Activation Workflow:**

1. Set semester status to `active`
2. Create Keycloak groups for the semester (`semester:WS2025/26:students`, `semester:WS2025/26:instructors`)
3. Enable provisioning API endpoints for this semester
4. Trigger webhook notification
5. Begin synchronization with campus management system

**Error Responses:**

* `400 Bad Request`: Invalid request body
* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `404 Not Found`: Semester not found
* `409 Conflict`: Semester already active

#### Archive Semester

**Endpoint:** `POST /semesters/{semesterCode}/archive`

**Description:** Archive an entire semester. Archives all courses within the semester.

**Request Body:**

```json
{
  "retentionYears": 5,
  "reason": "Semester end - WS2025/26"
}
```

**Response:** `202 Accepted`

```json
{
  "id": "semester:WS2025/26",
  "semesterCode": "WS2025/26",
  "status": "archived",
  "archivedAt": "2026-04-01T00:00:00Z",
  "retentionUntil": "2031-04-01T00:00:00Z",
  "coursesProcessed": 150,
  "coursesArchived": 148,
  "coursesFailed": 2,
  "failures": [
    {
      "courseId": "course:CS999:WS2025/26",
      "error": "Course already archived"
    }
  ]
}
```

**Archive Workflow:**

1. Set semester status to `archived`
2. Archive all courses in the semester (see Archive Course workflow)
3. Mark Keycloak semester groups as read-only
4. Move archived content to long-term storage
5. Disable provisioning API endpoints for this semester
6. Trigger webhook notification

**Error Responses:**

* `400 Bad Request`: Invalid request body
* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `404 Not Found`: Semester not found
* `409 Conflict`: Semester already archived

### Course Enrollment

#### Add Students to Course

**Endpoint:** `POST /courses/{courseId}/enrollment`

**Description:** Batch add students to a course.

**Request Body:**

```json
{
  "studentIds": [
    "user:student1@example.org",
    "user:student2@example.org",
    "user:student3@example.org"
  ],
  "role": "student",
  "enrollmentDate": "2025-10-01T00:00:00Z"
}
```

**Response:** `200 OK`

```json
{
  "courseId": "course:CS101:WS2025/26",
  "enrollmentsProcessed": 3,
  "enrollmentsSuccessful": 3,
  "enrollmentsFailed": 0,
  "enrollments": [
    {
      "userId": "user:student1@example.org",
      "role": "student",
      "enrolledAt": "2025-10-01T08:00:00Z",
      "platformAccess": {
        "ilias": true,
        "moodle": false,
        "bbb": true,
        "opencloud": true
      }
    },
    {
      "userId": "user:student2@example.org",
      "role": "student",
      "enrolledAt": "2025-10-01T08:00:00Z",
      "platformAccess": {
        "ilias": true,
        "moodle": false,
        "bbb": true,
        "opencloud": true
      }
    },
    {
      "userId": "user:student3@example.org",
      "role": "student",
      "enrolledAt": "2025-10-01T08:00:00Z",
      "platformAccess": {
        "ilias": true,
        "moodle": false,
        "bbb": true,
        "opencloud": true
      }
    }
  ]
}
```

**Enrollment Workflow:**

1. Validate student IDs against Keycloak
2. Add students to course Keycloak group
3. Provision accounts on enabled platforms (ILIAS, BBB, OpenCloud)
4. Create personal folder in OpenCloud course share
5. Send enrollment notification (optional)
6. Trigger webhook notification

**Error Responses:**

* `400 Bad Request`: Invalid request body
* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `404 Not Found`: Course not found
* `409 Conflict`: Student already enrolled
* `422 Unprocessable Entity`: Course has reached student quota

#### Remove Students from Course

**Endpoint:** `DELETE /courses/{courseId}/enrollment`

**Description:** Batch remove students from a course.

**Request Body:**

```json
{
  "studentIds": [
    "user:student1@example.org",
    "user:student2@example.org"
  ],
  "reason": "Student withdrawal"
}
```

**Response:** `200 OK`

```json
{
  "courseId": "course:CS101:WS2025/26",
  "enrollmentsProcessed": 2,
  "enrollmentsSuccessful": 2,
  "enrollmentsFailed": 0,
  "enrollments": [
    {
      "userId": "user:student1@example.org",
      "removedAt": "2025-10-15T14:00:00Z",
      "reason": "Student withdrawal",
      "accessRevoked": true
    },
    {
      "userId": "user:student2@example.org",
      "removedAt": "2025-10-15T14:00:00Z",
      "reason": "Student withdrawal",
      "accessRevoked": true
    }
  ]
}
```

**Removal Workflow:**

1. Remove students from course Keycloak group
2. Revoke platform access (ILIAS, BBB, OpenCloud)
3. Archive student data/grades (if configured)
4. Send withdrawal notification (optional)
5. Trigger webhook notification

**Error Responses:**

* `400 Bad Request`: Invalid request body
* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `404 Not Found`: Course not found

#### Update Student Role

**Endpoint:** `PATCH /courses/{courseId}/enrollment/{userId}`

**Description:** Update a student's role within a course (e.g., promote student to tutor).

**Request Body:**

```json
{
  "role": "tutor",
  "reason": "Student promoted to teaching assistant"
}
```

**Response:** `200 OK`

```json
{
  "userId": "user:student1@example.org",
  "courseId": "course:CS101:WS2025/26",
  "previousRole": "student",
  "newRole": "tutor",
  "updatedAt": "2025-10-20T10:00:00Z",
  "updatedBy": "user:instructor1@example.org"
}
```

**Error Responses:**

* `400 Bad Request`: Invalid request body
* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `404 Not Found`: Course or user not found

#### Get Course Roster

**Endpoint:** `GET /courses/{courseId}/enrollment`

**Description:** Retrieve the complete roster for a course.

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `role` | string | No | Filter by role (`student`, `tutor`, `instructor`) |
| `limit` | integer | No | Maximum number of results (default: 100, max: 1000) |
| `offset` | integer | No | Pagination offset (default: 0) |

**Response:** `200 OK`

```json
{
  "courseId": "course:CS101:WS2025/26",
  "totalEnrolled": 50,
  "enrollments": [
    {
      "userId": "user:student1@example.org",
      "role": "student",
      "enrolledAt": "2025-10-01T08:00:00Z",
      "lastAccessAt": "2025-10-20T14:30:00Z"
    },
    {
      "userId": "user:tutor1@example.org",
      "role": "tutor",
      "enrolledAt": "2025-10-01T08:00:00Z",
      "lastAccessAt": "2025-10-20T16:45:00Z"
    }
  ],
  "pagination": {
    "total": 50,
    "limit": 100,
    "offset": 0,
    "hasMore": false
  }
}
```

**Error Responses:**

* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `404 Not Found`: Course not found

### Resource Quotas

#### Get Quota for Course

**Endpoint:** `GET /courses/{courseId}/quota`

**Description:** Retrieve storage and usage quotas for a course.

**Response:** `200 OK`

```json
{
  "courseId": "course:CS101:WS2025/26",
  "quotaLimits": {
    "storageGB": 100,
    "studentQuotaGB": 2,
    "maxStudents": 200
  },
  "currentUsage": {
    "storageUsedGB": 45.2,
    "studentCount": 150,
    "storageUtilizationPercent": 45.2,
    "studentUtilizationPercent": 75.0
  },
  "breakdown": {
    "ilias": {
      "storageUsedGB": 30.5,
      "fileCount": 1250
    },
    "bbb": {
      "storageUsedGB": 10.0,
      "recordingHours": 25
    },
    "opencloud": {
      "storageUsedGB": 4.7,
      "sharedLinks": 45
    }
  },
  "status": "healthy",
  "warnings": [
    "Approaching student quota limit (75% used)"
  ]
}
```

**Error Responses:**

* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `404 Not Found`: Course not found

#### Update Quota for Course

**Endpoint:** `PUT /courses/{courseId}/quota`

**Description:** Update storage and usage quotas for a course.

**Request Body:**

```json
{
  "storageGB": 150,
  "studentQuotaGB": 3,
  "maxStudents": 250,
  "reason": "Increased quota for additional course materials"
}
```

**Response:** `200 OK`

```json
{
  "courseId": "course:CS101:WS2025/26",
  "quotaLimits": {
    "storageGB": 150,
    "studentQuotaGB": 3,
    "maxStudents": 250
  },
  "previousQuota": {
    "storageGB": 100,
    "studentQuotaGB": 2,
    "maxStudents": 200
  },
  "updatedAt": "2025-10-15T10:30:00Z",
  "updatedBy": "user:admin@example.org"
}
```

**Error Responses:**

* `400 Bad Request`: Invalid request body
* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `404 Not Found`: Course not found

#### Get Usage Statistics

**Endpoint:** `GET /courses/{courseId}/usage`

**Description:** Retrieve detailed usage statistics for a course.

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `startDate` | string | No | Start date (ISO 8601 format) |
| `endDate` | string | No | End date (ISO 8601 format) |
| `granularity` | string | No | Time granularity (`day`, `week`, `month`) |

**Response:** `200 OK`

```json
{
  "courseId": "course:CS101:WS2025/26",
  "period": {
    "startDate": "2025-10-01T00:00:00Z",
    "endDate": "2025-10-31T23:59:59Z",
    "granularity": "day"
  },
  "storage": {
    "totalUsedGB": 45.2,
    "trend": "increasing",
    "forecastGB": 60.0
  },
  "access": {
    "totalLogins": 450,
    "uniqueUsers": 150,
    "averageSessionDurationMinutes": 45,
    "peakUsage": {
      "date": "2025-10-15",
      "concurrentUsers": 45
    }
  },
  "platforms": {
    "ilias": {
      "pageViews": 15000,
      "uniqueVisitors": 145,
      "fileDownloads": 2500
    },
    "bbb": {
      "totalSessions": 25,
      "totalMinutes": 1500,
      "recordings": 5
    },
    "opencloud": {
      "filesUploaded": 350,
      "filesDownloaded": 800,
      "sharesCreated": 45
    }
  }
}
```

**Error Responses:**

* `400 Bad Request`: Invalid query parameters
* `401 Unauthorized`: Missing or invalid authentication token
* `403 Forbidden`: Insufficient permissions
* `404 Not Found`: Course not found

## Request and Response Schemas

### Course Object

```json
{
  "id": "string (course:CODE:SEMESTER)",
  "semesterCode": "string (WS2025/26 or SS2026)",
  "courseCode": "string (CS101)",
  "title": "string",
  "description": "string (optional)",
  "status": "string (active, archived, restored, deleted)",
  "lecturerIds": ["string"],
  "tutorIds": ["string"],
  "room": "string (optional)",
  "schedule": {
    "days": ["string"],
    "startTime": "string (HH:MM)",
    "endTime": "string (HH:MM)",
    "startDate": "string (ISO 8601 date)",
    "endDate": "string (ISO 8601 date)"
  },
  "platforms": {
    "ilias": {
      "enabled": "boolean",
      "courseId": "string (optional)",
      "url": "string (optional)"
    },
    "moodle": {
      "enabled": "boolean",
      "courseId": "string (optional)",
      "url": "string (optional)"
    },
    "bbb": {
      "enabled": "boolean",
      "roomName": "string (optional)",
      "url": "string (optional)"
    },
    "opencloud": {
      "enabled": "boolean",
      "sharePath": "string (optional)",
      "url": "string (optional)"
    }
  },
  "quota": {
    "storageGB": "integer",
    "studentQuotaGB": "integer",
    "maxStudents": "integer",
    "currentStorageUsageGB": "number",
    "currentStudentCount": "integer"
  },
  "createdAt": "string (ISO 8601 datetime)",
  "updatedAt": "string (ISO 8601 datetime)",
  "createdBy": "string",
  "updatedBy": "string (optional)"
}
```

### Semester Object

```json
{
  "id": "string (semester:CODE)",
  "semesterCode": "string (WS2025/26 or SS2026)",
  "name": "string",
  "startDate": "string (ISO 8601 date)",
  "endDate": "string (ISO 8601 date)",
  "type": "string (winter, summer)",
  "status": "string (upcoming, active, archived)",
  "defaultQuota": {
    "storageGB": "integer",
    "studentQuotaGB": "integer",
    "maxStudents": "integer"
  },
  "statistics": {
    "totalCourses": "integer",
    "activeCourses": "integer",
    "archivedCourses": "integer",
    "totalStudents": "integer",
    "totalStorageGB": "integer",
    "storageUsedGB": "number"
  },
  "createdAt": "string (ISO 8601 datetime)",
  "activatedAt": "string (ISO 8601 datetime, optional)",
  "archivedAt": "string (ISO 8601 datetime, optional)"
}
```

### Enrollment Object

```json
{
  "userId": "string",
  "courseId": "string",
  "role": "string (student, tutor, instructor)",
  "enrolledAt": "string (ISO 8601 datetime)",
  "lastAccessAt": "string (ISO 8601 datetime, optional)",
  "platformAccess": {
    "ilias": "boolean",
    "moodle": "boolean",
    "bbb": "boolean",
    "opencloud": "boolean"
  }
}
```

### Quota Object

```json
{
  "courseId": "string",
  "quotaLimits": {
    "storageGB": "integer",
    "studentQuotaGB": "integer",
    "maxStudents": "integer"
  },
  "currentUsage": {
    "storageUsedGB": "number",
    "studentCount": "integer",
    "storageUtilizationPercent": "number",
    "studentUtilizationPercent": "number"
  },
  "breakdown": {
    "ilias": {
      "storageUsedGB": "number",
      "fileCount": "integer"
    },
    "bbb": {
      "storageUsedGB": "number",
      "recordingHours": "integer"
    },
    "opencloud": {
      "storageUsedGB": "number",
      "sharedLinks": "integer"
    }
  },
  "status": "string (healthy, warning, critical)",
  "warnings": ["string"],
  "errors": ["string"]
}
```

### ErrorResponse Object

```json
{
  "error": {
    "code": "string (e.g., COURSE_NOT_FOUND)",
    "message": "string (human-readable error message)",
    "details": {
      "courseId": "string",
      "semesterCode": "string"
    },
    "requestId": "string (unique request identifier)",
    "timestamp": "string (ISO 8601 datetime)"
  }
}
```

## Semester-Based Resource Allocation

### Allocation Model

The semester-based resource allocation model ensures fair and predictable resource distribution across all courses within a semester.

**Allocation Principles:**

1. **Predictable Quotas:** Each course is allocated a fixed storage quota at creation time
2. **Student-Based Scaling:** Quotas can be adjusted based on actual enrollment
3. **Accountability:** Instructors can request quota increases through API
4. **Monitoring:** Real-time tracking of resource usage across the semester

**Default Quota Configuration:**

| Course Size | Storage GB | Per-Student GB | Max Students |
|-------------|------------|----------------|--------------|
| Small (<50 students) | 50 GB | 1 GB | 50 |
| Medium (50-200 students) | 100 GB | 2 GB | 200 |
| Large (>200 students) | 300 GB | 1.5 GB | 500 |
| Research/Lab | 500 GB | 5 GB | 100 |

**Quota Allocation Process:**

1. Semester activation creates initial quota pool
2. Course creation allocates per-course quotas from pool
3. Real-time monitoring tracks actual usage vs. allocated
4. Automatic alerts when approaching quota limits
5. Manual approval for quota increases exceeding pool

### Quota Management

Quota management is handled through the API endpoints `/courses/{id}/quota` and `/courses/{id}/usage`.

**Quota Lifecycle:**

1. **Initial Allocation:** Set during course creation based on semester defaults
2. **Monitoring:** Track usage via `/courses/{id}/usage` endpoint
3. **Adjustment:** Update quotas via `/courses/{id}/quota` endpoint
4. **Warning:** API returns warnings when approaching limits (75%, 90%)
5. **Enforcement:** Platform-specific quota enforcement (OpenCloud, ILIAS)

**Quota Enforcement:**

* **OpenCloud:** Per-user quota within course share
* **ILIAS:** Max file upload size per course
* **BBB:** Per-recording storage limits
* **Moodle:** Course backup size limits

### Automatic Scaling

The API supports automatic quota scaling based on enrollment growth.

**Scaling Triggers:**

* Student enrollment exceeds 90% of max students
* Storage usage exceeds 80% of allocated
* Instructor requests quota increase

**Scaling Policy:**

```json
{
  "autoScaling": {
    "enabled": true,
    "rules": [
      {
        "condition": "studentCount > maxStudents * 0.9",
        "action": {
          "type": "increase",
          "property": "maxStudents",
          "value": "maxStudents * 1.5",
          "maxLimit": 1000
        }
      },
      {
        "condition": "storageUtilization > 0.8",
        "action": {
          "type": "increase",
          "property": "storageGB",
          "value": "storageGB * 1.5",
          "maxLimit": 1000
        }
      }
    ]
  }
}
```

**Scaling Approval:**

* Automatic scaling within preset limits (e.g., up to 2x initial quota)
* Admin approval required for scaling beyond preset limits
* Notification sent to instructors and system administrators

## Rate Limiting and Throttling

### Rate Limits

To ensure fair API usage and system stability, the API implements rate limiting per client.

**Rate Limit Buckets:**

| Rate Limit | Bucket | Description |
|------------|--------|-------------|
| 1000 requests/hour | `course-admin` | Course administration operations |
| 100 requests/minute | `course-read` | Read operations (GET /courses) |
| 10 requests/second | `enrollment-batch` | Batch enrollment operations |
| Unlimited | `system-admin` | System maintenance operations (with special scope) |

**Rate Limit Headers:**

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 847
X-RateLimit-Reset: 1698765432
X-RateLimit-Bucket: course-admin
```

### Throttling Behavior

**When Rate Limit Exceeded:**

* Client receives `429 Too Many Requests` response
* `Retry-After` header indicates when request can be retried (in seconds)
* Request is queued if using batch operations
* Automatic exponential backoff recommended for retries

**Throttling Response:**

```http
HTTP/1.1 429 Too Many Requests
Content-Type: application/json
Retry-After: 60

{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Please retry after 60 seconds.",
    "details": {
      "rateLimit": 1000,
      "rateLimitRemaining": 0,
      "rateLimitReset": "2025-10-31T14:00:00Z",
      "bucket": "course-admin"
    }
  }
}
```

**Recommended Retry Logic:**

```python
import time
import json
import requests

def make_api_request(url, headers, body, max_retries=3):
    retry_count = 0
    while retry_count < max_retries:
        response = requests.post(url, headers=headers, json=body)

        if response.status_code == 429:
            retry_after = int(response.headers.get('Retry-After', 60))
            time.sleep(retry_after)
            retry_count += 1
            continue

        response.raise_for_status()
        return response.json()

    raise Exception("Max retries exceeded")
```

### Rate Limit Headers

**Standard Headers:**

| Header | Description |
|--------|-------------|
| `X-RateLimit-Limit` | Maximum requests allowed in current period |
| `X-RateLimit-Remaining` | Remaining requests in current period |
| `X-RateLimit-Reset` | Unix timestamp when quota resets |
| `X-RateLimit-Bucket` | Name of rate limit bucket |
| `Retry-After` | Seconds to wait before retrying (on 429) |

**Rate Limit Periods:**

* Hourly: Resets every hour (e.g., 1000 requests/hour)
* Per-minute: Resets every minute (e.g., 100 requests/minute)
* Per-second: Resets every second (e.g., 10 requests/second)

**Rate Limit Calculation:**

```
Rate Limit Remaining = Rate Limit Limit - Requests in Current Period
Rate Limit Reset = Current Time + Time to Next Period Boundary
```

## Campus Management Integration

### HISinOne Integration

**Overview:**

HISinOne is a campus management system (PCA) that manages course data, student enrollments, and academic records. The Semester Provisioning API integrates with HISinOne via SAML/OIDC authentication to synchronize course data.

**Integration Pattern:**

1. **Authentication:** SAML/OIDC-based authentication with HISinOne
2. **Data Synchronization:** Periodic pull or event-driven push of course data
3. **Course Mapping:** HISinOne course codes map to openDesk Edu course IDs
4. **Enrollment Sync:** Student enrollments synchronized from HISinOne

**Synchronization Triggers:**

* New semester activation
* Course creation/update in HISinOne
* Student enrollment changes
* Instructor assignment changes

**Synchronization Endpoints:**

```
GET /hisinone/semesters/{semesterCode}/courses
GET /hisinone/semesters/{semesterCode}/courses/{courseCode}/enrollment
POST /hisinone/sync/semester/{semesterCode}
```

**Authentication Flow:**

1. HISinOne integration service obtains OAuth 2.0 access token from Keycloak
2. Token includes `courses:read` and `courses:write` scopes
3. HISinOne API validates token via introspection endpoint
4. Authorized requests proceed to provisioning API

### HISinOne-Proxy Integration

**Overview:**

HISinOne-Proxy is a lightweight proxy layer that provides a simplified API interface to HISinOne. This proxy can be used when direct HISinOne integration is not feasible.

**Proxy Benefits:**

* Simplified API interface (no complex SAML/OIDC flow required)
* Caching layer reduces load on HISinOne
* Transformation layer for data mapping
* Authentication/authorization proxy

**Proxy API Pattern:**

```
GET /proxy/hisinone/semesters/{semesterCode}/courses
GET /proxy/hisinone/courses/{courseCode}/enrollment
POST /proxy/sync/trigger?semester={semesterCode}
```

**Proxy Configuration:**

```yaml
proxy:
  enabled: true
  hisinoneBaseUrl: "https://hisinone.university.edu/api"
  hisinoneCredentials:
    username: "opendesk-edu"
    password: "${HISINONE_PASSWORD}"
  cache:
    enabled: true
    ttl: 300 # 5 minutes
  authentication:
    type: "oauth2"
    issuerUrl: "https://idp.education.example.org/realms/opendesk"
```

### Synchronization Flow

**Event-Driven Synchronization:**

1. HISinOne detects course/enrollment change
2. HISinOne sends webhook event to provisioning API
3. Provisioning API validates event and processes synchronization
4. Provisioning API updates Keycloak groups and course data
5. Provisioning API triggers platform-specific updates (ILIAS, Moodle)
6. Provisioning API sends confirmation webhook to HISinOne

**Periodic Synchronization:**

1. Scheduled task (cron) triggers synchronization
2. Provisioning API pulls delta changes from HISinOne
3. Provisions updates to Keycloak and platforms
4. Logs synchronization results
5. Sends summary report

**Delta Pull Logic:**

```python
def sync_semester_delta(semester_code, last_sync_timestamp):
    # Get courses modified since last sync
    modified_courses = hisinone_client.get_courses(
        semester=semester_code,
        modified_since=last_sync_timestamp
    )

    # Get enrollments updated since last sync
    updated_enrollments = hisinone_client.get_enrollments(
        semester=semester_code,
        updated_since=last_sync_timestamp
    )

    # Process updates
    for course in modified_courses:
        update_course(course)

    for enrollment in updated_enrollments:
        update_enrollment(enrollment)

    # Update last sync timestamp
    save_sync_timestamp(semester_code, datetime.now())
```

## Error Handling

### HTTP Status Codes

| Status Code | Description | Usage |
|-------------|-------------|-------|
| `200 OK` | Success | Successful GET, PATCH, PUT, DELETE |
| `201 Created` | Resource Created | Successful POST creating new resource |
| `202 Accepted` | Async Operation | DELETE, archival operations enqueued |
| `400 Bad Request` | Invalid Request | Malformed request body or parameters |
| `401 Unauthorized` | Authentication Failure | Missing or invalid token |
| `403 Forbidden` | Authorization Failure | Insufficient permissions |
| `404 Not Found` | Resource Not Found | Course, semester, or user not found |
| `409 Conflict` | Resource Conflict | Duplicate creation, incompatible state |
| `422 Unprocessable Entity` | Validation Error | Business logic validation failure |
| `429 Too Many Requests` | Rate Limit Exceeded | Rate limit exceeded |
| `500 Internal Server Error` | Server Error | Unexpected server error |
| `503 Service Unavailable` | Service Unavailable | Maintenance or system overload |

### Error Response Format

All error responses follow a consistent format:

```json
{
  "error": {
    "code": "COURSE_NOT_FOUND",
    "message": "Course 'CS101' in semester 'WS2025/26' not found.",
    "details": {
      "courseId": "course:CS101:WS2025/26",
      "semesterCode": "WS2025/26"
    },
    "requestId": "req_abc123xyz456",
    "timestamp": "2025-10-31T14:30:00Z"
  }
}
```

**Error Code Prefixes:**

| Prefix | Domain | Example |
|--------|--------|---------|
| `COURSE_` | Course operations | `COURSE_NOT_FOUND`, `COURSE_ALREADY_EXISTS` |
| `SEMESTER_` | Semester operations | `SEMESTER_NOT_ACTIVE`, `SEMESTER_ALREADY_ARCHIVED` |
| `ENROLLMENT_` | Enrollment operations | `ENROLLMENT_QUOTA_EXCEEDED`, `ENROLLMENT_DUPLICATE` |
| `QUOTA_` | Quota operations | `QUOTA_LIMIT_EXCEEDED`, `QUOTA_INVALID` |
| `AUTH_` | Authentication | `AUTH_INVALID_TOKEN`, `AUTH_INSUFFICIENT_SCOPE` |
| `RATE_LIMIT_` | Rate limiting | `RATE_LIMIT_EXCEEDED` |

### Common Error Scenarios

**Course Creation Failures:**

1. **Course Already Exists:**
   * Error Code: `COURSE_ALREADY_EXISTS`
   * HTTP Status: `409 Conflict`
   * Recovery: Use course update endpoint instead

2. **Quota Exceeded:**
   * Error Code: `QUOTA_POOL_EXHAUSTED`
   * HTTP Status: `422 Unprocessable Entity`
   * Recovery: Request quota increase or reduce course count

3. **Invalid Semester:**
   * Error Code: `SEMESTER_NOT_FOUND`
   * HTTP Status: `404 Not Found`
   * Recovery: Create semester first or specify valid semester code

**Enrollment Failures:**

1. **Student Quota Exceeded:**
   * Error Code: `ENROLLMENT_QUOTA_EXCEEDED`
   * HTTP Status: `422 Unprocessable Entity`
   * Recovery: Increase `maxStudents` quota or remove students

2. **Duplicate Enrollment:**
   * Error Code: `ENROLLMENT_DUPLICATE`
   * HTTP Status: `409 Conflict`
   * Recovery: Student already enrolled, use update endpoint

3. **Non-Existent Student:**
   * Error Code: `USER_NOT_FOUND`
   * HTTP Status: `404 Not Found`
   * Recovery: Verify student ID in Keycloak

## Webhooks and Event Notifications

### Event Types

| Event Type | Description | Trigger |
|------------|-------------|---------|
| `course.created` | New course created | POST /courses |
| `course.updated` | Course metadata updated | PATCH /courses/{id} |
| `course.archived` | Course archived | POST /courses/{id}/archive |
| `course.restored` | Course restored | POST /courses/{id}/restore |
| `course.deleted` | Course deleted | DELETE /courses/{id} |
| `semester.activated` | Semester activated for provisioning | PUT /semesters/{code}/activate |
| `semester.archived` | Semester archived | POST /semesters/{code}/archive |
| `enrollment.added` | Student enrolled in course | POST /courses/{id}/enrollment |
| `enrollment.removed` | Student unenrolled from course | DELETE /courses/{id}/enrollment |
| `quota.warning` | Approaching quota limit | Usage exceeds 75% |
| `quota.exceeded` | Quota limit reached | Usage exceeds quota |

### Webhook Configuration

Webhooks are configured via API endpoint or environment variables.

**Configuration Management:**

```json
{
  "webhooks": [
    {
      "url": "https://services.university.edu/webhooks/course-events",
      "events": ["course.created", "course.updated", "course.archived"],
      "headers": {
        "Authorization": "Bearer ${WEBHOOK_SECRET}",
        "X-Custom-Header": "value"
      },
      "retryPolicy": {
        "maxRetries": 3,
        "retryDelaySeconds": 60,
        "exponentialBackoff": true
      },
      "enabled": true
    },
    {
      "url": "https://services.university.edu/webhooks/enrollment-events",
      "events": ["enrollment.added", "enrollment.removed"],
      "enabled": true
    }
  ]
}
```

**Webhook Authentication:**

* HMAC signature in `X-Webhook-Signature` header
* Secret shared between API and webhook receiver
* Signature computed as: `HMAC-SHA256(secret, event_payload)`

```python
def verify_webhook_signature(payload, signature, secret):
    computed_signature = hmac.new(
        secret.encode(),
        payload.encode(),
        hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(computed_signature, signature)
```

**Webhook Delivery Guarantees:**

* Minimum once delivery (may deliver duplicates)
* Retry on failure (configurable maxRetries)
* Exponential backoff between retries
* Timeout after configurable period

### Event Payload

**Course Created Event:**

```json
{
  "eventId": "evt_abc123xyz456",
  "eventType": "course.created",
  "timestamp": "2025-10-01T08:00:00Z",
  "data": {
    "courseId": "course:CS101:WS2025/26",
    "semesterCode": "WS2025/26",
    "courseCode": "CS101",
    "title": "Introduction to Computer Science",
    "lecturerIds": ["user:instructor1@example.org"],
    "quota": {
      "storageGB": 100,
      "maxStudents": 200
    }
  },
  "source": "system:hisinone-integration"
}
```

**Archival Event:**

```json
{
  "eventId": "evt_def456uvw789",
  "eventType": "course.archived",
  "timestamp": "2026-04-01T00:00:00Z",
  "data": {
    "courseId": "course:CS101:WS2025/26",
    "archiveReason": "Semester end - WS2025/26",
    "retentionUntil": "2031-04-01T00:00:00Z",
    "archivedLocations": {
      "ilias": "archived_courses/CS101_WS202526",
      "bbb": "recordings/CS101_WS202526"
    }
  },
  "source": "system:semester-admin"
}
```

**Quota Warning Event:**

```json
{
  "eventId": "evt_ghi789rst012",
  "eventType": "quota.warning",
  "timestamp": "2025-10-20T14:30:00Z",
  "data": {
    "courseId": "course:CS101:WS2025/26",
    "warningType": "storage",
    "currentUsageGB": 85.5,
    "quotaGB": 100,
    "utilizationPercent": 85.5,
    "recommendations": [
      "Review large files in OpenCloud",
      "Archive old BBB recordings",
      "Increase quota if needed"
    ]
  },
  "source": "system:quota-monitor"
}
```

## Lifecycle Hooks

Lifecycle hooks allow custom actions to be executed at key points in the course lifecycle.

### Pre-Creation Hook

**Trigger:** Before course creation

**Use Cases:**

* Validate course code against institutional standards
* Check lecturer availability
* Reserve room if specified
* Pre-provision platform resources

**Hook Payload:**

```json
{
  "hookType": "pre-creation",
  "semesterCode": "WS2025/26",
  "courseData": {
    "courseCode": "CS101",
    "title": "Introduction to Computer Science",
    "lecturerIds": ["user:instructor1@example.org"]
  }
}
```

**Hook Response:**

```json
{
  "approved": true,
  "message": "Course code valid and lecturer available",
  "modifications": {
    "quota": {
      "storageGB": 150  // Increased from default
    }
  }
}
```

**Failure Response:**

```json
{
  "approved": false,
  "message": "Lecturer already has course at this time",
  "errorCode": "LECTURER_CONFLICT"
}
```

### Post-Creation Hook

**Trigger:** After successful course creation

**Use Cases:**

* Send notifications to instructors
* Integrate with external calendars
* Create platform-specific course resources
* Log audit trail

**Hook Payload:**

```json
{
  "hookType": "post-creation",
  "course": {
    "id": "course:CS101:WS2025/26",
    "courseCode": "CS101",
    "title": "Introduction to Computer Science",
    "platforms": {
      "ilias": {
        "url": "https://lms.education.example.org/goto.php?target=crs_12345"
      }
    }
  }
}
```

### Pre-Archival Hook

**Trigger:** Before course archival

**Use Cases:**

* Validate archival prerequisites (e.g., grades submitted)
* Confirm archival retention period
* Notify instructors of impending archival

**Hook Payload:**

```json
{
  "hookType": "pre-archival",
  "courseId": "course:CS101:WS2025/26",
  "archiveRequest": {
    "retentionYears": 5,
    "archiveContent": true,
    "preserveRatings": false
  }
}
```

**Hook Response:**

```json
{
  "approved": true,
  "message": "Course ready for archival",
  "requirementsMet": [
    "Grades finalized",
    "Content exported",
    "Student evaluations submitted"
  ]
}
```

### Post-Archival Hook

**Trigger:** After successful course archival

**Use Cases:**

* Update catalog (mark course as archived)
* Archive audit trail
* Notify course stakeholders

**Hook Payload:**

```json
{
  "hookType": "post-archival",
  "courseId": "course:CS101:WS2025/26",
  "archiveResults": {
    "archivedAt": "2026-04-01T00:00:00Z",
    "archivedLocations": {
      "ilias": "archived_courses/CS101_WS202526",
      "bbb": "recordings/CS101_WS202526",
      "opencloud": "archived_courses/CS101_WS202526"
    }
  }
}
```

## Examples and Use Cases

### Semester Start Workflow

Scenario: University starts Wintersemester 2025/26 and needs to provision all courses.

**Workflow:**

1. **Create and Activate Semester**

```http
POST /api/v1/semesters
Content-Type: application/json

{
  "semesterCode": "WS2025/26",
  "name": "Wintersemester 2025/26",
  "startDate": "2025-10-01",
  "endDate": "2026-03-31",
  "type": "winter",
  "status": "upcoming"
}
```

```http
PUT /api/v1/semesters/WS2025/26/activate
```

2. **Synchronize Courses from HISinOne**

```http
POST /api/v1/hisinone/sync/semester/WS2025/26
```

3. **Bulk Create Courses**

```bash
# Process synchronization results
for course in hisinone_courses:
    create_course(course)
```

4. **Batch Enroll Students**

```bash
# For each course
for course in active_courses:
    enrollments = get_hisinone_enrollments(course.code)
    add_students_to_course(course.id, enrollments.student_ids)
```

**Complete Integration Script:**

```python
import requests

def provision_semester(semester_code):
    api_base = "https://api.education.example.org/api/v1"

    # Step 1: Create semester
    semester_response = requests.post(
        f"{api_base}/semesters",
        json={
            "semesterCode": semester_code,
            "name": f"Wintersemester {semester_code}",
            "startDate": "2025-10-01",
            "endDate": "2026-03-31",
            "type": "winter"
        }
    )
    semester = semester_response.json()

    # Step 2: Activate semester
    requests.put(f"{api_base}/semesters/{semester_code}/activate")

    # Step 3: Synchronize from HISinOne
    sync_response = requests.post(
        f"{api_base}/hisinone/sync/semester/{semester_code}"
    )
    courses = sync_response.json()["courses"]

    # Step 4: Create courses and enroll students
    for course in courses:
        create_course(course)
        enroll_students(course.id, course.enrollments)

def create_course(course_data):
    api_base = "https://api.education.example.org/api/v1"
    response = requests.post(
        f"{api_base}/courses",
        json={
            "semesterCode": course_data["semester"],
            "courseCode": course_data["code"],
            "title": course_data["title"],
            "lecturerIds": course_data["lecturers"],
            "quota": {
                "storageGB": 100,
                "maxStudents": 200
            }
        }
    )
    return response.json()

def enroll_students(course_id, student_ids):
    api_base = "https://api.education.example.org/api/v1"
    response = requests.post(
        f"{api_base}/courses/{course_id}/enrollment",
        json={
            "studentIds": student_ids,
            "role": "student"
        }
    )
    return response.json()

# Execute
provision_semester("WS2025/26")
```

### Course Update Workflow

Scenario: Instructor changes course title and adds a new lecturer.

**Workflow:**

```http
PATCH /api/v1/semesters/courses/course:CS101:WS2025/26
Content-Type: application/json

{
  "title": "Introduction to Computer Science (Updated Title)",
  "lecturerIds": [
    "user:instructor1@example.org",
    "user:instructor2@example.org",
    "user:new-instructor@example.org"
  ]
}
```

**Response:**

```json
{
  "id": "course:CS101:WS2025/26",
  "title": "Introduction to Computer Science (Updated Title)",
  "lecturerIds": [
    "user:instructor1@example.org",
    "user:instructor2@example.org",
    "user:new-instructor@example.org"
  ],
  "updatedAt": "2025-10-15T10:30:00Z",
  "previousTitle": "Introduction to Computer Science"
}
```

### Semester End Workflow

Scenario: Wintersemester ends, archive all courses gracefully.

**Workflow:**

1. **Archive Semester**

```http
POST /api/v1/semesters/WS2025/26/archive
Content-Type: application/json

{
  "retentionYears": 5,
  "reason": "Semester end - WS2025/26"
}
```

2. **Verify Archival Completion**

```http
GET /api/v1/semesters/WS2025/26
```

Response should show `"status": "archived"`.

3. **Archive Audit Log**

Audit log entry created in system:

```json
{
  "action": "semester.archived",
  "semesterCode": "WS2025/26",
  "performedBy": "system:semester-admin",
  "timestamp": "2026-04-01T00:00:00Z",
  "coursesArchived": 148,
  "retentionConfigured": "5 years"
}
```

---

## Additional Resources

* **Campus Management:** [HISinOne Documentation](https://www.his.de/de/hisinone/)
* **Identity Provider:** [Keycloak Documentation](https://www.keycloak.org/documentation)
* **Learning Platforms:**
  * [ILIAS](https://www.ilias.de/docu/)
  * [Moodle](https://docs.moodle.org/)
  * [BigBlueButton](https://docs.bigbluebutton.org/)
  * [OpenCloud](https://www.opencloud.eu/docs/)
* **Standards:**
  * [OAuth 2.0](https://oauth.net/2/)
  * [OpenAPI 3.0](https://swagger.io/specification/)

<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# Campus Management System Integration Hooks

This document defines integration hooks for connecting openDesk Edu with campus management systems (HISinOne, HISinOne-Proxy, Marvin), enabling automated student provisioning, course synchronization, semester lifecycle management, and event-driven data flows.

<!-- TOC -->
* [Campus Management System Integration Hooks](#campus-management-system-integration-hooks)
  * [Overview](#overview)
  * [Architecture](#architecture)
  * [Supported Campus Management Systems](#supported-campus-management-systems)
    * [HISinOne](#hisinone)
    * [HISinOne-Proxy](#hisinone-proxy)
    * [Marvin](#marvin)
    * [Custom Integration](#custom-integration)
  * [Integration Patterns](#integration-patterns)
    * [Pattern 1: Periodic Synchronization](#pattern-1-periodic-synchronization)
    * [Pattern 2: Event-Driven Synchronization](#pattern-2-event-driven-synchronization)
    * [Pattern 3: Hybrid Synchronization](#pattern-3-hybrid-synchronization)
  * [Data Flow Architecture](#data-flow-architecture)
    * [Course Data Flow](#course-data-flow)
    * [Enrollment Data Flow](#enrollment-data-flow)
    * [User Provisioning Flow](#user-provisioning-flow)
  * [HISinOne Integration](#hisinone-integration)
    * [Authentication and Authorization](#authentication-and-authorization)
    * [SAML SSO Configuration](#saml-sso-configuration)
    * [SOAP API Integration](#soap-api-integration)
    * [Course Data Synchronization](#course-data-synchronization)
    * [Enrollment Data Synchronization](#enrollment-data-synchronization)
  * [HISinOne-Proxy Integration](#hisinone-proxy-integration)
    * [Proxy Architecture](#proxy-architecture)
    * [Proxy API Endpoints](#proxy-api-endpoints)
    * [Authentication Configuration](#authentication-configuration)
    * [Caching Strategy](#caching-strategy)
    * [Data Transformation](#data-transformation)
  * [Event-Driven Integration](#event-driven-integration)
    * [Event Types](#event-types)
    * [Webhook Configuration](#webhook-configuration)
    * [Event Payload Structure](#event-payload-structure)
    * [Event Processing Flow](#event-processing-flow)
  * [Keycloak User Provisioning](#keycloak-user-provisioning)
    * [User Creation Workflow](#user-creation-workflow)
    * [Group Assignment](#group-assignment)
    * [Role Mapping](#role-mapping)
    * [Attribute Synchronization](#attribute-synchronization)
  * [LDAP/Active Directory Integration](#ldapactive-directory-integration)
    * [LDAP as User Directory](#ldap-as-user-directory)
    * [Active Directory Integration](#active-directory-integration)
    * [Attribute Mapping Rules](#attribute-mapping-rules)
    * [Synchronization Considerations](#synchronization-considerations)
  * [Error Handling and Retry Logic](#error-handling-and-retry-logic)
    * [Error Classification](#error-classification)
    * [Retry Strategies](#retry-strategies)
    * [Dead Letter Queue](#dead-letter queue)
    * [Error Notifications](#error-notifications)
  * [Monitoring and Observability](#monitoring-and-observability)
    * [Key Metrics](#key-metrics)
    * [Logging](#logging)
    * [Health Checks](#health-checks)
  * [Security Considerations](#security-considerations)
    * [Trust Establishment](#trust-establishment)
    * **[Data Privacy]**(#data-privacy)
    * [Access Control](#access-control)
    * [Audit Logging](#audit-logging)
  * [Implementation Examples](#implementation-examples)
    * [Example 1: HISinOne Course Synchronization](#example-1-hisinone-course-synchronization)
    * [Example 2: Event-Driven Enrollment Processing](#example-2-event-driven-enrollment-processing)
    * [Example 3: Custom Integration Adapter](#example-3-custom-integration-adapter)
  * [Testing and Validation](#testing-and-validation)
    * [Unit Testing](#unit-testing)
    * [Integration Testing](#integration-testing)
    * [End-to-End Testing](#end-to-end-testing)
  * [Troubleshooting](#troubleshooting)
    * [Common Issues](#common-issues)
    * [Diagnostic Tools](#diagnostic-tools)
    * [Recovery Procedures](#recovery-procedures)
<!-- TOC -->

## Overview

Campus management systems (CMS) serve as the authoritative source for course data, student enrollments, and academic records. openDesk Edu provides integration hooks to synchronize this data with learning platforms (ILIAS, Moodle) and identity management (Keycloak).

**Core Capabilities:**

* **Automated Student Provisioning:** Automatic user creation and group assignment from enrollment data
* **Course Synchronization:** Keep course metadata in sync with campus management system
* **Semester Lifecycle:** Activate, archive, and manage semesters based on academic calendar
* **Event-Driven Architecture:** Respond to real-time enrollment changes
* **Bidirectional Sync (Read-Only):** One-way data flow from campus management, never writing back

**Data Flow Principle:**

```
Campus Management System → openDesk Edu → Learning Platforms
  (Source of Truth)          (Transformation)            (Target Systems)
```

> [!important]
  Data flows from campus management systems TO openDesk Edu, never back. Campus management systems remain the authoritative source for all student, course, and enrollment data.

## Architecture

The campus management integration architecture follows an event-driven pattern with fallback to periodic synchronization.

```
┌─────────────────────────────────────────────────────────────────┐
│                    Campus Management System                      │
│                  (HISinOne / HISinOne-Proxy)                     │
└──────────────┬────────────────────────┬─────────────────────────┘
               │                        │
               │ Event Stream           │ REST/SOAP API
               │ (Webhooks)             │ (Polling)
               ▼                        ▼
┌──────────────────────────────────────────────────────────────────┐
│                 Integration Layer (Middleware)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │ Event Handler│  │  Sync Engine │  │  Data Transformer       │ │
│  │  (Webhooks)  │  │  (Scheduler) │  │  (HISinOne → Keycloak) │ │
│  └──────────────┘  └──────────────┘  └─────────────────────────┘ │
└──────────────────────────────────────┬───────────────────────────┘
                                       │
                                       │ REST API / Admin Events
                                       ▼
┌──────────────────────────────────────────────────────────────────┐
│                         Keycloak (IAM)                            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Users          │        Groups              │ Roles      │  │
│  │  (Students)     │  semester:WS2026:students │ student     │  │
│  │                 │  course:CS101:students    │ instructor  │  │
│  └───────────────────────────────────────────────────────────┘  │
└──────────────┬───────────────────────────────┬───────────────────┘
               │                               │
               │ OIDC/SAML                     │ LDAP/SAML
               ▼                               ▼
┌───────────────────────────┐     ┌───────────────────────┐
│   Learning Platforms      │     │   File Storage        │
│  ┌──────┐  ┌──────┐       │     │  ┌──────┐  ┌──────┐  │
│  │ILIAS │  │Moodle│  ...   │     │  │Next- │  │Open- │  │
│  └──────┘  └──────┘       │     │  │cloud │  │Cloud │  │
└───────────────────────────┘     │  └──────┘  └──────┘  │
                                  └───────────────────────┘
```

**Integration Layer Components:**

1. **Event Handler:** Receives and processes webhooks from campus management systems
2. **Sync Engine:** Periodic synchronization scheduler (cron-based)
3. **Data Transformer:** Maps campus management data to Keycloak schema
4. **Error Handler:** Manages retries and error notifications

**Data Read-Only Principle:**

* Campus management → openDesk Edu: Data synchronization (allowed)
* openDesk Edu → Campus Management: Data writes (forbidden)
* Learning platforms → Campus Management: Grade submissions (via separate integration)
  * This is a different integration pattern not covered in this document

## Supported Campus Management Systems

### HISinOne

**Overview:**

HISinOne is a comprehensive campus management system (PCA) developed by HIS GmbH, widely used in German universities. It manages:

* Course catalog and semester planning
* Student enrollment and registration
* Academic records and grades
* Room and resource scheduling

**Integration Characteristics:**

* **Authentication:** SAML 2.0 / OIDC
* **API:** SOAP-based web services (`qisserver/services2/`)
* **Data Format:** XML-based
* **Event System:** Webhooks for enrollment changes
* **Availability:** Production deployment required

**Supported Features:**

| Feature | Integration Method | API Endpoint |
|---------|--------------------|--------------|
| Course Data | Periodic Sync | GET /qisserver/services2/course |
| Enrollment Data | Event + Sync | POST /qisserver/services2/enrollment |
| Student Attributes | Event + Sync | GET /qisserver/services2/student |
| Semester Activations | Scheduled | GET /qisserver/services2/semester |

**Integration Preconditions:**

* HISinOne instance with SAML/SSO enabled
* OAuth 2.0 client credentials for API access
* Webhook endpoint configured in HISinOne
* Network connectivity between HISinOne and openDesk Edu

### HISinOne-Proxy

**Overview:**

HISinOne-Proxy is a community-maintained middleware that provides a simplified REST API interface to HISinOne. Hosted on GitHub: [DatabayAG/his_in_one_proxy](https://github.com/DatabayAG/his_in_one_proxy).

**Proxy Benefits:**

* **Simplified API:** RESTful JSON interface (no complex SOAP handling)
* **Caching Layer:** Reduces load on underlying HISinOne system
* **Data Transformation:** Converts HISinOne XML to JSON
* **Authentication Proxy:** Handles SAML/OIDC authentication
* **Rate Limiting:** Protects HISinOne from API abuse

**Supported Features:**

| Feature | API Endpoint | Description |
|---------|--------------|-------------|
| Course List | GET /api/courses | Get all courses for semester |
| Course Details | GET /api/courses/{id} | Get course metadata |
| Enrollment List | GET /api/enrollments | Get student enrollments |
| Student Info | GET /api/students/{id} | Get student attributes |
| Sync Trigger | POST /api/sync/trigger | Manual sync trigger |

**Proxy Configuration:**

```yaml
hisinoneProxy:
  enabled: true
  baseUrl: "https://hisinone-proxy.university.edu/api"
  authentication:
    type: "apikey"  # or "oauth2"
    apiKey: "${PROXY_API_KEY}"
    oauth2:
      issuerUrl: "https://idp.university.edu/realms/hisinone"
      clientId: "opendesk-edu"
      clientSecret: "${CAMPUS_CLIENT_SECRET}"
  cache:
    enabled: true
    ttl: 300  # 5 minutes
    backend: "redis"
  sync:
    interval: "6h"
    batchSize: 100
```

**When to Use HISinOne-Proxy vs Direct HISinOne:**

| Scenario | Recommended Approach |
|----------|---------------------|
| Need simplified REST API | HISinOne-Proxy |
| Direct SOAP access required | Direct HISinOne |
| Need caching layer | HISinOne-Proxy |
| Custom data transformation | HISinOne-Proxy |
| Minimal latency required | Direct HISinOne |
| Limited HISinOne API access | HISinOne-Proxy (reduces load) |

### Marvin

**Overview:**

Marvin is an alternative campus management system used in some higher education institutions. Integration pattern follows similar principles to HISinOne with REST API support.

**Integration Parameters:**

* **Authentication:** OAuth 2.0 client credentials
* **API:** RESTful JSON API
* **Data Format:** JSON
* **Event System:** Webhooks for enrollment updates

**API Endpoints:**

| Endpoint | Method | Purpose |
|----------|--------|---------|
| /api/v1/semesters | GET | List active semesters |
| /api/v1/courses | GET | Get courses for semester |
| /api/v1/courses/{id}/enrollments | GET | Get course enrollments |
| /api/v1/students/{id} | GET | Get student attributes |

### Custom Integration

If your institution uses a campus management system not listed above, you can implement a custom integration adapter.

**Custom Integration Pattern:**

1. **Implement Adapter Interface:**

   ```python
   class CampusManagementAdapter(ABC):
       @abstractmethod
       def get_courses(self, semester_code: str) -> List[Course]:
           pass

       @abstractmethod
       def get_enrollments(self, semester_code: str) -> List[Enrollment]:
           pass

       @abstractmethod
       def get_student(self, student_id: str) -> Student:
           pass
   ```

2. **Configure in helmfile:**

   ```yaml
   campusManagement:
     systemName: "custom-uni-system"
     adapterType: "customRestAdapter"
     baseUrl: "https://cms.university.edu/api"
     authentication:
       type: "oauth2"
       issuerUrl: "https://idp.university.edu/realms/cms"
       clientId: "opendesk-edu"
     syncInterval: 4h
   ```

3. **Map Data Fields:**

   ```yaml
   fieldMapping:
     courseCode: "kennung"
     title: "titel"
     lecturerIds: "dozenten"
     studentId: "matrikelnummer"
     email: "email"
     firstName: "vorname"
     lastName: "nachname"
   ```

## Integration Patterns

### Pattern 1: Periodic Synchronization

**Overview:**

Scheduled synchronization pulls data from campus management system at regular intervals. This pattern is reliable and suitable for systems without webhook support.

**Workflow:**

```
┌─────────────────────────────────────────────────────────────┐
│  Periodic Sync (Cron Job)                                    │
│  1. Triggered every N hours (e.g., 6 hours)                 │
│  2. Fetch delta changes (last_sync_timestamp)               │
│  3. Transform data to Keycloak schema                       │
│  4. Apply updates to Keycloak and platforms                 │
│  5. Log results and send notifications                      │
└─────────────────────────────────────────────────────────────┘
```

**Configuration:**

```yaml
syncSchedule:
  enabled: true
  interval: "6h"  # Every 6 hours
  startTime: "02:00"  # 2 AM local time
  timezone: "Europe/Berlin"
  retryOnFailure: true
  maxRetries: 3

deltaQuery:
  enabled: true
  incremental: true
  fullSyncDays: 7  # Full sync every 7 days
```

**Advantages:**

* Simple to implement
* No webhook infrastructure required
* Works with any REST/SOAP API
* Predictable load patterns

**Disadvantages:**

* Event latency (up to sync interval)
* May synchronize stale data if campus management changes quickly
* Periodic load spikes on integration systems

**When to Use:**

* Campus management system without webhook support
* Stable environments with infrequent changes
* Initial data migration
* Recovery from sync failures

### Pattern 2: Event-Driven Synchronization

**Overview:**

Webhook-based synchronization triggers in response to real-time events in the campus management system. This pattern provides near real-time updates.

**Workflow:**

```
┌─────────────────────────────────────────────────────────────┐
│  Event-Driven (Webhook)                                      │
│  1. Campus management emits event                           │
│  2. Webhook sent to integration endpoint                    │
│  3. Event handler validates and queues event                │
│  4. Worker processes event asynchronously                   │
│  5 Apply updates to Keycloak and platforms                   │
│  6. Send confirmation to campus management                  │
└─────────────────────────────────────────────────────────────┘
```

**Event Types:**

| Event | Trigger | Integration Handler |
|-------|---------|--------------------|
| `student.enrolled` | Student enrolled in course | Add student to course Keycloak group |
| `student.withdrawn` | Student withdrawn from course | Remove student from course group |
| `course.created` | New course created | Create course, course groups |
| `course.updated` | Course metadata updated | Update course in Keycloak |
| `semester.activated` | Semester activated | Activate semester, schedule syncs |
| `semester.archived` | Semester archived | Archive courses, remove groups |

**Webhook Configuration:**

```yaml
webhooks:
  enabled: true
  endpoint: "https://api.education.example.org/webhooks/campus-events"
  secret: "${WEBHOOK_SECRET}"
  eventTypes:
    - student.enrolled
    - student.withdrawn
    - course.created
    - course.updated
    - semester.activated
    - semester.archived
  retryPolicy:
    maxRetries: 3
    retryDelaySeconds: 60
    exponentialBackoff: true
  authentication:
    type: "hmac"
    algorithm: "sha256"
    headerName: "X-Webhook-Signature"
```

**Advantages:**

* Near real-time updates
* Reduced bandwidth (only delta changes)
* Lower load on integration systems
* Event traceability and audit

**Disadvantages:**

* Requires webhook support in campus management system
* More complex infrastructure (event queue, workers)
* Webhook reliability concerns (missed events)

**When to Use:**

* Campus management system with webhook support
* Environments requiring near real-time updates
* High-volume changes (large enrollment batches)
* Event auditing requirements

### Pattern 3: Hybrid Synchronization

**Overview:**

Combines event-driven sync for real-time updates with periodic sync as a fallback and for full data consistency.

**Workflow:**

```
┌─────────────────────────────────────────────────────────────┐
│  Hybrid (Event + Periodic)                                  │
│  1. Real-time: Webhook events processed immediately         │
│  2. Scheduled: Full sync every N days                      │
│  3. Event failure triggers cached retry                     │
│  4. Periodic sync catches missed events                    │
│  5. Compare results, log discrepancies                     │
└─────────────────────────────────────────────────────────────┘
```

**Configuration:**

```yaml
hybridSchedule:
  eventDriven:
    enabled: true
    priority: "high"  # Process events before scheduled sync

  periodicSync:
    enabled: true
    fullSyncInterval: "7d"  # Full sync weekly
    consistencyCheck: true
    reconcileDifferences: true

  eventCache:
    enabled: true
    ttl: 24h  # Cache events for 24 hours
    replayOnFailure: true
```

**Advantages:**

* Best of both worlds: real-time + reliability
* Graceful degradation (events fail, periodic sync catches up)
* Data consistency verification
* Audit logs of event vs sync differences

**Disadvantages:**

* Most complex pattern to implement
* Requires two sync mechanisms
* Resolving conflicting updates (event vs sync)

**When to Use:**

* Campus management system with webhook support
* Mission-critical environments requiring both real-time and reliability
* Regulatory requirements for data consistency
* Large deployments with multiple integration points

## Data Flow Architecture

### Course Data Flow

**Direction:** Campus Management → Keycloak → Learning Platforms

```
┌──────────────────────┐
│ Campus Management    │
│ (HISinOne / Proxy)   │
└──────────┬───────────┘
           │ GET /api/courses?semester=WS2026
           ▼
┌──────────────────────────────────────────┐
│  Data Transformation Layer               │
│  - Map HISinOne XML/JSON to schema       │
│  - Validate required fields              │
│  - Apply field mappings                  │
└──────────┬───────────────────────────────┘
           │ POST /api/v1/semesters/courses
           ▼
┌──────────────────────┐
│ Keycloak             │
│ - Create course      │
│ - Create course      │
│   groups             │
│ - Map semester roles │
└──────────┬───────────┘
           │ OIDC/SAML
           ▼
┌──────────────────────┐
│ Learning Platforms   │
│ - ILIAS: Create      │
│   course via API     │
│ - Moodle: Create     │
│   course via API     │
│ - BBB: Create room   │
└──────────────────────┘
```

**Data Mapping Example:**

| Campus Management Field | Keycloak/Platform Field | Transformation |
|-------------------------|------------------------|----------------|
| `kennung` | `courseCode` | Direct mapping |
| `titel` | `title` | Direct mapping |
| `dozenten[]` | `lecturerIds[]` | List mapping |
| `semester` | `semesterCode` | Format: `WS2025/26` |
| `raum` | `room` | Direct mapping |
| `startdatum` | `schedule.startDate` | Date format conversion |

**Transformation Rules:**

1. **Semester Code Formatting:**

   ```python
   def format_semester_code(raw_semester: str) -> str:
       """
       Convert HISinOne semester format to openDesk Edu format.

       Examples:
       "20262" → "WS2025/26"
       "20261" → "SS2025"
       """
       # HISinOne uses 6-digit year + term code (1 = summer, 2 = winter)
       year = raw_semester[:4]
       term = int(raw_semester[4])

       if term == 1:
           return f"SS{year}"
       elif term == 2:
           next_year = str(int(year) + 1)
           return f"WS{year}/{next_year[2:]}"  # WS2025/26
   ```

2. **User ID Mapping:**

   ```python
   def map_user_id(hisinone_id: str) -> str:
       """
       Convert HISinOne student ID to Keycloak user ID format.

       Example: "1234567" → "user:student1234567@university.edu"
       """
       return f"user:student{hisinone_id}@university.edu"
   ```

### Enrollment Data Flow

**Direction:** Campus Management → Keycloak → Course Groups

```
┌──────────────────────┐
│ Campus Management    │
│ (Enrollment Event)   │
└──────────┬───────────┘
           │ Webhook / Sync
           ▼
┌────────────────────────────┐
│  Enrollment Handler        │
│  - Validate student exists │
│  - Check quota limits      │
│  - Determine role          │
└──────────┬─────────────────┘
           │ POST /api/v1/courses/{id}/enrollment
           ▼
┌──────────────────────────────────────┐
│ Keycloak                              │
│ - Add user to course group            │
│ - Add user to semester group          │
│ - Assign platform permissions         │
└──────────┬───────────────────────────┘
           │ LDAP Sync
           ▼
┌──────────────────────┐
│ Learning Platforms   │
│ - ILIAS: Enroll      │
│   student in course  │
│ - Moodle: Enroll     │
│   via REST API       │
│ - OpenCloud: Grant   │
│   access to share    │
└──────────────────────┘
```

**Enrollment Event Processing:**

```python
def process_enrollment_event(event: EnrollmentEvent):
    """
    Process enrollment event from campus management system.

    Event contains:
    - studentId (HISinOne matriculation number)
    - courseCode (course identifier)
    - semesterCode (semester identifier)
    - role (student, tutor, instructor)
    - eventType (enrolled, withdrawn, role_changed)
    """
    # 1. Map student ID to Keycloak user
    user_id = map_user_id(event.studentId)
    course_id = f"course:{event.courseCode}:{event.semesterCode}"

    # 2. Validate user exists in Keycloak
    user = keycloak_admin.get_user(user_id)
    if not user:
        logger.error(f"User {user_id} not found, skipping enrollment")
        return

    # 3. Map campus management role to Keycloak role
    role_mapping = {
        "student": "student",
        "tutor": "tutor",
        "dozent": "instructor"
    }
    keycloak_role = role_mapping.get(event.role.lower(), "student")

    # 4. Process enrollment based on event type
    if event.eventType == "enrolled":
        # Add user to course group
        keycloak_admin.add_user_to_group(user_id, f"course:{event.courseCode}:students")

        # Add user to semester group
        keycloak_admin.add_user_to_group(user_id, f"semester:{event.semesterCode}:students")

        # Update platform access
        platform_access = get_platform_access_for_course(course_id)
        for platform in platform_access:
            provision_user_to_platform(user_id, platform, keycloak_role)

    elif event.eventType == "withdrawn":
        # Remove user from course group
        keycloak_admin.remove_user_from_group(user_id, f"course:{event.courseCode}:students")

        # Archive user's data (optional)
        archive_user_course_data(user_id, course_id)

    logger.info(f"Processed {event.eventType} for user {user_id} in course {course_id}")
```

### User Provisioning Flow

**Direction:** Campus Management → Keycloak → LDAP → Learning Platforms

```
┌──────────────────────┐
│ Campus Management    │
│ (Student Attributes) │
└──────────┬───────────┘
           │ GET /api/students/{id}
           ▼
┌────────────────────────────────┐
│  User Creation                 │
│  - Validate uniqueness         │
│  - Map attributes              │
│  - Create Keycloak user        │
└──────────┬─────────────────────┘
           │ POST /admin/realms/opendesk/users
           ▼
┌──────────────────────┐
│ Keycloak             │
│ - User created       │
│ - Default groups     │
│ - Base attributes    │
└──────────┬───────────┘
           │ LDAP Sync or OIDC
           ▼
┌──────────────────────┐
│ LDAP / Active Directory│
│ - User entry created  │
│   (if using LDAP as   │
│    user directory)    │
└──────────┬───────────┘
           │ LdapUserFederationProvider
           ▼
┌──────────────────────┐
│ Learning Platforms   │
│ - User provisioned   │
│   via SSO on first    │
│   login              │
└──────────────────────┘
```

**User Attribute Mapping:**

| Campus Management | Keycloak | LDAP (Active Directory) |
|-------------------|----------|-------------------------|
| `matrikelnummer` | `username` | `sAMAccountName` |
| `vorname` | `firstName` | `givenName` |
| `nachname` | `lastName` | `sn` |
| `email` | `email` | `mail` |
| `semester` | `custom:currentSemester` | `department` |
| `studienfach` | `custom:fieldOfStudy` | `description` |

**User Creation Workflow:**

1. **Receive student data from campus management**
2. **Check if user already exists in Keycloak** (by username or email)
3. **If not exists, create new user:**
   * Generate username: `student{matriculation_number}@university.edu`
   * Generate temporary password (auto-expiring after first login)
   * Assign default groups: `base-students`, `university-students`
4. **Map attributes from campus management to Keycloak user profile**
5. **Provision user to LDAP** (if using LDAP as user directory)
6. **Send welcome email** (optional)
7. **Log user creation event**

## HISinOne Integration

### Authentication and Authorization

HISinOne integration uses SAML 2.0-based single sign-on for authentication and OAuth 2.0 for API authorization.

**Authentication Flow:**

```
┌─────────────────────────────────────────────────────────────┐
│  1. Integration Service                                     │
│     Initiates SAML SSO to HISinOne                          │
└────────────────────┬────────────────────────────────────────┘
                     │ SAML Auth Request
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  2. HISinOne (IdP)                                          │
│     Authenticates and issues SAML assertion                 │
└────────────────────┬────────────────────────────────────────┘
                     │ SAML Assertion
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Integration Service                                     │
│     Extracts attributes and exchanges for OAuth 2.0 token   │
└────────────────────┬────────────────────────────────────────┘
                     │ OAuth 2.0 Token Request (Client Credentials)
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Keycloak                                                │
│     Validates credentials and issues OAuth 2.0 access token  │
└────────────────────┬────────────────────────────────────────┘
                     │ OAuth 2.0 AccessToken
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  5. Integration Service                                     │
│     Uses OAuth 2.0 tokens to access HISinOne SOAP API       │
└────────────────────┬────────────────────────────────────────┘
                     │ OAuth 2.0 Authorization: Bearer <token>
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  6. HISinOne SOAP API                                       │
│     Validates token and returns course/enrollment data      │
└─────────────────────────────────────────────────────────────┘
```

**OAuth 2.0 Client Configuration:**

```yaml
hisinone:
  oauth2:
    clientId: "opendesk-edu-integration"
    clientSecret: "${HISINONE_CLIENT_SECRET}"
    tokenEndpoint: "https://idp.university.edu/realms/hisinone/protocol/openid-connect/token"
    scopes:
      - "hisinone:courses:read"
      - "hisinone:enrollments:read"
      - "hisinone:students:read"
      - "hisinone:semesters:read"
    tokenLifetime: 3600  # 1 hour
    refreshTokenLifetime: 86400  # 24 hours
```

**Required Scopes:**

| Scope | Description | Required For |
|-------|-------------|--------------|
| `hisinone:courses:read` | Read course data | Course synchronization |
| `hisinone:enrollments:read` | Read enrollment data | Student provisioning |
| `hisinone:students:read` | Read student attributes | User provisioning |
| `hisinone:semesters:read` | Read semester data | Semester lifecycle |

### SAML SSO Configuration

**SAML Service Provider Metadata:**

The integration service must be registered as a SAML service provider in HISinOne's IdP.

**SP Metadata Fields:**

| Field | Value | Description |
|-------|-------|-------------|
| Entity ID | `https://api.education.example.org/saml/sp` | Unique SP identifier |
| Assertion Consumer Service | `https://api.education.example.org/saml/acs` | SAML response endpoint |
| Single Logout Service | `https://api.education.example.org/saml/slo` | Logout endpoint |
| Name ID Format | `urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified` | Name identifier format |
| Required Attributes | `eduPersonAffiliation`, `mail`, `displayName` | Attributes to request |

**SAML Configuration in Integration Service:**

```yaml
saml:
  serviceProvider:
    entityId: "https://api.education.example.org/saml/sp"
    metadataUrl: "https://idp.university.edu/metadata/hisinone"
    callbackUrl: "https://api.education.example.org/saml/acs"
    logoutUrl: "https://api.education.example.org/saml/slo"

  attributeMapping:
    eduPersonAffiliation: "affiliation"
    mail: "email"
    displayName: "firstName"
    eduPersonPrincipalName: "username"

  security:
    wantAssertionsSigned: true
    wantAssertionsEncrypted: false
    signatureAlgorithm: "RSA-SHA256"
    digestAlgorithm: "SHA256"
```

### SOAP API Integration

HISinOne exposesSOAP-based web services for accessing course and enrollment data.

**Base URL:**

```
https://hisinone.university.edu/qisserver/services2/
```

**Available SOAP Services:**

| Service | WSDL URL | Purpose |
|---------|----------|---------|
| CourseService | `/qisserver/services2/CourseService?wsdl` | Course catalog data |
| EnrollmentService | `/qisserver/services2/EnrollmentService?wsdl` | Student enrollment data |
| StudentService | `/qisserver/services2/StudentService?wsdl` | Student attributes |
| SemesterService | `/qisserver/services2/SemesterService?wsdl` | Semester lifecycle data |

**SOAP Request Example: Get Courses for Semester**

```xml
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                  xmlns:his="http://hisinone.de/services2/course">
   <soapenv:Header>
      <wsse:Security soapenv:mustUnderstand="1"
                 xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
         <wsse:BinarySecurityToken
            ValueType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3"
            EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">
            base64-encoded-x509-certificate
         </wsse:BinarySecurityToken>
      </wsse:Security>
   </soapenv:Header>
   <soapenv:Body>
      <his:GetCoursesRequest>
         <his:Semester>WS2025/26</his:Semester>
         <his:IncludeEnrollments>true</his:IncludeEnrollments>
         <his:StartDate>2025-10-01</his:StartDate>
         <his:EndDate>2026-03-31</his:EndDate>
      </his:GetCoursesRequest>
   </soapenv:Body>
</soapenv:Envelope>
```

**SOAP Response Example:**

```xml
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
   <soap:Body>
      <ns2:GetCoursesResponse xmlns:ns2="http://hisinone.de/services2/course">
         <ns2:Course>
            <ns2:Kennung>CS101</ns2:Kennung>
            <ns2:Titel>Introduction to Computer Science</ns2:Titel>
            <ns2:Dozenten>
               <ns2:Dozent>
                  <ns2:Kennung>dozent123</ns2:Kennung>
                  <ns2:Name>Dr. Jane Smith</ns2:Name>
               </ns2:Dozent>
            </ns2:Dozenten>
            <ns2:Raum>Building A, Room 101</ns2:Raum>
            <ns2:Termin>
               <ns2:Tag>Monday</ns2:Tag>
               <ns2:Startzeit>10:00</ns2:Startzeit>
               <ns2:Endzeit>11:30</ns2:Endzeit>
            </ns2:Termin>
         </ns2:Course>
      </ns2:GetCoursesResponse>
   </soap:Body>
</soap:Envelope>
```

### Course Data Synchronization

**Synchronization Steps:**

1. **Fetch courses from HISinOne:**
   * Call `GetCourses` SOAP endpoint with semester code
   * Retrieve course metadata (kennung, titel, dozenten, raum, termin)
   * Parse XML response to Python objects

2. **Transform course data:**
   * Map HISinOne fields to openDesk Edu schema
   * Format semester codes (e.g., "20262" → "WS2025/26")
   * Validate required fields

3. **Upsert courses in Keycloak:**
   * Check if course exists (by.course ID)
   * Create new course if not exists
   * Update existing course if exists

4. **Create Keycloak groups:**
   * Course-specific groups of format: `course:{courseCode}:{semesterCode}`
   * Lecturer groups: `course:{courseCode}:instructors`
   * Student groups: `course:{courseCode}:students`

5. **Provision to learning platforms:**
   * ILIAS: Create course via REST API
   * Moodle: Create course via Moodle web service
   * BBB: Create meeting room via BBB API
   * OpenCloud: Create course share via REST API

**Synchronization Code Example:**

```python
import requests
from xml.etree import ElementTree as ET

def sync_courses_from_hisinone(semester_code: str):
    """
    Sync course data from HISinOne to Keycloak.
    """

    # 1. Fetch courses from HISinOne SOAP API
    soap_request = build_hisinone_soap_request(semester_code)
    soap_response = hisinone_client.call_soap_api(soap_request)

    # 2. Parse XML response
    root = ET.fromstring(soap_response)
    courses = root.findall(".//ns2:Course", namespaces={"ns2": "http://hisinone.de/services2/course"})

    for course_xml in courses:
        # 3. Transform course data
        course = transform_hisinone_course(course_xml)

        # 4. Upsert course in Keycloak
        upsert_course_in_keycloak(course)

        # 5. Create Keycloak groups
        create_course_groups(course)

        # 6. Provision to learning platforms
        provision_course_to_platforms(course)

    logger.info(f"Synced {len(courses)} courses for semester {semester_code}")
```

### Enrollment Data Synchronization

**Setup Handler:**

```python
def handle_hisinone_webhook(request_data: dict):
    """
    Handle enrollment webhook from HISinOne.
    """

    # 1. Verify webhook signature
    if not verify_hisinone_signature(request_data):
        raise Unauthorized("Invalid webhook signature")

    # 2. Parse event data
    event = parse_hisinone_event(request_data)

    # 3. Queue event for processing
    event_queue.enqueue(event)

    # 4. Return 202 Accepted
    return {"status": "queued", "eventId": event.id}
```

**Event Processing:**

```python
def process_enrollment_event(event: HISinOneEvent):
    """
    Process enrollment event from HISinOne.
    """

    if event.event_type == "student.enrolled":
        # Get student data from HISinOne
        student = get_student_from_hisinone(event.student_id)

        # Create Keycloak user if not exists
        user = provision_user_to_keycloak(student)

        # Add to course group
        course_id = f"course:{event.course_code}:{semester_code}"
        keycloak_admin.add_user_to_group(
            user_id=user.id,
            group_id=f"course:{event.course_code}:students"
        )

        # Provision to learning platforms
        for platform in get_enabled_platforms(course_id):
            provision_user_to_platform(user.id, platform, "student")

    elif event.event_type == "student.withdrawn":
        # Remove from course group
        keycloak_admin.remove_user_from_group(
            user_id=event.student_id,
            group_id=f"course:{event.course_code}:students"
        )

        # Archive user data (optional)
        archive_user_course_data(event.student_id, course_id)
```

## HISinOne-Proxy Integration

### Proxy Architecture

HISinOne-Proxy acts as a middleware layer between openDesk Edu and HISinOne, providing:

* REST API wrapper around HISinOne SOAP services
* Data transformation (XML → JSON)
* Authentication proxy (handles SAML/OIDC)
* Response caching
* Rate limiting

```
┌──────────────────┐     REST API (JSON)      ┌─────────────────────┐
│ openDesk Edu     │ ─────────────────────▶   │ HISinOne-Proxy      │
│ Integration      │                          │ (Middleware)         │
└──────────────────┘                          └──────────┬──────────┘
                                                         │ SOAP (XML)
                                                         └────────────────────▶
                                                         │ HISinOne
                                                         └─────────────────────┘
```

### Proxy API Endpoints

**Course Endpoints:**

| Method | Endpoint | Description | Response |
|--------|----------|-------------|----------|
| GET | `/api/v1/semesters/{semesterCode}/courses` | Get courses for semester | JSON array of courses |
| GET | `/api/v1/courses/{courseId}` | Get course details | JSON course object |
| GET | `/api/v1/courses/{courseId}/enrollments` | Get course enrollments | JSON array of enrollments |

**Student Endpoints:**

| Method | Endpoint | Description | Response |
|--------|----------|-------------|----------|
| GET | `/api/v1/students/{studentId}` | Get student attributes | JSON student object |
| GET | `/api/v1/students/{studentId}/enrollments` | Get student enrollments | JSON array of courses |

**Sync Endpoints:**

| Method | Endpoint | Description | Response |
|--------|----------|-------------|----------|
| POST | `/api/v1/sync/trigger` | Trigger manual sync | Sync job ID |
| GET | `/api/v1/sync/status/{jobId}` | Get sync job status | Job status |
| GET | `/api/v1/sync/history` | Get sync history | Array of sync jobs |

**Example: Get Courses for Semester**

```bash
curl -X GET \
  "https://hisinone-proxy.university.edu/api/v1/semesters/WS202526/courses" \
  -H "Authorization: Bearer ${PROXY_API_KEY}" \
  -H "Content-Type: application/json"
```

**Response:**

```json
{
  "courses": [
    {
      "id": "CS101",
      "title": "Introduction to Computer Science",
      "semester": "WS202526",
      "lecturers": [
        {
          "id": "dozent123",
          "name": "Dr. Jane Smith"
        }
      ],
      "schedule": {
        "days": ["Monday", "Wednesday"],
        "startTime": "10:00",
        "endTime": "11:30"
      },
      "room": "Building A, Room 101",
      "enrollmentCount": 150
    }
  ],
  "meta": {
    "total": 150,
    "page": 1,
    "pageSize": 50
  }
}
```

### Authentication Configuration

HISinOne-Proxy supports multiple authentication methods.

**API Key Authentication:**

```yaml
hisinoneProxy:
  authentication:
    type: "apikey"
    apiKey: "${PROXY_API_KEY}"
    headerName: "X-API-Key"
```

**OAuth 2.0 Authentication:**

```yaml
hisinoneProxy:
  authentication:
    type: "oauth2"
    tokenEndpoint: "https://idp.university.edu/realms/oauth/protocol/openid-connect/token"
    clientId: "opendesk-edu"
    clientSecret: "${OAUTH_CLIENT_SECRET}"
    scopes: ["hisinone:read"]
```

**SAML SSO Authentication:**

```yaml
hisinoneProxy:
  authentication:
    type: "saml"
    idpMetadataUrl: "https://idp.university.edu/metadata/saml"
    spEntityId: "https://api.education.example.org/saml/sp"
    assertionConsumerServiceUrl: "https://api.education.example.org/saml/acs"
```

### Caching Strategy

HISinOne-Proxy caches responses to reduce load on the underlying HISinOne system.

**Caching Configuration:**

```yaml
hisinoneProxy:
  cache:
    enabled: true
    backend: "redis"
    redisUrl: "redis://redis-cache:6379/0"
    ttl:
      courses: 300      # 5 minutes
      students: 600     # 10 minutes
      enrollments: 60   # 1 minute
    maxSize: 10000      # Maximum cached items
```

**Cache Invalidation Strategies:**

1. **Time-to-Live (TTL):** Items expire after configured TTL

2. **Webhook-based Invalidation:**
   * HISinOne sends webhook to proxy on data change
   * Proxy invalidates affected cache entries
   * Next request fetches fresh data

3. **Purge API:**
   * Manual cache purge endpoint: `POST /api/v1/cache/purge`

### Data Transformation

HISinOne-Proxy transforms HISinOne XML data to JSON format.

**Transformation Rules:**

1. **XML Tag Names to JSON Keys:**
   * Convert PascalCase to camelCase
   * Example: `Kennung` → `kennung`, `Dozenten` → `lecturers`

2. **Date Formats:**
   * HISinOne: `YYYY-MM-DD` (XML)
   * Proxy: ISO 8601 format (JSON)

3. **Nested Structures:**
   * Flat XML structures to nested JSON
   * Example: `Dozent[]` → `lecturers: [{id, name}]`

4. **Empty Values:**
   * Replace `null` or empty strings with `null`

**Example Transformation:**

**HISinOne XML:**

```xml
<Course>
    <Kennung>CS101</Kennung>
    <Titel>Introduction to Computer Science</Titel>
    <Dozenten>
        <Dozent>
            <Kennung>dozent123</Kennung>
            <Name>Dr. Jane Smith</Name>
        </Dozent>
    </Dozenten>
</Course>
```

**Proxy JSON:**

```json
{
  "id": "CS101",
  "title": "Introduction to Computer Science",
  "lecturers": [
    {
      "id": "dozent123",
      "name": "Dr. Jane Smith"
    }
  ]
}
```

## Event-Driven Integration

### Event Types

Campus management systems emit events for data changes. The integration layer responds to these events.

**Student Lifecycle Events:**

| Event Type | Trigger | Integration Handler |
|------------|---------|--------------------|
| `student.enrolled` | Student enrolled in course | Add student to course group |
| `student.withdrawn` | Student withdrawn from course | Remove student from course group |
| `student.graduated` | Student completed studies | Transfer to alumni group |
| `student.suspended` | Student temporarily suspended | Suspend access (optional) |
| `student.reinstated` | Student reinstated after suspension | Restore access |

**Course Lifecycle Events:**

| Event Type | Trigger | Integration Handler |
|------------|---------|--------------------|
| `course.created` | New course created in CMS | Create course in Keycloak |
| `course.updated` | Course metadata modified | Update course in Keycloak |
| `course.cancelled` | Course cancelled | Archive course, notify enrollees |
| `course.archived` | Course archived (post-semester) | Move to archival storage |

**Semester Lifecycle Events:**

| Event Type | Trigger | Integration Handler |
|------------|---------|--------------------|
| `semester.activated` | Semester start date reached | Activate semester, enable provisioning |
| `semester.archived` | Semester end date + grace period | Archive all courses, disable provisioning |
| `semester.rollover` | Next semester preparation scheduled | Create next semester structure |

**Attribute Change Events:**

| Event Type | Trigger | Integration Handler |
|------------|---------|--------------------|
| `student.email_changed` | Student email changed | Update Keycloak user email |
| `student.name_changed` | Student name changed | Update Keycloak user first/last name |
| `student.status_changed` | Student status changed | Update access permissions |

### Webhook Configuration

**Webhook Endpoint:**

The integration service exposes a webhook endpoint for receiving events from campus management systems.

```
POST https://api.education.example.org/webhooks/campus-events
```

**Webhook Authentication:**

Campus management systems must authenticate webhook requests.

1. **HMAC Signature:**

   * Compute HMAC-SHA256 of request body using shared secret
   * Include signature in `X-Webhook-Signature` header
   * Integration service verifies signature before processing

   ```python
   def verify_webhook_signature(request_body: bytes, received_signature: str, secret: str) -> bool:
       """
       Verify webhook HMAC signature.
       """
       computed_signature = hmac.new(
           secret.encode(),
           request_body,
           hashlib.sha256
       ).hexdigest()

       return hmac.compare_digest(computed_signature, received_signature)
   ```

2. **API Key:**

   * Include API key in `Authorization` header
   * Format: `Authorization: Bearer ${API_KEY}`

**Webhook Configuration in Campus Management:**

```json
{
  "webhookUrl": "https://api.education.example.org/webhooks/campus-events",
  "secret": "${WEBHOOK_SECRET}",
  "eventTypes": [
    "student.enrolled",
    "student.withdrawn",
    "course.created",
    "course.updated",
    "semester.activated",
    "semester.archived"
  ],
  "retryPolicy": {
    "maxRetries": 3,
    "retryDelaySeconds": 60,
    "exponentialBackoff": true
  }
}
```

### Event Payload Structure

**Standard Event Payload:**

All events follow a consistent structure.

```json
{
  "eventId": "evt_abc123xyz456",
  "eventType": "student.enrolled",
  "eventTimestamp": "2026-03-27T10:30:00Z",
  "sourceSystem": "hisinone",
  "data": {
    "studentId": "1234567",
    "courseCode": "CS101",
    "semesterCode": "WS202526",
    "role": "student",
    "enrollmentDate": "2026-03-27T10:00:00Z"
  },
  "metadata": {
    "correlationId": "cor_789def012ghi",
    "source": "/api/v1/enrollments/evt_abc123xyz456",
    "version": "1.0"
  }
}
```

**Event Types and Data Structures:**

1. **Student Enrolled:**

   ```json
   {
     "eventId": "evt_001",
     "eventType": "student.enrolled",
     "data": {
       "studentId": "1234567",
       "courseCode": "CS101",
       "semesterCode": "WS202526",
       "role": "student"
     }
   }
   ```

2. **Course Created:**

   ```json
   {
     "eventId": "evt_002",
     "eventType": "course.created",
     "data": {
       "courseCode": "CS102",
       "title": "Data Structures",
       "semesterCode": "WS202526",
       "lecturerIds": ["dozent456", "dozent789"],
       "startDate": "2026-10-01",
       "endDate": "2027-03-31"
     }
   }
   ```

3. **Semester Activated:**

   ```json
   {
     "eventId": "evt_003",
     "eventType": "semester.activated",
     "data": {
       "semesterCode": "WS202526",
       "startDate": "2026-10-01",
       "endDate": "2027-03-31"
     }
   }
   ```

### Event Processing Flow

**Event Processing Architecture:**

```
┌──────────────────────┐
│ Campus Management    │
│ (Webhook)            │
└──────────┬───────────┘
           │ POST /webhooks/campus-events
           │ X-Webhook-Signature: sha256=...
           ▼
┌────────────────────────────────┐
│  Webhook Server                │
│  1. Verify signature           │
│  2. Validate event structure   │
│  3. Acknowledge (202)          │
└──────────┬─────────────────────┘
           │ Provisional Enqueue
           ▼
┌────────────────────────────────┐
│  Event Queue (Redis/MessageBus)│
│  queued_events                 │
└──────────┬─────────────────────┘
           │ Worker Pool
           ▼
┌────────────────────────────────┐
│  Event Processor               │
│  1. Transform event            │
│  2. Map data to Keycloak       │
│  3. Apply changes              │
│  4. Log success/failure        │
└──────────┬─────────────────────┘
           │
           ├───▶ Keycloak (groups, users, roles)
           ├───▶ ILIAS (course enrollment)
           ├───▶ Moodle (course enrollment)
           ├───▶ BBB (meeting room access)
           └───▶ OpenCloud (file share access)
```

**Event Processing Steps:**

1. **Receive Webhook:**
   * Verify HMAC signature or API key
   * Validate event structure
   * Return 202 Accepted (async processing)

2. **Queue Event:**
   * Serialize event to JSON
   * Add to message queue (Redis, RabbitMQ, etc.)
   * Store event metadata (timestamp, source, eventId)

3. **Process Event (Worker):**
   * Deserialize event from queue
   * Transform event data to Keycloak schema
   * Execute changes in Keycloak:
     * Update user attributes
     * Add/remove group memberships
     * Create/delete course groups
   * Propagate changes to learning platforms
   * Log results

4. **Error Handling:**
   * Retry failed events (exponential backoff)
   * Send failed events to dead letter queue
   * Alert administrators for critical failures

**Event Processor Code Example:**

```python
def process_event(event_queue: EventQueue):
    """
    Process events from queue.
    """
    while True:
        # Get event from queue (blocking)
        event_json = event_queue.dequeue(timeout=30)
        if not event_json:
            continue  # No events, continue

        event = parse_event(event_json)

        try:
            # Transform event to Keycloak schema
            keycloak_operation = map_event_to_keycloak(event)

            # Apply changes in Keycloak
            if keycloak_operation.type == "add_user_to_group":
                keycloak_admin.add_user_to_group(
                    user_id=keycloak_operation.user_id,
                    group_id=keycloak_operation.group_id
                )
            elif keycloak_operation.type == "remove_user_from_group":
                keycloak_admin.remove_user_from_group(
                    user_id=keycloak_operation.user_id,
                    group_id=keycloak_operation.group_id
                )

            # Log success
            logger.info(f"Processed event {event.eventId}")

        except Exception as e:
            # Retry event with exponential backoff
            event_queue.retry_event(event, delay=calculate_backoff(event.retry_count))

            # Log error
            logger.error(f"Failed to process event {event.eventId}: {str(e)}")

            # Alert admin if retry count exceeded
            if event.retry_count > MAX_RETRIES:
                alert_admin(f"Event {event.eventId} exceeded max retries")
```

## Keycloak User Provisioning

### User Creation Workflow

**Workflow Steps:**

1. **Trigger:**
   * Event from campus management or periodic sync
   * Student data received from HISinOne/Proxy

2. **User Lookup:**
   * Check if user exists in Keycloak (by username, email)
   * If exists, skip creation, update attributes if needed

3. **User Creation:**
   * Generate username: `student{matriculation_number}@university.edu`
   * Generate temporary password (auto-expiring)
   * Create user in Keycloak via Admin REST API

4. **Attribute Mapping:**
   * Map campus management attributes to Keycloak user profile
   * Set required attributes: username, email, firstName, lastName
   * Set custom attributes: currentSemester, fieldOfStudy

5. **Group Assignment:**
   * Assign to base groups: `base-students`, `university-students`
   * Assign to semester group: `semester:{code}:students`
   * Assign to role-specific groups based on campus management role

6. **Platform Provisioning:**
   * User automatically provisioned to learning platforms via SSO on first login
   * No explicit provisioning required

**User Creation API Call:**

```bash
curl -X POST \
  "https://idp.education.example.org/admin/realms/opendesk/users" \
  -H "Authorization: Bearer ${KEYCLOAK_ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "student1234567@university.edu",
    "email": "jane.doe@university.edu",
    "firstName": "Jane",
    "lastName": "Doe",
    "enabled": true,
    "emailVerified": true,
    "credentials": [
      {
        "type": "password",
        "value": "temporary-password",
        "temporary": true
      }
    ],
    "attributes": {
      "matriculationNumber": ["1234567"],
      "currentSemester": ["WS202526"],
      "fieldOfStudy": ["Computer Science"]
    },
    "groups": [
      "base-students",
      "university-students",
      "semester:WS202526:students"
    ]
  }'
```

### Group Assignment

**Group Hierarchy:**

```
base-students (all students)
└── university-students (all institution students)
    ├── semester:WS202526:students (semester-specific)
    │   ├── course:CS101:students (course-specific)
    │   └── course:CS102:students
    └── semester:SS2026:students (next semester)
```

**Group Naming Pattern:**

| Group Type | Pattern | Example | Purpose |
|------------|---------|---------|---------|
| Base Group | `{base}-{role}` | `base-students` | All students in institution |
| Semester Group | `semester:{code}:{role}` | `semester:WS202526:students` | All students in semester |
| Course Group | `course:{courseCode}:{role}` | `course:CS101:students` | Students enrolled in course |
| Role Group | `course:{courseCode}:instructors` | `course:CS101:instructors` | Course instructors |

**Group Assignment Rules:**

1. **New Student:**
   * Assigned to `base-students` group
   * Assigned to `university-students` group
   * Assigned to current semester group: `semester:{currentSemester}:students`

2. **Course Enrollment:**
   * Added to course-specific student group: `course:{courseCode}:students`
   * Not removed from semester group (may enroll in multiple courses)

3. **Semester Transition:**
   * Removed from previous semester group: `semester:{previousSemester}:students`
   * Added to new semester group: `semester:{newSemester}:students`
   * Course groups archived separately

4. **Student Graduation:**
   * Removed from `base-students` group
   * Added to `alumni:{graduationYear}` group (optional)

### Role Mapping

**Campus Management Roles to Keycloak Roles:**

| Campus Management Role | Keycloak Role-displayName | permissionLevel | Access Level |
|-----------------------|---------------------------|-----------------|--------------|
| `student` | `Student` | 50 | Standard student access |
| `tutor` / `tutorin` | `Tutor` | 75 | Teaching assistant access |
| `dozent` / `dozentin` | `Dozent` | 100 | Full instructor access |
| `gast` / `guest` | `Gast` | 10 | Guest/visitor access |

**Role-Based Permissions:**

**Student (permissionLevel: 50):**

* Access to enrolled courses
* View course content
* Take assessments
* Participate in forums
* Personal file storage (quota: 2GB per course)

**Tutor (permissionLevel: 75):**

* All student permissions
* Grade assessments
* Manage forum posts
* Moderate BBB rooms
* Additional file storage (quota: 10GB per course)

**Instructor (permissionLevel: 100):**

* All tutor permissions
* Create/edit course content
* Manage enrollments
* Full BBB moderator access
* Unlimited course storage

**Guest (permissionLevel: 10):**

* Read-only access to specific courses
* No assessments
* Limited forum participation
* No personal file storage

### Attribute Synchronization

**Required Attributes (User Profile):**

| Attribute | Source Field | Update Frequency |
|-----------|--------------|-----------------|
| `username` | `matriculationNumber` (mapped) | One-time (user creation) |
| `email` | `email` | Event-driven (email_changed) |
| `firstName` | `firstName` / `vorname` | Event-driven (name_changed) |
| `lastName` | `lastName` / `nachname` | Event-driven (name_changed) |

**Custom Attributes:**

| Attribute | Source Field | Description |
|-----------|--------------|-------------|
| `matriculationNumber` | `matrikelnummer` | Unique student ID |
| `currentSemester` | `semester` | Currently active semester |
| `fieldOfStudy` | `studienfach` | Academic field/major |
| `enrollmentStatus` | `status` | Active, suspended, graduated |

**Attribute Update Trigger:**

```python
def update_user_attributes(event: AttributeChangeEvent):
    """
    Update user attributes in Keycloak.
    """
    user_id = map_user_id(event.student_id)
    user = keycloak_admin.get_user(user_id)

    if not user:
        logger.error(f"User {user_id} not found, cannot update attributes")
        return

    # Update attributes based on event type
    if event.event_type == "student.email_changed":
        user.email = event.new_email
        user.emailVerified = False  # Require re-verification

    elif event.event_type == "student.name_changed":
        user.firstName = event.new_first_name
        user.lastName = event.new_last_name

    elif event.event_type == "student.status_changed":
        # Update custom attributes
        user.attributes["enrollmentStatus"] = [event.new_status]

        # Suspend or enable user account
        if event.new_status == "suspended":
            user.enabled = False
        else:
            user.enabled = True

    # Apply changes in Keycloak
    keycloak_admin.update_user(user_id=user.id, user=user)

    logger.info(f"Updated attributes for user {user_id}")
```

## LDAP/Active Directory Integration

### LDAP as User Directory

**Overview:**

LDAP can serve as the primary user directory for openDesk Edu, with campus management synchronizing user data to LDAP.

**Architecture:**

```
┌──────────────────┐
│ Campus           │
│ Management       │
│ (HISinOne)       │
└────────┬─────────┘
         │ Sync
         ▼
┌──────────────────┐
│ LDAP Server      │
│ (OpenLDAP, AD)   │
└────────┬─────────┘
         │ LdapUserFederationProvider
         ▼
┌──────────────────┐
│ Keycloak         │
│ (Read-Only LDAP  │
│  Federation)     │
└──────────────────┘
```

**LDAP Integration Benefits:**

* External user directory (separate from Keycloak)
* Central identity management for multiple services
* Existing LDAP infrastructure at many universities

**LDAP Integration Limitations:**

* Cannot modify users directly in Keycloak (read-only federation)
* Changes must be made in LDAP/AD
* Additional synchronization layer required

### Active Directory Integration

**Active Directory Schema Mapping:**

| Active Directory Attribute | Keycloak Attribute | LDAP Filter |
|---------------------------|-------------------|-------------|
| `sAMAccountName` | `username` | `(sAMAccountName={username})` |
| `mail` | `email` | `(mail={email})` |
| `givenName` | `firstName` | N/A |
| `sn` | `lastName` | N/A |
| `userPrincipalName` | `username` (alternative) | `(userPrincipalName={username})` |

**Keycloak LDAP User Federation Configuration:**

```json
{
  "name": "active-directory",
  "providerId": "ldap",
  "providerType": "org.keycloak.storage.UserStorageProvider",
  "parentId": "opendesk",
  "config": {
    "priority": ["0"],
    "enabled": ["true"],
    "fullSyncPeriod": ["86400"],
    "changedSyncPeriod": ["3600"],
    "connectionUrl": ["ldap://ad.university.edu:389"],
    "bindDn": ["CN=opendesk-edu,OU=Service Accounts,DC=university,DC=edu"],
    "bindCredential": ["AD_SERVICE_ACCOUNT_PASSWORD"],
    "usersDn": ["OU=Students,DC=university,DC=edu"],
    "usernameLDAPAttribute": ["sAMAccountName"],
    "rdnLDAPAttribute": ["cn"],
    "uuidLDAPAttribute": ["objectGUID"],
    "userObjectClasses": ["person", "organizationalPerson", "user"],
    "connectionPooling": ["true"],
    "pagination": ["true"],
    "batchSizeForSync": ["1000"],
    "editMode": ["READ_ONLY"],
    "syncRegistrations": ["true"]
  }
}
```

**LDAP User Attribute Mappers:**

| Mapper Name | LDAP Attribute | Keycloak Attribute | Is Mandatory |
|-------------|----------------|-------------------|--------------|
| `username` | `sAMAccountName` | `username` | Yes |
| `email` | `mail` | `email` | Yes |
| `firstName` | `givenName` | `firstName` | Yes |
| `lastName` | `sn` | `lastName` | No |

### Attribute Mapping Rules

**LDAP to Keycloak Mapping:**

| LDAP Attribute | Keycloak Attribute | Transformation |
|----------------|-------------------|----------------|
| `uid` | `username` | Direct mapping |
| `mail` | `email` | Direct mapping |
| `cn` | `firstName` | Use first part of CN |
| `sn` | `lastName` | Direct mapping |
| `mobile` | `attributes.mobile` | Attribute mapping |
| `departmentNumber` | `attributes.matriculationNumber` | Attribute mapping |

**Custom LDAP Filter for Students:**

```yaml
ldap:
  usersDn: "OU=Students,DC=university,DC=edu"
  customFilter: "(&(objectClass=person)(departmentNumber=*))"

  userSearchScope: "ONE_LEVEL"

  batchSizeForSync: 1000
  syncRegistrations: true
```

**LDAP Group Mapping to Keycloak:**

| LDAP Group | Keycloak Group | Members |
|------------|----------------|---------|
| `CN=All Students,OU=Groups,DC=university,DC=edu` | `base-students` | All students |
| `CN=WS202526 Students,OU=Groups,DC=university,DC=edu` | `semester:WS202526:students` | Students in semester |
| `CN=CS101 Students,OU=Groups,DC=university,DC=edu` | `course:CS101:students` | Course enrollments |

### Synchronization Considerations

**Campus Management → LDAP Sync:**

* Campus management system must synchronize user data to LDAP
* Sync frequency determines update latency
* Attribute changes trigger LDAP updates

**LDAP → Keycloak Sync:**

* Keycloak LDAP federation provider synchronizes from LDAP periodically
* Default full sync: 24 hours
* Default changed sync: 1 hour

**Sync Frequency Configuration:**

```yaml
ldap:
  fullSyncPeriod: 86400      # 24 hours (in seconds)
  changedSyncPeriod: 3600    # 1 hour (in seconds)
  batchSyncSize: 1000
  importEnabled: true
```

**Event-Based LDAP Updates (Alternative):**

If LDAP server supports it, configure event-based updates to Keycloak:

* LDAP server sends LDIF change notifications
* Keycloak receives updates and applies changes immediately
* Reduces synchronization latency to near real-time

## Error Handling and Retry Logic

### Error Classification

**Error Types:**

| Error Type | Severity | Retry Strategy | Notification |
|------------|----------|----------------|--------------|
| Network Timeout | Transient | Retry with backoff | No (logged) |
| Authentication Failure | Transient | Retry immediately | Yes (admin) |
| Rate Limit Exceeded | Transient | Retry after cooldown | No (logged) |
| Validation Error | Permanent | No retry | No (logged) |
| User Not Found | Permanent | No retry | Yes (admin) |
| Service Unavailable | Transient | Retry with backoff | Yes (admin) |
| Data Inconsistency | Permanent | Manual intervention | Yes (admin) |

**Error Response Codes:**

| HTTP Status | Error Type | Action |
|-------------|------------|--------|
| 200 OK | Success | - |
| 202 Accepted | Async processing queued | - |
| 400 Bad Request | Validation error | Log error, no retry |
| 401 Unauthorized | Authentication failure | Retry with fresh token |
| 403 Forbidden | Authorization failure | No retry (admin issue) |
| 404 Not Found | Resource not found | No retry (data issue) |
| 409 Conflict | Resource conflict | Resolve conflict, retry |
| 422 Unprocessable Entity | Business logic error | Log error, no retry |
| 429 Too Many Requests | Rate limit | Retry after cooldown |
| 500 Internal Server Error | Service error | Retry with backoff |
| 502 Bad Gateway | Service unavailable | Retry with backoff |
| 503 Service Unavailable | Service maintenance | Retry with backoff |

### Retry Strategies

**Exponential Backoff:**

Exponential backoff increases wait time between retries exponentially.

```python
import time
import random

def exponential_backoff_retry(func, max_retries=3, base_delay=60):
    """
    Retry function with exponential backoff.
    """
    retry_count = 0
    last_exception = None

    while retry_count < max_retries:
        try:
            return func()
        except Exception as e:
            last_exception = e
            retry_count += 1

            if retry_count < max_retries:
                # Calculate delay: base * 2^(retry-1) + jitter
                delay = base_delay * (2 ** (retry_count - 1))
                jitter = random.uniform(-0.1 * delay, 0.1 * delay)
                actual_delay = delay + jitter

                logger.info(f"Retry {retry_count}/{max_retries} in {actual_delay:.2f}s")
                time.sleep(actual_delay)

    # All retries exhausted
    raise last_exception
```

**Retry Schedule:**

| Retry Attempt | Delay (seconds) | Jitter (+/-10%) |
|---------------|-----------------|-----------------|
| 1 | 60 | 54-66 |
| 2 | 120 | 108-132 |
| 3 | 240 | 216-264 |

**Retry Configuration:**

```yaml
retryPolicy:
  maxRetries: 3
  baseDelaySeconds: 60
  exponentialBackoff: true
  jitterEnabled: true
  retryableErrors:
    - "NetworkError"
    - "TimeoutError"
    - "RateLimitExceeded"
    - "ServiceUnavailable"
  nonRetryableErrors:
    - "ValidationError"
    - "UserNotFound"
    - "AuthenticationFailure"
    - "PermissionDenied"
```

### Dead Letter Queue

**Overview:**

Events that fail after maximum retries are sent to a dead letter queue (DLQ) for manual review and recovery.

**Dead Letter Queue Structure:**

```
dead_letter_queue/
├── failed_events/
│   ├──evt_001.json
│   ├──evt_002.json
│   └──evt_003.json
└── recovery_scripts/
    ├──reprocess_evt_001.sh
    └──reprocess_evt_002.sh
```

**Dead Letter Queue Entry:**

```json
{
  "event": {
    "eventId": "evt_001",
    "eventType": "student.enrolled",
    "data": {
      "studentId": "1234567",
      "courseCode": "CS101",
      "semesterCode": "WS202526"
    }
  },
  "failureReason": "UserNotFound",
  "retryCount": 3,
  "lastAttemptAt": "2026-03-27T10:30:00Z",
  "queuedAt": "2026-03-27T10:00:00Z"
}
```

**Dead Letter Queue Management:**

```python
def send_to_dead_letter_queue(event: Event, failure_reason: str):
    """
    Send failed event to dead letter queue.
    """
    dlq_entry = {
        "event": event.to_dict(),
        "failureReason": failure_reason,
        "retryCount": event.retry_count,
        "lastAttemptAt": datetime.now().isoformat(),
        "queuedAt": event.created_at.isoformat()
    }

    # Write to dead letter queue
    dlq_path = f"/var/lib/integration/dead_letter_queue/{event.event_id}.json"
    with open(dlq_path, "w") as f:
        json.dump(dlq_entry, f, indent=2)

    # Alert admin
    alert_admin(
        subject=f"Event {event.event_id} sent to dead letter queue",
        body=f"Event failed after {event.retry_count} retries. Reason: {failure_reason}"
    )

    logger.error(f"Event {event.event_id} sent to dead letter queue: {failure_reason}")
```

### Error Notifications

**Notification Channels:**

| Channel | Priority | Use Cases |
|---------|----------|-----------|
| Email | High | Critical failures requiring admin intervention |
| Slack/Teams | Medium | Non-critical failures, status updates |
| Prometheus Alert | High | Service health monitoring |
| Log aggregation | Low | All failures for audit trail |

**Notification Triggers:**

1. **Critical Failures:**
   * Dead letter queue entries
   * Service unavailable > 5 minutes
   * Authentication failures (potential configuration issue)

2. **Warning Notifications:**
   * Rate limit exceeded
   * High error rate (>10% failures in last hour)
   * Sync latency exceeded (>1 hour for event-driven sync)

3. **Info Notifications:**
   * Scheduled sync completed successfully
   * Service configuration changes
   * Maintenance windows

**Email Notification Example:**

```python
def send_error_notification(event: Event, error: str):
    """
    Send email notification for integration errors.
    """
    subject = f"Integration Error: {event.event_id}"
    body = f"""
Event ID: {event.event_id}
Event Type: {event.event_type}
Error: {error}
Retry Count: {event.retry_count}
Timestamp: {datetime.now().isoformat()}

Please investigate and resolve manually if necessary.
"""

    send_email(
        to="edu-support@university.edu",
        subject=subject,
        body=body,
        priority="high"
    )
```

## Monitoring and Observability

### Key Metrics

**Integration Metrics:**

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|-----------------|
| `integration_events_total` | Counter | Total events received | - |
| `integration_events_processed` | Counter | Events processed successfully | - |
| `integration_events_failed` | Counter | Events failed to process | > 5% of total |
| `integration_latency_seconds` | Histogram | Time from event to completion | > 3600 seconds (1 hour) |
| `sync_duration_seconds` | Histogram | Duration of periodic sync | > 1800 seconds (30 min) |
| `integration_retry_count` | Histogram | Number of retries per event | > 3 (max reached) |
| `dead_letter_queue_size` | Gauge | Number of events in DLQ | > 10 |
| `hisinone_api_latency_seconds` | Histogram | HISinOne API response time | > 10 seconds |
| `keycloak_api_latency_seconds` | Histogram | Keycloak API response time | > 5 seconds |

**Prometheus Metrics Example:**

```python
from prometheus_client import Counter, Histogram, Gauge

# Integration metrics
integration_events_total = Counter('integration_events_total', 'Total events received', ['source_system'])
integration_events_processed = Counter('integration_events_processed', 'Events processed successfully', ['event_type'])
integration_events_failed = Counter('integration_events_failed', 'Events failed to process', ['event_type', 'error_type'])
integration_latency = Histogram('integration_latency_seconds', 'Time from event to completion')

# Sync metrics
sync_duration = Histogram('sync_duration_seconds', 'Duration of periodic sync', ['sync_type'])
sync_records_processed = Counter('sync_records_processed', 'Records processed during sync', ['sync_type'])

# Dead letter queue
dead_letter_queue_size = Gauge('dead_letter_queue_size', 'Number of events in dead letter queue')

# API latency
hisinone_api_latency = Histogram('hisinone_api_latency_seconds', 'HISinOne API response time', ['endpoint'])
keycloak_api_latency = Histogram('keycloak_api_latency_seconds', 'Keycloak API response time', ['endpoint'])
```

### Logging

**Log Levels:**

| Level | Use Cases | Examples |
|-------|-----------|----------|
| ERROR | Failures requiring admin intervention | Dead letter queue entries, authentication failures |
| WARN | Non-critical issues | Rate limit exceeded, high error rates |
| INFO | Normal operations | Events processed, sync completed |
| DEBUG | Detailed trace information | Event payloads, API requests/responses |

**Log Format:**

```
[2026-03-27T10:30:45Z] [INFO] [integration] event_id=evt_001 event_type=student.enrolled status=success duration=15.2s
[2026-03-27T10:31:12Z] [ERROR] [integration] event_id=evt_002 event_type=student.enrolled error=UserNotFound retry_count=3
[2026-03-27T10:32:00Z] [WARN] [sync] sync_type=course records_processed=150 duration=25.6s errors=2
```

**Log Structure:**

| Field | Description | Example |
|-------|-------------|---------|
| Timestamp | ISO 8601 datetime | `2026-03-27T10:30:45Z` |
| Level | Log level (ERROR, WARN, INFO, DEBUG) | `INFO` |
| Component | Integration component | `integration`, `sync`, `webhook` |
| event_id | Event identifier (if applicable) | `evt_001` |
| event_type | Event type (if applicable) | `student.enrolled` |
| status | Operation status | `success`, `failure`, `partial` |
| duration | Operation duration in seconds | `15.2s` |
| error | Error message (if failed) | `UserNotFound` |

### Health Checks

**Health Check Endpoints:**

```
GET /health/live      # Liveness probe (service running)
GET /health/ready     # Readiness probe (service ready to accept requests)
GET /health/campus    # Campus management connectivity
GET /health/keycloak  # Keycloak connectivity
GET /health/ldap      # LDAP connectivity (if configured)
```

**Health Check Responses:**

```json
{
  "status": "healthy",
  "timestamp": "2026-03-27T10:30:00Z",
  "checks": {
    "campus_management": {
      "status": "healthy",
      "url": "https://hisinone-proxy.university.edu/api",
      "latency_ms": 150
    },
    "keycloak": {
      "status": "healthy",
      "url": "https://idp.education.example.org",
      "latency_ms": 45
    },
    "ldap": {
      "status": "healthy",
      "url": "ldap://ad.university.edu:389",
      "latency_ms": 80
    },
    "message_queue": {
      "status": "healthy",
      "queue_size": 5,
      "queue_depth": 5
    },
    "dead_letter_queue": {
      "status": "warning",
      "queue_size": 3
    }
  }
}
```

**Kubernetes Health Checks:**

```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
```

## Security Considerations

### Trust Establishment

**Mutual TLS (mTLS):**

Integration service and campus management system can use mutual TLS for enhanced security.

```yaml
mtls:
  enabled: true
  clientCertificate: "/etc/certs/integration-client.crt"
  clientKey: "/etc/certs/integration-client.key"
  caCertificate: "/etc/campus-management/ca.crt"
  verifyPeer: true
  allowedHosts:
    - "hisinone-proxy.university.edu"
```

**Certificate Requirements:**

* Client certificate issued by university CA
* Server certificate from campus management system
* Minimum RSA key size: 2048 bits
* Certificate validity: 1-2 years

### Data Privacy

**GDPR Compliance:**

1. **Data Minimization:**
   * Only retrieve necessary attributes from campus management
   * Do not store sensitive data (passwords, payment info)

2. **Right to be Forgotten:**
   * Provide endpoint to delete user data on request
   * Archive deleted user data for audit trail
   * Remove user from all systems within 30 days

3. **Data Retention:**
   * Student data: Retain for duration of studies + statutory period
   * Course data: Retain for audit period (typically 5-7 years)
   * Archive deleted courses: Retain according to institutional policy

4. **Data Access Logs:**
   * Log all data access operations
   * Include timestamp, user, operation, resource
   * Retain logs for audit period

**Data Encryption:**

* **In Transit:** TLS 1.2 or higher for all API calls
* **At Rest:** Database encryption, encrypted volumes
* **Secrets Management:** Kubernetes secrets, HashiCorp Vault

### Access Control

**API Access Control:**

1. **OAuth 2.0 Scopes:**
   * `integration:webhooks` - Access to webhook endpoints
   * `integration:sync` - Trigger manual sync
   * `integration:admin` - Administrative operations

2. **Rate Limiting:**
   * 100 requests per minute per IP
   * 1000 requests per hour per client
   * Exponentially increase on abuse

3. **IP Whitelist:**
   * Only allow connections from campus management system IP ranges
   * Network firewall rules

**Keycloak Roles for Integration Service:**

| Role | Permissions | Required For |
|------|-------------|--------------|
| `integration-service` | Read/create users, manage groups | Integration service |
| `semester-admin` | Activate/archives semesters | Semester lifecycle |
| `course-admin` | Create/update/archive courses | Course synchronization |
| `view-users` | Read user attributes | User synchronization |

### Audit Logging

**Audit Log Events:**

| Event Type | Description | Log Level |
|------------|-------------|-----------|
| `user_created` | New user provisioned | INFO |
| `user_updated` | User attributes changed | INFO |
| `user_deleted` | User deactivated/deleted | WARN |
| `group_membership_added` | User added to group | INFO |
| `group_membership_removed` | User removed from group | INFO |
| `course_created` | New course created | INFO |
| `course_updated` | Course metadata updated | INFO |
| `course_archived` | Course archived | INFO |
| `sync_completed` | Periodic sync completed | INFO |
| `sync_failed` | Periodic sync failed | ERROR |
| `webhook_received` | Webhook event received | DEBUG |
| `webhook_processed` | Webhook event processed | INFO |
| `webhook_failed` | Webhook event failed | ERROR |

**Audit Log Format:**

```json
{
  "eventId": "audit_001",
  "timestamp": "2026-03-27T10:30:00Z",
  "actor": "integration-service",
  "action": "user_created",
  "resource": "user:student1234567@university.edu",
  "details": {
    "source": "campus_management",
    "attributes": {
      "email": "jane.doe@university.edu",
      "firstName": "Jane",
      "lastName": "Doe"
    }
  },
  "result": "success",
  "ip": "10.0.1.100"
}
```

**Audit Log Storage:**

* Retention: 7 years (legal requirement)
* Format: Structured JSON
* Storage: Elasticsearch, Splunk, or SIEM
* Access: Restricted to security team

## Implementation Examples

### Example 1: HISinOne Course Synchronization

**Scenario:** Sync courses from HISinOne to Keycloak for semester WS2025/26

**Prerequisites:**

* OAuth 2.0 client credentials configured
* HISinOne SOAP API accessible
* Keycloak admin API token

**Synchronization Code:**

```python
import requests
from xml.etree import ElementTree as ET
import logging

# Configuration
HISINONE_BASE_URL = "https://hisinone.university.edu"
KEYCLOAK_BASE_URL = "https://idp.education.example.org"
SEMESTER_CODE = "WS202526"

# Authentication
OAUTH_TOKEN = get_oauth_token()  # Obtain OAuth 2.0 access token

# 1. Fetch courses from HISinOne SOAP API
soap_url = f"{HISINONE_BASE_URL}/qisserver/services2/course"
soap_headers = {
    "Content-Type": "text/xml",
    "Authorization": f"Bearer {OAUTH_TOKEN}"
}

soap_request = f"""
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Body>
    <his:GetCoursesRequest xmlns:his="http://hisinone.de/services2/course">
      <his:Semester>{SEMESTER_CODE}</his:Semester>
    </his:GetCoursesRequest>
  </soapenv:Body>
</soapenv:Envelope>
"""

response = requests.post(soap_url, data=soap_request, headers=soap_headers)

# 2. Parse XML response
root = ET.fromstring(response.text)
courses = root.findall(".//ns2:Course", namespaces={"ns2": "http://hisinone.de/services2/course"})

# 3. Transform course data
for course_xml in courses:
    course_code = course_xml.find("ns2:Kennung", namespaces={"ns2": "http://hisinone.de/services2/course"}).text
    title = course_xml.find("ns2:Titel", namespaces={"ns2": "http://hisinone.de/services2/course"}).text

    # Create course ID
    course_id = f"course:{course_code}:WS2025/26"

    # 4. Upsert course in Keycloak
    keycloak_url = f"{KEYCLOAK_BASE_URL}/api/v1/semesters/courses"

    course_payload = {
        "semesterCode": "WS2025/26",
        "courseCode": course_code,
        "title": title,
        "platforms": {
            "ilias": "enabled",
            "moodle": "disabled",
            "bbb": "enabled",
            "opencloud": "enabled"
        }
    }

    keycloak_response = requests.post(
        keycloak_url,
        json=course_payload,
        headers={"Authorization": f"Bearer {KEYCLOAK_ADMIN_TOKEN}"}
    )

    if keycloak_response.status_code == 200:
        logging.info(f"Successfully synced course {course_id}")
    elif keycloak_response.status_code == 409:
        logging.info(f"Course {course_id} already exists")
    else:
        logging.error(f"Failed to sync course {course_id}: {keycloak_response.text}")

logging.info(f"Synced {len(courses)} courses for semester {SEMESTER_CODE}")
```

### Example 2: Event-Driven Enrollment Processing

**Scenario:** Process student enrollment webhook event

**Webhook Handler:**

```python
from flask import Flask, request, jsonify
import hmac
import hashlib
import logging

app = Flask(__name__)

# Configuration
WEBHOOK_SECRET = "shared-secret-with-hisinone"
EVENT_QUEUE = Redis("redis://redis-cache:6379/0")

@app.route("/webhooks/campus-events", methods=["POST"])
def handle_webhook():
    """
    Handle campus management webhook events.
    """

    # 1. Verify webhook signature
    received_signature = request.headers.get("X-Webhook-Signature")
    request_body = request.get_data()

    if not verify_signature(request_body, received_signature, WEBHOOK_SECRET):
        return jsonify({"error": "Invalid signature"}), 401

    # 2. Parse event
    event = request.json

    # 3. Validate event structure
    if not all(k in event for k in ["eventId", "eventType", "data"]):
        return jsonify({"error": "Invalid event structure"}), 400

    # 4. Queue event for processing
    EVENT_QUEUE.lpush("campus_events", json.dumps(event))

    # 5. Return 202 Accepted
    return jsonify({"status": "queued", "eventId": event["eventId"]}), 202

def verify_signature(request_body, received_signature, secret):
    """
    Verify HMAC signature.
    """
    computed_signature = hmac.new(
        secret.encode(),
        request_body,
        hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(computed_signature, received_signature)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
```

**Event Processor:**

```python
import json
import requests

# Configuration
KEYCLOAK_BASE_URL = "https://idp.education.example.org"
KEYCLOAK_ADMIN_TOKEN = get_keycloak_admin_token()

def process_events():
    """
    Process events from Redis queue.
    """

    while True:
        # Event from queue (blocking)
        event_json = EVENT_QUEUE.brpop("campus_events", timeout=30)
        if not event_json:
            continue

        event = json.loads(event_json[1])

        try:
            # Map event to Keycloak operation
            if event["eventType"] == "student.enrolled":
                process_enrollment(event)

            elif event["eventType"] == "student.withdrawn":
                process_withdrawal(event)

            elif event["eventType"] == "course.created":
                process_course_creation(event)

            logging.info(f"Processed event {event['eventId']}")

        except Exception as e:
            logging.error(f"Failed to process event {event['eventId']}: {str(e)}")
            # Retry logic would be here

def process_enrollment(event):
    """
    Process student enrollment event.
    """

    student_id = event["data"]["studentId"]
    course_id = f"course:{event['data']['courseCode']}:WS2025/26"

    # Map student ID to Keycloak user ID
    user_id = f"user:student{student_id}@university.edu"

    # Add user to course group
    keycloak_url = f"{KEYCLOAK_BASE_URL}/groups/{course_id}/members/{user_id}"
    requests.put(
        keycloak_url,
        headers={"Authorization": f"Bearer {KEYCLOAK_ADMIN_TOKEN}"}
    )

    logging.info(f"Enrolled user {user_id} in course {course_id}")

# Event processor would run as separate process/worker
if __name__ == "__main__":
    process_events()
```

### Example 3: Custom Integration Adapter

**Scenario:** Implementing a custom campus management system integration

**Custom Adapter:**

```python
from abc import ABC, abstractmethod
import requests

class CampusManagementAdapter(ABC):
    """
    Abstract base class for campus management adapters.
    """

    @abstractmethod
    def get_courses(self, semester_code: str) -> list:
        """Get courses for semester."""
        pass

    @abstractmethod
    def get_enrollments(self, semester_code: str) -> list:
        """Get enrollments for semester."""
        pass

    @abstractmethod
    def get_student(self, student_id: str) -> dict:
        """Get student attributes."""
        pass

class CustomUniversityAdapter(CampusManagementAdapter):
    """
    Custom adapter for University-specific campus management system.
    """

    def __init__(self, base_url, api_key):
        self.base_url = base_url
        self.api_key = api_key
        self.headers = {
            "X-API-Key": api_key,
            "Content-Type": "application/json"
        }

    def get_courses(self, semester_code: str) -> list:
        """Get courses for semester from custom API."""

        url = f"{self.base_url}/api/v1/courses"
        params = {"semester": semester_code}

        response = requests.get(url, params=params, headers=self.headers)

        if response.status_code == 200:
            courses_data = response.json()

            # Map custom API data to standard format
            courses = []
            for course in courses_data["courses"]:
                courses.append({
                    "courseCode": course["courseId"],
                    "title": course["courseName"],
                    "lecturerIds": course["instructors"],
                    "semesterCode": semester_code
                })

            return courses

        else:
            raise Exception(f"Failed to fetch courses: {response.status_code}")

    def get_enrollments(self, semester_code: str) -> list:
        """Get enrollments for semester from custom API."""

        url = f"{self.base_url}/api/v1/enrollments"
        params = {"semester": semester_code}

        response = requests.get(url, params=params, headers=self.headers)

        if response.status_code == 200:
            enrollments_data = response.json()

            # Map custom API data to standard format
            enrollments = []
            for enrollment in enrollments_data["enrollments"]:
                enrollments.append({
                    "studentId": enrollment["studentId"],
                    "courseCode": enrollment["courseId"],
                    "semesterCode": semester_code,
                    "role": enrollment["role"]
                })

            return enrollments

        else:
            raise Exception(f"Failed to fetch enrollments: {response.status_code}")

    def get_student(self, student_id: str) -> dict:
        """Get student attributes from custom API."""

        url = f"{self.base_url}/api/v1/students/{student_id}"

        response = requests.get(url, headers=self.headers)

        if response.status_code == 200:
            student = response.json()

            # Map custom API data to standard format
            return {
                "studentId": student["id"],
                "email": student["email"],
                "firstName": student["firstName"],
                "lastName": student["lastName"],
                "currentSemester": student["activeSemester"]
            }

        else:
            raise Exception(f"Failed to fetch student: {response.status_code}")

# Usage example
if __name__ == "__main__":
    adapter = CustomUniversityAdapter(
        base_url="https://cms.university.edu",
        api_key="your-api-key"
    )

    # Get courses for semester
    courses = adapter.get_courses("WS202526")
    print(f"Fetched {len(courses)} courses")

    # Get student attributes
    student = adapter.get_student("1234567")
    print(f"Student: {student['firstName']} {student['lastName']} ({student['email']})")
```

## Testing and Validation

### Unit Testing

**Test Cases:**

1. **Event Parsing:**
   * Verify webhook event structure validation
   * Test transformation to internal event format
   * Validate error handling for malformed events

2. **User ID Mapping:**
   * Test campus management ID to Keycloak ID mapping
   * Validate edge cases (missing attributes, special characters)

3. **Attribute Mapping:**
   * Verify campus management attributes map to Keycloak attributes
   * Test custom attribute handling

**Unit Test Example:**

```python
import pytest
from integration.event_processor import EventProcessor

def test_event_parsing_valid():
    """Test parsing valid webhook event."""
    event_json = {
        "eventId": "evt_001",
        "eventType": "student.enrolled",
        "data": {
            "studentId": "1234567",
            "courseCode": "CS101",
            "semesterCode": "WS202526"
        }
    }

    processor = EventProcessor()
    event = processor.parse_event(event_json)

    assert event.event_id == "evt_001"
    assert event.event_type == "student.enrolled"
    assert event.data["studentId"] == "1234567"

def test_event_parsing_invalid():
    """Test parsing invalid webhook event."""
    event_json = {
        "eventId": "evt_002"
        # Missing eventType and data
    }

    processor = EventProcessor()

    with pytest.raises(ValueError):
        processor.parse_event(event_json)
```

### Integration Testing

**Test Scenarios:**

1. **HISinOne Integration:**
   * Test OAuth 2.0 token acquisition
   * Verify SOAP API authentication
   * Test course data retrieval

2. **Keycloak Integration:**
   * Test user creation via Admin REST API
   * Verify group assignment
   * Test attribute mapping

3. **Event Processing:**
   * Test webhook reception
   * Verify event queuing
   * Test event processing end-to-end

**Integration Test Example:**

```python
import pytest
import requests

@pytest.fixture
def keycloak_admin_token():
    """Obtain Keycloak admin API token."""
    url = "https://idp.education.example.org/realms/master/protocol/openid-connect/token"
    data = {
        "grant_type": "client_credentials",
        "client_id": "admin-cli",
        "client_secret": "admin-secret"
    }

    response = requests.post(url, data=data)
    token = response.json()["access_token"]

    return token

def test_user_creation(keycloak_admin_token):
    """Test user creation in Keycloak."""

    url = "https://idp.education.example.org/admin/realms/opendesk/users"
    headers = {
        "Authorization": f"Bearer {keycloak_admin_token}",
        "Content-Type": "application/json"
    }

    user_data = {
        "username": "test.student@university.edu",
        "email": "test.student@university.edu",
        "firstName": "Test",
        "lastName": "Student",
        "enabled": True
    }

    response = requests.post(url, json=user_data, headers=headers)

    assert response.status_code == 201

    # Cleanup: Delete user
    users = requests.get(url, headers=headers).json()
    user = next(u for u in users if u["username"] == "test.student@university.edu")
    requests.delete(f"{url}/{user['id']}", headers=headers)
```

### End-to-End Testing

**E2E Test Scenarios:**

1. **Complete Enrollment Flow:**
   * Simulate enrollment webhook
   * Verify user created in Keycloak
   * Verify user added to course group
   * Verify user can log into ILIAS

2. **Periodic Sync:**
   * Trigger scheduled synchronization
   * Verify courses synced from HISinOne
   * Verify enrollments synced
   * Check for data inconsistencies

**E2E Test Framework:**

Use Playwright or Cypress for UI validation:

```typescript
// Playwright test example

test('student enrollment flow', async ({ page }) => {
  // 1. Simulate enrollment webhook
  await sendWebhook({
    eventType: 'student.enrolled',
    data: {
      studentId: 'test123',
      courseCode: 'CS101',
      semesterCode: 'WS202526'
    }
  });

  // 2. Login to Keycloak as student
  await page.goto('https://idp.education.example.org/realms/opendesk/account');
  await page.fill('#username', 'studenttest123@university.edu');
  await page.fill('#password', 'temporary-password');
  await page.click('#kc-login');

  // 3. Verify user enrolled in course
  await expect(page.locator('text=Introduction to Computer Science')).toBeVisible();

  // 4. Login to ILIAS via SSO
  await page.goto('https://lms.education.example.org/');
  await page.click('//a[contains(text(), "Single Sign-On")]');

  // 5. Verify course access in ILIAS
  await expect(page.locator('//a[contains(text(), "CS101")]')).toBeVisible();
});
```

## Troubleshooting

### Common Issues

**Issue 1: Webhook Signature Verification Failed**

**Symptom:** Webhook requests rejected with 401 Unauthorized

**Possible Causes:**

1. Secret mismatch between campus management and integration service
2. Signature calculation algorithm mismatch
3. Request body encoding issues

**Solutions:**

1. Verify shared secret matches in both systems
2. Confirm HMAC-SHA256 algorithm used
3. Check request body encoding (UTF-8)

```bash
# Verify webhook signature
curl -X POST \
  "https://api.education.example.org/webhooks/campus-events" \
  -H "X-Webhook-Signature: sha256=<computed_signature>" \
  -H "Content-Type: application/json" \
  -d '{"eventId":"evt_001","eventType":"test"}' \
  -v
```

**Issue 2: OAuth 2.0 Token Expired**

**Symptom:** API calls fail with 401 Unauthorized

**Possible Causes:**

1. Access token lifetime exceeded
2. Refresh token not available or expired
3. Client credentials revoked

**Solutions:**

1. Refresh access token using refresh token
2. Re-authenticate using client credentials
3. Verify client credentials are valid in Keycloak

```python
# Refresh OAuth token
def refresh_oauth_token(refresh_token):
    url = "https://idp.university.edu/realms/hisinone/protocol/openid-connect/token"
    data = {
        "grant_type": "refresh_token",
        "refresh_token": refresh_token,
        "client_id": "opendesk-edu",
        "client_secret": OAuth_CLIENT_SECRET
    }

    response = requests.post(url, data=data)
    return response.json()["access_token"]
```

**Issue 3: User Already Exists**

**Symptom:** User creation fails with conflict error

**Possible Causes:**

1. User already created in Keycloak
2. Username or email collision

**Solutions:**

1. Check if user exists before creating
2. Update existing user instead of creating new
3. Use on_duplicate_key_update logic

```python
# Check if user exists
def get_user_by_username(username):
    users = keycloak_admin.get_users({"username": username})
    return users[0] if users else None

# On user creation
def create_or_update_user(user_data):
    existing_user = get_user_by_username(user_data["username"])

    if existing_user:
        # Update existing user
        keycloak_admin.update_user(user_id=existing_user["id"], user=user_data)
    else:
        # Create new user
        keycloak_admin.create_user(user_data)
```

**Issue 4: Events Stuck in Queue**

**Symptom:** Events not processed from queue

**Possible Causes:**

1. Event processor not running
2. Worker pool exhausted
3. Queue connection issues

**Solutions:**

1. Restart event processor service
2. Check worker pool capacity
3. Verify Redis connection

```bash
# Check queue size
redis-cli -h redis-cache -p 6379 LLEN campus_events

# Check next event in queue
redis-cli -h redis-cache -p 6379 LINDEX campus_events 0

# Restart event processor
kubectl rollout restart deployment/event-processor
```

### Diagnostic Tools

**1. Event Inspector:**

Inspect events in queue to diagnose processing issues.

```bash
# List events in queue
redis-cli -h redis-cache -p 6379 LRANGE campus_events 0 10

# Get event details
redis-cli -h redis-cache -p 6379 LPOP campus_events

# Requeue event (for manual replay)
redis-cli -h redis-cache -p 6379 LPUSH campus_events '{"eventId":"evt_001",...}'
```

**2. Keycloak User Inspector:**

Inspect user accounts and group memberships.

```bash
# Get user info
curl -X GET \
  "https://idp.education.example.org/admin/realms/opendesk/users?username=student123" \
  -H "Authorization: Bearer ${KEYCLOAK_ADMIN_TOKEN}"

# Get user groups
curl -X GET \
  "https://idp.education.example.org/admin/realms/opendesk/users/{user_id}/groups" \
  -H "Authorization: Bearer ${KEYCLOAK_ADMIN_TOKEN}"
```

**3. HISinOne API Tester:**

Test HISinOne SOAP API connectivity and data retrieval.

```python
# Test HISinOne SOAP API
def test_hisinone_api():
    url = "https://hisinone.university.edu/qisserver/services2/course"
    headers = {"Authorization": f"Bearer {get_oauth_token()}"}

    soap_request = """
    <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
      <soapenv:Body>
        <his:GetCoursesRequest xmlns:his="http://hisinone.de/services2/course">
          <his:Semester>WS202526</his:Semester>
        </his:GetCoursesRequest>
      </soapenv:Body>
    </soapenv:Envelope>
    """

    response = requests.post(url, data=soap_request, headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
```

**4. Webhook Replay Tool:**

Replay webhooks from dead letter queue or logs.

```python
def replay_webhook(event_id: str):
    """
    Replay webhook event for debugging.
    """
    # Load event from dead letter queue
    with open(f"/var/lib/integration/dead_letter_queue/{event_id}.json", "r") as f:
        dlq_entry = json.load(f)

    event = dlq_entry["event"]

    # Re-process event
    try:
        process_event(event)
        logging.info(f"Successfully replayed event {event_id}")

        # Remove from dead letter queue
        os.remove(f"/var/lib/integration/dead_letter_queue/{event_id}.json")

    except Exception as e:
        logging.error(f"Failed to replay event {event_id}: {str(e)}")
```

### Recovery Procedures

**1. Recover from Sync Failure:**

When periodic sync fails, recover by running manual sync.

```bash
# Trigger manual sync via API
curl -X POST \
  "https://api.education.example.org/api/v1/sync/trigger?semester=WS202526" \
  -H "Authorization: Bearer ${API_TOKEN}"

# Monitor sync status
curl -X GET \
  "https://api.education.example.org/api/v1/sync/status/$(jq -r '.jobId' <<< $trigger_response)" \
  -H "Authorization: Bearer ${API_TOKEN}"
```

**2. Recover from Event Queue Exhaustion:**

If event queue fills up, scale workers or process events manually.

```bash
# Scale event processor workers
kubectl scale deployment event-processor --replicas=10

# Process events manually (temporary stopgap)
while true; do
  event_json=$(redis-cli -h redis-cache -p 6379 LPOP campus_events)
  if [ -z "$event_json" ]; then
    break
  fi

  echo "$event_json" | process_event.py
done
```

**3. Recover from Keycloak Timeout:**

If Keycloak API timeouts occur during bulk operations, reduce batch size or implement rate limiting.

```python
# Retry with reduced batch size
def sync_batch_with_retry(batch, max_retries=3):
    retries = 0
    while retries < max_retries:
        try:
            sync_batch(batch)
            return True

        except requests.Timeout:
            retries += 1
            logging.warning(f"Timeout (attempt {retries}/{max_retries}), reducing batch size")

            # Reduce batch size
            new_batch_size = len(batch) // 2
            if new_batch_size < 1:
                new_batch_size = 1

            # Split batch into smaller chunks
            chunks = [batch[i:i+new_batch_size] for i in range(0, len(batch), new_batch_size)]
            for chunk in chunks:
                sync_batch_with_retry(chunk)

    return False
```

**4. Recover from Data Inconsistency:**

If data becomes inconsistent between campus management and Keycloak, perform full re-sync.

```bash
# Trigger full re-sync (reconciliation mode)
curl -X POST \
  "https://api.education.example.org/api/v1/sync/trigger?semester=WS202526&mode=full" \
  -H "Authorization: Bearer ${API_TOKEN}"

# Monitor re-sync progress
watch -n 5 'curl -s -H "Authorization: Bearer ${API_TOKEN}" \
  "https://api.education.example.org/api/v1/sync/status?jobId=LATEST" \
  | jq ".progress"'
```

---

## Additional Resources

* **HISinOne Documentation:** <https://www.his.de/>
* **HISinOne-Proxy GitHub:** <https://github.com/DatabayAG/his_in_one_proxy>
* **Keycloak Admin REST API:** <https://www.keycloak.org/docs/latest/server_admin/#_rest_api>
* **OAuth 2.0 RFC:** <https://tools.ietf.org/html/rfc6749>
* **SAML 2.0 Technical Overview:** <https://wiki.oasis-open.org/security/>
* **GDPR Guidelines:** <https://gdpr.eu/>

---

*Last updated: 2026-03-27*
*Task: Document campus management system integration hooks*

# HISinOne Phase 1 Completion — Account Lifecycle Automation

**Date:** 2026-07-13
**Status:** Draft
**Branch:** `feat/hisinone-phase1-ldap`

## Overview

Complete HISinOne Phase 1 by automating the full account lifecycle: immatrikulation, exmatrikulation, beurlaubung, role changes, semester re-registration verification, and guest lecturer provisioning.

## Architecture

```
HISinOne (events) ──► hisinone-lifecycle-webhook ──► Keycloak Admin API
                    (extends existing webhook)       (manage users/groups)

                    ──► CronJob: semester-check ──► LDAP + Keycloak
                    (daily, re-registration verify)

                    ──► CronJob: guest-cleanup ──► Keycloak
                    (daily, expire guest accounts)
```

## Components

### 1. Webhook — Lifecycle Event Handlers

**File:** `scripts/semester-provisioning/sync/hisinone_webhook.py` (extended)

New event handlers added:

| Event | Action | Keycloak API Call |
|---|---|---|
| `person.created` with `type=student/faculty/employee` | Create user if not exists, assign base groups | `GET/POST /users`, `PUT /users/{id}/groups/{id}` |
| `immatriculation` | Ensure user enabled, assign semester groups | `PUT /users/{id}` (enabled=true), group assignment |
| `exmatriculation` | Disable user, remove semester groups, keep data | `PUT /users/{id}` (enabled=false), group removal |
| `leave_of_absence` | Suspend service access (remove active groups), mark with attribute | `PUT /users/{id}` (attributes.suspended=true), group removal |
| `role_change` | Diff old vs new groups, add/remove accordingly | Group membership diff logic |
| `re-registration` | Re-enable user, restore semester groups | `PUT /users/{id}` (enabled=true), group restoration |

**Keycloak client library** (`sync/keycloak_client.py`): Replaced stubs with real httpx-based implementation using Keycloak client credentials grant (OAuth2 `client_credentials`). Exposes:
- `create_user()`, `get_user()`, `update_user()`, `disable_user()`
- `assign_group()`, `remove_group()`, `list_user_groups()`
- `get_group_by_name()`, `list_groups()`

### 2. Keycloak Bootstrap — Lifecycle Client

**File:** `helmfile/charts/university-ldap-bootstrap/templates/university-ldap-federation.yaml` (extended)

Extend the existing bootstrap Job to also create a Keycloak client `hisinone-lifecycle` with:
- `clientId: hisinone-lifecycle`
- Service account enabled
- `manage-users` realm role assigned
- Client secret stored in Secret `hisinone-lifecycle-client`

### 3. CronJob — Semester Re-Registration Check

**File:** New `scripts/semester-provisioning/sync/semester_check.py`

- Query university LDAP for current enrollment status (configurable attribute, default `hisinoneEnrollmentStatus`)
- Fetch all Keycloak users with `semester:*` attribute matching current semester
- For users whose LDAP status != `registered`: disable Keycloak user, set `attributes.reRegistrationStatus=pending`
- For users whose LDAP status == `registered` but Keycloak is disabled: re-enable, restore groups
- Configurable grace period before disabling (env var `RE_REGISTRATION_GRACE_DAYS`)
- Log audit trail for all actions

Deployed as CronJob: `hisinone-semester-check`, schedule `0 6 * * *` (daily 06:00)

### 4. CronJob — Guest Lecturer Cleanup

**File:** New `scripts/semester-provisioning/sync/guest_cleanup.py`

- Scan Keycloak users with `attributes.guestLecturer=true` and `attributes.accountExpiry`
- Compare expiry date against current date
- If expired: disable user, remove all group memberships, log action
- If within 14 days of expiry: log warning (for proactive notification)

Deployed as CronJob: `hisinone-guest-cleanup`, schedule `0 6 * * *` (daily 06:00)

### 5. Helm Chart — hisinone-lifecycle

**New chart:** `helmfile/charts/hisinone-lifecycle/`

```
templates/
  deployment.yaml          # Webhook Deployment (1 replica)
  service.yaml             # Cluster-internal Service (port 8000)
  configmap.yaml           # Webhook config from .Values.hisinone
  cronjob-semester.yaml    # Semester re-registration check
  cronjob-guest.yaml       # Guest lecturer cleanup
Chart.yaml
```

**Values:** Reads from existing `.Values.hisinone.*` — no new config section needed. The `hisinone.yaml.gotmpl` already has `accountLifecycle.*`, `semesterEnrollment.*`, and `guestLecturers.*` sections.

### 6. Helmfile Wiring

**`helmfile/apps/nubus/helmfile-child.yaml.gotmpl`:** Add release:
```yaml
  - name: "hisinone-lifecycle"
    chart: "../../charts/hisinone-lifecycle"
    version: "0.1.0"
    values:
      - "../../environments/default/hisinone.yaml.gotmpl"
      - "../../environments/default/secrets.yaml.gotmpl"
      - "../../environments/default/_helper.yaml.gotmpl"
      - "../../environments/default/global.yaml.gotmpl"
      - "../../environments/default/opendesk_main.yaml.gotmpl"
      {{- range .Values.customization.release.hisinoneLifecycle }}
      - {{ . }}
      {{- end }}
    needs:
      - "university-ldap-bootstrap"
    installed: {{ and .Values.apps.nubus.enabled .Values.hisinone.enabled .Values.hisinone.accountLifecycle.enabled }}
    timeout: 120
```

### 7. CI Pipeline Extension

**`.woodpecker/build.yaml`:** Add Docker image for `hisinone-lifecycle`:
```yaml
  - name: hisinone-lifecycle
    dockerfile: scripts/semester-provisioning/Dockerfile
    context: scripts/semester-provisioning
    tags:
      - "{{ version }}-{{ sha }}"
      - latest
```

## Configuration

All values driven by existing `hisinone.yaml.gotmpl` env-var defaults:

| Env Var | Default | Used By |
|---|---|---|
| `HISINONE_WEBHOOK_SECRET` | `""` | Webhook HMAC |
| `HISINONE_ON_ENROLLMENT` | `"create"` | Webhook |
| `HISINONE_ON_EXMATRICULATION` | `"disable"` | Webhook |
| `HISINONE_ON_LOA` | `"suspend"` | Webhook |
| `HISINONE_DELETION_GRACE_DAYS` | `"180"` | Webhook |
| `HISINONE_SEMESTER_ENABLED` | `"false"` | CronJob |
| `HISINONE_RE_REGISTRATION_GRACE` | `"30"` | CronJob (new, add to hisinone.yaml.gotmpl) |
| `HISINONE_GUEST_LECTURERS_ENABLED` | `"false"` | CronJob |
| `HISINONE_GUEST_DURATION` | `"365"` | CronJob |

## Verification

1. Unit tests for `keycloak_client.py` (use `responses` or `respx` for HTTP mocking)
2. Unit tests for lifecycle event handlers
3. Unit tests for `semester_check.py` and `guest_cleanup.py`
4. Integration test: deploy chart, verify webhook endpoint responds, verify CronJobs created
5. LSP diagnostics clean on all Python files
6. `helm template` renders valid K8s manifests

## Out of Scope

- Course synchronization (Phase 2)
- Schedule/rooms/exams (Phase 3)
- Opencast/Tobira lecture recording (v1.2)

## Files Changed

| File | Action |
|---|---|
| `scripts/semester-provisioning/sync/hisinone_webhook.py` | Extend |
| `scripts/semester-provisioning/sync/keycloak_client.py` | Rewrite (stubs → real impl) |
| `scripts/semester-provisioning/sync/semester_check.py` | Create |
| `scripts/semester-provisioning/sync/guest_cleanup.py` | Create |
| `helmfile/charts/hisinone-lifecycle/Chart.yaml` | Create |
| `helmfile/charts/hisinone-lifecycle/templates/*.yaml` | Create (4 templates) |
| `helmfile/charts/university-ldap-bootstrap/templates/university-ldap-federation.yaml` | Extend |
| `helmfile/apps/nubus/helmfile-child.yaml.gotmpl` | Modify |
| `.woodpecker/build.yaml` | Modify |
| `docs/superpowers/specs/2026-07-13-hisinone-phase1-lifecycle.md` | Create (this spec) |

# Semester Provisioning — HISinOne Account Lifecycle Automation

Automated account lifecycle management for HISinOne integration with openDesk.
Handles user creation, immatriculation/exmatriculation, semester re-registration
verification, and guest lecturer account cleanup.

## Architecture

```
                                    ┌─────────────────────┐
                                    │   HISinOne Campus   │
                                    │   Management System │
                                    └────────┬────────────┘
                                             │ Webhooks (HMAC-signed)
                                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   hisinone_webhook.py (FastAPI)                  │
│                                                                  │
│  person.created  →  Create Keycloak user + assign base groups   │
│  immatriculation →  Enable user + assign semester groups        │
│  exmatriculation →  Remove semester groups + disable user       │
│  leave_of_absence →  Mark user as suspended                     │
│  role_change     →  Sync groups to new role                     │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                   keycloak_client.py                             │
│                                                                  │
│  Keycloak Admin REST API (OAuth2 client credentials)            │
│  User CRUD, Group management, Token caching                     │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│  semester_check  │   │  guest_cleanup   │   │  webhook_deploy  │
│  (CronJob)       │   │  (CronJob)       │   │  (Deployment)    │
│                  │   │                  │   │                  │
│  LDAP enrollment │   │  Expired guest   │   │  FastAPI server  │
│  → disable/      │   │  account cleanup │   │  port 8000       │
│  re-enable users │   │  + 14d warnings  │   │                  │
└──────────────────┘   └──────────────────┘   └──────────────────┘
```

## Services

### 1. Webhook Receiver (`sync/hisinone_webhook.py`)

FastAPI app that receives HMAC-signed webhooks from HISinOne.

- **URL:** `POST /api/v1/webhooks/hisinone`
- **Auth:** HMAC-SHA256 signature in `X-HISINONE-Signature` header
- **Lifecycle events:**
  - `person.created` — Provision new Keycloak user
  - `immatriculation` — Enable account, assign semester groups
  - `exmatriculation` — Remove groups, disable account
  - `leave_of_absence` — Mark suspended via attributes
  - `role_change` — Sync groups to new role

### 2. Semester Check (CronJob `sync/semester_check.py`)

Runs daily (default: `0 6 * * *`) to verify re-registration:

1. Query university LDAP for currently enrolled students
2. Compare against Keycloak users with current semester attribute
3. Students no longer enrolled → mark for re-registration with grace period
4. Re-registered students with disabled accounts → re-enable

**ENV:** `HISINONE_RE_REGISTRATION_GRACE` (default: 30 days)

### 3. Guest Cleanup (CronJob `sync/guest_cleanup.py`)

Runs daily (default: `0 6 * * *`) to clean up expired guest lecturers:

1. Find Keycloak accounts with `guestLecturer=true` attribute
2. Check `accountExpiry` attribute against current date
3. Expired accounts: remove all groups, disable account
4. Accounts expiring within 14 days: log warning

## Keycloak Client (`sync/keycloak_client.py`)

Core library used by all services:

- **Auth:** OAuth2 client credentials grant (or password grant fallback)
- **Token caching:** Automatic refresh 10s before expiry
- **User ops:** get, create, update, enable, disable
- **Group ops:** get, list user groups, assign, remove, sync (diff-based)
- **Config:** via `KeycloakConfig.from_env()` (see env vars below)

## Environment Variables

### Keycloak Auth
| Variable | Default | Description |
|---|---|---|
| `KEYCLOAK_URL` | `https://id.opendesk.internal` | Keycloak base URL |
| `KEYCLOAK_REALM` | `opendesk` | Keycloak realm name |
| `KEYCLOAK_CLIENT_ID` | `admin-cli` | OAuth2 client ID |
| `KEYCLOAK_CLIENT_SECRET` | — | Client secret (if using client creds) |
| `KEYCLOAK_ADMIN_USER` | — | Admin username (if using password grant) |
| `KEYCLOAK_ADMIN_PASSWORD` | — | Admin password (if using password grant) |
| `KEYCLOAK_VERIFY_SSL` | `true` | Verify TLS certificates |
| `KEYCLOAK_TIMEOUT` | `30` | HTTP request timeout (seconds) |

### LDAP (for semester_check.py)
| Variable | Default | Description |
|---|---|---|
| `HISINONE_LDAP_HOST` | `ldap.uni-marburg.de` | LDAP server hostname |
| `HISINONE_LDAP_PORT` | `636` | LDAP server port |
| `HISINONE_LDAP_USE_SSL` | `true` | Use LDAPS |
| `HISINONE_LDAP_BIND_DN` | — | Bind DN for LDAP queries |
| `HISINONE_LDAP_BIND_PASSWORD` | — | Bind password |
| `HISINONE_LDAP_USERS_BASE_DN` | — | Users search base DN |
| `HISINONE_LDAP_ATTR_USERNAME` | `uid` | Username attribute in LDAP |
| `HISINONE_ENROLLMENT_STATUS_ATTR` | `hisinoneEnrollmentStatus` | Enrollment attribute |

### Webhook
| Variable | Default | Description |
|---|---|---|
| `HISINONE_WEBHOOK_SECRET` | — | HMAC secret for webhook verification |
| `OPENDESK_API_BASE_URL` | `http://localhost:8000/api/v1` | Internal API URL |

### Semester Check
| Variable | Default | Description |
|---|---|---|
| `HISINONE_RE_REGISTRATION_GRACE` | `30` | Grace period in days |
| `HISINONE_CURRENT_SEMESTER` | — | Current semester identifier (e.g., `2026ws`) |

## Development

### Setup

```bash
cd scripts/semester-provisioning
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install pytest pytest-httpx pytest-asyncio ldap3  # dev extras
```

### Running Tests

```bash
# Quick unit tests
python -m pytest tests/ -v

# Integration suite (includes import checks + linting)
./tests/run_integration.sh

# Single test file
python -m pytest tests/test_keycloak_client.py -v
```

### Running Locally

```bash
# Start webhook (requires env vars set)
uvicorn sync.hisinone_webhook:app --reload --port 8000

# Run semester check (dry-run)
python -m sync.semester_check
DRY_RUN=true python -m sync.semester_check

# Run guest cleanup (dry-run)
python -m sync.guest_cleanup
DRY_RUN=true python -m sync.guest_cleanup
```

## Deployment

Deployed via the `hisinone-lifecycle` Helm chart:

```bash
helmfile -e default sync --selector name=hisinone-lifecycle
```

The chart creates:
- `Deployment` — webhook receiver (FastAPI on port 8000)
- `Service` — ClusterIP for internal routing
- `ConfigMap` — environment configuration
- `CronJob` — semester_check.py (daily at 06:00)
- `CronJob` — guest_cleanup.py (daily at 06:00)

## Git Hooks / CI

The integration test script is suitable for CI pipelines:

```bash
# Run before merge
./scripts/semester-provisioning/tests/run_integration.sh
```

# ICS Integration Test Specs — Design Document

**Date:** 2026-07-10
**Status:** Draft
**Author:** Sisyphus (OhMyOpenCode)

---

## 1. Purpose

Define a **declarative, human-readable, and machine-executable** test specification format for validating the intercom-service (ICS) integration with OpenCloud, SOGo, and ILIAS. This bridges the gap between the existing OpenSpec documentation system (which is not executable) and the procedural test code (which is not declarative).

## 2. Scope

### ✅ In scope

- YAML-based behavioral spec format for ICS routing tests
- Python-based spec executor (`tests/run-specs.py`)
- Auth abstraction (OIDC session, SAML, unauthenticated)
- Reporting integration with existing `tests/lib/report.sh`
- Specs for the three core ICS integrations: OpenCloud, SOGo, ILIAS
- Health check scenarios (proxy reachability, backend connectivity)
- Auth flow scenarios (unauthenticated redirect, authenticated header injection)
- CI integration via `tests/run.sh`

### ❌ Out of scope

- Replacing existing Playwright end-to-end tests
- Replacing existing pytest integration tests
- Full BDD/Gherkin toolchain (Cucumber, etc.)
- Testing of non-ICS services
- Performance or load testing
- UI/browser-level testing

## 3. Architecture

```
tests/
├── config.yaml                     # Service endpoints (existing)
├── specs/                          # NEW: declarative behavioral specs
│   ├── ics-routing.yaml            #   OC, SOGo, ILIAS proxy behavior
│   └── ics-backchannel.yaml        #   Backchannel logout via ICS
├── run-specs.py                    # NEW: YAML spec executor
├── run.sh                          # Extended: adds --specs flag
├── lib/
│   ├── http.sh                     # (existing)
│   ├── k8s.sh                      # (existing)
│   └── report.sh                   # (existing)
├── ...
```

### Data Flow

```
YAML Spec File
    │
    ▼
run-specs.py ──► HTTP requests to ICS endpoints
    │               │
    │               ▼
    │          Validate response
    │          (status, headers, redirect, body)
    │
    ▼
Results (table / JSON / JUnit)
    │
    ▼
report.sh ──► CI output
```

## 4. Spec Format

### 4.1. File Structure

Spec files live in `tests/specs/*.yaml`. Each file describes one integration concern.

### 4.2. Schema

```yaml
# File: tests/specs/ics-routing.yaml
name: "ICS Routing Integration"              # Human-readable name
description: |                                # Purpose of this spec
  Validates that the intercom-service correctly proxies
  requests to OpenCloud, SOGo, and ILIAS.
version: 1                                    # Schema version

services:                                     # One block per proxied service
  opencloud:
    route: /oc                                # ICS proxy path prefix
    backend: opencloud.opendesk.hrz.uni-marburg.de  # Actual backend
    auth: oidc                                # Auth type (oidc, saml, none)

    tests:                                    # List of test scenarios
      - scenario: "Unauthenticated redirect to Keycloak"
        steps:
          - request:
              method: GET
              path: /oc/
            expect:
              status: [302, 307]              # Acceptable status codes
              redirect_contains: /realms/opendesk  # Must be in Location header

      - scenario: "Authenticated proxy sets X-Forwarded-User"
        auth: session                         # Override: requires OIDC session
        steps:
          - request:
              method: GET
              path: /oc/
            expect:
              status: 200
              headers:
                X-Forwarded-User: present      # Must exist
                X-Forwarded-Host: opencloud.opendesk.hrz.uni-marburg.de  # Exact match

  sogo:
    route: /sogo
    backend: sogo.opendesk.hrz.uni-marburg.de
    auth: saml
    tests:
      - scenario: "Unauthenticated access is rejected"
        steps:
          - request:
              method: GET
              path: /sogo/SOGo/
            expect:
              status: [302, 401]
```

### 4.3. Auth Abstraction

| `auth` value | Behavior |
|---|---|
| `none` | No auth; raw HTTP request |
| `session` | Acquire OIDC token from Keycloak, attach as session cookie |
| `saml` | Acquire SAML session via IdP redirect chain |
| (not set) | Inherits from parent `services.*.auth` |

Credentials come from environment variables (`PORTAL_USERNAME`, `PORTAL_PASSWORD`) consistent with existing Playwright tests.

### 4.4. Expectation Types

| Expectation | Description | Example |
|---|---|---|
| `status` | HTTP status code or list | `200`, `[302, 307]` |
| `redirect_contains` | URL substring in Location header | `"/realms/opendesk"` |
| `headers.*` | Header presence or exact value | `X-Forwarded-User: present` |
| `body_contains` | Text must appear in response body | `"status":"ok"` |
| `body_json` | JSON path evaluation | `{"$.status": "ok"}` |

## 5. Runner Design (`tests/run-specs.py`)

### 5.1. Interface

```bash
# Run all specs
python tests/run-specs.py

# Run specific spec file
python tests/run-specs.py tests/specs/ics-routing.yaml

# Run as part of test framework
./run.sh --specs
./run.sh --all
```

### 5.2. Execution Model

```
For each spec file:
  For each service block:
    For each test scenario:
      1. Resolve auth (session token, SAML cookies, or none)
      2. Execute request steps sequentially
      3. Validate expectations per step
      4. Collect result (PASS / FAIL / WARN)
    Summarize service results
  Summarize spec results
```

### 5.3. Auth Resolution

- `auth: none` → raw HTTP request with no credentials
- `auth: session` → POST to Keycloak token endpoint with client credentials or password grant → get access_token → attach as `Authorization: Bearer` or session cookie
- `auth: saml` → navigate through Keycloak SAML IdP → extract cookies → attach to subsequent requests

### 5.4. Reporting

Output in three formats matching the existing framework:

- **Table** (default): Color-coded terminal output
- **JSON**: Machine-parseable `{test, type, status, message, details, timestamp}`
- **JUnit**: XML for CI integration

### 5.5. Error Handling

- Network errors → WARN + retry (2 attempts)
- Auth failures → FAIL with auth error details
- Unexpected status codes → FAIL with received vs. expected
- Missing headers → FAIL with header name
- Timeouts → WARN + skip (configurable timeout)

## 6. Integration with Existing Framework

### 6.1. `tests/run.sh` Extension

```bash
# New flag
--specs)         # Run spec-based tests (Layer 6)
--all)           # Include spec tests
```

### 6.2. CI Pipeline

```yaml
# GitLab CI / Forgejo Actions
spec-tests:
  stage: test
  script:
    - cd tests
    - pip install pyyaml requests
    - python run-specs.py
```

### 6.3. OpenSpec Companion

A companion document at `openspec/specs/integrations/ics-routing/spec.md` describes:
- The test spec format itself (meta-spec)
- Which integration behaviors are covered
- How the specs map to the broader OpenSpec service documentation

## 7. Initial Spec Contents

### 7.1. `tests/specs/ics-routing.yaml`

| Service | Route | Scenario | Expectation |
|---|---|---|---|
| OpenCloud | `/oc/` | Unauthenticated | 302 → Keycloak realm |
| OpenCloud | `/oc/` | Authenticated | 200 + X-Forwarded-User |
| OpenCloud | `/oc/status.php` | Health check | 200 |
| SOGo | `/sogo/SOGo/` | Unauthenticated | 302 or 401 |
| SOGo | `/sogo/SOGo/` | Authenticated | 200 |
| ILIAS | `/ilias/login.php` | Unauthenticated | 302 or 401 |
| ILIAS | `/ilias/login.php` | Authenticated | 200 |

### 7.2. `tests/specs/ics-backchannel.yaml`

| Service | Scenario | Expectation |
|---|---|---|
| OpenCloud | Portal logout → OC session terminated | OC requires re-auth |
| SOGo | Portal logout → SOGo session terminated | SOGo requires re-auth |
| ILIAS | Portal logout → ILIAS session terminated | ILIAS requires re-auth |

## 8. Dependencies

- Python 3.8+ (compatible with existing test infrastructure)
- `pyyaml` (YAML parsing)
- `requests` (HTTP client)
- No new system dependencies beyond what tests/ already requires

## 9. Success Criteria

1. All ICS routing specs execute and produce correct PASS/FAIL results against live cluster
2. Specs are human-readable (non-technical stakeholder can understand scenarios)
3. Runner integrates with `tests/run.sh` and produces output in table/JSON/JUnit formats
4. Auth flows (OIDC session, SAML) work without manual token management
5. Specs can be run in CI without human interaction

## 10. Future Evolution

- **Spec generation**: Generate Playwright test stubs from YAML specs for interactive scenarios
- **Spec validation**: Validate YAML specs against JSON schema on load
- **Gherkin export**: Transform YAML spec to Gherkin `.feature` files if Cucumber integration is needed later
- **Coverage tracking**: Track which OpenSpec behaviors have corresponding test specs

# openDesk Test Framework

Automated validation suite for the openDesk platform (HRZ cluster).

## Quick Start

```bash
cd opendesk/tests
./run.sh                          # Run all layers
./run.sh --layer 0                # Infrastructure only
./run.sh --layers 0-2             # Quick health check (~3 min)
./run.sh --ci --format json       # CI mode
```

## Layers

| Layer | Name | Runtime | What It Validates |
|---|---|---|---|
| 0 | Infrastructure | ~30s | Pods running, PVCs bound, ingresses have addresses |
| 1 | Smoke | ~2min | All endpoints return 200/302/401, SSL valid |
| 2 | Auth | ~5min | OIDC redirects, SAML metadata, Keycloak reachable |
| 3 | Integration | ~15min | LDAP, mail, storage, k8up, antivirus, filepicker |
| 4 | E2E | ~30min | Browser-level critical journeys (Playwright) |
| 5 | Regression | ~1min | Known bugfixes don't regress (OpenCloud OIDC) |
| 6 | Specs | ~5min | Declarative YAML specs for ICS integration (Layer 6) |

## Service Map

All services validated: portal, Keycloak, Nextcloud, OpenCloud, OX App Suite, Matrix/Element, Jitsi, BBB, Collabora, CryptPad, DrawIO, Excalidraw, OpenProject, ILIAS, Moodle, XWiki, MinIO, SeaweedFS, Grafana

## Requirements

- `kubectl` (pointed at HRZ cluster)
- `bash`
- `python3` + `requests` + `ldap3`
- `curl` + `openssl`
- `node` + `playwright` (Layer 4 only)

## Running from CI

```yaml
# GitLab CI
test:
  script:
    - cd opendesk/tests
    - ./run.sh --ci --layers 0-2
```

## Output Formats

- `--format table`: Human-readable (default)
- `--format json`: Machine-parseable
- `--format junit`: CI integration

## ICS Integration Spec System

The ICS integration testing uses a hybrid approach:

1. **YAML Behavioral Specs** (`tests/specs/*.yaml`) — declarative scenarios for ICS routing
   - Unauthenticated scenarios: executed directly via `tests/run-specs.py` (CLI, no browser needed)
   - Authenticated scenarios: need browser-based auth via `tests/playwright/ics-auth.spec.js`
2. **Playwright Browser Tests** (`tests/playwright/ics-auth.spec.js`) — authenticated flows
   - Handles SAML-brokered auth chain (ICS → Keycloak → SAML IdP)
   - Validates session establishment, cookie handling, logout propagation
3. **Run commands:**
   ```bash
   # Unauthenticated tests (CLI)
   python tests/run-specs.py
   ./tests/run.sh --specs
   
   # Authenticated tests (Playwright, requires credentials)
   PORTAL_USERNAME=ics-testuser PORTAL_PASSWORD=... \
     npx playwright test tests/playwright/ics-auth.spec.js
   ```

## Design

See `.sisyphus/plans/test-framework-design.md` for full architecture, implementation order, and rationale.
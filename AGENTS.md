# OpenDesk Edu — AGENTS.md

**Last updated:** 2026-07-24
**Cluster:** HRZ (`*.opendesk.hrz.uni-marburg.de`)

> **Note:** This sub-project was previously developed against a separate external host
> (`178.63.182.104`). All services now deploy on the **HRZ K3s cluster** alongside
> the main openDesk CE deployment.

> **Architecture Change (2026-07-23):** Migrated from fork-based to Git submodule architecture.
> CE submodule at `helmfile/ce/` pinned to v1.17.0 (f9c2fc97). See below for updated structure.

---

## Architecture (preserved knowledge)

### Repository Structure (Post-Migration)
- **CE Submodule**: `helmfile/ce/` - openDesk CE v1.17.0 (HTTPS: gitlab.opencode.de)
- **Edu Apps**: `helmfile/apps/edu/` - 33 edu-specific application directories
- **Edu Environments**: `helmfile/environments/edu/` - ce-overrides.yaml, images.yaml, secrets.yaml
- **Edu Orchestration**: `helmfile/edu-helmfile.yaml.gotmpl` - glob pattern for automatic app detection
- **Deployment Script**: `deploy.sh` - two-step deployment with --diff, --verbose, multi-env support

### Legacy Components (Still Valid)

#### SOGo
- **WOHttpAdaptor**: Runs on `127.0.0.1:20000` (internal watchdog ONLY)
- **External Access**: Requires Apache reverse proxy on port 80
- **Config Parameters**: `SOGoDaemonAddresses` and `SOGoListenPort` are for Apache config, not SOGo itself
- **Built Image**: SOGo 5.12.7 with ActiveSync, root support disabled

#### Portal
- **Data Initialization**: `stack-data-ums` job processes 24 YAML files via data-loader
- **Entry Creation**: `41-selfservice-portal.yaml` creates self-service portal structure
- **Authentication**: Reads from `ums-portal-consumer-object-storage` secret (MinIO)
- **Provisioning**: Registers via provisioning-api

---

## Submodule Management

### CE Submodule
- **Location**: `helmfile/ce/`
- **Version**: v1.17.0 (commit: f9c2fc97)
- **Update Script**: `scripts/update-ce.sh`
- **Strategy**: HTTPS (SSH unavailable for gitlab.opencode.de)

### Update Workflow
```bash
# Update CE submodule to latest v1.17.x
./scripts/update-ce.sh

# Or manually:
git submodule update --remote helmfile/ce
```

---

## Tests

| Location | Type | Scope |
|---|---|---|
| `tests/playwright/` | Playwright E2E | Backchannel, NC backchannel |
| `tests/integration/` | Python/pytest | Attribute mapping, course API, SAML metadata, semester lifecycle |

See also: `/opendesk/docs/testing.md` (platform-wide test concept) and
`.sisyphus/plans/test-framework-design.md` (upcoming comprehensive test framework).

---

## Commands

```bash
# Tests
pytest tests/integration/ -v
npx playwright test --config tests/playwright/

# Deployment
aws-vault exec edu-dev -- ./deploy.sh --diff
aws-vault exec edu-dev -- ./deploy.sh --verbose

# Submodule updates
./scripts/update-ce.sh
```

---

## Key Changes (v1.17.0 Migration)

### What Changed
1. **Architecture**: Fork-based → Submodule-based CE integration
2. **Paths**: All edu app chart paths updated (`../../charts/` → `../../../charts/`)
3. **Keycloak**: SAML clients (ILIAS, Moodle, BBB) restored via CE's `functional.authentication.oidc.clients`
4. **Cleanup**: Removed duplicate GPG keys, stale CE CI artifacts, dead templates

### What Remains
- All edu-specific configurations in `helmfile/apps/edu/`
- Portal structure and entries
- SOGo and Apache proxy configurations
- Test suites (Playwright, integration)

---

## Deployment Guide

See `docs/deployment.md` for complete deployment instructions.

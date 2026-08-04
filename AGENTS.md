# OpenDesk Edu — AGENTS.md

**Last updated:** 2026-06-04
**Cluster:** HRZ (`*.opendesk.hrz.uni-marburg.de`)

> **Note:** This sub-project was previously developed against a separate external host
> (`178.63.182.104`). All services now deploy on the **HRZ K3s cluster** alongside
> the main openDesk CE deployment. See `/opendesk/helmfile/` for the unified config.

---

## Architecture (preserved knowledge)

### SOGo
- **WOHttpAdaptor**: Runs on `127.0.0.1:20000` (internal watchdog ONLY)
- **External Access**: Requires Apache reverse proxy on port 80
- **Config Parameters**: `SOGoDaemonAddresses` and `SOGoListenPort` are for Apache config, not SOGo itself
- **Built Image**: SOGo 5.12.7 with ActiveSync, root support disabled

### Portal
- **Data Initialization**: `stack-data-ums` job processes 24 YAML files via data-loader
- **Entry Creation**: `41-selfservice-portal.yaml` creates self-service portal structure
- **Authentication**: Reads from `ums-portal-consumer-object-storage` secret (MinIO)
- **Provisioning**: Registers via provisioning-api

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
```

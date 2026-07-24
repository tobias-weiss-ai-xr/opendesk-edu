<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

# openDesk Edu

**openDesk Edu** is an open ecosystem built on [openDesk Community Edition (CE)](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk), providing educational institutions with full digital sovereignty through choice and interchangeability.

It deploys on the CE submodule (`helmfile/ce/`, v1.17.0) and adds 30+ edu-specific apps, all running on the **HRZ K3s cluster** (`*.opendesk.hrz.uni-marburg.de`).

---

## Architecture

openDesk Edu deploys in two layers:

| Layer | Location | Contents |
|---|---|---|
| **CE** | `helmfile/ce/` (git submodule) | Core services: Keycloak, Nubus, Collabora, Jitsi, Element, OpenProject, XWiki, etc. |
| **Edu** | `helmfile/apps/edu/` | 33 edu-specific apps: ILIAS, Moodle, BigBlueButton, SOGo, Grommunio, Etherpad, OpenCloud, etc. |

Every component is interchangeable — edu replaces or augments CE defaults to best serve university requirements:
- **Groupware**: SOGo + Grommunio; OX App Suite also available
- **File storage**: OpenCloud; Nextcloud also available
- **Mail**: Stalwart, Dovecot
- **Portal**: Self-service portal with edu-specific entries and provisioning

---

## Quick Start

```bash
# Prerequisites
helmfile v1.x
kubectl (cluster context configured)
sops (for encrypted secrets)

# Deploy (default: production)
./deploy.sh

# Dry-run
./deploy.sh --diff

# Deploy test environment
./deploy.sh edu-test
```

See [Deployment Guide](./docs/deployment.md) for detailed instructions.

---

## Edu Applications

| Category | Apps |
|---|---|
| **LMS** | ILIAS, Moodle |
| **VC/Streaming** | BigBlueButton, Opencast, Lecture Recording |
| **Groupware** | SOGo, Grommunio |
| **Collaboration** | Etherpad, Ethercalc, Collabora, OpenCloud |
| **Infrastructure** | Keycloak SAML federation (DFN-AAI), Shibboleth IdP |
| **Automation** | n8n, Semester provisioning, User import/deprovisioning |
| **Monitoring** | Grafana, Loki, Promtail, Alertmanager |

---

## Documentation

| Document | Description |
|---|---|
| [Deployment Guide](./docs/deployment.md) | Full deployment instructions |
| [AGENTS.md](./AGENTS.md) | Architecture reference (preserved knowledge) |
| [Semester Lifecycle](./docs/semester-lifecycle.md) | Semester automation |
| [DFN-AAI Federation](./docs/dfn-aai-federation.md) | SAML federation setup |
| [Testing](./docs/testing.md) | E2E and integration tests |
| [Course Provisioning API](./docs/course-provisioning-api.md) | REST API docs |

Full documentation in [`docs/`](./docs/).

---

## Testing

```bash
# Integration tests
pytest tests/integration/ -v

# Playwright E2E tests
npx playwright test --config tests/playwright/
```

---

## Repository Structure

```
.
├── helmfile/
│   ├── ce/                      # CE submodule (v1.17.0)
│   ├── apps/edu/                # 33 edu app charts
│   ├── charts/                  # Shared edu Helm charts
│   └── environments/edu/        # Edu config (overrides, secrets, images)
├── docs/                        # Edu documentation
├── tests/                       # Integration + E2E tests
├── scripts/                     # Deployment & utility scripts
├── deploy.sh                    # One-command deployment
└── AGENTS.md                    # Architecture reference
```

---

## License

Apache-2.0 — see [LICENSE](./LICENSE).

Copyright (C) 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH

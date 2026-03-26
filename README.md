<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

<div align="center">

<img src="docs/assets/readme-lead-image.svg" alt="openDesk Edu" width="100%"/>

# 🎓 openDesk Edu

**openDesk + Educational Services for Universities**

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Kubernetes](https://img.shields.io/badge/Platform-Kubernetes-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io)
[![Helm](https://img.shields.io/badge/Deploy-Helm-0F1689?logo=helm&logoColor=white)](https://helm.sh)
[![Upstream](https://img.shields.io/badge/Upstream-openDesk_CE_v1.13.x-green)](https://www.opencode.de/en/opendesk)

<br/>

[📖 ILIAS](https://www.ilias.de/) &nbsp;·&nbsp;
[📚 Moodle](https://moodle.org/) &nbsp;·&nbsp;
[🎥 BigBlueButton](https://bigbluebutton.org/) &nbsp;·&nbsp;
[☁️ OpenCloud](https://opencloud.eu/) &nbsp;·&nbsp;
[🔐 Keycloak SSO](https://www.keycloak.org/)

<br/>

An extension of [openDesk Community Edition](https://www.opencode.de/en/opendesk) that adds
**learning management systems** (ILIAS, Moodle) and provides **alternative components** for
video conferencing (BigBlueButton ↔ Jitsi) and file sharing (OpenCloud ↔ Nextcloud) —
all integrated with openDesk's existing Keycloak SSO and portal. Deploy everything on Kubernetes with a single `helmfile apply`.

[Getting Started →](#-quick-start) &nbsp;·&nbsp; [What's Added →](#-whats-added-on-top-of-opendesk-ce) &nbsp;·&nbsp; [Roadmap →](./ROADMAP.md) &nbsp;·&nbsp; [All Components →](#-full-component-matrix)

</div>

---

## 🚀 Quick Start

> **Prerequisites:** Kubernetes 1.28+, Helm 3, [helmfile](https://helmfile.readthedocs.io/)

```bash
# 1. Clone the repo
git clone https://github.com/tobias-weiss-ai-xr/opendesk-edu.git
cd opendesk-edu

# 2. Configure your environment
#    Edit helmfile/environments/default/global.yaml.gotmpl
#    Set your domain, mail domain, and image registry

# 3. Deploy
helmfile -e default apply

# 4. Access the portal
#    Open https://portal.<your-domain> in your browser
```

📖 For detailed instructions see the [Getting started guide](./docs/getting-started.md) and [Requirements](./docs/requirements.md).

---

## 📚 What is openDesk Edu?

openDesk Edu takes the stock [openDesk CE](https://www.opencode.de/en/opendesk) deployment and adds the
core services universities need — all integrated with openDesk's existing Keycloak-based SSO and portal.

### What's added on top of openDesk CE ➕

| Service | Component | Status | Description |
|:--------|:----------|:------:|:------------|
| 📖 **Learning Management** | [ILIAS](https://www.ilias.de/) | 🔄 Beta | Full-featured LMS with SAML SSO — courses, SCORM, assessments, forums |
| 📖 **Learning Management** | [Moodle](https://moodle.org/) | 🔄 Beta | LMS with Shibboleth auth — plugins, gradebook, workshops |

### Additional education tools 🎓

| Service | Component | Status | Description |
|:--------|:----------|:------:|:------------|
| 📝 **Collaborative Editing** | [Etherpad](https://etherpad.org/) | ✅ Stable | Real-time collaborative document editor — meeting notes, workshops, live editing |
| 📚 **Knowledge Base** | [BookStack](https://www.bookstackapp.com/) | ✅ Stable | Wiki with book/chapter structure — course materials, SOPs, documentation |
| 📋 **Project Management** | [Planka](https://planka.app/) | ✅ Stable | Kanban boards with OIDC — student projects, research planning |
| 🎫 **Service Desk** | [Zammad](https://zammad.com/) | ✅ Stable | Helpdesk with SAML — IT support, multi-channel (email, chat, phone) |
| 📊 **Surveys** | [LimeSurvey](https://www.limesurvey.org/) | ✅ Stable | Survey platform — course evaluations, academic research |
| 🔑 **Password Self-Service** | [LTB SSP](https://ltb-project.org/) | ✅ Stable | LDAP password reset — reduces helpdesk tickets |
| 📐 **Diagramming** | [Draw.io](https://www.drawio.com/) | ✅ Stable | Architecture diagrams, flowcharts, UML — export to PDF/VSDX |
| ✏️ **Whiteboarding** | [Excalidraw](https://excalidraw.com/) | ✅ Stable | Hand-drawn sketches, brainstorming — lightweight and fast |

### Alternative components 🔄

These can be used **instead of** their openDesk CE counterparts. Enable one or the other — not both.

| Replaces | Alternative | Status | Why? |
|:---------|:------------|:------:|:-----|
| 📹 [Jitsi](https://jitsi.github.io/) | [BigBlueButton](https://bigbluebutton.org/) | 🔄 Beta | Built for teaching — recording, breakout rooms, whiteboard, polling, session timers |
| 📁 [Nextcloud](https://nextcloud.com/) | [OpenCloud](https://opencloud.eu/) | 🔄 Beta | Lightweight CS3-based file sync — separate user namespace, per-course shares |

### How it works ⚙️

- 🔐 **Single Sign-On** — All educational services authenticate through openDesk's Keycloak via
  SAML 2.0 (ILIAS, BBB, Moodle) or OIDC (OpenCloud). One login, everything.
- 🖥️ **Unified Portal** — Custom SVG icons and portal tiles give users direct access to ILIAS, Moodle,
  BigBlueButton, and OpenCloud alongside all standard openDesk apps.
- 📦 **Helm Charts** — Each service has its own chart with configurable values, SAML SP config,
  ingress rules, and persistence.
- 💾 **Integrated Backups** — k8up-based backup schedules for educational service data.

### What's unchanged ✅

All core openDesk CE components remain intact — Element, Nextcloud, Open-Xchange, XWiki, OpenProject,
Jitsi, CryptPad, Notes, Collabora, and the full Nubus IAM stack. BBB and OpenCloud are optional
drop-in alternatives, not replacements. This is a **superset** of openDesk CE, not a fork.

---

## 🏢 Full Component Matrix

> The complete openDesk suite including all educational extensions.

| 🏷️ Function | 📦 Component | 📜 License | 📌 Version | 📖 Docs |
|:-------------|:-------------|:-----------|:-----------|:--------|
| 💬 Chat | Element ft. Nordeck widgets | AGPL-3.0 / Apache-2.0 | [1.12.6](https://github.com/element-hq/element-web/releases/tag/v1.12.6) | [Docs](https://element.io/user-guide) |
| 📝 Notes | Notes (aka Docs) | MIT | [4.4.0](https://github.com/suitenumerique/docs/releases/tag/v4.4.0) | In-app |
| 📊 Diagrams | CryptPad ft. diagrams.net | AGPL-3.0 | [2025.9.0](https://github.com/cryptpad/cryptpad/releases/tag/2025.9.0) | [Docs](https://docs.cryptpad.org/en/) |
| 📁 Files | Nextcloud | AGPL-3.0 | [32.0.6](https://nextcloud.com/de/changelog/#32-0-6) | [Docs](https://docs.nextcloud.com/) |
| 📧 Groupware | OX App Suite | GPL-2.0 / AGPL-3.0 | [8.46](https://documentation.open-xchange.com/appsuite/releases/8.46/) | [Docs](https://documentation.open-xchange.com/) |
| 📚 Wiki | XWiki | LGPL-2.1 | [17.10.4](https://www.xwiki.org/xwiki/bin/view/ReleaseNotes/Data/XWiki/17.10.4/) | [Docs](https://www.xwiki.org/xwiki/bin/view/Documentation) |
| 🔑 Portal & IAM | Nubus | AGPL-3.0 | [1.18.1](https://docs.software-univention.de/nubus-kubernetes-release-notes/1.x/en/1.18.html) | [Docs](https://docs.software-univention.de/n/en/nubus.html) |
| 📋 Projects | OpenProject | GPL-3.0 | [17.2.1](https://www.openproject.org/docs/release-notes/17-2-1/) | [Docs](https://www.openproject.org/docs/user-guide/) |
| 📹 Meetings | Jitsi | Apache-2.0 | [2.0.10590](https://github.com/jitsi/jitsi-meet/releases/tag/stable%2Fjitsi-meet_10590) | [Docs](https://jitsi.github.io/handbook/docs/category/user-guide/) |
| 📄 Office | Collabora | MPL-2.0 | [25.04.8](https://www.collaboraoffice.com/code-25-04-release-notes/) | [Docs](https://sdk.collaboraonline.com/) |
| 📖 **LMS** | **ILIAS** | GPL-3.0 | [7.28](https://github.com/ILIAS-eLearning/ILIAS/releases) | [Docs](https://docu.ilias.de/) |
| 📖 **LMS** | **Moodle** | GPL-3.0 | [4.4](https://moodle.org/release/) | [Docs](https://docs.moodle.org/) |
| 🎥 **Lectures** | **BigBlueButton** (↔ Jitsi) | LGPL-3.0 | [2.7](https://github.com/bigbluebutton/bigbluebutton/releases) | [Docs](https://docs.bigbluebutton.org/) |
| ☁️ **Files** | **OpenCloud** (↔ Nextcloud) | Apache-2.0 | [4.0.3](https://github.com/opencloudeu/opencloud/releases) | [Docs](https://docs.opencloud.eu/) |
| 📝 **Collab Editing** | **Etherpad** | Apache-2.0 | [1.9.9](https://github.com/ether/etherpad-lite/releases) | [Docs](https://etherpad.org/doc/) |
| 📚 **Wiki** | **BookStack** | MIT | [26.03](https://github.com/BookStackApp/BookStack/releases) | [Docs](https://www.bookstackapp.com/docs/) |
| 📋 **Kanban** | **Planka** | AGPL-3.0 | [2.1.0](https://github.com/plankanban/planka/releases) | [Docs](https://docs.planka.app/) |
| 🎫 **Helpdesk** | **Zammad** | AGPL-3.0 | [7.0](https://github.com/zammad/zammad/releases) | [Docs](https://docs.zammad.com/) |
| 📊 **Surveys** | **LimeSurvey** | GPL-2.0 | [6.6](https://github.com/LimeSurvey/LimeSurvey/releases) | [Docs](https://www.limesurvey.org/manual/) |
| 🔑 **Password Reset** | **LTB SSP** | GPL-3.0 | [1.7](https://github.com/ltb-project/self-service-password/releases) | [Docs](https://self-service-password.readthedocs.io/) |
| 📐 **Diagrams** | **Draw.io** | Apache-2.0 | [29.6](https://github.com/jgraph/drawio/releases) | [Docs](https://www.drawio.com/doc/) |
| ✏️ **Whiteboard** | **Excalidraw** | MIT | [latest](https://github.com/excalidraw/excalidraw/releases) | [Docs](https://docs.excalidraw.com/) |

---

## 📖 Documentation

| Topic | Link |
|:------|:-----|
| ⬆️ Upgrades & Migrations | [docs/migrations.md](./docs/migrations.md) |
| 📋 Requirements | [docs/requirements.md](./docs/requirements.md) |
| 🚀 Getting Started | [docs/getting-started.md](./docs/getting-started.md) |
| 🔧 Advanced Customization | [docs/enhanced-configuration.md](./docs/enhanced-configuration.md) |
| 🔌 External Services (edu) | [docs/external-services.md](./docs/external-services.md) |
| 🏗️ Architecture | [docs/architecture.md](./docs/architecture.md) |
| 🔐 Security | [docs/security.md](./docs/security.md) |
| 📊 Scaling | [docs/scaling.md](./docs/scaling.md) |
| 📈 Monitoring | [docs/monitoring.md](./docs/monitoring.md) |
| 🎨 Theming | [docs/theming.md](./docs/theming.md) |
| 🔑 Permissions | [docs/permissions.md](./docs/permissions.md) |
| 💾 Data Storage | [docs/data-storage.md](./docs/data-storage.md) |
| 🧪 Testing | [docs/testing.md](./docs/testing.md) |

---

## 🎤 Presentations

| Event | Topic | Format |
|:------|:------|:-------|
| [LinuxTag 2026](./docs/presentations/linuxtag-2026/linuxtag-2026-opendesk.md) | openDesk at University of Marburg — Deployment & openDesk Edu | Marp (HTML/PDF) |

---

## 🛠️ Tech Stack

| Layer | Technology |
|:------|:-----------|
| ☸️ Orchestration | [Kubernetes](https://kubernetes.io) |
| 📦 Package Management | [Helm](https://helm.sh) + [helmfile](https://helmfile.readthedocs.io/) |
| 🔐 Authentication | [Keycloak](https://www.keycloak.org/) (SAML 2.0 + OIDC) |
| 🎓 SAML SP | [Shibboleth](https://www.shibboleth.net/) (ILIAS, Moodle, BBB) |
| 💾 Backup | [k8up](https://k8up.io/) (restic + Kubernetes operator) |
| 🔒 Certificates | [openDesk Certificates](https://github.com/Bundesdruckerei/opendesk-certificates) |

---

## 💬 Feedback & Issues

Found a bug or have a feature request? Please [open an issue](https://github.com/tobias-weiss-ai-xr/opendesk-edu/issues).

## 🤝 Contributing

Contributions are welcome! See the [Development guide](./docs/developer/development.md) for how to get started.

---

## 📄 License

[Apache-2.0](https://opensource.org/licenses/Apache-2.0) — see [LICENSE](./LICENSE) for details.

## ©️ Copyright

openDesk Edu is a fork of [openDesk](https://www.opencode.de/en/opendesk). Upstream copyright:

Copyright (C) 2024-2025 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH

openDesk Edu additions:

Copyright (C) 2025-2026 openDesk Edu Contributors

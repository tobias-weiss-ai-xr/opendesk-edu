<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://www.opendesk-edu.org/static/brand/icon.svg">
  <img alt="openDesk Edu" src="https://www.opendesk-edu.org/static/brand/icon.svg" width="120" align="right">
</picture>

# 🎓 openDesk Edu

**Educational Digital Infrastructure — Collaboration and Research Services for Higher Education**

openDesk Edu extends [openDesk Community Edition](https://www.opencode.de/en/opendesk) with the core services universities need — learning management systems, collaborative tools, and research infrastructure — all integrated with openDesk's existing Keycloak SSO and unified portal. Deploy everything on Kubernetes with a single `helmfile apply`.

[🌐 Website](https://www.opendesk-edu.org) · [📖 Docs](https://www.opendesk-edu.org/en/docs) · [📝 Blog](https://www.opendesk-edu.org/en/blog) · [🚀 Get Started](https://github.com/opendesk-edu/opendesk-edu#-quick-start)

[![Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Kubernetes](https://img.shields.io/badge/Platform-Kubernetes-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io)

---

## 📦 Repositories

| Repository | Description | Status |
|:-----------|:------------|:------:|
| [**opendesk-edu/opendesk-edu**](https://github.com/opendesk-edu/opendesk-edu) | Core repository — Helm charts, helmfile deployment, documentation, and CI/CD for all educational services | 🟢 Active |
| [**opendesk-edu/opendesk-edu-website**](https://github.com/opendesk-edu/opendesk-edu-website) | Project website at [opendesk-edu.org](https://www.opendesk-edu.org) | 🟢 Active |
| [**opendesk-edu/opendesk-edu-spec**](https://github.com/opendesk-edu/opendesk-edu-spec) | Architecture specification, SLO definitions, and validation tests | 🟢 Active |
| [**opendesk-edu/opendesk-edu-landscape**](https://github.com/opendesk-edu/opendesk-edu-landscape) | Interactive landscape map of the openDesk Edu ecosystem | 🟢 Active |
| [**opendesk-edu/opendesk-cop**](https://github.com/opendesk-edu/opendesk-cop) | Continuity of Operations — backup, restore, and disaster recovery procedures | 🟢 Active |
| [**opendesk-edu/.github**](https://github.com/opendesk-edu/.github) | Organization profile and community health files | 🟢 Active |

---

## 🧩 Educational Services

openDesk Edu adds **13 services** on top of openDesk CE, plus **3 alternative components**:

### 📚 Learning Management
| Service | Component | SSO | Description |
|:--------|:----------|:---:|:------------|
| 📖 LMS | [ILIAS](https://www.ilias.de/) | SAML | Courses, assessments, forums, SCORM |
| 📖 LMS | [Moodle](https://moodle.org/) | Shibboleth | Assignments, workshops, gradebook |

### 🎓 Campus Tools
| Service | Component | Description |
|:--------|:----------|:------------|
| 🎥 Lectures | [BigBlueButton](https://bigbluebutton.org/) | Teaching-focused VC: recording, breakout rooms, whiteboard |
| 📝 Collaborative Editing | [Etherpad](https://etherpad.org/) | Real-time collaborative documents |
| 📚 Knowledge Base | [BookStack](https://www.bookstackapp.com/) | Book/chapter structured wiki |
| 📋 Project Management | [Planka](https://planka.app/) | Kanban boards with OIDC |
| 🎫 Service Desk | [Zammad](https://zammad.com/) | Multi-channel helpdesk with SAML |
| 📊 Surveys | [LimeSurvey](https://www.limesurvey.org/) | Course evaluations, research surveys |
| 🔑 Password Self-Service | [LTB SSP](https://ltb-project.org/) | LDAP password reset |
| 📐 Diagramming | [Draw.io](https://www.drawio.com/) | Architecture diagrams, flowcharts |
| ✏️ Whiteboarding | [Excalidraw](https://excalidraw.com/) | Hand-drawn sketches, brainstorming |
| ☁️ File Sync (alt) | [OpenCloud](https://opencloud.eu/) | CS3-based, lightweight file sync |
| 💌 Webmail (alt) | [SOGo](https://www.sogo.nu/) | Email-focused groupware |
| 📰 CMS | [TYPO3](https://typo3.org/) | Enterprise content management |

All services integrate with openDesk's **Keycloak SSO** and **Nubus portal** — one login for everything.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Nubus Portal & IAM                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │ Keycloak  │  │  LDAP    │  │  Shibboleth IdP  │   │
│  │ (SAML/OIDC│  │(OpenLDAP)│  │  (DFN-AAI)       │   │
│  └────┬─────┘  └────┬─────┘  └────────┬─────────┘   │
├───────┴──────────────┴──────────────────┴────────────┤
│                   Service Layer                       │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐         │
│  │ ILIAS  │ │ Moodle │ │  BBB   │ │OpenCloud│        │
│  │ SAML   │ │Shibboleth│ │SAML/OIDC│ │ OIDC   │      │
│  └────────┘ └────────┘ └────────┘ └────────┘         │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐         │
│  │Etherpad│ │BookStack│ │ Planka │ │ Zammad │         │
│  └────────┘ └────────┘ └────────┘ └────────┘         │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐         │
│  │LimeSurv.│ │ Draw.io│ │Excalidr.│ │  TYPO3 │        │
│  └────────┘ └────────┘ └────────┘ └────────┘         │
├──────────────────────────────────────────────────────┤
│              Infrastructure Layer                      │
│   ☸️ Kubernetes · 📦 Helm/helmfile · 💾 k8up/restic   │
└──────────────────────────────────────────────────────┘
```

---

## 🔗 Community & Contact

| | |
|:--|:--|
| 🌐 **Website** | [opendesk-edu.org](https://www.opendesk-edu.org) |
| 💬 **Matrix** | [#opendesk-ce-public:matrix.uni-marburg.de](https://matrix.to/#/#opendesk-ce-public:matrix.uni-marburg.de) |
| 🐙 **GitHub** | [github.com/opendesk-edu](https://github.com/opendesk-edu) |
| 🪣 **Codeberg** | [codeberg.org/opendesk-edu](https://codeberg.org/opendesk-edu) |
| 📧 **Email** | [info@opendesk-edu.org](mailto:info@opendesk-edu.org) |
| 📝 **Blog** | [opendesk-edu.org/en/blog](https://www.opendesk-edu.org/en/blog) |

---

## 📄 License

All openDesk Edu repositories are licensed under **Apache-2.0** unless otherwise noted.

openDesk Edu is a fork of [openDesk](https://www.opencode.de/en/opendesk) by Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH.

# 🗺️ Roadmap

> openDesk Edu — from current state to a complete digital workplace for universities.

## Principles

1. **Sovereignty first** — every service self-hosted, no data leaves the cluster
2. **Helm-native** — all integrations deployed via Helm charts within the existing helmfile structure
3. **SSO everywhere** — SAML 2.0 (Shibboleth SP → Keycloak) for legacy apps, OIDC for modern apps
4. **LTI where it matters** — any teaching tool must be launchable from LMS via LTI 1.3
5. **No NIH** — integrate proven open-source tools, don't rebuild them

---

## Current State (v1.0)

| What | Status |
|:-----|:------:|
| ILIAS LMS with SAML SSO | ✅ |
| Moodle LMS with Shibboleth | ✅ |
| BigBlueButton ↔ Jitsi (alternative) | ✅ |
| OpenCloud ↔ Nextcloud (alternative) | ✅ |
| Unified Keycloak SSO | ✅ |
| Portal integration (tiles, icons) | ✅ |

---

## v1.1 — Foundation

> Hardening what we have and adding the missing essentials.

### DFN-AAI / eduGAIN SAML Federation Support

German universities authenticate via the DFN-AAI federation (Shibboleth IdP). openDesk Edu must work as a
SAML Service Provider within this federation.

- [ ] Register openDesk Edu as a SAML SP in DFN-AAI
- [ ] Support standard eduGAIN attributes (`eduPersonAffiliation`, `mail`, `displayName`, `persistentId`)
- [ ] Document federation metadata generation for deployers
- [ ] Support Shibboleth IdP as external identity provider (for universities that already run one)
- [ ] Test with DFN-AAI test federation (`https://www.aai.dfn.de/`)

### Semester Lifecycle Management

Universities run on semester cycles (Wintersemester, Sommersemester). Courses, enrollments, and access
need to follow this rhythm.

- [ ] Course provisioning API (create/archive courses per semester)
- [ ] Role-based access control tied to semester enrollment (instructor, student, tutor)
- [ ] Automated course archival at semester end
- [ ] Integration hook for campus management systems (HIS/LSF)

### Backchannel Logout

Critical for security — when a user logs out of the portal, all sessions across all services must
be terminated.

- [ ] Implement SAML backchannel logout for ILIAS, Moodle, BBB
- [ ] Implement OIDC backchannel logout for OpenCloud, Nextcloud
- [ ] Central logout from portal propagates to all services

---

## v1.2 — Lecture Recording

> The #1 requested teaching tool beyond LMS + video conferencing.

### Opencast + Tobira Integration

[Opencast](https://opencast.org/) is the dominant open-source lecture recording system in DACH universities
(150+ contributors, active development, ECL-2.0 license). [Tobira](https://github.com/elan-ev/tobira) is a modern
video portal built on top of Opencast (Rust, AGPL-3.0).

| What | Why |
|:-----|:----|
| Official Docker images | Easy to wrap in Helm |
| LTI support | Launchable from Moodle/ILIAS courses |
| Shibboleth/OIDC auth | Fits Keycloak SSO |
| Built-in Prometheus metrics | Fits openDesk monitoring |
| Whisper transcription | Local AI transcription, no cloud dependency |

- [ ] Helm chart for Opencast (admin, worker, presentation nodes)
- [ ] Helm chart for Tobira video portal
- [ ] SSO integration via Keycloak (OIDC)
- [ ] LTI 1.3 integration with ILIAS and Moodle
- [ ] Storage backend (Ceph/NFS for recordings, separate PVC)
- [ ] Portal tile for Tobira
- [ ] Backup integration with k8up
- [ ] GPU scheduling support for transcription (optional)

---

## v2.0 — Course Evaluation & E-Portfolio

> Completing the teaching and learning cycle.

### EvaP — Course Evaluation

[EvaP](https://github.com/evasys/evasys) (MIT license, Python/Django) is the standard course evaluation
system used at HPI and growing in adoption. Lightweight, fits well into a Kubernetes deployment.

- [ ] Helm chart for EvaP
- [ ] LDAP/Keycloak SSO integration
- [ ] Semester-linked evaluation periods
- [ ] Portal tile for course evaluation

### Mahara — E-Portfolio

[Mahara](https://mahara.org/) (GPL v3, PHP) is the leading open-source e-portfolio platform. Supports
LTI for launch from LMS, SAML for SSO, and provides competency-based assessment.

- [ ] Helm chart for Mahara
- [ ] Shibboleth SP SSO integration
- [ ] LTI integration with ILIAS and Moodle
- [ ] Portal tile for e-portfolio

---

## v2.1 — Campus Operations

> Room booking, equipment lending, and resource management.

### MRBS — Room Booking

[MRBS](https://mrbs.sourceforge.io/) (GPL v2, PHP) is the most widely deployed open-source room booking
system in universities. Simple, LDAP-aware, well-understood.

- [ ] Helm chart for MRBS
- [ ] LDAP authentication
- [ ] Integration with university calendar (iCal export)
- [ ] Portal tile

### LEIHS — Equipment Booking

[LEIHS](https://github.com/leihs/leihs) (GPL v3, Ruby) is used at multiple German universities for
equipment and resource booking (cameras, laptops, lab equipment).

- [ ] Helm chart for LEIHS
- [ ] SSO integration (LDAP/Shibboleth)
- [ ] Portal tile

---

## v3.0 — Digital Examination

> Secure, on-premise exam infrastructure — a post-COVID standard.

### R/exams + Safe Exam Browser

[R/exams](https://www.r-exams.org/) (AGPL v3, R) supports online exams with LTI integration for Moodle and
ILIAS. Combined with the [Safe Exam Browser](https://safeexambrowser.org/) (GPL v2), provides a lockdown
environment.

- [ ] Helm chart for R/exams
- [ ] LTI integration with Moodle and ILIAS
- [ ] Safe Exam Browser configuration distribution
- [ ] Exam scheduling tied to semester calendar

### JPlag — Plagiarism Detection

[JPlag](https://github.com/jplag/jplag) (GPL v3, Java, developed at KIT) runs entirely locally — no data
leaves the cluster. Supports 15+ programming languages. GDPR-friendly by design.

- [ ] Helm chart for JPlag
- [ ] API integration with Moodle assignment submission
- [ ] Automated batch analysis per course

---

## v4.0 — AI & Analytics

> Where universities are heading — with data sovereignty.

### Local LLM Integration

Universities need AI tools that don't send student data to cloud providers. The German government is
funding €1B for AI infrastructure (2026-2030).

- [ ] Helm chart for local LLM inference (vLLM / Ollama)
- [ ] API gateway for LLM access from teaching tools
- [ ] Integration with Moodle (AI tutoring plugin) and ILIAS
- [ ] GPU scheduling and resource limits

### Learning Analytics (xAPI)

Capture learning activity across all services (LMS, video, portfolio) with xAPI standard.

- [ ] Learning Record Store (LRS) deployment
- [ ] xAPI event collection from ILIAS, Moodle, BBB
- [ ] GDPR-compliant analytics dashboards (anonymized by default)
- [ ] Instructor dashboards for course engagement

---

## v5.0 — Federation & Multi-Tenancy

> Sharing services across universities.

### Cross-University Service Sharing

Following models like VCRP (Rhineland-Palatinate shared OpenOlat), enable universities to share services
while keeping data separate.

- [ ] Multi-tenant Keycloak configuration
- [ ] Per-tenant namespace isolation in Kubernetes
- [ ] Shared Opencast/BBB infrastructure with tenant separation
- [ ] Shared helmfile environments for multi-university deployments

### Research Data Management

Growing EU requirement via European Open Science Cloud (EOSC).

- [ ] Integration with institutional repositories (Zenodo, Invenio)
- [ ] Research data storage (separate from teaching data)
- [ ] Data management plan templates

---

## Not Planned (or Deferred)

| Tool | Reason |
|:-----|:-------|
| **Stud.IP** | No LTI, no Docker/K8s, limited REST API — too hard to integrate. Universities that use it should keep it alongside openDesk. |
| **Papercut MF** | Proprietary. No viable open-source alternative exists for full print management (web print, follow-me, card readers). |
| **Canvas LMS** | Proprietary (Instructure). Conflicts with sovereignty principle. |
| **Shibboleth IdP** | Universities already run their own. openDesk Edu should integrate as a SP, not provide an IdP. |
| **Keycloak as eduGAIN IdP** | SAML federation support is incomplete. Use Shibboleth IdP for federation, Keycloak for internal IAM. |

---

## Timeline

```
2026 Q2   v1.0  Current state (ILIAS, Moodle, BBB, OpenCloud)
          v1.1  DFN-AAI federation + semester lifecycle + logout
2026 Q3   v1.2  Opencast + Tobira lecture recording
2026 Q4   v2.0  EvaP + Mahara (evaluation + portfolio)
2027 Q1   v2.1  MRBS + LEIHS (room + equipment booking)
2027 Q2   v3.0  R/exams + JPlag (digital examination)
2027 Q3   v4.0  Local LLM + xAPI analytics
2027 Q4   v5.0  Multi-tenancy + research data management
```

---

## Contributing

Have an idea for the roadmap? [Open an issue](https://github.com/tobias-weiss-ai-xr/opendesk-edu/issues) — we'd love to hear what your university needs.

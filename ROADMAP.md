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
| Etherpad collaborative editor (OIDC) | ✅ |
| BookStack knowledge base (SAML) | ✅ |
| Planka project boards (OIDC) | ✅ |
| Zammad helpdesk (SAML) | ✅ |
| LimeSurvey course evaluation (LDAP) | ✅ |
| Draw.io diagramming (stateless) | ✅ |
| Excalidraw whiteboard (stateless) | ✅ |
| Self-Service Password (LDAP) | ✅ |
| SOGo groupware (alternative to OX App Suite) | ✅ |
| TYPO3 CMS v13.4 LTS (SAML2 + OIDC SSO) | ✅ |
| Grommunio groupware (ActiveSync, OIDC) | ✅ |

---

## v1.1 — Foundation

> Hardening what we have and adding the missing essentials.

### DFN-AAI / eduGAIN SAML Federation Support

German universities authenticate via the DFN-AAI federation (Shibboleth IdP). openDesk Edu must work as a
SAML Service Provider within this federation.

- [ ] Register openDesk Edu as a SAML SP in DFN-AAI
- [x] Support standard eduGAIN attributes (`eduPersonAffiliation`, `mail`, `displayName`, `persistentId`)
- [x] Document federation metadata generation for deployers
- [x] Support Shibboleth IdP as external identity provider (for universities that already run one)
- [x] Predictable federation metadata (SP) — scripts at `scripts/saml-metadata-generator/` and `scripts/dfn-aai-setup/`
- [ ] Test with DFN-AAI test federation (`https://www.aai.dfn.de/`)

### Semester Lifecycle Management

Universities run on semester cycles (Wintersemester, Sommersemester). Courses, enrollments, and access
need to follow this rhythm.

- [x] Course provisioning API (create/archive courses per semester)
- [x] Role-based access control tied to semester enrollment (instructor, student, tutor)
- [x] Automated course archival at semester end
- [x] Integration hook for campus management systems (HIS/LSF)

### Build Pipeline — Own Container Images

All charts currently use upstream container images. Building own images gives sovereignty over
security patching, custom configurations, and supply-chain transparency.

- [ ] Set up CI pipeline for building images from upstream source
- [ ] Image registry infrastructure (Harbor or equivalent)
- [ ] Automated base-image updates (Dependabot/Renovate for Docker)
- [ ] Signing and attestation (cosign, SBOM generation)

### Backchannel Logout

Critical for security — when a user logs out of the portal, all sessions across all services must
be terminated.

- [x] Implement SAML backchannel logout for ILIAS, Moodle, BBB
- [x] Implement OIDC backchannel logout for OpenCloud, Nextcloud
- [x] Central logout from portal propagates to all services

### User Provisioning & Deprovisioning

Automate the complete user lifecycle — from account creation to permanent deletion — using the
existing `scripts/user_import/` tooling.

- [x] Clean up and migrate `user_import` tooling from legacy repo into `scripts/user_import/`
- [x] Configurable SAML account linking via Keycloak admin API (federated-identity endpoints)
- [x] Two-phase deprovisioning: disable (6-month grace period) → permanent delete
- [x] UCS/UDM REST API integration for provisioning (LDAP groups, CSV/ODS import)
- [x] Docker image for standalone execution
- [x] Documentation and operational runbook

---

## v1.5 — Campus Management Integration (HISinOne / Marvin)

> The deepest integration layer — connecting openDesk Edu to the university's central nervous system.
> This is what turns a collection of apps into a **unified digital campus**.

### Why This Matters

[HISinOne](https://www.his.de/hisinone/) by HIS eG is the dominant campus management system in German
higher education — used by **200+ universities**, including Marburg (where it runs as **"Marvin"**). It is the
**source of truth** for:

- **Who** is at the university — students, faculty, staff, guests (Personenverwaltung / PSV)
- **What** they study — degree programs, modules, exam regulations, ECTS credits
- **When** things happen — semester calendar, exam periods, course schedules, deadlines
- **How well** they do — exam grades, transcripts, module completion status

Every other system at a university is downstream from campus management. LMS courses are created because
a module exists in the Prüfungsordnung. Students enroll in courses because HISinOne says they're
registered. Rooms are booked because HISinOne's timetable says so. **Without campus management integration,
openDesk Edu is just a suite of disconnected apps. With it, it becomes a digital campus.**

### The Data Model

HISinOne manages the **complete student lifecycle**:

```
Application → Enrollment → Study → Exams → Graduation → Alumni
   (APP)        (STU)       (EXA)    (EXA)     (STU)    (ALU)
```

Key entities that flow into openDesk Edu:

| Entity | HISinOne Module | openDesk Impact |
|:-------|:----------------|:----------------|
| **Person** (identity, roles, contact) | PSV | Account provisioning, SSO, group assignment |
| **Student** (matrikel number, status, fees) | STU | Role-based access (student/faculty), account lifecycle |
| **Degree Program** (BA/MA/StEx, rules, ECTS) | EXA | Study progress tracking, module requirements |
| **Module** (credits, workload, type, description) | EXA | Course catalog, handbook data |
| **Course** (title, semester, lecturers, room, time) | EXA-VM | Course creation in LMS, schedule, room info |
| **Enrollment** (student ↔ course registration) | EXA-VM | LMS membership, course rosters |
| **Parallel Groups** (course sections) | EXA-VM | LMS groups, tutorial assignments |
| **Exam** (type, date, room, grade) | EXA-PM | Grade display, transcript of records |
| **Room** (capacity, equipment, location) | EXA-VM | Room info in course context |
| **Application** (applicant data, program choice) | APP | Pre-enrollment access, guest accounts |

### Integration Architecture

The proven pattern at German universities uses **three layers**:

```
┌──────────────┐       ┌──────────────────┐       ┌──────────────────┐
│   HISinOne   │       │  openDesk Edu    │       │    HISinOne     │
│   (Marvin)   │       │  Integration    │       │    Proxy         │
│              │       │  Layer           │       │    (PHP, OSS)    │
│  SOAP API    │◄──────│  (middleware)     │──────►│    + Queue       │
│  Events      │       │                  │       │    + Dedup        │
│  qisserver   │       │                  │       │    + Listener     │
└──────────────┘       └──────┬───────────┘       └──────────────────┘
                              │
                ┌─────────┴──────────┐
                │                    │
         ┌──────▼──────┐    ┌─────▼──────┐
         │  Keycloak   │    │  LMS       │
         │  (SSO +     │    │  (ILIAS /   │
         │   accounts) │    │   Moodle)   │
         └──────┬──────┘    └─────┬──────┘
                │                  │
         ┌──────▼──────┐    ┌─────▼──────┐    ┌──────────────┐
         │  BBB /      │    │  BBB /      │    │  Nextcloud /  │
         │  Jitsi      │    │  Jitsi      │    │  OpenCloud    │
         └─────────────┘    └─────────────┘    └──────────────┘
```

**Key technical decisions:**

1. **Build on the HISinOne-Proxy** ([GitHub](https://github.com/DatabayAG/his_in_one_proxy), GPL-3.0)
   — the community-standard middleware used by FH Dortmund (3,000 courses/semester), Uni Bonn,
   FH Aachen, HHU Düsseldorf. Don't reinvent the wheel.
2. **HISinOne communicates via SOAP** (`qisserver/services2/`) + **TCP event listener** (push, not poll)
3. **openDesk Integration Layer** extends the proxy with additional targets (Keycloak, BBB, OpenCloud)
4. **HISinOne is always the source of truth** — openDesk reads, never writes back to campus management

### Phase 1: Identity & Account Lifecycle

Automate user provisioning based on university enrollment/exmatriculation events.

**Data flow:**

```
HISinOne (immatrikulation) → LDAP/AD (existing university IdM) → Keycloak (user sync) → all services
HISinOne (exmatrikulation) → LDAP/AD → Keycloak (user deactivation) → access revoked
```

- [ ] Keycloak LDAP User Federation with the university's existing LDAP/AD
- [ ] Group mapping: HISinOne roles → Keycloak groups → openDesk service access
  - `student` → LMS access, course enrollment, file sharing
  - `employee` → email, groupware, project management
  - `lecturer` → LMS course owner, video conferencing host
  - `faculty:PHIL` → faculty-specific portal tiles and permissions
- [ ] Account lifecycle automation:
  - Immatrikulation → create Keycloak user, assign base groups
  - Beurlaubung (leave of absence) → suspend service access, keep account
  - Exmatrikulation → deactivate account, archive data, revoke access
  - Role change (student → staff) → update group memberships
- [ ] Semester re-registration (Rückmeldung) verification — disable accounts for students who don't re-register
- [ ] Guest lecturer provisioning — temporary accounts with time-limited access

### Phase 2: Course Synchronization

Automate course creation, enrollment, and roster management in ILIAS and Moodle.

**Data flow:**

```
HISinOne (semester start) → HISinOne-Proxy → openDesk Integration Layer
  → ILIAS: create courses, assign categories, add lecturers, enroll students
  → Moodle: create courses, assign cohorts, enroll students
  → BBB: create recurring meeting rooms per course (optional)
  → Nextcloud/OpenCloud: create course file shares (optional)
```

- [ ] Extend HISinOne-Proxy to support openDesk as additional target alongside ILIAS ECS
- [ ] Semester-triggered bulk course creation (all courses for upcoming semester)
- [ ] Continuous incremental sync:
  - New enrollments → add student to LMS course
  - Withdrawals → remove student from LMS course
  - Lecturer changes → update course ownership
  - Room/time changes → update course metadata
- [ ] Parallel group mapping (HISinOne Parallelgruppen → ILIAS course groups / Moodle groups)
- [ ] Course categorization based on HISinOne organizational structure (faculty → department → program)
- [ ] Course archival at semester end (freeze enrollments, archive content)

### Phase 3: Schedule, Rooms & Exams

Bring the semester calendar, room information, and exam data into the unified campus experience.

- [ ] Unified semester calendar:
  - Course schedule (day, time, room) from HISinOne → openDesk calendar / portal
  - Exam dates and registration deadlines
  - Re-registration deadlines
  - Semester breaks and holidays
- [ ] Room information display:
  - Room details (capacity, equipment, accessibility) in course context
  - Building maps / room finder integration
- [ ] Exam management integration:
  - Exam registration (Anmeldung zur Prüfung) from openDesk → HISinOne
  - Grade display in openDesk dashboard after HISinOne grade entry
  - Transcript of records (Notenauszug) accessible from portal
  - Module completion tracking (ECTS progress toward degree)

### Phase 4: Study Progress & Advising

Transform raw campus management data into actionable student-facing information.

- [ ] Study progress dashboard:
  - ECTS earned vs. required per degree program (from HISinOne rules engine)
  - Missing module identification
  - Semester-by-semester plan
  - GPA / grade overview
- [ ] Module handbook integration:
  - Published module descriptions from HISinOne → searchable in openDesk
  - Module prerequisites and dependencies
  - Cross-semester planning tool
- [ ] Notification bridge:
  - HISinOne events → openDesk push notifications (mobile, email, in-app)
  - Exam registration opens/closes
  - Grade published
  - Re-registration deadline approaching
  - Room change for a course
- [ ] Course collaboration spaces:
  - Auto-created Nextcloud/OpenCloud shares per course (based on roster)
  - BBB/Jitsi meeting rooms auto-created per course (based on schedule)

### Phase 5: Cross-Service Intelligence

Connect campus management data with collaboration and communication tools for a smarter campus.

- [ ] Communication groups based on course rosters (mailing lists, chat channels)
- [ ] Document management linked to degree programs (thesis templates, internship reports)
- [ ] Research project ↔ thesis/exam linking (OpenProject tasks → module completion)
- [ ] Analytics: course engagement, attendance patterns, grade trends (GDPR-compliant, anonymized)

### Technical Prerequisites

Before starting any HISinOne integration work:

- [ ] API access to university's HISinOne instance (`qisserver/services2/`)
- [ ] SOAP API credentials (API user + webservice token)
- [ ] Event listener registration (TCP endpoint accessible from HISinOne server)
- [ ] Document the university's specific HISinOne configuration (active modules, custom fields, role names)
- [ ] Fork/contribute to [HISinOne-Proxy](https://github.com/DatabayAG/his_in_one_proxy) for openDesk target support
- [ ] Integration test environment with HISinOne test data

### Risks & Mitigations

| Risk | Impact | Mitigation |
|:-----|:-------|:----------|
| No public API docs (HIS eG member-only) | Blocks development | Partner with university IT; use HISinOne-Proxy as reference |
| SOAP API (not REST) | More complex integration | Use proven proxy pattern; SOAP is stable and well-tested |
| TCP event listener (not webhooks) | Requires network config | Request firewall allowlist for HISinOne → proxy connection |
| Each university customizes HISinOne differently | Hard to generalize | Make integration layer fully configurable per institution |
| HISinOne is not containerized | Can't deploy alongside openDesk | Integration layer runs in-cluster; HISinOne stays on-prem |
| Student data is highly sensitive (DSGVO) | Legal/compliance risk | Follow data minimization; pseudonymize analytics; document data flows |

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

### SNIpR — Lightweight Recording Alternative

[SNIpR](https://github.com/reinauer/SNIpR) (MIT license, Rust) is a lightweight lecture recording
alternative by the same author as F13's transcription service. Perfect for smaller deployments or
universities that want maximum control with minimal infrastructure.

| Feature | Opencast | SNIpR |
|--------|---------|---------|
| Language | Java (large) | Rust (tiny) |
| Complexity | Microservices architecture | Single binary |
| Storage | Requires separate DB | Simple file-based |
| Transcription | Built-in Whisper GPU | External (F13 or stand-alone) |
| Resources | Heavy | Lightweight |
| LTI | Extensive | Basic |
| Use case | Enterprise | Small-to-medium universities |

**Recommendation:** Use Opencast for infrastructure-rich campuses, SNIpR for focused teaching needs.

- [ ] Helm chart for SNIpR recording service
- [ ] SSO integration via Keycloak (OIDC)
- [] Integration with F13 transcription service for auto-transcription
- [ ] Storage backend (S3-compatible for recordings)
- [ ] LTI 1.3 integration with ILIAS and Moodle
- [ ] Portal tile for SNIpR
- [ ] Backup integration with k8up

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

### F13 — Sovereign AI Assistant

[F13](https://f13-os.de/) is an open-source AI assistant developed at Baden-Württemberg universities
(MPL-2.0, 7 microservices). Provides chat, RAG, document summarization, and transcription — all
on-premise, no data leaves the cluster.

| What | Details |
|:-----|:--------|
| **Core** | FastAPI (Python), Svelte frontend |
| **Auth** | Keycloak-native (JWT via JWKS, UMA, RBAC) |
| **Services** | chat, summary, parser (OCR), RAG, transcription (Whisper) |
| **GPU** | Required for parser (EasyOCR), RAG (embeddings), transcription |
| **Registry** | `registry.opencode.de/f13/microservices/` |

- [ ] Helm chart for all 7 F13 microservices
- [ ] Keycloak realm/client configuration (`f13-api`, JWKS, UMA)
- [ ] GPU scheduling support (optional, for parser/RAG/transcription)
- [ ] Secret management (LLM API key, feedback DB, transcription DB, RabbitMQ, HuggingFace token)
- [ ] Configuration via YAML files (general, LLM models, RAG pipeline)
- [ ] Backup integration with k8up (PostgreSQL, Redis, file storage)
- [ ] Portal tile for F13 assistant

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

### SATOSA Proxy for Federated Instances

[SATOSA](https://github.com/IdentityPython/SATOSA) is a SAML/OIDC proxy that enables federated
identity scenarios — ideal for universities sharing openDesk Edu across federations (eduGAIN, DFN-AAI).

- [ ] Helm chart for SATOSA proxy
- [ ] SAML-to-OIDC translation for legacy university IdPs
- [ ] Attribute mapping (eduPerson → Keycloak claims)
- [ ] Multi-IdP routing (route users to their home institution's IdP)
- [ ] Integration with existing Keycloak broker setup

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
| **Shibboleth IdP deployment** | Universities already run their own IdP. openDesk Edu integrates as a SAML SP, not an IdP provider. SATOSA proxy (v5.0) handles SAML-to-OIDC translation for federated scenarios. |
| **Keycloak as eduGAIN IdP** | SAML federation support is incomplete. Use Shibboleth IdP for federation, Keycloak for internal IAM. |
| **Stack4Ops/public** | Evaluated and discarded — operations tooling not relevant to education integration needs |

---

## Timeline

```
2026 Q2   v1.0  Core platform + 15 education services (ILIAS, Moodle, BBB, OpenCloud, SOGo, Grommunio, TYPO3, Etherpad, BookStack, Planka, Zammad, LimeSurvey, Draw.io, Excalidraw, SSP)
            v1.1  DFN-AAI federation + semester lifecycle + logout + user provisioning/deprovisioning + own container image pipeline
2026 Q3   v1.2  Opencast + Tobira lecture recording
2026 Q4   v1.5  HISinOne/Marvin campus management integration (phase 1: identity)
2027 Q1   v1.5  HISinOne integration (phase 2: courses, phase 3: schedule/exams)
2027 Q2   v1.5  HISinOne integration (phase 4: study progress, phase 5: intelligence)
2027 Q3   v2.0  EvaP + Mahara (evaluation + portfolio)
2027 Q4   v2.1  MRBS + LEIHS (room + equipment booking)
2028 Q1   v3.0  R/exams + JPlag (digital examination)
2028 Q2   v4.0  Local LLM + xAPI analytics + F13 sovereign AI assistant
2028 Q3   v5.0  Multi-tenancy + SATOSA proxy + research data management
```

---

## Contributing

Have an idea for the roadmap? [Open an issue](https://github.com/opendesk-edu/opendesk-edu/issues) — we'd love to hear what your university needs.

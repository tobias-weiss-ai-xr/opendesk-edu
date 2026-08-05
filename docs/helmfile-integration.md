# Helmfile Integration Guide

> **Last updated:** 2026-06-03
> **Applies to:** openDesk Edu deployment repository

---

## 1. Overview

Helmfile is the deployment orchestration layer for openDesk Edu. All ~35+ services (infrastructure, groupware, learning management, scientific computing, AI, and more) are defined as **helmfile states** that reference either local Helm charts (under `helmfile/charts/`) or upstream OCI/HTTP chart repositories defined in `charts.yaml.gotmpl`.

The deployment is driven from a single entry point:

```
helmfile.yaml.gotmpl  (repository root)
```

Running `helmfile apply` (or `helmfile sync`) from the repository root evaluates all templates, resolves the ~35 release states, and applies them to the target Kubernetes cluster in the correct dependency order.

**Key design goals:**

- **Declarative:** Everything is Git-ops ready; the entire desired state is expressed in `.gotmpl` files.
- **Environment-aware:** Three built-in environments (`dev`, `test`, `prod`) overlay environment-specific overrides on top of `default/`.
- **Extensible:** Adding a new service requires ~3 files plus entries in two catalogs — no changes to the core pipeline.
- **Enterprise-ready:** CE/EE feature gates via the `OPENDESK_ENTERPRISE` environment variable.
- **Customizable:** Every release supports `customization.release.<name>` values that let operators inject additional value files without modifying the base templates.

---

## 2. Architecture

### 2.1 Template chain

The helmfile configuration is built from layered Go templates in a four-stage chain:

```
helmfile.yaml.gotmpl
    |
    v
helmfile_generic.yaml.gotmpl
    |
    v
helmfile/apps/<service>/helmfile-child.yaml.gotmpl
    |
    v
helmfile/apps/<service>/values.yaml.gotmpl   -->   Chart
```

**Stage 1 — `helmfile.yaml.gotmpl` (root entry point)**

Defines environments (`dev`, `test`, `prod`) and points each to a glob of override files:

```yaml
environments:
  dev:
    values:
      - "helmfile/environments/dev/*.yaml.gotmpl"
  test:
    values:
      - "helmfile/environments/test/*.yaml.gotmpl"
  prod:
    values:
      - "helmfile/environments/prod/*.yaml.gotmpl"

helmfiles:
  - path: "./helmfile_generic.yaml.gotmpl"
    values:
      - {{ toYaml .Values | nindent 8 }}
```

This file can also reference a remote repository (e.g. for downstream forks).

**Stage 2 — `helmfile_generic.yaml.gotmpl` (service catalog)**

Lists every service in deployment order, grouped by category. Each entry is a reference to a per-app `helmfile-child.yaml.gotmpl`. Values from the selected environment are merged and forwarded. Enterprise overrides are injected when `OPENDESK_ENTERPRISE=true`.

```
helmfiles:
  # Pre-migrations (run first)
  - path: "helmfile/apps/opendesk-migrations-pre/helmfile-child.yaml.gotmpl"
    values: &values
      - "helmfile/environments/default/*.yaml.gotmpl"
      - {{ toYaml .Values | nindent 8 }}
      {{- if eq (env "OPENDESK_ENTERPRISE") "true" }}
      - "helmfile/environments/default-enterprise-overrides/*.yaml.gotmpl"
      {{- end }}

  # Core services
  - path: "helmfile/apps/opendesk-services/helmfile-child.yaml.gotmpl"
    values: *values
  - path: "helmfile/apps/services-external/helmfile-child.yaml.gotmpl"
    values: *values
  ... (all ~35 services listed here)
```

**Stage 3 — `helmfile-child.yaml.gotmpl` (per-service release definition)**

Each service directory contains a `helmfile-child.yaml.gotmpl` that defines:

1. **Repository declarations** (for OCI/HTTP charts) including URL, GPG keyring, and auth credentials.
2. **Release definition** — chart name/version, values file references, `installed` toggle, timeout, post-renderers, and deployment ordering (`needs`, `wait`).
3. **Common labels** that tag the release with `deployStage` and `component`.

Example (etherpad):

```yaml
releases:
  - name: "etherpad"
    chart: "../../charts/etherpad"         # local chart path
    wait: true
    values:
      - "values.yaml.gotmpl"
      {{- range .Values.customization.release.etherpad }}
      - {{ . }}
      {{- end }}
    installed: {{ .Values.apps.etherpad.enabled }}
    timeout: 600

commonLabels:
  deployStage: "050-components"
  component: "etherpad"
```

For upstream charts (e.g. Ollama, Open WebUI), the chart comes from a Helm repository:

```yaml
repositories:
  - name: "ollama"
    url: "https://ollama.github.io/helm-chart"
    oci: false
releases:
  - name: "ollama"
    chart: "ollama/ollama"
    version: "0.68.0"
    values:
      - "values.yaml.gotmpl"
    installed: {{ .Values.apps.ollama.enabled }}
    timeout: 900
```

For openDesk-managed OCI charts, the repository points to the openDesk Artifactory mirror:

```yaml
repositories:
  - name: "postgresql-repo"
    keyring: "../../files/gpg-pubkeys/opencode.gpg"
    verify: {{ .Values.charts.postgresql.verify }}
    username: {{ env "OD_PRIVATE_REGISTRY_USERNAME" | quote }}
    password: {{ env "OD_PRIVATE_REGISTRY_PASSWORD" | quote }}
    oci: true
    url: "{{ coalesce .Values.repositories.helm.registryOpencodeDe .Values.global.helmRegistry | default .Values.charts.postgresql.registry }}/{{ .Values.charts.postgresql.repository }}"
```

**Stage 4 — `values.yaml.gotmpl` (per-service values template)**

Contains the concrete Helm values for the chart. Rendered values include:

- Image references (registry, repository, tag)
- Database configuration (PostgreSQL/MariaDB auth, database names)
- Ingress hostnames and annotations
- Persistence storage class and sizes
- Resource requests and limits
- Security contexts
- Service annotations
- Replica counts

Example (etherpad values.yaml.gotmpl):

```yaml
etherpad:
  image: "etherpad/etherpad"
  tag: "1.9.9"
  port: 9001

ingress:
  enabled: {{ .Values.ingress.enabled }}
  className: "haproxy"
  hosts:
    - host: "etherpad.{{ .Values.global.domain }}"
      paths:
        - path: /
          pathType: "ImplementationSpecific"

persistence:
  size: "1Gi"
  storageClass: {{ coalesce .Values.persistence.storages.etherpad.storageClassName .Values.persistence.storageClassNames.RWO | quote }}

postgresql:
  enabled: true
  auth:
    username: "etherpad"
    database: "etherpad"
```

### 2.2 Deployment ordering

The `deployStage` common label controls ordering across categories:

| Stage | Description |
|-------|-------------|
| `010-infra` | Infrastructure: Redis, PostgreSQL, MariaDB, MinIO, SeaweedFS, Ollama |
| `020-migrations-pre` | Pre-deployment database migrations |
| `030-opendesk-services` | Core platform: certificates, home page, static files, alerts, dashboards, Otterize |
| `030-services-external` | External services: Redis, PostgreSQL, MariaDB, MinIO, ClamAV, Postfix, dkimpy, Cassandra (EE) |
| `040-portal` | Identity & portal: Keycloak, Nubus (UMS), Intercom Service, SAML multidomain |
| `050-components` | Application services: all collaboration, learning, scientific computing, AI services |
| `060-post-migrations` | Post-deployment migrations |
| `070-portal-entries` | Portal entry registration |

Within the same stage, implicit ordering is achieved via `needs:` (e.g., `moodle` needs `moodle-pvc`).

### 2.3 Values merging hierarchy

Values are merged at three levels (later overrides earlier):

1. **Default environment** — `helmfile/environments/default/*.yaml.gotmpl` (loaded alphabetically)
2. **Selected environment** — `helmfile/environments/{dev,test,prod}/*.yaml.gotmpl`
3. **Customization** — `customization.release.<name>` entries (injected via `{{ .Values.customization.release... }}` in each helmfile-child)

The `a0-global.yaml.gotmpl` file (loaded first due to `a0` prefix) defines the `global:` section, including `domain`, `hosts`, and image pull configuration.

---

## 3. How to Add a New Service

Adding a service to the openDesk Edu helmfile deployment involves **8 steps**:

### 3.1 Steps

1. **Create the Helm chart** under `helmfile/charts/<service>/` (or reference an upstream chart).
2. **Create the app directory** — `helmfile/apps/<service>/`
3. **Create `helmfile-child.yaml.gotmpl`** — define the Helm release, repositories, labels.
4. **Create `values.yaml.gotmpl`** — chart-specific values (ingress, persistence, resources).
5. **Register in `charts.yaml.gotmpl`** — `helmfile/environments/default/charts.yaml.gotmpl`
6. **Register in `opendesk_main.yaml.gotmpl`** — `helmfile/environments/default/opendesk_main.yaml.gotmpl` (add `enabled` flag)
7. **Add to `helmfile_generic.yaml.gotmpl`** — insert the helmfile-child path in the correct category section.
8. **Add persistence defaults** (optional) — `helmfile/environments/default/persistence.yaml.gotmpl`
9. **Add ingress body size/timeout** (optional) — `helmfile/environments/default/ingress.yaml.gotmpl`

### 3.2 Example: Adding "snipr" (lecture recording)

**Step 1 — Local chart already exists** at `helmfile/charts/snipr/`.

**Step 2 — App directory** `helmfile/apps/snipr/`.

**Step 3 — `helmfile-child.yaml.gotmpl`:**

```yaml
releases:
  - name: snipr
    chart: ../../charts/snipr
    wait: true
    values:
      - "values.yaml.gotmpl"
      {{- range .Values.customization.release.snipr }}
      - {{ . }}
      {{- end }}
    installed: {{ .Values.apps.snipr.enabled }}
    timeout: 600

commonLabels:
  deployStage: "050-components"
  component: "snipr"
```

**Step 4 — `values.yaml.gotmpl`:** Defines image, ingress, persistence, resources, SSO client ID, LTI config.

**Step 5 — `charts.yaml.gotmpl`:**

```yaml
  snipr:
    # providerCategory: "Community"
    # providerResponsible: "openDesk Edu"
    # upstreamRegistry: "file://"
    # upstreamRepository: "snipr"
    registry: "file://"
    repository: "../../charts/snipr"
    name: "snipr"
    version: "1.0.0"
    verify: false
```

**Step 6 — `opendesk_main.yaml.gotmpl`:**

```yaml
  snipr:
    enabled: true
    namespace: ~
```

**Step 7 — `helmfile_generic.yaml.gotmpl`** (insert in the appropriate category):

```yaml
  ## Lecture Recording
  - path: "helmfile/apps/snipr/helmfile-child.yaml.gotmpl"
    values: *values
```

### 3.3 Service enabling/disabling

Each service respects an `enabled` toggle. Set `apps.<name>.enabled: false` in any environment override to skip deployment:

```yaml
apps:
  sogo:
    enabled: false
  etherpad:
    enabled: true
```

---

## 4. Service Categories

Services are organized by functional category in `helmfile_generic.yaml.gotmpl`:

### Core Platform

Foundational infrastructure: certificates, static files, home page, Prometheus alerts/ dashboards, network policies (Otterize).

### External/Infrastructure Services

Databases (PostgreSQL, MariaDB, Redis, Memcached, Cassandra*), object storage (MinIO), mail infrastructure (Postfix, Dovecot, dkimpy-milter), antivirus (ClamAV).

### Identity & Portal

The **Nubus** (Univention Management Stack) umbrella chart: LDAP server, Keycloak SSO, Portal (frontend + consumer), Intercom Service, portal entry registration, SAML multidomain.

### Groupware & Communication

- **OX App Suite** (Open-Xchange) — email, calendar, contacts, tasks (CE + EE)
- **SOGo** — lightweight groupware alternative
- **grommunio** — Grommunio groupware (optional, replaces OX/SOGo)
- **Element** — Matrix chat client
- **Synapse** — Matrix homeserver
- **Jitsi** — Video conferencing

### Storage & Files

- **Nextcloud** — File sync & share, with management and notify-push sub-charts
- **openCloud** — openCloud file sync (CE + EE)
- **SeaweedFS** — Distributed file storage (edu-specific)

### Office & Collaboration

- **Collabora Online** — Online document editing (CE + EE)
- **Cryptpad** — End-to-end encrypted collaborative pads
- **Notes** (Impress) — Collaborative notes
- **XWiki** — Enterprise wiki platform
- **Element Matrix widgets** — Neoboard, Neochoice, Neodatefix

### Documentation & Knowledge

- **BookStack** — Documentation/wiki platform
- **draw.io** — Diagramming tool
- **Excalidraw** — Virtual whiteboard
- **TYPO3** — Enterprise CMS

### Project Management & Helpdesk

- **OpenProject** — Project management
- **Planka** — Kanban boards
- **Zammad** — Helpdesk/ticketing system

### Learning & Research (LMS)

- **Moodle** — Learning management system
- **ILIAS** — Learning management system (Shibboleth-ready)
- **LimeSurvey** — Online survey tool
- **Snipr** — Lecture recording with LTI 1.3 integration

### Scientific Computing

- **JupyterHub** — Jupyter notebooks for teaching/research
- **RStudio** — R environment
- **Code-Server** (coder) — VS Code in the browser
- **Dask Gateway** — Distributed computing
- **KasmVNC** — Containerized desktop environments
- **Overleaf** — Collaborative LaTeX editor

### AI & LLM Tools

- **Ollama** — Local LLM inference server
- **Open WebUI** — Chat interface for Ollama

### Real-time Communication & Low-code

- **Etherpad** — Real-time collaborative text editing
- **n8n** — Workflow automation / low-code

### Web Terminals & Presentation

- **ttyd** — Web-based terminal
- **Slidev** — Presentation slides from Markdown

### Dashboard & Self-service

- **Collab Dashboard** — Unified dashboard for collaborative tools
- **Self-Service Password** — LDAP password self-service
- **Portal Entries** — Auto-registration of services in the portal
- **OpenProject Bootstrap** — OpenProject initial setup job

### Semester Lifecycle (edu-specific)

- **Semester Provisioning** — Automated semester lifecycle management
- **Migrations (pre/post)** — Database migration jobs

---

## 5. Component Reference Table

### 5.1 Core Platform & Infrastructure

| Service | Chart Source | Chart Name | Port | Storage | SSO | deployStage |
|---------|-------------|------------|------|---------|-----|-------------|
| certificates | OCI: opendesk-certificates | opendesk-certificates | — | — | — | 030-opendesk-services |
| home | OCI: opendesk-home | opendesk-home | 8080 | — | — | 030-opendesk-services |
| static-files | OCI: opendesk-static-files | opendesk-static-files | 8080 | — | — | 030-opendesk-services |
| alerts | OCI: opendesk-alerts | opendesk-alerts | — | — | — | 030-opendesk-services |
| dashboards | OCI: opendesk-dashboards | opendesk-dashboards | — | — | — | 030-opendesk-services |
| otterize | OCI: opendesk-otterize | opendesk-otterize | — | — | — | 030-opendesk-services |

### 5.2 External/Infrastructure Services

| Service | Chart Source | Chart Name | Port | Storage | SSO | deployStage |
|---------|-------------|------------|------|---------|-----|-------------|
| redis | OCI: Bitnami (mirror) | redis | 6379 | 1Gi | — | 030-services-external |
| memcached | OCI: Bitnami (mirror) | memcached | 11211 | — | — | 030-services-external |
| postgresql | OCI: opendesk-postgresql | postgresql | 5432 | 1Gi | — | 030-services-external |
| mariadb | OCI: opendesk-mariadb | mariadb | 3306 | 1Gi | — | 030-services-external |
| minio | OCI: Bitnami (mirror) | minio | 9000/9001 | 10Gi | — | 030-services-external |
| postfix | OCI: opendesk-postfix | postfix | 25 | 1Gi | — | 030-services-external |
| dovecot | OCI: opendesk-dovecot | dovecot | — | 1Gi | — | 030-services-external |
| dkimpy-milter | OCI: opendesk-dkimpy | opendesk-dkimpy-milter | 8891 | — | — | 030-services-external |
| clamav (distributed) | OCI: opendesk-clamav | opendesk-clamav | 3310 | 1Gi | — | 030-services-external |
| clamav-simple | OCI: opendesk-clamav | clamav-simple | 3310 | — | — | 030-services-external |
| cassandra (EE) | OCI: Bitnami (mirror) | cassandra | 9042 | 1Gi | — | 030-services-external |
| seaweedfs | Local: ../../charts/seaweedfs | seaweedfs | 8333 | variable | — | 010-infra |

### 5.3 Identity & Portal

| Service | Chart Source | Chart Name | Port | Storage | SSO | deployStage |
|---------|-------------|------------|------|---------|-----|-------------|
| nubus (UMS) | OCI: Univention (mirror) | nubus | 443/8080 | 1Gi+ | OIDC | 040-portal |
| intercom-service | OCI: Univention (mirror) | intercom-service | 8443 | — | OIDC | 040-portal |
| keycloak-bootstrap | OCI: opendesk-keycloak-bootstrap | opendesk-keycloak-bootstrap | — | — | — | 040-portal |
| portal-entries | Local: ../../charts/portal-entries | portal-entries | — | — | — | 070-portal-entries |
| saml-multidomain | OCI: Univention (mirror) | saml-multidomain | — | — | SAML | 040-portal |

### 5.4 Groupware & Communication

| Service | Chart Source | Chart Name | Port | Storage | SSO | deployStage |
|---------|-------------|------------|------|---------|-----|-------------|
| ox-appsuite | OCI: Open-Xchange (mirror) | appsuite-public-sector | 8080 | — | OIDC | 050-components |
| ox-connector | OCI: Univention (mirror) | ox-connector | — | 1Gi | — | 050-components |
| ox-bootstrap | OCI: opendesk-open-xchange-bootstrap | opendesk-open-xchange-bootstrap | — | — | — | 050-components |
| sogo | Local: ../../charts/sogo | sogo | 80/20000 | — | OIDC | 050-components |
| grommunio | Local chart | grommunio | 443 | — | OIDC | 050-components |
| element | OCI: opendesk-element | opendesk-element | 8080 | — | OIDC | 050-components |
| synapse | OCI: opendesk-element | opendesk-synapse | 8008 | 1Gi | OIDC | 050-components |
| synapse-web | OCI: opendesk-element | opendesk-synapse-web | 8080 | — | — | 050-components |
| synapse-admin | OCI: opendesk-element | opendesk-synapse-admin (EE) | 8080 | — | OIDC | 050-components |
| synapse-create-account | OCI: opendesk-element | opendesk-synapse-create-account | 8080 | — | — | 050-components |
| jitsi | OCI: opendesk-jitsi | opendesk-jitsi | 8443 | 1Gi (prosody) | OIDC | 050-components |
| matrix-neoboard-widget | OCI: opendesk-matrix-widgets | matrix-neoboard-widget | 8080 | — | — | 050-components |
| matrix-neochoice-widget | OCI: opendesk-matrix-widgets | matrix-neochoice-widget | 8080 | — | — | 050-components |
| matrix-neodatefix-bot | OCI: opendesk-matrix-widgets | matrix-neodatefix-bot | — | 1Gi | — | 050-components |
| matrix-neodatefix-widget | OCI: opendesk-matrix-widgets | matrix-neodatefix-widget | 8080 | — | — | 050-components |
| matrix-user-verification | OCI: opendesk-element | opendesk-matrix-user-verification-service | 8080 | — | — | 050-components |

### 5.5 Storage & Files

| Service | Chart Source | Chart Name | Port | Storage | SSO | deployStage |
|---------|-------------|------------|------|---------|-----|-------------|
| nextcloud | OCI: opendesk-nextcloud | opendesk-nextcloud | 8080 | — | OIDC | 050-components |
| nextcloud-management | OCI: opendesk-nextcloud | opendesk-nextcloud-management | — | — | — | 050-components |
| nextcloud-notifypush | OCI: opendesk-nextcloud | opendesk-nextcloud-notifypush | — | — | — | 050-components |
| opencloud | OCI: opendesk-opencloud | opencloud | 8080 | — | OIDC | 050-components |
| opencloud-sidecar | OCI: opendesk-opencloud-sidecar | opencloud-sidecar | — | — | — | 050-components |

### 5.6 Office & Collaboration

| Service | Chart Source | Chart Name | Port | Storage | SSO | deployStage |
|---------|-------------|------------|------|---------|-----|-------------|
| collabora-online | OCI: Collabora (mirror) | collabora-online | 9980 | — | — | 050-components |
| collabora-controller (EE) | OCI: Collabora (mirror) | cool-controller | 9980 | — | — | 050-components |
| cryptpad | OCI: XWiki (mirror) | cryptpad | 3000 | — | OIDC | 050-components |
| notes (impress) | OCI: opendesk-impress | impress | 8080 | — | OIDC | 050-components |
| notes-customization | OCI: opendesk-impress-customization | impress-customization | — | — | — | 050-components |
| xwiki | OCI: XWiki (mirror) | xwiki | 8080 | 1Gi | OIDC | 050-components |

### 5.7 Documentation & Knowledge

| Service | Chart Source | Chart Name | Port | Storage | SSO | deployStage |
|---------|-------------|------------|------|---------|-----|-------------|
| bookstack | Local: ../../charts/bookstack | bookstack | 8080 | — | OIDC | 050-components |
| drawio | Local: ../../charts/drawio | drawio | 8080 | — | — | 050-components |
| excalidraw | Local: ../../charts/excalidraw | excalidraw | 80 | — | — | 050-components |
| typo3 | Local: ../../charts/typo3 | typo3 | 8080 | 5Gi (fileadmin) + 1Gi (var) | SAML | 050-components |

### 5.8 Project Management & Helpdesk

| Service | Chart Source | Chart Name | Port | Storage | SSO | deployStage |
|---------|-------------|------------|------|---------|-----|-------------|
| openproject | OCI: OpenProject (mirror) | openproject | 8080 | 5Gi (tmp) | OIDC | 050-components |
| openproject-bootstrap | OCI: opendesk-openproject-bootstrap | opendesk-openproject-bootstrap | — | — | — | 060-post-migrations |
| planka | Local: ../../charts/planka | planka | 1337 | — | OIDC | 050-components |
| zammad | Local: ../../charts/zammad | zammad | 8080 | — | OIDC | 050-components |

### 5.9 Learning & Research (LMS)

| Service | Chart Source | Chart Name | Port | Storage | SSO | deployStage |
|---------|-------------|------------|------|---------|-----|-------------|
| moodle | Local: ../../charts/moodle | moodle | 8080 | — | SAML | 050-components |
| ilias | Local: ../../charts/ilias | ilias | 8080 | — | SAML/Shibboleth | 050-components |
| limesurvey | Local: ../../charts/limesurvey | limesurvey | 8080 | — | OIDC | 050-components |
| snipr | Local: ../../charts/snipr | snipr | 8080 | — | OIDC/LTI 1.3 | 050-components |

### 5.10 Scientific Computing

| Service | Chart Source | Chart Name | Port | Storage | SSO | deployStage |
|---------|-------------|------------|------|---------|-----|-------------|
| jupyterhub | HTTP: hub.jupyter.org | jupyterhub | 8080 | — | OIDC | 050-components |
| rstudio | Local: ../../charts/rstudio | rstudio | 8787 | — | OIDC | 050-components |
| code-server (coder) | HTTP: helm.coder.com | coder | 8080 | — | OIDC | 050-components |
| dask-gateway | HTTP: helm.dask.org | dask-gateway | 8000 | — | OIDC | 050-components |
| kasmvnc | Local: ../../charts/kasmvnc | kasmvnc | 443 | — | OIDC | 050-components |
| overleaf | OCI: ghcr.io/sharelatex | overleaf | 80 | — | OIDC | 050-components |

### 5.11 AI & LLM Tools

| Service | Chart Source | Chart Name | Port | Storage | SSO | deployStage |
|---------|-------------|------------|------|---------|-----|-------------|
| ollama | HTTP: ollama.github.io | ollama | 11434 | GPU optional | — | 010-infra |
| open-webui | HTTP: helm.openwebui.com | open-webui | 8080 | — | OIDC | 050-components |

### 5.12 Real-time & Low-code

| Service | Chart Source | Chart Name | Port | Storage | SSO | deployStage |
|---------|-------------|------------|------|---------|-----|-------------|
| etherpad | Local: ../../charts/etherpad | etherpad | 9001 | 1Gi | OIDC | 050-components |
| n8n | Local: ../../charts/n8n | n8n | 5678 | — | OIDC | 050-components |

### 5.13 Web Terminals & Presentation

| Service | Chart Source | Chart Name | Port | Storage | SSO | deployStage |
|---------|-------------|------------|------|---------|-----|-------------|
| ttyd | Local: ../../charts/ttyd | ttyd | 7681 | — | OIDC | 050-components |
| slidev | Local: ../../charts/slidev | slidev | 3030 | — | OIDC | 050-components |

### 5.14 Dashboard & Self-service

| Service | Chart Source | Chart Name | Port | Storage | SSO | deployStage |
|---------|-------------|------------|------|---------|-----|-------------|
| collab-dashboard | Local: ../../charts/collab-dashboard | collab-dashboard | 8080 | — | OIDC | 050-components |
| self-service-password | Local: ../../charts/self-service-password | self-service-password | 80 | — | — | 050-components |

### 5.15 Semester Lifecycle

| Service | Chart Source | Chart Name | Port | Storage | SSO | deployStage |
|---------|-------------|------------|------|---------|-----|-------------|
| semester-provisioning | Local: ../../charts/semester-provisioning | semester-provisioning | — | — | — | 050-components |
| opendesk-migrations-pre | OCI: opendesk-migrations | opendesk-migrations | — | — | — | 020-migrations-pre |
| opendesk-migrations-post | OCI: opendesk-migrations | opendesk-migrations | — | — | — | 060-post-migrations |

---

## 6. Environment Configuration

Three environments are defined in `helmfile.yaml.gotmpl`:

```
environments:
  dev:      helmfile/environments/dev/*.yaml.gotmpl
  test:     helmfile/environments/test/*.yaml.gotmpl
  prod:     helmfile/environments/prod/*.yaml.gotmpl
```

### 6.1 Default environment (`helmfile/environments/default/`)

This is the base configuration that all environments inherit. Key files:

| File | Purpose |
|------|---------|
| `a0-global.yaml.gotmpl` | Global domain, hosts map, image pull policy, grommunio toggle, backchannel logout |
| `opendesk_main.yaml.gotmpl` | Master `apps:` enable/disable flags for every service |
| `charts.yaml.gotmpl` | Central catalog of all Helm charts with registry, repository, name, version, GPG verification |
| `images.yaml.gotmpl` | Container image tags for all services |
| `secrets.yaml.gotmpl` | Secret value definitions (passwords, tokens, keys) |
| `functional.yaml.gotmpl` | Functional feature flags (admin logging, 2FA groups, OIDC clients, SSO federation, realm settings) |
| `persistence.yaml.gotmpl` | Default storage sizes and storage class per component |
| `resources.yaml.gotmpl` | CPU/memory requests and limits per component |
| `replicas.yaml.gotmpl` | Default replica counts per component |
| `ingress.yaml.gotmpl` | Ingress class name, body size/timeout limits, TLS config |
| `repositories.yaml.gotmpl` | Fine-grained registry settings, ClamAV mirror URLs |
| `annotations.yaml.gotmpl` | Common annotations for ingresses, services, service accounts |
| `_helper.yaml.gotmpl` | Internal helper values (LDAP host, base DN, realm name) |

### 6.2 Dev environment

Files: `helmfile/environments/dev/values.yaml.gotmpl`, `annotations.yaml.gotmpl`, `ingress.yaml.gotmpl`, `persistence.yaml.gotmpl`, `replicas.yaml.gotmpl`

Used for local development (e.g. minikube, kind). Typically disables resource-intensive services. Example overrides:

```yaml
apps:
  openproject:
    enabled: false
  nextcloud:
    enabled: false
```

### 6.3 Test environment

File: `helmfile/environments/test/values.yaml.gotmpl`

Used for CI/testing. Disables most openDesk services and enables collab-services (scientific computing) for integration tests:

```yaml
global:
  domain: "opendesk.hrz.uni-marburg.de"
apps:
  # Core openDesk disabled
  nubus:    { enabled: false }
  nextcloud: { enabled: false }
  # ... most apps false
  # Edu services phased in
  drawio:   { enabled: true }
  planka:   { enabled: true }
  etherpad: { enabled: true }
  # Collab services
  jupyterhub: { enabled: true }
  ollama:   { enabled: true }
  openWebui: { enabled: true }
  rstudio:  { enabled: true }
```

### 6.4 Prod environment

File: `helmfile/environments/prod/values.yaml.gotmpl`

Full production configuration with all services enabled. Multi-domain support:

```yaml
global:
  domain: "opendesk-edu.org"
apps:
  sogo:         { enabled: true }
  nubus:        { enabled: true }
  openproject:  { enabled: true }
  # ... all services enabled
namespace: "opendesk-edu"
```

### 6.5 Enterprise overrides

When `OPENDESK_ENTERPRISE=true`, additional values files from `helmfile/environments/default-enterprise-overrides/*.yaml.gotmpl` are injected automatically. Enterprise-specific components (Collabora Controller, Cassandra, Synapse Admin, Groupsync) are gated:

```yaml
apps:
  collaboraController:
    enabled: {{ if eq (env "OPENDESK_ENTERPRISE") "true" }}true{{ else }}false{{ end }}
  cassandra:
    enabled: {{ if eq (env "OPENDESK_ENTERPRISE") "true" }}true{{ else }}false{{ end }}
```

---

## 7. Known Issues and Workarounds

### 7.1 DNS CNAME / Certificate validation

**Issue:** Some pods use internal DNS names (e.g. `sogo.opendesk-edu.org`) for service discovery. If the external DNS is a CNAME pointing to the cluster, certificate generation may fail or services may be unreachable.

**Workaround:** Ensure the ingress controller is configured with the correct hostname and that TLS certificates (either via cert-manager or pre-provisioned `opendesk-certificates-tls` secret) cover all service hostnames defined in `global.hosts`. Use the `opendesk-certificates` chart to auto-generate self-signed certificates if no public CA is available.

### 7.2 HAProxy ingress proxy body size

**Issue:** Default HAProxy ingress limits may reject large uploads (e.g., files > 1MB to Nextcloud, Collabora documents).

**Workaround:** Body sizes are configured in `helmfile/environments/default/ingress.yaml.gotmpl`. Increase as needed:

```yaml
ingress:
  parameters:
    bodySize:
      nextcloud: "100M"
      collabora: "100M"
      objectstorage: "4G"
```

Timeout settings are also available for long-lived connections (Jitsi, Collabora).

### 7.3 Image pulling from private registries

**Issue:** Many charts reference images at `registry.opencode.de` which requires authentication.

**Workaround:** Set the following environment variables before running helmfile:

```bash
export OD_PRIVATE_REGISTRY_USERNAME="<your-username>"
export OD_PRIVATE_REGISTRY_PASSWORD="<your-password>"
# For enterprise-only images:
export OD_ENTERPRISE_PRIVATE_REGISTRY_USERNAME="..."
export OD_ENTERPRISE_PRIVATE_REGISTRY_PASSWORD="..."
```

These are consumed in every `helmfile-child.yaml.gotmpl` that defines an OCI repository. Additionally, `global.imagePullSecrets` can be set in the environment values to configure Kubernetes image pull secrets.

### 7.4 Bitnami chart version drift

**Issue:** Bitnami charts (Redis, Memcached, MinIO, Cassandra) are mirrored to `registry.opencode.de` from Docker Hub. The mirrored versions may lag behind upstream. Renovate bot auto-updates the tag, but the mirror may not have the new tag available immediately.

**Workaround:** Pin chart versions in `charts.yaml.gotmpl` to a known-good mirrored version. Check the mirror status at the openDesk GitLab mirror project before bumping versions. The mirror runs hourly at 42 minutes past the hour.

```yaml
  redis:
    registry: "registry.opencode.de"
    repository: "bmi/opendesk/components/external/charts/bitnami-charts"
    name: "redis"
    version: "18.6.1"   # pin to mirrored version
    verify: true
```

### 7.5 Ephemeral volumes / PVC issues

**Issue:** Some services use ephemeral storage or PVCs with `ReadWriteMany` access mode. If the cluster does not have a default `RWX` StorageClass or the provisioner does not support it, pods will fail to start.

**Workaround:** Set `persistence.storageClassNames.RWX` in the environment values to a supported RWX StorageClass (e.g., `nfs-client`, `longhorn`, `rook-cephfs`). For services with specific storage needs, set per-component storage classes in `persistence.storages.<component>.storageClassName`:

```yaml
persistence:
  storageClassNames:
    RWX: "nfs-client"
    RWO: "standard"
  storages:
    etherpad:
      storageClassName: "nfs-client"
```

### 7.6 Long pod startup times / timeouts

**Issue:** Some services (OpenProject, Jitsi, BigBlueButton) take 10+ minutes to start. The default helmfile timeout may be too short.

**Workaround:** Each `helmfile-child.yaml.gotmpl` sets a `timeout:` value per release. Defaults range from 600s (10 min) to 1800s (30 min). For particularly slow services, increase the timeout:

```yaml
releases:
  - name: "bigbluebutton"
    timeout: 1800   # 30 minutes
```

### 7.7 SOGo Apache proxy configuration

**Issue:** SOGo's architecture requires Apache as a reverse proxy. The SOGo WOHttpAdaptor listens on `127.0.0.1:20000` (internal only). Apache must bind to port 80 and proxy requests to SOGo. If the Apache ConfigMap is stale or corrupted, Apache fails to start with `AH00111: DefaultRuntimeDir` errors.

**Workaround:** Delete the stale ConfigMap and redeploy:

```bash
kubectl -n opendesk-edu delete configmap sogo-sogo-entrypoint
helmfile -e prod apply --selector name=sogo
```

### 7.8 Portal consumer init crash-loop (MinIO credentials mismatch)

**Issue:** The `ums-portal-consumer` pod may enter `Init:CrashLoopBackOff` because the portal consumer secret contains invalid MinIO credentials.

**Workaround:** Copy valid credentials from the working portal server secret:

```bash
ACCESS_KEY=$(kubectl -n opendesk-edu get secret ums-portal-server-object-storage \
  -o jsonpath='{.data.AWS_ACCESS_KEY_ID}' | base64 -d)
SECRET_KEY=$(kubectl -n opendesk-edu get secret ums-portal-server-object-storage \
  -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}' | base64 -d)
kubectl -n opendesk-edu create secret generic ums-portal-consumer-object-storage \
  --from-literal=AWS_ACCESS_KEY_ID="$ACCESS_KEY" \
  --from-literal=AWS_SECRET_ACCESS_KEY="$SECRET_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n opendesk-edu delete pod ums-portal-consumer-0
```

### 7.9 Renovate bot merge conflicts

**Issue:** Renovate auto-updates tags in `charts.yaml.gotmpl` and `images.yaml.gotmpl`. If both the bot and a developer modify the same file, merge conflicts can occur.

**Workaround:** The linting step in CI ensures alphabetical ordering. When resolving conflicts, run the openDesk CI CLI tool locally to re-sort:

```bash
opendesk-ci-cli sort-yaml helmfile/environments/default/charts.yaml.gotmpl
opendesk-ci-cli sort-yaml helmfile/environments/default/images.yaml.gotmpl
```

### 7.10 GPG key verification failures

**Issue:** OCI chart verification may fail if the GPG public key in `helmfile/files/gpg-pubkeys/` is outdated or missing.

**Workaround:** Place GPG public keys in binary format in `helmfile/files/gpg-pubkeys/` and reference them in the respective `helmfile-child.yaml.gotmpl`:

```yaml
repositories:
  - name: "open-xchange-repo"
    keyring: "../../files/gpg-pubkeys/open-xchange-com.gpg"
    verify: true
```

Set `verify: false` for local/unverified charts when testing.

---

## 8. Deployment Checklist (Starting from Scratch)

### 8.1 Prerequisites

- [ ] **Kubernetes cluster** (K3s, K8s, or OKD) v1.26+ with default StorageClass
- [ ] **Helm** v3.12+ installed locally
- [ ] **Helmfile** v0.160+ installed locally
- [ ] **kubectl** configured with cluster admin context
- [ ] **Ingress controller** (HAProxy or NGINX) installed and functional
- [ ] **Optional:** cert-manager for automatic TLS certificates
- [ ] **Optional:** RWX StorageClass (NFS, Longhorn, Rook Ceph) for multi-pod services

### 8.2 Environment setup

- [ ] Clone the repository:
  ```bash
  git clone <repo-url> /path/to/opendesk-edu
  cd /path/to/opendesk-edu
  ```
- [ ] Choose environment: `dev`, `test`, or `prod`
- [ ] Set environment variables (create a `.env` file):
  ```bash
  export DOMAIN="opendesk.example.com"
  export MAIL_DOMAIN="mail.example.com"
  export OD_PRIVATE_REGISTRY_USERNAME="user"
  export OD_PRIVATE_REGISTRY_PASSWORD="pass"
  export OPENDESK_ENTERPRISE="false"  # or "true"
  # Optional overrides:
  export PRIVATE_HELM_REGISTRY_URL=""
  export PRIVATE_IMAGE_REGISTRY_URL=""
  ```
- [ ] Create environment override file (if using custom env):
  ```bash
  mkdir -p helmfile/environments/mycustom
  cp helmfile/environments/test/values.yaml.gotmpl helmfile/environments/mycustom/
  # Edit to match your domain and service enablement
  ```

### 8.3 Pre-deployment checks

- [ ] Verify cluster access:
  ```bash
  kubectl cluster-info
  kubectl get nodes
  kubectl get storageclass
  ```
- [ ] Verify ingress controller is running:
  ```bash
  kubectl get pods -n ingress-nginx  # or ingress-haproxy
  ```
- [ ] Verify RWX StorageClass exists (for multi-replica services):
  ```bash
  kubectl get storageclass | grep RWX
  ```
- [ ] Review default persistence settings in `helmfile/environments/default/persistence.yaml.gotmpl` and adjust storage class names.
- [ ] Review `helmfile/environments/default/secrets.yaml.gotmpl` and ensure passwords/secrets are set appropriately for production.

### 8.4 Deployment sequence

**Phase 1 — Core infrastructure** (deployStage: 010-infra, 030-services-external):
```bash
helmfile -e <env> apply --selector deployStage=010-infra
helmfile -e <env> apply --selector deployStage=030-services-external
```

**Phase 2 — Platform services** (deployStage: 030-opendesk-services):
```bash
helmfile -e <env> apply --selector deployStage=030-opendesk-services
```

**Phase 3 — Pre-migrations** (deployStage: 020-migrations-pre):
```bash
helmfile -e <env> apply --selector deployStage=020-migrations-pre
```

**Phase 4 — Portal & identity** (deployStage: 040-portal):
```bash
helmfile -e <env> apply --selector deployStage=040-portal
```

**Phase 5 — Application components** (deployStage: 050-components):
```bash
helmfile -e <env> apply --selector deployStage=050-components
```

**Phase 6 — Post-migrations** (deployStage: 060-post-migrations):
```bash
helmfile -e <env> apply --selector deployStage=060-post-migrations
```

**Phase 7 — Portal entries** (deployStage: 070-portal-entries):
```bash
helmfile -e <env> apply --selector deployStage=070-portal-entries
```

**Alternative — Full deploy in one command:**
```bash
helmfile -e <env> apply
```

### 8.5 Post-deployment verification

- [ ] Check all pods are running:
  ```bash
  kubectl -n opendesk-edu get pods
  ```
- [ ] Check for crash-looping pods:
  ```bash
  kubectl -n opendesk-edu get pods | grep -E 'CrashLoop|Error|Init:'
  ```
- [ ] Verify ingress is configured:
  ```bash
  kubectl -n opendesk-edu get ingress
  ```
- [ ] Test external access to portal:
  ```bash
  curl -k https://portal.<your-domain>/
  ```
- [ ] Test SSO login (redirects to Keycloak):
  ```bash
  curl -k -L https://portal.<your-domain>/  # should redirect to Keycloak login
  ```
- [ ] Verify database pods are accepting connections (if using external DBs).
- [ ] Run smoke tests:
  ```bash
  helmfile -e <env> apply --selector app=smoke-tests  # if available
  ```
- [ ] Check logs for any errors:
  ```bash
  kubectl -n opendesk-edu logs --tail=50 -l app.kubernetes.io/instance=<service>
  ```

### 8.6 Ongoing operations

- [ ] **Upgrades:** Run `helmfile -e <env> apply` to sync any changes from Git.
- [ ] **Diff before apply:** Use `helmfile -e <env> diff` to review changes.
- [ ] **Selective updates:** Use `--selector` to target specific services:
  ```bash
  helmfile -e prod apply --selector name=etherpad
  ```
- [ ] **Secrets rotation:** Update `secrets.yaml.gotmpl` and re-run helmfile.
- [ ] **Monitoring:** Deploy Prometheus/Grafana dashboards (opendesk-dashboards chart).
- [ ] **Backups:** Implement etcd snapshots and database dumps as per `BACKUP_AND_DR.md`.

---

## Appendix A: Directory Map

```
opendesk-edu/
  helmfile.yaml.gotmpl                      # Root entry point (environments -> helmfile_generic)
  helmfile_generic.yaml.gotmpl              # Service catalog (all ~35+ services in order)

  helmfile/
    environments/
      default/                              # Base configuration (loaded first)
        a0-global.yaml.gotmpl               #   Global domain, hosts map
        opendesk_main.yaml.gotmpl           #   Master app enable/disable
        charts.yaml.gotmpl                  #   Chart catalog (~80 charts)
        images.yaml.gotmpl                  #   Image tags
        secrets.yaml.gotmpl                 #   Secrets/credentials
        functional.yaml.gotmpl              #   Feature flags
        persistence.yaml.gotmpl             #   Storage defaults
        resources.yaml.gotmpl               #   Resource limits
        replicas.yaml.gotmpl                #   Replica counts
        ingress.yaml.gotmpl                 #   Ingress config
        repositories.yaml.gotmpl            #   Registry settings
        annotations.yaml.gotmpl             #   Common annotations
        customization.yaml.gotmpl           #   Customization hooks
        ... (40+ files)
      default-enterprise-overrides/         # Enterprise-specific value overrides
      dev/                                  # Dev environment overrides
      test/                                 # Test environment overrides
      prod/                                 # Production environment overrides

    apps/                                   # Per-service release definitions
      <service>/
        helmfile-child.yaml.gotmpl          #   Release definition
        values.yaml.gotmpl                  #   Chart values template
        ... (additional .gotmpl value files)

    charts/                                 # Local Helm charts (vendored)
      <service>/
        Chart.yaml
        templates/
        values.yaml
        ...

    bases/                                  # Helmfile base templates (if any)
    files/                                  # GPG keys, theme files, Cosign keys
    ingress-fixes/                          # Ingress patch templates
    shared/                                 # Shared template helpers
```

## Appendix B: Key Environment Variables

| Variable | Purpose | Required |
|----------|---------|----------|
| `DOMAIN` | Primary deployment domain | Yes |
| `MAIL_DOMAIN` | Mail domain (if different from `DOMAIN`) | No |
| `MATRIX_DOMAIN` | Matrix domain (if different from `DOMAIN`) | No |
| `OD_PRIVATE_REGISTRY_USERNAME` | openCode registry username | Yes (OCI charts) |
| `OD_PRIVATE_REGISTRY_PASSWORD` | openCode registry password | Yes (OCI charts) |
| `OD_ENTERPRISE_PRIVATE_REGISTRY_USERNAME` | Enterprise registry username | EP only |
| `OD_ENTERPRISE_PRIVATE_REGISTRY_PASSWORD` | Enterprise registry password | EP only |
| `OPENDESK_ENTERPRISE` | Set to `"true"` to enable EE features | No (default: false) |
| `PRIVATE_HELM_REGISTRY_URL` | Override Helm registry URL | No |
| `PRIVATE_IMAGE_REGISTRY_URL` | Override image registry URL | No |
| `OPENDESK_1_12_0_SKIP_PVC_MIGRATION` | Skip PVC migration post-renderer | No |

## Appendix C: Useful helmfile commands

```bash
# Full diff
helmfile -e prod diff

# Selective diff
helmfile -e prod diff --selector name=etherpad

# Apply all
helmfile -e prod apply

# Apply with selector (deployStage or component)
helmfile -e prod apply --selector deployStage=050-components
helmfile -e prod apply --selector component=etherpad

# Apply single release by name
helmfile -e prod apply --selector name=etherpad

# Destroy (caution!)
helmfile -e prod destroy

# List all releases
helmfile -e prod list

# Build and show rendered output (debug)
helmfile -e prod build
```

---

> **Note:** Documentation references openDesk upstream conventions. For fork-specific workflows, see `docs/developer/development.md` and `CONTRIBUTING.md`.

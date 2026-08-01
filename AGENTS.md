# PROJECT KNOWLEDGE BASE

**Last updated:** 2026-06-24
**Repository:** openDesk HRZ Monorepo

This file is loaded automatically when Hermes Agent works in this directory.
It gives AI agents the complete picture: structure, commands, conventions, and
environment context for all sub-projects.

---

## OVERVIEW

Multi-repository monorepo combining:
1. **openDesk CE** platform deployment (helmfile-based Kubernetes)
2. **openDesk Edu** — CE + 25 education & research services
3. **openDesk SME** — small/medium enterprise variant
4. **openDesk Sec** — security-hardened variant + pentest reports
5. **openDesk Compose** — Docker Compose alternative
6. **k8up** — Kubernetes backup operator (Go, upstream fork)
7. **user_import** — User data provisioning tools (Python)
8. **Patched upstream Helm charts** (charts-upgrade-v1.12.0)
9. **Addon: OX↔Nextcloud Integration** (Java)
10. **opendesk-edu-website** (Next.js marketing site)

Hosted by **HRZ Marburg** — Debian 12, K3s v1.32.3, 9 nodes, Ceph CSI storage.

---

### Credentials & Access (Agent Memory)

Stored in Neo4j agent-memory database (`bolt://localhost:17687`, db `neo4j`) and documented here:

| System | User/Key | Auth Method | Details |
|--------|----------|-------------|---------|
| GitHub | `tobias-weiss-ai-xr` | gh CLI OAuth token | Scopes: gist, read:org, repo |
| Codeberg | `graphwiz-ai` | SSH key + API token | Token: stored in Neo4j agent-memory |
| Codeberg SSH | `id_ed25519_git` | SSH key "work" | `~/.ssh/id_ed25519_git` |
| Neo4j (agent-memory) | `neo4j` / `changeme123` | Password auth | Docker: `rt_commenter_neo4j`, Bolt:17687, HTTP:17474 |
| Litellm (local) | `sk-1234` | API key | `http://localhost:4000/v1` |
| OpenAI proxy (local) | `sk-mock` | API key | `http://localhost:18765/v1` |

---

### Etherpad Chart (self-contained, no Bitnami dependency)

Etherpad `opendesk/helmfile/charts/etherpad` has been refactored:
- **Bitnami postgresql sub-chart removed** — `Chart.yaml` no longer lists `postgresql` as dependency, `charts/` directory deleted.
- **Direct postgres StatefulSet + Service** — `templates/postgresql-statefulset.yaml` and `templates/postgresql-service.yaml` replace the sub-chart. PVC `data-etherpad-postgresql-0` survives upgrades.
- **DB credentials from secret** — `deployment.yaml` reads `DB_PASS` via `valueFrom.secretKeyRef` from existing secret `etherpad-postgresql`. `_helpers.tpl` simplified — removed `.Values.postgresql.auth` fallbacks.
- **Image**: `docker.io/library/postgres:17` (official image) — local Zot registry alternative available when containerd is configured for insecure registries.
- **Postgres data migration**: Existing Bitnami-initialized data (missing `postgresql.conf` and `pg_hba.conf` in PGDATA) was patched with minimal config files to work with official `postgres:17` uid 999.

## STRUCTURE

```
/
├── opendesk/                   # Main openDesk CE deployment
│   ├── helmfile/               #   Helmfile-driven deployment
│   │   ├── apps/               #   Per-app values
│   │   ├── bases/              #   Base helmfiles
│   │   ├── charts/             #   Local chart overrides
│   │   ├── environments/       #   Environment configs (default, etc.)
│   │   └── shared/             #   Shared resources
│   ├── docs/                   #   All platform documentation
│   │   ├── architecture/       #   Architecture diagrams
│   │   ├── developer/          #   Dev workflows
│   │   └── ...
│   ├── helmfile.yaml.gotmpl    #   Root helmfile
│   └── CONTRIBUTING.md
│
├── opendesk-edu/               # Education variant (mirrored to GitHub & Codeberg)
│   ├── helmfile/               #   Same structure as opendesk/
│   │   ├── apps/               #   Includes moodle, ilias, jupyterhub, etc.
│   │   ├── charts/             #   Local charts (sogo, opencloud-sidecar, ...)
│   │   └── environments/
│   ├── docs/                   #   Edu-specific docs
│   ├── scripts/                #   Deployment scripts, SAML generators, semester tools
│   ├── tests/                  #   Integration + Playwright tests
│   └── AGENTS.md               #   Legacy — maintained separately
│
├── opendesk-sme/               # SME variant (same structure)
│   └── helmfile/
│
├── opendesk_sec/               # Security variant
│   ├── opendesk/               #   Hardened deployment manifests
│   └── security-assessment-2025-03-26/  # Full pentest report
│       ├── 00-executive-summary.md
│       ├── 02-findings-critical.md
│       ├── ... (10 sections)
│       └── evidence/           #   Scan reports, screenshots
│
├── opendesk-compose/           # Docker Compose alternative
│   ├── docker-compose.yml
│   ├── scripts/backup.sh & restore.sh
│   └── VALIDATION.md
│
├── k8up/                       # Kubernetes backup operator (Go, upstream)
│   ├── api/v1/                 #   CRD types
│   ├── operator/               #   Controllers (reconcilers)
│   ├── restic/                 #   Restic integration
│   ├── cli/                    #   CLI tools
│   ├── cmd/                    #   Entry points (operator, restic, cli, k8up)
│   ├── e2e/                    #   Bats end-to-end tests
│   ├── envtest/                #   Integration test helpers
│   ├── charts/k8up/            #   Helm chart
│   ├── config/                 #   CRD + RBAC manifests
│   └── docs/                   #   Adoc/docs documentation
│
├── user_import/                # User data conversion tools (Python)
│   ├── lib/                    #   UCS, Keycloak, random user modules
│   ├── scripts/                #   JSON→XLSX conversion
│   ├── tests/                  #   pytest suite
│   ├── data/                   #   Demo data (names, cities, images)
│   └── pyproject.toml
│
├── charts-upgrade-v1.12.0/     # Patched upstream Helm charts (v1.12.0)
│   ├── cryptpad/               #   (contains many sub-charts)
│   ├── postgresql/
│   ├── nginx/
│   ├── redis/
│   ├── xwiki/                  #   Patched: Ingress, PDB, PSP removals
│   ├── nubus/
│   ├── mariadb/
│   └── ... (~30 sub-charts)
│
├── addon-nextcloud_integration/ # OX ↔ Nextcloud integration (Java)
│   ├── com.openexchange.*/     #   OSGi bundles
│   ├── open-xchange-*          #   Debian packaging
│   ├── helm/                   #   Helm chart
│   └── e2e/                    #   CodeceptJS e2e tests
│
├── common/                     # Shared Helm chart helpers
│   └── templates/              #   _affinities, _ingress, _secrets, _storage, etc.
│
├── k8s-mc-mirror/              # MinIO cluster mirror (K8s Deployment)
│
├── demo-namespace/             # Demo namespace + coredns config
│
├── monitoring/                 # Grafana dashboards + investigation docs
│
├── erprobungskonzept/          # German trial concept (PDF + checklist)
│
├── opendesk-edu-website/       # Brand website (Next.js + TypeScript)
│
├── AGENTS.md                   # THIS FILE (agent knowledge base)
│
└── README.md                   # Monorepo overview
```

> Loose docs/deploy logs/values from the former root now live in `opendesk-edu/docs/`
> (`zki/`, `mail/`, `legacy/`, `operations/`) and `opendesk-edu/deploy-configs/`.

---

## BUILD / LINT / TEST COMMANDS

### Go: k8up/

```bash
# Build
make build              # Build manager binary (includes generate, fmt, vet)
make docker-build       # Build docker image
make docker-push        # Push docker image

# Run all tests
make test               # Run all tests with coverage (./...)
make integration-test   # Integration tests with envtest
make e2e-test           # E2E tests (Bats on KIND)

# Run single test
go test -v -run TestFunctionName ./path/to/package

# Run specific Bats test
cd k8up/e2e && bats test-03-backup.bats

# Lint
make lint               # All lint targets
make golangci-lint      # golangci-lint
make fmt                # go fmt
go vet ./...

# Generate
make generate           # CRD, RBAC manifests
make crd                # CRD to file

# Run locally
make run-operator       # Operator module
make run-restic         # Restic module

# Charts
make -C k8up/charts/k8up clean
cd k8up/charts/k8up && helm package .
cd k8up/charts && go test ./...   # chart-test
```

### Python: user_import/

```bash
# Setup
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Run
python user_import/scripts/convert_user_json_to_xlsx.py
convert-json            # Entry point from pyproject.toml

# Test
pytest tests/
pytest tests/test_keycloak.py -v
pytest tests/test_ucs.py -v
```

### Helm Charts (charts-upgrade-v1.12.0/)

```bash
make chart-prepare      # Prepare charts
make chart-docs         # Generate READMEs (helm-docs)
make chart-lint         # Lint all charts
make chart-test         # Go unit tests
```

### Docker Compose (opendesk-compose/)

```bash
docker-compose up -d
docker-compose ps
docker-compose logs -f <service>
./scripts/backup.sh
./scripts/restore.sh <backup-file>
```

### Website (opendesk-edu-website/)

```bash
npm install
npm run dev             # Development server
npm run build           # Production build
npm run lint
npm test                # Vitest
npx playwright test     # E2E tests
```

### Addon (addon-nextcloud_integration/)

```bash
# Build with Ant (Java SDK builds)
ant -f com.openexchange.nextcloud.filepicker/build.xml
# CodeceptJS e2e
cd e2e && yarn install && npx codeceptjs run
```

---

## CODE STYLE GUIDELINES

### Go (k8up/)

**Import Style:**
- Grouped: stdlib → external (k8s libs + project internal)
- Example:
  ```go
  import (
      "context"
      "fmt"

      k8upv1 "github.com/k8up-io/k8up/v2/api/v1"
      "github.com/k8up-io/k8up/v2/operator/job"
      batchv1 "k8s.io/api/batch/v1"
      controllerruntime "sigs.k8s.io/controller-runtime"
  )
  ```

**Formatting (.editorconfig enforced):**
- Tabs for indentation
- LF line endings
- No trailing whitespace
- Final newline required

**Naming:**
- Public: PascalCase (MyStruct, MyFunction)
- Private: camelCase (myVar, myFunction)
- Constants: PascalCase (MaxRetries, K8uplabel)
- Interfaces: Single-method = -er suffix, multi-method = descriptive name

**Error Handling:**
- Never ignore errors: `if err != nil { return err }`
- Use `fmt.Errorf` with `%w`: `fmt.Errorf("failed: %w", err)`
- Structured logging with controller-runtime: `log.Error(err, "message")`
- Check K8s API errors with `apierrors.IsNotFound()`, `apierrors.IsAlreadyExists()`

**Testing:**
- `*_test.go` for unit tests, `*_integration_test.go` with `//go:build integration`
- Use `testify/assert`
- Table-driven tests: `for _, tt := range tests { t.Run(tt.name, ...) }`

**Types:**
- `k8s.io/utils/ptr.To()` for pointer literals
- `metav1.ObjectMeta` for metadata
- CRD types in `api/v1/` with `// +kubebuilder` markers

### Python (user_import/)

**Style:**
- 4-space indentation (spaces, not tabs)
- `snake_case` for variables/functions
- `PascalCase` for classes
- Constants: `snake_case` accepted (e.g., `non_reconcile_groups`)

**Error Handling:**
- Use `logging` module: `logging.error()`, `logging.warning()`, `logging.info()`
- Try/except with **specific** exceptions (AVOID bare `except:`)
- Log with context: `logging.error(f"Failed to process {user}: {err}")`
- Use `logging.exception()` in catch blocks for full stack traces

### YAML / Helm / Bats

**Style:**
- YAML/JSON: 2-space indentation
- Bats/Makefiles: Tab indentation
- Helm templates: `{{- -}}` for whitespace control
- `{{- if .Values.x -}}` / `{{- end -}}` pattern for conditionals

### TypeScript / Next.js (opendesk-edu-website)

- ESLint + Prettier config
- Playwright for E2E tests, Vitest for unit tests
- i18n routing (de, en, fr, zh)
- Next.js App Router

---

## CONVENTIONS

### Deployment Architecture
- **Helm charts for all deployments** — no standalone Kubernetes manifests
- **helmfile** for multi-environment orchestration
- Platform-level: **No Operators/CRDs** (k8up is the only exception)
- **New tools require team approval** (upstream policy)
- **ArgoCD** for GitOps in production (HRZ cluster)
- **Keycloak SSO** — SAML 2.0 + OIDC for all services
- **k8up** for restic-based backups
- **Ceph CSI** storage (RBD SSD for databases, CephFS HDD EC for files)

### Build/Release
- Makefile-driven workflow (`make test`, `make e2e-test`)
- POSIX shell in Makefiles: `SHELL := /bin/bash`
- macOS sed compatibility: use `gsed` (GNU sed)
- Platform-specific xargs: Linux `--no-run-if-empty`, macOS omit

### PR Discipline
- **Separate code changes from chart changes** (never mix)
- Code PRs: label `area:operator`, never touch charts/
- Chart PRs: label `area:chart` + `chart:k8up`, bump Chart version
- Run `make chart-docs` for chart documentation

### Documentation Standards
- SPDX headers on all files (Apache-2.0, AGPL-3.0, etc.)
- `README.md` + `AGENTS.md` in each major sub-project
- `CHANGELOG.md` for release-tracked sub-projects
- `REUSE.toml` for REUSE compliance (opendesk, opendesk-edu)

### Helmfile Pattern
```yaml
# Root helmfile.yaml.gotmpl
environments:
  default:
    values:
      - helmfile/environments/default/global.yaml.gotmpl

releases:
  - name: my-app
    chart: helmfile/charts/my-app
    values:
      - helmfile/apps/my-app/values.yaml.gotmpl
```

---

## ENVIRONMENT CONTEXT (HRZ Cluster)

### Cluster
- **K3s v1.32.3** on Debian 12
- **API**: https://192.168.3.200:6443
- **9 nodes**: 3 control-plane (vhrz2331-2333), 6 workers (vhrz2334-2339)
- **containerd** 2.0.4-k3s2
- **Ingress**: ingress-nginx + Traefik
- **GitOps**: ArgoCD
- **Monitoring**: Prometheus stack + Grafana (dashboards in ./monitoring/)

### Storage
- **ceph-rbd-ssd** — RWO, fast (databases, stateful sets)
- **ceph-cephfs-hdd-ec** — RWX, erasure-coded (files, shared storage)
- **Backup target**: `s3:https://s3.hrz.uni-marburg.de/backups`

### Networking
- **Proxy**: http://www-proxy2.uni-marburg.de:3128 (for pods needing internet)
- **Domain**: *.opendesk.hrz.uni-marburg.de → 192.168.3.201 (ingress IP)
- **DNS quirk**: CoreDNS returns SERVFAIL on external CNAME chains (HRZ-specific)
  - Fix: use `hostAliases` in deployments for internal domains
- **Nameservers**: 137.248.21.22, 137.248.1.5, 137.248.1.8

### Known HRZ Issues
1. **DNS CNAME chains fail** — CoreDNS can't resolve external CNAME chains.
   Add `hostAliases` with ingress IP for internal domains.
2. **www-proxy2.uni-marburg.de** resolves in DNS; `proxy02.hrz.uni-marburg.de` does NOT.
3. **MariaDB password staleness** — Helm-deployed password may differ from what was
   set during initial deploy; check and sync `ALTER USER`.
4. **Nextcloud AIO probe bug** — readiness/startup probes use `initialDelaySeconds`
   instead of `periodSeconds`, causing 10x PHP-FPM load and container restart loop.
   Fix by patching the running deployment and the chart template.
5. **MariaDB transient "Connection refused"** — Newly created pods (e.g., ILIAS cron
   jobs) occasionally get `SQLSTATE[HY000] [2002] Connection refused` on first
   attempt. The ILIAS cronjob now has a 5-attempt retry loop with 10s sleep to
   work around this.
6. **Planka Helm chart annotation conflict** — The upstream Planka chart sets
   `kubernetes.io/ingress.class: nginx` in `values.yaml`. When using HAProxy
   ingress, this annotation must be removed (keeping only `ingressClassName: haproxy`).
7. **k8up RWO PVC backup stuck** — k8up Schedule `backup-live` backs up all PVCs
   including RWO (ReadWriteOnce) PVCs bound to pods on different nodes. The backup
   pod can't mount all RWO PVCs simultaneously, causing it to hang in
   `ContainerCreating`. Stuck jobs can be deleted; next scheduled run (00:42 daily)
   will retry. Long-term fix: add `k8up.io/exclude: "true"` annotation on RWO PVCs
   or configure PodConfigRef with node affinity in the Schedule.
   **Sprint 6 fix**: All 29 RWO PVCs annotated with `k8up.io/exclude: "true"`.
   Only RWX (ReadWriteMany) PVCs are now backed up by the main schedule:
   `clamav-db`, `clamav-tmp`, `dovecot`, `opendesk-opencloud-data`,
   `seaweedfs-all-in-one-data`, `slidev-slides`. RWO PVCs need a separate backup
   strategy (CSI snapshots or per-node schedules).
8. **Nextcloud requires OCI registry credentials** — Nextcloud is `enabled: true`
   but the Helm chart is hosted on a private OCI registry (`opencode.de`). Without
   `OD_PRIVATE_REGISTRY_USERNAME` and `OD_PRIVATE_REGISTRY_PASSWORD` environment
   variables, `helmfile sync` cannot pull the chart.
9. **Grafana ingress class mismatch** — The kube-prometheus-stack Grafana ingress
    defaulted to `ingressClassName: nginx`. The nginx ingress controller shares the
    external IP (192.168.3.201) with haproxy but doesn't process all ingresses.
    Fix: switch to `haproxy` ingress class.
10. **license-cache CronJob broken-by-design** — `ums-udm-rest-api-license-cache`
    (beide Namespaces) schlägt immer mit StartError fehl. Das Binary
    `/usr/share/univention-directory-manager-tools/univention-update-license-cache`
    existiert nicht im Image `udm-rest-api:0.42.6`. Der CronJob kann erst
    funktionieren, wenn das Chart auf eine Version mit dem passenden Image
    aktualisiert wird. Bis dahin: ignorieren oder CronJob suspendieren.
    Betrifft: default + opendesk namespace.

### Custom Images & Registry (2026-07-28)

All custom images are hosted on **GHCR** (`ghcr.io/opendesk-edu/*`) with mirrors on:
- **Zot** (local): `172.17.209.143:5000/opendesk-edu/*`
- **GitLab**: `registry.gitlab.com/tbsweiss/opendesk-edu/*`

| Image | Type | Description |
|-------|------|-------------|
| `mariadb:11.4.4` | Custom-built | MariaDB with ILIAS-optimized config + `mariadb-admin` probes |
| `ilias-shibboleth:9-php8.2-apache` | Custom-built | ILIAS + Shibboleth SP 3.5 + mod_ssl |
| `moodle-shib:v1.4.0` | Custom-built | Moodle 4.4 + Shibboleth SP on Ubuntu 22.04 |
| `bookstack:v26.05.2-ls276` | Mirrored | linuxserver/bookstack pinned by digest |
| `drawio:latest` | Mirrored | jgraph/drawio pinned by digest |
| `excalidraw:latest` | Mirrored | excalidraw/excalidraw pinned by digest |
| `self-service-password:latest` | Mirrored | ltbproject/self-service-password pinned by digest |
| `planka:latest` | Mirrored | ghcr.io/plankanban/planka pinned by digest |

**Bitnami migration**: All 8 Helm charts are Bitnami-free. Replaced with direct StatefulSet + Service templates.
CI/CD: `.github/workflows/build-images.yml` auto-builds on Dockerfile changes.
Build script: `scripts/build-and-push.sh` for manual builds.

### Active Namespaces
argocd, buildkit, ceph-csi-cephfs, ceph-csi-rbd, deepl, default,
gitlab-runner-puppet, ingress-nginx, kube-node-lease, kube-public,
kube-system, **opendesk**, testing, traefik

---

## ANTI-PATTERNS (DO NOT DO)

| ❌ Anti-Pattern | ✅ Correct |
|----------------|-----------|
| Platform-specific xargs without conditional | Use `make -C k8up e2e-test` pattern |
| Bitnami Helm chart dependencies | Self-hosted StatefulSet + official base image |
| `mysqladmin` probes (MariaDB 11.4+) | `mariadb-admin ping` (binary renamed) |
| Hardcoded Zot ClusterIP in images | Use `ghcr.io/opendesk-edu/*` (stable registry) |
| Plain-text APP_KEY in values | Kubernetes secret via `valueFrom.secretKeyRef` |
| `capabilities.drop: [ALL]` without `DAC_OVERRIDE` | Add `DAC_OVERRIDE` if container needs to write files owned by other users |
| Non-POSIX shell in Makefiles | `SHELL=/bin/bash` required |
| Bare `except:` in Python | Use specific exceptions |
| Standalone Kubernetes manifests | MUST use Helm charts |
| New tools without team approval | Must be approved first |
| Suppression of type errors | Fix the type, don't silence it |
| Mixing code + chart changes in one PR | Separate PRs with labels |
| Using `policy/v1beta1` APIs | Use `policy/v1` (removed in K8s 1.25) |
| Using `extensions/v1beta1` ingress | Use `networking.k8s.io/v1` |
| PodSecurityPolicy (PSP) | Use Pod Security Admission instead |
| Editing running deployments directly | Prefer helmfile upgrade |
| PowerShell for SSH commands | Use WSL bash on Windows |
| Disabling brute-force protection in production | Never |

| ✅ Do Use | Notes |
|----------|-------|
| restic for backups | Via k8up operator |
| Bats testing (v1.11.0) | For k8up e2e tests |
| controller-runtime | For Kubernetes operators |
| Structured logging with zap | In k8up operator |
| testify/assert | For Go test assertions |
| Helmfile + helmfile.yaml.gotmpl | For multi-env deploys |

---

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Platform deployment | `opendesk/helmfile/` | Main openDesk CE |
| Platform docs | `opendesk/docs/` | Getting started, architecture, etc. |
| Edu services | `opendesk-edu/helmfile/apps/` | ILIAS, Moodle, JupyterHub, etc. |
| Edu charts | `opendesk-edu/helmfile/charts/` | Local chart definitions |
| SME variant | `opendesk-sme/` | Lighter profile |
| Security variant | `opendesk_sec/opendesk/` | Hardened manifests |
| Pentest report | `opendesk_sec/security-assessment-2025-03-26/` | Full assessment |
| Kubernetes operator | `k8up/` | Go, controllers in operator/ |
| CRD types | `k8up/api/v1/` | +kubebuilder markers |
| E2E tests | `k8up/e2e/*.bats` | Bats + detik |
| Helm chart (k8up) | `k8up/charts/k8up` | |
| User data conversion | `user_import/` | Python, pyproject.toml |
| Docker Compose | `opendesk-compose/` | Non-K8s alternative |
| Shared Helm helpers | `common/templates/` | _affinities, _ingress, _secrets |
| Grafana dashboards | `monitoring/` | JSON dashboards for openDesk |
| OX↔Nextcloud addon | `addon-nextcloud_integration/` | Java OSGi bundles |
| Brand website | `opendesk-edu-website/` | Next.js + TypeScript |
| Cluster status | `opendesk-edu/docs/operations/opendesk-environment-hrz.md` | Node details, resources |
| Planning/plans | `helmfile-git-*` branches, `.sisyphus/` | Sisyphus work plans |
| Nubus portal IAM | Nubus (Univention) | Portal + Keycloak |

---

## NOTES

- **Go version**: 1.23 (k8up/go.mod), but build environment may be older (1.19)
  - Compatibility patches applied for `maps`/`slices` usage
- **Bats version**: 1.11.0 (k8up/e2e/package.json)
- **Python**: pyproject.toml in user_import/
- **CI**: GitHub Actions (k8up), GitLab CI (opendesk CE), separate CI for edu variants
- **License**: Apache-2.0 unless otherwise noted per sub-project
- **Repositories mirrored**: opendesk-edu ↔ GitHub + Codeberg
- **Security**: Never disable brute-force protection in production
- **macOS compatibility**: gsed for sed, conditional xargs
- **HRZ-specific proxy**: `http://www-proxy2.uni-marburg.de:3128` for pods needing internet access

### Deployment Credentials Pattern
- Secrets stored in Keycloak / Vault, referenced via `secretKeyRef`
- LDAP auth: file-based (volume mount + env var), not inline
- Object storage: MinIO credentials in Kubernetes secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
- Portal consumers + servers share MinIO credentials in separate secrets

### Backup Architecture (k8up)
- Schedule CRD defines backup/check/prune/restore schedules
- PodConfigRef can customize pod specs (but must be complete — missing fields break schedule)
- Backups stored on `s3:https://s3.hrz.uni-marburg.de/backups`
- OpenProject PVCs can get stuck with `kubernetes.io/pvc-protection` finalizer
- Always delete Job resources (not just pods) when cleaning stuck backups

### OIDC Client Registration (Sprint 5)
- **SOGo OIDC client**: Registered in Keycloak realm `opendesk` as client ID `sogo`.
  Secret stored in `sogo-sogo` K8s secret under `oidc-client-secret` key. Also persisted
  in `opendesk-edu/helmfile/apps/sogo/values.yaml.gotmpl`.
- **Planka OIDC client**: Registered in Keycloak realm `opendesk` as client ID `planka`.
  Secret stored in `planka-planka-secrets` K8s secret under `planka-oidc-client-secret` key.
  Also persisted in `opendesk/helmfile/apps/planka/values.yaml.gotmpl`.
- Both clients have mappers for `email` and `preferred_username` claims.
- Registration via `kcadm.sh` on `ums-keycloak-0` (admin user: `kcadmin`).

# openDesk Edu — Cluster Status & Sprint Plan

## Current Status

**Cluster:** HRZ K3s (vhrz2331-2339), `opendesk-edu` namespace created 8d ago

| Metric | Value |
|--------|-------|
| Running pods | 39 (normal) |
| Pending pods | 1 (slidev — PVC stuck) |
| Deployments | 31 |
| Ingresses | 16 |
| Custom charts (local) | 24 |
| Missing services | 6 |

## Deployed Services

### Core platform (in `opendesk` namespace)
IAM (Nubus/UMS/Keycloak), Groupware (OX/Dovecot/Postfix), Nextcloud, Collabora,
CryptPad, Jitsi, Element, OpenProject, XWiki, Notes, OpenCloud, Matrix,
BigBlueButton, Moodle, ILIAS, MinIO, SeaweedFS, Prometheus/Grafana

### Edu-specific (in `opendesk-edu` namespace)
Bookstack, Code-Server, Collab Dashboard, Dask/JupyterHub, DrawIO, Etherpad,
Excalidraw, ILIAS, LimeSurvey, MariaDB, Ollama, OpenLDAP, Open WebUI, Planka,
PostgreSQL, RStudio, Self-Service Password, Slidev, SOGo (in demo namespace),
TTYD, TYPO3, SeaweedFS

## Issues

| # | Service | Issue | Severity |
|---|---------|-------|----------|
| 1 | **slidev** | PVC `slidev-slides` Pending on `ceph-rbd-ssd` — 0/9 nodes schedulable | Medium |
| 2 | **sogo** | Deployed in `demo-opendesk-edu` namespace, not in `opendesk-edu` | Low |
| 3 | **slidev** | 2nd replica stuck Pending (same PVC) | Low |

## Missing Services

| # | Service | Helmfile | Chart Type | Image | Dockerfile needed? |
|---|---------|----------|------------|-------|--------------------|
| 1 | **Zammad** | `apps/zammad/` | Local (`helmfile/charts/zammad/`) | `ghcr.io/zammad/zammad` | ❌ upstream image |
| 2 | **Overleaf** | `apps/overleaf/` | Upstream | `sharelatex/sharelatex:5.0.2` | ❌ upstream image |
| 3 | **KasmVNC** | `apps/kasmvnc/` | Upstream | n/a | ❌ upstream image |
| 4 | **Portal-entries** | `apps/portal-entries/` | Local (`helmfile/charts/portal-entries/`) | configmap-only | ❌ no app container |
| 5 | **Snipr** | `apps/snipr/` | Local (`helmfile/charts/snipr/`) | `ghcr.io/tobias-weiss-ai-xr/snipr:v1.0.0` | ✅ **needs Dockerfile** |
| 6 | **SOGo** | `apps/sogo/` | Local (`helmfile/charts/sogo/`) | upstream | ❌ deployed in wrong ns |

## Sprint Plan

### Sprint 1: Infrastructure Fixes (storage, namespace)

**Goal:** Fix blocking issues, prepare the ground

| Task | Effort | Details |
|------|--------|---------|
| 1.1 Fix slidev PVC | 2h | Delete stuck PVC, recreate with correct StorageClass or check RBD provisioning |
| 1.2 Move SOGo to opendesk-edu namespace | 2h | Redeploy SOGo chart from demo-opendesk-edu to opendesk-edu, update ingress |
| 1.3 Verify storage classes for all edu apps | 1h | Audit all edu PVCs for correct SC binding |
| 1.4 Smoke tests after fixes | 1h | Run smoke tests, verify all pods Running |

### Sprint 2: Core Missing Services

**Goal:** Deploy remaining upstream-chart services

| Task | Effort | Details |
|------|--------|---------|
| 2.1 Deploy Zammad | 4h | Configure values, deploy via helmfile, set up ingress + PostgreSQL + Elasticsearch |
| 2.2 Deploy Overleaf | 4h | Upstream chart, configure values, redis + mongo dependencies, ingress |
| 2.3 Deploy KasmVNC | 3h | Upstream chart, desktop access via browser, configure ingress + persistence |
| 2.4 Smoke tests | 1h | Verify each service accessible, basic functionality |

### Sprint 3: Custom Services (Snipr + Portal Entries)

**Goal:** Deploy custom-chart services that need Docker image or config

| Task | Effort | Details |
|------|--------|---------|
| 3.1 Snipr Dockerfile | 4h | Create Dockerfile for Rust SNIpR recording service (see `helmfile/charts/snipr/`), build and push to ghcr.io |
| 3.2 Snipr Helm deploy | 1h | Deploy snipr chart with built image, ingress, seaweedfs dependency |
| 3.3 Deploy portal-entries | 1h | Configmap-only chart, no container needed — apply and verify |
| 3.4 Smoke tests | 1h | Verify new services accessible |

### Sprint 4: Hardening & Documentation

**Goal:** Verify everything works end-to-end, document for operations

| Task | Effort | Details |
|------|--------|---------|
| 4.1 Update ingress configs for new services | 2h | Add/update ingress for zammad, overleaf, kasmvnc, snipr |
| 4.2 Run full smoke test suite | 2h | Run `smoke-tests` and verify all edu apps respond |
| 4.3 Update AGENTS.md | 1h | Document current state, ingress URLs, known issues |
| 4.4 GitOps sync | 1h | Update ArgoCD monolith manifest, push to repo |

## Summary

- **6 missing services** — 5 not deployed, 1 in wrong namespace
- **1 Dockerfile needed** — Snipr (`ghcr.io/tobias-weiss-ai-xr/snipr`)
- **1 infrastructure issue** — slidev PVC stuck
- **Total effort:** ~21h across 4 sprints

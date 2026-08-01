# OpenDesk Monorepo

This repository is a **multi-project monorepo** combining the openDesk digital workplace platform
with custom deployment automation, backup infrastructure, and educational extensions.

It is maintained at the **HRZ (Hochschulrechenzentrum) / University of Marburg** and contains
both upstream-forked and locally-developed components.

---

## Repository Map

```
./
├── opendesk/                   # Main openDesk CE deployment (upstream v1.13.x)
│   └── helmfile/               #   Helmfile-driven K8s deployment
│
├── opendesk-edu/               # openDesk Edu: CE + integrated education & research services
│   └── docs/presentations/     #   30-language conference presentations
│
├── opendesk-sme/               # openDesk for small/medium enterprises (lighter profile)
│
├── opendesk_sec/               # Security variant + security assessment reports
│   └── security-assessment-2025-03-26/   # Full pentest report
│
├── opendesk-compose/           # Docker Compose version (non-Kubernetes alternative)
│
├── k8up/                       # Kubernetes backup operator (Go) — upstream fork + patches
│   ├── operator/               #   Controller logic (Backup, Restore, Schedule, etc.)
│   ├── api/v1/                 #   CRD type definitions
│   ├── restic/                 #   Restic integration module
│   ├── cli/                    #   CLI tools
│   ├── e2e/                    #   Bats end-to-end tests
│   └── charts/k8up/            #   Helm chart
│
├── user_import/                # Python tools: UCS→Keycloak user provisioning
│   ├── lib/                    #   UCS API client, Keycloak API client, random user gen
│   ├── scripts/                #   JSON→XLSX conversion, import jobs
│   └── tests/                  #   pytest test suite
│
├── charts-upgrade-v1.12.0/     # Patched upstream Helm charts (K8s 1.25+ compatible)
│
├── addon-nextcloud_integration/ # OX App Suite ↔ Nextcloud integration addon (Java)
│
├── common/                     # Shared Helm chart helper templates (affinities, images, ingress, etc.)
│
├── k8s-mc-mirror/              # MinIO cluster mirroring tool (Kubernetes Deployment)
│
├── demo-namespace/             # Demo namespace manifests for K3s clusters
│
├── monitoring/                 # Grafana dashboards (JSON) + monitoring setup docs
│
├── erprobungskonzept/          # German-language trial concept / pilot documents
│
├── opendesk-edu-website/       # openDesk Edu brand website (Next.js)
│
├── AGENTS.md                   # THIS FILE IS FOR AI AGENTS — see below
│
└── README.md                   # This file
```

> Root-level docs, deployment scripts, and legacy session logs live in
> `opendesk-edu/docs/` (see `docs/zki/`, `docs/mail/`, `docs/legacy/`).
> Historical OpenCloud/Stalwart deploy values live in `opendesk-edu/deploy-configs/`.

---

## Sub-Project Quick Reference

| Directory | What It Is | Language | Deploy Method | Status |
|-----------|-----------|----------|---------------|--------|
| `opendesk/` | Main openDesk CE platform | YAML/Go | helmfile | Upstream v1.13.x |
| `opendesk-edu/` | Edu variant (CE + integrated services) | YAML/Python | helmfile | Active development |
| `opendesk-sme/` | SME variant | YAML | helmfile | Active development |
| `opendesk_sec/` | Security-hardened variant | YAML | helmfile | Assessment complete |
| `k8up/` | Kubernetes backup operator | Go | Helm/Kustomize | Forked from upstream |
| `user_import/` | User provisioning tools | Python | CLI | Production use |
| `opendesk-compose/` | Docker Compose version | YAML | docker-compose | Ready for deploy |
| `addon-nextcloud_integration/` | OX↔Nextcloud connector | Java/OX Addon | Custom | Stable |
| `opendesk-edu-website/` | Marketing website | TypeScript/Next.js | Docker/NPM | Live |

---

## Deployment Architecture

All Kubernetes deployments use **helmfile** with environments in `helmfile/environments/`:

```
helmfile -e <environment> apply
```

Environments define:
- `global.yaml.gotmpl` — Cluster-wide settings (domain, ingress, storage classes)
- `images.yaml.gotmpl` — Container image tags
- `charts.yaml.gotmpl` — Chart versions and repositories
- Per-app values in `helmfile/apps/`

**Cluster context**: K3s v1.32.3, 9 nodes (3 control-plane + 6 workers), containerd runtime,
Ceph CSI storage (RBD SSD + CephFS HDD EC), ArgoCD, ingress-nginx + Traefik.

Production cluster: **HRZ Marburg** (opendesk.hrz.uni-marburg.de)
— See [opendesk-edu/docs/operations/opendesk-environment-hrz.md](./opendesk-edu/docs/operations/opendesk-environment-hrz.md) for details.

---

## Key Technical Decisions

1. **Helm charts for everything** — No standalone K8s manifests (upstream policy)
2. **k8up for backups** — restic-based K8s-native backup operator with Schedule CRDs
3. **Keycloak SSO** — Central IAM with SAML 2.0 + OIDC for all services
4. **Nubus** — Portal and IAM layer (Univention technology)
5. **No Operators/CRDs at platform level** — k8up is the exception
6. **helmfile** — Stateful environment layering for multi-env deployments
7. **Makefile-driven** workflows for k8up development
8. **PR discipline** — Code changes never mixed with chart changes

---

## How to Navigate Documentation

### For Humans

| What You Want | Where to Look |
|---------------|---------------|
| Platform overview & install | `opendesk/docs/getting-started.md` |
| Edu variant features | `opendesk-edu/README.md` |
| SME variant features | `opendesk-sme/README.md` |
| Security hardening | `opendesk_sec/docs/specs/` |
| Docker Compose setup | `opendesk-compose/README.md` |
| Backup operator | `k8up/README.md` |
| User import tools | `user_import/README.md` |
| Upgrading openDesk | `opendesk/docs/migrations.md` |
| Cluster environment | `opendesk-edu/docs/operations/opendesk-environment-hrz.md` |

### For AI Agents

**Read `AGENTS.md`** — it contains all build/lint/test commands, code style guidelines,
conventions, anti-patterns, and environment context for every sub-project.
The project knowledge base is loaded automatically when Hermes Agent works in this directory.

---

## License

Unless otherwise noted in sub-project directories, this repository is licensed under
**Apache 2.0**. See individual `LICENSE` files in each sub-project for details.
Copyright Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH,
and openDesk Edu Contributors (2025-2026).

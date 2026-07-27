# openDesk Edu — Operations Runbook

**Cluster:** HRZ K3s v1.32.3  
**Namespace:** `opendesk`  
**Domain:** `opendesk.hrz.uni-marburg.de`  
**Ingress IP:** `192.168.3.201`  

---

## 1. Service Overview

| Service | Type | URL | Auth |
|---------|------|-----|------|
| OpenCloud | File sync | `files.opendesk.hrz.uni-marburg.de` | OIDC via Keycloak |
| Stalwart | Mail (SMTP/IMAP) | `mail.opendesk.hrz.uni-marburg.de` | OIDC via Keycloak |
| Keycloak | SSO/IAM | `id.opendesk.hrz.uni-marburg.de` | Admin: `kcadmin` |
| Portal | UI | `portal.opendesk.hrz.uni-marburg.de` | OIDC |
| ArgoCD | GitOps | `argocd.opendesk.hrz.uni-marburg.de` | SSO |

## 2. Quick Checks

```bash
# All services
kubectl get pods -n opendesk | grep -E "opencloud|stalwart|k8up"

# Stalwart listeners
kubectl exec stalwart-stalwart-0 -n opendesk -- cat /opt/stalwart/logs/stalwart.log.* 2>/dev/null | grep "listener started"

# OpenCloud status
curl -sk https://files.opendesk.hrz.uni-marburg.de/status.php

# Contract tests
cd opendesk-edu && bash scripts/contract-test.sh all

# k8up validation
cd opendesk-edu && bash scripts/k8up-validate.sh
```

## 3. Stalwart

### Config
File: `/opt/stalwart/etc/config.toml` (mounted from ConfigMap)

### Paths (v0.15.5)
| Mount | Path |
|-------|------|
| Config | `/opt/stalwart/etc/config.toml` |
| Data (RocksDB) | `/opt/stalwart/data` |
| Logs | `/opt/stalwart/logs` |

### Auth
- **OIDC issuer:** `https://id.opendesk.hrz.uni-marburg.de/realms/opendesk`
- **Client ID:** `stalwart`
- **Fallback admin:** `admin` / `admin123` (SHA-512 crypt hash)
- **Ports:** 25(SMTP), 587(Submission), 465(SMTPS), 143(IMAP), 993(IMAPS), 110(POP3), 995(POP3S), 4190(Sieve), 8080(HTTP API)

### Upgrade
Current: `v0.15.5` (image: `stalwartlabs/stalwart`)
- **v0.16 migration** requires Python migration script + web UI bundle (blocked by network)
- The v0.16 config format is JMAP-based — no more TOML files
- See `STALWART_STATUS.md` for details

### Backup
- PVC: `stalwart-stalwart` (20Gi RWO, ceph-rbd-ssd)
- Excluded from main backup (RWO) — separate schedule `backup-stalwart`
- Runs daily at 01:00
- Uses label selector `k8up.io/backup-group=stalwart`

## 4. OpenCloud

### Config
Environment variables set in deployment:
- `OC_OIDC_ISSUER`: `https://id.opendesk.hrz.uni-marburg.de/realms/opendesk`
- `PROXY_OIDC_CLIENT_ID`: `opendesk-opencloud`
- `OC_URL`: `https://files.opendesk.hrz.uni-marburg.de`

### Auth
- **OIDC issuer:** `https://id.opendesk.hrz.uni-marburg.de/realms/opendesk`
- **Client ID:** `opendesk-opencloud`
- **Client secret:** Stored in `opendesk-opencloud-secrets` (key `oc-oidc-client-secret`)

### Backup
- PVC: `opendesk-opencloud-data` (100Gi RWX, ceph-cephfs-hdd-ec)
- Backed up by `backup-live` (daily 00:42)
- No exclude annotation — should be included automatically

## 5. k8up Backup Operator

### Current State
- **Image:** `ghcr.io/k8up-io/k8up:v2.13.1` with custom binary via init container
- **Custom binary:** Built from `cmd/k8up` (not `cmd/operator`!) with Go 1.23.6
- **Init container:** Downloads binary from `k8up-bin-srv:9999/k8up`, mounts at `/usr/local/bin/k8up`
- **Binary server:** Deployment `k8up-binary-server` — serves the fixed binary

### Schedules (all in namespace `opendesk`)

| Schedule | PVCs | Backend | Schedule |
|----------|------|---------|----------|
| `backup-live` | All RWX PVCs | `s3.hrz.uni-marburg.de/backups` | Daily 00:42 |
| `backup-stalwart` | Stalwart RWO (label selector) | `s3.hrz.uni-marburg.de/backups` | Daily 01:00 |

### Recovery
S3 endpoint: `https://s3.hrz.uni-marburg.de`  
Bucket: `backups`  
Restore command: `kubectl apply -f restore.yaml` (see k8up docs)

## 6. ArgoCD GitOps

### Architecture
```
argocd/opendesk.git
├── master branch         → opendesk-apps (CE)  → 21 CE apps
└── deploy/edu-hrz branch → opendesk-edu-apps   → 35 edu apps
```

### Root Apps
| App | Branch | Status | Child Apps |
|-----|--------|--------|------------|
| `opendesk-apps` | `master` | `Synced/Healthy` | 21 CE |
| `opendesk-edu-apps` | `deploy/edu-hrz` | `Synced/Healthy` | 35 edu |

### Adding a New App
1. Edit `opendesk-edu-apps/values.yaml` in the `deploy/edu-hrz` branch
2. Push — ArgoCD auto-syncs
3. The app needs a `helmfile-child.yaml.gotmpl` in the edu repo

## 7. Known Issues

| Issue | Workaround | Status |
|-------|-----------|--------|
| HRZ DNS CNAME chain failure | `hostAliases` on all pods | ✅ Fixed |
| k8up init container (not full image) | Binary server pod serves fixed binary | ⚠️ Permanent workaround |
| Stalwart webadmin UI | Cannot download from GitHub | ⚠️ Blocked — needs side-load |
| Stalwart v0.16 upgrade | Requires migration script + webui bundle | ⚠️ Blocked by network |
| Bookstack CrashLoopBackOff | Missing APP_KEY (pre-existing) | ❌ Pre-existing |
| Portal consumer objstorage | Cannot reach `objectstorage.…` | ❌ Pre-existing |
| Seaweedfs backup schedule | Redundant, disabled (backs up to itself) | ✅ Fixed |

## 8. Credentials

| System | User | Auth | Source |
|--------|------|------|--------|
| Keycloak admin | `kcadmin` | Password | `keycloak-admin-password` secret |
| Stalwart admin | `admin` | `admin123` | SHA-512 hash in ConfigMap |
| ArgoCD | SSO via Keycloak | OIDC | — |
| LDAP admin | `cn=admin,dc=swp-ldap,dc=internal` | Password | `ums-ldap-server-admin` secret |
| GitLab bot | `gitlab-bot` | PAT | `repo-argocd-opendesk` secret |

## 9. Useful Commands

```bash
# Check all PVCs and backup annotations
kubectl get pvc -n opendesk -o json | jq '.items[] | {name: .metadata.name, modes: .spec.accessModes, exclude: .metadata.annotations."k8up.io/exclude"}'

# Check ArgoCD sync status
kubectl get applications -n argocd -o json | jq '.items[] | {name: .metadata.name, sync: .status.sync.status, health: .status.health.status}'

# Test contract suite
bash opendesk-edu/scripts/contract-test.sh all

# Validate k8up
bash opendesk-edu/scripts/k8up-validate.sh
```

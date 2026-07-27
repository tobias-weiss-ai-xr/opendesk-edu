# openDesk Edu - Operations Runbook

## Architecture

```
Services running on K3s cluster (opendesk.hrz.uni-marburg.de):

Keycloak SSO ──OIDC──→ OpenCloud, Stalwart, SOGo, Portal
                           │
Stalwart v0.16.15 ──SMTP→ External MX (MTA relay)
                  ──IMAP→ SOGo, Thunderbird
                  ──JMAP→ JMAP clients
                  ──POP3→ Legacy clients
                  ──Sie√→ Sieve filters
                           │
Postfix ── disabled (replicas=0)
```

## Services

| Service | URL | Status |
|---------|-----|--------|
| Portal | https://portal.opendesk.hrz.uni-marburg.de | ✅ |
| OpenCloud | https://files.opendesk.hrz.uni-marburg.de | ✅ |
| SOGo | https://contacts.opendesk.hrz.uni-marburg.de | ✅ |
| Stalwart | mail.opendesk.hrz.uni-marburg.de | ✅ |
| Element | https://element.opendesk.hrz.uni-marburg.de | ✅ |
| XWiki | https://xwiki.opendesk.hrz.uni-marburg.de | ✅ |

## Credentials

| System | User | Password | Where |
|--------|------|----------|-------|
| Keycloak admin | kcadmin | (from k8s secret) | `keycloak-admin-password` |
| Stalwart admin | admin | admin123 | `STALWART_RECOVERY_ADMIN` env |
| LDAP admin | cn=admin,dc=swp-ldap,dc=internal | (from k8s secret) | `ums-ldap-server-admin` |
| MASTER_PASSWORD | - | (from ~/.bashrc) | Used for OIDC secret derivation |

## Stalwart v0.16

### Ports
- 25: SMTP (inbound)
- 143: IMAP4
- 587: Submission (SMTP AUTH)
- 465: SMTPS
- 993: IMAPS
- 110: POP3
- 995: POP3S
- 4190: Sieve
- 8080: JMAP/HTTP API

### Config
- Data: `/var/lib/stalwart/data` (RocksDB)
- Config: `/etc/stalwart/config.json`
- Logs: `/var/lib/stalwart/logs` (stdout also)

### CLI
```bash
# Copy CLI into running pod (ephemeral /tmp)
kubectl cp $(kubectl get pod -n opendesk -l app=stalwart-cli -o name | head -1):/usr/local/bin/stalwart-cli /tmp/stalwart-cli
kubectl cp /tmp/stalwart-cli stalwart-stalwart-0:/tmp/ -n opendesk -c stalwart

# Usage
kubectl exec stalwart-stalwart-0 -n opendesk -- /tmp/stalwart-cli --url http://localhost:8080 --user admin --password admin123 <command>
```

### Probes (v0.16)
- TCP socket on port 8080 (NOT httpGet — v0.16 has no /api/health)
- Security context: allowPrivilegeEscalation=true, capabilities.drop=[]

## Keycloak OIDC Clients

| Client ID | Service | Realm | 
|-----------|---------|-------|
| opendesk-opencloud | OpenCloud | opendesk |
| sogo | SOGo | opendesk |
| stalwart | Stalwart | opendesk |
| opendesk-matrix | Element/Synapse | opendesk |
| opendesk-xwiki | XWiki | opendesk |
| (portal OIDC) | Portal (univention) | opendesk |

## Backup (k8up)

- **backup-live**: RWX PVCs daily 00:42
- **backup-stalwart**: RWO PVC via label selector daily 01:00
- All 29 RWO PVCs annotated `k8up.io/exclude: true`
- S3 target: `s3://s3.hrz.uni-marburg.de/backups`

## Deployment Methods

### Helmfile (full deployment)
```bash
cd opendesk-edu
helmfile -e edu -f helmfile/edu-helmfile.yaml.gotmpl sync
```

### ArgoCD (GitOps)
- CE apps: `opendesk-apps` @ master branch
- Edu apps: `opendesk-edu-apps` @ deploy/edu-hrz branch
- **Note**: CMP sidecar env var limitation means per-app env don't reach helmfile. CMP-based edu apps show `Unknown` in ArgoCD but are deployed via helmfile directly.

## SMTP Relay

Stalwart handles all SMTP. Postfix is disabled (replicas=0).

Services using Stalwart:
- SOGo: `smtp://stalwart-stalwart:587`
- OpenCloud: `stalwart-stalwart.opendesk.svc.cluster.local:587`

## Troubleshooting

### Stalwart CrashLoopBackOff
1. Check ConfigMap: must have ONLY `config.json` key, not `config.toml`
2. Check security context: `allowPrivilegeEscalation=true`, `capabilities.drop=[]`
3. Check probes: TCP socket on 8080, NOT httpGet

### ArgoCD CMP apps stuck "Unknown"
Known issue: per-app `plugin.env` vars don't reach the CMP sidecar in ArgoCD v3.1.8.
Workaround: use `helm.values` (Helm-based child apps) instead of CMP.

### HRZ DNS CNAME chain failures
CoreDNS returns SERVFAIL on external CNAME chains.
Fix: add `hostAliases` in pod specs pointing to ingress IP (192.168.3.201).

### Keycloak bootstrap chart fails
The `opendesk-keycloak-bootstrap` chart from OCI registry creates OIDC clients.
If it fails with "Object has no name defined": the `name` attribute is missing on existing clients.
Fix: delete conflicting clients via REST API.

## Known Contract Test Failures

| Test | Reason | Status |
|------|--------|--------|
| OpenCloud ingress unreachable | HRZ DNS CNAME issue | ⚠️ Known |
| OpenCloud not installed | Test check method | ⚠️ Known (runs) |
| Stalwart OIDC issuer | v0.16 uses internal OIDC provider | ⚠️ Known |
| Stalwart OIDC secret mismatch | v0.16 OIDC config differs from v0.15 | ⚠️ Known |
| ArgoCD edu root app not Synced | CMP env var limitation | ⚠️ Known |

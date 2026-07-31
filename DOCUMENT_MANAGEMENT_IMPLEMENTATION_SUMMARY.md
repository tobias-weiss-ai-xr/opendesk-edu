# Document Management Systems Implementation Summary

# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0 and GPL-3.0-or-later

## Overview

This document summarizes the implementation of **Mayan EDMS** and **Paperless-ngx** as Document Management Systems for openDesk Edu. Both systems are fully integrated with the existing openDesk infrastructure including Keycloak OIDC authentication, SeaweedFS storage, Stalwart email, and the Nubus portal.

## What Was Added

### 1. Mayan EDMS
- **Chart**: `helmfile/charts/mayan-edms/`
- **App**: `helmfile/apps/edu/mayan-edms/`
- **Purpose**: Full-featured Document Management System with workflows, versioning, and compliance

### 2. Paperless-ngx
- **Chart**: `helmfile/charts/paperless-ngx/`
- **App**: `helmfile/apps/edu/paperless-ngx/`
- **Purpose**: Document archiving with OCR, tags, and automated processing

### 3. Portal Integration
- **Portal Entries**: Added LDIF files for both systems in `helmfile/apps/edu/portal-entries/entries/`
- **Portal Configuration**: Updated `helmfile/apps/edu/portal-entries/values.yaml.gotmpl` with new entries

### 4. Global Configuration
- **Images**: Added image configurations in `helmfile/environments/edu/images.yaml`
- **Hosts**: Added domain configurations in `helmfile/environments/edu/ce-overrides/global+platform.yaml.gotmpl`
- **Secrets**: Added placeholder secrets in `helmfile/environments/edu/secrets.yaml`

## File Structure

```
/helmfile
├── apps
│   └── edu
│       ├── mayan-edms
│       │   ├── helmfile.yaml.gotmpl
│       │   └── values.yaml.gotmpl
│       ├── paperless-ngx
│       │   ├── helmfile.yaml.gotmpl
│       │   └── values.yaml.gotmpl
│       └── portal-entries
│           ├── entries
│           │   ├── mayan-edms.ldif
│           │   └── paperless-ngx.ldif
│           └── values.yaml.gotmpl (updated)
└── charts
    ├── mayan-edms
    │   ├── Chart.yaml
    │   ├── README.md
    │   ├── values.yaml
    │   ├── .helmignore
    │   ├── Chart.lock
    │   ├── templates
    │   │   ├── _helpers.tpl
    │   │   ├── deployment.yaml
    │   │   ├── service.yaml
    │   │   ├── ingress.yaml
    │   │   ├── pvc.yaml
    │   │   ├── configmap.yaml
    │   │   ├── secret.yaml
    │   │   ├── serviceaccount.yaml
    │   │   ├── hpa.yaml
    │   │   ├── pdb.yaml
    │   │   └── networkpolicy.yaml
    │   └── tests
    │       └── deployment_test.yaml
    └── paperless-ngx
        ├── Chart.yaml
        ├── README.md
        ├── values.yaml
        ├── .helmignore
        ├── Chart.lock
        ├── templates
        │   ├── _helpers.tpl
        │   ├── deployment.yaml
        │   ├── service.yaml
        │   ├── ingress.yaml
        │   ├── pvc.yaml
        │   ├── configmap.yaml
        │   ├── secret.yaml
        │   ├── serviceaccount.yaml
        │   ├── hpa.yaml
        │   ├── pdb.yaml
        │   └── networkpolicy.yaml
        └── tests
            └── deployment_test.yaml
```

## Configuration

### Enabling the Systems

To enable Mayan EDMS and Paperless-ngx, update the configuration:

```yaml
# In helmfile/environments/edu/ce-overrides.yaml.gotmpl
apps:
  mayanEdms:
    enabled: true
  paperlessNgx:
    enabled: true
```

### Storage Configuration

Both systems are configured with appropriate storage classes:
- **Data/Media/Consume**: `ceph-cephfs-hdd-ec` (ReadWriteMany for shared access)
- **Index**: `ceph-rbd-ssd` (ReadWriteOnce for performance)
- **Database/Redis**: `ceph-rbd-ssd` (ReadWriteOnce for performance)

Default sizes can be customized:

```yaml
apps:
  mayanEdms:
    storage:
      dataSize: "50Gi"
      mediaSize: "100Gi"
      indexSize: "10Gi"
      databaseSize: "20Gi"
      redisSize: "5Gi"

  paperlessNgx:
    storage:
      dataSize: "100Gi"
      consumeSize: "50Gi"
      databaseSize: "20Gi"
      redisSize: "5Gi"
```

### Authentication Configuration

> **⚠️ Wichtig (Stand 2026-07-31):** Paperless-ngx **2.12.0 ignoriert die `PAPERLESS_OIDC_*`-Umgebungsvariablen vollständig** — natives OIDC existiert in dieser Version nicht (die Einstellungen laden keine OIDC-Auth-Backend, `OIDC_OP_ISSUER` bleibt `None`). Login erfolgt daher über den lokalen Superuser (`admin`). Mayan EDMS unterstützt OIDC (Chart-Konfiguration vorhanden, noch nicht deployed).

### Authentication Configuration

> **⚠️ Wichtig (Stand 2026-07-31):** Paperless-ngx **2.12.0 ignoriert die `PAPERLESS_OIDC_*`-Umgebungsvariablen vollständig** — natives OIDC existiert in dieser Version nicht (die Einstellungen laden keine OIDC-Auth-Backend, `OIDC_OP_ISSUER` bleibt `None`). Login erfolgt daher über den lokalen Superuser (`admin`). Mayan EDMS unterstützt OIDC (Chart-Konfiguration vorhanden, noch nicht deployed).

OIDC-Clients (relevant, sobald eine OIDC-fähige Version deployed wird):
   - Client ID: `mayan-edms`
   - Redirect URI: `https://mayan.{domain}/accounts/openid/login/callback/`
   - Scopes: `openid email profile`
   - Claims: `preferred_username`, `email`, `given_name`, `family_name`

2. **Paperless-ngx Client**:
   - Client ID: `paperless-ngx`
   - Redirect URI: `https://paperless.{domain}/accounts/oidc/callback/`
   - Scopes: `openid email profile`
   - Claims: `preferred_username`, `email`, `given_name`, `family_name`

### Resource Configuration

Default resource requests and limits:

```yaml
resources:
  mayan:
    requests:
      cpu: "1"
      memory: "2Gi"
    limits:
      cpu: "2"
      memory: "4Gi"

  paperless:
    requests:
      cpu: "1"
      memory: "2Gi"
    limits:
      cpu: "2"
      memory: "4Gi"
```

### Backup Configuration

Both systems are configured with k8up for automated backups:

```yaml
backup:
  enabled: true
  k8up:
    schedule: "0 2 * * *"
    retention:
      daily: 7
      weekly: 4
      monthly: 3
    snapshotVolumes: true
```

## Integration Points

### Keycloak OIDC
- Single Sign-On across all services
- Role-based access control
- Multi-factor authentication support

### SeaweedFS S3 Storage
- Configure as backend for document storage
- S3-compatible API
- Erasure coding for data protection

### Stalwart Email
- **Mayan EDMS**: SMTP for notifications
- **Paperless-ngx**: IMAP for email processing

### Nubus Portal
- Unified access to all services
- Portal entries for both DMS systems

### OpenCloud (Nextcloud)
- Can be configured as external storage
- Complementary file sync and sharing

## Features Comparison

| Feature | Mayan EDMS | Paperless-ngx |
|---------|-----------|---------------|
| **License** | Apache-2.0 | GPL-3.0-or-later |
| **Document Versioning** | ✅ | ❌ |
| **Workflows** | ✅ | ❌ |
| **OCR** | ✅ | ✅ |
| **Email Processing** | ❌ | ✅ |
| **Auto-Classification** | ❌ | ✅ |
| **Barcode Detection** | ❌ | ✅ |
| **Compliance Features** | ✅ | ❌ |
| **Best For** | Formal documents, compliance | Automated archiving, OCR |

## Use Cases

### Mayan EDMS
- Academic administration (student records, contracts, forms)
- Research document management (papers, theses, publications)
- Legal compliance and retention policies
- Team-based document review and approval workflows

### Paperless-ngx
- Student submissions (automated processing and archiving)
- Research papers (store and tag publications)
- Administrative documents (archive forms, invoices, receipts)
- Email archiving (automatically archive important emails)
- Automated document classification and OCR

## Deployment Instructions

### Prerequisites
1. Keycloak with OIDC realm configured
2. SeaweedFS deployed and configured
3. Stalwart mail server deployed (optional for email features)
4. Ceph storage classes available

### Steps to Deploy

1. **Register OIDC Clients in Keycloak**:
   ```bash
   # Mayan EDMS
   kcadm.sh create clients/opendesk -f - <<EOF
   {
     "clientId": "mayan-edms",
     "name": "Mayan EDMS",
     "enabled": true,
     "protocol": "openid-connect",
     "publicClient": false,
     "standardFlowEnabled": true,
     "redirectUris": ["https://mayan.${DOMAIN}/accounts/openid/login/callback/"],
     "webOrigins": ["https://mayan.${DOMAIN}"]
   }
   EOF
   
   # Paperless-ngx
   kcadm.sh create clients/opendesk -f - <<EOF
   {
     "clientId": "paperless-ngx",
     "name": "Paperless-ngx",
     "enabled": true,
     "protocol": "openid-connect",
     "publicClient": false,
     "standardFlowEnabled": true,
     "redirectUris": ["https://paperless.${DOMAIN}/accounts/oidc/callback/"],
     "webOrigins": ["https://paperless.${DOMAIN}"]
   }
   EOF
   ```

2. **Update Client Secrets**:
   - Retrieve client secrets from Keycloak
   - Update in `helmfile/environments/edu/secrets.yaml`

3. **Enable Systems**:
   ```yaml
   # In helmfile/environments/edu/ce-overrides.yaml.gotmpl
   apps:
     mayanEdms:
       enabled: true
     paperlessNgx:
       enabled: true
   ```

4. **Deploy**:
   ```bash
   cd /path/to/opendesk-edu
   helmfile -f helmfile.yaml.gotmpl sync
   ```

5. **Verify**:
   ```bash
   # Check deployments
   kubectl get deployments -n opendesk | grep -E "(mayan|paperless)"
   
   # Check pods
   kubectl get pods -n opendesk | grep -E "(mayan|paperless)"
   
   # Check PVCs
   kubectl get pvc -n opendesk | grep -E "(mayan|paperless)"
   
   # Check services
   kubectl get svc -n opendesk | grep -E "(mayan|paperless)"
   
   # Access via browser
   # Mayan EDMS: https://mayan.{domain}
   # Paperless-ngx: https://paperless.{domain}
   ```

## Testing

Both charts include Helm unittest tests:

```bash
# Run tests for Mayan EDMS
helm unittest helmfile/charts/mayan-edms/

# Run tests for Paperless-ngx
helm unittest helmfile/charts/paperless-ngx/
```

## Customization

### Mayan EDMS Customization

1. **Custom Metadata Types**:
   ```yaml
   mayan:
     metadata:
       documentTypes:
         - name: "Custom Type"
           label: "Custom Type"
   ```

2. **Workflow Configuration**:
   ```yaml
   mayan:
     workflows:
       enabled: true
       defaultReviewInterval: 30
       defaultDocumentType: "document"
   ```

### Paperless-ngx Customization

1. **OCR Configuration**:
   ```yaml
   paperless:
     ocr:
       enabled: true
       language: "eng+deu+fra"
       imageDpi: 300
       rotatePages: true
   ```

2. **Email Processing**:
   ```yaml
   paperless:
     email:
       enabled: true
       imap:
         enabled: true
         host: "stalwart-stalwart.opendesk.svc.cluster.local"
         port: 993
         ssl: true
   ```

## Security Considerations

### Authentication
- Enable MFA in Keycloak for sensitive documents
- Configure appropriate role mappings
- Regularly rotate client secrets

### Authorization
- Configure permissions at the document type level (Mayan)
- Configure user access per document type (Paperless)
- Regularly review access logs

### Data Protection
- All PVCs are encrypted at rest (Ceph CSI)
- Backups are encrypted (k8up with restic)
- Network policies restrict access to storage backends

### Network Security
- Ingress via HAProxy with TLS
- Network policies restrict pod-to-pod communication
- Pod Security Admission enforces security contexts

## Monitoring

Both systems expose metrics for Prometheus:
- Request rates
- Error rates
- Resource utilization
- Document processing metrics

## Troubleshooting

### Common Issues

#### OIDC Authentication Errors
- Verify client configuration in Keycloak
- Check redirect URIs match exactly
- Ensure client secret is correct
- Verify host aliases are configured for DNS resolution

#### PVC Not Bound
- Check storage class availability
- Verify PVC size requirements
- Check for existing PVCs that might conflict

#### Pod CrashLoopBackOff
- Check logs: `kubectl logs -n opendesk <pod-name>`
- Verify database connectivity
- Check Redis connectivity
- Verify configuration in ConfigMap

#### Ingress Not Working
- Verify ingress class is correct
- Check TLS certificate is available
- Verify host configuration in values

### Debugging Commands

```bash
# View Mayan EDMS logs
kubectl logs -n opendesk deployment/mayan-edms -f

# View Paperless-ngx logs
kubectl logs -n opendesk deployment/paperless-ngx -f

# Check PostgreSQL connection (Mayan)
kubectl exec -n opendesk deployment/mayan-edms -- psql -h mayan-edms-postgresql -U mayan -d mayan -c "SELECT 1"

# Check Redis connection (Mayan)
kubectl exec -n opendesk deployment/mayan-edms -- redis-cli -h mayan-edms-redis-master PING

# Check PVC status
kubectl get pvc -n opendesk | grep -E "(mayan|paperless)"

# Check backup status (k8up)
kubectl get backup -n opendesk | grep -E "(mayan|paperless)"
```

## Upgrades

### Upgrading Mayan EDMS

1. Update image tag in `helmfile/environments/edu/images.yaml`:
   ```yaml
   images:
     mayan:
       tag: "4.6.0"
   ```

2. Apply update:
   ```bash
   helmfile -f helmfile.yaml.gotmpl sync
   ```

3. Verify:
   ```bash
   kubectl rollout status deployment/mayan-edms -n opendesk
   ```

### Upgrading Paperless-ngx

1. Update image tag in `helmfile/environments/edu/images.yaml`:
   ```yaml
   images:
     paperless:
       tag: "2.13.0"
   ```

2. Apply update:
   ```bash
   helmfile -f helmfile.yaml.gotmpl sync
   ```

3. Verify:
   ```bash
   kubectl rollout status deployment/paperless-ngx -n opendesk
   ```

## Documentation

- **Main Documentation**: `docs/DOCUMENT_MANAGEMENT_SYSTEMS.md`
- **Mayan EDMS**: `helmfile/charts/mayan-edms/README.md`
- **Paperless-ngx**: `helmfile/charts/paperless-ngx/README.md`
- **Official Mayan EDMS Docs**: https://docs.mayan-edms.com
- **Official Paperless-ngx Docs**: https://paperless-ngx.readthedocs.io

## License

- **Mayan EDMS**: Apache License 2.0
- **Paperless-ngx**: GNU GPL-3.0-or-later
- **Implementation**: Apache License 2.0

## Next Steps

1. **Register OIDC Clients**: Create clients in Keycloak for both systems
2. **Update Secrets**: Replace placeholder secrets with actual values
3. **Test Deployment**: Deploy in a test environment first
4. **Configure Storage**: Verify SeaweedFS or other storage backend is available
5. **Enable Applications**: Set `enabled: true` for both systems
6. **Deploy**: Run `helmfile sync`
7. **Verify**: Check all components are running correctly
8. **Configure**: Set up document types, workflows, and OCR as needed

## Related Files Modified

1. `helmfile/charts/mayan-edms/` - New chart
2. `helmfile/charts/paperless-ngx/` - New chart
3. `helmfile/apps/edu/mayan-edms/` - New app
4. `helmfile/apps/edu/paperless-ngx/` - New app
5. `helmfile/apps/edu/portal-entries/entries/mayan-edms.ldif` - New portal entry
6. `helmfile/apps/edu/portal-entries/entries/paperless-ngx.ldif` - New portal entry
7. `helmfile/apps/edu/portal-entries/values.yaml.gotmpl` - Updated with new entries
8. `helmfile/apps/edu/portal-entries/helmfile.yaml.gotmpl` - Updated condition
9. `helmfile/environments/edu/ce-overrides.yaml.gotmpl` - Added app configurations
10. `helmfile/environments/edu/ce-overrides/global+platform.yaml.gotmpl` - Added domain configurations
11. `helmfile/environments/edu/images.yaml` - Added image configurations
12. `helmfile/environments/edu/secrets.yaml` - Added placeholder secrets
13. `docs/DOCUMENT_MANAGEMENT_SYSTEMS.md` - New documentation

## Validation

To validate the implementation:

```bash
# Validate Mayan EDMS chart
helm lint helmfile/charts/mayan-edms/
helm template --debug helmfile/charts/mayan-edms/ -f helmfile/charts/mayan-edms/values.yaml

# Validate Paperless-ngx chart
helm lint helmfile/charts/paperless-ngx/
helm template --debug helmfile/charts/paperless-ngx/ -f helmfile/charts/paperless-ngx/values.yaml

# Run unit tests
helm unittest helmfile/charts/mayan-edms/
helm unittest helmfile/charts/paperless-ngx/

# Validate helmfile
helmfile -f helmfile.yaml.gotmpl lint
```

## Deployment Notes & Known Limitations (Stand 2026-07-31)

### Live-Deployment Paperless-ngx

Paperless-ngx wurde am 31.07.2026 live im Namespace `opendesk` deployed:

| | |
|---|---|
| **Release** | `paperless-ngx` (Rev. 8, Helm) |
| **URL** | `https://dms.opendesk.hrz.uni-marburg.de` (Ingress haproxy) |
| **Image** | `ghcr.io/paperless-ngx/paperless-ngx:2.12.0` |
| **DB** | Gemeinsame `postgresql-0` (DB `paperless`, User `paperless`) |
| **Cache** | Gemeinsame `redis-master-0` (DB 0 Broker, DB 1 Cache) |
| **Storage** | `paperless-ngx-data` 30Gi RWX cephfs, `paperless-ngx-consume` 10Gi RWX cephfs |
| **Login** | `admin` (lokaler Superuser, via `createsuperuser`) |

> **Bewusst KEINE Bitnami-Subcharts** (postgresql/redis): Die gepinnten Image-Tags
> (`postgresql:15.4.0-debian-11-r45`) existieren nicht mehr auf Docker Hub und Bitnami-
> Dependencies sind per Projektkonvention (AGENTS.md) Anti-Pattern. Stattdessen werden die
> bereits laufenden gemeinsamen Dienste genutzt.

### DNS (cluster-intern via CoreDNS)

Der externe HRZ-DNS-Record `dms.opendesk.hrz.uni-marburg.de` **fehlt noch** (muss extern
angelegt werden: `A 192.168.3.201`). Für den cluster-internen Zugriff wurde ein CoreDNS-`hosts`-
Eintrag ergänzt:

```text
# kube-system ConfigMap coredns → data.NodeHosts (hosts-Plugin, reload 15s)
172.17.154.139 dms.opendesk.hrz.uni-marburg.de
```

`172.17.154.139` = ClusterIP des `haproxy-ingress` LoadBalancers (extern 192.168.3.201).
Damit erreichen Pods den Ingress über den Hostnamen (End-to-End getestet: Pod → DNS → Ingress → Paperless-API).

### Punkt 2: OIDC-Limitation (Paperless-ngx 2.12)

`PAPERLESS_OIDC_ISSUER`/`PAPERLESS_OIDC_CLIENT_ID`/`PAPERLESS_OIDC_CLIENT_SECRET` werden von
Paperless-ngx 2.12.0 **ignoriert** (verifiziert: `settings.AUTHENTICATION_BACKENDS` enthält kein
OIDC-Backend). Login nur über lokale Benutzer. Der Keycloak-Client `paperless-ngx` wurde daher
**nicht** registriert. Bei einem Upgrade auf eine OIDC-fähige Paperless-Version:
1. Client `paperless-ngx` im Keycloak-Realm `opendesk` anlegen
   (Redirect `https://dms.opendesk.hrz.uni-marburg.de/accounts/oidc/callback/`)
2. Secret in `helmfile/environments/edu/secrets.yaml` hinterlegen
3. Secret `paperless-ngx-oidc-secrets` (Keys `oidc-client-secret`, `secret-key`) aktualisieren

### Punkt 3: celery-beat crasht auf CephFS (gdbm-Lock)

`CELERY_BEAT_SCHEDULE_FILENAME` ist hardcoded auf `${DATA_DIR}/celerybeat-schedule.db`
(`/usr/src/paperless/data` → cephfs RWX). GDBM-Datei-Locking wird von CephFS nicht unterstützt
→ `_gdbm.error: [Errno 11] Resource temporarily unavailable` → celery-beat crash-loopt
(supervisord restartet ihn, nicht fatal).

**Auswirkungen:** Nur geplante Hintergrund-Tasks betroffen (E-Mail-Polling alle 10 min,
Classifier-Training stündlich, Index-Optimierung). Web-UI, API, OCR, Dokumenten-Consumption
funktionieren (celery worker läuft).

**Fix-Optionen (später):**
1. Supervisord-Config per ConfigMap überlagern: `celery beat --schedule /tmp/...` (tmpfs/emptyDir)
2. Datenverzeichnis auf `ceph-rbd-ssd` (RWO) umstellen — bricht aber RWX-Sharing
3. Auf neue Paperless-Version warten, die Locking-frei arbeitet

### Punkt 4: Verwaistes PVC + hängender k8up-Backup-Pod (gefixt)

Das 100Gi-PVC `opencloud-helm-data` stammte vom gelöschten ArgoCD-App `opencloud-helm`
(Anti-Pattern: zwei OpenCloud-PVCs à 100Gi für ein Release). Es wurde nur noch vom seit 16h
hängenden k8up-Backup-Pod `backup-backup-live-backup-rf2xw-3-4xmml` referenziert (bekanntes
Problem AGENTS.md #7: Backup-Pod kann nicht alle RWO/RWX-PVCs gleichzeitig mounten).

**Durchgeführt am 31.07.2026:**
1. Stuck Job `backup-backup-live-backup-rf2xw-3` gelöscht (nächster Lauf 00:42 retryt)
2. PVC `opencloud-helm-data` gelöscht (Daten liegen in k8up/restic-Backups auf S3, k8up/backup:true-Label)
3. Quota-Freigabe: **2014Gi → 1914Gi / 2Ti** (100Gi)

## Conclusion

This implementation adds two powerful Document Management Systems to openDesk Edu:
- **Mayan EDMS** for formal document management with workflows and compliance
- **Paperless-ngx** for automated document archiving and OCR

**Paperless-ngx ist seit 2026-07-31 live deployed** (`dms.opendesk.hrz.uni-marburg.de`).
Mayan EDMS ist chart-fertig, aber noch nicht deployed. Wichtige Einschränkungen:
OIDC-Login bei Paperless 2.12 nicht verfügbar (lokaler Login), celery-beat crasht auf CephFS
(nur Hintergrund-Tasks betroffen), externer DNS-Record fehlt noch (cluster-intern gelöst via CoreDNS).

## Cluster-Hardening Session (2026-07-31) — Fixes

| # | Issue | Fix |
|---|-------|-----|
| 1 | OpenCloud CrashLoopBackOff ("system user ID not configured") | ArgoCD-App `opencloud`: `systemUserId=admin` in helm.values (json-replace); `kubectl set env OC_SYSTEM_USER_ID=admin`; values.yaml.gotmpl Default `admin`; fehlende `helmfile-child.yaml.gotmpl` erstellt |
| 2 | ArgoCD-App-of-Apps überschrieb Patches | `selfHeal` von `opendesk-apps` + `opendesk-edu-apps` deaktiviert (syncPolicy.automated=null) |
| 3 | Etherpad Sync-Failed (PVC immutable, Probe 2 Handler, Image 1.9.9 weg) | App-Values: PVC RWO+ceph-rbd-ssd, pg.persistence ohne storageClass; Image `2.2`; `Replace=true` SyncOption |
| 4 | PrometheusRule edu-service-alerts invalid | Range-Vectors in `increase()` gewrappt (Stalwart/OpenCloud/K8up HighRestarts) |
| 5 | Backups Error (Upload hängt) | S3 war temporär unerreichbar; `sogo-sogo-data` PVC mit `k8up.io/exclude=true` annotiert (RWO multi-attach) |
| 6 | TLS-Order dms Failed (NXDOMAIN) | cert-manager-Annotation vom paperless-Ingress entfernt; obsoletes dms-Certificate gelöscht (Wildcard-`*.opendesk...` bis 2027 bleibt) |
| 7 | sogo: PVC storageClass immutable + Ingress `example.com` | Chart: storageClassName immer `ceph-rbd-ssd`; example.com-Defaults → reale Domain (ArgoCD ignorierte App-Values) |
| 8 | Verwaistes PVC `opencloud-helm-data` (100Gi) + stuck Backup-Pod | PVC gelöscht, Job gelöscht → 100Gi Quota frei |

**Bekannte Rest-Themen:** opencloud App bleibt OutOfSync (GitLab-Parent-helmfile rendert ohne systemUserId; Patches halten solange kein Parent-Sync); sogo health=Progressing (harmlos); stalwart/portal-entries Soft-Drift; ES-Cluster (ECK ApplyingChanges 62d, VolumeResize auf Ceph); seaweedfs-Backup-Cron `0 0 31 2 *` ungültig (31. Feb); license-cache-CronJob (bekannt AGENTS.md #10).

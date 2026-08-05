# Document Management Systems - Deployment Checklist

## Overview

This checklist guides you through deploying Mayan EDMS and Paperless-ngx in openDesk Edu.

## Pre-Deployment Checklist

### Infrastructure Requirements
- [ ] Kubernetes cluster (K3s v1.32.3+) running
- [ ] Ceph CSI storage available
- [ ] HAProxy ingress controller running
- [ ] Cert-manager configured
- [ ] Keycloak deployed with OIDC realm
- [ ] SeaweedFS deployed (optional, for S3 storage)
- [ ] Stalwart mail server deployed (optional, for email features)

### Configuration Files
- [x] `helmfile/charts/mayan-edms/` - Created
- [x] `helmfile/charts/paperless-ngx/` - Created
- [x] `helmfile/apps/edu/mayan-edms/` - Created
- [x] `helmfile/apps/edu/paperless-ngx/` - Created
- [x] `helmfile/apps/edu/portal-entries/entries/mayan-edms.ldif` - Created
- [x] `helmfile/apps/edu/portal-entries/entries/paperless-ngx.ldif` - Created
- [x] `helmfile/apps/edu/portal-entries/values.yaml.gotmpl` - Updated
- [x] `helmfile/apps/edu/portal-entries/helmfile.yaml.gotmpl` - Updated
- [x] `helmfile/environments/edu/ce-overrides.yaml.gotmpl` - Updated
- [x] `helmfile/environments/edu/ce-overrides/global+platform.yaml.gotmpl` - Updated
- [x] `helmfile/environments/edu/images.yaml` - Updated
- [x] `helmfile/environments/edu/secrets.yaml` - Updated with placeholders

## Deployment Steps

### 1. Prepare Environment
```bash
cd /path/to/opendesk-edu
```

### 2. Register OIDC Clients in Keycloak

Use kcadm.sh or Keycloak admin UI to create clients:

#### Mayan EDMS Client
- Client ID: `mayan-edms`
- Name: `Mayan EDMS`
- Protocol: `openid-connect`
- Public Client: `false`
- Standard Flow Enabled: `true`
- Redirect URIs: `https://mayan.your-domain.com/accounts/openid/login/callback/`
- Web Origins: `https://mayan.your-domain.com`

#### Paperless-ngx Client
- Client ID: `paperless-ngx`
- Name: `Paperless-ngx`
- Protocol: `openid-connect`
- Public Client: `false`
- Standard Flow Enabled: `true`
- Redirect URIs: `https://paperless.your-domain.com/accounts/oidc/callback/`
- Web Origins: `https://paperless.your-domain.com`

### 3. Get Client Secrets
Retrieve the client secrets from Keycloak and update them in `helmfile/environments/edu/secrets.yaml`:

```yaml
secrets:
  keycloak:
    clientSecret:
      mayan: "YOUR_MAYAN_OIDC_SECRET"
      paperless: "YOUR_PAPERLESS_OIDC_SECRET"
  mayan:
    secretKey: "$(openssl rand -hex 64)"
    oidcClientSecret: "YOUR_MAYAN_OIDC_SECRET"
    postgresPassword: "$(openssl rand -hex 32)"
    databasePassword: "$(openssl rand -hex 32)"
    redisPassword: "$(openssl rand -hex 32)"
  paperless:
    secretKey: "$(openssl rand -hex 64)"
    oidcClientSecret: "YOUR_PAPERLESS_OIDC_SECRET"
    adminPassword: "$(openssl rand -hex 32)"
    postgresPassword: "$(openssl rand -hex 32)"
    databasePassword: "$(openssl rand -hex 32)"
    redisPassword: "$(openssl rand -hex 32)"
```

### 4. Enable Applications
Edit `helmfile/environments/edu/ce-overrides.yaml.gotmpl`:

```yaml
apps:
  mayanEdms:
    enabled: true
  paperlessNgx:
    enabled: true
```

### 5. Configure Storage (Optional)
Edit `helmfile/environments/edu/ce-overrides.yaml.gotmpl`:

```yaml
apps:
  mayanEdms:
    storage:
      dataSize: "100Gi"
      mediaSize: "200Gi"
      indexSize: "10Gi"
      databaseSize: "20Gi"
      redisSize: "5Gi"
  paperlessNgx:
    storage:
      dataSize: "200Gi"
      consumeSize: "50Gi"
      databaseSize: "20Gi"
      redisSize: "5Gi"
```

### 6. Configure Resources (Optional)
Edit `helmfile/environments/edu/ce-overrides.yaml.gotmpl`:

```yaml
resources:
  mayan:
    requests:
      cpu: "1"
      memory: "2Gi"
    limits:
      cpu: "2"
      memory: "4Gi"
  mayanPostgresql:
    requests:
      cpu: "500m"
      memory: "512Mi"
    limits:
      cpu: "1"
      memory: "1Gi"
  mayanRedis:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
  paperless:
    requests:
      cpu: "1"
      memory: "2Gi"
    limits:
      cpu: "2"
      memory: "4Gi"
  paperlessPostgresql:
    requests:
      cpu: "500m"
      memory: "512Mi"
    limits:
      cpu: "1"
      memory: "1Gi"
  paperlessRedis:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
```

### 7. Deploy
```bash
# Dry run to verify
helmfile -f helmfile.yaml.gotmpl diff

# Deploy
helmfile -f helmfile.yaml.gotmpl sync
```

### 8. Verify Deployment

#### Check Deployments
```bash
kubectl get deployments -n opendesk | grep -E "(mayan|paperless)"
```
Expected output shows all deployments with READY status.

#### Check Pods
```bash
kubectl get pods -n opendesk | grep -E "(mayan|paperless)"
```
All pods should be in Running state.

#### Check PVCs
```bash
kubectl get pvc -n opendesk | grep -E "(mayan|paperless)"
```
All PVCs should be Bound.

#### Check Services
```bash
kubectl get svc -n opendesk | grep -E "(mayan|paperless)"
```
All services should be available.

#### Check Ingress
```bash
kubectl get ingress -n opendesk | grep -E "(mayan|paperless)"
```
Ingress should show the correct hostnames.

> **Live-Deployment (31.07.2026):** Paperless-ngx läuft unter `dms.opendesk.hrz.uni-marburg.de`
> (nicht `paperless.`). Mayan EDMS noch nicht deployed.

### 9. Access Systems

- **Mayan EDMS**: https://mayan.your-domain.com (noch nicht deployed)
- **Paperless-ngx**: https://dms.opendesk.hrz.uni-marburg.de (live)

> **⚠️ Login (Paperless-ngx 2.12):** OIDC wird von Version 2.12.0 **nicht unterstützt**
> (`PAPERLESS_OIDC_*`-Env wird ignoriert) — Login nur mit lokalem Superuser (`admin`),
> angelegt via `python3 manage.py createsuperuser`.

### 10. Verify Functionality

#### Mayan EDMS
1. Login (OIDC sobald OIDC-fähig)
2. Upload a test document
3. Verify OCR works (if enabled)
4. Create a workflow
5. Test document versioning

#### Paperless-ngx
1. Login mit lokalem Admin-Konto
2. Upload a test document to consume folder
3. Verify OCR works (if enabled)
4. Test email processing (if configured)
5. Test tag-based classification

## Post-Deployment Tasks

### Configure OCR (Optional)
Verify Tesseract languages are installed in the containers.

### Configure Email Processing (Optional for Paperless-ngx)
Set up IMAP access to Stalwart for email-based document submission.

### Configure Backup
Verify k8up backups are running:
```bash
kubectl get backup -n opendesk | grep -E "(mayan|paperless)"
```

### Monitor Resources
Check resource usage:
```bash
kubectl top pods -n opendesk | grep -E "(mayan|paperless)"
```

### Enable Autoscaling (Optional)
Edit `helmfile/environments/edu/ce-overrides.yaml.gotmpl`:
```yaml
apps:
  mayanEdms:
    autoscaling:
      enabled: true
      minReplicas: 1
      maxReplicas: 3
      targetCPU: 70
      targetMemory: 70
  paperlessNgx:
    autoscaling:
      enabled: true
      minReplicas: 1
      maxReplicas: 3
      targetCPU: 70
      targetMemory: 70
```

## Troubleshooting

### Common Issues

#### OIDC Login Fails
- Verify client secret in secrets.yaml
- Check redirect URIs in Keycloak
- Verify host aliases in deployment
- Check network connectivity to Keycloak

#### PVC Not Bound
- Check storage class exists
- Verify sufficient storage available
- Check for conflicting PVCs

#### Pod CrashLoopBackOff
- Check logs: `kubectl logs -n opendesk <pod-name> --previous`
- Verify database connectivity
- Check Redis connectivity
- Verify configuration in ConfigMap

#### Ingress 404 Error
- Check ingress class is correct
- Verify service exists and is running
- Check TLS certificate is available
- Verify DNS resolution

### Debugging Commands

```bash
# View pod logs
kubectl logs -n opendesk deployment/mayan-edms -f
kubectl logs -n opendesk deployment/paperless-ngx -f

# Exec into pod for debugging
kubectl exec -it -n opendesk deployment/mayan-edms -- /bin/bash
kubectl exec -it -n opendesk deployment/paperless-ngx -- /bin/bash

# Test database connectivity (Mayan)
kubectl exec -n opendesk deployment/mayan-edms -- psql -h mayan-edms-postgresql -U mayan -d mayan -c "SELECT 1"

# Test Redis connectivity (Mayan)
kubectl exec -n opendesk deployment/mayan-edms -- redis-cli -h mayan-edms-redis-master -a YOUR_PASSWORD PING
```

## Rollback

To disable the systems:

1. Edit `helmfile/environments/edu/ce-overrides.yaml.gotmpl`:
   ```yaml
   apps:
     mayanEdms:
       enabled: false
     paperlessNgx:
       enabled: false
   ```

2. Deploy:
   ```bash
   helmfile -f helmfile.yaml.gotmpl sync
   ```

**Note**: This will delete the deployments but preserve PVCs (data will be retained).

## Documentation

- **Main Documentation**: `docs/DOCUMENT_MANAGEMENT_SYSTEMS.md`
- **Implementation Summary**: `DOCUMENT_MANAGEMENT_IMPLEMENTATION_SUMMARY.md`
- **Mayan EDMS Chart**: `helmfile/charts/mayan-edms/README.md`
- **Paperless-ngx Chart**: `helmfile/charts/paperless-ngx/README.md`

## Contacts

For support, contact the openDesk Edu team or refer to the official documentation for each system:
- Mayan EDMS: https://docs.mayan-edms.com
- Paperless-ngx: https://paperless-ngx.readthedocs.io

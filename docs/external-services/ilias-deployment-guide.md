# ILIAS Learning Management System - Deployment Guide

## Overview

ILIAS (Integrated Learning, Information and Work Cooperation System) is a powerful open-source Learning Management System (LMS) that can be deployed alongside openDesk with SSO integration via Shibboleth and Keycloak.

## Deployment Summary

- **URL:** <https://lms.opendesk.example.com>
- **Namespace:** `opendesk`
- **Helm Chart:** `helmfile/charts/ilias` (included in this repository)
- **Ingress:** haproxy (LoadBalancer IP assigned by your cloud/provider)

## Architecture

### Kubernetes Components

| Component | Type | Purpose |
|-----------|------|---------|
| `ilias-ilias` | Deployment | Main ILIAS web application |
| `ilias-ilias-ilserver` | Deployment | ILIAS RPC server |
| `ilias-ilias-config` | ConfigMap | ILIAS configuration files |
| `ilias-ilias-secrets` | Secret | Sensitive data (passwords, OIDC config) |
| `ilias-admin-credentials` | Secret | ILIAS admin credentials |
| `ilias-database-credentials` | Secret | Database access credentials |
| `ilias-ilias-*` (3x) | PersistentVolumeClaim | Data storage (4Gi each) |

### Database

- **Type:** MariaDB
- **Host:** `mariadb.opendesk.svc.cluster.local:3306`
- **Database:** `ilias`
- **User:** `ilias`
- **Tables:** 1043
- **Backup:** Manual MySQL dumps (stored in `ilias-mariadb-backup-pvc`)

### SSO Integration

- **Provider:** Keycloak
- **Realm:** `opendesk`
- **Protocol:** OpenID Connect (OIDC)
- **Client ID:** `ilias`
- **Discovery URL:** <https://id.opendesk.example.com/realms/opendesk/.well-known/openid-configuration>

## Access Credentials

### ILIAS Admin

- **Username:** `root`
- **Password:** `<YOUR_ILIAS_ADMIN_PASSWORD>`
- **Login:** <https://lms.opendesk.example.com/login.php>

### Database

- **User:** `ilias`
- **Password:** `<YOUR_ILIAS_DB_PASSWORD>`
- **Root Password:** `<YOUR_MARIADB_ROOT_PASSWORD>`

### Keycloak Admin

- **Username:** `kcadmin`
- **Password:** `<YOUR_KEYCLOAK_ADMIN_PASSWORD>`

## Configuration Files

### Kubernetes Secrets

All sensitive information is stored in Kubernetes secrets:

```bash
# View all ILIAS-related secrets
kubectl get secrets -n opendesk | grep ilias

# Get admin credentials
kubectl get secret ilias-admin-credentials -n opendesk -o yaml

# Get OIDC configuration
kubectl get secret ilias-ilias-secrets -n opendesk -o yaml
```

### ILIAS Client Configuration

The main client configuration is in `/var/www/html/data/default/client.ini.php`:

```ini
[oidc]
oidc_provider = "OpenIDConnect"
oidc_client_id = "ilias"
oidc_client_secret = "<YOUR_OIDC_CLIENT_SECRET>"
oidc_discovery_url = "https://id.opendesk.example.com/realms/opendesk/.well-known/openid-configuration"
oidc_scopes = "openid profile email"
oidc_sync_users = "1"
oidc_auto_provision = "1"
oidc_update_existing = "1"
oidc_debug_mode = "1"
```

## Backup Strategy

### Automated Backups

1. **k8up Backups** (Daily at 00:42)
   - Backs up all PVCs in `opendesk` namespace
   - Storage: S3 (<https://s3.example.com>)
   - Retention: 14 daily, 5 most recent
   - Check: Weekly (Mondays at 02:00)
   - Prune: Weekly (Sundays at 03:00)

2. **MariaDB Backups** (Manual)
   - Stored in `ilias-mariadb-backup-pvc`
   - Contains full MySQL dumps
   - Last backup: ~7 hours ago

### Backup Verification

```bash
# Check backup schedule status
kubectl get schedule backup-live -n opendesk

# Check recent backup jobs
kubectl get backups -n opendesk | tail -5

# Check backup pods
kubectl get pods -n opendesk | grep backup
```

### Restore Procedure

1. Restore PVCs from k8up backup:

   ```bash
   kubectl apply -f <backup-restoration-manifest>.yaml
   ```

2. Restore MariaDB from backup PVC:

   ```bash
   kubectl cp ilias-mariadb-backup-pvc:/path/to/dump.sql /tmp/dump.sql
   kubectl exec -n opendesk mariadb-0 -- mysql -u root -p ilias < /tmp/dump.sql
   ```

## SSO Configuration

### Current Status

✅ **Technically Complete:**

- Keycloak OIDC client created
- ILIAS OIDC configuration persistent
- Discovery endpoint accessible

⚠️ **Manual Step Required:**

- Enable OIDC in ILIAS admin panel

### Steps to Enable SSO

1. Login to ILIAS as root
2. Navigate to: Administration → Authentication → Authentication Methods
3. Find "OpenID Connect" and click Enable
4. Save configuration

### Test SSO

1. Access login page
2. Click "Login with Keycloak" (appears after enabling)
3. Authenticate with Keycloak credentials
4. Verify user creation/access in ILIAS

### Troubleshooting SSO

```bash
# Check ILIAS logs for OIDC errors
kubectl logs -n opendesk deploy/ilias-ilias --tail=50

# Test OIDC discovery endpoint
curl -k "https://id.opendesk.example.com/realms/opendesk/.well-known/openid-configuration"

# Test ILIAS OIDC endpoint
curl -k "https://lms.opendesk.example.com/openidconnect.php"

# Verify OIDC config in ILIAS
kubectl exec -n opendesk deploy/ilias-ilias -- cat /var/www/html/data/default/client.ini.php
```

## Maintenance

### Update ILIAS

1. Update Helm chart:

   ```bash
   helmfile -e default sync
   ```

2. Verify release:

   ```bash
   helm status ilias -n opendesk
   ```

3. Run database migrations (if needed):

   ```bash
   kubectl exec -n opendesk deploy/ilias-ilias -- php setup/cli.php update
   ```

### Reset Root Password

```bash
# Calculate MD5 hash
ILIAS_PASS="newpassword"
HASH=$(echo -n "$ILIAS_PASS" | md5sum | awk '{print $1}')

# Update in database
ILIAS_DB_PASS="<YOUR_ILIAS_DB_PASSWORD>"
kubectl exec -n opendesk mariadb-0 -- mysql -u ilias -p"$ILIAS_DB_PASS" ilias \
  -e "UPDATE usr_data SET passwd='$HASH', passwd_enc_type='md5' WHERE usr_id=6;"
```

### Check Pod Health

```bash
# Get pod status
kubectl get pods -n opendesk -l app.kubernetes.io/name=ilias

# Check logs
kubectl logs -n opendesk deploy/ilias-ilias

# Check events
kubectl get events -n opendesk --field-selector involvedObject.name=ilias-ilias
```

### Scale Resources

```bash
# Scale ILIAS deployment
kubectl scale deployment ilias-ilias -n opendesk --replicas=2

# Scale ILIAS RPC server
kubectl scale deployment ilias-ilias-ilserver -n opendesk --replicas=1
```

## Monitoring

### Logs

```bash
# Real-time log monitoring
kubectl logs -n opendesk deploy/ilias-ilias -f

# Last 100 lines
kubectl logs -n opendesk deploy/ilias-ilias --tail=100

# All pods
kubectl logs -n opendesk -l app.kubernetes.io/name=ilias --tail=50
```

### Metrics

ILIAS does not expose Prometheus metrics by default. Monitor via:

- Pod resource usage: `kubectl top pods -n opendesk`
- Ingress metrics: haproxy dashboard
- Storage: Kubernetes PVC metrics

### Health Checks

1. Check if ILIAS is responding:

   ```bash
   curl -k https://lms.opendesk.example.com/login.php
   ```

2. Check database connectivity:

   ```bash
   kubectl exec -n opendesk deploy/ilias-ilias -- php -r "new mysqli('mariadb.opendesk.svc.cluster.local', 'ilias', '<YOUR_ILIAS_DB_PASSWORD>', 'ilias'); echo 'OK';"
   ```

3. Check OIDC discovery:

   ```bash
   curl -k "https://id.opendesk.example.com/realms/opendesk/.well-known/openid-configuration"
   ```

## Security Considerations

1. **Secrets Management:**
   - All credentials stored in Kubernetes secrets
   - Rotate admin passwords regularly
   - Keep Keycloak client secret secure

2. **Network:**
   - TLS only (auto HTTPS detection enabled)
   - Internal database communication not encrypted
   - Consider network policies for isolated pods

3. **Access Control:**
   - ILIAS role-based access control (RBAC)
   - Keycloak realm-based user management
   - OIDC scopes limit data sharing

4. **Data Privacy:**
   - Auto-provision disabled by default
   - GDPR-compliant user handling
   - Audit logs enabled

## Appendix: Key Commands Reference

```bash
# Get deployment status
kubectl get all -n opendesk -l app.kubernetes.io/name=ilias

# View PVCs
kubectl get pvc -n opendesk | grep ilias

# Check storage usage
kubectl exec -n opendesk deploy/ilias-ilias -- df -h /var/www/html/data

# Restart ILIAS
kubectl rollout restart deployment ilias-ilias -n opendesk

# Access pod shell
kubectl exec -it -n opendesk deploy/ilias-ilias -- /bin/bash

# Port forward to local
kubectl port-forward -n opendesk deploy/ilias-ilias 8080:80

# Get ingress info
kubectl get ingress -n opendesk -l app.kubernetes.io/name=ilias

# View Helm release
helm list -n opendesk | grep ilias
```

## Support

### Documentation

- ILIAS Official: <https://www.ilias.de/docu/>
- ILIAS Installation Guide: <https://docu.ilias.de/goto.php?target=cat_27252_2&client_id=docu>
- OpenID Connect in ILIAS: <https://docu.ilias.de/goto.php?target=cat_298543_2&client_id=docu>

### Contact

For issues with:

- **ILIAS Configuration:** System administrator
- **Keycloak SSO:** System administrator
- **Kubernetes Infrastructure:** Platform team
- **Backup/Restore:** Storage team

# SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0

# User Provisioning Operations Runbook

## Overview

This runbook documents the operational procedures for the openDesk user provisioning system,
including provisioning new users, deprovisioning departed users, and troubleshooting common issues.

## Architecture

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐
│   IAM API /     │────▶│  user_import │────▶│  UCS UDM REST   │
│   CSV Files     │     │   Scripts    │     │     API         │
└─────────────────┘     └──────────────┘     └─────────────────┘
                              │
                              ▼
                        ┌──────────────┐
                        │   Keycloak   │
                        │  (SAML IdP)  │
                        └──────────────┘
```

**Components:**
- `provision.py` - Create new users from CSV/ODS/XLSX files or IAM API
- `deprovision_disable.py` - Disable users no longer in IAM (Phase 1)
- `deprovision_delete.py` - Permanently delete users after grace period (Phase 2)
- `sync_users.py` - Sync user attributes from IAM to UCS
- `archive_service_user.py` - Archive user data before deletion

## Prerequisites

### Required Access

| System | Credential | Purpose |
|--------|-----------|---------|
| UCS UDM REST API | Admin username/password | Create/modify/delete users |
| Keycloak | Admin API credentials | Link SAML identities |
| IAM API | API token (optional) | Fetch user lists |
| Kubernetes | ServiceAccount (for CronJob) | Run scheduled jobs |

### Network Requirements

- Outbound HTTPS to UCS UDM API (`https://ucs.{domain}/udm/`)
- Outbound HTTPS to Keycloak (`https://id.{domain}/`)
- Outbound HTTPS to IAM API (if used)
- IPv4 enforcement may be required for some UCS installations

## Configuration

### Environment Variables (Required)

```bash
# Domain configuration
IMPORT_DOMAIN="example.com"           # Your openDesk domain
IMPORT_MAILDOMAIN="example.com"       # Mail domain (defaults to IMPORT_DOMAIN)

# UCS credentials
UDM_API_USERNAME="Administrator"
UDM_API_PASSWORD="<secret>"

# Keycloak credentials
KEYCLOAK_URL="https://id.example.com"
KEYCLOAK_API_USERNAME="admin"
KEYCLOAK_API_PASSWORD="<secret>"
IDENTITY_PROVIDER="saml-umr"          # SAML IdP alias in Keycloak

# Optional: IAM API
IAM_API_URL="https://iam-api.example.com/openDesk/v1.0/openDesk_account_depro"

# Logging
LOGLEVEL="INFO"                       # DEBUG, INFO, WARNING, ERROR
LOGPATH="/var/log/user-provisioning"
```

### Secrets Management

**For Docker:**
```bash
docker run --rm \
  -e IMPORT_DOMAIN=example.com \
  -e UDM_API_PASSWORD="$(cat /run/secrets/udm-password)" \
  -e KEYCLOAK_API_PASSWORD="$(cat /run/secrets/keycloak-password)" \
  opendesk-user-import:latest
```

**For Kubernetes:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: user-provisioning-secrets
type: Opaque
stringData:
  udm-api-password: "secret-password"
  keycloak-api-password: "secret-password"
  iam-api-token: "secret-token"
```

## Operations

### Provisioning New Users

**Scenario:** New semester starts, import 500 students from CSV.

```bash
# Using Docker
docker run --rm \
  -e IMPORT_DOMAIN=example.com \
  -e UDM_API_PASSWORD=secret \
  -e KEYCLOAK_API_PASSWORD=secret \
  -v ./users-semester-2026.csv:/data/users.csv \
  opendesk-user-import:latest \
  python provision.py \
    --import_filename /data/users.csv \
    --reconcile_groups \
    --create_admin_accounts

# Using Kubernetes CronJob (on-demand execution)
kubectl create job manual-provision \
  --from=cronjob/user-provisioning \
  --env=IMPORT_FILENAME=users-semester-2026.csv
```

**Expected Output:**
```
INFO: Loaded 500 users from CSV
INFO: Created 485 new users in UCS
INFO: Updated 15 existing users
INFO: Created 500 admin accounts
INFO: Linked 500 SAML identities in Keycloak
INFO: Provisioning complete: 500 users processed
```

### Deprovisioning Departed Users

**Scenario:** Semester ends, remove users who left the institution.

**Phase 1: Disable (immediate)**
```bash
docker run --rm \
  -e IMPORT_DOMAIN=example.com \
  -e UDM_API_PASSWORD=secret \
  -e KEYCLOAK_API_PASSWORD=secret \
  -e IAM_API_URL=https://iam-api.example.com/... \
  opendesk-user-import:latest \
  python deprovision_disable.py \
    --dry_run  # First run in dry-run mode
```

Review the dry-run output, then run without `--dry_run`:
```bash
docker run --rm ... opendesk-user-import:latest \
  python deprovision_disable.py
```

**Phase 2: Delete (after grace period)**
```bash
docker run --rm \
  -e IMPORT_DOMAIN=example.com \
  -e UDM_API_PASSWORD=secret \
  opendesk-user-import:latest \
  python deprovision_delete.py \
    --grace_period_months 12 \
    --dry_run  # First run in dry-run mode
```

### Scheduled Execution (CronJob)

Deploy the provided CronJob manifest:

```bash
kubectl apply -f kubernetes/user-provisioning-cronjob.yaml
```

**Schedule:**
- Provisioning: Manual (triggered by admin)
- Deprovision disable: Daily at 02:00
- Deprovision delete: Weekly on Sunday at 03:00

## Monitoring

### Health Checks

```bash
# Check last run status
kubectl get jobs user-provisioning -o jsonpath='{.status.succeeded}'

# View recent logs
kubectl logs job/user-provisioning --tail=100

# Check for errors
kubectl logs job/user-provisioning | grep -i error
```

### Metrics (Prometheus)

| Metric | Description |
|--------|-------------|
| `user_provisioning_runs_total` | Total provisioning runs |
| `user_provisioning_users_created` | Users created in last run |
| `user_provisioning_users_disabled` | Users disabled in last run |
| `user_provisioning_users_deleted` | Users deleted in last run |
| `user_provisioning_errors_total` | Total errors |
| `user_provisioning_duration_seconds` | Run duration |

### Alerting Rules

```yaml
groups:
  - name: user-provisioning
    rules:
      - alert: UserProvisioningFailed
        expr: user_provisioning_errors_total > 0
        for: 5m
        annotations:
          summary: "User provisioning job failed"
          
      - alert: UserProvisioningStale
        expr: time() - user_provisioning_last_run_timestamp > 86400
        for: 1h
        annotations:
          summary: "No provisioning run in 24 hours"
```

## Troubleshooting

### Issue: UCS API Connection Failed

**Symptoms:**
```
ERROR: Failed to connect to UDM API: Connection refused
```

**Resolution:**
1. Verify UCS is reachable: `curl -k https://ucs.{domain}/udm/`
2. Check firewall rules allow outbound HTTPS
3. Try IPv4 enforcement: `--enforce_ipv4`
4. Verify credentials are correct

### Issue: SAML Identity Already Exists

**Symptoms:**
```
ERROR: SAML identity 'user123' already linked to different UCS user
```

**Resolution:**
1. Check for duplicate users in UCS: Search by username
2. Manually unlink the identity in Keycloak admin console
3. Re-run provisioning

### Issue: Keycloak API Timeout

**Symptoms:**
```
ERROR: Keycloak API request timed out after 30s
```

**Resolution:**
1. Check Keycloak cluster health
2. Increase timeout in script (modify `KEYCLOAK_TIMEOUT`)
3. Run during off-peak hours

### Issue: Grace Period Users Being Deleted Prematurely

**Symptoms:**
```
WARNING: User 'user123' deleted but should still be in grace period
```

**Resolution:**
1. Check `deprovisioned_date` attribute in UCS
2. Verify `--grace_period_months` parameter
3. Review deprovision_disable.py logs for the disable timestamp

## Security

### Credential Rotation

Rotate credentials quarterly:
1. Update secret in Kubernetes: `kubectl create secret generic ... --dry-run=client -o yaml | kubectl apply -f -`
2. Restart running CronJobs: `kubectl delete pod -l app=user-provisioning`
3. Verify new credentials work with a test run

### Audit Logging

All operations are logged to:
- Console output (captured by Kubernetes)
- Log file at `$LOGPATH/` (if mounted)
- UCS audit log (for user changes)
- Keycloak admin events (for SAML changes)

Review logs monthly for anomalies.

## Disaster Recovery

### Scenario: Accidental Mass Deletion

**Immediate Actions:**
1. Stop all provisioning jobs: `kubectl scale cronjob user-provisioning --replicas=0`
2. Restore users from UCS backup
3. Re-run provisioning with `--import_filename` to restore from source of truth

### Scenario: Credential Compromise

**Immediate Actions:**
1. Rotate all affected credentials immediately
2. Review audit logs for unauthorized access
3. Update secrets in Kubernetes
4. Document incident

## Contact

- Technical Support: <support-email>
- On-Call: <on-call-contact>
- Documentation: `docs/user-provisioning.md`

---

**Version:** 1.0  
**Last Updated:** 2026-07-09  
**Owner:** openDesk Operations Team

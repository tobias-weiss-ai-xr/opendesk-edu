# Disaster Recovery Guide

This guide provides step-by-step procedures for recovering openDesk Edu from various failure scenarios.

## Overview

**Recovery Objectives (RTO/RPO):**

| Service | RTO (Recovery Time) | RPO (Data Loss) | Backup Frequency |
|---------|---------------------|------------------|-----------------|
| Keycloak | 1 hour | 1 hour | Hourly |
| ILIAS | 4 hours | 24 hours | Daily |
| Moodle | 4 hours | 24 hours | Daily |
| Nextcloud | 2 hours | 1 hour | Hourly |
| BBB | 2 hours | Recording loss | Weekly |
| Provisioning Data | 1 hour | 1 day | Daily |
| Helm Charts | 1 hour | Latest | Daily |

## Prerequisites

### Before Disaster Recovery

1. **Verify Backup Availability:**
   ```bash
   # List available backups
   /opt/opendesk-edu/scripts/backup.sh list

   # Verify backup integrity
   /opt/opendesk-edu/scripts/restore.sh verify /backups/opendesk/opendesk_full_backup_20260406_120000.tar.gz
   ```

2. **Prepare Recovery Environment:**
   ```bash
   # Check Kubernetes cluster health
   kubectl cluster-info
   kubectl get nodes

   # Verify storage capacity
   df -h
   kubectl get pv
   ```

3. **Document Current State:**
   ```bash
   # Capture current state
   kubectl get all --all-namespaces > pre-recovery-state.txt
   ```

### Required Tools

- `kubectl` - Kubernetes CLI
- `helm` - Helm package manager
- `tar` - Archive extraction
- `jq` - JSON processor
- `rsync` - File synchronization
- `sops` - Secrets encryption/decryption (v1.1+)
- `age` or `gpg` - Key-based decryption for SOPS (v1.1+)

### v1.1 Prerequisites

Before restoring v1.1 services, verify the following additional assets are available:

1. **SOPS Private Key Recovery:**
   ```bash
   # Check if age private key exists (SOPS v1.1 encryption)
   ls -la /etc/opendesk/sops-age-key.txt
   # Or check for GnuPG key
   gpg --list-secret-keys

   # If missing, restore from secure backup
   # age private key stored in: /etc/opendesk/sops-age-key.txt (backup this file!)
   ```

2. **Backchannel Logout Configuration:**
   ```bash
   # Verify Keycloak client attributes include backchannel URLs
   # Reference configuration: helmfile/environments/default/backchannel-logout.yaml.gotmpl
   ```

3. **User Provisioning Manifests:**
   - CronJob definitions: `scripts/user_import/kubernetes/cronjob.yaml`
   - RBAC configuration: `scripts/user_import/kubernetes/rbac.yaml`
   - Secrets template: `scripts/user_import/kubernetes/secrets.yaml.template`
   - Operations runbook: `scripts/user_import/OPERATIONS_RUNBOOK.md`

## Recovery Scenarios

### Scenario 1: Single Service Failure

**Examples:**
- ILIAS database corruption
- Moodle application crash
- Nextcloud storage failure

**Recovery Steps:**

1. **Identify Failed Service:**
   ```bash
   # Check pod status
   kubectl get pods -n <namespace>

   # Check pod logs
   kubectl logs -f <pod-name> -n <namespace>

   # Describe pod for details
   kubectl describe pod <pod-name> -n <namespace>
   ```

2. **Select Appropriate Backup:**
   ```bash
   # List backups
   /opt/opendesk-edu/scripts/backup.sh list

   # Choose latest backup before failure
   ```

3. **Restore Single Service:**
   ```bash
   # Restore ILIAS
   /opt/opendesk-edu/scripts/restore.sh services \
     /backups/opendesk/opendesk_full_backup_20260406_120000.tar.gz

   # Restore Keycloak
   /opt/opendesk-edu/scripts/restore.sh keycloak \
     /backups/opendesk/opendesk_full_backup_20260406_120000.tar.gz
   ```

4. **Validate Recovery:**
   ```bash
   # Check pod health
   kubectl get pods -n <namespace>

   # Check logs for errors
   kubectl logs -f <pod-name> -n <namespace>

   # Test service access
   curl -I https://<service-url>
   ```

### Scenario 2: Complete Cluster Failure

**Examples:**
- Kubernetes master node failure
- Network partition
- Power outage

**Recovery Steps:**

1. **Assess Cluster State:**
   ```bash
   # Check cluster connectivity
   kubectl cluster-info

   # Check node status
   kubectl get nodes -o wide

   # Check etcd health (if accessible)
   etcdctl endpoint health
   ```

2. **Recover Cluster Infrastructure:**
   - Follow Kubernetes cluster recovery procedures
   - Restore master nodes from backups
   - Verify etcd cluster health
   - Restart worker nodes

3. **Restore Kubernetes Configuration:**
   ```bash
   # Restore PVC configurations
   kubectl apply -f /backups/opendesk/pvcs_20260406_120000.yaml

   # Restore Helm releases
   /opt/opendesk-edu/scripts/restore.sh restore \
     /backups/opendesk/opendesk_full_backup_20260406_120000.tar.gz
   ```

4. **Re-deploy Services (if needed):**
   ```bash
   # Re-deploy using helmfile
   cd helmfile
   helmfile -e default apply

   # Monitor deployment status
   kubectl get pods --all-namespaces -w
   ```

### Scenario 3: Data Loss / Corruption

**Examples:**
- Database corruption
- Accidental data deletion
- Ransomware attack

**Recovery Steps:**

1. **Assess Extent of Data Loss:**
   ```bash
   # Identify affected services
   kubectl get pods --all-namespaces | grep -i error

   # Check database integrity
   kubectl exec -n <namespace> <pod> -- \
     bash -c "mariadb-dump --check-only <database>"
   ```

2. **Stop Affected Services:**
   ```bash
   # Scale down to zero
   kubectl scale deployment <deployment> -n <namespace> --replicas=0

   # Or delete pods
   kubectl delete pods -n <namespace> -l app=<app>
   ```

3. **Restore Data from Backup:**
   ```bash
   # Full restore
   /opt/opendesk-edu/scripts/restore.sh restore \
     /backups/opendesk/opendesk_full_backup_20260406_120000.tar.gz

   # Selective restore
   /opt/opendesk-edu/scripts/restore.sh provisioning \
     /backups/opendesk/opendesk_full_backup_20260406_120000.tar.gz
   ```

4. **Validate Data Integrity:**
   ```bash
   # Check database consistency
   kubectl exec -n <namespace> <pod> -- \
     bash -c "mariadb-check <database>"

   # Verify user access
   curl -u admin:password https://keycloak.yourdomain.de/admin

   # Test critical workflows
   # - Login
   # - Course access
   # - File uploads
   ```

### Scenario 4.5: Backchannel Logout / User Provisioning Failure (v1.1)

**Examples:**
- Keycloak client configurations missing backchannel.logout.url
- User provisioning CronJobs not executing
- SOPS-encrypted secrets corrupted or missing

**Recovery Steps:**

1. **Assess v1.1 Feature State:**
   ```bash
   # Check backchannel logout client configs
   kubectl get configmap -n keycloak -l app.kubernetes.io/component=keycloak-config

   # Check user provisioning pods
   kubectl get cronjobs -n provisioning

   # Check SOPS encrypted secrets
   sops --decrypt helmfile/secrets/secrets.prod.enc.yaml > /dev/null 2>&1 || echo "SOPS KEY MISSING"
   ```

2. **Restore Backchannel Logout Configuration:**
   ```bash
   # Re-apply backchannel logout configuration
   cd helmfile
   helmfile -e default apply --selector app=keycloak

   # Verify client attributes in Keycloak admin UI:
   #   - ilias-saml: must have backchannel.logout.url
   #   - opencloud: must have backchannel_logout endpoint
   #   - nextcloud: must have user_oidc backchannel-logout endpoint
   ```

3. **Restore User Provisioning Infrastructure:**
   ```bash
   # Re-apply provisioning manifests
   kubectl apply -f scripts/user_import/kubernetes/rbac.yaml
   kubectl apply -f scripts/user_import/kubernetes/secrets.yaml
   kubectl apply -f scripts/user_import/kubernetes/cronjob.yaml

   # Verify CronJobs are running
   kubectl get cronjobs -n provisioning
   ```

4. **Recover SOPS Private Key (if needed):**
   ```bash
   # Restore age key from secure backup
   cp /backups/opendesk/sops-age-key-backup.txt /etc/opendesk/sops-age-key.txt
   chmod 600 /etc/opendesk/sops-age-key.txt

   # Verify decryption works
   sops --decrypt helmfile/secrets/secrets.prod.enc.yaml > /dev/null && echo "SOPS OK"
   ```

5. **Validate v1.1 Features:**
   ```bash
   # Test backchannel logout
   # Log in to 2+ services, perform global logout, verify all sessions terminated

   # Test user provisioning dry-run
   kubectl create job --from=cronjob/user-provisioning-sync --dry-run=client test-sync

   # Verify SOPS decryption in CI/CD
   sops --decrypt helmfile/secrets/secrets.prod.enc.yaml | grep -q "keycloak" && echo "Secrets OK"
   ```

---

### Scenario 5: Ransomware Attack

**Recovery Steps:**

1. **Immediate Containment:**
   ```bash
   # Shut down all services
   kubectl scale deployment --all-namespaces --all --replicas=0

   # Disconnect from network if needed
   # Isolate backup storage
   ```

2. **Assess Damage:**
   ```bash
   # Check for encrypted files
   find /var/lib -name "*.enc"

   # Check backup integrity
   /opt/opendesk-edu/scripts/restore.sh verify <backup-file>

   # Scan for malware
   kubectl run malware-scan --image=quay.io/security-scanner
   ```

3. **Restore from Clean Backup:**
   ```bash
   # Ensure backup is clean (verify offline)
   # Perform clean cluster rebuild if needed

   # Restore from verified backup
   /opt/opendesk-edu/scripts/restore.sh restore \
     /backups/opendesk/clean_backup_20260406_120000.tar.gz
   ```

4. **Post-Recovery Security:**
   ```bash
   # Change all admin passwords
   # Rotate all secrets
   # Revoke and re-issue certificates
   # Update all dependencies
   ```

## Recovery Order of Operations

**Dependencies:**
```
1. Keycloak (Identity Provider) - CRITICAL
2. Databases (MariaDB, PostgreSQL) - CRITICAL
3. Storage (PVCs) - HIGH
4. Services (ILIAS, Moodle, Nextcloud) - HIGH
5. Monitoring (Prometheus, Grafana) - MEDIUM
6. Provisioning Data - MEDIUM
7. Helm Charts - LOW (metadata only)
```

**Restore Order:**
1. Restore SOPS private key (age/GPG — required before secrets decryption)
2. Restore storage/PVCs first
3. Restore Keycloak (all services depend on SSO)
4. Restore databases
5. Restore service applications
6. Restore backchannel logout configuration (Keycloak client attributes)
7. Restore user provisioning infrastructure (CronJobs, RBAC, secrets)
8. Restore provisioning data
9. Restart monitoring
10. Validate all services including v1.1 features

## Pre-Recovery Checklist

- [ ] Verify backup availability and integrity
- [ ] Confirm backup timestamp is acceptable (within RPO)
- [ ] Check Kubernetes cluster status
- [ ] Verify sufficient storage for restore
- [ ] Document current state
- [ ] Notify stakeholders of expected downtime
- [ ] Prepare rollback plan
- [ ] Test restore procedure (if possible)

## Post-Recovery Checklist

- [ ] Verify all services are running
- [ ] Check pod status (Running, Ready)
- [ ] Verify service connectivity
- [ ] Test login flow (Keycloak SSO)
- [ ] Test critical workflows:
  - [ ] User authentication
  - [ ] Course access (ILIAS, Moodle)
  - [ ] File sharing (Nextcloud)
  - [ ] Video conferencing (BBB)
  - [ ] Backchannel logout (v1.1) — log out from one service, verify all sessions terminated
  - [ ] User provisioning sync (v1.1) — verify CronJobs running and executing
- [ ] Verify data integrity:
  - [ ] Database consistency
  - [ ] User accounts
  - [ ] Course enrollments
  - [ ] File storage
- [ ] Check logs for errors
- [ ] Monitor system performance
- [ ] Update documentation with lessons learned
- [ ] Notify stakeholders of recovery completion

## Testing Recovery Procedures

### Monthly Recovery Tests

**Test Scope:**
- Single service restore (ILIAS, Moodle, Nextcloud)
- Keycloak restore
- Provisioning data restore

**Procedure:**
1. Create test namespace
2. Restore service to test namespace
3. Validate restored data
4. Clean up test namespace

**Documentation:**
```bash
# Record test results
echo "$(date) | Monthly DR Test | Service: ILIAS | Success: YES" >> /var/log/dr-tests.log
```

### Annual Full Disaster Recovery Exercise

**Test Scope:**
- Complete cluster failure simulation
- Full restore from backups
- Validation of all services

**Procedure:**
1. Schedule maintenance window (8+ hours)
2. Create full cluster backup
3. Simulate cluster failure (optional)
4. Perform full cluster restore
5. Validate all services and data
6. Document performance metrics
7. Update RTO/RPO based on actual recovery times

## Communication Procedures

### Pre-Recovery Notification

**Stakeholders:**
- IT Director
- University leadership
- Department heads
- Service users (via email/notification system)

**Notification Template:**
```
Subject: Maintenance Alert - System Recovery

Dear openDesk Edu Users,

We are performing emergency system recovery starting at [TIME].
Expected duration: [DURATION].

Services affected:
- Login/Authentication
- Course Management (ILIAS, Moodle)
- File Sharing (Nextcloud)
- Video Conferencing (BBB)

We apologize for the inconvenience and will provide updates as available.

IT Support
```

### Recovery Progress Updates

**Update Frequency:** Every 30 minutes during recovery

**Status Levels:**
- **IN PROGRESS** - Recovery operations in progress
- **PARTIAL** - Some services restored
- **COMPLETE** - All services restored
- **FAILED** - Recovery failed, escalation required

### Post-Recovery Announcement

**Template:**
```
Subject: Recovery Complete - Services Restored

Dear openDesk Edu Users,

System recovery is now complete. All services are fully operational:
- Login/Authentication: ✓
- Course Management: ✓
- File Sharing: ✓
- Video Conferencing: ✓

Please report any issues to IT Support.

IT Support
```

## Roles and Responsibilities

| Role | Responsibilities | Contact |
|------|------------------|----------|
| IT Director | Authorize recovery, communicate to leadership | phone: +49-xxx-xxx |
| SysAdmin | Execute recovery procedures | email: it-support@university.de |
| Database Admin | Restore databases, verify integrity | email: dba@university.de |
| Network Admin | Ensure network connectivity during recovery | email: netadmin@university.de |
| Service Owner | Validate service functionality after recovery | varies by service |
| Security Officer | Monitor for security incidents during recovery | email: security@university.de |

## Emergency Contacts

**Primary:**
- IT Director: +49-xxx-xxx-xxxx
- SysAdmin On-Call: +49-xxx-xxx-xxxx

**Secondary:**
- Data Center: +49-xxx-xxx-xxxx
- Vendor Support: varies by vendor

**Escalation Path:**
1. Local SysAdmin
2. IT Director
3. Vice President IT
4. President/Chancellor

## Dependencies and Interdependencies

**Service Dependencies:**
```
Keycloak (SSO)
  ├─> ILIAS
  ├─> Moodle
  ├─> Nextcloud
  ├─> BBB
  └─> OpenCloud

Databases
  ├─> Keycloak (PostgreSQL)
  ├─> ILIAS (MariaDB)
  ├─> Moodle (MariaDB)
  └─> Nextcloud (MariaDB)

Storage (PVCs)
  ├─> Databases
  ├─> User Data
  └─> Archives
```

**Critical Path Analysis:**
1. Without Keycloak → No user access to any service
2. Without Databases → No data persistence
3. Without Storage → No application startup
4. Without Network → No cluster connectivity

## Common Issues and Solutions

### Issue: Backup Not Found

**Symptoms:**
```
ERROR: Backup file not found: /backups/opendesk/opendesk_full_backup_20260406_120000.tar.gz
```

**Solutions:**
1. Check backup directory: `ls -la /backups/opendesk/`
2. Verify BACKUP_DIR environment variable
3. Check backup log: `cat /var/log/opendesk-backup.log`
4. Restore from offsite backup if local backup missing

### Issue: Corrupted Backup

**Symptoms:**
```
ERROR: Backup file is corrupted
```

**Solutions:**
1. Verify with tar: `tar -tzf backup.tar.gz`
2. Try previous backup
3. Check if partial restore possible
4. Restore from offsite backup

### Issue: Service Won't Start After Restore

**Symptoms:**
- Pod in CrashLoopBackOff
- Service not accessible
- Database connection errors

**Solutions:**
1. Check pod logs: `kubectl logs <pod> -n <namespace>`
2. Check pod events: `kubectl describe pod <pod> -n <namespace>`
3. Verify PVC mounted: `kubectl describe pod <pod> -n <namespace> | grep Mounts`
4. Check resource limits: `kubectl describe pod <pod> -n <namespace> | grep Requests`
5. Restart service: `kubectl rollout restart deployment/<app> -n <namespace>`

### Issue: Keycloak SSO Not Working

**Symptoms:**
- Cannot login to any service
- "Invalid Redirect URI" errors
- SAML/OIDC errors

**Solutions:**
1. Check Keycloak status: `kubectl get pods -n keycloak`
2. Check Keycloak logs: `kubectl logs -n keycloak <keycloak-pod>`
3. Verify realm configuration in Keycloak admin UI
4. Check SAML/OIDC client configurations
5. Restart Keycloak: `kubectl rollout restart deployment/keycloak -n keycloak`

### Issue: Backchannel Logout Not Working (v1.1)

**Symptoms:**
- Logging out of one service does not terminate other sessions
- Sessions remain active after global logout

**Solutions:**
1. Verify Keycloak client attributes include `backchannel.logout.url`:
   ```bash
   kubectl get configmap keycloak-config -n keycloak -o yaml | grep backchannel.logout.url
   ```
2. Check ILIAS SAML client specifically has backchannel.logout.url (Gap 4 fix)
3. Verify backchannel handler files are mounted in pods:
   ```bash
   kubectl exec -it <pod> -n <namespace> -- ls -la /path/to/backchannel-handler
   ```
4. Check application logs for incoming SAML LogoutRequests:
   ```bash
   kubectl logs -n ilias <pod> | grep -i "logout\|SAMLRequest"
   ```
5. Redeploy backchannel configuration:
   ```bash
   cd helmfile && helmfile -e default apply --selector app=keycloak
   ```

### Issue: SOPS Encryption Key Missing (v1.1)

**Symptoms:**
```
sops: could not find any age key for given fingerprints
sops: could not find any GPG key for given fingerprints
```

**Solutions:**
1. Verify age private key location: `ls -la /etc/opendesk/sops-age-key.txt`
2. Verify GPG key existence: `gpg --list-secret-keys`
3. Restore from secure backup:
   ```bash
   # age key
   cp /backups/opendesk/sops-age-key-backup.txt /etc/opendesk/sops-age-key.txt

   # GPG key
   gpg --import /backups/opendesk/private-gpg-key.asc
   ```
4. If no backup exists, re-encrypt all secrets with a new key:
   ```bash
   age-keygen -o /etc/opendesk/sops-age-key.txt
   sops --encrypt --age $(cat /etc/opendesk/sops-age-key.txt | grep public | cut -d: -f2) \
     helmfile/secrets/secrets.prod.enc.yaml
   ```

### Issue: User Provisioning CronJobs Not Running (v1.1)

**Symptoms:**
- `kubectl get cronjobs -n provisioning` shows no resources
- User imports/exports not executing on schedule

**Solutions:**
1. Check provisioning namespace exists: `kubectl get ns provisioning`
2. Re-apply provisioning manifests:
   ```bash
   kubectl apply -f scripts/user_import/kubernetes/rbac.yaml
   kubectl apply -f scripts/user_import/kubernetes/secrets.yaml
   kubectl apply -f scripts/user_import/kubernetes/cronjob.yaml
   ```
3. Verify secrets exist:
   ```bash
   kubectl get secrets -n provisioning
   ```
4. Create test job to validate:
   ```bash
   kubectl create job --from=cronjob/user-provisioning-sync -n provisioning test-sync
   kubectl logs -n provisioning job/test-sync
   ```

## Performance Tuning for Recovery

**Speed Up Restore:**
1. **Parallel Restore:**
   ```bash
   # Restore multiple services in parallel
   /opt/opendesk-edu/scripts/restore.sh ilias backup.tar &
   /opt/opendesk-edu/scripts/restore.sh moodle backup.tar &
   /opt/opendesk-edu/scripts/restore.sh nextcloud backup.tar &
   wait
   ```

2. **Increase Database Performance:**
   ```bash
   # Scale up database during restore
   kubectl scale deployment mariadb -n <namespace> --replicas=1
   ```

3. **Use Faster Storage:**
   - Restore to faster storage (SSD vs HDD)
   - Copy to production storage after restore

## Compliance and Legal Considerations

**GDPR Requirements:**
- Document all data recovery actions
- Notify affected users of data loss
- Provide data subject access requests
- Maintain backup logs for audit trail

**Academic Freedom:**
- Preserve faculty research data
- Protect course materials
- Maintain continuity of teaching

## Appendix: Sample Recovery Timeline

**Scenario: ILIAS Database Failure**

| Time | Action | Owner |
|------|--------|--------|
| 00:00 | Incident reported | User |
| 00:05 | Assess damage, notify stakeholders | SysAdmin |
| 00:15 | Stop ILIAS service | SysAdmin |
| 00:20 | Select backup, verify integrity | SysAdmin |
| 00:25 | Restore ILIAS database | SysAdmin |
| 00:45 | Restart ILIAS service | SysAdmin |
| 00:50 | Validate data integrity | DBA |
| 01:00 | Test course access | Service Owner |
| 01:15 | Notify users of recovery | IT Director |
| 01:30 | Document incident, lessons learned | All |

**Total RTO: 1.5 hours (within target of 4 hours)**

## Support and Resources

**Documentation:**
- Backup Scripts: `/opt/opendesk-edu/scripts/backup.sh`
- Restore Scripts: `/opt/opendesk-edu/scripts/restore.sh`
- Archive Retention: `docs/archive-retention.md`
- Monitoring: `docs/monitoring-setup.md`

**Logs:**
- Backup Log: `/var/log/opendesk-backup.log`
- Restore Log: `/var/log/opendesk-restore.log`
- Service Logs: `kubectl logs <pod> -n <namespace>`

**External Resources:**
- Kubernetes Recovery: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/
- MariaDB Recovery: https://mariadb.com/kb/en/library/
- PostgreSQL Recovery: https://www.postgresql.org/docs/current/backup.html

---

Last Updated: 2026-07-10
Version: 1.1

## v1.1 Feature Recovery Summary

This section provides a quick-reference for recovering v1.1-specific features:

| Feature | Key Files | Recovery Priority |
|---------|-----------|------------------|
| SOPS Secrets Encryption | `helmfile/secrets/*.enc.yaml`, `/etc/opendesk/sops-age-key.txt` | P0 — required before secrets decryption |
| Backchannel Logout | `helmfile/environments/default/backchannel-logout.yaml.gotmpl`, Keycloak client attributes | P1 — must restore with Keycloak config |
| User Provisioning | `scripts/user_import/kubernetes/cronjob.yaml`, `rbac.yaml`, `secrets.yaml.template` | P2 — restore after core services |
| DFN-AAI Federation | `docs/dfn-aai-keycloak-integration.md`, SP metadata registration | P2 — restore IdP config with Keycloak
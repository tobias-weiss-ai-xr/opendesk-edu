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

### Scenario 4: Ransomware Attack

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

1. Restore storage/PVCs first
2. Restore Keycloak (all services depend on SSO)
3. Restore databases
4. Restore service applications
5. Restore provisioning data
6. Restart monitoring
7. Validate all services

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
| SysAdmin | Execute recovery procedures | email: <it-support@university.de> |
| Database Admin | Restore databases, verify integrity | email: <dba@university.de> |
| Network Admin | Ensure network connectivity during recovery | email: <netadmin@university.de> |
| Service Owner | Validate service functionality after recovery | varies by service |
| Security Officer | Monitor for security incidents during recovery | email: <security@university.de> |

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

- Kubernetes Recovery: <https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/>
- MariaDB Recovery: <https://mariadb.com/kb/en/library/>
- PostgreSQL Recovery: <https://www.postgresql.org/docs/current/backup.html>

---

Last Updated: 2026-04-06
Version: 1.0

# Backup & Disaster Recovery — openDesk Edu

## Current Infrastructure

**Backup tool:** k8up (Kubernetes backup operator)
**Storage:** S3-compatible (MinIO on-cluster + S3 at s3.hrz.uni-marburg.de)
**Schedule:** Daily backups via k8up Schedule CRD

## What's Backed Up

k8up automatically backs up all PVCs with the label `k8up/backup: "true"`.
PVCs with `k8up.io/exclude: "true"` are excluded (RWO volumes that can't be
mounted by the backup pod).

### Currently Excluded (RWO limitation)
These 29 RWO PVCs are annotated with `k8up.io/exclude: "true"`:
- All database PVCs (mariadb, postgresql, redis, etc.)
- All application data PVCs (ilias, moodle, bookstack, etc.)

### Currently Included (RWX only)
Only RWX PVCs can be backed up by k8up:
- `clamav-db` (clamav virus definitions)
- `clamav-tmp` (clamav temp storage)
- `dovecot` (mail storage)
- `opendesk-opencloud-data` (OpenCloud files)
- `seaweedfs-all-in-one-data` (SeaweedFS storage)
- `slidev-slides` (presentations)

## Restore Procedure

### Prerequisites
```bash
# k8up CLI (from the k8up pod)
kubectl exec -n opendesk deploy/k8up -- /usr/local/bin/k8up --help

# Or use the k8up binary
kubectl run -n opendesk k8up-restore --image=ghcr.io/k8up-io/k8up:v2.13.1 --rm -it -- sh
```

### List Available Backups
```bash
kubectl exec -n opendesk deploy/k8up -- /usr/local/bin/k8up restic \
  -g opendesk list snapshots
```

### Restore a Single PVC
```bash
# Create a restore Schedule
cat <<EOF | kubectl apply -f -
apiVersion: k8up.io/v1
kind: Restore
metadata:
  name: restore-ilias-mariadb
  namespace: opendesk
spec:
  restoreMethod:
    folder:
      claimName: data-ilias-mariadb-0
  snapshot: latest
  backend:
    repoPasswordSecretRef:
      name: k8up-repo-password
    s3:
      bucket: opendesk-backup
      endpoint: s3.hrz.uni-marburg.de
      accessKeyIDSecretRef:
        name: minio-credentials-live
        key: username
      secretAccessKeySecretRef:
        name: minio-credentials-live
        key: password
EOF
```

### Full Disaster Recovery

**Scenario:** Complete cluster loss. All PVCs, configs, and Helm releases gone.

```bash
# 1. Rebuild cluster (K3s)
curl -sfL https://get.k3s.io | sh -

# 2. Restore k8up first (it needs to be running to restore everything else)
kubectl apply -f helmfile/charts/k8up/

# 3. Restore MinIO (it contains other backups)
kubectl apply -f helmfile/charts/minio/

# 4. Restore databases from S3
for db in ilias-mariadb bookstack-mariadb postgresql redis; do
  kubectl apply -f - <<EOF
apiVersion: k8up.io/v1
kind: Restore
metadata:
  name: restore-$db
  namespace: opendesk
spec:
  restoreMethod:
    folder:
      claimName: data-$db-0
  snapshot: latest
  backend:
    repoPasswordSecretRef:
      name: k8up-repo-password
    s3:
      bucket: opendesk-backup
      endpoint: s3.hrz.uni-marburg.de
      accessKeyIDSecretRef:
        name: minio-credentials-live
        key: username
      secretAccessKeySecretRef:
        name: minio-credentials-live
        key: password
EOF
done

# 5. Restore application data (ILIAS, Moodle, etc.)
#    These are RWO and were excluded from k8up. Alternative backup needed.
#    See "RWO PVC Backup Strategy" below.
```

## Gaps & Workarounds

### RWO PVC Backup Strategy

k8up cannot back up RWO PVCs because the backup pod can't mount them while
they're attached to running pods. Solutions:

**Option A: CSI Snapshots (recommended)**
```bash
# Requires VolumeSnapshot CRDs and a CSI driver that supports snapshots
# Ceph CSI supports this
kubectl apply -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: ilias-mariadb-snapshot-$(date +%Y%m%d)
  namespace: opendesk
spec:
  volumeSnapshotClassName: ceph-rbd-ssd
  source:
    persistentVolumeClaimName: data-ilias-mariadb-0
EOF
```

**Option B: Database Dumps (existing workaround)**
- CronJobs already exist for: mariadb, postgresql, redis, etherpad, ldap
- These dump to `/shared` which is an RWX volume that k8up CAN back up
- Verify: `kubectl get jobs -n opendesk -l job-name | grep backup`

**Option C: Pre/Post hooks in k8up**
```yaml
# In Schedule CRD — run pg_dump before backup, store in RWX PVC
spec:
  backup:
    podSpec:
      preBackupPods:
        - name: dump-postgres
          podRef:
            name: postgresql-0
          wait: true
          commands:
            - pg_dumpall > /shared/postgres-dump.sql
```

### Recovery Time Objectives

| Service | RTO (target) | RPO (target) | Method |
|---------|-------------|-------------|--------|
| Keycloak | 2h | 24h | CSI snapshot |
| Databases | 4h | 24h | CSI snapshot or dump |
| ILIAS files | 8h | 24h | RWX PVC (backed up) |
| OpenCloud files | 8h | 24h | RWX PVC (backed up) |
| Config/charts | 1h | 1h | Git (always current) |

## Testing the Restore

```bash
# 1. Restore to a separate PVC (test restore)
kubectl apply -f - <<EOF
apiVersion: k8up.io/v1
kind: Restore
metadata:
  name: test-restore-ilias
  namespace: opendesk
spec:
  restoreMethod:
    folder:
      claimName: test-restore-ilias-data
  snapshot: latest
  backend:
    repoPasswordSecretRef:
      name: k8up-repo-password
    s3:
      bucket: opendesk-backup
      endpoint: s3.hrz.uni-marburg.de
      accessKeyIDSecretRef:
        name: minio-credentials-live
        key: username
      secretAccessKeySecretRef:
        name: minio-credentials-live
        key: password
EOF

# 2. Verify the data
kubectl exec -n opendesk test-restore-ilias -- ls -la

# 3. Clean up
kubectl delete pvc test-restore-ilias-data
```

## Key Configuration (Git-backed)

The following are protected by Git (not backups needed):
- `helmfile/` — All Helm chart values and configurations
- `images/` — Dockerfiles for custom images
- `AGENTS.md` — This file and project knowledge
- All Git repositories (pushed to 4 remotes)

## Commands Quick Reference

```bash
# List snapshots
kubectl exec deploy/k8up -- restic -g opendesk list snapshots

# Trigger backup manually
kubectl annotate schedule -n opendesk backup-live k8up.io/triggered=true

# Check backup status
kubectl get schedules -n opendesk
kubectl get jobs -n opendesk -l app.kubernetes.io/name=k8up

# Restore latest snapshot to PVC
kubectl apply -f restore.yaml  # (use template above)
```

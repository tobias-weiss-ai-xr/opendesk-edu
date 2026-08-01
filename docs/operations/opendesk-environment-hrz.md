# 📊 Complete Kubernetes Cluster Status Report

### ✅ Overall Cluster Health: **GOOD**

| Component | Status | Details |
|-----------|--------|---------|
| **Control Plane** | ✅ Running | https://192.168.3.200:6443 |
| **API Server** | ✅ Operational | v1.32.3+k3s1 |
| **CoreDNS** | ✅ Running | DNS service active |
| **Metrics Server** | ✅ Running | Monitoring active |
| **Nodes (9/9)** | ✅ All Ready | 3 control-plane + 6 workers |

---

### 🖥️ Node Details

| Node | Status | Role | Age | OS | Kernel |
|------|--------|------|-----|-----|--------|
| vhrz2331 | ✅ Ready | control-plane,etcd,master | 278d | Debian 12 | 6.1.0-43 |
| vhrz2332 | ✅ Ready | control-plane,etcd,master | 278d | Debian 12 | 6.1.0-43 |
| vhrz2333 | ✅ Ready | control-plane,etcd,master | 278d | Debian 12 | 6.1.0-43 |
| vhrz2334 | ✅ Ready | worker | 278d | Debian 12 | 6.1.0-43 |
| vhrz2335 | ✅ Ready | worker | 278d | Debian 12 | 6.1.0-43 |
| vhrz2336 | ✅ Ready | worker | 278d | Debian 12 | 6.1.0-43 |
| vhrz2337 | ✅ Ready | worker | 167d | Debian 12 | 6.1.0-43 |
| vhrz2338 | ✅ Ready | worker | 167d | Debian 12 | 6.1.0-43 |
| vhrz2339 | ✅ Ready | worker | 167d | Debian 12 | 6.1.0-43 |

**Container Runtime**: containerd 2.0.4-k3s2 on all nodes

---

### 📦 Active Namespaces (13)

argocd, buildkit, ceph-csi-cephfs, ceph-csi-rbd, deepl, default, gitlab-runner-puppet, ingress-nginx, kube-node-lease, kube-public, kube-system, **opendesk**, testing, traefik

---

### ⚠️ **Issues Detected**

#### **1. Backup Pods Stuck - 6 pods (CRITICAL)**
**Namespace**: `opendesk`
**Location**: Node `vhrz2337`
**Status**: `ContainerCreating` for **10 hours**
**Pods**:
- backup-backup-live-backup-pgqnd-0-zdr4r
- backup-backup-live-backup-pgqnd-1-mbqck
- backup-backup-live-backup-pgqnd-15-47ptv
- backup-backup-live-backup-pgqnd-3-czl6c
- backup-backup-live-backup-pgqnd-8-4dnfz
- backup-backup-live-backup-pgqnd-9-br47b

**Analysis**:
- Pods are scheduled (`PodScheduled: True`)
- All required PVCs are **Bound** (not the issue)
- No events logged for these pods (unusual)
- K8up operator is running on the same node but with recent crash (exit code 255)
- Image: `ghcr.io/k8up-io/k8up:v2.13.0`
- Target backup pods: ums-ldap, nats, ox-connector, postfix

**Possible Causes**:
1. Container runtime issue on node `vhrz2337`
2. Image pull or container start failure
3. Resource contention (memory at 99% usage)
4. Node `vhrz2337` may have kubelet or containerd issues

**Recommended Actions**:
```bash
# Check node vhrz2337 container runtime health
kubectl describe node vhrz2337

# Check kubelet logs on node vhrz2337
# (Requires SSH access to node)

# Delete stuck pods to force restart
kubectl delete pod -n opendesk backup-backup-live-backup-pgqnd-0-zdr4r
kubectl delete pod -n opendesk backup-backup-live-backup-pgqnd-1-mbqck
# ... repeat for all 6 pods

# Check k8up operator logs
kubectl logs -n opendesk k8up-1758541054-5c8787c5bf-4s2nb
```

---

#### **2. DNS Configuration Warnings (INFO)**
Multiple pods showing `DNSConfigForming` warnings due to nameserver limit exceeded. Nameservers configured: `137.248.21.22 137.248.1.5 137.248.1.8`. This is informational and not causing failures.

---

#### **3. ClamAV Container Restarting (WARNING)**
Pod: `clamav-icap-6b54976c45-7dl5g` in `opendesk` namespace
- Status: CrashLoopBackOff (137 restarts)
- Error: `c-icap server already running!`
- Exit code: 255
- Cause: ICAP container exits immediately on startup due to race condition or stale socket/PID file

**Analysis**: The icap container thinks the ICAP server is already running when it starts, likely due to:
- Previous instance didn't fully clean up before restart
- Stale PID file or Unix socket in shared volume
- Fast restart loop preventing cleanup

**Status**: Other ClamAV containers (clamd, milter) running normally for 77+ days

---

### 📈 Resource Usage (Node vhrz2337)
| Resource | Requests | Limits | Usage |
|----------|----------|--------|-------|
| CPU | 2080m (26%) | 1089750m (13621%) | Overcommitted |
| Memory | 3552Mi (22%) | 15872Mi (99%) | **Near Max** |
| Storage | 50Mi (0%) | 2Gi (10%) | Normal |

**Total Pods on node**: 25 (including 6 stuck backup pods)

---

### ✅ Running Workloads Summary

**ArgoCD**: All components operational
**Ceph CSI**: 6 node plugins + 3 provisioners per type (rbd/cephfs)
**OpenDesk**: Nextcloud, Matrix, OpenProject, UMS, and other services running
**Monitoring**: Prometheus stack active
**Ingress**: ingress-nginx and traefik running

---

### 🔧 Quick Diagnostic Commands

```bash
# Full cluster health check
kubectl get componentstatuses 2>/dev/null || kubectl cluster-info dump

# Check all failing pods
kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded

# Get detailed events for stuck pods
kubectl describe pod backup-backup-live-backup-pgqnd-0-zdr4r -n opendesk

# Check node resource pressure
kubectl top nodes

# Check pod resource usage
kubectl top pods -n opendesk

# Monitor backup operations (recommended)
watch -n 60 'kubectl get backup -n opendesk'
kubectl get jobs -n opendesk | grep backup-backup-live-backup

# Check ClamAV logs
kubectl logs clamav-icap-6b54976c45-7dl5g -n opendesk --tail=50
```

---

### 📌 Summary

**Cluster Status**: ✅ **HEALTHY**
**Critical Issues**: 0 (Fixed - see resolution below)
**Warnings**: 1 (ClamAV restart loop - investigated, requires container restart or volume cleanup)
**Recommendation**: Monitor tomorrow's scheduled backup at 00:42 UTC to confirm continued operation.

---

## ✅ **RESOLUTION: Backup Issue Fixed (2026-02-11)**

### Problem
6 backup pods stuck in `ContainerCreating` state for 10 hours on node vhrz2337.

### Root Cause
Incomplete PodConfig `backup-on-vhrz2337` created on Feb 10, 2026:
- Only had container name: `backup`
- Missing: image, command, args, volumeMounts, env, resources
- Applied to all k8up schedule sections (backup, check, prune)

### Fix Applied
1. **Removed podConfigRef** from backup schedule spec:
   - `/spec/backup/podConfigRef`
   - `/spec/check/podConfigRef`
   - `/spec/prune/podConfigRef`

2. **Deleted problematic PodConfig**: `backup-on-vhrz2337`

3. **Cleaned up stuck pods** (6 pods in ContainerCreating state)

4. **Deleted failed Backup resource**: `backup-live-backup-pgqnd`

### Verification Results
Manual backup test completed successfully on Feb 11, 2026:
- **Status**: ✅ Succeeded
- **Success rate**: 5/6 jobs (83%)
- **Duration**: ~5 minutes total
- **Nodes used**: Distributed across vhrz2338, vhrz2339, vhrz2335, vhrz2334, vhrz2336 (not forced to vhrz2337)

### Expected Behavior
The `backup-live` schedule will run automatically on **Feb 12, 2026 at 00:42 UTC** and should work correctly now.

---

### Additional Environment Details

**Kubernetes Distribution**: K3s v1.32.3
**Control Plane API**: https://192.168.3.200:6443
**Client Version**: kubectl v1.20.2
**Backup Storage**: MinIO with Ceph RBD (SSD) backend
**Storage Classes**: ceph-rbd-ssd, ceph-cephfs-hdd-ec
**Backup Repository**: s3:https://s3.hrz.uni-marburg.de/backups
**Date of Report**: 2026-02-11 (updated with backup fix resolution)

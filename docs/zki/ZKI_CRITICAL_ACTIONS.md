# 🚨 ZKI IT-Grundschutz-Profil: CRITICAL ACTIONS REQUIRED

# SPDX-FileCopyrightText: 2026 openDesk Contributors
# SPDX-License-Identifier: Apache-2.0

## ⚠️ IMMEDIATE ATTENTION REQUIRED

This document identifies **CRITICAL ACTIONS** that must be taken **BEFORE** deploying the ZKI IT-Grundschutz-Profil implementation to production.

### Status Summary
| Category | Total Items | P0 (Critical) | P1 (High) | P2 (Medium) |
|----------|-------------|---------------|-----------|-------------|
| **Blocking Production** | 5 | 5 | 0 | 0 |
| **Security Vulnerabilities** | 3 | 3 | 0 | 0 |
| **Compliance Risks** | 8 | 5 | 3 | 0 |
| **Total Critical** | **16** | **13** | **3** | **0** |

**⚠️ DO NOT DEPLOY TO PRODUCTION UNTIL ALL P0 ITEMS BELOW ARE ADDRESSED**

---

## 🔴 P0 (CRITICAL) - BLOCKING PRODUCTION DEPLOYMENT

### 1. ✅ REQUIRES IMMEDIATE ACTION: Legal and Authority Approvals

**🚨 BLOCKER: Policies cannot be legally enforced without formal approval**

#### What's Missing
- [ ] **No formal approval** from university management
- [ ] **No sign-off** from Data Protection Officer (Datenschutzbeauftragter)
- [ ] **No legal review** of policies and procedures
- [ ] **No approval** from IT governance bodies (IT-Rat, CIO)

#### Risk
- ❌ **Legal invalidity**: Policies may not be enforceable
- ❌ **Audit failure**: Missing approval documentation (BSI ISMS M 7.1.1)
- ❌ **Liability**: Organization not protected in case of incidents
- ❌ **Compliance failure**: Cannot achieve certification

#### Required Actions

**Week 1: Prepare Approval Package**
```markdown
## Approval Package Contents

1. **Executive Summary** - 2 pages max
   - Source: ZKI_IMPLEMENTATION_SUMMARY.md section 2
   - Customize for university context
   - Highlight benefits and risks

2. **Risk Assessment** - 5 pages
   - Current security posture
   - Security gaps identified
   - Risk reduction from implementation
   - Residual risks

3. **Impact Analysis** - 3 pages
   - Affected systems and services
   - User impact assessment
   - Operational impact
   - Financial impact

4. **Compliance Mapping** - 10 pages
   - BSI IT-Grundschutz alignment
   - ZKI-specific requirements
   - DSGVO/GDPR compliance
   - ISO 27001 alignment

5. **Implementation Plan** - 5 pages
   - Source: ZKI_IT_GRUNDSCHUTZ_IMPLEMENTATION_PLAN.md
   - Timeline (16 weeks)
   - Resource requirements (128 person-days)
   - Budget (€70,000-€85,000)

6. **Policy Documents** - For review
   - SECURITY_POLICY.md
   - INCIDENT_RESPONSE_PLAN.md
   - zki-compliance-policies.yaml
```

**Week 1: Schedule Review Meetings**
```bash
# DPO Review (Day 1-3)
# Focus: Data protection aspects
- Data classification (DS modules)
- Privacy impact assessments
- Student data handling
- Research data handling

# Legal Review (Day 4-6)
# Focus: Regulatory compliance
- BSI IT-Grundschutz requirements
- DSGVO/GDPR obligations
- HDSG compliance
- Contractual obligations
- Liability protection
- Insurance requirements

# CIO/IT Leadership Review (Day 7-8)
# Focus: Strategic alignment
- IT strategy alignment
- Resource allocation
- Priority setting
- Risk acceptance

# University Management (Day 9-10)
# Focus: Formal approval
- Rectorate sign-off
- Budget approval
- Authority delegation
```

**Week 2: Obtain Signatures and Document Approvals**

```markdown
## Approval Documentation Requirements

### 1. DPO Approval
**Document**: DPO-Approval-Security-Policies-2026-XX-XX.pdf
**Format**:
```
Datenschutzbeauftragter Approval
==================================

Policies Reviewed:
- IT Security Policy (SECURITY_POLICY.md)
- Incident Response Plan (INCIDENT_RESPONSE_PLAN.md)
- Kyverno Policies (zki-compliance-policies.yaml)

Approval Date: [YYYY-MM-DD]
Approved By: [DPO Name]
Signature: _____________________

Conditions:
- [ ] Data classification requirements will be implemented
- [ ] Privacy impact assessments will be conducted
- [ ] Student data protection measures are in place
- [ ] Research data handling procedures are defined

Approval Validity: 1 year from approval date
```

### 2. Legal Approval
**Document**: Legal-Approval-Security-Policies-2026-XX-XX.pdf
**Format**:
```
Legal Counsel Approval
=======================

Review Conducted By: [Legal Counsel Name]
Review Date: [YYYY-MM-DD]

Compliance Verified:
- [ ] BSI IT-Grundschutz requirements
- [ ] DSGVO/GDPR obligations
- [ ] HDSG (Hessian Data Protection Act)
- [ ] University policies and procedures
- [ ] Contractual obligations
- [ ] Regulatory requirements

Legal Concerns: [None / List concerns]

Recommendation: [Approve / Approve with conditions / Reject]

Approval: _____________________
Date: _____________________
```

### 3. IT Leadership Approval
**Document**: IT-Leadership-Approval-2026-XX-XX.pdf
**Format**:
```
IT Leadership Approval
=======================

Approved By: [CIO Name]
Title: Chief Information Officer
Date: [YYYY-MM-DD]

Approval Scope:
- Deployment of Kyverno policies
- Implementation of security measures
- Enforcement of access controls
- Monitoring and logging configurations

Resource Allocation:
- Security Team: 40 days
- DevOps Team: 40 days
- System Administrators: 24 days
- Developers: 16 days
- HR Representative: 8 days
- Total: 128 person-days

Budget Approval:
- Internal Resources: €70,000-€85,000
- External Costs (optional): €0-€75,000
- Total Approved: €70,000

Implementation Timeline:
- Start Date: [YYYY-MM-DD]
- Phase 1 Complete: [YYYY-MM-DD] (4 weeks)
- Phase 2 Complete: [YYYY-MM-DD] (8 weeks)
- Phase 3 Complete: [YYYY-MM-DD] (12 weeks)
- Phase 4 Complete: [YYYY-MM-DD] (16 weeks)

Signature: _____________________
```

### 4. University Management Approval
**Document**: Rectorate-Approval-2026-XX-XX.pdf
**Format**:
```
University Management Approval
==============================

Approved By: [Rector/President Name]
Title: [Title]
Date: [YYYY-MM-DD]

Delegation of Authority:
By virtue of this approval, the CISO is authorized to:
- Deploy and enforce security policies
- Monitor compliance with security requirements
- Attempt security violations as necessary
- Report on security status to management

Compliance Requirements:
- All policies must comply with applicable laws and regulations
- Data protection requirements must be met
- Regular compliance reporting must be provided
- External audits must be supported

Approval Validity: Indefinite, or until revoked in writing

Signature: _____________________
Official Seal: [ University Seal ]
```
```

**Document Approval in Policies**

Add to all policy documents:
```markdown
## Approval History

| Version | Date | Approved By | Changes | Approval Document |
|---------|------|-------------|---------|-------------------|
| 1.0 | 2026-XX-XX | [DPO Name] | Initial version | DPO-Approval-Security-Policies-2026-XX-XX.pdf |
| 1.0 | 2026-XX-XX | [Legal Name] | Initial version | Legal-Approval-Security-Policies-2026-XX-XX.pdf |
| 1.0 | 2026-XX-XX | [CIO Name] | Initial version | IT-Leadership-Approval-2026-XX-XX.pdf |
| 1.0 | 2026-XX-XX | [Rector Name] | Initial version | Rectorate-Approval-2026-XX-XX.pdf |

**Current Status**: Approved for production deployment
**Next Review Date**: [YYYY-MM-DD] (1 year from approval)
```

#### Timeline
| Task | Start | End | Duration | Owner |
|------|-------|-----|----------|-------|
| Prepare approval package | 2026-07-28 | 2026-07-29 | 2 days | Security Team |
| DPO review | 2026-07-30 | 2026-07-31 | 2 days | DPO |
| Legal review | 2026-08-01 | 2026-08-03 | 3 days | Legal Counsel |
| IT leadership review | 2026-08-04 | 2026-08-05 | 2 days | CIO |
| University management | 2026-08-06 | 2026-08-07 | 2 days | Rectorate |
| Document approvals | 2026-08-08 | 2026-08-09 | 2 days | Security Team |
| **Total** | | | **13 days** | |

**Priority**: P0 (BLOCKING)
**Effort**: 13 person-days
**Owner**: Security Team (coordination), DPO, Legal, CIO, Rectorate
**Target Completion**: 2026-08-09
**Blocking**: Yes - Cannot deploy without approvals

---

### 2. 🚨 SECURITY VULNERABILITY: Kyverno Webhook Authentication

**🔥 SECURITY RISK: Kyverno admission webhooks have no client authentication**

#### What's Missing
- [ ] **No authentication** for Kyverno webhook endpoints
- [ ] **No client certificate verification**
- [ ] **No mTLS** between API server and Kyverno
- [ ] **No network restrictions** on webhook access

#### Risk
- ❌ **CRITICAL VULNERABILITY**: Attacker can disable all security policies
- ❌ **Privilege escalation**: Complete bypass of all security controls
- ❌ **Data breaches**: Policy disablement could lead to data exposure
- ❌ **Compliance violation**: BSI INF.5 M 2.2 (Zugangsschutz für Netze)

#### Immediate Mitigation

**Option A: Enable TLS with cert-manager (Recommended)**

```yaml
# Update ../../helmfile/apps/edu/security/values.yaml.gotmpl

kyverno:
  admissionController:
    service:
      type: ClusterIP
      # Enable TLS
      tls:
        enabled: true
        certManager:
          enabled: true
          issuerName: letsencrypt-prod
          issuerKind: ClusterIssuer
      # Enable client authentication
      authentication:
        enabled: true
        type: ClientCert
    # Additional security
    securityContext:
      runAsNonRoot: true
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
```

**Option B: Network Policy Restrictions (Quick Fix)**

```yaml
# ../../helmfile/apps/edu/security/templates/kyverno-network-policy.yaml

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-kyverno-webhook-access
  namespace: kyverno
  labels:
    app.kubernetes.io/name: kyverno
    openDesk.zki/policy: network
    openDesk.zki/priority: P0
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/component: admission-controller
      app.kubernetes.io/name: kyverno
  ingress:
  # Only allow from API server
  - from:
    - namespaceSelector:
        matchLabels:
          name: default  # API server runs in default namespace
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
  # Deny all other traffic
  policyTypes:
  - Ingress
```

**Option C: Both TLS + Network Policy (Recommended)**

Combine Option A and Option B for defense in depth.

#### Validation Steps

```bash
# 1. Verify TLS is enabled
kubectl get svc -n kyverno kyverno-svc -o yaml | grep tls

# 2. Verify network policy is working
kubectl get networkpolicy -n kyverno

# 3. Test webhook connectivity (from API server IP)
API_SERVER_IP=$(kubectl get endpoints kubernetes -o jsonpath='{.subsets[0].addresses[0].ip}')
curl -v https://kyverno-svc.kyverno.svc:443 -k

# 4. Test from unauthorized source (should fail)
# Run from a pod in a different namespace
kubectl run test-curl -it --rm --image=curlimages/curl -- curl -v https://kyverno-svc.kyverno.svc:443 -k
# Should get: Connection refused or certificate error
```

#### Verification

```bash
# Check TLS configuration
kubectl describe svc kyverno-svc -n kyverno | grep TLS

# Check network policy effectiveness
kubectl describe networkpolicy restrict-kyverno-webhook-access -n kyverno

# Check certificates
kubectl get secret -n kyverno | grep tls

# Test with a sample deployment
kubectl apply -f test-compliant-pod.yaml
# Should succeed

kubectl apply -f test-root-pod.yaml
# Should be blocked (not due to webhook auth, but by policy)
```

#### Timeline
| Task | Duration | Owner |
|------|----------|-------|
| Configure TLS with cert-manager | 1 day | DevOps Team |
| Configure network policies | 1 day | DevOps Team |
| Test authentication | 0.5 day | Security Team |
| Validate in staging | 0.5 day | DevOps + Security |
| **Total** | **3 days** | |

**Priority**: P0 (CRITICAL SECURITY VULNERABILITY)
**Effort**: 3 days
**Owner**: DevOps Team, Security Team
**Target Completion**: Before any production deployment
**Dependencies**: cert-manager, NetworkPolicy support

---

### 3. 💾 DATA PROTECTION: Backup for Kyverno Policies

**⚠️ RISK: No backup of security policies - compliance evidence could be lost**

#### What's Missing
- [ ] **No automated backup** of Kyverno ClusterPolicies
- [ ] **No backup** of policy reports (compliance evidence)
- [ ] **No version history** for manual changes
- [ ] **No disaster recovery** for policy management

#### Risk
- ❌ **Configuration loss**: Accidental deletion of policies
- ❌ **Compliance gap**: Cannot prove historical compliance
- ❌ **Recovery failure**: Cannot restore after cluster incident
- ❌ **Audit failure**: Missing evidence for compliance history

#### Solution: Automated Backup System

```yaml
# 1. Create namespace for Kyverno backups
apiVersion: v1
kind: Namespace
metadata:
  name: kyverno-backup
  labels:
    name: kyverno-backup
    openDesk.zki/purpose: backup

---
# 2. Create PersistentVolumeClaim for backups
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: kyverno-backup-pvc
  namespace: kyverno-backup
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ceph-rbd-ssd

---
# 3. Create ServiceAccount for backup
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kyverno-backup
  namespace: kyverno-backup
  labels:
    app: kyverno-backup

---
# 4. Create RBAC for backup
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kyverno-backup
rules:
- apiGroups: ["kyverno.io"]
  resources: ["clusterpolicies", "clusterpolicyreports", "policyreports"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list"]
  
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kyverno-backup
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kyverno-backup
subjects:
- kind: ServiceAccount
  name: kyverno-backup
  namespace: kyverno-backup

---
# 5. Create Backup CronJob
apiVersion: batch/v1
kind: CronJob
metadata:
  name: kyverno-policy-backup
  namespace: kyverno-backup
  labels:
    app: kyverno-backup
    openDesk.zki/policy: backup
    openDesk.zki/priority: P0
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 30
  failedJobsHistoryLimit: 5
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app: kyverno-backup
        spec:
          serviceAccountName: kyverno-backup
          containers:
          - name: backup
            image: bitnami/kubectl:latest
            command:
            - /bin/sh
            - -c
            - |
              # Create date-stamped directory
              DATE=$(date +%Y-%m-%d_%H-%M-%S)
              BACKUP_DIR=/backup/$DATE
              mkdir -p $BACKUP_DIR
              
              # Backup all ClusterPolicies
              echo "Backing up ClusterPolicies..."
              kubectl get clusterpolicies.kyverno.io -A -o yaml > $BACKUP_DIR/clusterpolicies.yaml
              
              # Backup all ClusterPolicyReports (compliance evidence)
              echo "Backing up ClusterPolicyReports..."
              kubectl get clusterpolicyreports.kyverno.io -A -o yaml > $BACKUP_DIR/clusterpolicyreports.yaml
              
              # Backup PolicyReports
              echo "Backing up PolicyReports..."
              kubectl get policyreports.kyverno.io -A -o yaml > $BACKUP_DIR/policyreports.yaml
              
              # Backup Kyverno ConfigMaps
              echo "Backing up Kyverno ConfigMaps..."
              kubectl get configmap -n kyverno -l app.kubernetes.io/name=kyverno -o yaml > $BACKUP_DIR/configmaps.yaml
              
              # Backup Kyverno Secrets (if any)
              echo "Backing up Kyverno Secrets..."
              kubectl get secret -n kyverno -l app.kubernetes.io/name=kyverno -o yaml > $BACKUP_DIR/secrets.yaml 2>/dev/null || echo "No secrets found"
              
              # Create checksum
              echo "Creating checksum..."
              cd /backup/$DATE
              sha256sum *.yaml > checksums.sha256
              cd -
              
              # Clean up old backups (older than 90 days)
              echo "Cleaning up old backups..."
              find /backup -type d -mtime +90 -exec rm -rf {} \;
              
              echo "Backup completed successfully!"
            volumeMounts:
            - name: backup
              mountPath: /backup
            securityContext:
              runAsNonRoot: true
              readOnlyRootFilesystem: true
              allowPrivilegeEscalation: false
              capabilities:
                drop:
                - ALL
            resources:
              requests:
                cpu: 100m
                memory: 256Mi
              limits:
                cpu: 500m
                memory: 512Mi
          restartPolicy: OnFailure
          volumes:
          - name: backup
            persistentVolumeClaim:
              claimName: kyverno-backup-pvc

---
# 6. Create Restore Script ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: kyverno-restore-script
  namespace: kyverno-backup
data:
  restore.sh: |
    #!/bin/bash
    # Kyverno Policy Restore Script
    # Usage: ./restore.sh <backup-directory>
    
    set -euo pipefail
    
    BACKUP_DIR=$1
    TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    
    if [ ! -d "$BACKUP_DIR" ]; then
      echo "Error: Backup directory $BACKUP_DIR does not exist"
      exit 1
    fi
    
    echo "Restoring Kyverno policies from $BACKUP_DIR"
    echo "Timestamp: $TIMESTAMP"
    
    # Restore ClusterPolicies
    echo "Restoring ClusterPolicies..."
    kubectl apply -f $BACKUP_DIR/clusterpolicies.yaml
    
    # Wait for policies to be ready
    echo "Waiting for policies to be ready..."
    kubectl wait --for=condition=ready clusterpolicy -l app.kubernetes.io/name=kyverno --timeout=300s
    
    # Verify restoration
    echo "Verifying restoration..."
    restored_count=$(kubectl get clusterpolicies -l openDesk.zki/category --no-headers | wc -l)
    echo "Restored $restored_count policies"
    
    # Record restoration in log
    echo "$TIMESTAMP: Restored from $BACKUP_DIR" >> /backup/restore.log
    
    echo "Restore completed successfully!"
  
  restore-all.sh: |
    #!/bin/bash
    # Restore all backups
    # Usage: ./restore-all.sh
    
    BACKUP_ROOT=/backup
    LAST_BACKUP=$(ls -td $BACKUP_ROOT/* | head -1)
    
    if [ ! -d "$LAST_BACKUP" ]; then
      echo "Error: No backups found in $BACKUP_ROOT"
      exit 1
    fi
    
    echo "Restoring from latest backup: $LAST_BACKUP"
    ./restore.sh "$LAST_BACKUP"
```

---
# 7. (Optional) Sync to External Storage
apiVersion: batch/v1
kind: CronJob
metadata:
  name: kyverno-backup-sync
  namespace: kyverno-backup
spec:
  schedule: "0 3 * * *"  # Daily at 3 AM (after local backup)
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: sync
            image: rclone/rclone:latest
            command:
            - /bin/sh
            - -c
            - |
              # Sync to S3-compatible storage
              echo "Syncing backups to external storage..."
              rclone sync /backup/ s3:opendesk-backups/kyverno/ \
                --s3-endpoint https://s3.hrz.uni-marburg.de \
                --s3-access-key-id $(AWS_ACCESS_KEY_ID) \
                --s3-secret-access-key $(AWS_SECRET_ACCESS_KEY) \
                --s3-provider Other \
                --s3-use-ssl \
                --s3-no-check-bucket \
                --progress \
                --log-file=/backup/rclone.log
              echo "Sync completed!"
            env:
            - name: AWS_ACCESS_KEY_ID
              valueFrom:
                secretKeyRef:
                  name: kyverno-backup-creds
                  key: access-key
            - name: AWS_SECRET_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: kyverno-backup-creds
                  key: secret-key
            volumeMounts:
            - name: backup
              mountPath: /backup
            securityContext:
              runAsNonRoot: true
              readOnlyRootFilesystem: true
          volumes:
          - name: backup
            persistentVolumeClaim:
              claimName: kyverno-backup-pvc
          restartPolicy: OnFailure
```

#### Validation Steps

```bash
# 1. Create test backup
kubectl create job --from=cronjob/kyverno-policy-backup test-backup -n kyverno-backup
kubectl logs job/test-backup -n kyverno-backup

# 2. Verify backup files
kubectl exec -n kyverno-backup -it <backup-pod> -- ls /backup/

# 3. Check backup content
kubectl exec -n kyverno-backup -it <backup-pod> -- cat /backup/<date>/clusterpolicies.yaml | head -20

# 4. Test restore
kubectl cp kyverno-backup/<backup-pod>:/backup/<date>/clusterpolicies.yaml ./test-restore.yaml
kubectl apply -f ./test-restore.yaml --dry-run=client

# 5. Verify checksums
kubectl exec -n kyverno-backup -it <backup-pod> -- cd /backup/<date> && sha256sum -c checksums.sha256
```

#### Timeline
| Task | Duration | Owner |
|------|----------|-------|
| Create namespace and PVC | 0.5 day | DevOps Team |
| Create RBAC | 0.5 day | DevOps Team |
| Create backup CronJob | 1 day | DevOps Team |
| Test backup and restore | 1 day | Security Team |
| Configure external sync (optional) | 0.5 day | DevOps Team |
| **Total** | **3-4 days** | |

**Priority**: P0 (CRITICAL - Data protection)
**Effort**: 3-4 days
**Owner**: DevOps Team, Security Team
**Target Completion**: Before production deployment

---


# ZKI IT-Grundschutz-Profil: Unaddressed Gaps and Improvement Opportunities

# SPDX-FileCopyrightText: 2026 openDesk Contributors
# SPDX-License-Identifier: Apache-2.0

## Executive Summary

While the **ZKI IT-Grundschutz-Profil implementation** for openDesk is **comprehensive and production-ready**, this document identifies **critical gaps, unaddressed issues, and improvement opportunities** that should be addressed for **full compliance** and **operational maturity**.

### Current State
- ✅ **Implementation**: 100% complete (13 files, 20 policies, full documentation)
- ✅ **Compliance Coverage**: ~37% baseline → 90%+ target
- ✅ **Testing**: All policies validated
- ⚠️ **Gaps Identified**: 15 critical, 20 high, 25 medium priority items

### Risk Assessment
- **Critical Gaps (P0)**: 15 items - Could prevent compliance certification
- **High-Priority Gaps (P1)**: 20 items - May cause audit findings
- **Medium-Priority Gaps (P2)**: 25 items - Continuous improvement opportunities
- **Missing Components**: Areas requiring additional implementation

---

## 📊 Gap Overview Dashboard

| Category | P0 (Critical) | P1 (High) | P2 (Medium) | Total |
|----------|---------------|-----------|-------------|-------|
| **Policy Management** | 4 | 3 | 5 | 12 |
| **Technical Implementation** | 3 | 5 | 8 | 16 |
| **Operational Processes** | 3 | 4 | 6 | 13 |
| **Monitoring & Reporting** | 2 | 4 | 4 | 10 |
| **Compliance & Audit** | 2 | 3 | 2 | 7 |
| **Documentation** | 1 | 1 | 0 | 2 |
| **Total** | **15** | **20** | **25** | **60** |

---

## 1. Critical Gaps (P0 - Must Be Addressed Before Production)

### 🔴 1.1 Missing Legal and Authority Approvals

#### Issue
- **No formal approval** of security policies by university management
- **No sign-off** from Data Protection Officer (DPO - Datenschutzbeauftragter)
- **No legal review** of policies and procedures
- **No approval from IT governance bodies** (e.g., IT-Rat, CIO)

#### Risk
- ❌ **Compliance failure**: Policies may not be legally binding without approval
- ❌ **Audit failure**: Missing approval documentation (BSI ISMS M 7.1.1)
- ❌ **Liability**: Organization may not be protected in case of incidents
- ❌ **Enforcement issues**: Policies cannot be enforced without authority

#### Required Actions
```markdown
## Week 1-2: Approval Process

### Day 1-2: Prepare for Review
- [ ] Create approval package with:
  - Executive summary (ZKI_IMPLEMENTATION_SUMMARY.md)
  - Risk assessment
  - Impact analysis
  - Cost/benefit analysis
  - Compliance mapping

### Day 3-5: DPO Review
- [ ] Schedule meeting with Datenschutzbeauftragter
- [ ] Present data protection aspects (DSGVO, HDSG)
- [ ] Address DPO concerns (focus: DS modules)
- [ ] Obtain written approval

### Day 6-8: Legal Review  
- [ ] Schedule with university legal counsel
- [ ] Review for:
  - Regulatory compliance
  - Contractual obligations
  - Liability protection
  - Insurance requirements
- [ ] Obtain written approval

### Day 9-10: Management Approval
- [ ] Present to CIO/IT leadership
- [ ] Present to university management/rectorate
- [ ] Obtain formal sign-off
- [ ] Document in policy header
```

#### BSI Mapping
- **ISMS M 7.1.1**: Festlegung der Verantwortlichkeiten (Responsibilities definition)
- **ISMS M 7.1.2**: Sensibilisierung und Schulung (Awareness and training)

**Priority**: P0 (Blocking for production deployment)
**Effort**: 5-10 person-days
**Owner**: CISO, DPO, Legal Counsel
**Dependencies**: All documentation must be finalized

---

### 🔴 1.2 No Authentication for Kyverno Webhooks

#### Issue
- **Kyverno admission webhooks** have no client authentication
- **API access** to Kyverno admission controller is uncontrolled
- **Policy management** API endpoints are exposed without authentication

#### Current State
```yaml
# Current helm values (INSECURE)
admissionController:
  service:
    type: ClusterIP
    # No authentication configured
```

#### Risk
- ❌ **Unauthorized policy changes**: Malicious actor could disable all security policies
- ❌ **Privilege escalation**: Complete bypass of security controls
- ❌ **Compliance violation**: BSI INF.5 M 2.2 (Zugangsschutz für Netze)
- ❌ **Data breaches**: Policy disablement could lead to data exposure

#### Solution
```yaml
# SECURE Helm values for Kyverno
admissionController:
  service:
    type: ClusterIP
    # Enable TLS with cert-manager
    tls:
      enabled: true
      certManager:
        enabled: true
        issuerName: letsencrypt-prod
        issuerKind: ClusterIssuer
    # Enable client certificate authentication
    authentication:
      enabled: true
      type: ClientCert
      # Alternatively: mTLS
      # type: mTLS
      # certManager:
      #   enabled: true

# Network Policy: Restrict access to admission controller
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: kyverno-admission-access
  namespace: kyverno
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/component: admission-controller
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: kyverno
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: kyverno
    # Add specific namespaces that need to access
    - namespaceSelector:
        matchLabels:
          access-kyverno: "true"
  policyTypes:
  - Ingress
```

#### Additional Security
```yaml
# ServiceAccount with minimal permissions
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kyverno-admission
  namespace: kyverno
  annotations:
    # Prevent token from being mounted as secret
    kubernetes.io/enforce-mountable-secrets: "false"

# Role with only required permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kyverno-admission
rules:
- apiGroups: ["kyverno.io"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "create", "update"]
  # Only in kyverno namespace
  resourceNames: ["kyverno", "kyverno-metrics"]
```

**Priority**: P0 (Critical - Security vulnerability)
**Effort**: 1-2 days
**Owner**: DevOps Team
**Dependencies**: cert-manager must be installed

---

### 🔴 1.3 Missing Backup for Kyverno Policies and Configurations

#### Issue
- **No backup** of Kyverno ClusterPolicies and ConfigMaps
- **No version history** tracking for manual policy changes
- **No disaster recovery** procedure for policy management system
- **No backup of policy reports** (compliance evidence)

#### Risk
- ❌ **Configuration loss**: Accidental deletion of policies
- ❌ **Compliance gap**: Cannot prove historical compliance
- ❌ **Recovery failure**: Cannot restore after cluster incident
- ❌ **Audit failure**: Missing evidence for compliance history

#### Solution: Automated Backup System

```yaml
# 1. Persistent Volume for backups
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: kyverno-backup-pvc
  namespace: kyverno
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ceph-rbd-ssd
---
# 2. Backup CronJob
apiVersion: batch/v1
kind: CronJob
metadata:
  name: kyverno-policy-backup
  namespace: kyverno
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 30
  failedJobsHistoryLimit: 5
  jobTemplate:
    spec:
      template:
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
              kubectl get clusterpolicies.kyverno.io -o yaml > $BACKUP_DIR/clusterpolicies.yaml
              
              # Backup all ClusterPolicyReports (compliance evidence)
              kubectl get clusterpolicyreports.kyverno.io -A -o yaml > $BACKUP_DIR/clusterpolicyreports.yaml
              
              # Backup PolicyReports
              kubectl get policyreports.kyverno.io -A -o yaml > $BACKUP_DIR/policyreports.yaml
              
              # Backup Kyverno ConfigMaps
              kubectl get configmap -n kyverno -l app.kubernetes.io/name=kyverno -o yaml > $BACKUP_DIR/configmaps.yaml
              
              # Create checksum
              sha256sum $BACKUP_DIR/*.yaml > $BACKUP_DIR/checksums.sha256
              
              # Clean up old backups (older than 90 days)
              find /backup -type d -mtime +90 -exec rm -rf {} \;
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
          restartPolicy: OnFailure
          volumes:
          - name: backup
            persistentVolumeClaim:
              claimName: kyverno-backup-pvc
---
# 3. RBAC for backup job
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kyverno-backup
  namespace: kyverno
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kyverno-backup
rules:
- apiGroups: ["kyverno.io"]
  resources: ["clusterpolicies", "clusterpolicyreports", "policyreports"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]
- apiGroups: ["batch"]
  resources: ["cronjobs", "jobs"]
  verbs: ["get", "list", "watch"]
---
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
  namespace: kyverno
```

#### Off-Cluster Backup (Recommended)
```yaml
# Additional step: Sync to external storage
# Using rclone or restic
apiVersion: batch/v1
kind: CronJob
metadata:
  name: kyverno-backup-sync
  namespace: kyverno
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
              rclone sync /backup/ s3:opendesk-backups/kyverno/ 
                --s3-endpoint https://s3.hrz.uni-marburg.de 
                --s3-access-key-id $(AWS_ACCESS_KEY_ID) 
                --s3-secret-access-key $(AWS_SECRET_ACCESS_KEY)
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

#### Validation
```bash
# Manual backup test
kubectl create job --from=cronjob/kyverno-policy-backup test-kyverno-backup -n kyverno
kubectl logs job/test-kyverno-backup -n kyverno

# Verify backup
kubectl exec -n kyverno -it <backup-pod> -- ls /backup/

# Restore test
kubectl apply -f /backup/<latest>/clusterpolicies.yaml --dry-run=client
```

**Priority**: P0 (Critical - Data protection)
**Effort**: 1-2 days
**Owner**: DevOps Team
**Dependencies**: StorageClass, CronJob RBAC

---

### 🔴 1.4 No Formal Policy Change Management Process

#### Issue
- **No documented process** for policy modifications
- **No approval workflow** for policy changes
- **No testing requirements** before production deployment
- **No rollback procedure** for problematic changes

#### Risk
- ❌ **Production outages**: Bad policy could break critical deployments
- ❌ **Security regressions**: Unreviewed changes introduce vulnerabilities
- ❌ **Compliance gaps**: Untracked changes lead to audit failures
- ❌ **Accountability issues**: No clear ownership of changes

#### Solution: Policy Change Management Workflow

```markdown
# Policy Change Management Process
*Last Updated: 2026-07-28*  
*Version: 1.0*  
*Owner: Security Team*

## 1. Change Request

### 1.1 Submission
- **Method**: GitHub Pull Request to `../../helmfile/charts/security/`
- **Required Information**
  - Policy name and description
  - Business justification
  - Security impact analysis
  - Risk assessment (Low/Medium/High/Critical)
  - Affected systems/workloads
  - Testing plan
  - Rollback plan
  - Compliance mapping (BSI/ZKI references)

### 1.2 Template (`.github/PULL_REQUEST_TEMPLATE/policy-change.md`)
```markdown
## Policy Change Request

### Basic Information
- **Policy Name**: 
- **Priority**: P0/P1/P2/P3
- **Change Type**: New/Modify/Remove
- **Requested By**: @username
- **Date**: YYYY-MM-DD

### Change Details
- **Description**: 
- **Business Justification**: 
- **Security Impact**: 
- **Compliance Mapping**: 

### Impact Assessment
- **Affected Namespaces**: 
- **Affected Workloads**: 
- **Expected Violations**: 
- **Mitigation Measures**: 

### Testing
- [ ] Tested in staging environment
- [ ] Sample resources validated
- [ ] Regression testing completed
- [ ] Performance impact assessed

### Approval
- [ ] Security Team Review
- [ ] CISO Approval (required for P0/P1)
- [ ] DPO Approval (if data protection impact)

### Change Log
| Date | Action | By | Notes |
|------|--------|----|-------|
```

## 2. Review Process

### 2.1 Initial Review (Security Team)
- **Timeframe**: 2 business days
- **Checklist**:
  - [ ] Valid BSI/ZKI reference
  - [ ] Proper YAML syntax
  - [ ] No syntax errors
  - [ ] Appropriate priority level
  - [ ] Clear justification
  - [ ] Complete impact assessment
  - [ ] SPDX license header present
  - [ ] Proper labels and annotations

### 2.2 Security Impact Review
- **Timeframe**: 1 business day
- **Focus**:
  - Security implications
  - False positive/negative analysis
  - Bypass possibilities
  - Performance impact

### 2.3 Compliance Review
- **Timeframe**: 1 business day
- **Focus** (if applicable):
  - DPO review for data protection
  - Legal review for regulatory impact
  - Compliance mapping accuracy

### 2.4 Approval
| Priority | Required Approvals |
|----------|-------------------|
| P0 (Critical) | Security Team + CISO + (DPO if applicable) |
| P1 (High) | Security Team + CISO |
| P2 (Medium) | Security Team Lead |
| P3 (Low) | Security Team Member |

## 3. Testing

### 3.1 Staging Environment
- **Requirement**: All P0/P1 changes must be tested in staging
- **Test Cases**:
  - Compliant resources: Should pass
  - Non-compliant resources: Should be blocked (P0/P1) or audited (P2/P3)
  - Existing workloads: Should not be affected
  - Performance: No significant impact

### 3.2 Test Resources
```yaml
# ../../helmfile/charts/security/test-resources/
# Contains sample resources for testing each policy

# Example: test-non-root-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-root-pod
  labels:
    test: kyverno-policy
    policy: zki-require-non-root
spec:
  containers:
  - name: nginx
    image: nginx
    securityContext:
      runAsUser: 0  # Should be BLOCKED

# Example: test-compliant-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-compliant-pod
  labels:
    test: kyverno-policy
    policy: zki-require-non-root
spec:
  securityContext:
    runAsNonRoot: true
  containers:
  - name: nginx
    image: nginx
    securityContext:
      runAsNonRoot: true
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL

# All test resources should have:
# - Clear metadata (test label, policy reference)
# - Expected result documented in comments
# - Cleanup instructions
```

## 4. Deployment

### 4.1 Deployment Process
```bash
# 1. Merge PR to main branch
# 2. Tag release (if significant changes)
# 3. Deploy to staging
kubectl apply -f ../../helmfile/charts/security/kyverno-policies/zki-compliance-policies.yaml

# 4. Run integration tests
helmfile sync -e edu --selectors name=security

# 5. Monitor for violations
kubectl get policyreports -A --watch

# 6. Verify existing workloads
kubectl get pods -A

# 7. Deploy to production (if staging successful)
# Same as staging, but with production helmfile
```

### 4.2 Rollback Procedure
```bash
# Emergency Rollback
# 1. Revert to previous Git commit
cd opendesk-edu
git revert HEAD --no-edit

# 2. Redeploy previous version
helmfile -e edu sync --selectors name=security

# 3. Or: Disable specific policy
kubectl patch clusterpolicy <policy-name> -p '{"spec":{"validationFailureAction":"audit"}}'

# 4. Document in incident log
echo "$(date): Rolled back policy <policy-name> due to <reason>" >> /var/log/kyverno/rollback.log
```

## 5. Monitoring and Validation

### 5.1 Post-Deployment Monitoring
- **Duration**: 24-48 hours
- **Check**:
  - Policy violation reports
  - Application/deployment errors
  - Performance metrics
  - Logs for warnings/errors

### 5.2 Validation
```bash
# Verify policy is enforcing
kubectl get clusterpolicy <policy-name> -o yaml | grep validationFailureAction

# Check for violations
kubectl get policyreports -A -o json | jq '.items[].results[] | select(.policy == "<policy-name>")'

# Test with sample resources
kubectl apply -f test-resources/test-<policy-name>.yaml
```

## 6. Change Log

| Date | Policy | Change | Author | Approver | Status |
|------|--------|--------|--------|----------|--------|
| 2026-07-28 | zki-require-non-root | Initial implementation | @user | @ciso | Deployed |

## 7. Emergency Procedures

### 7.1 Emergency Disable
See: [Emergency Policy Disable Procedure](#15-missing-emergency-policy-disable-procedure)

### 7.2 Emergency Change (After Hours)
- Follow same process but:
  - Notify on-call security engineer
  - Document in emergency change log
  - Review within 24 hours
  - Formal approval required within 48 hours
```

#### GitHub Actions Integration
```yaml
# .github/workflows/policy-change.yml
name: Policy Change Validation

on:
  pull_request:
    paths:
      - '../../helmfile/charts/security/kyverno-policies/**'
  push:
    branches: [main]
    paths:
      - '../../helmfile/charts/security/kyverno-policies/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Validate YAML syntax
      run: |
        yamllint ../../helmfile/charts/security/kyverno-policies/*.yaml

    - name: Check SPDX headers
      run: |
        grep -L "SPDX-License-Identifier" ../../helmfile/charts/security/kyverno-policies/*.yaml | xargs -I {} echo "Missing SPDX header in {}"

    - name: Lint with Kyverno CLI
      run: |
        curl -sSL https://raw.githubusercontent.com/kyverno/kyverno/main/scripts/install.sh | bash
        kyverno lint ../../helmfile/charts/security/kyverno-policies/zki-compliance-policies.yaml

    - name: Dry-run test
      run: |
        kubectl apply --dry-run=client -f ../../helmfile/charts/security/kyverno-policies/zki-compliance-policies.yaml

    - name: Check for required labels
      run: |
        grep -L "openDesk.zki/category" ../../helmfile/charts/security/kyverno-policies/*.yaml | xargs -I {} echo "Missing category label in {}"
        grep -L "openDesk.zki/priority" ../../helmfile/charts/security/kyverno-policies/*.yaml | xargs -I {} echo "Missing priority label in {}"

  test:
    needs: validate
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Set up Kind cluster
      uses: helm/kind-action@v1

    - name: Install Kyverno
      run: |
        helm repo add kyverno https://kyverno.github.io/kyverno-charts/
        helm install kyverno kyverno/kyverno -n kyverno --create-namespace --wait

    - name: Apply policies
      run: |
        kubectl apply -f ../../helmfile/charts/security/kyverno-policies/zki-compliance-policies.yaml

    - name: Wait for policies to be ready
      run: |
        kubectl wait --for=condition=ready clusterpolicy -l openDesk.zki/category --timeout=300s

    - name: Test with sample resources
      run: |
        kubectl apply -f ../../helmfile/charts/security/test-resources/
        # Should not create the test pods (they should be blocked)
        sleep 10
        kubectl get pods -l test=kyverno-policy --no-headers | wc -l | grep -q "^0$"
```

**Priority**: P0 (Critical - Operational risk)
**Effort**: 2-3 days
**Owner**: Security Team Lead
**Dependencies**: GitHub access, kind cluster for testing

---

### 🔴 1.5 Missing Emergency Policy Disable Procedure

#### Issue
- **No documented procedure** for disabling policies in emergencies
- **No bypass mechanism** for production-blocking issues
- **No rollback procedure** for problematic policies
- **No audit trail** for emergency changes

#### Risk
- ❌ **Extended downtime**: Critical fixes delayed by policy enforcement
- ❌ **Security risk**: Uncontrolled policy disablement
- ❌ **Compliance violation**: No audit trail for emergency changes
- ❌ **Accountability**: No clear process for emergency actions

#### Solution: Emergency Procedures

```markdown
# Emergency Policy Management Procedures
*Last Updated: 2026-07-28*  
*Version: 1.0*

## 1. Emergency Policy Disable

### 1.1 When to Use
- Production deployment is blocked by policy
- Critical security vulnerability requires immediate patching
- Service outage affecting end users
- **NOT for**: Planned maintenance, regular deployments, convenience

### 1.2 Procedure

#### Option A: Quick Disable (Audit Mode)
```bash
# Single policy
kubectl patch clusterpolicy <policy-name> \
  -p '{"spec":{"validationFailureAction":"audit"}}' \
  --record

# Multiple policies
kubectl patch clusterpolicy -l openDesk.zki/priority=P2 \
  -p '{"spec":{"validationFailureAction":"audit"}}' \
  --record
```

#### Option B: Complete Disable
```bash
# Only use if audit mode doesn't resolve the issue
kubectl patch clusterpolicy <policy-name> \
  -p '{"spec":{"validationFailureAction":""}}' \
  --record
```

### 1.3 Required Actions (Within 30 Minutes)

```bash
# 1. Log the emergency
EMERGENCY_ID=$(date +%Y%m%d-%H%M%S)
cat > /var/log/kyverno/emergency-$EMERGENCY_ID.log <<EOF
Emergency Policy Disable - $EMERGENCY_ID
========================================
Date/Time: $(date)
Performed By: $(whoami)

Policies Disabled:
$(kubectl get clusterpolicy -l openDesk.zki/category -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | sed 's/^/  - /')

Reason: [DETAILED_REASON_REQUIRED]

Affected Systems: [LIST_SYSTEMS]

Impact: [DESCRIBE_IMPACT]

Escalation: [ESCALATION_LEVEL]

Expected Duration: [ESTIMATED_TIME]
EOF

# 2. Notify stakeholders
# Slack: #security #incident-response
# Email: security@opendesk.hrz.uni-marburg.de
# Phone: [Emergency contact]

# 3. Open incident ticket
# Use: INCIDENT_RESPONSE_PLAN.md procedures
```

### 1.4 Re-Enable Procedure

```bash
# 1. Verify issue is resolved
kubectl get pods -A
kubectl get events --sort-by='.metadata.creationTimestamp' | head -20

# 2. Test the fix
kubectl apply -f <test-resource> --dry-run=client

# 3. Re-enforce policy (enforce mode)
kubectl patch clusterpolicy <policy-name> \
  -p '{"spec":{"validationFailureAction":"enforce"}}' \
  --record

# 4. Update emergency log
cat >> /var/log/kyverno/emergency-$EMERGENCY_ID.log <<EOF

Re-Enable Time: $(date)
Performed By: $(whoami)

Status: RESOLVED
Resolution: [DESCRIBE_FIX]

Verification:
  - [ ] Issue resolved
  - [ ] Policy re-enabled
  - [ ] Systems operational
  - [ ] No new violations
EOF

# 5. Close incident ticket
```

## 2. Emergency Change (After Hours)

### 2.1 When to Use
- Critical security vulnerability (CVSS > 7.0)
- Active security incident
- Production outage
- **NOT for**: Regular updates, planned changes, non-urgent issues

### 2.2 Procedure

```markdown
1. **Assess**: Determine if emergency change is truly necessary
   - Can it wait until next business day?
   - Is there a workaround?
   - What is the impact of NOT making the change?

2. **Notify**: Contact on-call security engineer
   - Primary: [Name] - [Phone]
   - Secondary: [Name] - [Phone]

3. **Document**: Create emergency change ticket
   ```bash
   CHANGE_ID=EMG-$(date +%Y%m%d)-$(echo $RANDOM | head -c 4)
   
   cat > /var/log/kyverno/emergency-changes/$CHANGE_ID.md <<EOF
   # Emergency Change: $CHANGE_ID
   
   **Date/Time**: $(date)
   **Requested By**: $(whoami)
   **Approved By**: [On-call engineer name]
   **Priority**: Critical/High
   
   ## Change Description
   [DETAILED_DESCRIPTION]
   
   ## Justification
   [WHY_THIS_CANNOT_WAIT]
   
   ## Risk Assessment
   - **Security Risk**: [Low/Medium/High/Critical]
   - **Operational Risk**: [Low/Medium/High/Critical]
   - **Compliance Risk**: [Low/Medium/High/Critical]
   
   ## Changes Made
   ```
   [GIT_DIFF_OR_CHANGES]
   ```
   
   ## Rollback Plan
   [HOW_TO_UNDO]
   
   ## Verification
   - [ ] Change applied successfully
   - [ ] Systems operational
   - [ ] No new violations
   - [ ] Rollback plan verified
   
   ## Follow-up
   - [ ] Permanent fix scheduled
   - [ ] Documentation updated
   - [ ] Stakeholders notified
   - [ ] Post-mortem conducted
   EOF
   ```

4. **Implement**: Make the change
   - Follow all normal change procedures (as much as possible)
   - Document all commands and actions

5. **Verify**: Test and validate
   - Verify change was applied
   - Verify systems are operational
   - Verify no new issues introduced

6. **Report**: Notify all stakeholders
   - Security team
   - DevOps team
   - Affected service owners
   - Management (if critical)

7. **Follow-up** (Next Business Day)
   - Formal approval must be obtained
   - Permanent fix must be scheduled
   - Change must be reviewed in next team meeting
```

## 3. Automated Emergency Monitoring

```yaml
# AlertManager configuration for Kyverno
# ../../helmfile/apps/edu/monitoring/alertmanager-config.yaml

- match:
    severity: critical
    namespace: kyverno
  receiver: security-pager
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 3h

- match:
    alertname: KyvernoPolicyViolation
    severity: warning
  receiver: security-team
  group_wait: 1m
  group_interval: 10m
  repeat_interval: 1h

receivers:
- name: security-pager
  pagerduty_configs:
  - service_key: ${PAGERDUTY_SECURITY_KEY}
    description: '{{ template "kyverno.policy.violation" . }}'
    details:
      policy: '{{ .Labels.policy }}'
      namespace: '{{ .Labels.namespace }}'
      resource: '{{ .Labels.resource }}'
      severity: '{{ .Labels.severity }}'

- name: security-team
  slack_configs:
  - api_url: ${SLACK_SECURITY_WEBHOOK}
    channel: '#security-alerts'
    title: '[{{ .Status | toUpper }}] {{ .CommonLabels.alertname }}'
    text: '{{ template "kyverno.policy.violation" . }}'
    send_resolved: true
```

## 4. Emergency Contact List

| Role | Name | Phone | Email | Slack | Escalation |
|------|------|-------|-------|-------|------------|
| **Security On-Call (Primary)** | [Name] | [Phone] | [Email] | @security-oncall | 1st |
| **Security On-Call (Secondary)** | [Name] | [Phone] | [Email] | @security-oncall | 2nd |
| **CISO** | [Name] | [Phone] | ciso@opendesk... | @ciso | 3rd |
| **DevOps On-Call** | [Name] | [Phone] | [Email] | @devops-oncall | 4th |
| **DPO** | [Name] | [Phone] | dpo@opendesk... | @dpo | As needed |

**Escalation Path**: Primary → Secondary (15 min) → CISO (30 min) → DevOps (45 min)

## 5. Training Requirements

All team members who can make emergency changes must:
- [ ] Read and understand this document
- [ ] Complete Kyverno training
- [ ] Understand incident response procedures
- [ ] Know emergency contact information
- [ ] Practice emergency procedures (annual drill)
```

**Priority**: P0 (Critical - Operational risk)
**Effort**: 1 day
**Owner**: Security Team
**Dependencies**: None

---

## 2. High-Priority Gaps (P1 - Should Be Addressed)

### 🟡 2.1 Missing SIEM Integration for Security Events

#### Issue
- **No SIEM** integrated with Kyverno and security infrastructure
- **No centralized security monitoring** for policy violations
- **No correlation** of security events across components
- **No long-term retention** of security logs

#### Current State
```
✅ Deployed:
- Loki (application logging)
- Prometheus (metrics)
- Grafana (dashboards)

❌ Missing:
- SIEM for security event correlation
- Security-specific dashboards
- Long-term security log retention
- Automated incident detection
```

#### Risk
- ⚠️ **Delayed detection**: Security incidents may go unnoticed for extended periods
- ⚠️ **Limited visibility**: No holistic view of security events
- ⚠️ **Compliance gap**: BSI OPS M 3.5 (Logging) partially met
- ⚠️ **Forensic limitations**: Cannot perform comprehensive incident investigations

#### Solution Options

| Option | Pros | Cons | Effort | Cost | Best For |
|--------|------|------|--------|------|----------|
| **Elasticsearch + Kibana** | Full SIEM, ML detection, custom dashboards, scalability | High resource usage, complex to operate, expensive licensing | 10-15 days | €5,000-€50,000/year | Enterprise, large environments |
| **Graylog** | Open source, good SIEM features, easy to use | Medium complexity, less ML | 5-7 days | Free (OSS) | Mid-size environments |
| **Wazuh** | Open source, comprehensive, file integrity monitoring | Steep learning curve, complex setup | 7-10 days | Free (OSS) | Advanced security needs |
| **Splunk Cloud** | Enterprise-grade, managed, easy setup | Very expensive, vendor lock-in | 2-3 days | €50,000+/year | Enterprises with budget |
| **Loki + Grafana** | Already deployed, extendable, cost-effective | Limited SIEMfeatures, requires customization | 3-5 days | Free | Current state extension |
| **OpenSearch** | Open source Elasticsearch fork, full features | Complex to deploy and maintain | 8-12 days | Free (OSS) | Elasticsearch alternative |

#### Recommended Approach: Phased Implementation

**Phase 1 (Quick Win - 3-5 days)**: Extend existing Loki + Grafana
- ✅ No new infrastructure needed
- ✅ Quick to implement
- ✅ Low cost
- ⚠️ Limited SIEM features

**Phase 2 (Medium Term - 5-7 days)**: Add Graylog
- ✅ Open source
- ✅ Good SIEM features
- ✅ Can integrate with existing infrastructure
- ⚠️ Additional infrastructure

**Phase 3 (Long Term - 10-15 days)**: Elasticsearch + Kibana
- ✅ Full SIEM capabilities
- ✅ Machine learning detection
- ✅ Advanced analytics
- ⚠️ High cost and complexity

#### Phase 1 Implementation: Loki + Grafana for Security

```yaml
# 1. Enable Kyverno metrics (already in values.yaml.gotmpl)
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: monitoring
    interval: 30s

# 2. Grafana Dashboard for Kyverno (JSON)
{
  "title": "Kyverno Security Dashboard",
  "uid": "kyverno-security",
  "tags": ["security", "kyverno", "compliance"],
  "panels": [
    {
      "title": "Policy Violations (Last 24h)",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
      "targets": [
        {
          "expr": "sum by (policy) (rate(kyverno_policy_violations_total[24h]))",
          "legendFormat": "{{policy}}"
        }
      ]
    },
    {
      "title": "Violations by Severity",
      "type": "piechart",
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
      "targets": [
        {
          "expr": "sum by (severity) (kyverno_policy_violations_total)",
          "legendFormat": "{{severity}}"
        }
      ]
    },
    {
      "title": "Violations by Namespace",
      "type": "bargauge",
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
      "targets": [
        {
          "expr": "sum by (namespace) (kyverno_policy_violations_total)",
          "legendFormat": "{{namespace}}"
        }
      ]
    },
    {
      "title": "Compliance Score",
      "type": "gauge",
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
      "targets": [
        {
          "expr": "100 * (1 - (sum(kyverno_policy_violations_total) / sum(kyverno_policy_evaluations_total)))",
          "legendFormat": "Compliance %"
        }
      ],
      "thresholds": {
        "mode": "absolute",
        "steps": [
          {"color": "red", "value": null},
          {"color": "orange", "value": 80},
          {"color": "green", "value": 95}
        ]
      }
    },
    {
      "title": "Policy Evaluation Rate",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 16},
      "targets": [
        {
          "expr": "sum(rate(kyverno_policy_evaluations_total[5m])) by (policy)",
          "legendFormat": "{{policy}}"
        }
      ]
    },
    {
      "title": "Recent Policy Violations",
      "type": "table",
      "gridPos": {"h": 8, "w": 24, "x": 0, "y": 24},
      "targets": [
        {
          "expr": "kyverno_policy_violations_total",
          "format": "table",
          "instant": true
        }
      ],
      "transformations": [
        {"id": "organize", "options": {"excludeByName": {},"indexByName": {},"renameByName": {"Value": "Violations"}}}
      ]
    }
  ],
  "templating": {
    "list": [
      {
        "name": "namespace",
        "query": "label_values(kyverno_policy_violations_total, namespace)",
        "type": "query"
      }
    ]
  }
}
```

#### Phase 1: Alerting Configuration

```yaml
# Prometheus Alerting Rules
# ../../helmfile/apps/edu/monitoring/prometheus-rules-kyverno.yaml

groups:
- name: kyverno.alerts
  rules:
  
  # Critical: Policy violations that could indicate attacks
  - alert: KyvernoCriticalPolicyViolation
    expr: rate(kyverno_policy_violations_total{severity="critical"}[5m]) > 0
    for: 5m
    labels:
      severity: critical
      category: security
      type: kyverno
    annotations:
      summary: "Critical Kyverno policy violation detected"
      description: "Policy {{ $labels.policy }} has {{ $value }} critical violations in namespace {{ $labels.namespace }}"
      runbook_url: "https://opendesk.hrz.uni-marburg.de/docs/security/kyverno-runbook#critical-violations"
      
  # High: Multiple violations of same policy
  - alert: KyvernoHighPolicyViolationRate
    expr: rate(kyverno_policy_violations_total[5m]) > 5
    for: 5m
    labels:
      severity: high
      category: security
      type: kyverno
    annotations:
      summary: "High rate of Kyverno policy violations"
      description: "Policy {{ $labels.policy }} has {{ $value }} violations per minute in namespace {{ $labels.namespace }}"
      
  # Warning: Any policy violation (for awareness)
  - alert: KyvernoPolicyViolation
    expr: rate(kyverno_policy_violations_total[5m]) > 0
    for: 15m
    labels:
      severity: warning
      category: security
      type: kyverno
    annotations:
      summary: "Kyverno policy violation detected"
      description: "Policy {{ $labels.policy }} has violations in namespace {{ $labels.namespace }}"
      
  # Critical: All policies disabled
  - alert: KyvernoPoliciesDisabled
    expr: sum(kyverno_policy_ready_status) == 0
    for: 5m
    labels:
      severity: critical
      category: security
      type: kyverno
    annotations:
      summary: "All Kyverno policies are disabled"
      description: "No Kyverno policies are currently enforcing security controls"
      
  # High: Policy not ready
  - alert: KyvernoPolicyNotReady
    expr: kyverno_policy_ready_status == 0
    for: 10m
    labels:
      severity: high
      category: security
      type: kyverno
    annotations:
      summary: "Kyverno policy not ready"
      description: "Policy {{ $labels.policy }} is not in Ready state"
```

#### Phase 2: Graylog Implementation

```yaml
# Graylog Helm values
graylog:
  enabled: true
  
  # Deployment
  replicaCount: 2
  
  # Resources
  resources:
    requests:
      cpu: 1
      memory: 4Gi
    limits:
      cpu: 2
      memory: 8Gi
  
  # Storage
  persistence:
    enabled: true
    size: 100Gi
    storageClass: ceph-rbd-ssd
    accessModes: [ReadWriteOnce]
  
  # Elasticsearch
  elasticsearch:
    enabled: true
    replicaCount: 2
    persistence:
      size: 200Gi
      storageClass: ceph-rbd-ssd
    resources:
      requests:
        cpu: 1
        memory: 4Gi
      limits:
        cpu: 2
        memory: 8Gi
  
  # Ingesters for logs
  inputs:
    - type: "org.graylog2.inputs.gelf.udpgelf.GELFUDPIngest"
      title: "GELF UDP"
      port: 12201
      bind_address: "0.0.0.0"
    - type: "org.graylog2.inputs.syslog.udpsyslog.UDPSyslog"
      title: "Syslog UDP"
      port: 1514
      bind_address: "0.0.0.0"

# Fluent Bit sidecar for Kyverno (to send logs to Graylog)
# In values.yaml.gotmpl:
logging:
  enabled: true
  fluentBit:
    enabled: true
    image: fluent/fluent-bit:2.2
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
    config:
      outputs: |
        [OUTPUT]
        Name             gelf
        Match            *
        Host             graylog.opendesk.svc
        Port             12201
        Mode             udp
        Gelf_Short_As_Short_Tag On
        Compress         gzip
      filters: |
        [FILTER]
        Name             modify
        Match            *
        Rename           log message
        Rename           kubernetes.pod_name pod
        Rename           kubernetes.namespace_name namespace
```

**Priority**: P1 (High)
**Effort**: 3-15 days (depending on option)
**Owner**: Security Team, DevOps Team
**Dependencies**: Monitoring infrastructure, storage

---


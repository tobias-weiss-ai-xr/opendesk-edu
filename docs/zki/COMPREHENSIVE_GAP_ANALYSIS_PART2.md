# 🔍 Comprehensive Gap Analysis: ZKI IT-Grundschutz-Profil Implementation - Part 2

# SPDX-FileCopyrightText: 2026 openDesk Contributors
# SPDX-License-Identifier: Apache-2.0

## 📋 Continuation from COMPREHENSIVE_GAP_ANALYSIS.md

This document continues the comprehensive gap analysis, covering Integration Gaps, Documentation Gaps, and all Medium-Priority (P2) gaps.

---

## 🟡 High-Priority Gaps (P1) - Continued

### 🟡 5. Integration Gaps

#### 5.1 No Integration with Existing IAM
**Issue**: Kyverno policies don't integrate with existing Keycloak OIDC
**Risk**: Inconsistent access control, duplicate user management, compliance gap

**Current State**:
```
✅ Keycloak deployed (OIDC provider)
✅ Most services use Keycloak for authentication
❌ Kyverno policies don't reference Keycloak
❌ No RBAC synchronization
❌ No user/role validation in policies
```

**Required Integration**:

```yaml
# Option 1: Keycloak Group-Based Policy Enforcement
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-keycloak-auth
  annotations:
    policies.kyverno.io/title: Require Keycloak Authentication
    policies.kyverno.io/category: Access Control
    policies.kyverno.io/severity: medium
    openDesk.zki/priority: P1
    openDesk.zki/compliance: "BSI ISMS M 7.1.1"
  labels:
    openDesk.zki/category: access-control
    openDesk.zki/priority: P1
spec:
  validationFailureAction: enforce
  background: false
  rules:
  - name: check-keycloak-groups
    match:
      any:
      - resources:
          kinds:
          - Pod
          - Deployment
          - StatefulSet
    context:
    - name: keycloakGroups
      apiCall:
        url: "https://keycloak.opendesk.svc/auth/admin/realms/opendesk/groups"
        method: GET
        jmesPath: "[].name"
    validate:
      message: "Pod must be associated with a valid Keycloak group"
      pattern:
        metadata.labels.keycloak\.group: "{{ keycloakGroups[] }}"

# Option 2: Validate Service Accounts
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: validate-service-accounts
  annotations:
    policies.kyverno.io/title: Validate Service Accounts
    policies.kyverno.io/category: Access Control
    openDesk.zki/priority: P1
    openDesk.zki/compliance: "BSI ISMS M 7.1.2"
spec:
  validationFailureAction: enforce
  rules:
  - name: check-service-account
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Pod must use a valid service account"
      pattern:
        spec.serviceAccountName: "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"

# Option 3: Require Keycloak Annotations
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-keycloak-annotations
  annotations:
    policies.kyverno.io/title: Require Keycloak Annotations
    openDesk.zki/priority: P1
    openDesk.zki/compliance: "BSI ISMS M 7.1.1"
spec:
  validationFailureAction: audit
  rules:
  - name: check-annotations
    match:
      any:
      - resources:
          kinds:
          - Deployment
          - StatefulSet
    validate:
      message: "Deployment should have Keycloak integration annotations"
      pattern:
        metadata.annotations:
          keycloak\.org/realm: "opendesk"
          keycloak\.org/auth-server-url: "https://keycloak.opendesk.hrz.uni-marburg.de/auth"
```

**Owner**: Security Team, DevOps Team
**Effort**: 3-5 person-days
**Timeline**: Week 4-5

---

#### 5.2 No Integration with Existing Monitoring
**Issue**: Kyverno doesn't integrate with existing monitoring (Loki, Prometheus)
**Risk**: Limited visibility, no correlation with other metrics, manual compliance reporting

**Current State**:
```
✅ Loki deployed (logging)
✅ Prometheus deployed (metrics)
✅ Grafana deployed (dashboards)
❌ No Kyverno-specific dashboards
❌ No policy violation alerts
❌ No compliance trend tracking
```

**Required Integration**:

This is covered in **Gap 3.2 (No Policy Metrics and Dashboards)** and **Gap 3.1 (No SIEM Integration)**.

**Owner**: Monitoring Team
**Effort**: 2-3 person-days
**Timeline**: Week 2-3

---

#### 5.3 No Integration with Backup System (k8up)
**Issue**: Kyverno policies not included in k8up backup schedules
**Risk**: Policy configurations not backed up, cannot restore after disaster

**Current State**:
```
✅ k8up deployed (backup operator)
✅ Regular PVC backups configured
❌ Kyverno resources not in backup schedules
❌ No backup verification for policies
```

**Required Integration**:

```yaml
# Option 1: Label resources for k8up backup
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-backup-labels
  labels:
    k8up.io/backup: "true"
    openDesk.zki/backup: "true"
  annotations:
    openDesk.zki/compliance: "BSI DS M 5.5"
spec:
  validationFailureAction: audit
  rules:
  - name: check-backup-label
    match:
      any:
      - resources:
          kinds:
          - Deployment
          - StatefulSet
          - ConfigMap
          - Secret
    validate:
      message: "Resource should have backup label for k8up"
      pattern:
        metadata.labels:
          k8up\.io/backup: "true"

# Option 2: Create k8up Backup CR for Kyverno namespace
apiVersion: backup.appuio.ch/v1alpha1
kind: Backup
metadata:
  name: kyverno-backup-daily
  namespace: kyverno
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: kyverno
  snapshotVolumes: false
  ttl: "24h"
  schedule: "0 2 * * *"
  backend:
    s3:
      endpoint: "s3.hrz.uni-marburg.de"
      bucket: "opendesk-backups"
      prefix: "kyverno"
      accessKeyIDSecretRef:
        name: k8up-s3-creds
        key: access-key
      secretAccessKeySecretRef:
        name: k8up-s3-creds
        key: secret-key
```

**Owner**: DevOps Team
**Effort**: 1-2 person-days
**Timeline**: Week 3

---

#### 5.4 No Integration with Vulnerability Scanning
**Issue**: Kyverno doesn't integrate with Trivy vulnerability scanning
**Risk**: Vulnerable containers not blocked, compliance gap, security risk

**Current State**:
```
✅ Trivy deployed (vulnerability scanning)
✅ Regular image scans configured
❌ No policy-based blocking of vulnerable images
❌ No integration between Trivy and Kyverno
```

**Required Integration**:

```yaml
# Policy: Block images with critical vulnerabilities
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: block-critical-vulnerabilities
  annotations:
    policies.kyverno.io/title: Block Critical Vulnerabilities
    policies.kyverno.io/category: Security
    policies.kyverno.io/severity: high
    openDesk.zki/priority: P1
    openDesk.zki/compliance: "BSI INF.1 M 1.89"
  labels:
    openDesk.zki/category: vulnerability
    openDesk.zki/priority: P1
spec:
  validationFailureAction: enforce
  background: false
  webhookTimeoutSeconds: 30
  rules:
  - name: check-trivy-results
    match:
      any:
      - resources:
          kinds:
          - Pod
    context:
    - name: imageVulnerabilities
      apiCall:
        url: "http://trivy-operator.trivy.svc:8080/api/v1/namespaces/{{ request.object.metadata.namespace }}/vulnerabilityreports/{{ request.object.metadata.name }}"
        method: GET
        jmesPath: "report.vulnerabilities[?severity == 'CRITICAL'].cve"
    validate:
      message: "Image has critical vulnerabilities: {{ imageVulnerabilities[] }}"
      pattern:
        not:
          any:
          - imageVulnerabilities: "*"

# Alternative: Use Trivy Operator CRD directly
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: check-vulnerability-reports
  annotations:
    openDesk.zki/priority: P1
spec:
  validationFailureAction: enforce
  rules:
  - name: check-vulnerabilities
    match:
      any:
      - resources:
          kinds:
          - Pod
    context:
    - name: vulnReports
      apiCall:
        url: "/apis/aquasecurity.github.io/v1alpha1/namespaces/{{ request.object.metadata.namespace }}/vulnerabilityreports"
        method: GET
    validate:
      message: "Pod uses image with critical vulnerabilities"
      deny:
        conditions:
          all:
          - key: "{{ vulnReports.items[].report.vulnerabilities[].severity }}"
            operator: Equals
            value: "CRITICAL"
```

**Owner**: Security Team, DevOps Team
**Effort**: 2-3 person-days
**Timeline**: Week 4-5

---

### 🟡 6. Documentation Gaps

#### 6.1 No Runbook for Common Issues
**Issue**: No troubleshooting guide for policy violations
**Risk**: Extended resolution times, inconsistent handling, knowledge loss

**Current State**:
```
✅ Policies documented
✅ Test resources available
❌ No troubleshooting guide
❌ No common issue resolutions
❌ No FAQ
```

**Required Runbook**:

```markdown
# Kyverno Policy Runbook

## Common Policy Violations and Resolutions

### 🚫 Policy: zki-require-non-root

**Violation Message**: `validation error: running as root is not allowed`

**Cause**: Container `securityContext.runAsUser` is set to 0 or not set.

**Resolution**:
```yaml
# Option 1: Set runAsNonRoot in Pod spec
spec:
  securityContext:
    runAsNonRoot: true
    
# Option 2: Set securityContext in container
spec:
  containers:
  - name: my-container
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000  # Specific UID
```

**Testing**:
```bash
# Check current settings
kubectl get pod <pod-name> -o jsonpath='{.spec.securityContext.runAsNonRoot}'

# Verify fix
kubectl apply -f <fixed-manifest>.yaml
```

**Prevention**:
- Always set `runAsNonRoot: true` in Pod specs
- Use non-root user IDs (1000+)
- Test with compliance checker before deployment

---

### 🚫 Policy: zki-require-readonly-rootfs

**Violation Message**: `validation error: root filesystem must be read-only`

**Cause**: Container `securityContext.readOnlyRootFilesystem` is not set to true.

**Resolution**:
```yaml
spec:
  containers:
  - name: my-container
    securityContext:
      readOnlyRootFilesystem: true
      # If you need to write to emptyDir or volumes, add:
      volumeMounts:
      - name: tmp
        mountPath: /tmp
    volumes:
    - name: tmp
      emptyDir: {}
```

**Note**: This policy is currently in **audit mode** (P1 priority).

---

### 🚫 Policy: zki-drop-all-capabilities

**Violation Message**: `validation error: must drop ALL capabilities`

**Cause**: Container `securityContext.capabilities.drop` does not include ALL.

**Resolution**:
```yaml
spec:
  containers:
  - name: my-container
    securityContext:
      capabilities:
        drop:
        - ALL
      # If you need specific capabilities, add them to ADD (not drop)
      # capabilities:
      #   add:
      #   - NET_BIND_SERVICE
```

---

### 🚫 Policy: zki-require-seccomp

**Violation Message**: `validation error: seccomp profile must be set`

**Cause**: Container `securityContext.seccompProfile.type` is not set.

**Resolution**:
```yaml
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault  # or Local with specific profile
    
  containers:
  - name: my-container
    securityContext:
      seccompProfile:
        type: RuntimeDefault
```

---

### 🚫 Policy: zki-prevent-privilege-escalation

**Violation Message**: `validation error: privilege escalation must be prevented`

**Cause**: Container `securityContext.allowPrivilegeEscalation` is not set to false.

**Resolution**:
```yaml
spec:
  containers:
  - name: my-container
    securityContext:
      allowPrivilegeEscalation: false
```

---

### 🚫 Policy: zki-require-network-policy

**Violation Message**: `validation error: namespace must have NetworkPolicy`

**Cause**: Namespace has no NetworkPolicy resources.

**Resolution**:
```yaml
# Create a default-deny NetworkPolicy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: <your-namespace>
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress: []
  egress: []

# Then create specific allow policies
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-from-haproxy
  namespace: <your-namespace>
spec:
  podSelector:
    matchLabels:
      app: <your-app>
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: haproxy
    ports:
    - protocol: TCP
      port: 80
      
# Apply
kubectl apply -f network-policy.yaml
```

---

### 🚫 Policy: zki-require-tls-for-ingress

**Violation Message**: `validation error: ingress must have TLS configuration`

**Cause**: Ingress `spec.tls` section is missing.

**Resolution**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
spec:
  tls:
  - hosts:
    - my-app.opendesk.hrz.uni-marburg.de
    secretName: tls-my-app  # Must exist in namespace
  rules:
  - host: my-app.opendesk.hrz.uni-marburg.de
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

---

## 🟢 Medium-Priority Gaps (P2) - Continuous Improvement

### 🟢 7. Policy Enhancement Gaps

#### 7.1 No Custom Policies for openDesk Services
**Issue**: Generic policies may not cover openDesk-specific requirements

**Examples of Needed Policies**:
- Validate Nextcloud configuration
- Validate Moodle configuration
- Validate ILIAS configuration
- Validate Keycloak configuration
- Validate Nubus portal configuration

**Recommended**: Create service-specific policies as needed.

**Owner**: Security Team, Service Owners
**Effort**: 1-2 days per service
**Timeline**: Ongoing

---

#### 7.2 No Policy for Resource Limits
**Issue**: No enforcement of resource request/limit standards

**Risk**: Resource exhaustion, noisy neighbor problem, cluster instability

**Proposed Policy**:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
  annotations:
    policies.kyverno.io/title: Require Resource Limits
    policies.kyverno.io/category: Resource Management
    openDesk.zki/priority: P2
    openDesk.zki/compliance: "BSI INF.2 M 1.92"
  labels:
    openDesk.zki/category: resource-management
    openDesk.zki/priority: P2
spec:
  validationFailureAction: audit
  rules:
  - name: check-resource-limits
    match:
      any:
      - resources:
          kinds:
          - Pod
          - Deployment
          - StatefulSet
          - DaemonSet
          - Job
          - CronJob
    validate:
      message: "Containers must have resource requests and limits"
      pattern:
        spec:
          containers:
          - resources:
              requests:
                cpu: ">=0"
                memory: ">=0"
              limits:
                cpu: ">=0"
                memory: ">=0"
```

**Owner**: DevOps Team
**Effort**: 1 person-day
**Timeline**: Week 6-8

---

#### 7.3 No Policy for Pod Affinity/Anti-Affinity
**Issue**: No enforcement of pod scheduling requirements

**Risk**: Single point of failure, performance issues, compliance gap

**Proposed Policy**:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-pod-anti-affinity
  annotations:
    policies.kyverno.io/title: Require Pod Anti-Affinity
    policies.kyverno.io/category: High Availability
    openDesk.zki/priority: P2
    openDesk.zki/compliance: "BSI INF.2 M 1.92"
  labels:
    openDesk.zki/category: ha
    openDesk.zki/priority: P2
spec:
  validationFailureAction: audit
  rules:
  - name: check-anti-affinity
    match:
      any:
      - resources:
          kinds:
          - Deployment
          - StatefulSet
    validate:
      message: "Deployments should have pod anti-affinity for high availability"
      pattern:
        spec:
          template:
            spec:
              affinity:
                podAntiAffinity:
                  preferredDuringSchedulingIgnoredDuringExecution:
                  - weight: 100
                    podAffinityTerm:
                      labelSelector:
                        matchExpressions:
                        - key: app
                          operator: In
                          values: ["{{ request.object.spec.template.metadata.labels.app }}"]
                      topologyKey: kubernetes.io/hostname
```

**Owner**: DevOps Team
**Effort**: 1 person-day
**Timeline**: Week 6-8

---

### 🟢 8. Compliance Gaps (P2)

#### 8.1 No Regular Compliance Audits
**Issue**: No scheduled internal compliance audits
**Risk**: Compliance drift, audit findings, security gaps

**Current State**:
```
✅ Compliance checklist created
❌ No audit schedule
❌ No audit process
❌ No audit documentation
```

**Recommended Audit Schedule**:

| Audit Type | Frequency | Scope | Owner |
|------------|-----------|-------|-------|
| Internal Compliance | Quarterly | All P0/P1 requirements | Security Team |
| Internal Security | Semi-annual | All security controls | Security Team |
| External Audit | Annual | Full compliance | External Auditor |
| Spot Checks | Monthly | Random requirements | Security Team |

**Audit Process**:
1. Plan: Define scope, schedule, team
2. Prepare: Gather documentation, evidence
3. Execute: Conduct interviews, tests, reviews
4. Report: Document findings, recommendations
5. Remediate: Address findings with action plans
6. Follow-up: Verify remediation

**Owner**: Security Team, Compliance Officer
**Effort**: 2-3 person-days per audit
**Timeline**: Starting Q4 2026

---

#### 8.2 No Compliance Certification Plan
**Issue**: No plan for achieving BSI IT-Grundschutz certification
**Risk**: Missed certification opportunity, no external validation

**Recommended Certification Plan**:

```markdown
# BSI IT-Grundschutz Certification Plan

## Timeline

| Phase | Duration | Activities |
|-------|----------|------------|
| Preparation | 3 months | Gap analysis, remediation, documentation |
| ISMS Establishment | 3 months | Implement ISMS, train staff, test processes |
| Internal Audit | 1 month | Conduct internal audit, address findings |
| Pre-Audit | 2 months | Pre-audit assessment, final preparations |
| Certification Audit | 1 month | External audit, certification decision |
| **Total** | **10 months** | |

## Required Activities

### Phase 1: Preparation (Months 1-3)
- [ ] Complete all P0 and P1 actions
- [ ] Address all critical gaps
- [ ] Implement all required BSI modules
- [ ] Document all processes and procedures

### Phase 2: ISMS Establishment (Months 4-6)
- [ ] Establish Information Security Management System
- [ ] Define security organization and roles
- [ ] Implement access control procedures
- [ ] Establish incident response processes
- [ ] Implement monitoring and logging
- [ ] Conduct security awareness training

### Phase 3: Internal Audit (Month 7)
- [ ] Conduct comprehensive internal audit
- [ ] Test all security controls
- [ ] Verify documentation completeness
- [ ] Address all audit findings

### Phase 4: Pre-Audit (Months 8-9)
- [ ] Engage certification body
- [ ] Conduct pre-audit assessment
- [ ] Address pre-audit findings
- [ ] Finalize documentation

### Phase 5: Certification Audit (Month 10)
- [ ] Schedule certification audit
- [ ] Prepare for audit
- [ ] Conduct audit
- [ ] Receive certification decision

## certification Body Options
- BSI (Federal Office for Information Security)
- TÜV (Technischer Überwachungsverein)
- DEKRA
- Other accredited certification bodies

## Cost Estimate
| Item | Estimate |
|------|----------|
| Internal Preparation | €70,000-€97,500 (already budgeted) |
| External Consultant | €10,000-€20,000 (optional) |
| Certification Audit | €15,000-€25,000 |
| Annual Surveillance | €5,000-€10,000 |
| **Total** | **€100,000-€152,500** |
```

**Owner**: Security Team, Management
**Effort**: 1-2 person-days to create plan
**Timeline**: Month 1-2

---


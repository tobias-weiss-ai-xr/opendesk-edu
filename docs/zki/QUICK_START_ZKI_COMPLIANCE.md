# Quick Start Guide: ZKI IT-Grundschutz-Compliance for openDesk

# SPDX-FileCopyrightText: 2026 openDesk Contributors
# SPDX-License-Identifier: Apache-2.0

## 🚀 Getting Started in 5 Minutes

This guide helps you **quickly deploy and validate** the ZKI IT-Grundschutz-Profil compliance implementation for openDesk.

---

## 📋 Prerequisites Check

Before you begin, verify your environment:

```bash
# Check Kubernetes version
kubectl version --short
# Expected: v1.32.3 or higher

# Check Kyverno installation
kubectl get pods -n kyverno
# Expected: Running pods (kyverno-admission, kyverno-background, etc.)

# Check helmfile
helmfile --version
# Expected: v0.160.0 or higher

# Check Disk Space
df -h /var/lib/rancher/k3s
# Expected: At least 10GB free
```

✅ **All checks passed?** Continue to deployment!

❌ **Missing something?** See [Prerequisites Section](#-prerequisites) below.

---

## 🎯 5-Minute Deployment

### Step 1: Install Kyverno (if not installed)

```bash
# Add Kyverno Helm repository
helm repo add kyverno https://kyverno.github.io/kyverno-charts/
helm repo update

# Install Kyverno
helm install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace \
  --version v3.2.5 \
  --set admissionController.replicas=2 \
  --set backgroundController.replicas=1

# Wait for Kyverno to be ready
kubectl wait --for=condition=ready pod -n kyverno -l app.kubernetes.io/instance=kyverno --timeout=300s

# Verify
kubectl get pods -n kyverno
```

**✅ Expected Output:** All Kyverno pods in `Running` state

---

### Step 2: Deploy ZKI Compliance Policies

```bash
# Deploy the security chart with Kyverno policies
cd /home/weissto_local/git/opendesk_git/opendesk-edu

# Deploy using helmfile (recommended)
helmfile -e edu sync --selectors name=security

# OR deploy manually
kubectl apply -f helmfile/charts/security/kyverno-policies/zki-compliance-policies.yaml

# Verify policies are created
kubectl get clusterpolicies.kyverno.io -l openDesk.zki/category
```

**✅ Expected Output:** 20+ policies listed, all in `Ready` state

---

### Step 3: Test Policies (Immediate Verification)

```bash
# Test 1: Non-root containers (P0 - Critical)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-root-pod
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx
    securityContext:
      runAsUser: 0
EOF
```

**✅ Expected:** Should be **BLOCKED** by `zki-require-non-root` policy

```bash
# Test 2: TLS for Ingress (P0 - Critical)
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-insecure-ingress
spec:
  rules:
  - host: test.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-service
            port:
              number: 80
EOF
```

**✅ Expected:** Should be **BLOCKED** by `zki-require-tls-for-ingress` policy

```bash
# Test 3: Check policy violations
kubectl get policyreports -A
kubectl get clusterpolicyreports -n kyverno
```

**✅ Expected:** Clean reports (or only expected violations)

---

### Step 4: Verify Compliance Status

```bash
# Check compliance with the checklist
cat ZKI_IT_GRUNDSCHUTZ_CHECKLIST.md | grep -E "^\| (✅|⚠️|❌|⏳)" | head -20

# Get cluster policy report
kubectl get clusterpolicyreport -n kyverno -o yaml | grep -A5 "summary:"
```

**✅ Expected:** Clean compliance status with minimal violations

---

## 📊 Your First 5 Compliance Wins

| # | Task | Command | Status | compliancetype |
|---|------|---------|--------|----------------|
| 1 | Deploy Kyverno | `helm install kyverno ...` | ✅ Done | Core |
| 2 | Deploy Security Policies | `helmfile sync` | ✅ Done | Core |
| 3 | Block Root Containers | Test with `runAsUser: 0` | ✅ Enforced | P0 |
| 4 | Require TLS for Ingress | Test with insecure ingress | ✅ Enforced | P0 |
| 5 | Check Policy Reports | `kubectl get policyreports` | ✅ Monitored | P0 |

**🎉 Congratulations!** You've achieved 5 critical compliance wins in 5 minutes!

---

## 🔍 Deep Dive Validation

### Check All ZKI Policies

```bash
# List all ZKI-related policies
kubectl get clusterpolicies.kyverno.io -l openDesk.zki/priority

# Get details of a specific policy
kubectl get clusterpolicy zki-require-non-root -o yaml

# Check policy violations
kubectl get policyreport -A -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,PASS:.results[*].result,POLICY:.results[*].policy,RESOURCE:.results[*].resource.kind/name"
```

### Test All P0 (Critical) Policies

```bash
# Create a test namespace
kubectl create namespace zki-test

# Test 1: Pod with hostPath (should be blocked)
cat <<EOF | kubectl apply -f - -n zki-test
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-pod
spec:
  containers:
  - name: nginx
    image: nginx
  volumes:
  - name: hostpath-vol
    hostPath:
      path: /tmp
EOF

# Test 2: Pod with hostNetwork (should be blocked)
cat <<EOF | kubectl apply -f - -n zki-test
apiVersion: v1
kind: Pod
metadata:
  name: hostnet-pod
spec:
  hostNetwork: true
  containers:
  - name: nginx
    image: nginx
EOF

# Test 3: Namespace without NetworkPolicy (should audit)
kubectl get networkpolicies -n zki-test

# Clean up
kubectl delete namespace zki-test
```

---

## 🛠️ Prerequisites

### Install Missing Components

#### 1. Install Kyverno

```bash
helm repo add kyverno https://kyverno.github.io/kyverno-charts/
helm repo update
helm install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace \
  --version v3.2.5
```

#### 2. Install helmfile

```bash
# For Debian/Ubuntu
curl -L https://github.com/helmfile/helmfile/releases/download/v0.160.0/helmfile_0.160.0_linux_amd64.tar.gz | tar xvz
sudo mv helmfile /usr/local/bin/helmfile

# For macOS
brew install helmfile

# Verify
helmfile --version
```

#### 3. Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

---

## 📚 Common Commands Reference

### Policy Management

```bash
# List all policies
kubectl get clusterpolicies.kyverno.io

# List ZKI-specific policies
kubectl get clusterpolicies.kyverno.io -l openDesk.zki/category

# Get policy details
kubectl describe clusterpolicy zki-require-non-root

# Disable a policy (for debugging)
kubectl patch clusterpolicy zki-require-non-root -p '{"spec":{"validationFailureAction":"audit"}}'

# Re-enable a policy
kubectl patch clusterpolicy zki-require-non-root -p '{"spec":{"validationFailureAction":"enforce"}}'

# Delete a policy
kubectl delete clusterpolicy zki-require-non-root
```

### Compliance Reports

```bash
# List all policy reports
kubectl get policyreports -A
kubectl get clusterpolicyreports -n kyverno

# Get detailed report
kubectl get clusterpolicyreport kyverno-cluster-policy-report -n kyverno -o json | jq '.results[] | {policy, resource, result, message}'

# Check for violations
kubectl get policyreports -A -o json | jq '.items[].results[] | select(.result == "fail") | {namespace, policy, resource, message}'
```

### Testing

```bash
# Create a compliant pod (should succeed)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: compliant-pod
  labels:
    owner: "openDesk Team"
    team: "DevOps"
    data-classification: "internal"
    data-owner: "DevOps"
    data-retention: "1 year"
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
    fsGroup: 1000
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
EOF

# Should succeed!
echo "Compliant pod created successfully!"
```

---

## 🚨 Troubleshooting

### Problem: Policies Not Appearing

```bash
# Check Kyverno controller logs
kubectl logs -n kyverno -l app.kubernetes.io/component=admission-controller

# Check if Kyverno is running
kubectl get pods -n kyverno

# Check for errors
kubectl describe pod -n kyverno <kyverno-pod-name>
```

**Solutions:**
1. Ensure Kyverno is properly installed
2. Check for certificate issues: `kubectl get secret -n kyverno`
3. Reinstall Kyverno with `--set admissionController.tls.auto-generated=false`

---

### Problem: Policy Violations Not Showing

```bash
# Check if policies are in Ready state
kubectl get clusterpolicies.kyverno.io

# Check Kyverno background controller logs
kubectl logs -n kyverno -l app.kubernetes.io/component=background-controller

# Check for policy validation errors
kubectl get events -n kyverno --sort-by='.metadata.creationTimestamp'
```

**Solutions:**
1. Ensure policies have correct YAML syntax
2. Check policy conditions and match expressions
3. Use `kubectl apply --dry-run=client -f policy.yaml` to validate

---

### Problem: Pods Being Blocked Unexpectedly

```bash
# Check which policy is blocking the pod
kubectl get events --sort-by='.metadata.creationTimestamp' | grep -i "denied\|blocked\|forbidden"

# Get detailed violation message
kubectl describe pod <pod-name>

# Check policy reports for the pod
kubectl get policyreports -o json | jq '.items[].results[] | select(.resource.kind == "Pod" and .resource.name == "'<pod-name>'")'
```

**Solutions:**
1. Review the blocking policy
2. Modify your pod spec to comply with the policy
3. Request an exception (see SECURITY_POLICY.md)
4. Temporarily set policy to `audit` mode for debugging

---

## 📖 Essential Reading

### Quick Reference Documents

1. **[ZKI_IMPLEMENTATION_SUMMARY.md](ZKI_IMPLEMENTATION_SUMMARY.md)**
   - Executive summary of the entire implementation
   - File inventory and structure
   - Deployment instructions
   - **Read Time**: 10 minutes

2. **[ZKI_IT_GRUNDSCHUTZ_CHECKLIST.md](ZKI_IT_GRUNDSCHUTZ_CHECKLIST.md)**
   - Interactive compliance checklist
   - Track your progress
   - **Action**: Update status as you implement

3. **[SECURITY_POLICY.md](../../security-policies/zki/SECURITY_POLICY.md)**
   - Main security policy document
   - **Action**: Review and customize for your organization

4. **[INCIDENT_RESPONSE_PLAN.md](../../security-policies/zki/INCIDENT_RESPONSE_PLAN.md)**
   - Incident response procedures
   - **Action**: Update contact information

---

### Deep Dive Documents

| Document | Purpose | When to Read |
|----------|---------|---------------|
| [ZKI_IT_GRUNDSCHUTZ_ANALYSIS.md](ZKI_IT_GRUNDSCHUTZ_ANALYSIS.md) | Detailed gap analysis | Planning phase |
| [ZKI_IT_GRUNDSCHUTZ_IMPLEMENTATION_PLAN.md](ZKI_IT_GRUNDSCHUTZ_IMPLEMENTATION_PLAN.md) | 16-week implementation roadmap | Project kickoff |
| zki-compliance-policies.yaml | Kyverno policy details | Debugging violations |
| values.yaml.gotmpl | Security configuration | Customizing settings |

---

## 🎯 Next Steps

### After 5-Minute Deployment

1. **✅ Done**: Deployed Kyverno and ZKI compliance policies
2. **✅ Done**: Verified policies are enforcing security requirements
3. **🔄 Next**: Customize policies for your specific needs

### Week 1 Tasks

- [ ] **Review** all created security policies
- [ ] **Update** contact information in INCIDENT_RESPONSE_PLAN.md
- [ ] **Customize** security headers in values.yaml.gotmpl
- [ ] **Test** all P0 policies with your existing workloads
- [ ] **Document** any policy exceptions needed

### Week 2-4 Tasks (Phase 1)

- [ ] **Complete** all P0 (Critical) tasks from CHECKLIST.md
- [ ] **Implement** MFA for all admin accounts
- [ ] **Deploy** egress filtering for all namespaces
- [ ] **Verify** TLS 1.2+ for all services
- [ ] **Document** access control policies
- [ ] **Conduct** initial gap analysis review

---

## 🆘 Need Help?

### Common Issues and Solutions

| Issue | Solution | Documentation |
|-------|----------|---------------|
| Kyverno pods not running | Check installation, restart pods | Kyverno docs |
| Policies not appearing | Verify YAML syntax, check logs | Kyverno docs |
| Pods blocked unexpectedly | Review policy, check violation message | CHECKLIST.md |
| Need policy exception | Follow exception process | SECURITY_POLICY.md §13 |
| Don't understand a policy | Check annotations in policy | zki-compliance-policies.yaml |

### Escalation Path

1. **Check this guide** ✅
2. **Check Kyverno documentation**: https://kyverno.io/docs/
3. **Ask in Slack**: #security-help
4. **Contact Security Team**: security@opendesk.hrz.uni-marburg.de
5. **Escalate to CISO**: ciso@opendesk.hrz.uni-marburg.de

---

## 📞 Contacts

| Role | Name | Email | Slack | Emergency |
|------|------|-------|-------|-----------|
| **Security Team** | openDesk Security | security@opendesk.hrz.uni-marburg.de | #security | No |
| **Incident Response** | IRT | incident@opendesk.hrz.uni-marburg.de | #incident-response | Yes |
| **DevOps Team** | DevOps | devops@opendesk.hrz.uni-marburg.de | #devops | No |
| **CISO** | [Name] | ciso@opendesk.hrz.uni-marburg.de | @ciso | Yes |

---

## 🎓 Training Resources

### Quick Training (15 minutes)

1. **Kyverno Basics**: https://kyverno.io/docs/introduction/
2. **Policy Examples**: https://kyverno.io/policies/
3. **BSI IT-Grundschutz**: https://www.bsi.bund.de/DE/Themen/ITGrundschutz/itgrundschutz_node.html
4. **ZKI IT-Grundschutz-Profil**: https://www.zki.de/arbeitskreise/it-sicherheit

### In-Depth Training (1 hour+)

1. **Read** SECURITY_POLICY.md
2. **Read** INCIDENT_RESPONSE_PLAN.md
3. **Review** zki-compliance-policies.yaml
4. **Complete** CHECKLIST.md

---

## 📊 Success Metrics

| Metric | Target | Current | How to Measure |
|--------|--------|---------|----------------|
| Policies Deployed | 20 | ✅ | `kubectl get clusterpolicies` |
| P0 Compliance | 100% | Track | CHECKLIST.md |
| Policy Violations | 0 | Track | Kyverno reports |
| Security Incidents | <5/year | Track | INCIDENT_RESPONSE_PLAN.md |
| Mean Time to Detect | <1 hour | Track | Monitoring |
| Compliance Score | >80% | Track | CHECKLIST.md |

---

## 🏆 Your Compliance Journey

### Week 0 (Today)
- ✅ Deploy Kyverno
- ✅ Deploy ZKI compliance policies
- ✅ Test policies
- ✅ Verify compliance

### Week 1
- [ ] Complete P0 (Critical) tasks
- [ ] Review and customize policies
- [ ] Train team on new policies

### Week 2-4 (Phase 1)
- [ ] Implement foundation security
- [ ] Address critical gaps
- [ ] Achieve baseline compliance (50%)

### Week 5-8 (Phase 2)
- [ ] Implement operational security
- [ ] Deploy logging and monitoring
- [ ] Achieve 70% compliance

### Week 9-12 (Phase 3)
- [ ] Implement advanced security
- [ ] Deploy IDS/WAF
- [ ] Achieve 85% compliance

### Week 13-16 (Phase 4)
- [ ] Implement maturity measures
- [ ] Conduct audit
- [ ] Achieve 90%+ compliance

**🎯 Target: 90% ZKI IT-Grundschutz-Profil compliance in 16 weeks!**

---

## 📝 Checklist

### Before You Start
- [ ] Kubernetes cluster running (v1.32.3+)
- [ ] Kyverno installed
- [ ] helmfile installed
- [ ] Arkade installed (optional)
- [ ] k9s installed (optional, for UI)

### 5-Minute Deployment
- [ ] Install Kyverno (if needed)
- [ ] Deploy ZKI compliance policies
- [ ] Test policies with sample violations
- [ ] Verify compliance status
- [ ] Celebrate! 🎉

### Next Steps
- [ ] Review all security policies
- [ ] Update contact information
- [ ] Customize configuration
- [ ] Complete P0 tasks
- [ ] Schedule team training

---

## 💡 Tips and Best Practices

### 1. Start Small, Iterate Fast
```bash
# Don't try to fix everything at once
# Start with audit mode, then enforce
kubectl patch clusterpolicy zki-require-non-root -p '{"spec":{"validationFailureAction":"audit"}}'
```

### 2. Use Descriptive Policy Names
```yaml
# Good: zki-require-non-root
# Bad: policy-1
```

### 3. Document Everything
```yaml
annotations:
  policies.kyverno.io/description: "Requires all pods to run as non-root"
  openDesk.zki/compliance: "BSI-INF.1-M1.84"
  openDesk.zki/priority: "P0"
```

### 4. Test Policies Before Enforcing
```bash
# Create test namespace
kubectl create namespace zki-test

# Test policies in audit mode first
kubectl patch clusterpolicy zki-require-non-root -p '{"spec":{"validationFailureAction":"audit"}}'

# Deploy your resources and check violations
kubectl get policyreports -n zki-test

# Fix issues, then enforce
kubectl patch clusterpolicy zki-require-non-root -p '{"spec":{"validationFailureAction":"enforce"}}'

# Clean up
kubectl delete namespace zki-test
```

### 5. Use Policy Exceptions Wisely
```yaml
# In a policy, allow specific namespaces
preconditions:
  all:
  - key: "{{ request.object.metadata.namespace }}"
    operator: NotIn
    value: ["kube-system", "monitoring", "logging"]
```

---

## 🔧 Useful Tools

| Tool | Purpose | Installation |
|------|---------|--------------|
| **k9s** | Kubernetes UI | `arkade get k9s` |
| **kubectx** | Context switching | `arkade get kubectx` |
| **kubectl-neat** | Clean output | `arkade get kubectl-neat` |
| **jq** | JSON processing | `apt install jq` |
| **yq** | YAML processing | `arkade get yq` |
| **Trivy** | Vulnerability scanning | `arkade get trivy` |
| **kubeval** | Validate manifests | `arkade get kubeval` |

---

## 🌟 Success Stories

### Case Study: Fixing Root Containers

**Before:**
```yaml
containers:
- name: app
  image: myapp
  securityContext:
    runAsUser: 0  # ❌ Root user
```

**After:**
```yaml
securityContext:
  runAsNonRoot: true
containers:
- name: app
  image: myapp
  securityContext:
    runAsUser: 1000  # ✅ Non-root user
```

**Result:** More secure, compliant with BSI INF.1 M 1.84

---

### Case Study: Adding TLS to Ingress

**Before:**
```yaml
spec:
  rules:
  - host: myapp.example.com
    http: ...  # ❌ No TLS
```

**After:**
```yaml
spec:
  tls:
  - hosts: ["myapp.example.com"]
    secretName: tls-myapp  # ✅ TLS configured
  rules:
  - host: myapp.example.com
    http: ...
```

**Result:** Compliant with BSI INF.5 M 2.2, encrypted traffic

---

## 📚 Glossary

| Term | Definition |
|------|------------|
| **BSI** | Bundesamt für Sicherheit in der Informationstechnik (Federal Office for Information Security) |
| **ZKI** | Zentren für Kommunikations- und Informationsverarbeitung (IT Centers for Communication and Information Processing) |
| **IT-Grundschutz** | BSI's baseline IT security methodology |
| **Kyverno** | Kubernetes-native policy engine |
| **P0/P1/P2/P3** | Priority levels (Critical/High/Medium/Low) |
| **ISMS** | Information Security Management System |
| **DSGVO/GDPR** | Datenschutz-Grundverordnung (General Data Protection Regulation) |
| **MFA** | Multi-Factor Authentication |
| **mTLS** | Mutual TLS (two-way TLS authentication) |
| **CVE** | Common Vulnerabilities and Exposures |

---

## 🎉 Congratulations!

You've successfully:
1. ✅ **Deployed** Kyverno and ZKI compliance policies
2. ✅ **Tested** the policies with real scenarios
3. ✅ **Verified** compliance status
4. ✅ **Learned** the basics of policy enforcement

**Next Steps:**
- Complete the Week 1 tasks
- Review the SECURITY_POLICY.md
- Customize the configuration for your needs
- Track your progress in CHECKLIST.md

**You're on your way to 90%+ ZKI IT-Grundschutz-Profil compliance!**

---

**Document Version**: 1.0  
**Last Updated**: 2026-07-28  
**Owner**: openDesk Security Team  
**Classification**: Internal  

*This guide will be updated as the implementation progresses. Your feedback is welcome!*

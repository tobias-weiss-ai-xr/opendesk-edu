# ZKI IT-Grundschutz-Profil: Gaps and Improvements - Part 2

# SPDX-FileCopyrightText: 2026 openDesk Contributors  
# SPDX-License-Identifier: Apache-2.0

## Continuation from ZKI_GAPS_AND_IMPROVEMENTS.md

---

### 🟡 2.2 No Automated Testing for Kyverno Policies

#### Issue
- **No CI/CD pipeline** for policy changes
- **No automated testing** before deployment
- **No regression testing** for policy updates
- **No integration testing** with existing workloads

#### Risk
- ⚠️ **Production failures**: Untested policies break deployments
- ⚠️ **Security regressions**: New vulnerabilities introduced
- ⚠️ **Compliance drift**: Policies may conflict with each other
- ⚠️ **False positives/negatives**: Policies may not work as intended

#### Solution: Complete CI/CD Pipeline

```yaml
# .github/workflows/kyverno-ci-cd.yml
name: Kyverno Policy CI/CD

on:
  pull_request:
    paths:
      - '../../helmfile/charts/security/**'
      - '.github/workflows/kyverno-ci-cd.yml'
  push:
    branches: [main, release-*]
    paths:
      - '../../helmfile/charts/security/**'

# Environment variables
env:
  KUBECONFIG_FILE: ${{ github.workspace }}/kubeconfig
  KIND_CLUSTER_NAME: kyverno-test
  HELM_EXPERIMENTAL_OCI: 1

jobs:
  lint:
    name: Lint and Validate
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'

      - name: Install kyverno CLI
        run: |
          curl -sSL https://raw.githubusercontent.com/kyverno/kyverno/main/scripts/install.sh | bash
          kyverno version

      - name: Install yamllint
        run: pip install yamllint

      - name: Lint YAML files
        run: |
          yamllint -c .yamllint.yaml \
            ../../helmfile/charts/security/kyverno-policies/*.yaml

      - name: Check SPDX headers
        run: |
          echo "Checking SPDX headers..."
          MISSING=$(grep -L "SPDX-License-Identifier" \
            ../../helmfile/charts/security/kyverno-policies/*.yaml)
          if [ -n "$MISSING" ]; then
            echo "::error::Missing SPDX headers in: $MISSING"
            exit 1
          fi

      - name: Validate YAML syntax
        run: |
          echo "Validating YAML syntax..."
          for file in ../../helmfile/charts/security/kyverno-policies/*.yaml; do
            yq eval '.' "$file" > /dev/null || {
              echo "::error::Invalid YAML in $file"
              exit 1
            }
          done

      - name: Lint with kyverno CLI
        run: |
          kyverno lint \
            ../../helmfile/charts/security/kyverno-policies/zki-compliance-policies.yaml

      - name: Check for required labels
        run: |
          echo "Checking for required labels..."
          for file in ../../helmfile/charts/security/kyverno-policies/*.yaml; do
            if ! grep -q "openDesk.zki/category" "$file"; then
              echo "::error::Missing category label in $file"
              exit 1
            fi
            if ! grep -q "openDesk.zki/priority" "$file"; then
              echo "::error::Missing priority label in $file"
              exit 1
            fi
            if ! grep -q "BSI" "$file"; then
              echo "::warning::Missing BSI reference in $file"
            fi
          done

  test:
    name: Test Policies
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup KinD cluster
        uses: helm/kind-action@v1
        with:
          cluster_name: ${{ env.KIND_CLUSTER_NAME }}
          config: .github/kind-config.yaml

      - name: Install cert-manager
        run: |
          kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
          kubectl wait --for=condition=ready pod -n cert-manager -l app=cert-manager --timeout=300s

      - name: Install Kyverno
        run: |
          helm repo add kyverno https://kyverno.github.io/kyverno-charts/
          helm repo update
          helm install kyverno kyverno/kyverno \
            -n kyverno --create-namespace \
            --version v3.2.5 \
            --set admissionController.replicas=1 \
            --wait --timeout 300s

      - name: Apply policies (dry-run)
        run: |
          kubectl apply --dry-run=server -f \
            ../../helmfile/charts/security/kyverno-policies/zki-compliance-policies.yaml

      - name: Apply policies
        run: |
          kubectl apply -f \
            ../../helmfile/charts/security/kyverno-policies/zki-compliance-policies.yaml

      - name: Wait for policies to be ready
        run: |
          kubectl wait --for=condition=ready clusterpolicy -l openDesk.zki/category \
            --timeout=300s

      - name: Verify policy count
        run: |
          COUNT=$(kubectl get clusterpolicies -l openDesk.zki/category --no-headers | wc -l)
          echo " Policies deployed: $COUNT"
          if [ "$COUNT" -lt 15 ]; then
            echo "::error::Expected at least 15 policies, got $COUNT"
            kubectl get clusterpolicies -l openDesk.zki/category
            exit 1
          fi

      - name: Test with compliant resources
        run: |
          # Test compliant pod
          kubectl apply -f \
            ../../helmfile/charts/security/test-resources/test-compliant-pod.yaml
          
          # Wait for pod to be ready (should succeed)
          kubectl wait --for=condition=ready pod/test-compliant-pod --timeout=60s
          
          # Verify pod is running
          STATUS=$(kubectl get pod test-compliant-pod -o jsonpath='{.status.phase}')
          if [ "$STATUS" != "Running" ]; then
            echo "::error::Compliant pod should be Running, got: $STATUS"
            kubectl describe pod test-compliant-pod
            exit 1
          fi

      - name: Test with non-compliant resources (should be blocked)
        run: |
          # Test root pod (should be blocked)
          SET +e  # Don't fail on error
          kubectl apply -f \
            ../../helmfile/charts/security/test-resources/test-root-pod.yaml 2>&1 | \
            tee /tmp/test-output.txt
          SET -e
          
          if ! grep -q "denied\|blocked\|forbidden" /tmp/test-output.txt; then
            echo "::error::Root pod should have been blocked"
            cat /tmp/test-output.txt
            exit 1
          fi
          
          # Verify pod was NOT created
          if kubectl get pod test-root-pod 2>/dev/null; then
            echo "::error::Root pod was created, should have been blocked"
            exit 1
          fi

      - name: Test all P0 policies
        run: |
          # Get all P0 policies
          P0_POLICIES=$(kubectl get clusterpolicies -l openDesk.zki/priority=P0 \
            -o jsonpath='{.items[*].metadata.name}')
          
          echo "Testing P0 policies: $P0_POLICIES"
          
          for POLICY in $P0_POLICIES; do
            echo "  Testing $POLICY..."
            # Each P0 policy should have a corresponding test
            TEST_FILE="../../helmfile/charts/security/test-resources/test-$POLICY.yaml"
            if [ -f "$TEST_FILE" ]; then
              kubectl apply -f "$TEST_FILE" 2>&1 | grep -q "denied\|blocked\|forbidden" || {
                echo "::error::P0 policy $POLICY test failed"
                exit 1
              }
            fi
          done

      - name: Check policy reports
        run: |
          # Should have policy reports for violations
          sleep 30  # Wait for reports to be generated
          REPORTS=$(kubectl get policyreports -A --no-headers | wc -l)
          echo "Policy reports generated: $REPORTS"
          if [ "$REPORTS" -eq 0 ]; then
            echo "::warning::No policy reports generated"
          fi

  integration:
    name: Integration Test
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup KinD cluster
        uses: helm/kind-action@v1

      - name: Install dependencies
        run: |
          helm repo add kyverno https://kyverno.github.io/kyverno-charts/
          helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
          helm repo add grafana https://grafana.github.io/helm-charts
          helm repo update

      - name: Install monitoring stack
        run: |
          kubectl create namespace monitoring
          helm install prometheus prometheus-community/kube-prometheus-stack \
            -n monitoring --wait --timeout 300s
          helm install grafana grafana/grafana \
            -n monitoring --wait --timeout 300s

      - name: Install Kyverno with monitoring
        run: |
          helm install kyverno kyverno/kyverno \
            -n kyverno --create-namespace \
            --version v3.2.5 \
            --set admissionController.metricsEnabled=true \
            --set admissionController.serviceMonitor.enabled=true \
            --set admissionController.serviceMonitor.namespace=monitoring \
            --wait --timeout 300s

      - name: Deploy security chart
        run: |
          cd opendesk-edu
          helmfile -e edu sync --selectors name=security

      - name: Verify helmfile deployment
        run: |
          # Check that security release exists
          kubectl get helmfiles -n opendesk | grep security || {
            echo "::error::Security helmfile release not found"
            exit 1
          }
          
          # Check that Kyverno is running
          kubectl get pods -n kyverno
          kubectl wait --for=condition=ready pod -n kyverno --timeout=300s

  deploy-staging:
    name: Deploy to Staging
    needs: integration
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: staging
      url: https://staging.opendesk.hrz.uni-marburg.de
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure Kubernetes
        uses: azure/k8s-set-context@v3
        with:
          method: kubeconfig
          kubeconfig: ${{ secrets.KUBECONFIG_STAGING }}

      - name: Deploy to staging
        run: |
          cd opendesk-edu
          helmfile -e edu sync --selectors name=security

      - name: Verify deployment
        run: |
          kubectl get clusterpolicies -l openDesk.zki/category -n kyverno
          kubectl get pods -n kyverno

      - name: Run smoke tests
        run: |
          # Verify a few key policies
          kubectl get clusterpolicy zki-require-non-root -o jsonpath='{.spec.validationFailureAction}' | \
            grep -q "enforce" || {
              echo "::error::zki-require-non-root not in enforce mode"
              exit 1
            }

  deploy-production:
    name: Deploy to Production
    needs: deploy-staging
    if: github.ref == 'refs/tags/v*'
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://opendesk.hrz.uni-marburg.de
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure Kubernetes
        uses: azure/k8s-set-context@v3
        with:
          method: kubeconfig
          kubeconfig: ${{ secrets.KUBECONFIG_PRODUCTION }}

      - name: Deploy to production
        run: |
          cd opendesk-edu
          helmfile -e edu sync --selectors name=security

      - name: Verify production deployment
        run: |
          kubectl get clusterpolicies -l openDesk.zki/category
          kubectl rollout status deployment -n kyverno kyverno-admission-controller

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: ${{ github.ref_name }}
          name: Release ${{ github.ref_name }}
          body: |
            Security policy update ${{ github.ref_name }}
            
            ## Changes
            - Updated Kyverno policies
            
            ## Verification
            - [ ] Production deployment successful
            - [ ] All policies in Ready state
            - [ ] No new violations
          draft: false
          prerelease: false
```

#### Test Resources Structure

```
../../helmfile/charts/security/test-resources/
├── README.md                    # Test instructions
├── test-compliant-pod.yaml      # Should PASS
├── test-root-pod.yaml           # Should FAIL (zki-require-non-root)
├── test-hostpath-pod.yaml       # Should FAIL (zki-restrict-host-path)
├── test-hostnet-pod.yaml        # Should FAIL (zki-restrict-host-network)
├── test-passwd-file.yaml        # Should FAIL (zki-restrict-passwd-file)
├── test-insecure-ingress.yaml   # Should FAIL (zki-require-tls-for-ingress)
├── test-host-pid-pod.yaml       # Should FAIL (zki-restrict-host-pid)
├── test-host-ipc-pod.yaml       # Should FAIL (zki-restrict-host-ipc)
├── test-privileged-pod.yaml     # Should FAIL (zki-drop-all-capabilities)
├── test-no-readonly-pod.yaml    # Should AUDIT (zki-require-readonly-rootfs)
├── test-no-networkpolicy-ns.yaml # Should AUDIT (zki-require-network-policy)
└── test-missing-headers.yaml    # Should AUDIT (zki-require-security-headers)
```

**Priority**: P1 (High)
**Effort**: 3-5 days
**Owner**: DevOps Team
**Dependencies**: GitHub Actions, KinD cluster for testing

---

### 🟡 2.3 Missing Policy Metrics and Grafana Dashboards

#### Issue
- **No Prometheus metrics** for policy violations
- **No Grafana dashboards** for compliance monitoring
- **No historical data** retention for compliance reporting
- **No alerting** for policy violations

#### Current State
```
✅ Kyverno generates policy violations
✅ Kyverno can export metrics (not enabled)
❌ No Prometheus scraping configured
❌ No Grafana dashboards for security
❌ No alerts for security events
```

#### Risk
- ⚠️ **Limited visibility**: Cannot track compliance over time
- ⚠️ **No proactive monitoring**: Policy violations may go unnoticed
- ⚠️ **Compliance reporting**: Manual effort required for audits
- ⚠️ **No trend analysis**: Cannot identify security improvements or regressions

#### Solution: Complete Monitoring Stack

**1. Enable Kyverno Metrics (already in values.yaml.gotmpl)**

```yaml
# In ../../helmfile/apps/edu/security/values.yaml.gotmpl
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: monitoring
    interval: 30s
    scrapeTimeout: 10s
    labels:
      release: prometheus-operator
```

**2. Prometheus Alerting Rules**

```yaml
# ../../helmfile/apps/edu/monitoring/prometheus-rules-kyverno.yaml

groups:
- name: kyverno.rules
  interval: 5m
  rules:

  # Metrics
  - record: kyverno:policy_evaluations:rate5m
    expr: sum by (policy) (rate(kyverno_policy_evaluations_total[5m]))

  - record: kyverno:policy_violations:rate5m
    expr: sum by (policy, severity, namespace) (rate(kyverno_policy_violations_total[5m]))

  - record: kyverno:policy_violations:total
    expr: sum by (policy) (kyverno_policy_violations_total)

  # Compliance score
  - record: kyverno:compliance_score
    expr: 100 * (1 - (sum(rate(kyverno_policy_violations_total[5m])) / sum(rate(kyverno_policy_evaluations_total[5m]))))

- name: kyverno.alerts
  rules:

  # Critical alerts
  - alert: KyvernoPolicyDisabled
    expr: kyverno_policy_ready_status == 0
    for: 10m
    labels:
      severity: critical
      category: security
      type: kyverno
    annotations:
      summary: "Kyverno policy {{ $labels.policy }} is not ready"
      description: "Policy {{ $labels.policy }} has been disabled or is not functioning"
      runbook_url: "https://opendesk.hrz.uni-marburg.de/docs/security/kyverno-runbook#policy-not-ready"

  - alert: KyvernoAdmissionControllerDown
    expr: sum(up{job="kyverno-admission-controller"}) by (job) == 0
    for: 5m
    labels:
      severity: critical
      category: security
      type: kyverno
    annotations:
      summary: "Kyverno admission controller is down"
      description: "All Kyverno admission controllers are down - no policies are being enforced"
      runbook_url: "https://opendesk.hrz.uni-marburg.de/docs/security/kyverno-runbook#admission-controller-down"

  - alert: HighPolicyViolationRate
    expr: sum(rate(kyverno_policy_violations_total[5m])) by (policy) > 10
    for: 10m
    labels:
      severity: critical
      category: security
      type: kyverno
    annotations:
      summary: "High rate of policy violations for {{ $labels.policy }}"
      description: "Policy {{ $labels.policy }} has {{ $value }} violations per minute"

  # High alerts
  - alert: KyvernoPolicyViolations
    expr: sum(rate(kyverno_policy_violations_total[5m])) by (policy, namespace) > 0
    for: 30m
    labels:
      severity: high
      category: security
      type: kyverno
    annotations:
      summary: "Kyverno policy violations in {{ $labels.namespace }}"
      description: "Policy {{ $labels.policy }} has violations in namespace {{ $labels.namespace }}"

  - alert: MultiplePoliciesNotReady
    expr: sum(kyverno_policy_ready_status == 0) > 3
    for: 15m
    labels:
      severity: high
      category: security
      type: kyverno
    annotations:
      summary: "Multiple Kyverno policies are not ready"
      description: "{{ $value }} Kyverno policies are not in Ready state"

  # Warning alerts
  - alert: KyvernoPolicyNotReady
    expr: kyverno_policy_ready_status == 0
    for: 5m
    labels:
      severity: warning
      category: security
      type: kyverno
    annotations:
      summary: "Kyverno policy {{ $labels.policy }} is not ready"
      description: "Policy may be experiencing issues"

  - alert: LowComplianceScore
    expr: kyverno:compliance_score < 80
    for: 1h
    labels:
      severity: warning
      category: security
      type: kyverno
    annotations:
      summary: "Low Kyverno compliance score ({{ $value }}%)"
      description: "Overall compliance score has dropped below 80%"
```

**3. Grafana Dashboards**

Create comprehensive dashboards in JSON format and store them in:
```
../../helmfile/apps/edu/monitoring/grafana-dashboards/
  ├── kyverno-overview.json
  ├── kyverno-policies.json
  ├── kyverno-compliance.json
  └── security-metrics.json
```

**4. Compliance Reporting Tool**

```python
#!/usr/bin/env python3
"""
Kyverno Compliance Reporting Tool
Generates compliance reports for audits
"""

import json
import yaml
from datetime import datetime
from kubernetes import client, config
import pandas as pd

def get Policy_violations():
    """Get all policy violations"""
    config.load_kube_config()
    v1 = client.CustomObjectsApi()
    
    # Get ClusterPolicyReports
    reports = v1.list_cluster_custom_object(
        group="wgpolicyk8s.io",
        version="v1alpha2",
        plural="clusterpolicyreports"
    )
    
    violations = []
    for report in reports['items']:
        for result in report.get('results', []):
            if result.get('result') == 'fail':
                violations.append({
                    'timestamp': report['metadata']['creationTimestamp'],
                    'policy': result.get('policy'),
                    'resource': result.get('resource', {}).get('name'),
                    'kind': result.get('resource', {}).get('kind'),
                    'namespace': result.get('resource', {}).get('namespace'),
                    'severity': result.get('severity'),
                    'message': result.get('message'),
                    'score': result.get('score')
                })
    
    return pd.DataFrame(violations)

def generate_compliance_report(output_file='compliance-report.html'):
    """Generate HTML compliance report"""
    df = get_policy_violations()
    
    # Calculate compliance metrics
    total_policies = len(df['policy'].unique())
    total_violations = len(df)
    violations_by_severity = df['severity'].value_counts().to_dict()
    violations_by_policy = df['policy'].value_counts().head(10).to_dict()
    
    # Create report
    report = f"""
    <html>
    <head><title>Kyverno Compliance Report - {datetime.now().strftime('%Y-%m-%d')}</title></head>
    <body>
    <h1>Kyverno Compliance Report</h1>
    <p>Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
    
    <h2>Executive Summary</h2>
    <table>
    <tr><th>Metric</th><th>Value</th></tr>
    <tr><td>Total Policies</td><td>{total_policies}</td></tr>
    <tr><td>Total Violations</td><td>{total_violations}</td></tr>
    <tr><td>Compliance Score</td><td>{100 - (total_violations / (total_violations + 1) * 100):.1f}%</td></tr>
    </table>
    
    <h2>Violations by Severity</h2>
    <table>
    <tr><th>Severity</th><th>Count</th><th>Percentage</th></tr>
    """
    
    for severity, count in violations_by_severity.items():
        percentage = (count / total_violations * 100) if total_violations > 0 else 0
        report += f"<tr><td>{severity}</td><td>{count}</td><td>{percentage:.1f}%</td></tr>"
    
    report += """
    </table>
    
    <h2>Top 10 Violated Policies</h2>
    <table>
    <tr><th>Policy</th><th>Violations</th></tr>
    """
    
    for policy, count in violations_by_policy.items():
        report += f"<tr><td>{policy}</td><td>{count}</td></tr>"
    
    report += """
    </table>
    
    <h2>Detailed Violations</h2>
    <table>
    <tr><th>Timestamp</th><th>Policy</th><th>Resource</th><th>Kind</th><th>Namespace</th><th>Message</th></tr>
    """
    
    for _, row in df.head(100).iterrows():
        report += f"""
        <tr>
        <td>{row['timestamp']}</td>
        <td>{row['policy']}</td>
        <td>{row['resource']}</td>
        <td>{row['kind']}</td>
        <td>{row['namespace']}</td>
        <td>{row['message'][:100]}...</td>
        </tr>
        """
    
    report += """
    </table>
    </body>
    </html>
    """
    
    with open(output_file, 'w') as f:
        f.write(report)
    
    print(f"Report generated: {output_file}")

if __name__ == '__main__':
    generate_compliance_report()
```

**Priority**: P1 (High)
**Effort**: 2-3 days
**Owner**: Monitoring Team
**Dependencies**: Prometheus, Grafana, Alertmanager

---


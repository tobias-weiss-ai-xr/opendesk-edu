# Loki and Promtail Setup Verification

**Generated:** 2026-02-20
**Status:** NOT INSTALLED
**Impact:** No centralized log aggregation for troubleshooting

---

## Verification Results

### Loki Status
| Component | Status | Details |
|-----------|--------|---------|
| **Loki Pods** | ❌ Not Found | No pods containing "loki" found in any namespace |
| **Loki Namespace** | ❌ Not Found | No dedicated Loki namespace exists |
| **Loki Service** | ❌ Not Verified | Cannot verify without pods |

### Promtail Status
| Component | Status | Details |
|-----------|--------|---------|
| **Promtail Pods** | ❌ Not Found | No pods containing "promtail" found in any namespace |
| **DaemonSet** | ❌ Not Found | Promtail typically runs as a DaemonSet |

### Grafana Datasources
| Datasource | Status | Notes |
|------------|--------|-------|
| **Loki** | ❌ Not Configured | Grafana config does not show Loki datasource |
| **Prometheus** | ✅ Available | `kube-prom-stack-kube-prome-prometheus` is configured |

---

## Why Loki/Promtail is Not Installed

Based on the verification, Loki and Promtail are **not installed** in the cluster.

### Potential Reasons
1. **Simplified Monitoring Setup**: The cluster uses kube-prometheus-stack without Loki add-ons
2. **Alternative Log Collection**: May be using Kubernetes native `kubectl logs` or external log management
3. **Phase-based Rollout**: May be planned for future implementation

---

## Installation Options

### Option 1: Install Loki and Promtail via Helm (Recommended)
```bash
# Add Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Loki
helm upgrade --install loki grafana/loki-stack -n loki --create-namespace

# Or install Loki & Promtail separately
helm upgrade --install loki grafana/loki -n loki --create-namespace
helm upgrade --install promtail grafana/promtail -n loki --set loki.serviceName=loki
```

### Option 2: Install via ArgoCD (GitOps)
Add to your ArgoCD applications:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: loki
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://grafana.github.io/helm-charts
    chart: loki-stack
    targetRevision: 2.10.2
  destination:
    server: https://kubernetes.default.svc
    namespace: loki
```

### Option 3: Use Elasticsearch + Fluent Bit (Alternative)
If your organization prefers Elasticsearch over Loki:
```bash
helm repo add elastic https://helm.elastic.co
helm repo update

# Install Elasticsearch
helm upgrade --install elasticsearch elastic/elasticsearch -n elk

# Install Fluent Bit
helm upgrade --install fluent-bit elastic/fluent-bit -n elk
```

---

## Loki/Promtail Configuration (for Future Installation)

### Loki Values (`values.yaml`)
```yaml
# Basic Loki configuration
loki:
  commonConfig:
    replication_factor: 1
  storage:
    type: filesystem
  schemaConfig:
    configs:
      - from: 2020-10-24
        store: boltdb-shipper
        object_store: filesystem
        schema: v11
        index:
          prefix: index_
          period: 24h

# Use persistent storage for logs
persistence:
  enabled: true
  size: 10Gi
  storageClassName: ceph-rbd

# Enable Grafana integration
serviceMonitor:
  enabled: true
```

### Promtail Values (`values.yaml`)
```yaml
# Scrape logs from all namespaces
config:
  clients:
    - url: http://loki:3100/loki/api/v1/push

  snippets:
    scrapeConfigs: |
      - job_name: kubernetes-pods
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels:
              - __meta_kubernetes_pod_label_app_kubernetes_io_name
            target_label: app
          - source_labels:
              - __meta_kubernetes_pod_label_app_kubernetes_io_instance
            target_label: instance
          - source_labels:
              - __meta_kubernetes_pod_label_app_kubernetes_io_component
            target_label: component
          - source_labels:
              - __meta_kubernetes_pod_node_name
            target_label: node_name
          - source_labels:
              - __meta_kubernetes_namespace
            target_label: namespace

# Enable service monitor for metrics monitoring
serviceMonitor:
  enabled: true
```

---

## Grafana Loki Datasource Configuration

After installing Loki, add thedatasource to Grafana:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  namespace: opendesk
data:
  datasources.yaml: |
    apiVersion: 1
    datasources:
      - name: Loki
        type: loki
        url: http://loki.loki.svc.cluster.local:3100
        access: proxy
        isDefault: false
        editable: true
```

Or apply via CLI:
```bash
kubectl create configmap grafana-datasources -n opendesk \
  --from-file=datasources.yaml --dry-run=client -o yaml | kubectl apply -f -

kubectl rollout restart deployment -n opendesk kube-prom-stack-grafana
```

---

## LogQL Queries for OpenDesk

Once installed, use these LogQL queries:

### UDS LDAP Authentication Failures
```logql
{namespace="opendesk", app=~".*ums-ldap.*"} |= "authentication failed"
```

### UDM Transformer Errors
```logql
{namespace="opendesk", pod=~".*ums-provisioning-udm-transformer.*"} |= "ERROR"
```

### Backup Job Errors
```logql
{namespace="opendesk", pod=~".*k8up-.*"} |= "error" | kal
```

### Keycloak Login Failures
```logql
{namespace="opendesk", app="ums-keycloak"} |= "invalid_user_credentials"
```

### Nextcloud Sync Errors
```logql
{namespace="opendesk", app=~".*nextcloud.*"} |= "sync error"
```

---

## Storage Requirements

| Component | Storage | Notes |
|-----------|---------|-------|
| **Loki** | 10Gi+ | Depends on log retention policy |
| **Promtail** | None | Stateless, no storage needed |
| **Elasticsearch** (alternative) | 50Gi+ | More resource-intensive |

---

## Recommendations

### Immediate (Phase 1)
1. Install Loki and Promtail via Helm or ArgoCD
2. Configure Loki to use Ceph RBD storage
3. Set up log retention policy (e.g., 30 days)
4. Add Loki datasource to existing Grafana

### Short-term (Phase 2)
1. Create log-based panels in existing dashboards
2. Set up LogQL alerts for critical errors
3. Configure log scraping for all OpenDesk components
4. Test log queries for UMS and backup components

### Medium-term (Phase 3)
1. Implement log-based metrics (parse logs for metrics)
2. Configure log sampling for high-volume pods
3. Set up log correlation with traces (if using OpenTelemetry)
4. Create dedicated LogQL dashboards

### Long-term (Phase 4)
1. Implement log retention policies based on compliance
2. Set up log forwarding to external SIEM (optional)
3. Configure multi-tenant Loki (if multiple teams)
4. Optimize log ingestion rate and storage usage

---

## Troubleshooting Commands

```bash
# Check Loki pods
kubectl get pods -n loki

# Check Promtail logs
kubectl logs -n loki promtail-xxxxx -f

# Check Loki ingestion
kubectl logs -n loki loki-xxxxx -f | grep "ingester"

# Test Loki query
curl -s http://loki.loki.svc.cluster.local:3100/loki/api/v1/query_range \
  --data-urlencode 'query={namespace="opendesk"}' \
  --data-urlencode 'limit=100' | jq .

# Check Prometheus targets for Loki
kubectl get prometheus -n opendesk
```

---

## Summary

| Metric | Status |
|--------|--------|
| Loki Installed | ❌ No |
| Promtail Installed | ❌ No |
| Centralized Logging Available | ❌ No |
| Grafana Loki Datasource | ❌ Not configured |
| LogQL Queries Available | ❌ No |

**Next Steps:** Install Loki and Promtail to enable centralized log aggregation and log-based alerting for the OpenDesk cluster.
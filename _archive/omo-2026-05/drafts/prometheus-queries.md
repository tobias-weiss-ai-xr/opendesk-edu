# Prometheus Metrics and Queries

**Generated:** 2026-02-20
**Purpose:** Document available Prometheus metrics for K8up and UMS monitoring

---

## Available Metrics Overview

### K8up Metrics
The following K8up-specific metrics are exposed:

| Metric | Description | Available |
|--------|-------------|-----------|
| `k8up_jobs_successful_counter` | Total number of successful K8up jobs | ✅ Yes |
| `k8up_jobs_total` | Total number of K8up jobs | ✅ Yes |
| `k8up_schedules_gauge` | Number of active backup schedules | ✅ Yes |

### Standard Kubernetes Metrics (for K8up and UMS)

#### Job/Backup Status
| Metric | Description | Example Query |
|--------|-------------|---------------|
| `kube_job_status_active` | Number of currently active jobs | `kube_job_status_active{job_name=~"backup-.*"}` |
| `kube_job_status_completion_time` | Job completion timestamp | `kube_job_status_completion_time{job_name=~"backup-.*-backup-.*"}` |
| `kube_job_status_failed_total` | Total failed job count | `kube_job_status_failed_total{job_name=~"backup-.*"}` |
| `kube_job_info` | Job metadata | `kube_job_info{job_name=~"backup-.*"}` |

#### Pod Health
| Metric | Description | Example Query |
|--------|-------------|---------------|
| `kube_pod_status_phase` | Pod phase (Running/Pending/Failed) | `kube_pod_status_phase{namespace="opendesk"}` |
| `kube_pod_container_status_restarts_total` | Container restart count | `kube_pod_container_status_restarts_total{namespace="opendesk"}` |
| `kube_pod_container_status_ready` | Container readiness status | `kube_pod_container_status_ready{namespace="opendesk"} == 0` |

#### PVC/Storage
| Metric | Description | Example Query |
|--------|-------------|---------------|
| `kube_persistentvolumeclaim_info` | PVC metadata | `kube_persistentvolumeclaim_info{namespace="opendesk"}` |
| `kube_persistentvolumeclaim_resource_requests_storage_bytes` | PVC storage request | `sum(kube_persistentvolumeclaim_resource_requests_storage_bytes{namespace="opendesk"})` |
| `kubelet_volume_stats_used_bytes` | Volume used space | `sum(kubelet_volume_stats_used_bytes{namespace="opendesk"})` |
| `kubelet_volume_stats_capacity_bytes` | Volume capacity | `sum(kubelet_volume_stats_capacity_bytes{namespace="opendesk"})` |

---

## K8up Backup Monitoring Queries

### Backup Job Status
```promql
# Successful backups in last 24h
increase(k8up_jobs_successful_counter{namespace="opendesk"}[24h])

# Total backup jobs
k8up_jobs_total{namespace="opendesk"}

# Active backup jobs (stuck)
kube_job_status_active{namespace="opendesk", job_name=~"backup-.*-backup-.*"} > 0
```

### Backup Health
```promql
# Backup success rate (last 7 days)
(
  increase(k8up_jobs_successful_counter{namespace="opendesk"}[7d])
  /
  increase(k8up_jobs_total{namespace="opendesk"}[7d])
) * 100

# Time since last successful backup
time() - max(kube_job_status_completion_time{namespace="opendesk", job_name=~"backup-.*-backup-.*", status="succeeded"})
```

### Prune Job Status
```promql
# Successful prune jobs
increase(kube_job_status_succeeded_total{namespace="opendesk", job_name=~"prune-.*"}[24h])

# Failed prune jobs
increase(kube_job_status_failed_total{namespace="opendesk", job_name=~"prune-.*"}[24h])
```

### Snapshot Count
```promql
# Total snapshots
count(k8up_snapshots_info{namespace="opendesk"})

# Snapshots by repository
count by (repository) (k8up_snapshots_info{namespace="opendesk"})
```

---

## UMSHealth Monitoring Queries

### UMS Component Health
```promql
# UMS pods by status
sum by (phase) (kube_pod_status_phase{namespace="opendesk", pod=~".*ums-.*"})

# UMS replicas ready vs desired
(kube_statefulset_status_replicas_ready{namespace="opendesk", statefulset=~".*ums-.*"}
or
kube_deployment_status_replicas_available{namespace="opendesk", deployment=~".*ums-.*"})

# UMS pods with restarts
kou_pod_container_restarts_total{namespace="opendesk", pod=~".*ums-.*", container!="POD"}
```

### LDAP Server Health
```promql
# LDAP primary and secondary pods
kube_pod_status_phase{namespace="opendesk", pod=~".*ums-ldap-server-(primary|secondary).*"}

# LDAP replica health
kube_statefulset_status_replicas_ready{namespace="opendesk", statefulset=~".*ums-ldap-server.*"}

# LDAP pod restarts (alert if > 0)
kube_pod_container_status_restarts_total{namespace="opendesk", pod=~".*ums-ldap-server.*"}
```

### UMS Provisioning Components
```promql
# UDM Transformer (currently failing - CrashLoopBackOff)
kube_pod_status_phase{namespace="opendesk", pod=~".*ums-provisioning-udm-transformer.*"}

# UDM Listener
kube_pod_status_phase{namespace="opendesk", pod=~".*ums-provisioning-udm-listener.*"}

# Portal Consumer
kube_pod_status_phase{namespace="opendesk", pod=~".*ums-portal-consumer.*"}

# UDM REST API
kube_deployment_status_replicas_available{namespace="opendesk", deployment="ums-udm-rest-api"}
```

### Keycloak/UMS
```promql
# Keycloak pods
kube_statefulset_status_replicas_ready{namespace="opendesk", statefulset="ums-keycloak"}

# Keycloak extensions handler/proxy
kube_deployment_status_replicas_available{namespace="opendesk", deployment=~".*ums-keycloak-.*"}
```

---

## General Health Queries

### Pod Health Summary
```promql
# Pods by phase in opendesk namespace
sum by (phase) (kube_pod_status_phase{namespace="opendesk"})

# Pods with high restart rate (> 3 in 15min)
rate(kube_pod_container_status_restarts_total{namespace="opendesk"}[15m]) > 0.2

# Pods not ready (potential issues)
kube_pod_container_status_ready{namespace="opendesk"} == 0
```

### Resource Usage
```promql
# Total memory by UMS component
sum by (pod) (container_memory_working_set_bytes{namespace="opendesk", pod=~".*ums-.*", container!=""})

# Total CPU by UMS component
sum by (pod) (rate(container_cpu_usage_seconds_total{namespace="opendesk", pod=~".*ums-.*"}[5m]))
```

---

## Alert Query Examples

### Critical Alerts
```promql
# udm-transformer not running (CrashLoopBackOff)
kube_pod_status_phase{namespace="opendesk", pod=~".*ums-provisioning-udm-transformer.*", phase="Running"} == 0

# No successful backups in 24h
(time() - max(kube_job_status_completion_time{namespace="opendesk", job_name=~"backup-.*-backup-.*", status="succeeded"})) > 24*3600

# LDAP primary pod down
kube_pod_status_phase{namespace="opendesk", pod=~".*ums-ldap-server-primary.*", phase="Running"} == 0

# High pod restart rate
rate(kube_pod_container_status_restarts_total{namespace="opendesk", pod=~".*ums-.*"}[15m]) > 0.2
```

### Warning Alerts
```promql
# LDAP secondary scaled to zero (expected behavior but worth monitoring)
kube_statefulset_status_replicas_ready{namespace="opendesk", statefulset="ums-ldap-server-secondary"} < 1

# Pending UMS pods
count(kube_pod_status_phase{namespace="opendesk", pod=~".*ums-.*", phase="Pending"}) > 0

# Backup duration > 1 hour (needs custom metric, not available in current setup)
```

---

## Missing UMS Metrics

The UMS components do **NOT** expose custom metrics for:

### LDAP
- LDAP query latency
- LDAP authentication success/failure rate
- LDAP connection pool metrics
- LDAP replication lag
- LDAP bind errors

### UDM
- UDM sync event count
- UDM transformation success/failure rate
- UDM API latency
- UDM backlog size

### Portal
- Portal event processing rate
- Portal API latency
- Portal consumer errors

### Keycloak
- Keycloak login success/failure rate
- Keycloak session count
- Keycloak token issues

---

## Recommendations

### Short-term (use available metrics)
1. Monitor UMS pod health via standard K8s metrics
2. Alert on udm-transformer CrashLoopBackOff
3. Alert on LDAP primary pod downtime
4. Track UMS component restart rates

### Medium-term (enhance metrics)
1. Enable **Prometheus exporter for LDAP** (slapd-metrics or custom exporter)
2. Enable **Keycloak metrics collection** via Prometheus plugin
3. Add **custom metrics** to UDM listener and transformer
4. Expose **portal consumer event processing metrics**

### Long-term (comprehensive monitoring)
1. Deploy **OpenTelemetry** for distributed tracing
2. Integrate **Loki** for log-based metrics
3. Configure **custom alert rules** for UMS-specific health
4. Add **performance baselines** and anomaly detection

---

## Testing Commands

```bash
# Test Prometheus connection
kubectl exec -n opendesk prometheus-kube-prom-stack-kube-prome-prometheus-0 -- \
  wget -qO- http://localhost:9090/api/v1/query?query=k8up_jobs_total

# Check K8up metrics
kubectl exec -n opendesk prometheus-kube-prom-stack-kube-prome-prometheus-0 -- \
  wget -qO- 'http://localhost:9090/api/v1/query?query={__name__=~"k8up_.*"}'

# Check UMS pod status
kubectl get pods -n opendesk | grep ums

# Check UDM transformer logs
kubectl logs -n opendesk ums-provisioning-udm-transformer-68b5f6f765-hh6zc --tail=50
```
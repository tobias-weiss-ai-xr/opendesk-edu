# Monitoring Setup Guide

This guide provides detailed instructions for setting up comprehensive monitoring for openDesk Edu deployments.

## Overview

openDesk Edu uses Prometheus-based monitoring with Grafana dashboards for observability across all services.

**Monitoring Stack Components:**

- **Prometheus** - Metrics collection and storage
- **Grafana** - Dashboard and visualization
- **Alertmanager** - Alert routing and notification
- **Loki** - Log aggregation (optional)
- **Promtail** - Log collection (optional)

## Prerequisites

- Kubernetes 1.28+ cluster
- Helm 3+ installed
- Sufficient cluster resources (recommend: 4 CPU cores, 16GB RAM for monitoring stack)
- Persistent storage for Prometheus (50GB+) and Grafana (5GB+)

## Quick Start

### 1. Install Monitoring Stack

```bash
# Add Prometheus Community Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values helmfile/environments/default/monitoring.yaml.gotmpl
```

### 2. Enable Service Monitors

Edit `helmfile/environments/default/monitoring.yaml.gotmpl`:

```yaml
monitoring:
  prometheus:
    prometheusSpec:
      serviceMonitors:
        enabled: true
      podMonitors:
        enabled: true
      prometheusRules:
        enabled: true
      serviceMonitorSelectorNilUsesHelmValues: true
      podMonitorSelectorNilUsesHelmValues: true
      serviceMonitorNamespaceSelector:
        matchLabels:
          monitoring: enabled
      podMonitorNamespaceSelector:
        matchLabels:
          monitoring: enabled
```

### 3. Enable Grafana Dashboards

```yaml
monitoring:
  grafana:
    enabled: true
    defaultDashboardsTimezone: Europe/Berlin
    sidecar:
      dashboards:
        enabled: true
        label: grafana_dashboard
      datasources:
        enabled: true
        label: prometheus_datasource
```

### 4. Access Grafana

```bash
# Port-forward to Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Or access via Ingress (if configured)
# https://grafana.yourdomain.de
```

Default credentials:

- Username: `admin`
- Password: Get via: `kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 -d`

## Service-Specific Monitoring

### Keycloak Monitoring

#### PodMonitor

Create `helmfile/charts/keycloak/templates/podmonitor.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: keycloak
  namespace: keycloak
  labels:
    monitoring: enabled
spec:
  selector:
    matchLabels:
      app: keycloak
  podMetricsEndpoints:
    - port: metrics
      path: /metrics
      interval: 30s
```

#### Key Metrics

- **Authentication:** `keycloak_logins_total`, `keycloak_failed_login_attempts_total`
- **Session Management:** `keycloak_active_sessions`, `keycloak_session_created_total`
- **Performance:** `http_server_requests_seconds`, `jvm_memory_used_bytes`
- **Database:** `keycloak_db_connection_pool_active`, `keycloak_db_query_duration_seconds`

#### Alerts

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: keycloak-alerts
  namespace: monitoring
spec:
  groups:
    - name: keycloak
      rules:
        - alert: KeycloakHighFailedLogins
          expr: rate(keycloak_logins_total{result="failed"}[5m]) > 10
          for: 2m
          labels:
            severity: warning
            service: keycloak
          annotations:
            summary: High failed login rate detected
            description: "Failed login rate > 10/min for 2 minutes"

        - alert: KeycloakDatabaseDown
          expr: keycloak_db_connection_pool_active == 0
          for: 1m
          labels:
            severity: critical
            service: keycloak
          annotations:
            summary: Keycloak database connection lost
            description: "No active database connections"
```

### ILIAS Monitoring

#### PodMonitor

Create `helmfile/charts/ilias/templates/podmonitor.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: ilias
  namespace: ilias
  labels:
    monitoring: enabled
spec:
  selector:
    matchLabels:
      app: ilias
  podMetricsEndpoints:
    - port: metrics
      interval: 60s
```

#### Key Metrics

- **User Activity:** `ilias_active_users`, `ilias_sessions_total`
- **Course Access:** `ilias_course_access_total`, `ilias_object_access_total`
- **Performance:** `ilias_page_load_duration_seconds`, `ilias_api_response_time`
- **Storage:** `ilias_disk_usage_bytes`, `ilias_files_total`

#### Alerts

```yaml
- alert: ILIASHighErrorRate
  expr: rate(ilias_errors_total[5m]) > 0.1
  for: 5m
  labels:
    severity: warning
    service: ilias
  annotations:
    summary: ILIAS error rate elevated
    description: "Error rate > 0.1/sec for 5 minutes"

- alert: ILIASDiskSpaceLow
  expr: ilias_disk_usage_bytes / ilias_disk_capacity_bytes > 0.9
  for: 5m
  labels:
    severity: critical
    service: ilias
  annotations:
    summary: ILIAS disk space critical
    description: "Disk usage > 90%"
```

### Moodle Monitoring

#### PodMonitor

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: moodle
  namespace: moodle
  labels:
    monitoring: enabled
spec:
  selector:
    matchLabels:
      app: moodle
  podMetricsEndpoints:
    - port: metrics
      interval: 60s
```

#### Key Metrics

- **User Activity:** `moodle_active_users`, `moodle_logged_in_users`
- **Course Activity:** `moodle_course_view_total`, `moodle_quiz_attempts_total`
- **Submissions:** `moodle_assignment_submissions_total`, `moodle_forum_posts_total`
- **Performance:** `moodle_page_load_seconds`, `moodle_db_query_duration`

#### Alerts

```yaml
- alert: MoodleDatabaseSlow
  expr: moodle_db_query_duration_seconds{quantile="0.99"} > 1
  for: 5m
  labels:
    severity: warning
    service: moodle
  annotations:
    summary: Moodle database queries slow
    description: "99th percentile query latency > 1 second"

- alert: MoodleActiveUsersHigh
  expr: moodle_active_users > 1000
  for: 10m
  labels:
    severity: info
    service: moodle
  annotations:
    summary: High concurrent user activity
    description: "More than 1000 active users"
```

### BigBlueButton Monitoring

#### ServiceMonitor

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: bbb
  namespace: bigbluebutton
  labels:
    monitoring: enabled
spec:
  selector:
    matchLabels:
      app: bbb
  endpoints:
    - port: metrics
      interval: 60s
```

#### Key Metrics

- **Meetings:** `bbb_meetings_active`, `bbb_meetings_total`
- **Participants:** `bbb_participants_active`, `bbb_participants_total`
- **Recordings:** `bbb_recordings_total`, `bbb_recording_storage_bytes`
- **Performance:** `bbb_server_load_average`, `bbb_freeswitch_cpu_usage_percent`

#### Alerts

```yaml
- alert: BBBMeetingCountHigh
  expr: bbb_meetings_active > 50
  for: 5m
  labels:
    severity: warning
    service: bbb
  annotations:
    summary: High concurrent meeting count
    description: "More than 50 active meetings"

- alert: BBBRecordingStorageFull
  expr: bbb_recording_storage_bytes / bbb_recording_capacity_bytes > 0.95
  for: 5m
  labels:
    severity: critical
    service: bbb
  annotations:
    summary: BBB recording storage nearly full
    description: "Recording storage > 95% capacity"
```

### Nextcloud/OpenCloud Monitoring

#### PodMonitor

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: nextcloud
  namespace: nextcloud
  labels:
    monitoring: enabled
spec:
  selector:
    matchLabels:
      app: nextcloud
  podMetricsEndpoints:
    - port: metrics
      interval: 60s
```

#### Key Metrics

- **User Activity:** `nextcloud_users_total`, `nextcloud_files_total`
- **Storage:** `nextcloud_storage_used_bytes`, `nextcloud_free_space_bytes`
- **Performance:** `nextcloud_file_ops_total`, `nextcloud_api_request_duration`
- **Sharing:** `nextcloud_shares_active`, `nextcloud_shared_files_total`

#### Alerts

```yaml
- alert: NextcloudStorageFull
  expr: nextcloud_free_space_bytes < 10737418240  # 10GB
  for: 5m
  labels:
    severity: critical
    service: nextcloud
  annotations:
    summary: Nextcloud storage critical
    description: "Less than 10GB free space"

- alert: NextcloudHighFileOps
  expr: rate(nextcloud_file_ops_total[5m]) > 1000
  for: 5m
  labels:
    severity: warning
    service: nextcloud
  annotations:
    summary: High file operation rate
    description: "More than 1000 file ops/sec"
```

### Provisioning Scripts Monitoring

#### Custom Metrics Export

The provisioning scripts can export metrics to Prometheus.

Add to `scripts/user_import/sync_users.py`:

```python
from prometheus_client import Counter, Gauge, start_http_server

# Define metrics
sync_total = Counter('opendesk_sync_total', 'Total sync operations', ['status'])
sync_duration = Gauge('opendesk_sync_duration_seconds', 'Sync duration in seconds')
sync_users_synced = Gauge('opendesk_sync_users_synced', 'Users synced this run')
sync_users_failed = Gauge('opendesk_sync_users_failed', 'Users failed this run')

# Expose metrics
start_http_server(8000)
```

#### PodMonitor

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: provisioning-scripts
  namespace: default
  labels:
    monitoring: enabled
spec:
  selector:
    matchLabels:
      app: provisioning-scripts
  podMetricsEndpoints:
    - port: metrics
      interval: 30s
```

#### Key Metrics

- **Sync Operations:** `opendesk_sync_total{status="success|failed"}`
- **Sync Duration:** `opendesk_sync_duration_seconds`
- **User Processing:** `opendesk_sync_users_synced`, `opendesk_sync_users_failed`
- **Deprovisioning:** `opendesk_deprovision_total`, `opendesk_archive_total`

#### Alerts

```yaml
- alert: ProvisioningSyncFailed
  expr: rate(opendesk_sync_total{status="failed"}[1h]) > 0.1
  for: 5m
  labels:
    severity: critical
    service: provisioning
  annotations:
    summary: User provisioning sync failing
    description: "High failure rate in LDAP→Keycloak sync"

- alert: ProvisioningSyncStalled
  expr: time() - opendesk_sync_last_success_timestamp_seconds > 3600
  for: 5m
  labels:
    severity: warning
    service: provisioning
  annotations:
    summary: Provisioning sync not running
    description: "No successful sync in 1 hour"
```

## Alert Rules Configuration

### Alert Severity Levels

| Severity | Response Time | Notification Channels |
|-----------|----------------|----------------------|
| critical | Immediate (0-15 min) | PagerDuty, SMS, Phone |
| warning | Within 1 hour | Email, Slack, Teams |
| info | Within 4 hours | Email, Dashboard |
| debug | Within 24 hours | Log only |

### Alertmanager Configuration

Create `helmfile/environments/default/alertmanager.yaml.gotmpl`:

```yaml
monitoring:
  alertmanager:
    config:
      global:
        resolve_timeout: 5m
        smtp_smarthost: smtp.university.de
        smtp_from: alerts@university.de
      route:
        receiver: 'default-receiver'
        group_by: ['alertname', 'cluster', 'service']
        group_wait: 30s
        group_interval: 5m
        repeat_interval: 12h
        routes:
          - match:
              severity: critical
            receiver: 'critical-receiver'
          - match:
              severity: warning
            receiver: 'warning-receiver'
      receivers:
        - name: 'default-receiver'
          email_configs:
            - to: 'it-support@university.de'
              send_resolved: true
        - name: 'critical-receiver'
          email_configs:
            - to: 'oncall@university.de'
              send_resolved: true
          pagerduty_configs:
            - service_key: ${{ secrets.PAGERDUTY_SERVICE_KEY }}
        - name: 'warning-receiver'
          slack_configs:
            - api_url: ${{ secrets.SLACK_WEBHOOK_URL }}
              channel: '#opendesk-alerts'
              send_resolved: true
```

### Creating Alert Secrets

```bash
# Create Kubernetes secret for PagerDuty
kubectl create secret generic alertmanager-secrets -n monitoring \
  --from-literal=pagerduty-service-key='your-pagerduty-key'

# Create Kubernetes secret for Slack
kubectl create secret generic alertmanager-secrets -n monitoring \
  --from-literal=slack-webhook-url='https://hooks.slack.com/services/YOUR/WEBHOOK'
```

## Logging with Loki

### Install Loki Stack

```bash
# Add Grafana Loki Helm repo
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Loki
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --values helmfile/environments/default/loki.yaml.gotmpl
```

### Configure Promtail

```yaml
monitoring:
  promtail:
    enabled: true
    config:
      logFormat: json
      positions:
        filename: /tmp/positions.yaml
      clients:
        - url: http://loki:3100/loki/api/v1/push
      scrapeConfigs:
        - jobName: opendesk-services
          kubernetes_sd_configs:
            - role: pod
          relabel_configs:
            - source_labels:
                - __meta_kubernetes_pod_name
              target_label: pod_name
            - source_labels:
                - __meta_kubernetes_pod_namespace
              target_label: namespace
            - source_labels:
                - __meta_kubernetes_pod_node_name
              target_label: node_name
```

### Access Logs

```bash
# Access Grafana logs
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Explore logs in Grafana
http://localhost:3000/explore
```

## Grafana Dashboard Templates

### Dashboard Import

Create JSON dashboards in `helmfile/charts/grafana-dashboards/templates/`:

```json
{
  "dashboard": {
    "title": "openDesk Edu - Services Overview",
    "panels": [
      {
        "title": "Active Users",
        "targets": [
          {
            "expr": "sum(opendesk_active_users)",
            "legendFormat": "{{service}}"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "sum(rate(http_server_requests_total[5m])) by (service)",
            "legendFormat": "{{service}}"
          }
        ],
        "type": "graph"
      }
    ]
  }
}
```

### Pre-built Dashboards

Import these dashboards into Grafana:

1. **openDesk Edu - Overview**
   - Service health status
   - User activity metrics
   - System resources

2. **Keycloak Dashboard**
   - Login/failure rates
   - Active sessions
   - Authentication latency

3. **ILIAS Dashboard**
   - Course access
   - User enrollment
   - Storage usage

4. **Moodle Dashboard**
   - Quiz submissions
   - Forum activity
   - Assignment completion

5. **BBB Dashboard**
   - Active meetings
   - Participant count
   - Recording storage

6. **Provisioning Dashboard**
   - Sync status
   - Error rates
   - Processing time

### Dashboards as ConfigMaps

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  overview.json: |
    {{ .Files.Get "dashboards/overview.json" | .AsConfig }}
  keycloak.json: |
    {{ .Files.Get "dashboards/keycloak.json" | .AsConfig }}
```

## Monitoring Maintenance

### Storage Management

```bash
# Check Prometheus disk usage
kubectl exec -n monitoring prometheus-kube-prometheus-stack-prometheus-0 -- du -sh /prometheus

# Extend PVC if needed
kubectl patch pvc prometheus-kube-prometheus-stack-prometheus -n monitoring -p '{"spec":{"resources":{"requests":{"storage":"100Gi"}}}'

# Clean old metrics (retention policy)
kubectl edit prometheus -n monitoring
# Set retention: 15d
```

### Performance Tuning

```yaml
# Adjust Prometheus sampling
monitoring:
  prometheus:
    prometheusSpec:
      scrapeInterval: 30s
      evaluationInterval: 30s
      sampleLimit: 10000000
      retentionSize: 50GB
```

### Monitoring Health Check

```bash
# Check Prometheus targets
kubectl exec -n monitoring prometheus-0 -- promtool check config

# Check Alertmanager health
curl http://alertmanager.monitoring:9093/-/healthy

# Check Grafana health
curl http://grafana.monitoring:3000/api/health
```

## Troubleshooting

### Metrics Not Appearing

1. **Check PodMonitor/ServiceMonitor:**

   ```bash
   kubectl get podmonitor -A
   kubectl get servicemonitor -A
   ```

2. **Check Prometheus targets:**

   ```bash
   kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
   # http://localhost:9090/targets
   ```

3. **Verify labels match:**

   ```bash
   kubectl get pod <pod-name> -o yaml | grep labels
   ```

### Alerts Not Firing

1. **Check Alertmanager config:**

   ```bash
   kubectl get secret alertmanager-kube-prometheus-stack-alertmanager -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d
   ```

2. **Check alert rules:**

   ```bash
   kubectl exec -n monitoring prometheus-0 -- promtool check rules /etc/prometheus/rules/
   ```

3. **Check alert evaluation:**

   ```bash
   kubectl exec -n monitoring prometheus-0 -- promtool query instant 'up{job="prometheus"}'
   ```

### High Resource Usage

```bash
# Check monitoring stack resources
kubectl top pods -n monitoring

# Scale down if needed
kubectl scale deployment -n monitoring kube-prometheus-stack-grafana --replicas=1
kubectl scale deployment -n monitoring kube-prometheus-stack-prometheus --replicas=1
```

## Monitoring Checklist

### Pre-Deployment

- [ ] Monitoring namespace created
- [ ] kube-prometheus-stack installed
- [ ] ServiceMonitors/PodMonitors configured for all services
- [ ] PrometheusRule resources created
- [ ] Grafana dashboards imported
- [ ] Alertmanager configured
- [ ] Notification channels tested
- [ ] Alert rules validated
- [ ] Storage allocated (Prometheus: 50GB+, Grafana: 5GB+)

### Post-Deployment

- [ ] All services appear in Prometheus targets
- [ ] All dashboards load in Grafana
- [ ] Test alert triggers
- [ ] Notification channels working
- [ ] Metrics visible for all services
- [ ] Resource usage acceptable
- [ ] Monitoring stack healthy

### Ongoing

- [ ] Weekly: Review alert rules
- [ ] Weekly: Check storage usage
- [ ] Monthly: Update dashboards
- [ ] Quarterly: Performance tuning review
- [ ] Annually: Full monitoring audit

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Kube-Prometheus-Stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Loki](https://grafana.com/docs/loki/latest/)

---

Last Updated: 2026-04-06
Version: 1.0

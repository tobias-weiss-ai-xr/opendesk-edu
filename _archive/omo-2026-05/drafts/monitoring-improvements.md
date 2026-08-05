# Monitoring Improvements Summary

**Generated:** 2026-02-20
**Purpose:** Summary of monitoring enhancements for OpenDesk cluster

---

## Overview

This document summarizes the monitoring improvements designed to enhance visibility into the OpenDesk cluster, with focus on K8up backup operations and UMS (User Management Service) health.

---

## Deliverables

### 1. Documentation

| File | Purpose | Status |
|------|---------|--------|
| `.sisyphus/drafts/monitoring-gaps.md` | Analysis of current monitoring gaps | ✅ Complete |
| `.sisyphus/drafts/prometheus-queries.md` | Prometheus metrics and query reference | ✅ Complete |
| `.sisyphus/drafts/loki-setup.md` | Loki/Promtail installation guide | ✅ Complete |

### 2. Grafana Dashboards

| Dashboard | File | UID | Panels | Status |
|-----------|------|-----|--------|--------|
| **K8up Backup Health** | `.sisyphus/plans/k8up-backup-dashboard.json` | `k8up-backup-health` | 15 | ✅ Complete |
| **UMS Health** | `.sisyphus/plans/ums-health-dashboard.json` | `ums-health-dashboard` | 16 | ✅ Complete |

### 3. Alert Rules

| Alert Group | File | Rules | Status |
|-------------|------|-------|--------|
| **UMS Health Alerts** | `.sisyphus/plans/prometheus-alerts.yaml` | 16 | ✅ Complete |

---

## K8up Backup Dashboard Features

### Key Indicators
- **Successful Backups (Total)**: All-time success counter
- **Backups (Last 24h)**: Recent backup activity
- **Time Since Last Backup**: Critical health indicator with thresholds (23h warn, 25h critical)
- **Active Backup Jobs**: Stuck backup detection
- **Failed Backups (24h)**: Recent failure tracking
- **Backup Storage Used**: Storage capacity monitoring

### Visualization Types
- Pie charts: Jobs by type, snapshots by repository
- Time series: Backup success rate, storage usage percentage
- Stat panels: Critical indicators with conditional coloring

### What's New vs. Existing
| Feature | Existing Dashboard | New Dashboard |
|---------|-------------------|---------------|
| Prune job tracking | ❌ No | ✅ Yes |
| Storage by PVC | ❌ No | ✅ Yes |
| Time since last backup | ❌ No | ✅ Yes |
| snaps by repository | ❌ No | ✅ Yes |
| Failed backups (24h) | ❌ No | ✅ Yes |

---

## UMS Health Dashboard Features

### Component Status Panels
- **LDAP Primary**: Status indicator (Up/Down)
- **LDAP Secondary**: Status indicator (scale-to-zero expected)
- **Keycloak**: Status indicator
- **UDM Listener**: Status indicator
- **UDM Transformer**: Status indicator (CrashLoopBackOff detection)
- **Portal Consumer**: Status indicator
- **UDM REST API**: Status indicator

### Health Metrics
- **Pod Restart Rate**: 15-minute sliding window rate calculations
- **Memory Usage**: Per-pod memory consumption over time
- **CPU Usage**: Per-pod CPU percentage
- **Pod Status Distribution**: Running/Pending/Failed pod counts

### What's New
| Feature | Before | After |
|---------|--------|-------|
| UMS visibility | ❌ None | ✅ Full dedicated dashboard |
| LDAP monitoring | ❌ None | ✅ Primary/Secondary status |
| UDM Transformer tracking | ❌ None | ✅ CrashLoopBackOff detection |
| Restart rate alerts | ❌ None | ✅ Rate-based monitoring |

---

## Alert Rules

### UMS Core Alerts (6 rules)
| Alert | Severity | Description |
|-------|----------|-------------|
| `UMSLdapPrimaryDown` | Critical | LDAP primary pod not running |
| `UMSKeycloakDown` | Critical | Keycloak not responding |
| `UMSUDMListenerDown` | Critical | UDM listener not running |
| `UMSUDMTransformerDown` | Critical | UDM transformer not available |
| `UMSPortalConsumerDown` | Warning | Portal consumer not running |
| `UMSUDMRestAPIDown` | Warning | UDM REST API unavailable |

### UMS Pod Health Alerts (3 rules)
| Alert | Severity | Description |
|-------|----------|-------------|
| `UMSHighPodRestartRate` | Warning | Pod restarting >3 times per 15m |
| `UMSPendingPods` | Warning | Pods stuck in Pending state |
| `UMSFailedPods` | Critical | Pods in Failed state |

### UMS Resource Alerts (2 rules)
| Alert | Severity | Description |
|-------|----------|-------------|
| `UMSHighMemoryUsage` | Warning | Pod using >2GB memory |
| `UMSHighCPUUsage` | Warning | Pod using >80% CPU |

### Backup Alerts (4 rules)
| Alert | Severity | Description |
|-------|----------|-------------|
| `BackupStuckInActive` | Warning | Backup job active >2 hours |
| `PruneJobFailed` | Warning | Prune job failed |
| `BackupStorageHighUsage` | Warning | Backup PVC >90% full |

---

## Deployment Instructions

### 1. Apply Grafana Dashboards

```bash
# Create ConfigMap for K8up Backup Dashboard
kubectl create configmap grafana-dashboard-k8up-backup-health \
  -n opendesk \
  --from-file=k8up-backup-health.json=/path/to/.sisyphus/plans/k8up-backup-dashboard.json \
  --dry-run=client -o yaml | kubectl apply -f -

# Create ConfigMap for UMS Health Dashboard
kubectl create configmap grafana-dashboard-ums-health \
  -n opendesk \
  --from-file=ums-health-dashboard.json=/path/to/.sisyphus/plans/ums-health-dashboard.json \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart Grafana to load dashboards
kubectl rollout restart deployment -n opendesk kube-prom-stack-grafana
```

### 2. Apply Alert Rules

```bash
kubectl apply -f /path/to/.sisyphus/plans/prometheus-alerts.yaml
```

### 3. Verify Rules Loaded

```bash
# Check PrometheusRule is loaded
kubectl get prometheusrule -n opendesk ums-health-alerts

# Verify rules in Prometheus
kubectl exec -n opendesk prometheus-kube-prom-stack-kube-prome-prometheus-0 -- \
  wget -qO- 'http://localhost:9090/api/v1/rules' | jq '.data.groups[] | select(.name | contains("ums")) | .name'
```

---

## Known Issues & Recommendations

### Issue: udm-transformer CrashLoopBackOff
**Root Cause**: Missing LDAP configuration environment variables (`ldap_host`, `ldap_port`, `ldap_base_dn`, etc.)

**Resolution** Required:
```yaml
# Add to deployment or ConfigMap
env:
  - name: ldap_host
    value: "ums-ldap-server-primary.opendesk.svc.cluster.local"
  - name: ldap_port
    value: "389"
  - name: ldap_base_dn
    value: "dc=swp-ldap,dc=internal"  # Match udm-listener
  - name: ldap_bind_dn
    value: "cn=admin,dc=swp-ldap,dc=internal"
```

---

## Future Enhancements

### Phase 1 - Log Aggregation (Immediate)
- Install Loki and Promtail
- Configure log scraping for UMS components
- Add log-based Grafana panels

### Phase 2 - Enhanced Metrics (Short-term)
- Enable LDAP Prometheus exporter
- Enable Keycloak Prometheus plugin
- Expose custom metrics from UDM components

### Phase 3 - Performance Budgeting (Medium-term)
- Define SLOs for UMS components
- Create burn rate charts
- Configure alerting based on error budget

### Phase 4 - Advanced Analytics (Long-term)
- Integrate BigQuery or ClickHouse for metric storage
- Create anomaly detection rules
- Implement predictive alerting

---

## Success Criteria

Monitoring improvements are considered successful when:

- [ ] K8up Backup Dashboard displays all panels with data
- [ ] UMS Health Dashboard shows consistent component status
- [ ] All 16 alert rules are loaded into Prometheus
- [ ] `UMSUDMTransformerDown` alert fires for the known CrashLoopBackOff
- [ ] Grafana dashboards load within 5 seconds
- [ ] Alert notifications are received via configured routes (Slack/email)

---

## Files Modified/Created

```
.sisyphus/
├── drafts/
│   ├── monitoring-gaps.md          ✅ NEW - Gap analysis
│   ├── prometheus-queries.md       ✅ NEW - Metrics reference
│   └── loki-setup.md               ✅ NEW - Loki install guide
└── plans/
    ├── k8up-backup-dashboard.json  ✅ NEW - Backup dashboard
    ├── ums-health-dashboard.json   ✅ NEW - UMS dashboard
    └── prometheus-alerts.yaml      ✅ NEW - Alert rules
```

---

## Next Steps

### Immediate (Today)
1. [ ] Review dashboards in Grafana after deployment
2. [ ] Verify alert rules trigger correctly
3. [ ] Test alert notification channels

### This Week
1. [ ] Fix udm-transformer CrashLoopBackOff (LDAP config)
2. [ ] Install Loki and Promtail
3. [ ] Configure log-based dashboards

### This Month
1. [ ] Enable LDAP metrics exporter
2. [ ] Enable Keycloak metrics
3. [ ] Review and adjust alert thresholds

---

## Summary

This monitoring improvement initiative addresses the critical gaps identified in the existing OpenDesk cluster monitoring:

| Area | Before | After |
|------|--------|-------|
| **UMS visibility** | None | Full dedicated dashboard + alerts |
| **Backup monitoring** | Basic dashboard | Enhanced + prune job tracking |
| **Alert coverage** | K8up only | K8up + UMS (16 new rules) |
| **Log aggregation** | None | Loki/Promtail guide provided |
| **Documentation** | Limited | Complete metrics + gap analysis |

The improvements are designed to be **non-invasive** and **transparent** to existing monitoring, adding capabilities without disrupting current operations.
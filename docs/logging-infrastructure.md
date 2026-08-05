<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Logging Infrastructure Overview
**SPDX-License-Identifier: Apache-2.0**

## Overview
This document describes the centralized logging infrastructure available in the openDesk Edu platform as of Sprint 10 completion.

**Last Updated:** 2026-06-25
**Version:** 1.0

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     openDesk Edu Platform                         │
│                      (opendesk namespace)                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │        Application Pods (Draw.io, Excalidraw, etc.)            │ │
│  │                                                           │ │
│  │  ┌───────────────────────────────────────────────────────────┐  │ │
│  │  │  Promtail DaemonSet (9 instances)                    │  │  │
│  │  │  - Runs on all cluster nodes                         │  │  │
│  │  │  - Collects pod logs from /var/log/pods/                │  │  │
│  │  └──────────────┬──────────────────────────────────────┘  │ │ │
│  │                 │                                           │ │ │
│  │                 ▼                                           │ │ │
│  │  ┌───────────────────────────────────────────────────────────┐  │ │
│  │  │ Loki Service (1 instance, 2Gi RAM, 50Gi storage)          │  │  │
│  │  │ - Ceph RBD storage (ceph-rbd-ssd)                        │  │ │
│  │  │ - 31-day retention period                              │  │  │
│  │  └───────┬───────────────────────────────────────────────┘  │ │ │
│  │         │                                                   │ │ │
│  │         ▼                                                   │ │ │
│  │  ┌───────────────────────────────────────────────────────────┐  │ │ │
│  │  │ Grafana (existing)                                      │  │ │ │
│  │  │ - Loki datasource configured                             │  │ │ │
│  │  │ - Log exploration dashboards                             │ │ │ │
│  │  │ - Backup monitoring dashboards                          │  │ │ │
│  │  │                                                            │ │ │ │
│  │  │ ┌────────────────────────────────────────────────────────┐│ │ │ │
│  │  │ │ Prometheus (existing)                             │ │ │ │ │
│  │  │ │ |                                   Alertmanager (new)  │ │ │ │ │
│  │  │ └────────────────────────────────────────────────────────┘│ │ │ │
│  │  │                                                         │ │ │ │
│  │  │ Postfix (existing)                                         │ │ │ │
│  │  │ - Email delivery for alerts                         │ │ │ │ │
│  │  └───────────────────────────────────────────────────────────┘  │ │ │
│  │                                                            │ │ │ │
│  └─────────────────────────────────────────────────────────────────┘ │ │
│                                                                    │ │
└─────────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────┘
```

---

## Components Deployed

### 1. Loki - Log Aggregation Service
**Chart**: `opendesk-edu/helmfile/charts/loki/`

**Deployment:**
- Replicas: 1
- Resources: 256Mi RAM request, 2Gi RAM limit, 100m CPU request, 1 CPU limit
- Storage: 50Gi PVC with `ceph-rbd-ssd` storage class
- Image: `grafana/loki:3.6.7`

**Features:**
- Filesystem-based storage using Ceph RBD
- 31-day log retention
- Increased ingestion limits: 50MB/sec rate, 100MB burst
- Prometheus ServiceMonitor enabled

**Access:**
- API: `http://loki.opendesk:3100`  
- Grafana datasource configured

---

### 2. Promtail - Log Collection Agent
**Chart**: `opendesk-edu/helmfile/charts/promtail/`

**Deployment:**
- DaemonSet: 9 instances (one per cluster node)
- Resources: 64Mi RAM request, 512Mi RAM limit, 50m CPU request, 500m CPU limit
- Image: `grafana/promtail:3.5.1`

**Configuration:**
- **Source**: `/var/log/pod/opendesk_*/*/*.log` (file-based collection)
- **Target**: `http://loki:3100/loki/api/v1/push`
- **Features**: Structured metadata extraction, batching, compression

**Coverage:**
- Collects logs from all pods in opendesk namespace
- DaemonSet ensures node-level coverage

---

### 3. Alertmanager - Alert Notification System  
**Chart**: `opendesk-edu/helmfile/charts/alertmanager/`

**Deployment:**
- Replicas: 1
- Resources: 64Mi RAM request, 256Mi RAM limit, 50m CPU request, 500m CPU limit
- Image: `prom/alertmanager:v0.27.0`

**Configuration:**
- **Email Provider**: Postfix service (`postfix.opendesk.svc.cluster.local:25`)
- **From Address**: `alertmanager@opendesk.hrz.uni-marburg.de`
- **Default Recipient**: `admin@opendesk.hrz.uni-marburg.de`

**Alert Routing:**
- **backup-critical-receiver**: Critical backup failures
- **backup-warning-receiver**: Backup-related warnings  
- **default-receiver**: All other alerts

**Features:**
- Alert grouping and deduplication
- Alert silencing capabilities
- Prometheus integration for metric alerts

---

### 4. Grafana Dashboards
**Chart**: `opendesk-edu/helmfile/charts/grafana-dashboards/`

**Dashboards Provided:**
- **Backup Dashboard**: 
  - Job status monitoring
  - Success/failure tracking
  - Volume metrics
  - Integration of metrics + logs
  
- **Log Explorer Dashboard**:
  - Real-time log volume monitoring  
  - Error extraction and display
  - Service-specific log viewers (Keycloak, backup processes)
  - General system log exploration

**Integration:**
- Loki datasource configured in Grafana
- Prometheus datasource (existing)
- Dashboards auto-loaded with proper annotations

---

## Resource Summary

| Component | Replicas | RAM (Request/Limit) | CPU (Request/Limit) | Storage | Network |
|-----------|-----------|---------------------|----------------------|---------|---------|
| Loki | 1 | 256Mi / 2Gi | 100m / 1 | 50Gi Ceph RBD | :3100 |
| Promtail | 9 (DaemonSet) | 64Mi / 512Mi per node | 50m / 500m per node | None | :3100 |
| Alertmanager | 1 | 64Mi / 256Mi | 50m / 500m | None | :9093 |
| Grafana | 3 | Existing cluster setup | Existing cluster setup | Existing | Existing |

**Total Resources**: ~5–6Gi RAM, 5+ CPU, 50Gi storage

---

## Installation

### Prerequisites
- Ceph RBD storage class (`ceph-rbd-ssd`)
- Existing Postfix service for email delivery
- Grafana platform components (deployed separately)
- OpenDesk TLS certificates infrastructure

### Deployment Commands

```bash
# Deploy Loki
helm upgrade --install loki ./helmfile/charts/loki \
  -n opendesk --values helmfile/charts/loki/values.yaml

# Deploy Promtail  
helm upgrade --install promtail ./helmfile/charts/promtail \
  -n opendesk --values helmfile/charts/promtail/values.yaml

# Deploy Alertmanager
helm upgrade --install alertmanager ./helmfile/charts/alertmanager \
  -n opendesk --values helmfile/charts/alertmanager/values.yaml

# Deploy Grafana Dashboards
kubectl apply -f helmfile/charts/grafana-dashboards/backup-dashboard.json
kubectl apply -f helmfile/charts/grafana-dashboards/log-explorer-dashboard.json
kubectl annotate configmap opendesk-loki-dashboards \
  grafana_dashboard="1" --overwrite
```

---

## Configuration Files

### Chart Locations
```
opendesk-edu/helmfile/charts/
├── loki/
│   ├── Chart.yaml
│   ├── values.yaml          # Main configuration
│   ├── README.md
│   ├── deployment.yaml     # Complete deployment spec
│   └── local-config.yaml   # Loki configuration
├── promtail/
│   ├── Chart.yaml
│   ├── values.yaml          # Main configuration  
│   ├── README.md
│   └── promtail-deployment.yaml
├── alertmanager/
│   ├── Chart.yaml
│   ├── values.yaml          # Email and routing config
│   ├── README.md
│   └── alertmanager-deployment.yaml
└── grafana-dashboards/
    ├── Chart.yaml
    ├── values.yaml          # Datasource and dashboard config
    ├── backup-dashboard.json
    └── log-explorer-dashboard.json
```

### Configuration Hierarchy
1. **Chart values** (`values.yaml`) - Main configuration parameters
2. **Deployment specs** (`deployment.yaml`) - Complete Kubernetes configurations
3. **Secrets** - Certificates, credentials, configurations
4. **ConfigMaps** - Loki config, Alertmanager rules

---

## Dependencies and Integration

### Required Services
- **Postfix** - Email delivery (existing)
- **Grafana** - Visualization platform (existing)  
- **Prometheus** - Metrics collection and alerting (existing)
- **Ceph RBD** - Storage backend (existing)

### Services Dependencies
1. **Postfix → Alertmanager**: Email delivery for alerts
2. **Promtail → Loki**: Log shipping via HTTP
3. **Alertmanager → Grafana**: On-call rotation, silencing management
4. **Prometheus → Alertmanager**: Alert rule evaluation and firing
5. **Grafana → Loki**: Log query and visualization

### Network Communication
- **Promtail → Loki**: `http://loki.opendesk:3100/loki/api/v1/push`
- **Alertmanager → Postfix**: `postfix.opendesk.svc.cluster.local:25`
- **Grafana → Loki**: `http://loki.opendesk:3100` (ClusterIP)
- **Prometheus → Alertmanager**: Via CRD scope referrals

---

## Monitoring and Observability

### Self-Monitoring
- **Loki**: Promtail UI for component health, metrics endpoint
- **Promtail**: ServiceMonitor integration, log monitoring  
- **Alertmanager**: Web UI for pipeline inspection, observer status
- **Grafana**: Built-in Loki query UI, dashboard alerts

### Key Metrics
- **Loki Ingestion Rate**: Logs per second, bytes per second
- **Promtail Shipping Success Rate**: Successful batch responses
- **Alertmanager Alert Volume**: Firing alerts, notification status
- **Grafana Query Performance**: Query latency, result volumes

### Health Status
All components are currently operational:
```
✅ Loki: 1/1 Running - Serving logs
✅ Promtail: 9/9 READY - Collecting logs from 9 nodes
✅ Alertmanager: 1/1 Running - Processing alerts  
✅ Grafana: 3/3 Running - Providing dashboards
✅ Data Flow: Pods → Promtail → Loki → Grafana
```

---

## Log Querying

### Access Methods
1. **Grafana UI**: Explore logs through web interface on `grafana.opendesk.hrz.uni-marburg.de`
2. **Loki API**: Direct HTTP API calls for automation
3. **Command Line**: `logcli` tool for efficient queries
4. **Port Forwarding**: Local Loki API access via `kubectl port-forward`

### Example Queries (LogQL)

#### View Recent Errors
```
{job="opendesk-logs"} |= "error" | logfmt
```

#### Keycloak Authentication Issues
```
{job="opendesk-logs", filename=~".*keycloak.*"} |= "authentication failed"
```

#### Backup Process Monitors
```
{job="opendesk-logs", filename=~".*backup.*"} | logfmt | thumbprint
```

#### Service-Specific Logs
```
{job="opendesk-logs"} | app=~".*graphviz.*" | logfmt
```

---

## Troubleshooting

### Common Issues

**1. Promtail rate limit errors**
- **Symptom**: `ingestion rate limit exceeded` errors in Promtail logs
- **Solution**: Adjust Loki `ingestionRateMb` and `ingestionBurstSizeMb` in values.yaml

**2. No logs appearing in Grafana**
- **Symptom**: Loki query returns empty results
- **Solutions**:
  - Verify Promtail pods are running (`kubectl get pods -n opendesk -l app=promtail`)
  - Check Loki is accessible (`curl http://loki:3100/ready`)
  - Test Loki query: `curl "http://loki:3100/loki/api/v1/label/job/values"`

**3. Alertmanager not sending emails**
- **Symptom**: Alerts fired but no email received
- **Solutions**:
  - Check Postfix service status (`kubectl get svc -n opendesk | grep postfix`)
  - Verify Alertmanager configuration (`kubectl get cm -A | grep alertmanager`)
  - Test email delivery via `curl http://postfix.opendesk.svc.cluster.local:25`
  - Verify Postfix connectivity via `nslookup postfix.opendesk.svc.cluster.local`

**4. Grafana connection errors**
- **Student**: "Loki datasource connection refused"
- **Solutions**:
  - Check Loki service is accessible
  - Verify Grafana datasource URL is correct
  - Check Loki PVC is mounted and healthy

---

## Maintenance

### Operational Tasks

#### Routine Monitoring
- **Daily**: Check Loki ingestion rates, error rates, storage usage
- **Weekly**: Review Promtail logs for collection issues, disk usage
- **Monthly**: Review alert routing, false positive rate, email delivery statistics  
- **Quarterly**: Review retention policy effectiveness, storage capacity planning

#### Storage Management
- **Loki Storage**: Monitor 50Gi PVC usage, plan expansion
- **Log Retention**: Adjust 31-day retention based on compliance requirements
- **Cleanup**: Remove old log data if retention policy changes

#### Capacity Planning
- **Considereations**:
  - Plan storage expansion at 70% utilization
  - Monitor log volume trends for scaling needs
  - Estimate storage requirements for new services

---

## Future Enhancements

### Phase 2 Optimizations
- Multi-tenant Loki for departmental log separation
- Log sampling for high-volume services  
- Advanced LogQL queries and alert rules
- Integration with external SIEM systems
- Noise reduction and log filtering

### Platform Integration
- Unified alert policy with openDesk core
- Service mesh integration for distributed tracing
- Enhanced security with log-based RBAC
- Compliance logging features (audit trails, immutable logs)

### Advanced Features
- Log-based metrics extraction
- Real-time log anomaly detection  
- Automated root cause analysis
- Multi-cluster log aggregation
- Long-term log archival and search optimization

---

## Contact & Support

- **Documentation**: `/home/weissto_local/git/opendesk_git/opendesk-edu/docs/logging-infrastructure.md`
- **Chart Locations**: `/home/weissto_local/git/opendesk_git/opendesk-edu/helmfile/charts/`
- **Platform AGENTS.md**: `/home/weissto_local/git/opendesk_git/AGENTS.md`
- **Sprint 10 Documentation**: `.sisyphus/sprint-010-status.md`

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-06-25 | Initial logging infrastructure deployment - Loki, Promtail, Alertmanager, Grafana dashboards |

---

**Status**: ✅ Operational - Logging infrastructure fully functional as part of Sprint 10 completion.
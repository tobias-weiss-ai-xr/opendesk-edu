# Monitoring Gaps Analysis

**Generated:** 2026-02-20
**Purpose:** Document gaps in current OpenDesk monitoring setup

---

## Current Monitoring Setup

### Installed Components
- **Prometheus**: `prometheus-kube-prom-stack-kube-prome-prometheus-0` (Running)
- **Grafana**: `kube-prom-stack-grafana-85bd9bf796-xd8gh` (Running)
- **K8up Backup Operator**: `k8up-1758541054-5c8787c5bf-4s2nb` (Running)

### Existing Grafana Dashboards
1. **K8up Backup Overview** (`k8up-backup-overview`)
   - Successful Backups counter
   - Total Backup Jobs counter
   - Jobs by Type (pie chart)
   - Total PVCs counter
   - Backup Rate (Last Hour)

2. **OpenDesk Instance Overview** (`opendesk-instance-overview`)
   - High-level metrics (Total Deployments, Applications Down, Pod Restarts)
   - Application-specific status (Nextcloud, Collabora, Jitsi, Matrix, OpenProject, Keycloak)
   - Resource usage (Memory, Storage, CPU)
   - Pod health metrics (Pending, Failed, Status Distribution)

### Existing Prometheus Alert Rules
- **k8up-backup-alerts**: Backup job failures, stuck backups, no backups in 24h, RWO PVC count

---

## Identified Gaps

### 1. UMS-Specific Monitoring (Critical)
**Missing:** Dedicated monitoring for UMS (User Management Service) components

| Component | Current Status | What's Missing |
|-----------|----------------|----------------|
| `ums-ldap-server-primary` | Running | LDAP query latency, error rates, connection pool metrics |
| `ums-ldap-server-secondary` | 0/0 (scale-to-zero) | LDAP replication lag, failover time |
| `ums-portal-consumer` | Running | Event processing rate, errors, backlog |
| `ums-provisioning-udm-listener` | Running | User sync events, processing latency |
| `ums-provisioning-udm-transformer` | **CrashLoopBackOff** | Critical: Not running, no alerts |
| `ums-provisioning-api` | Running | API latency, error rate, request rate |
| `ums-udm-rest-api` | Running | API call success/failure, response time |
| `ums-keycloak` | Running | Authentication success/failure, session metrics |

### 2. Backup Monitoring Enhancements (High Priority)
**Missing:** Detailed backup health visibility

| Metric Type | Current Status | What's Missing |
|-------------|----------------|----------------|
| Backup Job Status | Alert rules exist | Prune job visibility, snapshot count trends |
| Backup Duration | Not tracked | Time taken per backup, storage usage trends |
| Repository Health | Not tracked | S3 connection errors, storage capacity alerts |
| Retention Compliance | Schedule configured | Retention policy verification alerts |

### 3. Log Integration (High Priority)
**Missing:** Loki and Promtail for log aggregation

- No centralized log collection for:
  - LDAP authentication failures
  - UDM sync errors
  - Backup job logs
  - Application error logs
  - No LogQL queries in Grafana dashboards

### 4. Application-Specific Alerts (Medium Priority)
**Missing:** Service-specific alerting

| Application | What's Needed |
|-------------|---------------|
| Nextcloud | Sync errors, storage near capacity, user login failures |
| Collabora | document conversion failures, high memory usage |
| Jitsi Meet | Call failures, high participant count, bandwidth usage |
| Matrix Synapse | Federation failures, event backpressure |
| OpenProject | Database connection issues, background job failures |

### 5. Performance Trends (Medium Priority)
**Missing:** Long-term performance metrics

- API latency trends (no duration histograms tracked)
- Login success/failure rates over time
- Active user counts (Jitsi, Matrix, Nextcloud)
- Database connection pool metrics
- Cache hit/miss rates

### 6. Multi-Cluster Support (Low Priority)
**Missing:** Multi-cluster monitoring capabilities

- No cluster labels in Prometheus scrape configurations
- No Grafana multi-cluster datasource configuration
- No unified dashboards across environments

---

## Priority Summary

| Gap | Severity | Impact | Effort |
|-----|----------|--------|--------|
| UMS-specific monitoring | Critical | No visibility into user management health | Medium |
| Fix `udm-transformer` CrashLoopBackOff | Critical | User account provisioning not working | Medium |
| Log integration (Loki) | High | Difficult to troubleshoot issues | Medium |
| Backup monitoring enhancements | High | Backup health verification | Low |
| Application-specific alerts | Medium | Faster incident response | Medium |
| Performance trends | Medium | Capacity planning, optimization | Medium |
| Multi-cluster support | Low | Future-proofing | High |

---

## Recommended Next Steps

1. **Immediate (Critical)**
   - Create dedicated UMS Health Dashboard
   - Add alerts for UMS component health
   - Fix `udm-transformer` CrashLoopBackOff (LDAP configuration missing)

2. **Short-term (1-2 weeks)**
   - Install Loki and Promtail for log aggregation
   - Enhance K8up backup dashboard with prune job and repository health
   - Add application-specific alerts for critical services

3. **Medium-term (1-2 months)**
   - Add performance trend panels to dashboards
   - Configure custom alerts for backup retention compliance
   - Enable multi-cluster support

---
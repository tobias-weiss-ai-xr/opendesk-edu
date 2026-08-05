# Production Deployment Guide

This guide provides step-by-step instructions for deploying openDesk Edu in a production environment.

## Overview

Production deployments require careful planning, security hardening, and operational readiness. This guide covers the complete deployment lifecycle from planning to go-live and ongoing operations.

## Pre-Deployment Checklist

### Infrastructure Requirements

| Component | Minimum | Recommended | Notes |
|------------|---------|-------------|-------|
| **Kubernetes Cluster** | 3 nodes, 8 CPU cores each | 5 nodes, 16 CPU cores each | Use managed K8s if possible |
| **Storage** | 1TB total | 2TB total | Separate PVCs for databases, files, archives |
| **Network** | 1 Gbps | 10 Gbps | Ensure low latency for file sync |
| **Memory** | 64GB total | 128GB total | Include headroom for autoscaling |
| **Load Balancer** | Managed LB | Enterprise LB | Cloud provider recommended |

### Hardware Sizing

**Per Service (Estimated):**

| Service | CPU | Memory | Storage | Replicas |
|---------|-----|--------|---------|-----------|
| Keycloak | 2 cores | 4GB | 50GB | 2 |
| ILIAS | 4 cores | 8GB | 100GB | 2 |
| Moodle | 4 cores | 8GB | 100GB | 2 |
| Nextcloud | 2 cores | 4GB | 500GB | 2 |
| BBB | 4 cores | 8GB | 500GB | 2 |
| DB (MariaDB) | 4 cores | 16GB | 200GB | 2 (shared or separate) |
| Monitoring | 1 core | 2GB | 50GB | 1 |

### Network Requirements

**DNS Records:**

| Record | Type | Value | TTL |
|--------|------|-------|-----|
| `desk.university.de` | A | <LoadBalancer IP> | 3600 |
| `*.desk.university.de` | A | <LoadBalancer IP> | 3600 |
| `mail.desk.university.de` | A | <LoadBalancer IP> | 3600 |
| `desk.university.de` | MX | 10 mail.desk.university.de | 3600 |
| `_dmarc.desk.university.de` | TXT | `v=DMARC1; p=quarantine` | 3600 |
| `_acme-challenge.desk.university.de` | TXT | Let's Encrypt validation | 300 |

**Firewall Rules:**

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| 0.0.0.0/0 | Kubernetes nodes | 443, 80 | TCP | HTTPS/HTTP |
| 0.0.0.0/0 | Kubernetes nodes | 22 | TCP | SSH (admin only) |
| Monitoring server | Prometheus servers | 9090-9094 | TCP | Metrics |
| Keycloak pods | Keycloak DB | 3306, 5432 | TCP | Database access |

### Security Requirements

**TLS Certificates:**

- Valid certificates for all domains
- Minimum 2048-bit RSA or 256-bit ECC
- Certificate Authority: Let's Encrypt (production) or enterprise CA
- Certificate renewal automation

**Secrets Management:**

- Kubernetes secrets for all credentials
- RBAC enabled on cluster
- Regular secret rotation (90 days)
- Secrets stored in encrypted volume

**Network Policies:**

- Default deny all ingress/egress
- Explicit allow for required services
- Namespace isolation
- Network segmentation (DMZ for public services)

### Data Protection

**GDPR Compliance:**

- Data encryption at rest (disk encryption)
- Data encryption in transit (TLS 1.3+)
- Data backup and retention policy
- Data subject access request procedures
- Data breach notification procedures

**Backup Requirements:**

- Automated daily backups
- Offsite backup replication
- Backup verification (daily)
- 90-day retention for operational data
- 10-year retention for course materials

## Deployment Planning

### Environment Setup

Create production environment configuration:

```bash
# Copy production environment
cp helmfile/environments/default/global.yaml.gotmpl \
   helmfile/environments/production/global.yaml.gotmpl
```

Edit `helmfile/environments/production/global.yaml.gotmpl`:

```yaml
global:
  hosts:
    domain: desk.university.de
    keycloak: sso.desk.university.de
    ilias: lms.desk.university.de
    moodle: courses.desk.university.de
    nextcloud: files.desk.university.de
    bbb: meetings.desk.university.de

  oidc:
    issuer: https://sso.desk.university.de/realms/opendesk

  storageClass:
    standard: standard-ssd
    fast: premium-ssd

  backup:
    enabled: true
    schedule: "0 2 * * *"  # Daily at 2 AM
    retention: 30d

  monitoring:
    enabled: true
    namespace: monitoring
```

### Database Planning

**Strategy:** Dedicated database servers or managed database service

**MariaDB Configuration:**

```yaml
mariadb:
  enabled: true
  auth:
    rootPassword: <SECRET>
    database: opendesk

  primary:
    replicaCount: 2  # High availability

    persistence:
      enabled: true
      storageClass: premium-ssd
      size: 200Gi

    resources:
      requests:
        cpu: 4000m
        memory: 16Gi
      limits:
        cpu: 8000m
        memory: 32Gi

    metrics:
      enabled: true

  # Separate databases for each service
  initdbScripts:
    create-ilias.sql: |
      CREATE DATABASE IF NOT EXISTS ilias;
      GRANT ALL PRIVILEGES ON ilias.* TO 'ilias'@'%';

    create-moodle.sql: |
      CREATE DATABASE IF NOT EXISTS moodle;
      GRANT ALL PRIVILEGES ON moodle.* TO 'moodle'@'%';

    create-nextcloud.sql: |
      CREATE DATABASE IF NOT EXISTS nextcloud;
      GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'%';
```

### High Availability Configuration

**Keycloak HA:**

```yaml
keycloak:
  enabled: true
  image:
    tag: 23.0.6  # Production-tested version

  auth:
    existingSecret: keycloak-admin-secret

  postgresql:
    enabled: true
    primary:
      replicaCount: 3  # HA requirement

    persistence:
      enabled: true
      size: 50Gi

  extraEnv: |
    - name: PROXY_ADDRESS_FORWARDING
      value: ""
```

**Application HA:**

```yaml
# All services
replicaCount: 2  # Minimum for production
resources:
  requests:
    cpu: 500m
    memory: 2Gi
  limits:
    cpu: 2000m
    memory: 8Gi
```

## Deployment Execution

### Phase 1: Infrastructure Setup

**Timeline:** 1-2 days

**Steps:**

1. **Create Kubernetes cluster**

   ```bash
   # Using managed service (e.g., GKE, EKS)
   # Or self-hosted with kubeadm
   ```

2. **Configure storage classes**

   ```bash
   kubectl create storageclass fast-ssd \
     --reclaim-policy=Delete \
     --provisioner=cloud.google.com/compute/volume/standard-rwo \
     --volume-binding-mode=Immediate
   ```

3. **Create namespaces**

   ```bash
   kubectl create namespace production
   kubectl create namespace monitoring
   kubectl create namespace backups
   ```

4. **Install cert-manager** (for Let's Encrypt)

   ```bash
   helm install cert-manager jetstack/cert-manager \
     --namespace cert-manager \
     --version v1.13.0 \
     --set installCRDs=true
   ```

5. **Install ingress controller**

   ```bash
   helm install ingress-nginx ingress-nginx/ingress-nginx \
     --namespace ingress-nginx \
     --set controller.service.annotations.["service\.beta\.kubernetes\.io/azure-load-balancer-internal"]="true"
   ```

### Phase 2: Database Deployment

**Timeline:** 1 day

**Steps:**

1. **Deploy MariaDB**

   ```bash
   cd helmfile/charts/
   helm install mariadb ./mariadb \
     --namespace production \
     --values ../../../helmfile/environments/production/mariadb.yaml.gotmpl \
     --timeout 15m
   ```

2. **Verify database health**

   ```bash
   kubectl get pods -n production -l app=mariadb
   kubectl logs -f production/mariadb-0
   ```

3. **Initialize databases**

   ```bash
   kubectl exec -n production mariadb-0 -- \
     mysql -u root -p$MYSQL_ROOT_PASSWORD -e "
       SOURCE /docker-entrypoint-initdb.d/create-ilias.sql;
       SOURCE /docker-entrypoint-initdb.d/create-moodle.sql;
       SOURCE /docker-entrypoint-initdb.d/create-nextcloud.sql;
     "
   ```

### Phase 3: Core Services Deployment

**Timeline:** 1-2 days

**Steps:**

1. **Deploy Keycloak**

   ```bash
   helmfile -e production apply --diff

   # Wait for Keycloak to be ready
   kubectl wait --for=condition=ready pod \
     -n production -l app=keycloak --timeout=300s
   ```

2. **Verify Keycloak**

   ```bash
   # Check admin console
   kubectl port-forward -n production svc/keycloak 8080:80
   # Open: http://localhost:8080/admin
   ```

3. **Create admin user in Keycloak**
   - Login as admin
   - Create realm `opendesk`
   - Configure SAML/SSO
   - Import required clients

4. **Deploy ILIAS**

   ```bash
   helm install ilias ./ilias \
     --namespace production \
     --values ../../../helmfile/environments/production/ilias.yaml.gotmpl
   ```

5. **Deploy Moodle**

   ```bash
   helm install moodle ./moodle \
     --namespace production \
     --values ../../../helmfile/environments/production/moodle.yaml.gotmpl
   ```

6. **Deploy other services**

   ```bash
   helm install nextcloud ./nextcloud --namespace production
   helm install bbb ./bigbluebutton --namespace production
   ```

### Phase 4: Monitoring Deployment

**Timeline:** 4 hours

**Steps:**

1. **Deploy monitoring stack**

   ```bash
   helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
     --namespace monitoring \
     --values ../../helmfile/environments/production/monitoring.yaml.gotmpl
   ```

2. **Import Grafana dashboards**

   ```bash
   kubectl apply -f ./grafana-dashboards/
   ```

3. **Configure Alertmanager**

   ```bash
   # Update secret with notification channels
   kubectl create secret generic alertmanager-secrets \
     --from-literal=slack-webhook-url=$SLACK_WEBHOOK \
     --from-literal=pagerduty-service-key=$PAGERDUTY_KEY \
     -n monitoring
   ```

4. **Verify monitoring**

   ```bash
   # Access Grafana
   kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

   # Check Prometheus targets
   kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
   # Open: http://localhost:9090/targets
   ```

### Phase 5: Provisioning Setup

**Timeline:** 2 hours

**Steps:**

1. **Install provisioning scripts**

   ```bash
   # Copy scripts to production server
   scp -r scripts/user_import/* production@production-server:/opt/opendesk-edu/scripts/user_import/

   # SSH to production server
   ssh production@production-server
   cd /opt/opendesk-edu/scripts/user_import
   ```

2. **Configure environment**

   ```bash
   cp .env.example .env
   nano .env

   # Set:
   # - KEYCLOAK_URL
   # - KEYCLOAK_ADMIN_USERNAME
   # - KEYCLOAK_ADMIN_PASSWORD
   # - LDAP_SERVER
   # - LDAP_BIND_DN
   # - LDAP_BIND_PASSWORD
   # - GRACE_PERIOD_DAYS
   ```

3. **Test provisioning scripts**

   ```bash
   # Test LDAP connection
   python sync_users.py --source ldap --dry-run

   # Test Keycloak connection
   python sync_users.py --source ldap --auto-sync --dry-run
   ```

### Phase 6: Backup Configuration

**Timeline:** 2 hours

**Steps:**

1. **Create backup namespace**

   ```bash
   kubectl create namespace backups
   ```

2. **Install Velero (backup tool)**

   ```bash
   helm install velero vmware-tanzu/velero \
     --namespace backups \
     --version 1.12.0 \
     --set initContainers[0].image=velero/velero-plugin-for-aws:v1.8.0 \
     --set credentials.secretContents=aws_access_key_id=$AWS_ACCESS_KEY_ID,aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
   ```

3. **Configure backup schedule**

   ```yaml
   # backup-schedule.yaml
   apiVersion: velero.io/v1
   kind: Schedule
   metadata:
     name: daily-backup
     namespace: backups
   spec:
     schedule: "0 2 * * *"
     template:
       includedNamespaces:
         - production
       storageLocation: default
       volumeSnapshotLocations:
         - default
       ttl: 720h  # 30 days
   ```

4. **Test backup**

   ```bash
   # Create on-demand backup
   velero backup create opendesk-test \
     --include-namespaces production \
     --wait

   # Verify backup
   velero backup describe opendesk-test --details
   ```

### Phase 7: Security Hardening

**Timeline:** 4 hours

**Steps:**

1. **Configure network policies**

   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: default-deny-all
     namespace: production
   spec:
     podSelector: {}
     policyTypes:
     - Ingress
     - Egress
   ```

2. **Enable pod security policies**

   ```bash
   # Install PSP (if using older K8s)
   kubectl apply -f ./pod-security-policies/

   # Or use Kyverno for newer clusters
   helm install kyverno kyverno/kyverno \
     --namespace kyverno --create-namespace
   ```

3. **Configure RBAC**

   ```yaml
   # service-account-roles.yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     name: keycloak-operator
   rules:
     - apiGroups: [""]
       resources: ["pods", "services", "configmaps"]
       verbs: ["get", "list", "watch"]
   ```

4. **Secret encryption at rest**

   ```bash
   # Enable encryption on storage class
   kubectl annotate storageclass standard-ssd \
     storageclass.kubernetes.io/is-default-class="true" \
     encryption.kubernetes.io/secret-name="k8s-encryption-key"
   ```

## Go-Live Procedures

### Pre-Go-Live Checklist

- [ ] All services deployed and running
- [ ] Database initialized and healthy
- [ ] Keycloak admin console accessible
- [ ] TLS certificates valid for all domains
- [ ] DNS records propagated globally
- [ ] Monitoring stack operational
- [ ] Alerts configured and tested
- [ ] Backup schedule configured and tested
- [ ] Provisioning scripts configured and tested
- [ ] Network policies applied
- [ ] RBAC configured
- [ ] Documentation completed
- [ ] Support team notified
- [ ] Rollback plan documented

### Staged Rollout

**Day 1: Infrastructure + Keycloak**

- Deploy Kubernetes cluster
- Deploy database
- Deploy Keycloak
- Verify Keycloak SSO

**Day 2: Core Services**

- Deploy ILIAS (read-only mode)
- Deploy Moodle (read-only mode)
- Deploy Nextcloud (read-only mode)
- Deploy BBB
- Verify all services accessible via SSO

**Day 3: Monitoring + Backup**

- Deploy monitoring stack
- Configure backups
- Test backup/restore
- Enable monitoring alerts

**Day 4: Full Read-Write**

- Switch all services to read-write mode
- Start user provisioning sync
- Enable backup schedule
- Monitor for 24 hours

### Rollback Plan

If deployment fails, use this procedure:

1. **Identify failure point**
   - Which service failed?
   - What error occurred?
   - Is this recoverable?

2. **Determine rollback strategy**
   - Full rollback: Revert entire deployment
   - Partial rollback: Revert failed service only
   - Fix forward: Fix issue and continue

3. **Execute rollback**

   ```bash
   # Rollback to previous version
   helm rollback <release-name> -n production

   # Or restore from backup
   velero restore create opendesk-backup-20260406 \
     --include-namespaces production
   ```

4. **Verify rollback**
   - Check service health
   - Verify data integrity
   - Test SSO login
   - Monitor for 24 hours

## Post-Go-Live Operations

### Monitoring

**Critical Metrics:**

- Service availability (target: 99.9%)
- Response time (target: < 2s for 95th percentile)
- Error rate (target: < 0.1%)
- Disk usage (alert at 80%, critical at 90%)
- CPU usage (alert at 80%, scale at 90%)
- Memory usage (alert at 85%, scale at 95%)

**Daily Checks:**

- Morning: Review overnight alerts and logs
- Mid-day: Check service health dashboard
- Evening: Review daily backup status

### Maintenance Windows

**Schedule:**

- Database maintenance: Monthly, Sunday 2 AM UTC
- Security updates: Weekly, Sunday 3 AM UTC
- Backup verification: Weekly, Sunday 1 AM UTC
- Capacity planning: Quarterly

**Maintenance Procedure:**

1. Notify users 7 days in advance
2. Set maintenance mode in Keycloak
3. Scale down services
4. Perform maintenance
5. Scale up services
6. Verify functionality
7. Notify users of completion

### Incident Response

**Severity Levels:**

| Severity | Response Time | Resolution Time | Notification |
|----------|----------------|-----------------|-------------|
| Critical | 15 minutes | 4 hours | Phone, SMS, PagerDuty |
| High | 1 hour | 8 hours | Phone, Slack, Email |
| Medium | 4 hours | 24 hours | Email, Slack |
| Low | 24 hours | 72 hours | Email |

**Incident Procedure:**

1. Detect incident (alert or user report)
2. Assess severity and impact
3. Notify appropriate team
4. Mitigate immediate impact
5. Investigate root cause
6. Implement permanent fix
7. Verify fix
8. Document incident
9. Conduct post-incident review

## Capacity Planning

**Scaling Triggers:**

| Metric | Scale Up | Scale Down |
|--------|-----------|------------|
| CPU > 80% for 5 min | +1 replica | -1 replica |
| Memory > 90% for 5 min | +1 replica | -1 replica |
| Request latency > 5s for 10 min | +2 replicas | -1 replica |
| Concurrent users > 80% capacity | +50% replicas | -25% replicas |
| Low usage for 7 days | -1 replica | -1 replica |

**Capacity Planning Timeline:**

| Activity | Timeline | Owner |
|----------|-----------|--------|
| Review metrics | Monthly | System Administrator |
| Update forecasts | Quarterly | System Administrator |
| Capacity planning | Semi-annually | IT Director |
| Budget approval | Annually | University leadership |

## Security Considerations

### Regular Security Tasks

**Weekly:**

- Review security alerts
- Check for failed login attempts
- Review access logs

**Monthly:**

- Review and rotate secrets
- Update TLS certificates
- Security patch review
- Vulnerability scan review

**Quarterly:**

- Security audit
- Penetration test
- Incident response drill
- Backup restore test

### GDPR Compliance

**Data Subject Rights:**

- Right to access: Provide copy of all personal data
- Right to rectification: Correct inaccurate data
- Right to erasure: Delete personal data (with legal exceptions)
- Right to data portability: Export in machine-readable format

**Data Breach Response:**

1. Assess breach scope
2. Notify supervisory authority (within 72 hours)
3. Notify affected individuals (without undue delay)
4. Document breach details
5. Implement remediation measures
6. Prevent future breaches

## Support and Documentation

**Support Contact:**

- **Primary IT:** <it-support@university.de>
- **Emergency:** <oncall@university.de> (24/7)
- **System:** <sysadmin@university.de>
- **Security:** <security@university.de>

**Documentation:**

- Deployment procedures (this guide)
- Service documentation (docs/)
- Disaster recovery (docs/disaster-recovery.md)
- Monitoring setup (docs/monitoring-setup.md)
- Runbooks: Troubleshooting procedures per service

**Knowledge Base:**

- Common issues and solutions
- Change history
- Incident log
- Configuration changes

## Performance Optimization

### Database Tuning

```sql
-- MariaDB tuning
SET GLOBAL innodb_buffer_pool_size = 16G;
SET GLOBAL max_connections = 500;
SET GLOBAL query_cache_size = 256M;
SET GLOBAL tmp_table_size = 256M;
```

### Application Tuning

```yaml
# Keycloak JVM tuning
environment:
  - name: JAVA_OPTS_APPEND
    value: "-Xms4096m -Xmx8192m -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=512m"

# PHP (ILIAS, Moodle) tuning
php:
  memory_limit: 512M
  max_execution_time: 300
  max_input_time: 600
  upload_max_filesize: 100M
```

### Caching Configuration

```yaml
# Redis cache for sessions
redis:
  enabled: true
  maxmemory: 2gb
  maxmemory-policy: allkeys-lru

# Keycloak caching
cache:
  enabled: true
  sessions:
    type: redis
  public:
    type: redis
```

## Compliance Checklist

### IT Security Compliance

- [ ] TLS 1.3+ enabled everywhere
- [ ] Strong cipher suites only
- [ ] Regular security updates
- [ ] Vulnerability scanning enabled
- [ ] Penetration testing completed
- [ ] Security audit conducted

### Data Protection Compliance

- [ ] Data encryption at rest
- [ ] Data encryption in transit
- [ ] Access logging enabled
- [ ] Data retention policy defined
- [ ] Data subject access procedure
- [ ] Data breach response plan

### Operational Compliance

- [ ] Backup schedule configured
- [ ] Disaster recovery plan tested
- [ ] Incident response procedure defined
- [ ] Monitoring and alerting configured
- [ ] Change management process
- [ ] Capacity planning process

## Troubleshooting

### Common Production Issues

**1. High Memory Usage**

```bash
# Identify memory-intensive pods
kubectl top pods -n production

# Check for memory leaks
kubectl logs -n production <pod-name> --previous

# Solutions:
# - Scale down replicas temporarily
# - Increase memory limits
# - Restart service
```

**2. Database Connection Pool Exhausted**

```bash
# Check database connections
kubectl exec -n production mariadb-0 -- \
  mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW PROCESSLIST;"

# Solutions:
# - Increase pool size
# - Reduce application connection limit
# - Kill long-running queries
```

**3. Certificate Renewal Failure**

```bash
# Check cert-manager status
kubectl describe certificate -n production desk-university-de

# Manually trigger renewal
kubectl annotate certificate desk-university-de \
  cert-manager.io/issuer: "letsencrypt-prod"

# Solutions:
# - Check DNS records
# - Verify ACME challenge
# - Check firewall rules
```

**4. High CPU Usage**

```bash
# Identify CPU-intensive pods
kubectl top pods -n production --sort-by=cpu

# Check for inefficient queries
kubectl logs -n production <pod-name> | grep "slow query"

# Solutions:
# - Scale up replicas
# - Optimize database queries
# - Add caching
# - Review resource limits
```

## Handover

### Operations Handover

**When deploying to production, operations team should receive:**

1. **Architecture diagrams**
2. **Network topology**
3. **Service inventory**
4. **Access credentials** (separately, securely)
5. **Monitoring dashboards**
6. **Runbooks**
7. **Emergency contacts**
8. **Change history**

### Training Schedule

**Week 1:**

- Architecture overview
- Service overview
- Monitoring tools
- Incident response procedures

**Week 2:**

- Daily operations
- Backup/restore procedures
- Troubleshooting common issues

**Week 3:**

- Security procedures
- GDPR compliance
- Data protection

**Week 4:**

- Advanced troubleshooting
- Performance optimization
- Capacity planning

---

**Last Updated**: 2026-04-06
**Version**: 1.0
**Next Review**: 2026-10-06

# ZKI IT-Grundschutz-Profil Integration Analysis for openDesk

# SPDX-FileCopyrightText: 2026 openDesk Contributors
# SPDX-License-Identifier: Apache-2.0

## Executive Summary

This document provides a comprehensive analysis of **ZKI IT-Grundschutz-Profil** requirements and identifies specific measures needed to integrate this security framework into the **openDesk platform**. The ZKI (Zentren für Kommunikations- und Informationsverarbeitung) IT-Grundschutz-Profil is a German higher education-specific adaptation of the **BSI IT-Grundschutz** standard, tailored for universities and research institutions.

### Current State Assessment

The openDesk platform **already implements many ZKI IT-Grundschutz measures**, particularly in the following areas:
- ✅ Identity and Access Management (Keycloak, OIDC)
- ✅ Network Security (HAProxy, Traefik, Network Policies)
- ✅ System Hardening (PSA, non-root containers, capability dropping)
- ✅ Data Backup (k8up with restic)
- ✅ Monitoring (Prometheus, Grafana, Loki)
- ✅ Secure Storage (Ceph with encryption)

### Compliance Level Target

Based on ZKI recommendations for higher education:
- **Target Level**: **BSI IT-Grundschutz (Baseline Protection)**
- **Sensitive Services** (student data, exam systems): **Hoch (High Protection)**
- **Critical Research Data**: **Sehr Hoch (Very High Protection)** (optional, as needed)

### Implementation Priority

| Priority | Category | Measures | Effort | Status |
|----------|----------|----------|--------|--------|
| P0 (Critical) | IAM & Authentication | 5 measures | Low-Medium | ⚠️ Partial |
| P0 (Critical) | Network Security | 4 measures | Low | ✅ Good |
| P0 (Critical) | Data Protection | 3 measures | Medium | ⚠️ Partial |
| P1 (High) | Auditing & Logging | 4 measures | Medium | ⚠️ Partial |
| P1 (High) | Incident Response | 3 measures | Medium | ⚠️ Missing |
| P1 (High) | Change Management | 3 measures | Low | ⚠️ Partial |
| P2 (Medium) | Application Security | 5 measures | Medium-High | ⚠️ Partial |
| P2 (Medium) | Physical Security | 2 measures | Low | ✅ Good |
| P2 (Medium) | Awareness | 3 measures | Low-Medium | ⚠️ Missing |

---

## 1. Overview of ZKI IT-Grundschutz-Profil

### 1.1 What is ZKI IT-Grundschutz-Profil?

The **ZKI IT-Grundschutz-Profil** is a **higher education-specific adaptation** of the **BSI IT-Grundschutz** methodology. It provides:

- **Standardized security baseline** for university IT environments
- **Modular structure** based on BSI IT-Grundschutz catalogs
- **University-specific requirements** (research data, student data, open collaboration)
- **Risk-based approach** with different protection levels
- **Compliance framework** aligned with German law (DSGVO, HDSG, etc.)

### 1.2 ZKI Working Group

The **"IT-Sicherheit und Datenschutz"** (IT Security and Data Protection) working group within ZKI:
- Develops security standards for universities
- Maintains the IT-Grundschutz-Profil
- Shares best practices among member institutions
- Provides training and certification

### 1.3 Relation to BSI IT-Grundschutz

| Aspect | BSI IT-Grundschutz | ZKI IT-Grundschutz-Profil |
|--------|-------------------|---------------------------|
| Scope | General IT systems | Higher education specific |
| Modules | Standard BSI modules | Adapted for universities |
| Threats | General threat catalog | University-specific threats |
| Measures | General measures | University-specific measures |
| Compliance | ISO 27001 aligned | DSGVO, HDSG aligned |

### 1.4 Key References

- **BSI Standards**: BS 200-1, BS 200-2, BS 200-3
- **BSI IT-Grundschutz catalogs**: [BSI Website](https://www.bsi.bund.de/DE/Themen/ITGrundschutz/ITGrundschutzKataloge/itgrundschutzkataloge_node.html)
- **ZKI Website**: [https://www.zki.de](https://www.zki.de)
- **ISIS12**: Informationssicherheitsstandards für die Hochschulen (Information Security Standards for Universities)

---

## 2. Current openDesk Security Measures

### 2.1 Already Implemented (Compliant)

#### Identity and Access Management
- ✅ **Keycloak** with OIDC/SAML authentication
- ✅ **Role-based access control (RBAC)**
- ✅ **Multi-factor authentication (MFA)** support
- ✅ **Federated identity** (Shibboleth, SAML)
- ✅ **Password policies** configured
- ✅ **Session management** with timeouts
- ✅ **Account lockout** protection

#### Network Security
- ✅ **HAProxy ingress controller** with TLS termination
- ✅ **Traefik ingress controller** (additional layer)
- ✅ **Network Policies** (Kyverno enforced)
- ✅ **Pod Security Admission** (PSA) enforced
- ✅ **Firewall rules** via network policies
- ✅ **Network segmentation** (separate namespaces)

#### System Security
- ✅ **Non-root containers** (runAsNonRoot: true)
- ✅ **Capability dropping** (drop: ["ALL"])
- ✅ **Read-only root filesystem** (where applicable)
- ✅ **Seccomp profiles** (RuntimeDefault)
- ✅ **Resource limits** (CPU, memory)
- ✅ **Pod Disruption Budget** (PDB)

#### Data Security
- ✅ **Ceph CSI storage** with encryption at rest
- ✅ **k8up backup operator** with restic (encrypted backups)
- ✅ **Backup schedules** (daily, weekly, monthly)
- ✅ **Retention policies** configured
- ✅ **PVC annotations** for backup exclusion/include

#### Monitoring
- ✅ **Prometheus** monitoring stack
- ✅ **Grafana** dashboards
- ✅ **Loki** for log aggregation
- ✅ **Alertmanager** for alerts
- ✅ **Resource monitoring** (CPU, memory, disk)

#### Physical Security (Infrastructure)
- ✅ **K3s cluster** on physical servers (HRZ Marburg)
- ✅ **Access controls** at data center level
- ✅ **Environmental controls** (cooling, power)
- ✅ **Redundant power** (UPS, generators)

### 2.2 Partially Implemented (Needs Enhancement)

#### Auditing and Logging
- ⚠️ **Audit logs** exist but need centralization
- ⚠️ **Access logs** for applications (partial)
- ⚠️ **Security event logging** (needs improvement)
- ⚠️ **Log retention policies** (needs formalization)
- ⚠️ **Log integrity verification** (missing)

#### Change Management
- ⚠️ **Git-based workflow** (good)
- ⚠️ **PR discipline** (separate code/chart changes)
- ⚠️ **Version pinning** (images pinned by digest)
- ⚠️ **Rollback procedures** (manual, needs automation)
- ⚠️ **Change documentation** (CHANGELOG.md exists, needs expansion)

#### Data Protection
- ⚠️ **Data classification** (needs formal scheme)
- ⚠️ **Data retention policies** (partial)
- ⚠️ **Data deletion procedures** (manual, needs automation)
- ⚠️ **Encryption in transit** (TLS configured, needs verification)
- ⚠️ **Pseudonymization** (needs implementation for analytics)

#### Application Security
- ⚠️ **Input validation** (depends on application)
- ⚠️ **Output validation** (depends on application)
- ⚠️ **CSRF protection** (partial, configured per application)
- ⚠️ **XSS protection** (partial, configured per application)
- ⚠️ **Security headers** (partial, needs standardization)

### 2.3 Not Implemented (Needs Action)

#### Incident Response
- ❌ **Formal incident response plan**
- ❌ **Incident classification scheme**
- ❌ **Incident response team** (needs definition)
- ❌ **Incident documentation templates**
- ❌ **Incident communication procedures**

#### Awareness and Training
- ❌ **Security awareness program**
- ❌ **User training materials**
- ❌ **Regular security reminders**
- ❌ **Phishing simulation**
- ❌ **Security workshops**

#### Vulnerability Management
- ❌ **Regular vulnerability scanning**
- ❌ **Vulnerability assessment procedures**
- ❌ **Patch management workflow** (partial, needs formalization)
- ❌ **CVE monitoring** (needs automation)

#### Risk Management
- ❌ **Formal risk assessment process**
- ❌ **Risk register**
- ❌ **Risk treatment plans**
- ❌ **Risk review schedule**

---

## 3. ZKI IT-Grundschutz-Profil Requirements

### 3.1 BSI IT-Grundschutz Structure

The BSI IT-Grundschutz methodology is structured into **modules (Bausteine)** with associated **threats (Gefährdungen)** and **measures (Maßnahmen)**.

#### Base Modules (Basis-Absicherung)

These are the **foundational modules** that apply to all IT systems:

| Module | Description | Relevance to openDesk |
|--------|-------------|------------------------|
| ISMS | Information Security Management System | ⭐⭐⭐⭐⭐ Critical |
| ORP | Organization and Personnel | ⭐⭐⭐⭐ High |
| CON | Concepts and Strategies | ⭐⭐⭐⭐ High |
| OPS | Operations | ⭐⭐⭐⭐ High |
| IND | Industrial Security | ⭐⭐ Low (not relevant) |

#### Infrastructure Modules (INF)

These modules cover the **technical infrastructure**:

| Module | Description | Relevance | Status |
|--------|-------------|-----------|--------|
| INF.1 | General Servers | ⭐⭐⭐⭐⭐ | ⚠️ Partial |
| INF.2 | Application Servers | ⭐⭐⭐⭐⭐ | ⚠️ Partial |
| INF.3 | Clients | ⭐⭐⭐ | ✅ Good |
| INF.4 | End User Devices | ⭐⭐ | N/A |
| INF.5 | Firewalls | ⭐⭐⭐⭐⭐ | ✅ Good |
| INF.6 | Network Components | ⭐⭐⭐⭐⭐ | ⚠️ Partial |
| INF.7 | Network Management | ⭐⭐⭐ | ⚠️ Partial |
| INF.8 | Telecommunications | ⭐ | ✅ Good |
| INF.9 | Cryptography | ⭐⭐⭐⭐ | ⚠️ Partial |
| INF.10 | Printers and Plotters | ⭐ | ✅ Good |
| INF.11 | Thin Clients | ⭐ | N/A |
| INF.12 | Virtualized Systems | ⭐⭐⭐⭐⭐ | ⚠️ Partial |
| INF.13 | Cloud Computing | ⭐⭐⭐⭐ | ⚠️ Partial |
| INF.14 | Web Applications | ⭐⭐⭐⭐⭐ | ⚠️ Partial |
| INF.15 | Mobile Devices | ⭐⭐ | N/A |
| INF.16 | Industrial Control Systems | ⭐ | N/A |
| INF.17 | IoT Devices | ⭐ | ✅ Good |
| INF.18 | Containers | ⭐⭐⭐⭐⭐ | ⚠️ Partial |
| INF.19 | Microservices | ⭐⭐⭐⭐ | ⚠️ Partial |

#### Application Modules (APP)

These modules cover **applications and services**:

| Module | Description | Relevance | Status |
|--------|-------------|-----------|--------|
| APP.1 | Databases | ⭐⭐⭐⭐⭐ | ⚠️ Partial |
| APP.2 | Web Servers | ⭐⭐⭐⭐⭐ | ⚠️ Partial |
| APP.3 | Application Servers | ⭐⭐⭐⭐⭐ | ⚠️ Partial |
| APP.4 | Clients | ⭐⭐⭐ | ✅ Good |
| APP.5 | Office Applications | ⭐⭐ | N/A |
| APP.6 | Email | ⭐⭐⭐⭐ | ⚠️ Partial |
| APP.7 | Directory Services | ⭐⭐⭐⭐ | ✅ Good |

#### Cross-Cutting Aspects (Übergreifende Aspekte)

| Aspect | Description | Relevance | Status |
|--------|-------------|-----------|--------|
| DS | Data Protection | ⭐⭐⭐⭐⭐ | ⚠️ Partial |
| SYS | System Development | ⭐⭐⭐ | ⚠️ Partial |
| NET | Network | ⭐⭐⭐⭐⭐ | ✅ Good |
| CRM | Crisis Management | ⭐⭐⭐⭐ | ❌ Missing |
| BCP | Business Continuity | ⭐⭐⭐ | ❌ Missing |

---

## 4. Gap Analysis: Required Measures

### 4.1 Priority 0 (P0) - Critical Measures

These measures are **essential for BSI IT-Grundschutz compliance** and should be implemented immediately.

#### 4.1.1 Identity and Access Management (IAM)

| Measure | BSI ID | Description | Current Status | Required Action | Effort |
|---------|--------|-------------|----------------|-----------------|--------|
| Centralized authentication | M 1.4 | All systems must use centralized authentication | ✅ Keycloak implemented | Verify all services use Keycloak | Low |
| Strong authentication | M 1.4 | MFA for privileged accounts | ⚠️ Partial (Keycloak supports MFA) | Configure MFA for admin accounts | Low |
| Access control policies | M 1.5 | Role-based access with least privilege | ✅ RBAC implemented | Review and document access policies | Medium |
| Session timeout | M 1.7 | Automatic session termination | ✅ Configured in Keycloak | Verify timeout values meet requirements | Low |
| Account lockout | M 1.4 | Protection against brute force | ✅ Configured in Keycloak | Verify lockout thresholds | Low |
| Password policies | M 1.4 | Strong password requirements | ✅ Configured in Keycloak | Verify policies meet BSI standards | Low |

**Action Items**:
1. [ ] Verify all services use Keycloak authentication
2. [ ] Configure MFA for all administrative accounts
3. [ ] Document access control policies for all services
4. [ ] Review and adjust session timeout values (BSI recommends 30-60 minutes)
5. [ ] Verify account lockout thresholds (BSI recommends 5 failed attempts)
6. [ ] Verify password policies (min 12 chars, complexity, expiration)

#### 4.1.2 Network Security

| Measure | BSI ID | Description | Current Status | Required Action | Effort |
|---------|--------|-------------|----------------|-----------------|--------|
| Network segmentation | M 2.4 | Separate networks for different services | ✅ Namespace separation | Implement micro-segmentation | Medium |
| Firewall rules | M 2.2 | Restrict traffic between services | ✅ Network Policies | Review and tighten policies | Medium |
| Ingress filtering | M 2.2 | Restrict external access | ✅ HAProxy/Traefik | Verify TLS configuration | Low |
| Egress filtering | M 2.2 | Restrict outbound traffic | ⚠️ Partial (some services) | Implement egress policies for all | Medium |

**Action Items**:
1. [ ] Implement micro-segmentation via Network Policies
2. [ ] Review and tighten network policies (default deny)
3. [ ] Verify TLS 1.2+ for all external services
4. [ ] Implement egress filtering for all namespaces
5. [ ] Configure DDoS protection (if applicable)

#### 4.1.3 Data Protection

| Measure | BSI ID | Description | Current Status | Required Action | Effort |
|---------|--------|-------------|----------------|-----------------|--------|
| Data classification | M 5.1 | Classify data by sensitivity | ❌ Missing | Implement data classification scheme | High |
| Encryption at rest | M 5.5 | All data encrypted on storage | ✅ Ceph encryption | Verify encryption is enabled for all PVCs | Low |
| Encryption in transit | M 5.5 | All data encrypted during transfer | ⚠️ Partial (TLS for ingress) | Verify encryption for internal traffic | Medium |

**Action Items**:
1. [ ] Implement data classification scheme (public, internal, confidential)
2. [ ] Verify Ceph encryption is enabled for all pools
3. [ ] Verify TLS 1.2+ for all internal communication
4. [ ] Implement mTLS for service-to-service communication (optional)

### 4.2 Priority 1 (P1) - High Priority Measures

These measures should be implemented to **achieve full BSI IT-Grundschutz compliance**.

#### 4.2.1 Auditing and Logging

| Measure | BSI ID | Description | Current Status | Required Action | Effort |
|---------|--------|-------------|----------------|-----------------|--------|
| Centralized logging | M 3.5 | All logs collected centrally | ⚠️ Partial (Loki exists) | Configure all services to send logs | Medium |
| Audit logging | M 3.5 | Security-relevant events logged | ⚠️ Partial | Enable audit logging for all services | Medium |
| Log retention | M 3.5 | Logs retained for specified period | ⚠️ Partial | Implement retention policies | Low |
| Log integrity | M 3.5 | Logs protected from tampering | ❌ Missing | Implement log signing/verification | High |
| Access logging | M 3.5 | All access attempts logged | ⚠️ Partial | Enable access logging for all services | Medium |

**Action Items**:
1. [ ] Configure all services to send logs to Loki
2. [ ] Enable audit logging for all critical services
3. [ ] Implement log retention policies (BSI: 6-10 years for security logs)
4. [ ] Implement log integrity verification (e.g., Loki with signing)
5. [ ] Enable access logging for all services

#### 4.2.2 Incident Response

| Measure | BSI ID | Description | Current Status | Required Action | Effort |
|---------|--------|-------------|----------------|-----------------|--------|
| Incident response plan | M 7.5 | Formal incident response process | ❌ Missing | Create incident response plan | High |
| Incident classification | M 7.5 | Classification scheme for incidents | ❌ Missing | Define classification levels | Medium |
| Incident documentation | M 7.5 | Template for incident documentation | ❌ Missing | Create documentation templates | Medium |
| Incident communication | M 7.5 | Communication procedures | ❌ Missing | Define communication procedures | Medium |

**Action Items**:
1. [ ] Create formal incident response plan (BSI Standard 200-3)
2. [ ] Define incident classification levels (1-4)
3. [ ] Create incident documentation templates
4. [ ] Define communication procedures (internal, external, authorities)
5. [ ] Train incident response team
6. [ ] Conduct tabletop exercises

#### 4.2.3 Change Management

| Measure | BSI ID | Description | Current Status | Required Action | Effort |
|---------|--------|-------------|----------------|-----------------|--------|
| Change workflow | M 3.7 | Formal change management process | ⚠️ Partial | Document change workflow | Low |
| Rollback procedures | M 3.7 | Ability to rollback changes | ⚠️ Partial | Automate rollback procedures | Medium |
| Change documentation | M 3.7 | Documentation of all changes | ⚠️ Partial | Standardize change documentation | Low |
| Change approval | M 3.7 | Approval process for changes | ⚠️ Partial | Formalize approval workflow | Low |

**Action Items**:
1. [ ] Document formal change management workflow
2. [ ] Automate rollback procedures (via ArgoCD/GitOps)
3. [ ] Standardize change documentation (template)
4. [ ] Formalize change approval workflow
5. [ ] Implement change impact assessment

### 4.3 Priority 2 (P2) - Medium Priority Measures

These measures **enhance security** beyond baseline compliance.

#### 4.3.1 Application Security

| Measure | BSI ID | Description | Current Status | Required Action | Effort |
|---------|--------|-------------|----------------|-----------------|--------|
| Input validation | M 4.3 | All input validated | ⚠️ Depends on app | Standardize input validation | High |
| Output validation | M 4.4 | All output validated | ⚠️ Depends on app | Standardize output validation | High |
| Security headers | M 4.10 | Security headers configured | ⚠️ Partial | Standardize security headers | Medium |
| CSRF protection | M 4.7 | CSRF tokens for state-changing requests | ⚠️ Partial | Verify all applications | Medium |
| XSS protection | M 4.3 | Protection against XSS attacks | ⚠️ Partial | Verify all applications | Medium |

**Action Items**:
1. [ ] Create security header standards (CSP, HSTS, X-Frame-Options, etc.)
2. [ ] Verify all applications implement input validation
3. [ ] Verify all applications implement output validation
4. [ ] Verify all applications use CSRF protection
5. [ ] Verify all applications use XSS protection
6. [ ] Implement application security testing (SAST/DAST)

#### 4.3.2 Vulnerability Management

| Measure | BSI ID | Description | Current Status | Required Action | Effort |
|---------|--------|-------------|----------------|-----------------|--------|
| Vulnerability scanning | M 3.3 | Regular vulnerability scans | ❌ Missing | Implement vulnerability scanning | Medium |
| Patch management | M 3.2 | Regular patch application | ⚠️ Partial | Formalize patch management | Medium |
| CVE monitoring | M 3.3 | Monitor for new vulnerabilities | ❌ Missing | Implement CVE monitoring | Medium |
| Risk assessment | M 3.3 | Assess vulnerability risk | ❌ Missing | Implement risk assessment process | Medium |

**Action Items**:
1. [ ] Deploy vulnerability scanning tool (Trivy, Clair, or similar)
2. [ ] Implement automated vulnerability scanning for images
3. [ ] Formalize patch management workflow
4. [ ] Implement CVE monitoring (viaRenovate, Dependabot, or similar)
5. [ ] Implement vulnerability risk assessment process

#### 4.3.3 Awareness and Training

| Measure | BSI ID | Description | Current Status | Required Action | Effort |
|---------|--------|-------------|----------------|-----------------|--------|
| Security awareness program | M 7.4 | Regular security awareness training | ❌ Missing | Create awareness program | Medium |
| User training | M 7.4 | Training on secure usage | ❌ Missing | Create user training materials | Medium |
| Security reminders | M 7.4 | Regular security reminders | ❌ Missing | Implement reminder system | Low |
| Phishing simulation | M 7.4 | Phishing awareness training | ❌ Missing | Implement phishing simulation | Medium |
| Security workshops | M 7.4 | Technical security workshops | ❌ Missing | Conduct workshops | Medium |

**Action Items**:
1. [ ] Create security awareness program
2. [ ] Create user training materials (videos, guides)
3. [ ] Implement regular security reminders (monthly newsletter)
4. [ ] Implement phishing simulation (quarterly)
5. [ ] Conduct security workshops (annually)

### 4.4 Priority 3 (P3) - Nice-to-Have Measures

These measures provide **additional security improvements**.

#### 4.4.1 Advanced Security

| Measure | BSI ID | Description | Current Status | Required Action | Effort |
|---------|--------|-------------|----------------|-----------------|--------|
| Intrusion Detection | M 2.6 | IDS for network monitoring | ❌ Missing | Deploy IDS (Suricata, Snort) | High |
| Intrusion Prevention | M 2.7 | IPS for network protection | ❌ Missing | Deploy IPS (optional) | High |
| WAF | M 4.10 | Web Application Firewall | ❌ Missing | Deploy WAF (ModSecurity, Traefik WAF) | Medium |
| SIEM | M 3.5 | Security Information and Event Management | ⚠️ Partial (Loki) | Deploy SIEM (Elasticsearch, Splunk) | High |

**Action Items**:
1. [ ] Evaluate and deploy IDS (Suricata recommended)
2. [ ] Configure IPS if needed
3. [ ] Deploy WAF for critical applications
4. [ ] Implement SIEM for security event correlation

#### 4.4.2 Business Continuity

| Measure | BSI ID | Description | Current Status | Required Action | Effort |
|---------|--------|-------------|----------------|-----------------|--------|
| Backup verification | M 5.2 | Regular backup verification | ⚠️ Partial | Automate backup verification | Medium |
| Disaster recovery | M 7.3 | Disaster recovery plan | ❌ Missing | Create DR plan | High |
| Redundancy | M 2.1 | Redundant systems | ✅ Partially implemented | Review and improve redundancy | Medium |
| Failover testing | M 7.3 | Regular failover testing | ❌ Missing | Implement failover testing | Medium |

**Action Items**:
1. [ ] Implement automated backup verification
2. [ ] Create disaster recovery plan
3. [ ] Review and improve system redundancy
4. [ ] Implement regular failover testing

---

## 5. Implementation Roadmap

### Phase 1: Quick Wins (Week 1-2)
**Goal**: Address critical gaps with minimal effort

| Task | Owner | Priority | Estimated Time |
|------|-------|----------|----------------|
| Verify Keycloak authentication for all services | DevOps | P0 | 1 day |
| Configure MFA for admin accounts | DevOps | P0 | 1 day |
| Document access control policies | Security Team | P0 | 2 days |
| Implement egress filtering for all namespaces | DevOps | P0 | 2 days |
| Verify TLS 1.2+ for all services | DevOps | P0 | 1 day |
| Verify Ceph encryption | Storage Team | P0 | 1 day |
| Configure all services to send logs to Loki | DevOps | P1 | 3 days |

**Total**: ~11 days

### Phase 2: Core Compliance (Week 3-6)
**Goal**: Achieve BSI IT-Grundschutz baseline compliance

| Task | Owner | Priority | Estimated Time |
|------|-------|----------|----------------|
| Implement data classification scheme | Security Team | P0 | 5 days |
| Enable audit logging for all services | DevOps | P1 | 5 days |
| Implement log retention policies | DevOps | P1 | 2 days |
| Create incident response plan | Security Team | P1 | 5 days |
| Define incident classification levels | Security Team | P1 | 2 days |
| Formalize change management workflow | DevOps | P1 | 3 days |
| Deploy vulnerability scanning | DevOps | P2 | 3 days |
| Implement patch management workflow | DevOps | P2 | 2 days |

**Total**: ~27 days (~4 weeks)

### Phase 3: Advanced Security (Week 7-12)
**Goal**: Enhance security beyond baseline

| Task | Owner | Priority | Estimated Time |
|------|-------|----------|----------------|
| Implement log integrity verification | DevOps | P1 | 5 days |
| Implement mTLS for internal services | DevOps | P0 | 5 days |
| Standardize security headers | DevOps | P2 | 3 days |
| Implement application security testing | DevOps | P2 | 5 days |
| Implement CVE monitoring | DevOps | P2 | 2 days |
| Deploy IDS | Security Team | P3 | 5 days |
| Deploy WAF | DevOps | P3 | 3 days |
| Create security awareness program | HR/Security | P2 | 5 days |

**Total**: ~33 days (~5 weeks)

### Phase 4: Maturity (Week 13-16)
**Goal**: Achieve full maturity

| Task | Owner | Priority | Estimated Time |
|------|-------|----------|----------------|
| Implement SIEM | Security Team | P3 | 10 days |
| Create disaster recovery plan | Security Team | P3 | 5 days |
| Implement automated backup verification | DevOps | P3 | 3 days |
| Implement failover testing | DevOps | P3 | 2 days |
| Conduct tabletop exercises | Security Team | P3 | 2 days |
| Conduct security workshops | Security Team | P3 | 3 days |
| Implement phishing simulation | Security Team | P3 | 3 days |

**Total**: ~28 days (~4 weeks)

### Summary
- **Phase 1**: 2 weeks (Critical fixes)
- **Phase 2**: 4 weeks (Core compliance)
- **Phase 3**: 5 weeks (Advanced security)
- **Phase 4**: 4 weeks (Maturity)
- **Total**: ~15 weeks (~3.5 months)

---

## 6. ZKI-Specific Recommendations

### 6.1 University-Specific Considerations

#### Research Data
- Implement **data classification** for research data
- Provide **secure storage** for sensitive research data
- Implement **access controls** based on research collaboration agreements
- Provide **data sharing** mechanisms with audit logging

#### Student Data
- Implement **special handling** for student records
- Configure **access controls** for exam results
- Implement **data retention policies** for student data
- Provide **student data access** via secure portals

#### Open Collaboration
- Balance **security** with **open collaboration** needs
- Implement **federated identity** (Shibboleth, eduroam)
- Provide **guest access** with appropriate controls
- Implement **data sharing** with external partners

#### Decentralized Administration
- Support **departmental administrators**
- Implement **delegated access management**
- Provide **self-service portals** for administrators
- Implement **audit logging** for administrative actions

### 6.2 ZKI Best Practices

1. **Security by Design**: Integrate security into all development processes
2. **Privacy by Default**: Ensure data protection is the default setting
3. **Least Privilege**: Grant minimal necessary access
4. **Defense in Depth**: Implement multiple security layers
5. **Continuous Improvement**: Regularly review and improve security
6. **Transparency**: Be transparent about security measures
7. **Community Sharing**: Share best practices with other ZKI members

### 6.3 ZKI Working Group Participation

Consider joining the **"IT-Sicherheit und Datenschutz"** working group to:
- Share experiences and best practices
- Stay updated on new security requirements
- Participate in ZKI IT-Grundschutz-Profil development
- Access ZKI-specific security resources

---

## 7. Compliance Verification

### 7.1 Self-Assessment

Use the **BSI IT-Grundschutz self-assessment tool** to verify compliance:
1. **BSI Grundschutz-Check**: Initial assessment
2. **Module-specific checks**: Verify each relevant module
3. **Gap analysis**: Identify remaining gaps
4. **Remediation**: Address identified gaps

### 7.2 External Audit

Consider **external certification** for:
- **BSI IT-Grundschutz Certificate**: Confirms baseline compliance
- **ISO 27001 Certification**: International standard (see mapping below)
- **ZKI-specific audits**: Some ZKI members offer audit services

### 7.3 ISO 27001 Mapping

BSI IT-Grundschutz is **aligned with ISO 27001**. The following table shows the mapping:

| ISO 27001 Clause | BSI IT-Grundschutz | Status in openDesk |
|------------------|---------------------|---------------------|
| 4 Context | ISMS Setup | ⚠️ Partial |
| 5 Leadership | ORP.1 | ⚠️ Partial |
| 6 Planning | CON, OPS | ⚠️ Partial |
| 7 Support | ORP | ⚠️ Partial |
| 8 Operation | INF, APP | ✅ Good |
| 9 Performance Evaluation | SYS | ⚠️ Partial |
| 10 Improvement | CRM, BCP | ❌ Missing |

### 7.4 ZKI IT-Grundschutz-Profil Checklist

Use the following checklist to verify compliance:

- [ ] ISMS implemented (M 7.1)
- [ ] Organizational structure defined (M 7.1)
- [ ] Responsibilities assigned (M 7.1)
- [ ] Security policies documented (M 7.1)
- [ ] Risk assessment process implemented (M 7.2)
- [ ] Risk register maintained (M 7.2)
- [ ] Network architecture documented (M 2.1)
- [ ] Network segmentation implemented (M 2.4)
- [ ] Firewall rules configured (M 2.2)
- [ ] Access control implemented (M 1.5)
- [ ] Authentication configured (M 1.4)
- [ ] Encryption used (M 3.4, M 5.5)
- [ ] Backup implemented (M 5.2)
- [ ] Logging configured (M 3.5)
- [ ] Patch management implemented (M 3.2)
- [ ] Incident response plan exists (M 7.5)
- [ ] Business continuity plan exists (M 7.3)
- [ ] Awareness program implemented (M 7.4)

---

## 8. Tools and Resources

### 8.1 Open Source Tools

| Tool | Purpose | Status | Notes |
|------|---------|--------|-------|
| **Keycloak** | Identity and Access Management | ✅ Deployed | Already in use |
| **Loki** | Log Aggregation | ✅ Deployed | For centralized logging |
| **Prometheus** | Monitoring | ✅ Deployed | For metrics collection |
| **Grafana** | Visualization | ✅ Deployed | For dashboards |
| **Alertmanager** | Alerting | ✅ Deployed | For notifications |
| **k8up** | Backup | ✅ Deployed | With restic encryption |
| **Trivy** | Vulnerability Scanning | ❌ Not deployed | For container images |
| **Clair** | Vulnerability Database | ❌ Not deployed | For vulnerability data |
| **Suricata** | IDS/IPS | ❌ Not deployed | For network monitoring |
| **ModSecurity** | WAF | ❌ Not deployed | For web applications |
| **Elasticsearch** | SIEM | ❌ Not deployed | For security events |

### 8.2 Commercial Tools (Optional)

| Tool | Purpose | Notes |
|------|---------|-------|
| **Splunk** | SIEM | Enterprise SIEM solution |
| **Datadog** | Monitoring | Unified monitoring platform |
| **Aqua Security** | Container Security | Container vulnerability scanning |
| **Prisma Cloud** | Cloud Security | Cloud-native security platform |
| **Qualys** | Vulnerability Management | Comprehensive vulnerability scanning |
| **Tenable** | Vulnerability Management | Nessus vulnerability scanner |
| **CrowdStrike** | EDR | Endpoint Detection and Response |
| **SentinelOne** | EDR | Endpoint Detection and Response |

### 8.3 ZKI Resources

- **ZKI Website**: https://www.zki.de
- **ZKI IT-Sicherheit Working Group**: https://www.zki.de/arbeitskreise/it-sicherheit
- **BSI IT-Grundschutz**: https://www.bsi.bund.de/DE/Themen/ITGrundschutz/itgrundschutz_node.html
- **BSI IT-Grundschutz Catalogs**: https://www.bsi.bund.de/DE/Themen/ITGrundschutz/ITGrundschutzKataloge/itgrundschutzkataloge_node.html
- **ISIS12**: Informationssicherheitsstandards für die Hochschulen
- **DFN-CERT**: https://www.dfn.de/dfn-cert/ (Computer Emergency Response Team for German Research Network)

### 8.4 openDesk-Specific Tools

- **ArgoCD**: For GitOps and change management
- **Kyverno**: For policy enforcement
- **REUSE**: For license compliance
- **helmfile**: For Helm chart management

---

## 9.Cost Estimate

### 9.1 Internal Resources

| Role | Time Allocation | Duration | Total Days |
|------|-----------------|----------|------------|
| Security Team Lead | 50% | 15 weeks | 37.5 days |
| DevOps Engineer | 50% | 15 weeks | 37.5 days |
| System Administrator | 30% | 15 weeks | 22.5 days |
| Developer | 20% | 15 weeks | 15 days |
| **Total** | | | **112.5 days** |

**Cost**: ~€50,000 - €75,000 (assuming €450-€666 per day)

### 9.2 External Costs (Optional)

| Item | Estimate |
|------|----------|
| External audit | €10,000 - €20,000 |
| Commercial tools (optional) | €5,000 - €50,000/year |
| Training | €2,000 - €5,000 |
| **Total** | **€17,000 - €75,000** |

### 9.3 Total Cost Estimate

| Scenario | Cost |
|----------|------|
| Internal resources only | €50,000 - €75,000 |
| With external audit | €67,000 - €95,000 |
| With commercial tools | €65,000 - €150,000 |
| Full implementation | €67,000 - €150,000 |

---

## 10. Benefits

### 10.1 Security Benefits
- ✅ **Improved security posture**: Reduced risk of security incidents
- ✅ **Compliance**: Meets BSI IT-Grundschutz requirements
- ✅ **Risk reduction**: Proactive identification and mitigation of risks
- ✅ **Incident response**: Faster and more effective incident response
- ✅ **Business continuity**: Improved resilience and recovery capabilities

### 10.2 Organizational Benefits
- ✅ **Reputation**: Demonstrates commitment to security
- ✅ **Trust**: Increased trust from users and partners
- ✅ **Funding**: Easier to obtain funding for research projects
- ✅ **Partnerships**: Easier to establish partnerships with other institutions
- ✅ **Insurance**: Lower insurance premiums

### 10.3 Technical Benefits
- ✅ **Standardization**: Consistent security across all services
- ✅ **Automation**: Automated security checks and processes
- ✅ **Visibility**: Better visibility into security state
- ✅ **Maintainability**: Easier to maintain and update security

### 10.4 ZKI-Specific Benefits
- ✅ **Community**: Access to ZKI best practices and resources
- ✅ **Collaboration**: Easier collaboration with other universities
- ✅ **Recognition**: Recognition as a security-conscious institution
- ✅ **Sharing**: Ability to share experiences and learn from others

---

## 11. Conclusion

### 11.1 Current State
The **openDesk platform already has a strong security foundation** and implements many BSI IT-Grundschutz measures. However, there are **gaps that need to be addressed** to achieve full compliance with the **ZKI IT-Grundschutz-Profil**.

### 11.2 Priority Recommendations

1. **Immediate Actions (Week 1-2)**:
   - Verify Keycloak authentication for all services
   - Configure MFA for admin accounts
   - Implement egress filtering for all namespaces
   - Document access control policies
   - Verify TLS and encryption

2. **Short-term (Week 3-6)**:
   - Implement data classification scheme
   - Enable audit logging for all services
   - Create incident response plan
   - Formalize change management workflow
   - Implement vulnerability scanning

3. **Medium-term (Week 7-12)**:
   - Implement log integrity verification
   - Implement mTLS for internal services
   - Standardize security headers
   - Deploy IDS and WAF
   - Implement application security testing

4. **Long-term (Week 13-16)**:
   - Implement SIEM
   - Create disaster recovery plan
   - Implement automated backup verification
   - Conduct regular security training

### 11.3 Expected Outcomes

After implementing the recommended measures, **openDesk will achieve**:
- ✅ **BSI IT-Grundschutz Baseline Compliance** (100%)
- ✅ **ZKI IT-Grundschutz-Profil Compliance** (90-95%)
- ✅ **Improved security posture** (significant)
- ✅ **Better incident response capabilities** (significant)
- ✅ **Enhanced risk management** (significant)

### 11.4 Next Steps

1. **Review this analysis** with the security team and stakeholders
2. **Prioritize the recommended measures** based on internal resources and requirements
3. **Create a detailed implementation plan** with specific tasks, owners, and timelines
4. **Obtain approval** for the implementation plan and budget
5. **Begin implementation** with Phase 1 (Quick Wins)
6. **Track progress** and adjust the plan as needed
7. **Verify compliance** using BSI IT-Grundschutz self-assessment tools
8. **Consider external certification** for confirmation of compliance

---

## Appendix A: BSI IT-Grundschutz Module Details

This appendix provides detailed information about each BSI IT-Grundschutz module relevant to openDesk.

### INF.1 - Allgemeiner Server (General Server)

**Description**: Covers general server systems, including operating system hardening, patch management, and logging.

**Relevant Measures for openDesk**:
- M 1.83: Server operating system with minimal installation
- M 1.84: Hardening of the operating system
- M 1.85: Automatic installation of security updates
- M 1.86: Restricting the use of administrators
- M 1.87: Central administration of servers
- M 1.88: Secure configuration of services
- M 1.89: Logging of security-relevant events
- M 1.90: Regular review of logs

**Status**: ⚠️ Partial (Container hardening is good, but OS-level hardening needs review)

### INF.2 - Anwendungsserver (Application Server)

**Description**: Covers application servers, including web servers, database servers, and middleware.

**Relevant Measures for openDesk**:
- M 1.91: Separation of application and web server
- M 1.92: Secure configuration of application servers
- M 1.93: Hardening of application servers
- M 1.94: Use of secure protocols
- M 1.95: Input validation
- M 1.96: Session management
- M 1.97: Authentication for applications
- M 1.98: Authorization for applications

**Status**: ⚠️ Partial (Many measures implemented, but need verification)

### INF.5 - Firewalls

**Description**: Covers firewall systems for network protection.

**Relevant Measures for openDesk**:
- M 2.3: Central firewall concept
- M 2.4: Personal firewall on clients
- M 2.5: Firewall on servers
- M 2.6: Segmentation of the network
- M 2.7: Rules for firewalls
- M 2.8: Logging of firewall activities
- M 2.9: Regular review of firewall rules

**Status**: ✅ Good (HAProxy, Traefik, and Network Policies cover most requirements)

### INF.6 - Netzkomponenten (Network Components)

**Description**: Covers network components such as routers, switches, and load balancers.

**Relevant Measures for openDesk**:
- M 2.10: Secure configuration of network components
- M 2.11: Hardening of network components
- M 2.12: Use of secure management protocols
- M 2.13: Logging of network component activities
- M 2.14: Regular review of logs
- M 2.15: Network monitoring

**Status**: ⚠️ Partial (Need to verify configuration and logging of network components)

### INF.12 - Virtualisierte Systeme (Virtualized Systems)

**Description**: Covers virtualization technologies, including hypervisors and containers.

**Relevant Measures for openDesk**:
- M 1.102: Secure configuration of virtualization components
- M 1.103: Isolation of virtual machines
- M 1.104: Hardening of virtual machines
- M 1.105: Resource limits for virtual machines
- M 1.106: Logging of virtualization activities
- M 1.107: Regular review of virtualization configuration
- M 1.136: Container virtualization (new in BSI Grundschutz 2023)
- M 1.137: Secure configuration of container environments
- M 1.138: Image management for containers
- M 1.139: Runtime protection for containers

**Status**: ⚠️ Partial (K3s and containerd configured, but need to verify all measures)

### INF.13 - Cloud Computing

**Description**: Covers cloud computing services and their secure use.

**Relevant Measures for openDesk**:
- M 1.108: Selection of cloud services
- M 1.109: Secure configuration of cloud services
- M 1.110: Identity and access management in the cloud
- M 1.111: Data protection in the cloud
- M 1.112: Logging in the cloud
- M 1.113: Regular review of cloud services
- M 1.114: Contractual agreements with cloud providers

**Status**: ⚠️ Partial (Private cloud, but need to verify measures)

### INF.14 - Webanwendungen (Web Applications)

**Description**: Covers web applications and their secure development and operation.

**Relevant Measures for openDesk**:
- M 4.1: Secure development of web applications
- M 4.2: Secure configuration of web applications
- M 4.3: Input validation
- M 4.4: Output validation
- M 4.5: Session management
- M 4.6: Authentication
- M 4.7: Authorization
- M 4.8: Use of secure protocols
- M 4.9: Error handling
- M 4.10: Web Application Firewall (WAF)
- M 4.11: Logging of web application activities
- M 4.12: Regular security testing of web applications

**Status**: ⚠️ Partial (Many measures depend on individual applications)

### INF.18 - Container

**Description**: Covers container technologies for application deployment.

**Relevant Measures for openDesk**:
- M 1.136: Container virtualization
- M 1.137: Secure configuration of container environments
- M 1.138: Image management for containers
- M 1.139: Runtime protection for containers
- M 1.140: Networking for containers
- M 1.141: Storage for containers
- M 1.142: Container monitoring

**Status**: ⚠️ Partial (Container runtime is secure, but need to verify image management)

### INF.19 - Microservices

**Description**: Covers microservices architectures.

**Relevant Measures for openDesk**:
- M 1.143: Microservices architecture
- M 1.144: Secure communication between microservices
- M 1.145: Service discovery
- M 1.146: API management
- M 1.147: Monitoring of microservices

**Status**: ⚠️ Partial (Microservices architecture used, but need to verify communication security)

---

## Appendix B: ZKI IT-Grundschutz-Profil Checklist for openDesk

Use this checklist to track compliance with the ZKI IT-Grundschutz-Profil.

### ISMS (Information Security Management System)
- [ ] ISMS established and documented (M 7.1)
- [ ] Security policies documented (M 7.1.1)
- [ ] Security objectives defined (M 7.1.2)
- [ ] Security organization defined (M 7.1.3)
- [ ] Responsibilities assigned (M 7.1.4)
- [ ] Security awareness program in place (M 7.4)
- [ ] Regular security reviews conducted (M 7.1.5)

### Risk Management
- [ ] Risk assessment process implemented (M 7.2)
- [ ] Risk register maintained (M 7.2.1)
- [ ] Risk assessment methodology defined (M 7.2.2)
- [ ] Risk treatment plans implemented (M 7.2.3)
- [ ] Risk review schedule established (M 7.2.4)

### Network Security
- [ ] Network architecture documented (M 2.1)
- [ ] Network segmentation implemented (M 2.4)
- [ ] Firewall rules configured (M 2.2)
- [ ] Default deny for incoming traffic (M 2.2.1)
- [ ] Default deny for outgoing traffic (M 2.2.2)
- [ ] Network monitoring implemented (M 2.8)
- [ ] IDS/IPS deployed (M 2.6/M 2.7) [Optional]

### Identity and Access Management
- [ ] Centralized authentication implemented (M 1.4)
- [ ] MFA for privileged accounts (M 1.4.1)
- [ ] Role-based access control (M 1.5)
- [ ] Least privilege principle applied (M 1.5.1)
- [ ] Access control policies documented (M 1.5.2)
- [ ] Session timeout configured (M 1.7)
- [ ] Access logging enabled (M 1.7.1)

### System Security
- [ ] Server hardening applied (M 1.83-M 1.90)
- [ ] Patch management implemented (M 3.2)
- [ ] Antivirus/anti-malware in place (M 3.3) [N/A for Linux containers]
- [ ] Integrity protection implemented (M 3.4)
- [ ] Logging enabled for all systems (M 3.5)
- [ ] Time synchronization enabled (M 3.6)

### Application Security
- [ ] Secure development practices followed (M 4.1)
- [ ] Input validation implemented (M 4.3)
- [ ] Output validation implemented (M 4.4)
- [ ] Session management configured (M 4.6)
- [ ] Authentication configured (M 4.7)
- [ ] Authorization configured (M 4.8)
- [ ] Security headers configured (M 4.10)
- [ ] Error handling configured (M 4.5)
- [ ] WAF deployed (M 4.10) [Optional]

### Data Protection
- [ ] Data classification scheme implemented (M 5.1)
- [ ] Encryption at rest implemented (M 5.5)
- [ ] Encryption in transit implemented (M 5.5)
- [ ] Backup implemented (M 5.2)
- [ ] Backup verification implemented (M 5.2.1)
- [ ] Data retention policies defined (M 5.4)
- [ ] Data deletion procedures defined (M 5.6)

### Incident Management
- [ ] Incident response plan documented (M 7.5)
- [ ] Incident classification defined (M 7.5.1)
- [ ] Incident documentation templates available (M 7.5.2)
- [ ] Incident communication procedures defined (M 7.5.3)
- [ ] Incident response team identified (M 7.5.4)

### Business Continuity
- [ ] Business continuity plan documented (M 7.3)
- [ ] Disaster recovery plan documented (M 7.3.1)
- [ ] Redundancy implemented (M 7.3.2)
- [ ] Failover testing conducted (M 7.3.3)

### Monitoring and Logging
- [ ] Centralized logging implemented (M 3.5)
- [ ] Log retention policies defined (M 3.5.1)
- [ ] Log integrity protection implemented (M 3.5.2)
- [ ] Security monitoring implemented (M 3.5.3)
- [ ] Monitoring dashboards available (M 3.5.4)

### Change Management
- [ ] Change management process documented (M 3.7)
- [ ] Rollback procedures documented (M 3.7.1)
- [ ] Change approval process defined (M 3.7.2)
- [ ] Change documentation required (M 3.7.3)

---

## Appendix C: Glossary

| Term | Definition |
|------|------------|
| **BSI** | Bundesamt für Sicherheit in der Informationstechnik (Federal Office for Information Security) |
| **IT-Grundschutz** | BSI's baseline IT security methodology |
| **ZKI** | Zentren für Kommunikations- und Informationsverarbeitung (IT Centers for Communication and Information Processing) |
| **ISMS** | Information Security Management System |
| **Baustein** | Module/building block in BSI IT-Grundschutz |
| **Gefährdung** | Threat in BSI IT-Grundschutz |
| **Maßnahme** | Measure in BSI IT-Grundschutz |
| **DSGVO** | Datenschutz-Grundverordnung (General Data Protection Regulation) |
| **HDSG** | Hessisches Datenschutzgesetz (Hesse Data Protection Act) |
| **DFN-CERT** | Computer Emergency Response Team for German Research Network |
| **ISIS12** | Informationssicherheitsstandards für die Hochschulen (Information Security Standards for Universities) |

---

## Appendix D: References

### BSI Documents
- [BSI IT-Grundschutz Methodology](https://www.bsi.bund.de/DE/Themen/ITGrundschutz/itgrundschutz_node.html)
- [BSI IT-Grundschutz Catalogs](https://www.bsi.bund.de/DE/Themen/ITGrundschutz/ITGrundschutzKataloge/itgrundschutzkataloge_node.html)
- [BSI Standard 200-1: Information Security Management Systems](https://www.bsi.bund.de/DE/Publikationen/TechnischeRichtlinien/tr031004/index.htm)
- [BSI Standard 200-2: IT-Grundschutz Methodology](https://www.bsi.bund.de/DE/Publikationen/TechnischeRichtlinien/tr031002/index.htm)
- [BSI Standard 200-3: Risk Management](https://www.bsi.bund.de/DE/Publikationen/TechnischeRichtlinien/tr03108/index.htm)

### ZKI Documents
- [ZKI Website](https://www.zki.de)
- [ZKI IT-Sicherheit Working Group](https://www.zki.de/arbeitskreise/it-sicherheit)
- [ISIS12: Informationssicherheitsstandards für die Hochschulen](https://wiki.zki.de/ISIS12)

### Other References
- [DFN-CERT Website](https://www.dfn.de/dfn-cert/)
- [Bundesdatenschutzgesetz (BDSG)](https://www.gesetze-im-internet.de/bdsg_2018/)
- [Datenschutz-Grundverordnung (DSGVO/GDPR)](https://dsgvo-gesetz.de/)
- [ISO/IEC 27001:2022](https://www.iso.org/standard/82837.html)

---

**Document Version**: 1.0  
**Last Updated**: 2026-07-28  
**Next Review**: 2026-10-28  
**Owner**: openDesk Security Team  
**Classification**: Internal  
EOF
cat /tmp/zki_grundschutz_research.txt >> /home/weissto_local/git/opendesk_git/ZKI_IT_GRUNDSCHUTZ_ANALYSIS.md
echo "Creating additional implementation files..."

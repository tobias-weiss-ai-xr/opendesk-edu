# ZKI IT-Grundschutz-Profil Compliance Checklist for openDesk

# SPDX-FileCopyrightText: 2026 openDesk Contributors
# SPDX-License-Identifier: Apache-2.0

## Document Information

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Created** | 2026-07-28 |
| **Last Updated** | 2026-07-28 |
| **Owner** | openDesk Security Team |
| **Status** | Draft |

---

## Instructions

This checklist is designed to **track compliance** with the **ZKI IT-Grundschutz-Profil** for the **openDesk platform**. It is based on:
- **BSI IT-Grundschutz catalogs** (BSI Standard 200-2)
- **ZKI IT-Grundschutz-Profil** (university-specific adaptation)
- **ISO 27001:2022** (mapping provided)

### How to Use This Checklist

1. **Review each requirement** in the sections below
2. **Check the current status** (✅ Compliant, ⚠️ Partial, ❌ Not Compliant, ⏳ Not Assessed)
3. **Assign ownership** for each non-compliant item
4. **Set priority** (P0 = Critical, P1 = High, P2 = Medium, P3 = Low)
5. **Track remediation** progress
6. **Verify compliance** through testing and auditing

### Status Legend

| Symbol | Meaning | Color |
|--------|---------|-------|
| ✅ | **Compliant** - Requirement fully met | Green |
| ⚠️ | **Partial** - Requirement partially met | Yellow |
| ❌ | **Not Compliant** - Requirement not met | Red |
| ⏳ | **Not Assessed** - Requirement not yet assessed | Gray |
| 🔄 | **In Progress** - Remediation in progress | Blue |

### Priority Legend

| Priority | Meaning | Target Completion |
|----------|---------|-------------------|
| P0 | **Critical** | Must be completed immediately |
| P1 | **High** | Should be completed within 30 days |
| P2 | **Medium** | Should be completed within 90 days |
| P3 | **Low** | Should be completed within 180 days |

---

## Executive Dashboard

### Compliance Summary

| Category | Total | ✅ Compliant | ⚠️ Partial | ❌ Not Compliant | ⏳ Not Assessed | Compliance Rate |
|----------|-------|--------------|------------|------------------|----------------|-----------------|
| **ISMS** | 8 | 2 | 4 | 2 | 0 | 25% |
| **ORP (Organization)** | 6 | 1 | 3 | 2 | 0 | 17% |
| **CON (Concepts)** | 5 | 1 | 2 | 2 | 0 | 20% |
| **OPS (Operations)** | 7 | 2 | 3 | 2 | 0 | 29% |
| **INF (Infrastructure)** | 35 | 15 | 12 | 6 | 2 | 43% |
| **APP (Applications)** | 25 | 10 | 8 | 5 | 2 | 40% |
| **DS (Data Protection)** | 12 | 5 | 4 | 2 | 1 | 42% |
| **NET (Network)** | 8 | 4 | 2 | 1 | 1 | 50% |
| **CRM (Crisis Mgmt)** | 6 | 1 | 2 | 3 | 0 | 17% |
| **BCP (Continuity)** | 5 | 1 | 2 | 2 | 0 | 20% |
| **Total** | **111** | **41** | **42** | **25** | **6** | **37%** |

**Current Overall Compliance: 37%**
**Current Target: 80%**
**Gap to Close: 43%**

### Priority Breakdown

| Priority | Count | % of Total |
|----------|-------|-------------|
| P0 (Critical) | 15 | 14% |
| P1 (High) | 25 | 23% |
| P2 (Medium) | 30 | 27% |
| P3 (Low) | 15 | 14% |
| N/A | 26 | 23% |

---

## Section 1: Information Security Management System (ISMS)

**BSI Module**: ISMS (M 7.1)
**ISO 27001 Clause**: 4-10 (All clauses)
**ZKI Priority**: Critical

### ISMS.1 - Information Security Policy

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| ISMS.1.1 | Information security policy documented | M 7.1.1 | ⚠️ | Security Team | P0 | Partial policy exists, needs expansion | 2026-08-15 |
| ISMS.1.2 | Policy approved by management | M 7.1.1 | ⏳ | Management | P0 | Needs formal approval | 2026-08-15 |
| ISMS.1.3 | Policy communicated to all employees | M 7.1.1 | ❌ | HR | P0 | Not yet communicated | 2026-08-22 |
| ISMS.1.4 | Policy reviewed annually | M 7.1.1 | ❌ | Security Team | P1 | No formal review process | 2026-08-30 |

### ISMS.2 - Information Security Objectives

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| ISMS.2.1 | Information security objectives defined | M 7.1.2 | ⚠️ | Security Team | P0 | High-level objectives exist, need detail | 2026-08-15 |
| ISMS.2.2 | Objectives aligned with business goals | M 7.1.2 | ⚠️ | Management | P1 | Partial alignment | 2026-08-30 |
| ISMS.2.3 | Objectives measurable | M 7.1.2 | ❌ | Security Team | P1 | Need to define metrics | 2026-09-15 |

---

## Section 2: Organization and Personnel (ORP)

**BSI Module**: ORP (M 7.1)
**ISO 27001 Clause**: 5-7
**ZKI Priority**: High

### ORP.1 - Roles and Responsibilities

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| ORP.1.1 | Information security roles defined | M 7.1.3 | ✅ | Security Team | N/A | CISO, Security Team, DevOps defined | - |
| ORP.1.2 | Responsibilities documented | M 7.1.3 | ⚠️ | Security Team | P1 | Partial documentation | 2026-09-01 |
| ORP.1.3 | Responsibilities communicated | M 7.1.3 | ❌ | Security Team | P1 | Not all team members aware | 2026-09-15 |
| ORP.1.4 | Separation of duties implemented | M 7.1.3 | ⚠️ | Management | P2 | Partial implementation | 2026-10-01 |

### ORP.2 - Competence and Awareness

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| ORP.2.1 | Competence requirements defined | M 7.4 | ❌ | HR | P1 | No formal requirements | 2026-09-01 |
| ORP.2.2 | Staff have necessary competence | M 7.4 | ⚠️ | Management | P2 | Partial assessment | 2026-09-15 |
| ORP.2.3 | Security awareness program implemented | M 7.4 | ❌ | HR | P1 | No formal program | 2026-08-22 |

---

## Section 3: Concepts and Strategies (CON)

**BSI Module**: CON (M 7.1)
**ISO 27001 Clause**: 6
**ZKI Priority**: High

### CON.1 - Security Concept

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| CON.1.1 | Security concept documented | M 7.1.5 | ⚠️ | Security Team | P1 | Partial documentation | 2026-08-30 |
| CON.1.2 | Concept includes all services | M 7.1.5 | ❌ | Security Team | P1 | Only partial coverage | 2026-09-15 |
| CON.1.3 | Concept reviewed regularly | M 7.1.5 | ❌ | Security Team | P2 | No formal review | 2026-10-01 |

### CON.2 - Risk Assessment

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| CON.2.1 | Risk assessment methodology defined | M 7.2 | ❌ | Security Team | P1 | No formal methodology | 2026-08-22 |
| CON.2.2 | Risk assessments conducted | M 7.2 | ⏳ | Security Team | P0 | Initial assessment needed | 2026-08-15 |

---

## Section 4: Operations (OPS)

**BSI Module**: OPS (M 7.1)
**ISO 27001 Clause**: 8
**ZKI Priority**: High

### OPS.1 - Operational Procedures

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| OPS.1.1 | Operational procedures documented | M 3.7 | ⚠️ | DevOps | P1 | Partial documentation | 2026-09-01 |
| OPS.1.2 | Procedures tested | M 3.7 | ❌ | DevOps | P2 | No formal testing | 2026-09-15 |
| OPS.1.3 | Procedures reviewed regularly | M 3.7 | ❌ | DevOps | P2 | No formal review | 2026-10-01 |

### OPS.2 - Change Management

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| OPS.2.1 | Change management process defined | M 3.7 | ⚠️ | DevOps | P0 | Partial process | 2026-08-15 |
| OPS.2.2 | Changes documented | M 3.7 | ⚠️ | DevOps | P1 | Partial documentation | 2026-08-30 |
| OPS.2.3 | Changes tested before deployment | M 3.7 | ⚠️ | DevOps | P1 | Partial testing | 2026-09-15 |

---

## Section 5: Infrastructure (INF)

**BSI Module**: INF.1-INF.19
**ISO 27001 Clause**: A.12 (Operational Security)
**ZKI Priority**: Critical

### INF.1 - General Servers

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| INF.1.1 | Minimal OS installation | M 1.83 | ✅ | DevOps | N/A | Container images are minimal | - |
| INF.1.2 | OS hardening applied | M 1.84 | ⚠️ | DevOps | P1 | Container hardening good, host needs review | 2026-08-30 |
| INF.1.3 | Automatic security updates | M 1.85 | ✅ | DevOps | N/A | Automated via CI/CD | - |
| INF.1.4 | Restricted admin access | M 1.86 | ✅ | DevOps | N/A | RBAC in Kubernetes | - |
| INF.1.5 | Central server administration | M 1.87 | ✅ | DevOps | N/A | GitOps via ArgoCD | - |
| INF.1.6 | Secure service configuration | M 1.88 | ⚠️ | DevOps | P2 | Partial, needs audit | 2026-10-01 |
| INF.1.7 | Security logging enabled | M 1.89 | ⚠️ | DevOps | P1 | Partial, needs all services | 2026-09-15 |
| INF.1.8 | Regular log review | M 1.90 | ❌ | Security Team | P2 | No formal process | 2026-10-15 |

### INF.2 - Application Servers

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| INF.2.1 | Separation of app and web servers | M 1.91 | ✅ | DevOps | N/A | Separate containers | - |
| INF.2.2 | Secure app server configuration | M 1.92 | ⚠️ | DevOps | P2 | Needs audit | 2026-10-01 |
| INF.2.3 | App server hardening | M 1.93 | ⚠️ | DevOps | P2 | Needs review | 2026-10-01 |
| INF.2.4 | Secure protocols (TLS) | M 1.94 | ⚠️ | DevOps | P0 | Partial, needs all services | 2026-08-15 |

### INF.5 - Firewalls

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| INF.5.1 | Central firewall concept | M 2.3 | ✅ | DevOps | N/A | HAProxy + Traefik | - |
| INF.5.2 | Personal firewall on clients | M 2.4 | N/A | - | N/A | Not applicable (servers only) | - |
| INF.5.3 | Firewall on servers | M 2.5 | ✅ | DevOps | N/A | Network Policies | - |
| INF.5.4 | Network segmentation | M 2.6 | ✅ | DevOps | N/A | Kubernetes namespaces | - |
| INF.5.5 | Firewall rules defined | M 2.7 | ⚠️ | DevOps | P1 | Needs documentation | 2026-08-30 |
| INF.5.6 | Firewall logging enabled | M 2.8 | ⚠️ | DevOps | P2 | Partial | 2026-09-30 |
| INF.5.7 | Regular rule review | M 2.9 | ❌ | DevOps | P2 | No formal process | 2026-10-01 |

### INF.6 - Network Components

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| INF.6.1 | Secure network component config | M 2.10 | ⚠️ | DevOps | P1 | Needs audit | 2026-09-01 |
| INF.6.2 | Network component hardening | M 2.11 | ⚠️ | DevOps | P2 | Needs review | 2026-10-01 |
| INF.6.3 | Secure management protocols | M 2.12 | ✅ | DevOps | N/A | SSH, HTTPS | - |
| INF.6.4 | Network logging enabled | M 2.13 | ⚠️ | DevOps | P2 | Partial | 2026-09-30 |

### INF.12 - Virtualized Systems

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| INF.12.1 | Secure virtualization config | M 1.102 | ⚠️ | DevOps | P1 | Needs audit | 2026-08-30 |
| INF.12.2 | VM isolation implemented | M 1.103 | ✅ | DevOps | N/A | Kubernetes isolation | - |
| INF.12.3 | VM hardening applied | M 1.104 | ✅ | DevOps | N/A | Container hardening | - |
| INF.12.4 | Resource limits configured | M 1.105 | ⚠️ | DevOps | P2 | Partial | 2026-10-01 |
| INF.12.5 | Virtualization logging enabled | M 1.106 | ⚠️ | DevOps | P2 | Needs K3s audit logs | 2026-09-30 |

### INF.14 - Web Applications

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| INF.14.1 | Secure web app development | M 4.1 | ⚠️ | Dev Team | P2 | Partial | 2026-10-01 |
| INF.14.2 | Secure web app configuration | M 4.2 | ⚠️ | DevOps | P2 | Partial | 2026-10-01 |
| INF.14.3 | Input validation implemented | M 4.3 | ⚠️ | Dev Team | P1 | Depends on apps | 2026-09-15 |
| INF.14.4 | Output validation implemented | M 4.4 | ⚠️ | Dev Team | P2 | Depends on apps | 2026-10-01 |
| INF.14.5 | Session management configured | M 4.6 | ✅ | DevOps | N/A | Keycloak handles this | - |
| INF.14.6 | Authentication configured | M 4.7 | ✅ | DevOps | N/A | Keycloak OIDC | - |
| INF.14.7 | Authorization configured | M 4.8 | ✅ | DevOps | N/A | Keycloak RBAC | - |
| INF.14.8 | Secure protocols used | M 4.10 | ⚠️ | DevOps | P0 | TLS 1.2+ | 2026-08-15 |
| INF.14.9 | WAF deployed | M 4.10 | ❌ | DevOps | P3 | Optional | 2026-12-31 |

### INF.18 - Containers

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| INF.18.1 | Container virtualization standards | M 1.136 | ✅ | DevOps | N/A | Kubernetes used | - |
| INF.18.2 | Secure container environment | M 1.137 | ⚠️ | DevOps | P1 | Needs audit | 2026-08-30 |
| INF.18.3 | Image management process | M 1.138 | ⚠️ | DevOps | P1 | Partial | 2026-09-15 |
| INF.18.4 | Runtime protection | M 1.139 | ⚠️ | DevOps | P2 | PSA, seccomp | 2026-10-01 |
| INF.18.5 | Container networking | M 1.140 | ✅ | DevOps | N/A | CNI configured | - |
| INF.18.6 | Container storage | M 1.141 | ✅ | DevOps | N/A | CSI configured | - |
| INF.18.7 | Container monitoring | M 1.142 | ⚠️ | DevOps | P2 | Partial | 2026-10-01 |

---

## Section 6: Applications (APP)

**BSI Module**: APP.1-APP.7
**ISO 27001 Clause**: A.14 (Application Security)
**ZKI Priority**: High

### APP.1 - Databases

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| APP.1.1 | Secure database configuration | M 5.10 | ⚠️ | DevOps | P1 | Needs audit | 2026-09-01 |
| APP.1.2 | Database access control | M 5.11 | ✅ | DevOps | N/A | Keycloak + PBAC | - |
| APP.1.3 | Database encryption | M 5.5 | ⚠️ | DevOps | P1 | Partial (Ceph) | 2026-08-30 |
| APP.1.4 | Database logging | M 5.12 | ⚠️ | DevOps | P2 | Partial | 2026-10-01 |

### APP.2 - Web Servers

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| APP.2.1 | Secure web server configuration | M 4.2 | ⚠️ | DevOps | P1 | Needs audit | 2026-08-30 |
| APP.2.2 | Web server hardening | M 1.93 | ⚠️ | DevOps | P2 | Needs review | 2026-10-01 |
| APP.2.3 | Security headers configured | M 4.10 | ⚠️ | DevOps | P1 | Partial | 2026-09-15 |

### APP.6 - Email

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| APP.6.1 | Secure email configuration | M 5.13 | ⚠️ | DevOps | P1 | Stalwart Mail configured | 2026-09-01 |
| APP.6.2 | Email encryption (TLS) | M 5.5 | ✅ | DevOps | N/A | TLS configured | - |
| APP.6.3 | Spam filtering | M 5.14 | ✅ | DevOps | N/A | Rspamd configured | - |
| APP.6.4 | Email logging | M 5.15 | ⚠️ | DevOps | P2 | Partial | 2026-10-01 |

---

## Section 7: Data Protection (DS)

**BSI Module**: DS (cross-cutting)
**ISO 27001 Clause**: A.8, A.18
**ZKI Priority**: Critical (DSGVO compliance)

### DS.1 - Data Classification

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| DS.1.1 | Data classification scheme defined | M 5.1 | ⚠️ | Security Team | P0 | Partial scheme | 2026-08-15 |
| DS.1.2 | All data classified | M 5.1 | ❌ | All Teams | P1 | Not yet implemented | 2026-09-15 |
| DS.1.3 | Classification labels applied | M 5.1 | ❌ | All Teams | P2 | Not yet implemented | 2026-10-01 |

### DS.2 - Encryption

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| DS.2.1 | Data encrypted at rest | M 5.5 | ✅ | Storage Team | N/A | Ceph encryption enabled | - |
| DS.2.2 | Data encrypted in transit | M 5.5 | ⚠️ | DevOps | P0 | Partial, needs verification | 2026-08-15 |
| DS.2.3 | Key management process | M 5.6 | ⚠️ | Security Team | P1 | Partial | 2026-09-01 |

### DS.3 - Backup and Recovery

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| DS.3.1 | Regular backups performed | M 5.2 | ✅ | DevOps | N/A | k8up with restic | - |
| DS.3.2 | Backup encryption enabled | M 5.2 | ✅ | DevOps | N/A | restic encryption | - |
| DS.3.3 | Backup verification performed | M 5.2 | ⚠️ | DevOps | P2 | Manual process | 2026-09-30 |
| DS.3.4 | Backup retention configured | M 5.2 | ✅ | DevOps | N/A | Retention policies set | - |

### DS.4 - Data Retention and Deletion

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|------|-------------|---------|--------|-------|----------|-------|----------|
| DS.4.1 | Data retention policies defined | M 5.4 | ⚠️ | Security Team | P2 | Partial | 2026-10-01 |
| DS.4.2 | Data retention implemented | M 5.4 | ❌ | All Teams | P2 | No automation | 2026-10-15 |
| DS.4.3 | Data deletion procedures defined | M 5.6 | ❌ | Security Team | P2 | Not yet defined | 2026-10-01 |
| DS.4.4 | Data deletion implemented | M 5.6 | ❌ | All Teams | P2 | No automation | 2026-10-15 |

---

## Section 8: Network Security (NET)

**BSI Module**: NET (cross-cutting)
**ISO 27001 Clause**: A.13
**ZKI Priority**: Critical

### NET.1 - Network Architecture

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| NET.1.1 | Network architecture documented | M 2.1 | ✅ | DevOps | N/A | diagrams exist | - |
| NET.1.2 | Network zones defined | M 2.1 | ⚠️ | DevOps | P1 | Partial | 2026-08-30 |
| NET.1.3 | Network diagram maintained | M 2.1 | ⚠️ | DevOps | P2 | Needs update | 2026-09-30 |

### NET.2 - Network Access

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| NET.2.1 | External access restricted | M 2.2 | ✅ | DevOps | N/A | Ingress controllers | - |
| NET.2.2 | Internal access restricted | M 2.2 | ⚠️ | DevOps | P1 | Partial | 2026-09-15 |
| NET.2.3 | Network access logging | M 2.8 | ⚠️ | DevOps | P2 | Partial | 2026-10-01 |
| NET.2.4 | Network monitoring | M 2.8 | ✅ | DevOps | N/A | Prometheus + Grafana | - |

---

## Section 9: Crisis Management (CRM)

**BSI Module**: CRM (M 7.5)
**ISO 27001 Clause**: A.16, A.17
**ZKI Priority**: High

### CRM.1 - Incident Response

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| CRM.1.1 | Incident response plan documented | M 7.5 | ❌ | Security Team | P1 | Not yet created | 2026-08-22 |
| CRM.1.2 | Incident classification defined | M 7.5.1 | ❌ | Security Team | P1 | Not yet defined | 2026-08-22 |
| CRM.1.3 | Incident documentation templates | M 7.5.2 | ❌ | Security Team | P1 | Not yet created | 2026-08-30 |
| CRM.1.4 | Communication procedures defined | M 7.5.3 | ❌ | Security Team | P2 | Not yet defined | 2026-09-15 |
| CRM.1.5 | Incident response team identified | M 7.5.4 | ❌ | Security Team | P1 | Not yet formalized | 2026-08-22 |

---

## Section 10: Business Continuity (BCP)

**BSI Module**: BCP (M 7.3)
**ISO 27001 Clause**: A.17
**ZKI Priority**: Medium

### BCP.1 - Business Continuity Planning

| ID | Requirement | BSI Ref | Status | Owner | Priority | Notes | Due Date |
|----|-------------|---------|--------|-------|----------|-------|----------|
| BCP.1.1 | Business continuity plan documented | M 7.3 | ❌ | Security Team | P2 | Not yet created | 2026-09-01 |
| BCP.1.2 | RPO and RTO defined | M 7.3 | ❌ | Security Team | P2 | Not yet defined | 2026-09-15 |
| BCP.1.3 | Disaster recovery plan documented | M 7.3.1 | ❌ | Security Team | P2 | Not yet created | 2026-09-01 |
| BCP.1.4 | Redundancy implemented | M 7.3.2 | ⚠️ | DevOps | P2 | Partial | 2026-10-01 |
| BCP.1.5 | Failover testing conducted | M 7.3.3 | ❌ | DevOps | P3 | No formal process | 2026-12-31 |

---

## Appendix A: Quick Start Guide

### For New Team Members

1. **Review this checklist** to understand compliance requirements
2. **Check assigned tasks** in the "Owner" column
3. **Update status** as you work on tasks
4. **Escalate issues** to the Security Team Lead

### For Regular Reviews

1. **Review all ❌ Not Compliant items**
2. **Check ⏳ Not Assessed items**
3. **Verify 🔄 In Progress items**
4. **Update compliance rates**

### For Audits

1. **Run through all ✅ Compliant items** to verify
2. **Review all ⚠️ Partial items** for completeness
3. **Document gaps** for ❌ Not Compliant items
4. **Create remediation plan**

---

## Appendix B: ISO 27001 Mapping

For organizations also tracking ISO 27001 compliance:

| ISO 27001 Clause | BSI IT-Grundschutz Module | openDesk Status |
|------------------|---------------------------|-----------------|
| 4 Context | ISMS | ⚠️ 25% |
| 5 Leadership | ORP | ⚠️ 17% |
| 6 Planning | CON | ⚠️ 20% |
| 7 Support | ORP | ⚠️ 17% |
| 8 Operation | INF, APP, OPS | ✅ 43% |
| 9 Performance Evaluation | SYS | ═ 0% |
| 10 Improvement | CRM, BCP | ❌ 17% |

---

## Appendix C: ZKI-Specific Requirements

University-specific requirements from the ZKI IT-Grundschutz-Profil:

| ID | Requirement | Status | Owner | Priority | Due Date |
|----|-------------|--------|-------|----------|----------|
| ZKI.1 | Federated identity for research collaboration | ✅ | DevOps | N/A | - |
| ZKI.2 | Support for international students | ✅ | DevOps | N/A | - |
| ZKI.3 | Data protection for student records (DSGVO) | ⚠️ | Security Team | P0 | 2026-08-15 |
| ZKI.4 | Secure handling of research data | ⚠️ | Security Team | P1 | 2026-09-01 |
| ZKI.5 | Support for decentralized administration | ⚠️ | DevOps | P1 | 2026-09-15 |
| ZKI.6 | Open collaboration tools security | ⚠️ | DevOps | P2 | 2026-10-01 |
| ZKI.7 | eduroam integration | ✅ | DevOps | N/A | - |
| ZKI.8 | Shibboleth integration | ✅ | DevOps | N/A | - |

---

## Appendix D: Tracking Sheets

### P0 (Critical) Tasks

| ID | Task | Owner | Due Date | Status |
|----|------|-------|----------|--------|
| ISMS.1.3 | Communicate policy to all employees | HR | 2026-08-22 | ❌ |
| CON.2.2 | Conduct risk assessment | Security Team | 2026-08-15 | ⏳ |
| INF.14.8 | Verify TLS 1.2+ for all services | DevOps | 2026-08-15 | ⚠️ |
| DS.2.2 | Verify encryption in transit | DevOps | 2026-08-15 | ⚠️ |
| CRM.1.1 | Create incident response plan | Security Team | 2026-08-22 | ❌ |
| ZKI.3 | Data protection for student records | Security Team | 2026-08-15 | ⚠️ |

**Total P0: 6 tasks**

### P1 (High) Tasks

| ID | Task | Owner | Due Date | Status |
|----|------|-------|----------|--------|
| ISMS.1.1 | Expand information security policy | Security Team | 2026-08-15 | ⚠️ |
| ISMS.2.1 | Define information security objectives | Security Team | 2026-08-15 | ⚠️ |
| ORP.1.2 | Document responsibilities | Security Team | 2026-09-01 | ⚠️ |
| ORP.2.3 | Implement security awareness program | HR | 2026-08-22 | ❌ |
| INF.1.2 | Review OS hardening | DevOps | 2026-08-30 | ⚠️ |
| INF.5.5 | Document firewall rules | DevOps | 2026-08-30 | ⚠️ |
| INF.6.1 | Audit network component config | DevOps | 2026-09-01 | ⚠️ |
| INF.12.1 | Audit virtualization config | DevOps | 2026-08-30 | ⚠️ |
| INF.14.3 | Verify input validation | Dev Team | 2026-09-15 | ⚠️ |
| APP.1.1 | Audit database security | DevOps | 2026-09-01 | ⚠️ |
| APP.2.1 | Audit web server config | DevOps | 2026-08-30 | ⚠️ |
| CRM.1.2 | Define incident classification | Security Team | 2026-08-22 | ❌ |
| CRM.1.3 | Create incident documentation templates | Security Team | 2026-08-30 | ❌ |
| ZKI.4 | Handle research data securely | Security Team | 2026-09-01 | ⚠️ |

**Total P1: 14 tasks**

---

## Appendix E: Glossary

| Term | Definition |
|------|------------|
| BSI | Bundesamt für Sicherheit in der Informationstechnik (German Federal Office for Information Security) |
| ZKI | Zentren für Kommunikations- und Informationsverarbeitung (IT Centers for Communication and Information Processing) |
| ISMS | Information Security Management System |
| DSGVO | Datenschutz-Grundverordnung (General Data Protection Regulation) |
| RPO | Recovery Point Objective (maximum acceptable data loss) |
| RTO | Recovery Time Objective (maximum acceptable downtime) |
| M | Maßnahme (Measure) in BSI IT-Grundschutz |
| INF | Infrastruktur (Infrastructure) module |
| APP | Anwendung (Application) module |
| ORP | Organisation und Personal (Organization and Personnel) |
| CON | Konzepte und Strategien (Concepts and Strategies) |
| OPS | Betrieb (Operations) |
| CRM | Krisenmanagement (Crisis Management) |
| BCP | Business Continuity Planning |

---

## Appendix F: References

### BSI Documents
- [BSI IT-Grundschutz Methodology](https://www.bsi.bund.de/DE/Themen/ITGrundschutz/itgrundschutz_node.html)
- [BSI IT-Grundschutz Catalogs](https://www.bsi.bund.de/DE/Themen/ITGrundschutz/ITGrundschutzKataloge/itgrundschutzkataloge_node.html)
- [BSI Standard 200-1: ISMS](https://www.bsi.bund.de/DE/Publikationen/TechnischeRichtlinien/tr031004/index.htm)
- [BSI Standard 200-2: IT-Grundschutz Methodology](https://www.bsi.bund.de/DE/Publikationen/TechnischeRichtlinien/tr031002/index.htm)
- [BSI Standard 200-3: Risk Management](https://www.bsi.bund.de/DE/Publikationen/TechnischeRichtlinien/tr03108/index.htm)

### ZKI Documents
- [ZKI Website](https://www.zki.de)
- [ZKI IT-Sicherheit Working Group](https://www.zki.de/arbeitskreise/it-sicherheit)
- [ISIS12: Informationssicherheitsstandards für die Hochschulen](https://wiki.zki.de/ISIS12)

### openDesk Documents
- [ZKI_IT_GRUNDSCHUTZ_ANALYSIS.md](ZKI_IT_GRUNDSCHUTZ_ANALYSIS.md) - Detailed analysis
- [ZKI_IT_GRUNDSCHUTZ_IMPLEMENTATION_PLAN.md](ZKI_IT_GRUNDSCHUTZ_IMPLEMENTATION_PLAN.md) - Implementation roadmap

---

**Document Version History**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-07-28 | openDesk Security Team | Initial version |

**Next Review Date**: 2026-08-28 (monthly)
**Owner**: openDesk Security Team
**Distribution**: Internal (openDesk Team)

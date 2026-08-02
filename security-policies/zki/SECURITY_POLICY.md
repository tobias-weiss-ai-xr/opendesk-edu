# openDesk IT Security Policy
# Aligned with ZKI IT-Grundschutz-Profil

# SPDX-FileCopyrightText: 2026 openDesk Contributors
# SPDX-License-Identifier: AGPL-3.0

---

## Document Control

| Field | Value |
|-------|-------|
| **Title** | openDesk IT Security Policy |
| **Version** | 1.0 |
| **Author** | openDesk Security Team |
| **Approver** | openDesk Management |
| **Date** | 2026-07-28 |
| **Effective Date** | 2026-08-01 |
| **Last Review** | - |
| **Next Review** | 2026-08-01 |
| **Classification** | Internal |

---

## 1. Purpose

This **Information Security Policy** establishes the framework for protecting **openDesk** information assets and ensuring compliance with:
- **BSI IT-Grundschutz** (Federal Office for Information Security)
- **ZKI IT-Grundschutz-Profil** (Higher Education adaptation)
- **ISO/IEC 27001:2022** (Information Security Management)
- **DSGVO / GDPR** (General Data Protection Regulation)
- **HDSG** (Hessian Data Protection Act)
- **University-specific requirements**

### 1.1 Scope

This policy applies to:
- All **openDesk platform** systems, services, and components
- All **users** (administrators, staff, students, external collaborators)
- All **data** processed, stored, or transmitted by openDesk
- All **third-party systems** connected to openDesk
- All **locations** where openDesk operates (HRZ Marburg, cloud, remote)

### 1.2 Objectives

The objectives of this policy are to:
1. ✅ **Protect** information assets from unauthorized access, disclosure, modification, or destruction
2. ✅ **Ensure** compliance with legal, regulatory, and contractual requirements
3. ✅ **Maintain** availability, integrity, and confidentiality of information
4. ✅ **Enable** secure collaboration and research
5. ✅ **Minimize** the impact of security incidents
6. ✅ **Continuously improve** security posture

---

## 2. Policy Framework

### 2.1 Security Principles

The following **security principles** guide all information security activities:

| Principle | Description | Implementation |
|-----------|-------------|----------------|
| **Least Privilege** | Users and systems have only the minimum access required | RBAC, access reviews |
| **Separation of Duties** | Critical functions are separated to prevent fraud | Role separation, dual control |
| **Defense in Depth** | Multiple layers of security controls | Network, host, application, data |
| **Security by Design** | Security is built into systems from the start | Secure development lifecycle |
| **Privacy by Default** | Data protection is the default setting | DSGVO-compliant defaults |
| **Need to Know** | Access to information is limited to those who need it | Access controls, encryption |
| **Continuous Improvement** | Security is continuously monitored and improved | Audits, reviews, updates |

### 2.2 Security Standards

This policy references the following standards:

| Standard | Description | Applicability |
|----------|-------------|---------------|
| **BSI IT-Grundschutz** | German federal IT security standard | All systems |
| **ZKI IT-Grundschutz-Profil** | Higher education adaptation | All systems |
| **ISO/IEC 27001** | International information security standard | All systems |
| **CIS Benchmarks** | Center for Internet Security benchmarks | All systems |
| **NIST SP 800-53** | US federal security controls | Reference only |
| **DSGVO/GDPR** | General Data Protection Regulation | All personal data |
| **HDSG** | Hessian Data Protection Act | All data in Hesse |

---

## 3. Security Organization

### 3.1 Roles and Responsibilities

#### 3.1.1 Chief Information Security Officer (CISO)

**Role**: Overall responsibility for information security
**Responsibilities**:
- Develop and maintain information security strategy
- Ensure compliance with this policy and applicable regulations
- Approve security policies, standards, and procedures
- Report security status to management and stakeholders
- Coordinate incident response
- Oversee security awareness program

**Current**: [To be assigned]

#### 3.1.2 Security Team

**Role**: Implement and maintain information security
**Responsibilities**:
- Implement and maintain security controls
- Monitor security events and incidents
- Conduct security assessments and audits
- Maintain security documentation
- Coordinate vulnerability management
- Provide security guidance to teams

**Current**: openDesk DevOps Team

#### 3.1.3 System Owners

**Role**: Responsible for specific systems or services
**Responsibilities**:
- Implement security controls for their systems
- Ensure compliance with this policy
- Report security incidents
- Coordinate with Security Team
- Maintain system documentation

#### 3.1.4 Data Owners

**Role**: Responsible for specific data sets
**Responsibilities**:
- Classify data according to sensitivity
- Define access control requirements
- Ensure proper handling of data
- Coordinate data protection measures
- Approve data sharing requests

#### 3.1.5 Users

**Role**: All individuals who access openDesk systems
**Responsibilities**:
- Comply with this policy and all security procedures
- Use strong, unique passwords
- Enable MFA when required
- Report security incidents or suspicious activity
- Complete security awareness training
- Use systems and data only for authorized purposes

### 3.2 Security Committees

#### 3.2.1 Information Security Steering Committee

**Purpose**: Strategic oversight of information security
**Members**:
- CISO (Chair)
- IT Director
- Legal Counsel
- Data Protection Officer
- HR Representative
- Faculty Representative

**Meeting Frequency**: Quarterly

#### 3.2.2 Security Working Group

**Purpose**: Operational implementation of security measures
**Members**:
- Security Team
- DevOps Team
- System Administrators
- Application Developers
- Network Engineers

**Meeting Frequency**: Bi-weekly

---

## 4. Access Control

### 4.1 Identity and Authentication

#### 4.1.1 Centralized Authentication

**Requirement**: All systems MUST use **Keycloak** for authentication
**Exceptions**: Service accounts with approved justifications
**Implementation**:
- OIDC (OpenID Connect) for web applications
- SAML 2.0 for enterprise applications
- LDAP for legacy systems (migrating to OIDC/SAML)

#### 4.1.2 Authentication Factors

| Level | Description | Requirements | Use Case |
|-------|-------------|-------------|----------|
| **Level 1** | Single factor | Password only | Public services, low-risk data |
| **Level 2** | Two factors | Password + TOTP | Administrative access, medium-risk data |
| **Level 3** | Two factors | Password + Hardware token | High-risk data, privileged access |
| **Level 4** | Three factors | Password + Hardware token + Biometric | Very high-risk data (optional) |

**Default**: Level 2 for all administrative accounts

#### 4.1.3 Password Policy

| Requirement | Value |
|-------------|-------|
| Minimum length | 12 characters |
| Maximum age | 90 days |
| Minimum age | 1 day |
| History | Last 10 passwords |
| Complexity | 3 of 4 character types (upper, lower, number, special) |
| Lockout threshold | 5 failed attempts |
| Lockout duration | 30 minutes |

**Exceptions**: Service accounts may use longer passwords (24+ characters) without expiration

#### 4.1.4 Multi-Factor Authentication (MFA)

**Requirement**: MFA MUST be enabled for:
- All administrative accounts
- All accounts with access to sensitive data
- All accounts with privileged access

**Recommended**: MFA for all user accounts

**Supported Methods**:
- TOTP (Time-based One-Time Passwords)
- Hardware tokens (YubiKey, etc.)
- WebAuthn / FIDO2

### 4.2 Authorization and Access Control

#### 4.2.1 Role-Based Access Control (RBAC)

**Requirement**: All access MUST be based on **roles**
**Implementation**:
- Pre-defined roles in Keycloak
- Role assignments based on job function
- Regular role reviews (quarterly)

#### 4.2.2 Least Privilege

**Requirement**: Users and systems MUST have only the minimum access required
**Implementation**:
- Default: No access
- Access granted based on role and need
- Regular access reviews (quarterly)
- Automatic provisioning/deprovisioning

#### 4.2.3 Access Review

**Frequency**: Quarterly
**Scope**: All user accounts and system access
**Process**:
1. Generate list of all active accounts
2. Review access rights for each account
3. Remove unnecessary access
4. Document review results
5. Escalate issues to management

#### 4.2.4 Privileged Access

**Requirement**: Privileged access MUST be:
- Approved by management
- Limited in time (temporary when possible)
- Monitored and logged
- Reviewed regularly

**Privileged Roles**:
- Kubernetes cluster-admin
- Database superusers
- System administrators
- Security administrators

### 4.3 Session Management

| Requirement | Value |
|-------------|-------|
| Session timeout (active) | 30 minutes |
| Session timeout (inactive) | 15 minutes |
| Maximum session duration | 8 hours |
| Concurrent sessions | Maximum 5 per user |
| Session fixations | Prevented |
| Session hijacking | Prevented via CSRF tokens, secure cookies |

---

## 5. Network Security

### 5.1 Network Architecture

#### 5.1.1 Network Segmentation

**Requirement**: Network MUST be segmented to limit lateral movement
**Implementation**:
- **Separate namespaces** in Kubernetes for different services
- **Network Policies** to control traffic between namespaces
- **Default-deny** for all cross-namespace traffic
- **Micro-segmentation** for sensitive services

#### 5.1.2 Network Zones

| Zone | Description | Security Level | Access |
|------|-------------|----------------|--------|
| **Internet** | External access | Low | Public |
| **DMZ** | Public-facing services | Medium | Restricted |
| **Internal** | Internal services | High | Internal only |
| **Database** | Database servers | Very High | Database clients only |
| **Management** | Management systems | Very High | Administrators only |

### 5.2 Firewall Rules

#### 5.2.1 Ingress Rules

- **Default**: Deny all incoming traffic
- **Allowed**: Only explicitly permitted traffic
- **HTTPS (443)**: Allowed to authorized services only
- **HTTP (80)**: Redirect to HTTPS
- **SSH (22)**: Restricted to management IP ranges
- **Other ports**: Case-by-case review

#### 5.2.2 Egress Rules

- **Default**: Deny all outgoing traffic (for sensitive services)
- **Allowed**: Only necessary outgoing traffic
- **DNS (53)**: Allowed to authorized DNS servers
- **HTTP/HTTPS (80/443)**: Allowed to internet (with proxy)
- **NTP (123)**: Allowed to time servers
- **SMTP (25/587)**: Allowed to authorized mail servers

### 5.3 Ingress Controllers

#### 5.3.1 HAProxy Ingress

**Security Configuration**:
- TLS 1.2+ only
- Strong cipher suites (AES256-GCM, CHACHA20-POLY1305)
- Perfect Forward Secrecy (PFS)
- OCSP Stapling
- HTTP Strict Transport Security (HSTS)
- Rate limiting
- IP reputation filtering (optional)

#### 5.3.2 Traefik Ingress

**Security Configuration**:
- TLS 1.2+ only
- Strong cipher suites
- Automatic certificate management (Let's Encrypt)
- Forward authentication (Keycloak)
- Rate limiting
- IP whitelisting (for sensitive services)

### 5.4 Network Monitoring

**Monitored Metrics**:
- Network traffic volume and patterns
- Connection attempts and failures
- Bandwidth usage
- Latency and performance
- Security events (IDS/IPS)

**Alerts**:
- Unusual traffic patterns
- Port scanning attempts
- DDoS attacks
- Unauthorized access attempts

---

## 6. System Security

### 6.1 Server Security

#### 6.1.1 Operating System Hardening

**Kubernetes Hosts**:
- Minimal operating system installation
- Only necessary services running
- Automatic security updates
- Disk encryption (LUKS)
- Firewall enabled (UFW/iptables)
- SSH hardened (disable root login, key-based auth only)
- Kernel parameters hardened (sysctl)

**Container Images**:
- Minimal base images (Alpine, Distroless)
- Only necessary packages installed
- Regular image updates
- Vulnerability scanning (Trivy)
- Image signing and verification (Cosign)

#### 6.1.2 Kubernetes Security

**Cluster Configuration**:
- **Pod Security Admission (PSA)**: Enforced
- **Network Policies**: Enforced
- **Role-Based Access Control (RBAC)**: Enforced
- **API Server**: Restricted access, audit logging
- **etcd**: Encrypted, restricted access
- **kubelet**: TLS bootstrapping, certificate rotation

**Pod Security**:
- **runAsNonRoot**: true (required)
- **readOnlyRootFilesystem**: true (when possible)
- **capabilities.drop**: ["ALL"] (required)
- **capabilities.add**: Only necessary capabilities
- **seccompProfile**: RuntimeDefault (required)
- **allowPrivilegeEscalation**: false (required)

### 6.2 Patch Management

#### 6.2.1 Patch Sources

| Component | Source | Frequency |
|-----------|--------|-----------|
| Kubernetes | Upstream releases | Quarterly |
| Container Images | Upstream maintainers | Rolling |
| Helm Charts | Upstream maintainers | Rolling |
| Operating System | Debian security | Automatic |
| Applications | Vendor releases | Rolling |

#### 6.2.2 Patch Process

1. **Monitor**: Subscribe to security mailing lists
2. **Assess**: Evaluate risk and urgency
3. **Test**: Test patches in staging environment
4. **Approve**: Obtain approval for production deployment
5. **Deploy**: Deploy patches to production
6. **Verify**: Verify patches are applied correctly
7. **Document**: Document patch deployment

#### 6.2.3 Patch SLAs

| Severity | SLA | Examples |
|----------|-----|----------|
| **Critical** | 24 hours | Remote code execution, privilege escalation |
| **High** | 72 hours | Information disclosure, DoS |
| **Medium** | 7 days | Non-critical vulnerabilities |
| **Low** | 30 days | Low-impact issues |

### 6.3 Logging and Monitoring

#### 6.3.1 Centralized Logging

**Implementation**: Loki + Promtail

**Log Sources**:
- Application logs (all services)
- System logs (Kubernetes nodes)
- Security logs (Keycloak, HAProxy, etc.)
- Audit logs (K3s, Ceph, etc.)

**Log Retention**:
- **Application logs**: 90 days
- **System logs**: 180 days
- **Security logs**: 7 years (BSI requirement)
- **Audit logs**: 7 years (BSI requirement)

#### 6.3.2 Monitoring

**Implementation**: Prometheus + Grafana + Alertmanager

**Monitored Systems**:
- Kubernetes cluster (nodes, pods, deployments)
- Services (health, performance, availability)
- Storage (Ceph, PVCs)
- Network (traffic, bandwidth, latency)
- Security (authentication, authorization, attacks)

**Alerts**:
- Service downtime
- High resource usage
- Authentication failures
- Unauthorized access attempts
- Security policy violations

#### 6.3.3 Audit Logging

**Audited Events**:
- Authentication attempts (success/failure)
- Authorization decisions
- Administrative actions
- Configuration changes
- Data access (sensitive data)
- System changes

**Audit Log Requirements**:
- Immutable (cannot be modified)
- Tamper-evident (detect modification attempts)
- Retained for 7 years
- Reviewed regularly

### 6.4 Vulnerability Management

#### 6.4.1 Vulnerability Scanning

**Implementation**: Trivy

**Scan Types**:
- **Container images**: On push, daily
- **Running containers**: Weekly
- **Host systems**: Monthly
- **Network**: Quarterly (with Suricata)

#### 6.4.2 Vulnerability Assessment

**Process**:
1. **Scan**: Run vulnerability scans
2. **Assess**: Evaluate risk (CVSS score, exploitability)
3. **Prioritize**: Category by severity (Critical, High, Medium, Low)
4. **Remediate**: Apply patches or mitigations
5. **Verify**: Verify vulnerabilities are fixed
6. **Report**: Document results and actions

#### 6.4.3 Vulnerability SLAs

| Severity | Assessment SLA | Remediation SLA |
|----------|-----------------|------------------|
| **Critical (9.0-10.0)** | 24 hours | 72 hours |
| **High (7.0-8.9)** | 48 hours | 7 days |
| **Medium (4.0-6.9)** | 72 hours | 30 days |
| **Low (0.1-3.9)** | 7 days | 90 days |

---

## 7. Data Protection

### 7.1 Data Classification

#### 7.1.1 Classification Levels

| Level | Description | Examples | Protection Requirements |
|-------|-------------|----------|-------------------------|
| **Public** | Information that can be freely shared | Public website content, press releases | None |
| **Internal** | Internal business information | Meeting minutes, internal policies | Basic |
| **Confidential** | Sensitive business information | Contracts, financial data | Enhanced |
| **Restricted** | Highly sensitive information | Student records, personnel data | High |
| **Top Secret** | Most sensitive information | Research data (classified), legal matters | Very High |

#### 7.1.2 Classification Process

1. **Identify**: Identify all data processed by openDesk
2. **Classify**: Assign classification level based on sensitivity
3. **Label**: Apply classification labels (metadata)
4. **Protect**: Apply appropriate protection measures
5. **Review**: Review classification regularly (annually)

#### 7.1.3 Classification Labels

**Implementation**: Metadata tags in Kubernetes and storage systems

**Labels**:
- `data-classification`: public/internal/confidential/restricted/top-secret
- `data-owner`: Team or individual responsible
- `data-retention`: Retention period
- `data-sensitivity`: Personal data, research data, etc.

### 7.2 Data Handling

#### 7.2.1 Data Storage

| Classification | Storage Location | Encryption | Backup |
|----------------|------------------|------------|--------|
| Public | Any | Optional | Optional |
| Internal | Internal storage | Yes | Yes |
| Confidential | Restricted storage | Yes | Yes |
| Restricted | Very restricted storage | Yes | Yes |
| Top Secret | Isolated storage | Yes | Yes |

**Encryption**:
- **At rest**: AES-256 (Ceph encryption)
- **In transit**: TLS 1.2+ (all communication)
- **Key management**: Kubernetes secrets, HashiCorp Vault (future)

#### 7.2.2 Data Transmission

**Requirements**:
- All data transmission MUST use encryption (TLS 1.2+)
- Sensitive data MUST use additional protections (mTLS, VPN)
- Email MUST use encryption (TLS, S/MIME, or PGP)
- File transfers MUST use secure protocols (HTTPS, SFTP, SCP)

#### 7.2.3 Data Access

**Requirements**:
- Access MUST be based on need-to-know
- Access MUST be logged (audit logging)
- Sensitive data MUST require explicit approval
- Remote access MUST use VPN or secure gateway

### 7.3 Data Retention and Disposal

#### 7.3.1 Retention Periods

| Data Type | Retention Period | Legal Basis |
|-----------|-----------------|-------------|
| Student records | 10 years | DSGVO, HDSG |
| Personnel data | 10 years after employment | DSGVO, HDSG |
| Financial data | 10 years | Tax law |
| Research data | As per research agreement | Varies |
| Logs (application) | 90 days | Internal policy |
| Logs (system) | 180 days | Internal policy |
| Logs (security/audit) | 7 years | BSI IT-Grundschutz |
| Backups | As per data type | - |

#### 7.3.2 Data Disposal

**Process**:
1. **Identify**: Identify data to be disposed
2. **Verify**: Verify retention period has expired
3. **Approve**: Obtain approval from data owner
4. **Delete**: Securely delete data
5. **Verify**: Verify deletion is complete
6. **Document**: Document disposal

**Secure Deletion Methods**:
- **Files**: Shredding (multiple passes)
- **Databases**: Secure deletion queries
- **Storage**: Cryptographic erasure (re-encrypt with new key)
- **Physical media**: Degaussing or physical destruction

### 7.4 Data Protection Impact Assessment (DPIA)

**Requirement**: DPIA MUST be conducted for:
- New systems processing personal data
- Changes to existing systems
- High-risk data processing activities

**Process**:
1. **Initiate**: Identify need for DPIA
2. **Describe**: Describe processing activity
3. **Assess**: Assess necessity and proportionality
4. **Identify**: Identify risks to data subjects
5. **Mitigate**: Define mitigation measures
6. **Approve**: Obtain approval from DPO
7. **Document**: Document DPIA results

---

## 8. Application Security

### 8.1 Secure Development

#### 8.1.1 Secure Development Lifecycle (SDL)

**Phases**:
1. **Requirements**: Security requirements defined
2. **Design**: Security architecture designed
3. **Implementation**: Secure coding practices
4. **Testing**: Security testing performed
5. **Deployment**: Secure deployment practices
6. **Maintenance**: Security updates applied

#### 8.1.2 Secure Coding Standards

**Requirements**:
- **Input validation**: All input MUST be validated and sanitized
- **Output validation**: All output MUST be validated and encoded
- **Error handling**: Errors MUST NOT reveal sensitive information
- **Logging**: Sensitive data MUST NOT be logged
- **Cryptography**: Use approved algorithms and libraries
- **Dependencies**: Use trusted, up-to-date libraries

#### 8.1.3 Security Testing

**Test Types**:
- **SAST (Static Application Security Testing)**: Code analysis
- **DAST (Dynamic Application Security Testing)**: Runtime analysis
- **Dependency scanning**: Vulnerability scanning of dependencies
- **Penetration testing**: Manual security testing

**Frequency**:
- **SAST**: On every commit
- **DAST**: On every deployment to staging
- **Dependency scanning**: Daily
- **Penetration testing**: Annually (or on major changes)

### 8.2 Web Application Security

#### 8.2.1 Security Headers

**Required Headers**:
```
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https:; style-src 'self' 'unsafe-inline' https:; img-src 'self' data: https:; font-src 'self' https:; connect-src 'self' https:; frame-src 'none'; object-src 'none'; base-uri 'self'; form-action 'self' https:;
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
```

#### 8.2.2 Common Vulnerabilities

**OWASP Top 10 Protection**:

| Vulnerability | Protection |
|---------------|------------|
| **Injection** | Input validation, prepared statements |
| **Broken Authentication** | Strong authentication, session management |
| **Sensitive Data Exposure** | Encryption, proper key management |
| **XML External Entities (XXE)** | Disable XXE processing |
| **Broken Access Control** | Proper authorization, least privilege |
| **Security Misconfiguration** | Hardened configurations, regular audits |
| **Cross-Site Scripting (XSS)** | Output encoding, CSP |
| **Insecure Deserialization** | Avoid deserialization, use safe libraries |
| **Using Components with Known Vulnerabilities** | Dependency scanning, updates |
| **Insufficient Logging & Monitoring** | Comprehensive logging, monitoring |

### 8.3 API Security

#### 8.3.1 Authentication

- **API Keys**: For machine-to-machine communication
- **OAuth 2.0**: For user-to-machine communication
- **JWT**: For stateless authentication
- **mTLS**: For service-to-service communication

#### 8.3.2 Authorization

- **OAuth 2.0 Scopes**: Fine-grained permissions
- **RBAC**: Role-based access control
- **ABAC**: Attribute-based access control (future)

#### 8.3.3 Rate Limiting

- **Default**: 100 requests per minute per client
- **Authenticated**: 1000 requests per minute per user
- **Sensitive APIs**: Custom limits based on risk

#### 8.3.4 Input Validation

- **Schema validation**: JSON Schema, OpenAPI
- **Type checking**: Strict type checking
- **Range checking**: Input range validation
- **Sanitization**: Input sanitization

---

## 9. Incident Management

### 9.1 Incident Classification

| Level | Description | Response Time | Examples |
|-------|-------------|---------------|----------|
| **Level 1 - Critical** | Severe impact, immediate action required | 15 minutes | System breach, data leak, DDoS attack |
| **Level 2 - High** | Significant impact, urgent action required | 1 hour | Unauthorized access, service outage |
| **Level 3 - Medium** | Moderate impact, action required | 4 hours | Security policy violation, suspicious activity |
| **Level 4 - Low** | Minimal impact, monitor and investigate | 24 hours | Minor security events |

### 9.2 Incident Response Process

#### 9.2.1 Preparation

- **Incident Response Plan**: Documented and approved
- **Incident Response Team**: Identified and trained
- **Communication Plan**: Defined (internal, external, authorities)
- **Tools**: Incident management system, communication tools

#### 9.2.2 Detection and Analysis

1. **Detect**: Identify potential security incident
2. **Triage**: Initial assessment of severity and validity
3. **Analyze**: Determine scope, impact, and root cause
4. **Classify**: Assign incident classification level

#### 9.2.3 Containment

1. **Short-term containment**: Immediate actions to stop the incident
2. **Long-term containment**: Actions to prevent recurrence
3. **Evidence preservation**: Collect and preserve evidence
4. **Documentation**: Document all containment actions

#### 9.2.4 Eradication

1. **Identify root cause**: Determine how the incident occurred
2. **Remove threat**: Eliminate the root cause
3. **Patch vulnerabilities**: Apply patches or fixes
4. **Verify eradication**: Confirm the threat is removed

#### 9.2.5 Recovery

1. **Restore services**: Bring systems back online
2. **Verify functionality**: Test systems for normal operation
3. **Monitor**: Increased monitoring for signs of recurrence
4. **Document**: Document recovery actions

#### 9.2.6 Lessons Learned

1. **Review**: Conduct post-incident review
2. **Identify improvements**: Identify process improvements
3. **Implement changes**: Update policies and procedures
4. **Train**: Train staff on lessons learned
5. **Report**: Report to stakeholders

### 9.3 Communication

#### 9.3.1 Internal Communication

- **Incident Team**: Real-time updates via Slack/email
- **Management**: Hourly updates during critical incidents
- **Staff**: Daily updates during ongoing incidents
- **All Users**: As needed (for user-facing impacts)

#### 9.3.2 External Communication

- **Authorities**: As required by law (DSGVO, etc.)
- **Affected Users**: As required (data breaches, etc.)
- **Public**: Only with management approval
- **Media**: Only via designated spokesperson

#### 9.3.3 Communication Templates

Templates are available for:
- Initial incident notification
- Incident status updates
- Incident resolution notification
- Data breach notification (DSGVO)
- Public statement

---

## 10. Business Continuity

### 10.1 Business Continuity Planning

**Objective**: Ensure continuity of critical services during disruptions

**Scope**: All critical openDesk services

### 10.2 Recovery Objectives

| Service | RPO (Recovery Point Objective) | RTO (Recovery Time Objective) | Priority |
|---------|--------------------------------|-------------------------------|----------|
| Authentication (Keycloak) | 15 minutes | 1 hour | Critical |
| Database (MariaDB) | 15 minutes | 1 hour | Critical |
| Storage (Ceph) | 1 hour | 4 hours | High |
| Kubernetes Control Plane | 15 minutes | 2 hours | Critical |
| Ingress Controllers | 5 minutes | 30 minutes | Critical |
| Monitoring (Prometheus) | 5 minutes | 30 minutes | High |
| Logging (Loki) | 5 minutes | 30 minutes | High |
| Application Services | 15 minutes | 2 hours | High |

### 10.3 Disaster Recovery

#### 10.3.1 Backup Strategy

| Data Type | Backup Frequency | Retention | Encryption |
|-----------|------------------|-----------|------------|
| Databases | Daily | 30 days | Yes |
| Storage | Daily | 30 days | Yes |
| Configurations | Daily | 90 days | Yes |
| Logs (security/audit) | Daily | 7 years | Yes |
| Full system | Weekly | 1 year | Yes |

**Implementation**: k8up with restic

#### 10.3.2 Recovery Process

1. **Declare disaster**: Management decision to declare disaster
2. **Activate DR team**: Assemble disaster recovery team
3. **Assess damage**: Determine scope of disaster
4. **Restore systems**: Restore from backups
5. **Verify functionality**: Test restored systems
6. **Resume operations**: Bring systems back online
7. **Document**: Document recovery actions

#### 10.3.3 Failover

**Automatic Failover**:
- Kubernetes pods: Automatic restart
- Load balancing: Automatic failover

**Manual Failover**:
- Kubernetes control plane: Manual failover
- Database: Manual failover (with replication)
- Storage: Manual failover (with replication)

### 10.4 Testing

**Test Types**:
- **Tabletop exercises**: Quarterly
- **Backups verification**: Monthly
- **Failover testing**: Semi-annually
- **Full DR testing**: Annually

---

## 11. Compliance

### 11.1 Compliance Framework

**Primary Standards**:
- **BSI IT-Grundschutz**: Baseline requirement
- **ZKI IT-Grundschutz-Profil**: University-specific adaptation
- **ISO/IEC 27001**: International standard (alignment)
- **DSGVO/GDPR**: Legal requirement
- **HDSG**: Legal requirement (Hesse)

### 11.2 Compliance Monitoring

**Monitoring Activities**:
- **Self-assessment**: Quarterly
- **Internal audit**: Annually
- **External audit**: Bi-annually (optional)
- **Certification**: Annual (BSI IT-Grundschutz, optional)

### 11.3 Compliance Reporting

**Reports**:
- **Security Status Report**: Monthly
- **Compliance Report**: Quarterly
- **Audit Report**: Annually
- **Incident Report**: As needed

**Recipients**:
- **Internal**: Management, Security Team
- **External**: Authorities (as required), stakeholders

---

## 12. Security Awareness

### 12.1 Awareness Program

**Objective**: Educate users about security threats and best practices

**Target Audience**: All users of openDesk

### 12.2 Training Requirements

| Role | Initial Training | Annual Training | Frequency |
|------|------------------|-----------------|-----------|
| **Employees** | Security fundamentals | Security refresher | Annually |
| **Administrators** | Advanced security | Security updates | Semi-annually |
| **Developers** | Secure coding | Security updates | Semi-annually |
| **All Users** | Security awareness | Security reminders | Monthly |

### 12.3 Training Methods

- **Online modules**: Self-paced learning
- **Workshops**: Instructor-led training
- **Webinars**: Live online training
- **Newsletters**: Monthly security updates
- **Posters**: Physical and digital reminders
- **Phishing simulations**: Quarterly

### 12.4 Training Content

**Topics**:
- Password security
- Multi-factor authentication
- Phishing awareness
- Social engineering
- Data protection (DSGVO)
- Safe internet usage
- Incident reporting
- Remote work security

---

## 13. Exceptions and Waivers

### 13.1 Exception Process

**Steps**:
1. **Request**: Submit exception request
2. **Assess**: Security Team assesses risk
3. **Approve**: CISO approves or denies
4. **Implement**: Implement compensating controls
5. **Review**: Regular review of exceptions
6. **Document**: Document exception details

### 13.2 Waiver Process

**Steps**:
1. **Request**: Submit waiver request
2. **Justify**: Provide business justification
3. **Assess**: Security Team assesses impact
4. **Approve**: Management approves or denies
5. **Implement**: Implement waiver with conditions
6. **Review**: Regular review of waivers
7. **Document**: Document waiver details

### 13.3 Exception/Waiver Register

All exceptions and waivers MUST be documented in a central register:
- **Requester**: Who requested the exception
- **Reason**: Business justification
- **Risk**: Assessed risk level
- **Controls**: Compensating controls
- **Approval**: Who approved and when
- **Expiration**: When the exception expires
- **Review**: Next review date

---

## 14. Policy Maintenance

### 14.1 Review and Update

**Review Frequency**: Annually
**Trigger Events**:
- Significant changes to systems or processes
- New legal or regulatory requirements
- Security incidents
- Audit findings
- Changes to business needs

**Process**:
1. **Initiate**: Identify need for review
2. **Assess**: Assess current policy effectiveness
3. **Update**: Revise policy as needed
4. **Approve**: Obtain approval
5. **Communicate**: Communicate changes
6. **Train**: Train staff on changes

### 14.2 Version Control

| Version | Date | Author | Changes | Approval |
|---------|------|--------|---------|----------|
| 1.0 | 2026-07-28 | openDesk Security Team | Initial version | Pending |

### 14.3 Document History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-07-28 | 1.0 | openDesk Security Team | Initial version created |

---

## 15. Related Documents

### 15.1 Policies

- [Acceptable Use Policy](ACCEPTABLE_USE_POLICY.md)
- [Data Classification Policy](DATA_CLASSIFICATION_POLICY.md)
- [Incident Response Policy](INCIDENT_RESPONSE_POLICY.md)
- [Business Continuity Policy](BUSINESS_CONTINUITY_POLICY.md)
- [Access Control Policy](ACCESS_CONTROL_POLICY.md)

### 15.2 Standards

- [Security Standards](SECURITY_STANDARDS.md)
- [Network Security Standards](NETWORK_SECURITY_STANDARDS.md)
- [Data Protection Standards](DATA_PROTECTION_STANDARDS.md)

### 15.3 Procedures

- [Incident Response Procedure](INCIDENT_RESPONSE_PROCEDURE.md)
- [Change Management Procedure](CHANGE_MANAGEMENT_PROCEDURE.md)
- [Vulnerability Management Procedure](VULNERABILITY_MANAGEMENT_PROCEDURE.md)
- [Access Review Procedure](ACCESS_REVIEW_PROCEDURE.md)

### 15.4 Guidelines

- [Secure Development Guidelines](SECURE_DEVELOPMENT_GUIDELINES.md)
- [User Security Guidelines](USER_SECURITY_GUIDELINES.md)
- [Administrator Security Guidelines](ADMINISTRATOR_SECURITY_GUIDELINES.md)

---

## 16. Definitions

| Term | Definition |
|------|------------|
| **Access Control** | Process of controlling who or what can view or use resources |
| **Asset** | Anything of value to the organization (information, systems, people) |
| **Authentication** | Process of verifying the identity of a user or system |
| **Authorization** | Process of granting or denying access to resources |
| **Confidentiality** | Ensuring information is accessible only to those authorized |
| **Integrity** | Ensuring information is accurate and complete |
| **Availability** | Ensuring information and systems are accessible when needed |
| **Risk** | Combination of the likelihood and impact of an event |
| **Threat** | Potential cause of an unwanted incident |
| **Vulnerability** | Weakness that can be exploited by a threat |
| **Incident** | Adverse event that threatens security |
| **Breach** | Confirmed incident that results in data compromise |
| **DSGVO/GDPR** | General Data Protection Regulation (EU) |
| **HDSG** | Hessian Data Protection Act (Germany) |
| **BSI** | Bundesamt für Sicherheit in der Informationstechnik (Federal Office for Information Security, Germany) |
| **ZKI** | Zentren für Kommunikations- und Informationsverarbeitung (IT Centers for Communication and Information Processing, Germany) |
| **ISMS** | Information Security Management System |
| **DPIA** | Data Protection Impact Assessment |
| **RPO** | Recovery Point Objective (maximum acceptable data loss) |
| **RTO** | Recovery Time Objective (maximum acceptable downtime) |

---

## 17. Contacts

| Role | Name | Email | Phone |
|------|------|-------|-------|
| **CISO** | [To be assigned] | ciso@opendesk.hrz.uni-marburg.de | [To be assigned] |
| **Security Team Lead** | [To be assigned] | security@opendesk.hrz.uni-marburg.de | [To be assigned] |
| **Incident Response** | openDesk Security Team | incident@opendesk.hrz.uni-marburg.de | +49-xxx-xxxx |
| **Data Protection Officer** | [To be assigned] | dpo@uni-marburg.de | [To be assigned] |

---

## 18. Approval

**Approved by**: __________________________
**Name**: [To be assigned]
**Title**: [To be assigned]
**Date**: __________________________

**Approved by**: __________________________
**Name**: [To be assigned]
**Title**: [To be assigned]
**Date**: __________________________

---

**Document Classification**: Internal
**Document Owner**: openDesk Security Team
**Distribution**: All openDesk staff, contractors, and users

*This policy is effective upon approval and supersedes all previous versions.*

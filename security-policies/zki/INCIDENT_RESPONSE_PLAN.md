# openDesk Incident Response Plan
# Aligned with BSI Standard 200-3 and ZKI IT-Grundschutz-Profil

# SPDX-FileCopyrightText: 2026 openDesk Contributors
# SPDX-License-Identifier: AGPL-3.0

---

## Document Control

| Field | Value |
|-------|-------|
| **Title** | openDesk Incident Response Plan |
| **Version** | 1.0 |
| **Author** | openDesk Security Team |
| **Approver** | openDesk CISO |
| **Date** | 2026-07-28 |
| **Effective Date** | 2026-08-01 |
| **Last Review** | - |
| **Next Review** | 2026-08-01 |
| **Classification** | Internal - Confidential |
| **Document ID** | openDesk-IRP-001 |

---

## 1. Purpose

This **Incident Response Plan (IRP)** establishes the framework for **detecting, responding to, and recovering** from security incidents that affect the **openDesk platform**. The plan ensures:

1. ✅ **Rapid detection** of security incidents
2. ✅ **Effective response** to contain and mitigate incidents
3. ✅ **Minimal impact** on operations and data
4. ✅ **Compliance** with BSI IT-Grundschutz and ZKI requirements
5. ✅ **Proper communication** with stakeholders
6. ✅ **Lessons learned** to improve security posture

### 1.1 Scope

This plan applies to:
- All **openDesk platform** services, systems, and components
- All **security incidents** affecting openDesk
- All **staff** involved in incident response
- All **locations** where openDesk operates

### 1.2 Objectives

| Objective | Description | Target |
|-----------|-------------|--------|
| **Detection Time** | Time to detect a security incident | <1 hour |
| **Response Time** | Time to respond to a detected incident | <30 minutes (P0/P1) |
| **Containment Time** | Time to contain an incident | <4 hours (P0/P1) |
| **Recovery Time** | Time to recover from an incident | <24 hours (P0/P1) |
| **Communication** | Stakeholders informed promptly | <1 hour (P0) |

---

## 2. Incident Classification

### 2.1 Classification Matrix

| **Level** | **Name** | **Description** | **Impact** | **Response Time** | **Escalation** |
|-----------|----------|-----------------|------------|-------------------|----------------|
| **0** | **Critical** | Severe impact, immediate action required | System-wide outage, data breach, active attack | 15 minutes | 24/7, immediate, all hands |
| **1** | **High** | Significant impact, urgent action required | Major service outage, unauthorized access, data modification | 1 hour | Business hours + on-call |
| **2** | **Medium** | Moderate impact, action required | Minor service disruption, security policy violation | 4 hours | Business hours |
| **3** | **Low** | Minimal impact, monitor and investigate | Suspicious activity, minor security events | 24 hours | Business hours |

### 2.2 Impact Categories

| **Category** | **Definition** | **Examples** |
|--------------|---------------|--------------|
| **Confidentiality** | Unauthorized access or disclosure of information | Data breach, information leak |
| **Integrity** | Unauthorized modification or destruction of information | Data tampering, sabotage |
| **Availability** | Disruption of service or system unavailability | DDoS,DoS, hardware failure |
| **Reputation** | Damage to organization's reputation | Public incident, negative press |
| **Legal/Compliance** | Violation of laws or regulations | DSGVO breach, contract violation |

### 2.3 Classification Examples

#### Level 0 - Critical Incidents
- **System breach**: Unauthorized access to production systems
- **Data breach**: Confirmed exposure of sensitive data (student records, personnel data)
- **Ransomware**: Active ransomware attack
- **DDoS attack**: Large-scale DDoS causing service outage
- **Insider threat**: Malicious insider activity
- **Supply chain attack**: Compromised third-party service
- **Zero-day exploitation**: Active exploitation of unknown vulnerability
- **Physical compromise**: Unauthorized physical access to data center

#### Level 1 - High Incidents
- **Unauthorized access**: Suspected access to sensitive systems or data
- **Service outage**: Major service unavailable for >1 hour
- **Phishing campaign**: Successful phishing attack affecting multiple users
- **Malware infection**: Malware detected on production systems
- **Data modification**: Unauthorized modification of non-critical data
- **Misconfiguration**: Security misconfiguration exposing services
- **Brute force attack**: Sustained brute force attack against authentication systems

#### Level 2 - Medium Incidents
- **Security policy violation**: Violation of security policies
- **Suspicious activity**: Unusual login attempts or access patterns
- **Service degradation**: Performance degradation due to security issue
- **Vulnerability scanning**: External vulnerability scan detected
- **Port scanning**: Network scanning activity detected
- **Social engineering**: Attempted social engineering attack
- **Lost device**: Lost or stolen device with access to openDesk

#### Level 3 - Low Incidents
- **Minor policy violation**: Minor violation of security policies
- **Low-risk vulnerability**: Non-exploitable vulnerability detected
- **Informational**: Security-related informational events
- **False positive**: Confirmed false positive security alert

---

## 3. Incident Response Team

### 3.1 Team Structure

#### 3.1.1 Incident Response Manager

**Role**: Overall coordination of incident response
**Responsibilities**:
- Coordinate incident response activities
- Make strategic decisions during incidents
- Escalate to management and stakeholders
- Ensure proper communication
- Conduct post-incident reviews

**Primary**: [To be assigned] - openDesk Security Team Lead
**Secondary**: [To be assigned] - openDesk CISO

#### 3.1.2 Incident Response Team (IRT)

**Core Members**:

| Role | Name | Contact | Responsibilities |
|------|------|---------|------------------|
| **Security Lead** | [To be assigned] | security@opendesk.hrz.uni-marburg.de | Technical lead, investigation, containment |
| **DevOps Lead** | [To be assigned] | devops@opendesk.hrz.uni-marburg.de | Infrastructure, Kubernetes, services |
| **Network Lead** | [To be assigned] | network@opendesk.hrz.uni-marburg.de | Network security, firewall, traffic |
| **Application Lead** | [To be assigned] | apps@opendesk.hrz.uni-marburg.de | Application security, web apps |
| **Data Lead** | [To be assigned] | data@opendesk.hrz.uni-marburg.de | Data protection, DSGVO compliance |
| **Communication Lead** | [To be assigned] | comms@opendesk.hrz.uni-marburg.de | Internal and external communication |

**Extended Members** (on-call):
- System Administrators
- Application Developers
- Database Administrators
- Storage Administrators
- Legal Counsel
- HR Representative
- Management

#### 3.1.3 On-Call Schedule

**Coverage**: 24/7/365
**Rotation**: Weekly
**Escalation**: Primary → Secondary → Tertiary → All

**On-Call Contacts**:
- **Primary**: [To be assigned] - +49-xxx-xxxx
- **Secondary**: [To be assigned] - +49-xxx-xxxx
- **Tertiary**: [To be assigned] - +49-xxx-xxxx

**Emergency Contact**: incident@opendesk.hrz.uni-marburg.de

### 3.2 Team Activation

#### 3.2.1 Activation Triggers

| Level | Activation | Notification Method | Required Personnel |
|-------|------------|---------------------|--------------------|
| **0 - Critical** | Immediate | Phone, SMS, Slack @all | All IRT members, on-call |
| **1 - High** | Immediate | Phone, Slack @IRT | Core IRT members, relevant domain experts |
| **2 - Medium** | Within 1 hour | Slack, Email | Incident Response Manager + relevant domain expert |
| **3 - Low** | Within 4 hours | Slack, Email | Incident Response Manager or delegate |

#### 3.2.2 Activation Process

1. **Detection**: Incident detected (automated or manual)
2. **Triage**: Initial assessment of severity and validity
3. **Classification**: Assign incident classification level
4. **Notification**: Notify required personnel per matrix above
5. **Acknowledgment**: Team members acknowledge notification
6. **Assembly**: Team assembles (virtual or physical war room)
7. **Briefing**: Incident Response Manager provides initial briefing

---

## 4. Incident Response Process

### 4.1 Phase 1: Preparation

**Objective**: Ensure readiness to respond to incidents

#### 4.1.1 Documentation

**Required Documents**:
- ✅ This Incident Response Plan (maintained)
- [ ] Contact list (IRT, management, stakeholders, authorities)
- [ ] Service inventory (all services, dependencies, owners)
- [ ] Network diagram (current architecture)
- [ ] Incident logging templates
- [ ] Communication templates (internal, external, authorities)
- [ ] Backup and recovery procedures
- [ ] Failover procedures

#### 4.1.2 Tools and Infrastructure

**Required Tools**:
- **Incident Management**: [To be selected] (e.g., Jira Service Management, PagerDuty)
- **Communication**: Slack (primary), Email, Phone
- **Collaboration**: Slack channels (#incident-response, #war-room)
- **Logging**: Loki, Prometheus, Grafana
- **Monitoring**: Prometheus, Alertmanager
- **Forensics**: Velociraptor, Autopsy (optional)
- **Backup**: k8up, restic
- **Documentation**: Git (this repository)

**Incident Response Infrastructure**:
- **War Room**: Physical or virtual meeting space
- **Dedicated Network**: Isolated network for incident response
- **Forensic Workstations**: Secure workstations for analysis
- **Secure Storage**: Encrypted storage for evidence
- **Backup Power**: UPS for critical systems

#### 4.1.3 Training and Exercises

**Training Requirements**:
- **All IRT members**: Annual incident response training
- **All staff**: Biennial security awareness training
- **New staff**: Incident response orientation

**Exercise Schedule**:
- **Tabletop exercises**: Quarterly
- **Technical exercises**: Bi-annually
- **Full-scale exercises**: Annually

### 4.2 Phase 2: Detection and Analysis

**Objective**: Identify and understand the incident

#### 4.2.1 Detection Sources

| Source | Description | Example |
|--------|-------------|---------|
| **Automated Alerts** | Security tools generate alerts | IDS, SIEM, WAF |
| **User Reports** | Users report suspicious activity | Phishing, unusual behavior |
| **Administrator Observations** | Admins notice unusual activity | Unusual logs, performance issues |
| **External Reports** | External parties report incidents | CERT, customers, partners |
| **Routine Monitoring** | Regular monitoring detects anomalies | Log review, vulnerability scans |

#### 4.2.2 Detection Process

```
1. Alert/Report Received
   ↓
2. Initial Triage
   ├── Is this a security incident?
   │   ├── Yes → Proceed to classification
   │   └── No → Close as false positive
   ↓
3. Assign Incident ID
   ↓
4. Classify Incident (Level 0-3)
   ↓
5. Log Initial Information
   └─ Incident type, source, time, impact, etc.
```

#### 4.2.3 Triage Questions

**Is this a security incident?**
- Does it involve unauthorized access, use, disclosure, disruption, modification, or destruction of data or systems?
- Does it violate security policies?
- Does it have the potential to cause harm?

**What is the impact?**
- Which systems or services are affected?
- What data is at risk?
- How many users are affected?
- What is the potential business impact?

**What is the urgency?**
- Is the incident ongoing?
- Is the impact increasing?
- Is there a risk of data loss or breach?

#### 4.2.4 Initial Actions

1. **Preserve Evidence**: Do not modify systems or data
2. **Isolate if Necessary**: Only if required to prevent further damage
3. **Document**: Record all observations and actions
4. **Notify**: Inform Incident Response Manager
5. **Escalate**: If beyond your authority or expertise

### 4.3 Phase 3: Containment

**Objective**: Prevent the incident from causing further damage

#### 4.3.1 Containment Strategy

**Short-Term Containment**: Immediate actions to stop the incident
**Long-Term Containment**: Actions to prevent recurrence

| Incident Type | Short-Term Containment | Long-Term Containment |
|---------------|------------------------|-----------------------|
| **Unauthorized Access** | Disconnect affected systems, revoke access | Implement additional access controls, review permissions |
| **Malware** | Isolate infected systems, block malicious IPs | Remove malware, patch vulnerabilities, enhance detection |
| **DDoS** | Rate limiting, traffic filtering, engage ISP | Implement DDoS protection, scale infrastructure |
| **Data Breach** | Revoke access, change credentials | Implement additional monitoring, encrypt data |
| **Phishing** | Block malicious emails, remove from inboxes | Implement email filtering, train users |
| **Insider Threat** | Suspend access, monitor activity | Review access controls, implement user behavior analytics |

#### 4.3.2 Containment Actions

**Network Containment**:
- Block malicious IPs or domains
- Isolate affected network segments
- Disable affected services
- Implement additional firewall rules

**System Containment**:
- Disconnect affected systems from network
- Shut down affected systems
- Take snapshots for forensic analysis
- Revoke compromised credentials

**Application Containment**:
- Disable affected application features
- Roll back to previous version
- Implement additional access controls
- Rate limit or throttle requests

**Data Containment**:
- Revoke access to affected data
- Encrypt affected data
- Copy data to secure location
- Delete compromised data (if appropriate)

#### 4.3.3 Containment Checklist

- [ ] Incident containment strategy approved
- [ ] Short-term containment actions implemented
- [ ] Long-term containment plan developed
- [ ] Evidence preserved (snapshots, logs, memory dumps)
- [ ] Impact minimized
- [ ] Communication sent to stakeholders
- [ ] Containment actions documented

### 4.4 Phase 4: Eradication

**Objective**: Remove the root cause of the incident

#### 4.4.1 Investigation

**Goal**: Identify the root cause of the incident

**Investigation Process**:
1. **Collect Evidence**: Gather all relevant data and logs
2. **Analyze Evidence**: Identify attack vectors and methods
3. **Identify Root Cause**: Determine how the incident occurred
4. **Document Findings**: Record investigation results

**Evidence Types**:
- **Logs**: System, application, security, audit logs
- **Network Traffic**: PCAP files, netflow data
- **System State**: Memory dumps, disk images, running processes
- **User Activity**: Authentication logs, access logs, command history
- **Malware**: Binary samples, hashes, analysis reports

**Forensic Guidelines**:
- **Preserve Chain of Custody**: Document who handled evidence and when
- **Do Not Modify**: Never modify original evidence
- **Use Write Blockers**: When working with disk images
- **Document Everything**: Record all actions and observations
- **Work on Copies**: Always work on copies of evidence

#### 4.4.2 Root Cause Analysis

**Methods**:
- **5 Whys**: Ask "why" repeatedly to find root cause
- **Fishbone Diagram**: Visualize potential causes
- **Timeline Analysis**: Map events to identify patterns
- **Hypothesis Testing**: Test potential causes

**Root Cause Categories**:
- **Technical**: Vulnerabilities, misconfigurations, software bugs
- **Human**: User error, lack of training, social engineering
- **Process**: Missing or inadequate processes, lack of oversight
- **External**: Third-party breaches, supply chain attacks

#### 4.4.3 Eradication Actions

**Remove the Threat**:
- Remove malware from infected systems
- Revoke compromised credentials
- Patch vulnerable systems
- Close open ports or services
- Remove backdoors or malicious code

**Fix Vulnerabilities**:
- Apply security patches
- Update configurations
- Implement additional controls
- Harden systems

**Verify Eradication**:
- Confirm removal of all malware
- Verify no backdoors remain
- Test patches and updates
- Confirm systems are secure

#### 4.4.4 Eradication Checklist

- [ ] Root cause identified
- [ ] Evidence collected and preserved
- [ ] Threat removed from all affected systems
- [ ] Vulnerabilities patched or mitigated
- [ ] Systems verified to be secure
- [ ] Eradication actions documented

### 4.5 Phase 5: Recovery

**Objective**: Restore normal operations

#### 4.5.1 Recovery Strategy

**Priorities**:
1. **Critical Systems**: Authentication, database, storage
2. **High-Importance Systems**: Core services, user-facing applications
3. **Medium-Importance Systems**: Supporting services, internal tools
4. **Low-Importance Systems**: Non-critical services

**Recovery Methods**:
- **Restore from Backup**: For data loss or corruption
- **Roll Back**: For failed changes or updates
- **Fail Over**: For system or hardware failure
- **Rebuild**: For compromised systems

#### 4.5.2 Recovery Process

1. **Plan**: Develop detailed recovery plan
2. **Test**: Test recovery procedures in staging
3. **Execute**: Implement recovery actions
4. **Verify**: Test recovered systems for normal operation
5. **Monitor**: Enhanced monitoring for signs of recurrence

#### 4.5.3 Recovery Actions

**System Recovery**:
- Restore from clean backups
- Rebuild compromised systems
- Reconfigure systems with secure settings
- Reconnect to network

**Service Recovery**:
- Restart services with secure configurations
- Verify service functionality
- Test integrations
- Monitor service health

**Data Recovery**:
- Restore from backups
- Verify data integrity
- Reapply any lost changes
- Monitor for data corruption

#### 4.5.4 Recovery Checklist

- [ ] Recovery plan developed and approved
- [ ] Recovery procedures tested
- [ ] Systems restored from clean sources
- [ ] Data integrity verified
- [ ] Services tested and verified
- [ ] Enhanced monitoring implemented
- [ ] Recovery actions documented

### 4.6 Phase 6: Lessons Learned

**Objective**: Improve security posture based on incident experience

#### 4.6.1 Post-Incident Review

**Timing**: Within 5 business days of incident resolution
**Participants**: IRT, stakeholders, management
**Duration**: 1-2 hours

**Review Agenda**:
1. **Incident Overview**: Summary of incident
2. **Timeline**: Detailed timeline of events
3. **Root Cause**: Analysis of root cause
4. **Response**: Review of response actions
5. **Impact**: Assessment of impact
6. **Lessons Learned**: Identify improvements
7. **Action Items**: Define follow-up actions

#### 4.6.2 Lessons Learned Document

**Template**:
```markdown
## Post-Incident Review: [Incident ID]

### 1. Incident Overview
- **Incident ID**: 
- **Classification**: 
- **Date/Time**: 
- **Duration**: 

### 2. Timeline
| Time | Event | Owner | Notes |
|------|-------|-------|-------|

### 3. Root Cause
- **Primary Cause**: 
- **Secondary Causes**: 
- **Contributing Factors**: 

### 4. Impact Assessment
- **Systems Affected**: 
- **Data Affected**: 
- **Users Affected**: 
- **Business Impact**: 
- **Financial Impact**: 
- **Reputation Impact**: 

### 5. Response Review
- **What went well**: 
- **What could be improved**: 
- **Response time**: 
- **Effectiveness**: 

### 6. Lessons Learned
- **Technical**: 
- **Process**: 
- **People**: 
- **Tools**: 

### 7. Action Items
| ID | Action | Owner | Priority | Due Date | Status |
|----|--------|-------|----------|----------|--------|

### 8. Follow-Up
- **Next Review**: 
- **Owner**: 
```

#### 4.6.3 Action Items

**Prioritization**:
- **P0**: Immediate action required (within 24 hours)
- **P1**: High priority (within 1 week)
- **P2**: Medium priority (within 1 month)
- **P3**: Low priority (within 3 months)

**Tracking**:
- **Incident Management System**: Primary tracking
- **Project Management Tool**: Jira, GitHub, etc.
- **Status Updates**: Weekly until completion

---

## 5. Communication Plan

### 5.1 Communication Timeline

| Time | Action | Audience | Method |
|------|--------|----------|--------|
| **Detection** | Initial notification | IRT | Slack, Phone, SMS |
| **Classification** | Incident classification | IRT | Slack, War Room |
| **+15 min (P0)** | Initial briefing | IRT, Management | War Room |
| **+30 min (P0)** | Stakeholder notification | Stakeholders | Email, Phone |
| **+1 hour (P0)** |Internal communication | All staff | Email, Slack |
| **+2 hours (P0)** | External communication (if needed) | Users, partners | Email, Website |
| **+4 hours (P0)** | Authority notification (if needed) | Authorities | Email, Phone |
| **Ongoing** | Regular updates | All audiences | Email, Slack |
| **Resolution** | Final report | All audiences | Email, Meeting |

### 5.2 Communication Channels

| Channel | Purpose | Audience | Frequency |
|---------|---------|----------|-----------|
| **#incident-response** | Real-time incident discussion | IRT | Continuous |
| **#war-room** | Dedicated incident response | IRT | As needed |
| **Email** | Formal notifications | All audiences | As needed |
| **Phone/SMS** | Urgent notifications | IRT, Management | As needed |
| **Slack @all** | Broadcast notifications | All staff | As needed |
| **Status Page** | Service status updates | Users, public | As needed |
| **Website** | Public statements | Public | As needed |

### 5.3 Communication Templates

#### 5.3.1 Internal Notification (IRT)

```
Subject: SECURITY INCIDENT - [Incident ID] - [Classification]

INCIDENT ALERT
- Incident ID: [ID]
- Classification: [Level]
- Detected: [Time]
- Source: [Source]
- Description: [Brief description]

IMMEDIATE ACTIONS:
- [Action 1]
- [Action 2]
- [Action 3]

NEXT STEPS:
- [Next step 1]
- [Next step 2]

War Room: [Link]
Contact: [Name] - [Phone]
```

#### 5.3.2 Management Notification

```
Subject: URGENT: Security Incident - [Incident ID] - [Classification]

Dear [Management],

A security incident has been detected and is currently being investigated.

INCIDENT DETAILS:
- Incident ID: [ID]
- Classification: [Level]
- Detected: [Time]
- Affected Systems: [Systems]
- Potential Impact: [Impact]

RESPONSE:
- Incident Response Team has been activated
- Containment actions are underway
- Investigation is in progress

NEXT STEPS:
- Regular updates will be provided
- A full report will be available upon resolution

Please contact [Name] at [Phone] for any questions.

Best regards,
[Your Name]
Incident Response Manager
```

#### 5.3.3 User Notification (Service Outage)

```
Subject: Service Outage - [Service Name]

Dear Users,

We are currently experiencing a service outage affecting [Service Name].

DETAILS:
- Service: [Service Name]
- Start Time: [Time]
- Expected Resolution: [Time]
- Impact: [Description]

All affected users will be notified once the service is restored.

We apologize for any inconvenience and appreciate your patience.

For updates, please visit our status page: [Link]

Best regards,
openDesk Team
```

#### 5.3.4 User Notification (Data Breach) - DSGVO

```
Subject: Important: Security Incident Affecting Your Data

Dear [User],

We are writing to inform you of a security incident that may have affected your personal data.

INCIDENT DETAILS:
- Date: [Date]
- Description: [Brief description]
- Data Affected: [Types of data]
- Potential Impact: [Description]

PROTECTIVE MEASURES:
- We have taken immediate action to contain the incident
- We are conducting a thorough investigation
- We are implementing additional security measures

RECOMMENDED ACTIONS:
- [Action 1, if any]
- [Action 2, if any]

SUPPORT:
If you have any questions or concerns, please contact us at:
- Email: [Email]
- Phone: [Phone]
- Website: [Link]

We take this incident very seriously and are committed to protecting your data.
We will provide updates as our investigation progresses.

Sincerely,
[Name]
Data Protection Officer
openDesk
```

#### 5.3.5 Authority Notification (DSGVO)

```
Subject: Data Breach Notification - Art. 33 DSGVO

To: [Authority Name]

NOTIFICATION OF PERSONAL DATA BREACH
(Article 33 of Regulation (EU) 2016/679)

1. Details of the Data Protection Officer
   - Name: [Name]
   - Email: [Email]
   - Phone: [Phone]

2. Description of the Personal Data Breach
   - Date and time of breach: [Date/Time]
   - Date and time of detection: [Date/Time]
   - Description of breach: [Description]
   - Categories of data subjects: [Categories]
   - Approximate number of data subjects: [Number]
   - Categories of personal data: [Categories]
   - Approximate number of personal data records: [Number]

3. Details of the Data Protection Officer
   - Name: [Name]
   - Contact: [Contact]

4. Description of the Likely Consequences
   - [Description]

5. Description of the Measures Proposed or Taken
   - Containment measures: [List]
   - Mitigation measures: [List]
   - Preventive measures: [List]

6. Additional Information
   - [Any additional relevant information]

Please contact us if you require any further information.

Sincerely,
[Name]
Data Protection Officer
openDesk
```

#### 5.3.6 Public Statement

```
Security Incident Notice

[Date]

openDesk is aware of a security incident affecting [Service/Component].

We detected this incident on [Date] and immediately activated our incident response team.
We are working diligently to investigate, contain, and resolve the issue.

At this time, we have no evidence that [specific data] was accessed or compromised.
We will provide updates as more information becomes available.

No action is required on the part of users at this time.

For questions, please contact: [Email]

We appreciate your patience and understanding.

[Name]
Spokesperson
openDesk
```

### 5.4 Escalation Matrix

| Situation | Escalate To | Method | Timeline |
|-----------|-------------|--------|----------|
| **P0 Incident detected** | All IRT members, On-call | Phone, SMS, Slack @all | Immediate |
| **P0 Incident confirmed** | Incident Response Manager | Phone | Immediate |
| **P0 Impact assessment** | Management | Phone, Email | Within 15 min |
| **P0 Stakeholder notification** | Stakeholders | Email, Phone | Within 30 min |
| **P0 Authority notification** | Authorities | Email, Phone | Within 72 hours (DSGVO) |
| **P1 Incident detected** | Core IRT members | Slack @IRT, Email | Immediate |
| **P1 Incident confirmed** | Incident Response Manager | Slack, Email | Within 1 hour |
| **P1 Management notification** | Management | Email | Within 2 hours |
| **P2 Incident detected** | Incident Response Manager | Slack, Email | Within 4 hours |
| **P3 Incident detected** | Delegate | Slack, Email | Within 24 hours |
| **Incident resolution** | All stakeholders | Email, Meeting | Within 24 hours |

---

## 6. Incident Documentation

### 6.1 Incident Record

**Template**:
```markdown
## Incident Record: [Incident ID]

### 1. Incident Details
- **Incident ID**: [ID]
- **Classification**: [Level 0-3]
- **Title**: [Brief description]
- **Status**: [Open/In Progress/Resolved/Closed]
- **Priority**: [P0-P3]

### 2. Timeline
| Date/Time | Event | Owner | Notes |
|-----------|-------|-------|-------|
| | | | |

### 3. Detection
- **Detected by**: [Name/Team/System]
- **Detection method**: [Automated/Manual]
- **Initial report**: [Description]
- **First response**: [Actions taken]

### 4. Classification
- **Primary category**: [Confidentiality/Integrity/Availability/Other]
- **Secondary categories**: [List]
- **Impact**: [Description]
- **Scope**: [Description]

### 5. Response
- **Incident Response Manager**: [Name]
- **Team Members**: [List]
- **War Room**: [Link]
- **Actions Taken**: [List]

### 6. Containment
- **Strategy**: [Short-term/Long-term]
- **Actions**: [List]
- **Effectiveness**: [Description]

### 7. Investigation
- **Root Cause**: [Description]
- **Attack Vector**: [Description]
- **Evidence Collected**: [List]
- **Forensic Analysis**: [Description]

### 8. Eradication
- **Actions Taken**: [List]
- **Verification**: [Description]
- **Effectiveness**: [Description]

### 9. Recovery
- **Actions Taken**: [List]
- **Verification**: [Description]
- **Monitoring**: [Description]

### 10. Impact Assessment
- **Systems Affected**: [List]
- **Data Affected**: [List]
- **Users Affected**: [Number]
- **Downtime**: [Duration]
- **Financial Impact**: [Estimate]
- **Reputation Impact**: [Description]

### 11. Communication
- **Internal**: [List]
- **External**: [List]
- **Authorities**: [List]

### 12. Lessons Learned
- **What went well**: [List]
- **What could be improved**: [List]
- **Action Items**: [List]

### 13. Closure
- **Resolution Date**: [Date]
- **Closed by**: [Name]
- **Closure Notes**: [Description]
```

### 6.2 Evidence Collection

**Evidence Types and Collection Methods**:

| Evidence Type | Collection Method | Storage Location | Retention |
|---------------|-------------------|------------------|-----------|
| **Logs** | Export from logging systems | Secure storage | 7 years |
| **Network Traffic** | PCAP capture | Secure storage | 1 year |
| **Memory Dumps** | Forensic tools (Volatility) | Secure storage | 1 year |
| **Disk Images** | Forensic imaging (dd, FTK) | Secure storage | 1 year |
| **Screenshots** | Manual capture | Secure storage | 1 year |
| **Configuration Files** | Export from systems | Secure storage | 1 year |
| **Malware Samples** | Safe capture (password-protected ZIP) | Secure storage | 1 year |
| **Interview Notes** | Manual documentation | Secure storage | 7 years |
| **Emails** | Export from email system | Secure storage | 7 years |

**Evidence Handling**:
- **Chain of Custody**: Document who handled evidence and when
- **Integrity**: Use hashes to verify evidence integrity
- **Secure Storage**: Encrypt all evidence at rest
- **Access Control**: Limit access to evidence to authorized personnel only

### 6.3 Reporting

**Report Types**:

| Report | Audience | Frequency | Template |
|--------|----------|-----------|---------|
| **Initial Incident Report** | IRT, Management | Upon detection | [Template] |
| **Status Update** | Stakeholders | Regular (daily for P0) | [Template] |
| **Final Incident Report** | All stakeholders | Upon resolution | [Template] |
| **Lessons Learned Report** | Management | Within 5 days of resolution | [Template] |
| **Compliance Report** | Authorities | As required | [Template] |

---

## 7. Tools and Resources

### 7.1 Incident Response Tools

| Tool | Purpose | Access | Notes |
|------|---------|--------|-------|
| **Slack** | Real-time communication | IRT | #incident-response, #war-room |
| **Email** | Formal communication | All | incident@opendesk.hrz.uni-marburg.de |
| **Phone/SMS** | Urgent communication | IRT, On-call | [Numbers] |
| **Loki + Grafana** | Logging and visualization | IRT | For investigation |
| **Prometheus + Alertmanager** | Monitoring and alerting | IRT | For detection |
| **k8up + restic** | Backup and recovery | DevOps | For recovery |
| **Velociraptor** | Endpoint detection and response | Security Team | For investigation |
| **Autopsy** | Digital forensics | Security Team | For analysis |
| **Trivy** | Vulnerability scanning | DevOps | For assessment |
| **Jira/Service Desk** | Incident tracking | IRT | For documentation |
| **Git** | Documentation | All | For version control |

### 7.2 Contact Information

**Internal Contacts**:

| Role | Name | Email | Phone | Notes |
|------|------|-------|-------|-------|
| **Incident Response Manager** | [Name] | irt@opendesk.hrz.uni-marburg.de | +49-xxx-xxxx | Primary |
| **CISO** | [Name] | ciso@opendesk.hrz.uni-marburg.de | +49-xxx-xxxx | Secondary |
| **Security Team Lead** | [Name] | security@opendesk.hrz.uni-marburg.de | +49-xxx-xxxx | Tertiary |
| **DevOps Lead** | [Name] | devops@opendesk.hrz.uni-marburg.de | +49-xxx-xxxx | |
| **Network Lead** | [Name] | network@opendesk.hrz.uni-marburg.de | +49-xxx-xxxx | |
| **DataProtection Officer** | [Name] | dpo@uni-marburg.de | +49-xxx-xxxx | External |

**External Contacts**:

| Organization | Contact | Email | Phone | Notes |
|--------------|---------|-------|-------|-------|
| **DFN-CERT** | [Name] | cert@dfn.de | +49-40-808077-555 | German Research Network CERT |
| **BSI** | [Name] | info@bsi.bund.de | +49-228-999582-0 | Federal Office for Information Security |
| **Hessian Data Protection Authority** | [Name] | poststelle@datenschutz.hessen.de | +49-611-848480 | HDSG |
| **Police** | [Local] | [Email] | 110 | Emergency |
| **HRZ Marburg** | [Name] | support@hrz.uni-marburg.de | +49-6421-2820 | Hosting provider |

---

## 8. Training and Exercises

### 8.1 Training Requirements

| Role | Training | Frequency | Format |
|------|----------|-----------|--------|
| **IRT Members** | Incident Response Training | Annual | Workshop, Online |
| **All Staff** | Security Awareness Training | Annual | Online |
| **New Staff** | Incident Response Orientation | Onboarding | Workshop |
| **Management** | Incident Response Briefing | Annual | Meeting |

**Training Topics**:
- Incident response process and procedures
- Incident classification and prioritization
- Detection and analysis techniques
- Containment and eradication strategies
- Communication and documentation
- Tools and resources
- Legal and compliance requirements

### 8.2 Exercise Schedule

| Exercise Type | Frequency | Duration | Participants | Goals |
|---------------|-----------|----------|--------------|-------|
| **Tabletop Exercise** | Quarterly | 1-2 hours | IRT, Management | Test plans, improve communication |
| **Technical Exercise** | Bi-annually | 2-4 hours | IRT, DevOps | Test technical response |
| **Full-Scale Exercise** | Annually | 4-8 hours | All staff | Test end-to-end response |

### 8.3 Exercise Scenarios

| Scenario | Description | Goals |
|----------|-------------|-------|
| **Data Breach** | Simulated data breach scenario | Test breach response, communication |
| **Ransomware Attack** | Simulated ransomware scenario | Test containment, recovery, negotiation |
| **DDoS Attack** | Simulated DDoS scenario | Test mitigation, communication |
| **Unauthorized Access** | Simulated insider threat scenario | Test detection, investigation |
| **Supply Chain Attack** | Simulated third-party breach scenario | Test response, vendor management |
| **Physical Security Incident** | Simulated physical security breach | Test physical response, access control |

---

## 9. Continuous Improvement

### 9.1 Plan Review

**Review Frequency**: Annually
**Review Triggers**:
- Significant security incidents
- Major changes to infrastructure or systems
- New legal or regulatory requirements
- Changes to business needs or risk profile
- Lessons learned from incidents or exercises

**Review Process**:
1. **Assess**: Evaluate current plan effectiveness
2. **Identify**: Identify areas for improvement
3. **Develop**: Develop updates and enhancements
4. **Approve**: Obtain approval for changes
5. **Implement**: Roll out updates
6. **Train**: Train staff on changes

### 9.2 Metrics

**Incident Response Metrics**:

| Metric | Definition | Target | Measurement |
|--------|------------|--------|-------------|
| **Mean Time to Detect (MTTD)** | Average time to detect incidents | <1 hour | Automated |
| **Mean Time to Respond (MTTR)** | Average time to respond to incidents | <30 min (P0/P1) | Automated |
| **Mean Time to Contain (MTTC)** | Average time to contain incidents | <4 hours (P0/P1) | Manual |
| **Mean Time to Resolve (MTTR)** | Average time to resolve incidents | <24 hours (P0/P1) | Manual |
| **Incident Count** | Number of incidents per period | <5/year (P0) | Manual |
| **False Positive Rate** | Percentage of false positive alerts | <10% | Automated |
| **Lessons Learned Count** | Number of improvements implemented | >80% of action items | Manual |

### 9.3 Feedback

**Feedback Sources**:
- IRT members
- Stakeholders
- Users
- Management
- External auditors
- Lessons learned from incidents

**Feedback Process**:
1. **Collect**: Gather feedback from various sources
2. **Analyze**: Identify common themes and issues
3. **Prioritize**: Rank feedback by importance and impact
4. **Implement**: Make improvements based on feedback
5. **Communicate**: Inform stakeholders of changes

---

## 10. Appendices

### Appendix A: Glossary

| Term | Definition |
|------|------------|
| **BSI** | Bundesamt für Sicherheit in der Informationstechnik (German Federal Office for Information Security) |
| **DFN-CERT** | Computer Emergency Response Team for the German Research Network |
| **DSGVO/GDPR** | Datenschutz-Grundverordnung/General Data Protection Regulation |
| **HDSG** | Hessisches Datenschutzgesetz (Hessian Data Protection Act) |
| **HSTS** | HTTP Strict Transport Security |
| **IDS** | Intrusion Detection System |
| **IPS** | Intrusion Prevention System |
| **IRP** | Incident Response Plan |
| **IRT** | Incident Response Team |
| **mTLS** | Mutual TLS (two-way TLS authentication) |
| **MFA** | Multi-Factor Authentication |
| **PCAP** | Packet Capture |
| **RPO** | Recovery Point Objective |
| **RTO** | Recovery Time Objective |
| **SLA** | Service Level Agreement |
| **TLS** | Transport Layer Security |
| **WAF** | Web Application Firewall |
| **ZKI** | Zentren für Kommunikations- und Informationsverarbeitung (IT Centers for Communication and Information Processing) |

### Appendix B: References

**Internal Documents**:
- [openDesk IT Security Policy](SECURITY_POLICY.md)
- [ZKI IT-Grundschutz-Profil Implementation Plan](../ZKI_IT_GRUNDSCHUTZ_IMPLEMENTATION_PLAN.md)
- [ZKI IT-Grundschutz-Profil Analysis](../ZKI_IT_GRUNDSCHUTZ_ANALYSIS.md)

**External References**:
- [BSI Standard 200-3: Risk Management](https://www.bsi.bund.de/DE/Publikationen/TechnischeRichtlinien/tr03108/index.htm)
- [BSI IT-Grundschutz Catalogs](https://www.bsi.bund.de/DE/Themen/ITGrundschutz/ITGrundschutzKataloge/itgrundschutzkataloge_node.html)
- [ZKI IT-Sicherheit Working Group](https://www.zki.de/arbeitskreise/it-sicherheit)
- [NIST SP 800-61: Computer Security Incident Handling Guide](https://csrc.nist.gov/publications/detail/sp/800-61/rev-2/final)
- [ISO/IEC 27035: Information Security Incident Management](https://www.iso.org/standard/54503.html)
- [DSGVO/GDPR: General Data Protection Regulation](https://dsgvo-gesetz.de/)
- [HDSG: Hessian Data Protection Act](https://www.hmdj.hessen.de/sites/default/files/media/hmdj/inhalt_dateien/datenschutz/hdsg_stand_10.06.2019.pdf)

### Appendix C: Incident ID Format

**Format**: `openDesk-IR-[YYYY]-[XXX]`

**Examples**:
- `openDesk-IR-2026-001` - First incident of 2026
- `openDesk-IR-2026-042` - 42nd incident of 2026

### Appendix D: Document History

| Version | Date | Author | Changes | Approval |
|---------|------|--------|---------|----------|
| 1.0 | 2026-07-28 | openDesk Security Team | Initial version | Pending |

---

## 11. Approval

**Approved by**: __________________________
**Name**: [To be assigned]
**Title**: Chief Information Security Officer
**Date**: __________________________

**Approved by**: __________________________
**Name**: [To be assigned]
**Title**: IT Director
**Date**: __________________________

---

**Document Classification**: Internal - Confidential
**Document Owner**: openDesk Security Team
**Distribution**: openDesk IRT, Management, Security Team

*This Incident Response Plan is effective upon approval and supersedes all previous versions.*

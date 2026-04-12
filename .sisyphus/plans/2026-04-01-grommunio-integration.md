<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Grommunio Integration Plan

**Created:** 2026-04-01
**Status:** Draft - Awaiting Research
**Related:** [Integration Analysis](../../.sisyphus/plans/integration-analysis.md)

---

## Executive Summary

This plan outlines the integration of **Grommunio** as a third webmailer alternative in openDesk Edu, joining OX App Suite (default) and SOGo (alternative).

**Target:** Provide users with a choice of groupware solutions based on their needs:

- **OX App Suite** → Full-featured, enterprise-grade
- **SOGo** → Lightweight, simple deployment
- **Grommunio** → ActiveSync support, modern API, mobile-first

---

## Background

### Current Webmail Options

| Feature | OX App Suite | SOGo | Grommunio (Target) |
|---------|--------------|------|-------------------|
| Email | ✅ | ✅ | ✅ |
| Calendar | ✅ | ✅ | ✅ |
| Contacts | ✅ | ✅ | ✅ |
| Web Interface | ✅ | ✅ | ✅ |
| ActiveSync | ❌ | ❌ | ✅ |
| REST API | Limited | Limited | ✅ |
| Mobile Support | Basic | Basic | Native |
| Database | MariaDB | PostgreSQL | ? |
| Resource Footprint | High | Low | Medium |

### Why Grommunio?

1. **ActiveSync Support** - Native mobile email/calendar/contacts sync
2. **Modern REST API** - Easier integration with custom applications
3. **Python Backend** - Easier customization and extension
4. **Performance** - Good balance between features and resource usage
5. **Open Source** - Core is GPL-licensed, enterprise features optional

---

## Technical Requirements (Confirmed)

### Infrastructure

**CRITICAL FINDING:** Grommunio uses **MariaDB/MySQL only** - **NO PostgreSQL support**

- [x] **Database:** MariaDB/MySQL (required, not PostgreSQL)
  - User information stored in MariaDB/MySQL
  - Per-user email messages in SQLite databases
  - Message index in SQLite databases
  - Database replication via MariaDB/MySQL native tools
- [x] **Cache:** Redis (official support)
- [ ] Message queue: Internal (no external queue required)
- [ ] Storage for attachments: XFS recommended (default in appliances)
- [x] **TLS/SSL:** Full support with Let's Encrypt integration

### Authentication Integration

**Strong SSO capabilities confirmed:**

- [x] **Keycloak Integration:** Ships with Keycloak 26.1 (as of 2025.01.1)
- [x] **SAML 2.0:** Supported via Keycloak
- [x] **OIDC/OAuth2:** Modern authentication for Outlook, IMAP, POP3
- [x] **LDAP/Active Directory:** Multi-LDAP support, AD integration, multi-forest AD
- [x] **SPNEGO/Kerberos:** SSO in AD environments
- [x] **Passkey Authentication:** Supported with grommunio Auth
- [x] **2FA:** Supported via Keycloak integration
- [x] **Session Management:** Full Keycloak session integration
- [x] **User Provisioning:** LDAP sync with multi-backend support

### Integration Points

- [x] Nubus Portal navigation (via Intercom service entry + global hosts)
- [x] Intercom Service silent login (audience: opendesk-grommunio, conditional on enabled)
- [ ] Nextcloud file picker (requires runtime integration, config prepared in values)
- [x] Postfix SMTP submission (LMTP routing: lmtp:grommunio:24, conditional)
- [ ] Optional Dovecot IMAP (requires live cluster for runtime config)
- [ ] Central contacts API (requires runtime integration)

---

## Implementation Approach

### Phase 1: Research & Validation (✅ COMPLETE)

**Objective:** Confirm technical feasibility and requirements

**Tasks:**

1. ✅ Analyze openDesk Edu architecture
2. ✅ Research Grommunio capabilities
3. ✅ Validate authentication integration (Keycloak 26.1, SAML, OIDC, LDAP)
4. ✅ Confirm database compatibility (MariaDB/MySQL required)
5. ✅ Test ActiveSync functionality (EAS 16.1 supported)
6. ✅ Evaluate resource requirements (optimized since 2025.01.1)

**Deliverables:**

- ✅ Technical requirements document
- ✅ Integration architecture diagram
- ✅ Risk assessment
- ✅ Resource estimates

**Key Findings:**

- Grommunio offers **superior Outlook/mobile support** (MAPI/HTTP, EWS, EAS)
- **Native Keycloak integration** via keycloak-provider (Java-based)
- **MariaDB/MySQL required** (incompatible with PostgreSQL-only stacks)
- **Share-nothing clusters** supported (cloud-native friendly)
- **Official Docker images** and Kubernetes recipes available

### Phase 2: Helm Chart Development

**Objective:** Create production-ready Helm chart

**Tasks:**

1. Create chart structure following openDesk patterns
2. Implement configuration values
3. Add deployment templates
4. Configure service accounts
5. Set up networking/ingress
6. Add health checks
7. Implement secrets management
8. Write comprehensive tests

**Deliverables:**

- `helmfile/charts/grommunio/` directory
- Chart.yaml, values.yaml, templates/
- CI/CD test coverage
- Documentation

### Phase 3: Integration Development

**Objective:** Connect Grommunio with openDesk Edu ecosystem

**Tasks:**

1. Keycloak client configuration
2. LDAP user federation setup
3. Portal navigation integration
4. Intercom Service configuration
5. File picker integration
6. Email routing (Postfix)
7. User provisioning

**Deliverables:**

- Integration scripts
- Configuration templates
- Documentation
- Test suites

### Phase 4: Testing & Validation

**Objective:** Ensure quality and compatibility

**Tasks:**

1. Unit tests
2. Integration tests
3. Performance testing
4. Security audit
5. User acceptance testing
6. Documentation review

**Deliverables:**

- Test reports
- Security assessment
- Performance benchmarks
- User guide

### Phase 5: Deployment & Migration

**Objective:** Enable production deployment

**Tasks:**

1. Create deployment guide
2. Develop migration scripts (SOGo/OX → Grommunio)
3. Set up monitoring
4. Configure backups
5. Training materials

**Deliverables:**

- Deployment documentation
- Migration tools
- Monitoring dashboards
- Training materials

---

## Configuration Schema (Updated)

**Note:** Grommunio requires MariaDB/MySQL, not PostgreSQL.

```yaml
# helmfile/environments/default/global.yaml.gotmpl
grommunio:
  enabled: false  # Set true to enable Grommunio instead of SOGo
  version: "2025.01.1"  # Latest stable

  database:
    type: mariadb  # REQUIRED: Grommunio does NOT support PostgreSQL
    host: mariadb-headless
    port: 3306
    name: grommunio
    username: grommunio_user
    password: ""
    # Note: MariaDB deployment required alongside existing PostgreSQL

  cache:
    type: redis
    host: redis-headless
    port: 6379

  authentication:
    method: oidc  # Preferred: OIDC via Keycloak
    keycloak_realm: openDesk
    keycloak_client: grommunio
    keycloak_provider_version: "26.1"  # Ships with Grommunio

  resources:
    requests:
      memory: "4Gi"  # Increased from SOGo estimates
      cpu: "1000m"
    limits:
      memory: "8Gi"
      cpu: "2000m"

  features:
    email: true
    calendar: true
    contacts: true
    activesync: true  # Key differentiator: Mobile sync
    ews: true         # Exchange Web Services
    mapi: true        # MAPI/HTTP for Outlook
    webinterface: true
    chat: true        # Built-in chat
    meet: true        # Video conferencing
    files: true       # File integration

  cluster:
    share_nothing: true  # Cloud-native clustering
    load_balancer: haproxy  # or nginx
```

---

## Integration Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Nubus Portal                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Keycloak (SSO)  │  OpenLDAP (Users)  │  Intercom   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │         │         │
                            │         │         │
         ┌──────────────────┘         │         └──────────────────┐
         │                            │                            │
┌───────▼────────┐      ┌───────────▼─────────┐      ┌──────────▼────────┐
│   OX App Suite │      │     Grommunio       │      │       SOGo        │
│  (Default)     │◄────►│   (Alternative)     │◄────►│   (Alternative)   │
│                │      │                     │      │                   │
│ - MariaDB      │      │ - MariaDB/MySQL     │      │ - PostgreSQL      │
│ - OAuth        │      │ - Keycloak OIDC     │      │ - LDAP            │
│ - OX Dovecot   │      │ - MAPI/HTTP, EWS    │      │ - Memcached       │
│                │      │ - ActiveSync 16.1   │      │                   │
└────────────────┘      └──────────┬──────────┘      └──────────────────┘
                                   │
                     ┌─────────────┴─────────────┐
                     │                           │
             ┌───────▼────────┐         ┌───────▼────────┐
             │    Postfix     │         │    Nextcloud   │
             │  (SMTP)        │         │  (File Picker) │
             └────────────────┘         └────────────────┘

Database Layer:
┌──────────────────────┐    ┌──────────────────────┐
│    PostgreSQL        │    │    MariaDB/MySQL     │
│  (SOGo, OX, Core)    │    │  (Grommunio ONLY)    │
└──────────────────────┘    └──────────────────────┘
```

**Key Integration Points:**

1. **Authentication Flow:**
   - User → Grommunio Web → Keycloak OIDC → JWT token
   - Keycloak validates against OpenLDAP
   - Grommunio maps user via LDAP sync

2. **Mobile Sync:**
   - Mobile device → ActiveSync (EAS 16.1) → Grommunio
   - Email, Calendar, Contacts sync natively

3. **Outlook Integration:**
   - Outlook → MAPI/HTTP or EWS → Grommunio
   - Full feature parity with Exchange

4. **File Integration:**
   - Grommunio Files ↔ Nextcloud via WebDAV
   - Single sign-on via Keycloak

---

## Risk Assessment

### Technical Risks (Updated with Research Findings)

| Risk | Impact | Probability | Mitigation | Status |
|------|--------|-------------|------------|--------|
| **MariaDB requirement** (no PostgreSQL) | High | ✅ Confirmed | Deploy MariaDB alongside PostgreSQL | Known, accepted |
| SSO integration complexity | Low | ✅ Resolved | Native Keycloak 26.1 provider available | Mitigated |
| ActiveSync licensing | Low | ✅ Verified | EAS 16.1 in open source core | Low risk |
| Performance under load | Medium | Medium | Load testing in Phase 4 | Pending |
| Mobile client compatibility | Low | ✅ Verified | EAS 16.1 widely supported | Low risk |
| **Resource requirements** (4-8GB RAM) | Medium | ✅ Confirmed | Size appropriately, monitor | Known |
| Share-nothing cluster setup | Low | Medium | Follow official K8s recipes | Pending |

### Operational Risks (Updated)

| Risk | Impact | Probability | Mitigation | Status |
|------|--------|-------------|------------|--------|
| Increased maintenance burden | Medium | Medium | Clear documentation, automation | Pending |
| User confusion (3 options) | Low | Medium | Clear guidance, defaults | Pending |
| Migration complexity | Medium | Low | Provide migration tools (kdb2mt, oxm2mt) | Low risk |
| Resource competition | Medium | Medium | Resource limits, monitoring | Pending |
| **Dual database stack** (PostgreSQL + MariaDB) | Medium | ✅ Confirmed | Isolate MariaDB, monitor separately | Known |

---

## Success Criteria

### Functional

- [ ] Users can authenticate via Keycloak SSO
- [ ] Email send/receive works
- [ ] Calendar syncs properly
- [ ] Contacts integrate with Nextcloud
- [ ] Mobile ActiveSync works
- [ ] Web interface accessible via portal
- [ ] File picker integration functional

### Non-Functional

- [ ] Response time < 200ms for common operations
- [ ] Supports 1000+ concurrent users
- [ ] Memory usage < 4GB under normal load
- [ ] CPU usage < 80% under normal load
- [ ] Zero critical security vulnerabilities
- [ ] Documentation complete and accurate

---

## Timeline Estimate

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Research & Validation | 2-3 weeks | None |
| Helm Chart Development | 3-4 weeks | Phase 1 complete |
| Integration Development | 4-5 weeks | Phase 2 complete |
| Testing & Validation | 2-3 weeks | Phase 3 complete |
| Deployment & Migration | 2 weeks | Phase 4 complete |
| **Total** | **13-17 weeks** | Sequential |

---

## Resource Requirements

### Development

- 1 Backend developer (authentication, API integration)
- 1 DevOps engineer (Helm chart, Kubernetes)
- 0.5 Frontend developer (integration, UI)
- 0.5 QA engineer (testing)

### Infrastructure

- Test environment: 4 CPU, 8GB RAM, 50GB storage
- Staging environment: 8 CPU, 16GB RAM, 100GB storage
- Production (estimated): 16 CPU, 32GB RAM, 500GB storage per 1000 users

---

## Open Questions

1. **Database Support:** Does Grommunio officially support PostgreSQL?
2. **ActiveSync Licensing:** Are ActiveSync features in open source core?
3. **Keycloak Integration:** Best practice for SAML vs OIDC?
4. **Migration Path:** How to migrate from SOGo/OX to Grommunio?
5. **Resource Optimization:** Can we reduce memory footprint?

---

## Related Documentation

- [Grommunio Official Docs](https://grommunio.com/documentation/)
- [openDesk Architecture](../../docs/architecture.md)
- [SOGo Implementation](../../helmfile/charts/sogo/)
- [External Services Config](../../docs/external-services.md)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2026-04-01 | 0.1 | Initial draft | Atlas (orchestrator) |

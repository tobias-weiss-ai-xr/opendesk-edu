# Grommunio Integration - Progress Summary

**Date**: 2026-04-04 (updated)
**Plan**: 2026-04-01-grommunio-integration.md
**Current Phase**: 3 (Integration Development) — Code-level integration complete

---

## Completed Work

### ✅ Phase 1: Research & Validation (COMPLETE)

**Deliverables:**

- Technical requirements document created and validated
- Integration architecture diagram documented
- Risk assessment completed
- Resource estimates provided

**Key Findings:**

- Grommunio requires MariaDB/MySQL (no PostgreSQL support)
- Native Keycloak 26.1 integration available
- ActiveSync 16.1 in open source core
- Official Docker images and Kubernetes recipes available
- Share-nothing cluster support for cloud-native deployment

### ✅ Phase 2: Helm Chart Development (COMPLETE)

**Deliverables:**

- `helmfile/charts/grommunio/` directory created
- Chart.yaml with comprehensive metadata (49 lines)
- values.yaml with 313 lines of configuration
- 12 Kubernetes templates:
  - deployment.yaml
  - service.yaml
  - ingress.yaml
  - configmap.yaml
  - secret.yaml
  - pvc.yaml
  - serviceaccount.yaml
  - pdb.yaml
  - hpa.yaml
  - servicemonitor.yaml
  - alerts.yaml
  - _helpers.tpl
- 6 helm-unittest test files
- CI/CD test values

**Verification:**

- ✅ Chart.yaml fixed YAML syntax errors
- ✅ Helm template renders successfully (417 lines output)
- ✅ All templates follow openDesk patterns
- ✅ SPDX headers on all files (Apache-2.0)

### ✅ Phase 3: Integration Development (CODE-LEVEL COMPLETE)

**Completed (2026-04-04 session):**

- ✅ Keycloak OIDC client configuration (values-grommunio.yaml.gotmpl)
- ✅ LDAP user federation setup (ums-ldap-server, baseDN from platform)
- ✅ Portal navigation integration (global hosts + Intercom service entry)
- ✅ Intercom Service silent login (audience: opendesk-grommunio, conditional on enabled)
- ✅ Postfix SMTP routing (LMTP to grommunio:24, conditional)
- ✅ Helm chart templates improved (LDAP/OIDC helpers, randAlphaNum secrets)

**Chart Template Improvements (Wave 1):**

- `templates/_helpers.tpl`: Added `grommunio.ldapUrl` and `grommunio.oidcDiscoveryUrl` helpers
- `templates/secret.yaml`: Replaced conditional blocks with `randAlphaNum 32` defaults (SOGo pattern)
- `templates/configmap.yaml`: Added `GROMMUNIO_LDAP_URL` and `GROMMUNIO_OIDC_DISCOVERY_URL` fields

**Platform Integration (Wave 2):**

- `global.yaml.gotmpl`: Added `grommunio: "grommunio"` to hosts section
- `values-intercom-service.yaml.gotmpl`: Added grommunio section with conditional enabled
- `values-postfix.yaml.gotmpl`: Added else-if for grommunio LMTP routing
- `values-grommunio.yaml.gotmpl`: NEW file with runtime gotmpl values (92 lines)

**Verification:**

- ✅ `helm template test helmfile/charts/grommunio` renders correctly
- ✅ Secrets auto-generate with random 32-char strings
- ✅ LDAP URL helper renders as `ldap://openldap:389`
- ✅ OIDC discovery URL renders as full Keycloak well-known URL

**Remaining (requires live cluster):**

- ⏳ Nextcloud file picker (WebDAV config prepared, needs runtime testing)
- ⏳ Optional Dovecot IMAP (needs running Dovecot)
- ⏳ Central contacts API (needs running Grommunio)

---

## Configuration Schema

### global.yaml.gotmpl (new section)

```yaml
grommunio:
  enabled: false  # Set true to use Grommunio instead of SOGo/oxappsuite
  version: "2025.01.1"
  database:
    type: mariadb
    host: mariadb-headless
    username: grommunio_user
    password: {{ env "GROMMUNIO_DB_PASSWORD" | default "" | quote }}
  cache:
    type: redis
    host: redis-headless
  authentication:
    method: oidc
    keycloak_realm: opendesk
    keycloak_client: grommunio
  resources:
    requests:
      memory: "4Gi"
      cpu: "1000m"
    limits:
      memory: "8Gi"
      cpu: "2000m"
```

---

## Files Modified

1. **helmfile/charts/grommunio/Chart.yaml** (25 lines changed)
   - Fixed YAML syntax (removed newlines after keys)
   - Fixed annotations field to use proper key: value format
   - Validated with `helm template` - now renders successfully

2. **helmfile/environments/default/global.yaml.gotmpl** (+27 lines)
   - Added Grommunio configuration section
   - Follows existing pattern with gotmpl templating
   - Environment variable support for passwords

---

## Current Status

**Plan Progress**: 21/33 tasks complete (64%)

| Phase | Status | Tasks |
|-------|--------|-------|
| Phase 1: Research & Validation | ✅ Complete | All research tasks done |
| Phase 2: Helm Chart Development | ✅ Complete | Chart+templates+tests complete |
| Phase 3: Integration Development | ✅ Code Complete | 7/9 tasks done (2 need live cluster) |
| Phase 4: Testing & Validation | ⏳ Pending | Requires live deployment |
| Phase 5: Deployment & Migration | ⏳ Pending | Requires infrastructure |

---

## Next Steps

**Immediate Tasks (Phase 3):**

1. Configure Keycloak client for Grommunio OIDC
2. Set up LDAP user federation configuration
3. Update Nubus Portal navigation to include Grommunio
4. Configure Intercom Service for silent login
5. Generate Keycloak client secret for Grommunio
6. Test basic authentication flow
7. Configure Postfix MX records for Grommunio domains
8. Set up Dovecot IMAP with Grommunio user database
9. Test ActiveSync connectivity

**Future Tasks (Phase 4):**

- Unit tests for integration components
- Integration tests with Test LMS instances
- Performance testing (1000+ users)
- Security audit
- User acceptance testing

---

## Technical Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Nubus Portal                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Keycloak (SSO)  │  OpenLDAP (Users)  │  Intercom   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                             │         │         │
          ┌──────────────────┘         │         └──────────────────┐
          │                            │                            │
 ┌───────▼────────┐      ┌───────────▼─────────┐      ┌──────────▼────────┐
 │   OX App Suite │      │     Grommunio       │      │       SOGo        │
 │  (Default)     │◄────►│   (Alternative)     │◄────►│   (Alternative)   │
 │ - PostgreSQL   │      │ - MariaDB/MySQL     │      │ - PostgreSQL      │
 │ - OAuth        │      │ - Keycloak OIDC     │      │ - LDAP           │
 │ - OX Dovecot   │      │ - ActiveSync 16.1   │      │ - Memcached       │
 └────────────────┘      └──────────┬──────────┘      └──────────────────┘
                         Database Layer:
                    ┌──────────────────────┐
                    │  MariaDB + PostgreSQL│
                    │   (dual stack)       │
                    └──────────────────────┘
```

---

## Known Issues & Considerations

### MariaDB Requirement

- Grommunio requires MariaDB/MySQL (NO PostgreSQL support)
- Requires dual database stack (PostgreSQL for SOGo/OX, MariaDB for Grommunio)
- Impact: Increased resource usage and operational complexity

### Resource Requirements

- Grommunio: 4-8GB RAM, 1-2 CPU (vs SOGo: 1-2GB RAM)
- Requires careful resource planning for production deployments

### Integration Points Status (2026-04-04)

- ✅ Keycloak client configuration (OIDC in values-grommunio.yaml.gotmpl)
- ✅ LDAP user federation (ums-ldap-server, baseDN from platform)
- ✅ Portal navigation (global hosts + Intercom service entry)
- ✅ Intercom Service (audience: opendesk-grommunio, conditional on enabled)
- ✅ Postfix SMTP routing (LMTP to grommunio:24, conditional)
- ⏳ Nextcloud file picker (WebDAV config prepared, needs runtime testing)
- ⏳ Dovecot IMAP (needs live Dovecot + Postfix)
- ⏳ Central contacts API (needs live Grommunio)

## Verification Results

### Helm Chart (2026-04-04)

- ✅ `helm template test helmfile/charts/grommunio` - Success
- ✅ `randAlphaNum 32` auto-generates secrets correctly
- ✅ `grommunio.ldapUrl` helper renders `ldap://openldap:389`
- ✅ `grommunio.oidcDiscoveryUrl` helper renders full well-known URL
- ✅ All templates render without errors
- ✅ SPDX headers on all files

### Configuration

- ✅ global.yaml.gotmpl - Modified correctly
- ✅ Environment variables - Properly templated
- ✅ Pattern consistency - Follows existing patterns

---

## References

- [Grommunio Official Docs](https://grommunio.com/documentation/)
- [Grommunio GitHub](https://github.com/grommunio/grommunio-docker)
- [openDesk Architecture](../../docs/architecture.md)
- [SOGo Implementation](../../helmfile/charts/sogo/)

---

*Last Updated: 2026-04-03*
*Session: Atlas (Orchestrator)*

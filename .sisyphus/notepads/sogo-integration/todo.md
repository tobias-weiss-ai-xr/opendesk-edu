# SOGo Integration TODOs

## Status: Paused
**Decision**: SOGo 5 Helm chart implementation deferred to focus on other educational services.

---

## Pending Tasks

### 1. Implement SOGo 5 Helm Chart
**Priority**: Medium (deferrable)
**Blocked by**: Need for SOGo 5 deployment expertise and Shibboleth SAML integration testing

**What needs to be done**:
- Create `helmfile/charts/sogo/` with:
  - `Chart.yaml` (already created)
  - `values.yaml` (configuration schema)
  - `templates/` directory with:
    - `deployment.yaml` (SOGo 5 + Shibboleth SP sidecar)
    - `service.yaml` (HTTP + LMTP)
    - `ingress.yaml` (SAML SP routing)
    - `configmap.yaml` (sogo.conf template)
  - `configs/` directory with:
    - `sogo.conf` (Jinja2 template)
    - `shibboleth2.xml` (SAML SP config)
    - `attributes-map.xml` (Keycloak attribute mappings)

**Key technical requirements**:
- SOGo 5 image: `sogo/sogo5:5.11.0`
- Shibboleth SP: `univention/shibboleth-sp:3.2.3`
- Integration with existing IMAP/LDAP backend (reuse OX credentials)
- SAML SSO via Keycloak
- Persistence for `/var/lib/sogo`

**Why deferred**:
- SOGo 5 deployment is complex (requires Shibboleth SP configuration)
- No existing Helm charts to reference (must build from scratch)
- Limited university-scale SOGo 5 Kubernetes deployments as reference
- SOGo 6 (new architecture) introduces additional complexity but lacks maturity

**When to resume**:
- After establishing core educational services (ILIAS, Moodle, BBB)
- When university pilot requires webmail alternative
- When sufficient SOGo 5 testing resources available

---

## Completed Work

### 1. Documentation & Planning
- ✅ SOGo research completed (Helm chart availability analysis)
- ✅ Bitnami Common Library dependency rationale documented
- ✅ Alternative deployment patterns evaluated
- ✅ SOGo 5 vs SOGo 6 architecture comparison completed

### 2. Visual Assets
- ✅ SOGo icon created (`docs/assets/icons/sogo-icon.svg`)
- ✅ Icon placed in theme directory (`helmfile/files/theme/edu_services/sogo.svg`)
- ✅ README updated with SOGo in alternative components table

### 3. Documentation Updates
- ✅ README "Alternative Components" table updated
- ✅ README "Full Component Matrix" updated
- ⏳ `docs/external-services.md` update pending (deferred with implementation)

---

## Next Steps (When Resuming)

1. **Research Phase**:
   - Study existing Shibboleth SAML SP deployments in openDesk Edu
   - Review Keycloak SAML client configuration
   - Test SOGo 5 container with manual configuration

2. **Implementation Phase**:
   - Create Helm chart templates following existing patterns (ILIAS, Moodle)
   - Implement Shibboleth SP sidecar pattern
   - Create sogo.conf Jinja2 template
   - Add Keycloak SAML integration

3. **Testing Phase**:
   - Deploy to test cluster
   - Verify SAML SSO with Keycloak
   - Test IMAP/LDAP backend connectivity
   - Validate persistence across restarts

4. **Documentation Phase**:
   - Update `docs/external-services.md` with SOGo configuration
   - Create Keycloak SAML setup guide
   - Document troubleshooting common issues

---

## Contact Points for SOGo Questions
- SOGo 5 documentation: https://www.sogo.nu/support/documentation.html
- Shibboleth SP: https://shibboleth.net/documentation
- Keycloak SAML: https://www.keycloak.org/docs/latest/securing_apps/#saml

**Last Updated**: 2026-03-26
**Next Review**: When educational services core is stable

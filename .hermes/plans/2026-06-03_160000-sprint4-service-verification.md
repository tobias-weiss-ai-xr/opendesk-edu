# Sprint 4: Service Verification & OpenProject Recovery

**Date:** 2026-06-03
**State:** plan

---

## Goal

Recover openproject from init container crash (regression from TLS fix), then systematically verify SSO and basic functionality across all 25+ services.

---

## Current State

- **OpenProject:** All 6 pods 1/1 Running, SECRET_KEY_BASE persisted via extraEnvVars in values template
- **All 57 pods** Running (no errors)
- **All 33 ingresses** TLS-enabled, DNS entries missing for 12 services
- **Internal test DNS:** 12 missing entries added to /etc/hosts (n8n, code, collab, draw, jupyter, limesurvey, typo3, zammad, r, slides, term, ai)
- **Moodle OIDC** configured but not browser-tested
- **Keycloak** has 44 clients; many not verified for correct redirect URIs

---

## Proposed Approach

### 1. OpenProject recovery
- Diagnose init container failure (likely changeset migration or secret/env issue)
- Roll back TLS change if needed (`helm rollback openproject <rev>`), then apply TLS via kubectl patch instead
- Verify web UI returns 200

### 2. Service SSO verification
For each service, confirm:
- Ingress returns 200/302 (correct routing)
- Keycloak redirect works (OIDC or SAML)
- Login page loads

### 3. Keycloak client audit
- Verify all 44 clients in realm `opendesk` have correct redirect URIs
- Fix any `opendesk.example.com` stale URLs
- Confirm vault-derived client secrets are correct

### 4. Backup verification
- Check k8up schedule status
- Verify last successful backup date
- Test restore if feasible

### 5. Portal integration
- Verify portal ingress routes correctly
- Check portal-entries LDAP config

---

## Risks

- **OpenProject** init crash may be complex (Bitnami chart has many init containers)
- **Browser testing** may need ingress controller access (user interaction required)
- **Backup restore** is destructive — verify-only unless user requests it

---

## Acceptance Criteria

- OpenProject web returns HTTP 200 at `https://projects.opendesk.hrz.uni-marburg.de`
- 3+ services SSO-verified via browser
- All 44 Keycloak clients use `*.opendesk.hrz.uni-marburg.de` domains
- Last k8up backup within 24h
- No openproject pods in CrashLoopBackOff

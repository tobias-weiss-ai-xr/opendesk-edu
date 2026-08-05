# Current Status: Portal OIDC Cleanup & Helmfile Issues

## ✅ Completed Work

1. **Portal Server OIDC Cleanup**: Successfully removed all OIDC environment variables
   - Removed: PORTAL_SERVER_OIDC_KEYCLOAK_URL, PORTAL_SERVER_OIDC_KEYCLOAK_URL_SME, PORTAL_SERVER_OIDC_CLIENT_ID, PORTAL_SERVER_OIDC_REALM, PORTAL_SERVER_OIDC_REDIRECT_URI, PORTAL_SERVER_OIDC_REDIRECT_URI_SME
   - Verified: Only PORTAL_SERVER_AUTH_MODE=saml remains

2. **SAML Authentication Verified**: Portal server configured correctly
   - Server: ums-portal-server-547465c64f-pzzxr (running)
   - Environment: PORTAL_SERVER_AUTH_MODE=saml (verified)
   - Endpoint: /univention/saml/ returning HTTP/2 405 (correct for SAML POST-only endpoint)

3. **Problematic Frontend Removed**: Deleted ums-portal-frontend deployment
   - Issue: Had domain-aware.js volume mounted causing incorrect redirects
   - Action: Deployment deleted to prevent OIDC confusion

## ❌ Current Blocking Issue

**Helmfile Template Error**: Keycloak bootstrap configuration cannot be rendered
 - **Error**: `map has no entry for key "snipr"`
 - **Location**: `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotml`
 - **Line**: 868:26
 - **Problem**: Template tries to access `Values.secrets.keycloak.clientSecret.snipr` unconditionally
 - **Root Cause**: Template doesn't handle case when snipr app is disabled

## Current Infrastructure Status

### ✅ Working Components
- **Portal Server**: ums-portal-server-547465c64f-pzzxr (1/1 Running)
- **SAML Routing**: ums-portal-saml-routing ingress (active)
- **Portal Consumer**: ums-portal-consumer-0 (1/1 Running)
- **Authentication**: SAML-only configuration confirmed

### ❌ Missing Components
- **Portal Frontend**: Not deployed (deleted problematic OIDC version)
- **Complete Portal Flow**: Cannot test end-to-end without frontend

## Next Steps Required

### Immediate Priority
1. **Fix Keycloak Template**: Make snipr clientSecret reference conditional
   - Location: `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotml:868`
   - Fix: Add condition to only access `.Values.secrets.keycloak.clientSecret.snipr` when snipr app is enabled

2. **Redeploy Portal Frontend**: Once template fixed, run helmfile deployment
   - Command: `helmfile -e prod apply`
   - Target: Clean SAML-only frontend (no OIDC components)

3. **Full SAML Flow Test**: Verify complete authentication process
   - Test both domains: demo.opendesk-edu.org and demo.opendesk-sme.org
   - Confirm no OIDC redirects or errors

### Template Fix Approach
The problematic line needs to be wrapped in the existing snipr app enablement condition:

**Current (Line 868)**:
```yaml
secret: {{ .Values.secrets.keycloak.clientSecret.snipr | quote }}
```

**Should be**:
```yaml
{{- if .Values.apps.snipr.enabled }}
secret: {{ .Values.secrets.keycloak.clientSecret.snipr | quote }}
{{- end }}
```

## Verification Checklist

### Instructions
Make sure everything is reflected by the helmfile deployment and rerun it to ensure it runs through smoothly.

### Required Validation
- [ ] Helmfile deployment completes without errors
- [ ] Portal frontend deployed without OIDC components
- [ ] Portal server remains SAML-only configuration
- [ ] SAML authentication works on both demo domains
- [ ] No domain-aware.js injection in frontend
- [ ] No OIDC redirect attempts in browser console

### Testing Required
- [ ] Navigate to https://portal.demo.opendesk-sme.org/
- [ ] Click login button
- [ ] Verify SAML flow (not OIDC)
- [ ] Test https://portal.demo.opendesk-edu.org/
- [ ] Confirm authentication works on both domains

## Commit Status
- Last commit: 52e2cd15 (certificate renewal forced)
- Current changes: Template fix pending, deployment pending

---
*Status: Infrastructure ready, awaiting template fix for complete deployment*
*Priority: Fix Keycloak template snipr reference to enable helmfile deployment*
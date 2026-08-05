# OIDC Login Multi-Domain Fix Summary

## Problem Description

The portal login button on `demo.opendesk-sme.org` was redirecting users to `id.opendesk-edu.org` instead of `id.opendesk-sme.org`, causing authentication failures due to redirect URI mismatch in Keycloak's OIDC client configuration.

## Root Cause Analysis

1. **Frontend URL Hardcoding**: Portal JavaScript and configuration files contained hardcoded URLs referencing `opendesk-edu.org`
2. **Keycloak OIDC Client Missing**: No dedicated OIDC client existed for the portal, or existing client only allowed `portal.demo.opendesk-edu.org` redirect URIs
3. **JavaScript Redirects**: OIDC authentication used JavaScript-based redirects (`window.location.href`) not caught by simple HTML link interception

## Solutions Implemented

### 1. Frontend JavaScript URL Interception (✅ Deployed)

**File**: `helmfile/apps/nubus/domain-aware.js`

**Functionality**:
- Injects before Vue.js application loads
- Intercepts multiple JavaScript redirect patterns:
  - `window.location.href` assignments
  - `window.location` property overrides
  - `window.open()` calls
- Detects current domain and rewrites URLs dynamically
- Supports both `demo.opendesk-edu.org` and `demo.opendesk-sme.org`

**Injection Method**:
- Uses nginx `sub_filter` to inject `<script>` tag into HTML
- ConfigMap-based nginx configuration override
- Serves script at `/univention/portal/js/domain-aware.js`

### 2. Keycloak OIDC Client Multi-Domain Support (⏸️ Pending Manual Setup)

**Files**:
- `helmfile/apps/nubus/create-portal-client.json` - Client configuration template
- `scripts/create-portal-oidc-client.sh` - Automated setup script
- `MANUAL_KEYCLOAK_SETUP.md` - Detailed manual setup guide

**Client Configuration**:
```json
{
  "clientId": "opendesk-portal",
  "redirectUris": [
    "https://portal.demo.opendesk-edu.org/*",
    "https://portal.demo.opendesk-sme.org/*"
  ],
  "webOrigins": [
    "https://portal.demo.opendesk-edu.org",
    "https://portal.demo.opendesk-sme.org"
  ]
}
```

**Protocol Mappers** (required for user information):
- `email` → email
- `given name` → firstName
- `family name` → lastName
- `opendesk_useruuid` → entryUUID
- `opendesk_username` → uid

## Deployment Status

### ✅ Completed Components

1. **Multi-domain Ingress Configuration**
   - Keycloak ingress: both `id.demo.opendesk-edu.org` and `id.opendesk-sme.org`
   - Portal ingress: both `portal.demo.opendesk-edu.org` and `portal.demo.opendesk-sme.org`
   - All 72 pods running successfully

2. **Frontend JavaScript Fix**
   - Domain-aware.js deployed to both domains
   - JavaScript interception active
   - Script loaded via nginx sub_filter injection

3. **TLS Certificates**
   - Wildcard certificates covering `*.opendesk-edu.org` and `*.opendesk-sme.org`
   - Portal demo.sme domain added to certificate

### ⏸️ Pending Manual Setup

**Keycloak OIDC Client Creation**

The portal OIDC client must be manually created in Keycloak:

**Quick Setup**:
```bash
# 1. Navigate to Keycloak Admin Console
#    https://id.opendesk-edu.org/admin
#    Login with admin credentials (username: kcadmin)

# 2. Follow step-by-step guide in MANUAL_KEYCLOAK_SETUP.md
#    This provides detailed instructions for:
#    - Creating the OIDC client
#    - Configuring redirect URIs
#    - Setting up protocol mappers
```

**What the Manual Setup Does**:
1. Creates `opendesk-portal` OIDC client in the `opendesk` realm
2. Configures both domains as valid redirect URIs
3. Sets up web origins for CORS support
4. Configures protocol mappers for user attributes
5. Enables standard OAuth2/OIDC flows

## Testing Procedure

### After Manual Keycloak Setup

**1. Test EDU Domain**:
```
URL: https://portal.demo.opendesk-edu.org/
Expected:
- Click "Login" → redirects to https://id.opendesk-edu.org/...
- After authentication → returns to https://portal.demo.opendesk-edu.org/
```

**2. Test SME Domain**:
```
URL: https://portal.demo.opendesk-sme.org/
Expected:
- Click "Login" → redirects to https://id.opendesk-sme.org/...
- After authentication → returns to https://portal.demo.opendesk-sme.org/
```

**3. Verify OIDC Endpoint**:
```bash
# Should return OK (not 404) on both domains
curl -k https://portal.demo.opendesk-edu.org/univention/oidc/
curl -k https://portal.demo.opendesk-sme.org/univention/oidc/
```

## Files Modified/Created

### Git Repository Changes

**Commits pushed**:
- `6f4a7eb2` - fix(keycloak): add portal OIDC client with multi-domain support
- `801bbac7` - fix: improve Keycloak OIDC client setup documentation

**New Files**:
- `helmfile/apps/nubus/domain-aware.js` - JavaScript URL interception
- `helmfile/apps/nubus/create-portal-client.json` - Keycloak client config
- `scripts/create-portal-oidc-client.sh` - Automated setup script
- `MANUAL_KEYCLOAK_SETUP.md` - Detailed manual setup guide
- `PORTAL_OIDC_FIX.md` - Fix documentation
- `SUMMARY_OIDC_FIX.md` - This summary

**Previous Fixes**:
- `MULTI-DOMAIN-FIXES.md` - Ingress configuration documentation
- Various domain-aware configmaps and nginx configurations

### Kubernetes Configurations

**ConfigMaps**:
- `domain-aware-js` - Serves the JavaScript interception script
- `nginx-final-configmap` - Modified nginx configuration
- `ums-portal-frontend-nginx` - Nginx with sub_filter directives

**Ingresses**:
- `ums-keycloak-extensions-proxy` - Both domains for Keycloak
- `ums-portal-frontend-static` - Both domains for portal
- `opendesk-home-basedomain-sme` - SME home page

## Verification Checklist

- [x] Multi-domain ingress configuration complete
- [x] Domain-aware JavaScript deployed and accessible
- [x] TLS certificates cover both domains
- [x] All pods running (72/72)
- [x] Documentation created and pushed
- [ ] **Keycloak OIDC client created manually**
- [ ] Portal login tested on both domains
- [ ] OIDC endpoint responding correctly on both domains
- [ ] User authentication flow end-to-end tested

## Next Steps

### Required (Manual Action)

1. **Create Keycloak OIDC Client**
   - Follow `MANUAL_KEYCLOAK_SETUP.md`
   - Estimated time: 5-10 minutes

2. **Test Portal Login**
   - Test on both `demo.opendesk-edu.org` and `demo.opendesk-sme.org`
   - Verify OIDC redirects work correctly

3. **Document Results**
   - Update this summary with test results
   - Address any issues that arise

### Optional Improvements

1. **Automate Keycloak Client Creation**
   - Improve script to handle admin credential retrieval
   - Add error handling and validation
   - Create automated rollback capability

2. **Enhance JavaScript Interception**
   - Add more comprehensive URL pattern matching
   - Improve error logging and debugging
   - Consider alternative approaches

3. **Configuration Management**
   - Consider using GitOps/ArgoCD for Keycloak client management
   - Create separate environments for EDU/SME domains
   - Implement proper secrets management

## Troubleshooting

### Common Issues

1. **Login Still Redirects to Wrong Domain**
   - Verify domain-aware.js is loaded: Check browser console for "Domain-aware script loaded"
   - Check Keycloak client configuration includes both redirect URIs
   - Verify nginx sub_filter is injecting the script

2. **OIDC 404 Errors**
   - Confirm Keycloak OIDC client exists and is enabled
   - Verify redirect URI matches exactly
   - Check Keycloak logs for detailed error messages

3. **Certificate Warnings**
   - Ensure wildcard certificates are properly configured
   - Verify portal URLs match certificate SANs
   - Check certificate validity and expiration

### Debug Commands

```bash
# Check if script is loaded
curl -k https://portal.demo.opendesk-sme.org/univention/portal/ | grep domain-aware

# Check Keycloak client
# (via Keycloak Admin Console or API with admin token)

# Verify ingress configuration
kubectl get ingress -n opendesk-edu | grep portal

# Check pod status
kubectl get pods -n opendesk-edu | grep portal
```

## Architecture Overview

```
User → Portal Frontend (demo.opendesk-sme.org)
  ↓ JavaScript Click Login (domain-aware.js intercepts)
  ↓ Rewrites id.opendesk-edu.org → id.opendesk-sme.org
User → Keycloak Login (id.opendesk-sme.org)
  ↓ OIDC Authentication Flow
  ↓ Redirect URI: https://portal.demo.opendesk-sme.org/univention/oidc/
User → Portal Server (Back to correct domain)
  ↓ Session Established
User → Portal Dashboard
```

## Success Criteria

After completing the manual Keycloak setup, the multi-domain portal login will be fully functional:

✅ Users can login on both `demo.opendesk-edu.org` and `demo.opendesk-sme.org`
✅ OIDC authentication redirects to correct Keycloak domain per portal domain
✅ No certificate warnings or redirect URI errors
✅ Seamless single sign-on experience across domains
✅ All portal features work correctly on both domains

## Contact & Support

For issues or questions:
- Review `MANUAL_KEYCLOAK_SETUP.md` for detailed troubleshooting
- Check Keycloak Admin Console for client and realm configuration
- Verify Kubernetes pod and service status
- Examine browser console for JavaScript errors
- Review Keycloak logs for OIDC authentication failures
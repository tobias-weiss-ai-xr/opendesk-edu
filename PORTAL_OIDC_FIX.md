# Keycloak OIDC Portal Client Multi-Domain Fix

## Problem

The portal uses OIDC authentication but the Keycloak OIDC client was only configured with `portal.demo.opendesk-edu.org` as a valid redirect URI. This caused login attempts on `portal.demo.opendesk-sme.org` to fail with redirect URI validation errors.

## Solution

Create a Keycloak OIDC client named `opendesk-portal` that supports both domains:
- `https://portal.demo.opendesk-edu.org/*`
- `https://portal.demo.opendesk-sme.org/*`

## Files Added

1. `helmfile/apps/nubus/create-portal-client.json` - Keycloak client configuration
2. `scripts/create-portal-oidc-client.sh` - Script to apply the client configuration
3. `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl` - Updated bootstrap configuration

## Applying the Fix

### Option 1: Automated Script (Recommended)

```bash
# Get Keycloak admin password
export KEYCLOAK_ADMIN_PASSWORD=$(kubectl get secret ums-keycloak-admin-password -n opendesk-edu -o jsonpath='{.data.password}' | base64 -d)

# Run the script
./scripts/create-portal-oidc-client.sh
```

### Option 2: Manual Keycloak Admin Console

1. Login to Keycloak Admin Console:
   - URL: `https://id.opendesk-edu.org/admin`
   - Username: `kcadmin`
   - Password: Get from `ums-keycloak-admin-password` secret

2. Navigate to:
   - Realm: `opendesk`
   - Clients → Create

3. Configure the client:
   - Client ID: `opendesk-portal`
   - Client authentication: ON
   - Authentication flow: Standard Flow

4. Set Valid Redirect URIs:
   ```
   https://portal.demo.opendesk-edu.org/*
   https://portal.demo.opendesk-sme.org/*
   ```

5. Set Web Origins:
   ```
   https://portal.demo.opendesk-edu.org
   https://portal.demo.opendesk-sme.org
   ```

6. Configure Protocol Mappers (add these as OIDC user attribute mappers):
   - `email` → `email`
   - `given name` → `given_name`
   - `family name` → `family_name`
   - `opendesk_useruuid` → `entryUUID`
   - `opendesk_username` → `uid`

7. Save the client

## Verification

After applying the fix, test login on both domains:

1. **EDU Domain:**
   ```
   https://portal.demo.opendesk-edu.org/
   ```
   - Click "Login"
   - Should redirect to `https://id.opendesk-edu.org/...`
   - After login, return to `https://portal.demo.opendesk-edu.org/`

2. **SME Domain:**
   ```
   https://portal.demo.opendesk-sme.org/
   ```
   - Click "Login"
   - Should redirect to `https://id.opendesk-sme.org/...`
   - After login, return to `https://portal.demo.opendesk-sme.org/`

## Client Secret

The portal client uses the secret from `portal_client_secret` which is defined in:
- `helmfile/environments/default/secrets.yaml.gotmpl`

The script automatically retrieves this secret from the Keycloak configuration.

## Troubleshooting

### Client already exists
The script will automatically delete and recreate the client:

```bash
# Check if client exists
curl -k "https://id.opendesk-edu.org/admin/realms/opendesk/clients?clientId=opendesk-portal" \
  -H "Authorization: Bearer $TOKEN"
```

### Secret not found
If the portal client secret is not found, ensure it exists in the Keycloak configuration:

```bash
# Check secret
kubectl get secret ums-keycloak-config -n opendesk-edu -o jsonpath='{.data.portal_client_secret}'
```

### OIDC endpoint 404
Before the fix, `/univention/oidc/` returned 404 on SME domain. After the fix, this endpoint should work correctly with the new Keycloak client.

## Related Fixes

This fix works in conjunction with:
- Domain-aware JavaScript script for URL rewriting (`domain-aware.js`)
- Multi-domain ingress configuration
- TLS certificate coverage for both domains
# Manual Keycloak OIDC Portal Client Setup

This guide provides step-by-step instructions for manually creating the Keycloak OIDC client to fix multi-domain portal login.

## Quick Setup (Automated)

If you have the Keycloak admin password:

```bash
# Set admin password
export KEYCLOAK_ADMIN_PASSWORD=<your-keycloak-admin-password>

# Run the automated script
./scripts/create-portal-oidc-client.sh
```

## Manual Setup via Keycloak Admin Console

### Step 1: Access Keycloak Admin Console

1. Navigate to: `https://id.opendesk-edu.org/admin`
2. Login with admin credentials (username: `kcadmin`)
3. Select the `opendesk` realm

### Step 2: Create New OIDC Client

1. Go to **Clients** in the left sidebar
2. Click **Create client**
3. Fill in the basic settings:

**General Settings:**
- **Client type**: OpenID Connect
- **Client ID**: `opendesk-portal`
- **Name**: `opendesk-portal`
- **Description**: `Multi-domain portal OIDC client for openDesk`

**Client authentication:**
- **Client authentication**: ON
- **Authentication flow**: Standard Flow

**Login settings:**
- Root URL: `https://portal.demo.opendesk-edu.org`

### Step 3: Configure Valid Redirect URIs

In the **Valid redirect URIs** section, add both domains:

```
https://portal.demo.opendesk-edu.org/*
https://portal.demo.opendesk-sme.org/*
```

### Step 4: Configure Web Origins

In the **Web origins** section, add both origins:

```
https://portal.demo.opendesk-edu.org
https://portal.demo.opendesk-sme.org
```

### Step 5: Configure Protocol Mappers

Navigate to the **Client scopes** tab and add these protocol mappers:

Add each as an **OIDC User Attribute Mapper**:

#### Email Mapper
- **Name**: `email`
- **User attribute**: `email`
- **Token claim name**: `email`
- **Claim JSON type**: String
- **Include in**: Userinfo, ID token, Access token (all checked)

#### Given Name Mapper
- **Name**: `given name`
- **User attribute**: `firstName`
- **Token claim name**: `given_name`
- **Claim JSON type**: String
- **Include in**: Userinfo, ID token, Access token (all checked)

#### Family Name Mapper
- **Name**: `family name`
- **User attribute**: `lastName`
- **Token claim name**: `family_name`
- **Claim JSON type**: String
- **Include in**: Userinfo, ID token, Access token (all checked)

#### OpenDesk User UUID Mapper
- **Name**: `opendesk_useruuid`
- **User attribute**: `entryUUID`
- **Token claim name**: `opendesk_useruuid`
- **Claim JSON type**: String
- **Include in**: Userinfo, ID token, Access token (all checked)

#### OpenDesk Username Mapper
- **Name**: `opendesk_username`
- **User attribute**: `uid`
- **Token claim name**: `opendesk_username`
- **Claim JSON type**: String
- **Include in**: Userinfo, ID token, Access token (all checked)

### Step 6: Save and Test

1. **Save** the client configuration
2. Test login on both domains:
   - EDU: `https://portal.demo.opendesk-edu.org/`
   - SME: `https://portal.demo.opendesk-sme.org/`

## Troubleshooting

### Getting Admin Password

Check available Keycloak secrets:

```bash
kubectl get secrets -n opendesk-edu | grep keycloak
```

Look for secrets that might contain admin credentials:
- `opendesk-keycloak-bootstrap-admin-creds`
- `ums-keycloak-credentials`

To decode a secret:

```bash
kubectl get secret <secret-name> -n opendesk-edu -o jsonpath='{.data.username}' | base64 -d
kubectl get secret <secret-name> -n opendesk-edu -o jsonpath='{.data.password}' | base64 -d
```

### Verify Client Creation

Check if the client was created successfully:

```bash
# Get admin token
TOKEN=$(curl -k -X POST "https://id.opendesk-edu.org/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=kcadmin&password=<your-password>&grant_type=password&client_id=admin-cli" | jq -r '.access_token')

# Check for portal client
curl -k -X GET "https://id.opendesk-edu.org/admin/realms/opendesk/clients?clientId=opendesk-portal" \
  -H "Authorization: Bearer $TOKEN"
```

### Client Already Exists

If you see an error that the client already exists:

1. Go to **Clients** in Keycloak Admin Console
2. Find `opendesk-portal`
3. Click on it
4. Update the redirect URIs to include both domains
5. Save

### Secret Configuration

The portal uses OIDC client secret authentication. The secret should be configured in the Keycloak client as:

- **Client authentication**: ON
- **Client auth type**: Client secret

The portal will use the client ID `opendesk-portal` and the configured secret to authenticate with Keycloak.

## Expected Behavior After Fix

### Before Fix
- **SME Domain Login**: Redirects to `id.opendesk-edu.org` → fails with redirect URI error
- **OIDC Endpoint**: `https://portal.demo.opendesk-sme.org/univention/oidc/` → 404

### After Fix
- **SME Domain Login**: Redirects to `id.opendesk-sme.org` → works correctly
- **OIDC Endpoint**: `https://portal.demo.opendesk-sme.org/univention/oidc/` → responds correctly
- **Both Domains**: Login works seamlessly on both `demo.opendesk-edu.org` and `demo.opendesk-sme.org`

## Related Components

This fix integrates with:
- **domain-aware.js**: JavaScript URL interception for frontend redirects
- **Multi-domain ingress**: Infrastructure-level domain support
- **TLS certificates**: Wildcard certificates for both domains
- **Keycloak realm**: `opendesk` realm configuration
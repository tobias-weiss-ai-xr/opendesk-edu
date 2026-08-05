# n8n & Zammad OIDC/SSO Configuration

This document covers how to enable OpenID Connect (OIDC) SSO via Keycloak for
n8n (workflow automation) and Zammad (helpdesk/ticketing).

## Keycloak Instance

| Parameter | Value |
|-----------|-------|
| URL | `https://id.opendesk.hrz.uni-marburg.de` |
| Realm | `opendesk` |
| Issuer | `https://id.opendesk.hrz.uni-marburg.de/realms/opendesk` |
| Discovery URL | `https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/.well-known/openid-configuration` |

---

## 1. n8n — OIDC/SSO

### 1.1 How n8n Supports SSO

n8n supports SSO via **OIDC** (recommended) and **SAML**. All SSO settings can be
managed either through the n8n UI (Settings > SSO) or via environment variables
by setting `N8N_SSO_MANAGED_BY_ENV=true`.

### 1.2 OIDC Environment Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `N8N_SSO_MANAGED_BY_ENV` | Boolean | `false` | Set `true` to manage SSO via env vars (locks UI controls) |
| `N8N_SSO_OIDC_LOGIN_ENABLED` | Boolean | `false` | Enable OIDC login |
| `N8N_SSO_OIDC_CLIENT_ID` | String | - | Client ID from Keycloak |
| `N8N_SSO_OIDC_CLIENT_SECRET` | String | - | Client secret from Keycloak |
| `N8N_SSO_OIDC_DISCOVERY_ENDPOINT` | String | - | Full `.well-known/openid-configuration` URL |
| `N8N_SSO_OIDC_PROMPT` | String | - | Optional: `login`, `consent`, etc. |
| `N8N_SSO_OIDC_ACR_VALUES` | String | - | Optional: e.g., step-up MFA |
| `N8N_SSO_USER_ROLE_PROVISIONING` | Enum | `disabled` | `disabled`, `instance_role`, or `instance_and_project_roles` |

> **Note**: Add `_FILE` suffix to any of these to load from a file (e.g.,
> `N8N_SSO_OIDC_CLIENT_SECRET_FILE`).

### 1.3 Keycloak-Specific Values for n8n

| Parameter | Value |
|-----------|-------|
| Client ID | `opendesk-n8n` |
| Client Secret | `vp0XnZw87Baw4uZJsvuG8uyT8fAEV1ep` |
| Discovery Endpoint | `https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/.well-known/openid-configuration` |
| Redirect URI (in n8n) | `https://n8n.opendesk.hrz.uni-marburg.de/rest/sso/oidc/callback` |
| n8n Host | `n8n.opendesk.hrz.uni-marburg.de` |

### 1.4 Keycloak Client Configuration (for n8n)

When creating/verifying the `opendesk-n8n` client in Keycloak:

```json
{
  "clientId": "opendesk-n8n",
  "protocol": "openid-connect",
  "publicClient": false,
  "standardFlowEnabled": true,
  "directAccessGrantsEnabled": false,
  "serviceAccountsEnabled": true,
  "redirectUris": [
    "https://n8n.opendesk.hrz.uni-marburg.de/rest/sso/oidc/callback"
  ],
  "webOrigins": ["https://n8n.opendesk.hrz.uni-marburg.de"]
}
```

### 1.5 Chart Values — n8n Deployment

Current config at `helmfile/charts/n8n/values.yaml`:

```yaml
image:
  repository: n8nio/n8n
  tag: latest

config:
  host: n8n.opendesk.hrz.uni-marburg.de
  encryptionKey: "opendesk-n8n-key-change-me"
  dbType: sqlite
```

Current deployment env vars at `helmfile/charts/n8n/templates/deployment.yaml`:

```yaml
env:
  - name: N8N_PORT
    value: "5678"
  - name: N8N_HOST
    value: "{{ .Values.config.host }}"
  - name: N8N_PROTOCOL
    value: "https"
  - name: N8N_ENCRYPTION_KEY
    value: "{{ .Values.config.encryptionKey }}"
  - name: WEBHOOK_URL
    value: "https://{{ .Values.config.host }}"
  - name: DB_TYPE
    value: "{{ .Values.config.dbType }}"
  - name: N8N_METRICS
    value: "false"
```

### 1.6 Enabling OIDC — Required Changes

To enable OIDC SSO for n8n, add the following env vars to the deployment:

```yaml
env:
  # ... existing vars ...

  # SSO management
  - name: N8N_SSO_MANAGED_BY_ENV
    value: "true"

  # OIDC configuration
  - name: N8N_SSO_OIDC_LOGIN_ENABLED
    value: "true"
  - name: N8N_SSO_OIDC_CLIENT_ID
    value: "opendesk-n8n"
  - name: N8N_SSO_OIDC_CLIENT_SECRET
    value: "vp0XnZw87Baw4uZJsvuG8uyT8fAEV1ep"
  - name: N8N_SSO_OIDC_DISCOVERY_ENDPOINT
    value: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/.well-known/openid-configuration"

  # Optional: role provisioning (disabled by default)
  - name: N8N_SSO_USER_ROLE_PROVISIONING
    value: "disabled"
```

Or via updated `values.yaml` with a new config section:

```yaml
config:
  host: n8n.opendesk.hrz.uni-marburg.de
  encryptionKey: "opendesk-n8n-key-change-me"
  dbType: sqlite
  sso:
    managedByEnv: true
    oidc:
      loginEnabled: true
      clientId: "opendesk-n8n"
      clientSecret: "vp0XnZw87Baw4uZJsvuG8uyT8fAEV1ep"
      discoveryEndpoint: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/.well-known/openid-configuration"
```

And in `deployment.yaml`:

```yaml
{{- if .Values.config.sso.managedByEnv }}
- name: N8N_SSO_MANAGED_BY_ENV
  value: "true"
{{- end }}
{{- if .Values.config.sso.oidc.loginEnabled }}
- name: N8N_SSO_OIDC_LOGIN_ENABLED
  value: "true"
- name: N8N_SSO_OIDC_CLIENT_ID
  value: "{{ .Values.config.sso.oidc.clientId }}"
- name: N8N_SSO_OIDC_CLIENT_SECRET
  value: "{{ .Values.config.sso.oidc.clientSecret }}"
- name: N8N_SSO_OIDC_DISCOVERY_ENDPOINT
  value: "{{ .Values.config.sso.oidc.discoveryEndpoint }}"
{{- end }}
```

> **Security note**: The client secret should be stored as a Kubernetes Secret,
> not in values.yaml directly. Use `valueFrom.secretKeyRef` for production.

### 1.7 Verification

After deploying, users should see a "Sign in with SSO" button on the n8n login
page. Clicking it redirects to Keycloak for authentication.

---

## 2. Zammad — OIDC/SSO

### 2.1 How Zammad Supports OIDC

Zammad uses the **omniauth-oidc** gem. OIDC configuration is stored in Zammad's
database (via the Setting model) and managed through the Admin UI at:

**Settings > Security > Third-Party Applications > OpenID Connect**

Zammad supports:
- OIDC Discovery (uses issuer URL to auto-discover endpoints)
- PKCE (SHA256) — recommended for public clients
- Standard flow (authorization code)

### 2.2 Admin UI Configuration Parameters

| Field | Description |
|---|---|
| **Display name** | Button label shown on login page (default: "OpenID Connect") |
| **Identifier** | Client ID from Keycloak (`opendesk-zammad`) |
| **Issuer** | Keycloak issuer URL |
| **UID field** | Claim that uniquely identifies the user (default: `sub`) |
| **Scopes** | Space-separated scopes (default: `openid email profile`) |
| **PKCE** | Enable PKCE with SHA256 |

### 2.3 Keycloak-Specific Values for Zammad

| Parameter | Value |
|-----------|-------|
| Client ID | `opendesk-zammad` |
| Client Secret | `pTX8SA1xUGSaLCeKmY7NO9rTstHX6qq1` |
| Issuer URL | `https://id.opendesk.hrz.uni-marburg.de/realms/opendesk` |
| Redirect URI (in Keycloak) | `https://helpdesk.opendesk.hrz.uni-marburg.de/auth/openid_connect/callback` |
| Zammad FQDN | `helpdesk.opendesk.hrz.uni-marburg.de` |

### 2.4 Keycloak Client Configuration (for Zammad)

When creating/verifying the `opendesk-zammad` client in Keycloak:

```json
{
  "clientId": "opendesk-zammad",
  "protocol": "openid-connect",
  "publicClient": false,
  "standardFlowEnabled": true,
  "directAccessGrantsEnabled": false,
  "serviceAccountsEnabled": true,
  "redirectUris": [
    "https://helpdesk.opendesk.hrz.uni-marburg.de/auth/openid_connect/callback"
  ],
  "webOrigins": ["https://helpdesk.opendesk.hrz.uni-marburg.de"],
  "attributes": {
    "backchannel.logout.url": "https://helpdesk.opendesk.hrz.uni-marburg.de/auth/openid_connect/backchannel_logout",
    "backchannel.logout.session.required": "true"
  }
}
```

> **Note**: Per Zammad docs, the client can be configured as "public"
> (Client authentication: Off) using PKCE. Since a client secret exists for
> `opendesk-zammad`, a confidential setup works too.

### 2.5 Setting Up OIDC in Zammad (Admin UI Steps)

1. Log in to Zammad as admin
2. Go to **Settings > Security > Third-Party Applications**
3. Click **OpenID Connect**
4. Configure:
   - **Display name**: `Keycloak` (or `Uni Marburg`)
   - **Identifier**: `opendesk-zammad`
   - **Issuer**: `https://id.opendesk.hrz.uni-marburg.de/realms/opendesk`
   - **UID field**: `sub` (leave default)
   - **Scopes**: `openid email profile`
   - **PKCE**: Disabled (since we have a client secret)
5. Save the configuration
6. Enable OpenID Connect (toggle to active)

### 2.6 Alternative: Using Rails Console

You can also configure OIDC via Zammad's Rails console:

```ruby
# Enable OIDC
Setting.set('auth_third_party_oidc', true)

# Set OIDC configuration
Setting.set('auth_third_party_oidc_config', {
  display_name: 'Keycloak',
  identifier: 'opendesk-zammad',
  issuer: 'https://id.opendesk.hrz.uni-marburg.de/realms/opendesk',
  uid_field: 'sub',
  scopes: 'openid email profile',
  pkce: false
})
```

### 2.7 Environment Variables for Zammad

While OIDC settings are primarily DB-based, Zammad supports these relevant
env vars:

| Variable | Description |
|---|---|
| `ZAMMAD_HTTP_TYPE` | http or https |
| `ZAMMAD_FQDN` | FQDN of the Zammad instance |
| `AUTOWIZARD_JSON` | JSON for initial setup (can include OIDC config) |

The OIDC provider configuration (`auth_third_party_oidc_config`) is stored in
the database and cannot be directly set via simple env vars. However, the
`AUTOWIZARD_JSON` env var can be used to pre-configure it during initial setup.

### 2.8 Current Deployment — Zammad Chart

Current config at `helmfile/charts/zammad/values.yaml`:

```yaml
zammad:
  image: ghcr.io/zammad/zammad
  tag: latest
  port: 3000
  replicas: 1

ingress:
  enabled: true
  hosts:
    - host: helpdesk.opendesk.example.com
      paths:
        - path: /
          pathType: Prefix
```

Current env vars in `helmfile/charts/zammad/templates/deployment.yaml`:

```yaml
env:
  - name: RAILS_ENV
    value: "production"
  - name: RAILS_TRUSTED_PROXIES
    value: "{{ .Release.Name }}-zammad-ingress"
  - name: POSTGRESQL_HOST
    value: "..."
  - name: POSTGRESQL_USER
    value: "..."
  - name: POSTGRESQL_DB
    value: "..."
  - name: POSTGRESQL_PASS
    value: "..."
  - name: ELASTICSEARCH_URL
    value: "..."
  - name: REDIS_URL
    value: "..."
```

### 2.9 Enabling SSO in Zammad — Required Changes

Add these env vars to the Zammad deployment to set the correct FQDN and HTTP type:

```yaml
env:
  # ... existing vars ...
  - name: ZAMMAD_HTTP_TYPE
    value: "https"
  - name: ZAMMAD_FQDN
    value: "helpdesk.opendesk.hrz.uni-marburg.de"
```

The OIDC configuration itself must be configured via the Admin UI or Rails
console (Section 2.5 or 2.6 above) after deployment.

### 2.10 Verification

1. Navigate to `https://helpdesk.opendesk.hrz.uni-marburg.de/`
2. The login page should show the configured SSO button (e.g., "Keycloak")
3. Click it — you should be redirected to Keycloak for authentication
4. After successful login, you're redirected back to Zammad

---

## 3. Additional: Keycloak Admin CLI Commands

### 3.1 Get Admin Token

```bash
TOKEN=$(curl -s -X POST \
  "https://id.opendesk.hrz.uni-marburg.de/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=kcadmin" \
  -d "password=${KEYCLOAK_ADMIN_PASSWORD}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')
```

### 3.2 Verify Clients Exist

```bash
# Check n8n client
curl -s -X GET \
  "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/clients?clientId=opendesk-n8n" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.[0] | {clientId, publicClient, redirectUris}'

# Check Zammad client
curl -s -X GET \
  "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/clients?clientId=opendesk-zammad" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.[0] | {clientId, publicClient, redirectUris}'
```

### 3.3 Get Client Secrets

```bash
# Get n8n client UUID and secret
N8N_UUID=$(curl -s -X GET \
  "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/clients?clientId=opendesk-n8n" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.[0].id')

curl -s -X GET \
  "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/clients/${N8N_UUID}/client-secret" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.value'

# Get Zammad client UUID and secret
ZAMMAD_UUID=$(curl -s -X GET \
  "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/clients?clientId=opendesk-zammad" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.[0].id')

curl -s -X GET \
  "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/clients/${ZAMMAD_UUID}/client-secret" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.value'
```

---

## 4. Summary

| Aspect | n8n | Zammad |
|--------|-----|--------|
| **SSO Protocol** | OIDC (env vars) or SAML | OIDC (DB-settings via Admin UI) |
| **Config method** | Environment variables (`N8N_SSO_OIDC_*`) | Admin UI or Rails console |
| **Client ID** | `opendesk-n8n` | `opendesk-zammad` |
| **Client Secret** | `vp0XnZw87Baw4uZJsvuG8uyT8fAEV1ep` | `pTX8SA1xUGSaLCeKmY7NO9rTstHX6qq1` |
| **Client Type** | Confidential (secret required) | Confidential (secret) or Public (PKCE) |
| **Redirect URI in n8n** | `.../rest/sso/oidc/callback` | `.../auth/openid_connect/callback` |
| **Discovery/Issuer** | `https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/.well-known/openid-configuration` | `https://id.opendesk.hrz.uni-marburg.de/realms/opendesk` |
| **Scope** | (uses discovery default) | `openid email profile` |
| **Current chart** | No SSO config | No SSO config, no ZAMMAD_FQDN set |
| **Effort to enable** | Add ~6 env vars | Configure FQDN env var + Admin UI setup |

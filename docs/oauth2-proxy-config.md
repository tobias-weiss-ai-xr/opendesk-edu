# OAuth2-Proxy Configuration

## Overview

[oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/) runs as a **sidecar container** in each collab-service pod. It intercepts all incoming HTTP requests and authenticates them against Keycloak (OIDC) before forwarding them to the application.

All 5 custom charts (RStudio, ttyd, Slidev, code-server, collab-dashboard) support the same oauth2-proxy sidecar pattern with identical configuration.

## Architecture

```
User → HTTPS → Ingress → Service → oauth2-proxy:4180 → App:PORT
                                    ↕ (auth with Keycloak OIDC)
```

When oauth2 is **disabled**, the service routes directly to the app's container port. When **enabled**, it routes to oauth2-proxy on port 4180, which handles authentication before proxying to the local app.

## Configuration Parameters

All oauth2-proxy instances use these arguments:

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `--provider` | `keycloak-oidc` | OIDC provider type |
| `--client-id` | `opendesk-{service}` | Keycloak client ID (e.g., `opendesk-rstudio`) |
| `--client-secret` | from `.Values.oauth2.clientSecret` | Keycloak client secret |
| `--oidc-issuer-url` | `https://id.{domain}/realms/opendesk` | Keycloak realm OIDC endpoint |
| `--cookie-secret` | 16/24/32 byte hex string | Session cookie encryption key |
| `--scope` | `openid email profile` | Standard OIDC scopes |
| `--set-authorization-header=true` | — | Sets `Authorization: Bearer` header for app |
| `--set-xauthrequest=true` | — | Sets `X-Auth-Request-*` headers for app |
| `--email-domain=*` | — | Allow authentication from any email domain |
| `--skip-provider-button=true` | — | Skip provider selection → auto-redirect to Keycloak |
| `--redirect-url` | `https://{host}/oauth2/callback` | OAuth callback URL (registered in Keycloak) |
| `--upstream` | `http://127.0.0.1:{PORT}` | Backend application address |
| `--http-address` | `0.0.0.0:4180` | oauth2-proxy listen port |

## Service Integration

The chart's `service.yaml` dynamically selects the target port:

```yaml
targetPort: {{ if .Values.oauth2.enabled }}oauth2{{ else }}http{{ end }}
```

- **oauth2 enabled**: Service routes to container port 4180 (oauth2-proxy)
- **oauth2 disabled**: Service routes to the application's container port

This means the Ingress always targets the same service port — the routing decision is internal to the service.

## Enabling OAuth2

Enable oauth2-proxy during Helm install/upgrade:

```bash
helm upgrade --install {service} ./helmfile/charts/{service} \
  --set oauth2.enabled=true \
  --set oauth2.clientSecret=<keycloak-client-secret> \
  --set oauth2.cookieSecret=$(openssl rand -hex 16) \
  --set oauth2.oidcIssuerUrl=https://id.YOUR_DOMAIN/realms/opendesk
```

Or set in a values file:

```yaml
oauth2:
  enabled: true
  clientSecret: "your-client-secret"
  cookieSecret: "aabbccddeeff...32hexchars"
  oidcIssuerUrl: "https://id.opendesk.example.com/realms/opendesk"
```

## Cookie Secret

The `--cookie-secret` is used to encrypt session cookies.

- Must be **16, 24, or 32 bytes** (32, 48, or 64 hex characters)
- Generate: `openssl rand -hex 16` (produces 32 hex chars = 16 bytes)
- Must be **stable across pod restarts** (users lose sessions otherwise)
- Store as a Kubernetes Secret, never hardcode in values files

**Important**: If cookie secret changes, all existing sessions become invalid.

## Keycloak Client Setup

Each service needs an OIDC client in Keycloak:

1. In the Keycloak admin console, open the `opendesk` realm
2. Create a new client:
   - **Client ID**: `opendesk-{service}` (e.g., `opendesk-rstudio`)
   - **Client protocol**: `openid-connect`
   - **Enabled**: `ON`
3. Set **Valid Redirect URIs**:
   - `https://{service}.{domain}/*`
   - `https://{service}.{domain}/oauth2/callback`
4. Under **Credentials** tab, copy the **Client Secret**
5. Configure **Access Type**: `confidential`

## Upstream Service Ports

Each service's oauth2-proxy must point to the correct local port:

| Service | Internal Port | Image |
|---------|---------------|-------|
| RStudio | 8787 | `rocker/rstudio` |
| ttyd | 7681 | `tsl0922/ttyd` |
| Slidev | 80 | `nginx:alpine` |
| code-server | 8080 | `codercom/code-server` |
| collab-dashboard | 80 | `weissto/collab-dashboard` |

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| **502 Bad Gateway** | oauth2-proxy can't reach upstream app | Check `--upstream` port matches `service.port` |
| **Too many redirects** | Cookie secret mismatch across restarts | Set a stable `--cookie-secret` |
| **Login loop** | Redirect URI mismatch | Match `--redirect-url` exactly to Keycloak's registered URI |
| **"email domain not allowed"** | `--email-domain` not set | Add `--email-domain=*` |
| **Blank page after login** | App not configured for trusted proxy | oauth2-proxy sets `X-Auth-Request-*` headers correctly |
| **401 after successful login** | `--set-authorization-header=true` missing | Add the flag to forward Bearer token |

## Template Reference

The oauth2-proxy sidecar is defined inline in each chart's `deployment.yaml`:

```yaml
{{- if .Values.oauth2.enabled }}
- name: oauth2-proxy
  image: quay.io/oauth2-proxy/oauth2-proxy:v7.6.0
  args:
    - --provider={{ .Values.oauth2.provider }}
    - --client-id={{ .Values.oauth2.clientId }}
    - --client-secret={{ .Values.oauth2.clientSecret }}
    - --oidc-issuer-url={{ .Values.oauth2.oidcIssuerUrl }}
    - --cookie-secret={{ .Values.oauth2.cookieSecret }}
    - --scope=openid,email,profile
    - --set-authorization-header=true
    - --set-xauthrequest=true
    - --email-domain=*
    - --skip-provider-button=true
    - --redirect-url=https://{{ (index .Values.ingress.hosts 0).host }}/oauth2/callback
    - --upstream=http://127.0.0.1:{{ .Values.service.port }}
    - --http-address=0.0.0.0:4180
  ports:
    - containerPort: 4180
      protocol: TCP
      name: oauth2
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 256Mi
{{- end }}
```

## Default Values

Each chart provides these defaults in `values.yaml`:

```yaml
oauth2:
  enabled: false
  provider: "keycloak-oidc"
  clientId: "opendesk-{service}"
  clientSecret: ""
  oidcIssuerUrl: "https://id.opendesk.example.com/realms/opendesk"
  cookieSecret: ""
```

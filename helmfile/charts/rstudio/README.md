# RStudio Server

RStudio Server Helm chart for openDesk Edu — runs RStudio in a container with optional Keycloak SSO via oauth2-proxy and OpenCloud storage integration.

## Configuration

### Basic

| Parameter | Default | Description |
|-----------|---------|-------------|
| `image.repository` | `rocker/rstudio` | Docker image |
| `image.tag` | `4.4.2` | Image tag |
| `service.port` | `8787` | RStudio listen port |
| `ingress.hosts[0].host` | `r.opendesk.example.com` | Ingress hostname |
| `persistence.size` | `10Gi` | Workspace volume size |

### OAuth2 / Keycloak SSO

Enable with `oauth2.enabled=true`. Requires client secret and cookie secret:

```bash
helm upgrade --install rstudio . \
  --set oauth2.enabled=true \
  --set oauth2.clientSecret=<keycloak-client-secret> \
  --set oauth2.cookieSecret=$(openssl rand -hex 16) \
  --set oauth2.oidcIssuerUrl=https://id.example.com/realms/opendesk
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `oauth2.enabled` | `false` | Enable oauth2-proxy sidecar |
| `oauth2.clientId` | `opendesk-rstudio` | Keycloak client ID |
| `oauth2.clientSecret` | `""` | Keycloak client secret |
| `oauth2.oidcIssuerUrl` | `https://id.opendesk.example.com/realms/opendesk` | OIDC issuer URL |
| `oauth2.cookieSecret` | `""` | 16/24/32 byte hex secret |

### OpenCloud Storage

Mount OpenCloud files via rclone sidecar:

```yaml
opencloud:
  enabled: true
  url: "https://opencloud.example.com"
  username: "demo"
  password: "demo"
  syncInterval: "60s"
```

## Architecture

```
User → HTTPS → Ingress → oauth2-proxy:4180 → RStudio:8787
                                              ↕ rclone (OpenCloud sync)
```
# ttyd — Web Terminal

Browser-based Linux terminal using [tsl0922/ttyd](https://github.com/tsl0922/ttyd) with optional Keycloak SSO.

## Configuration

### Basic

| Parameter | Default | Description |
|-----------|---------|-------------|
| `image.repository` | `tsl0922/ttyd` | Docker image |
| `image.tag` | `1.7.7` | Image tag |
| `service.port` | `7681` | Web terminal port |
| `ingress.hosts[0].host` | `term.opendesk.example.com` | Ingress hostname |

### OAuth2 / Keycloak SSO

```bash
helm upgrade --install ttyd . \
  --set oauth2.enabled=true \
  --set oauth2.clientSecret=<keycloak-client-secret> \
  --set oauth2.cookieSecret=$(openssl rand -hex 16) \
  --set oauth2.oidcIssuerUrl=https://id.example.com/realms/opendesk
```

## Architecture

```
User → Ingress → oauth2-proxy:4180 → ttyd:7681 → /bin/bash
```
# code-server — VS Code in the Browser

Runs [coder/code-server](https://github.com/coder/code-server) with optional Keycloak SSO.

## Configuration

### Basic

| Parameter | Default | Description |
|-----------|---------|-------------|
| `image.repository` | `codercom/code-server` | Docker image |
| `image.tag` | `4.96.2` | Image tag |
| `service.port` | `8080` | Web IDE port |
| `ingress.hosts[0].host` | `code.opendesk.example.com` | Ingress hostname |
| `persistence.size` | `5Gi` | Workspace volume size |

### OAuth2 / Keycloak SSO

```bash
helm upgrade --install code-server . \
  --set oauth2.enabled=true \
  --set oauth2.clientSecret=<keycloak-client-secret> \
  --set oauth2.cookieSecret=$(openssl rand -hex 16) \
  --set oauth2.oidcIssuerUrl=https://id.example.com/realms/opendesk
```

## Architecture

```
User → oauth2-proxy:4180 → code-server:8080
```
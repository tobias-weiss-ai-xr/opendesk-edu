# Slidev — Markdown Presentations

Serves [Slidev](https://sli.dev/) presentations via nginx with optional Keycloak SSO.

By default serves a static nginx landing page. Mount pre-built Slidev output (`dist/` contents) to `/usr/share/nginx/html` via persistence.

## Configuration

### Basic

| Parameter | Default | Description |
|-----------|---------|-------------|
| `ingress.hosts[0].host` | `slides.opendesk.example.com` | Ingress hostname |
| `persistence.enabled` | `true` | Enable PVC for slides |
| `persistence.size` | `1Gi` | Volume size |

### OAuth2 / Keycloak SSO

```bash
helm upgrade --install slidev . \
  --set oauth2.enabled=true \
  --set oauth2.clientSecret=<keycloak-client-secret> \
  --set oauth2.cookieSecret=$(openssl rand -hex 16) \
  --set oauth2.oidcIssuerUrl=https://id.example.com/realms/opendesk
```

## Usage

To serve custom slides:
1. Build slides: `npx slidev build --out dist`
2. Copy `dist/*` to the PVC mount path
3. Restart the pod
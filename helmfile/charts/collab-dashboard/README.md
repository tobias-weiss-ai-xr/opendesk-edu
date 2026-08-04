# Collab Dashboard

Feature catalog SPA showing all collab-services with CoCalc feature mapping. Built with React, Vite, TypeScript and Tailwind CSS.

## Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `image.repository` | `weissto/collab-dashboard` | Docker image |
| `image.tag` | `latest` | Image tag |
| `ingress.hosts[0].host` | `collab.opendesk.example.com` | Ingress hostname |

### OAuth2 / Keycloak SSO

```bash
helm upgrade --install collab-dashboard . \
  --set oauth2.enabled=true \
  --set oauth2.clientSecret=<keycloak-client-secret> \
  --set oauth2.cookieSecret=$(openssl rand -hex 16) \
  --set oauth2.oidcIssuerUrl=https://id.example.com/realms/opendesk
```

## Development

```bash
cd ../../collab-dashboard
npm install
npm run dev
```

## Building

```bash
cd ../../collab-dashboard
docker build -t weissto/collab-dashboard:latest .
docker push weissto/collab-dashboard:latest
```
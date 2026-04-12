# Planka

A Helm chart for deploying [Planka](https://planka.cloud/) (v2.1) project management / Kanban board with PostgreSQL and optional OIDC/Keycloak authentication.

## Prerequisites

- Kubernetes 1.29+
- Helm 3
- PV provisioner supporting ReadWriteMany access mode

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/planka \
  --set planka.baseUrl="https://planka.example.com"
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `planka.image` | Planka container image | `ghcr.io/plankanban/planka` |
| `planka.tag` | Image tag | `latest` |
| `planka.port` | Container port | `1337` |
| `planka.baseUrl` | Public base URL (required) | `""` |
| `planka.defaultEmail` | Default admin email | `""` |
| `planka.oidc.clientId` | OIDC client ID | `""` |
| `planka.oidc.authEndpoint` | OIDC authorization endpoint | `""` |
| `planka.oidc.tokenEndpoint` | OIDC token endpoint | `""` |
| `planka.volumes.data.size` | Data volume size | `1Gi` |
| `planka.resources.requests.cpu/memory` | Pod resource requests | `100m / 256Mi` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.hosts[0].host` | Ingress hostname | `planka.opendesk.example.com` |
| `postgresql.enabled` | Deploy bundled PostgreSQL | `true` |

### OIDC / Keycloak Integration

```bash
helm install my-release opendesk-edu/planka \
  --set planka.oidc.clientId="planka" \
  --set planka.oidc.authEndpoint="https://keycloak.example.com/realms/opendesk/protocol/openid-connect/auth" \
  --set planka.oidc.tokenEndpoint="https://keycloak.example.com/realms/opendesk/protocol/openid-connect/token" \
  --set planka.oidc.userinfoEndpoint="https://keycloak.example.com/realms/opendesk/protocol/openid-connect/userinfo"
```

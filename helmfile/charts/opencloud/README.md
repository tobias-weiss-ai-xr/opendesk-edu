# OpenCloud

A Helm chart for deploying [OpenCloud](https://www.opencloud.eu/) file sync and share server with OIDC authentication.

## Prerequisites

- Kubernetes 1.29+
- Helm 3
- PV provisioner supporting ReadWriteMany access mode
- A Keycloak instance for OIDC authentication

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/opencloud \
  --set oidc.clientSecret="<your-client-secret>" \
  --set jwtSecret="<random-secret>" \
  --set transferSecret="<random-secret>"
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | Container image repository | `<your-org>/opencloud` |
| `image.tag` | Image tag | `v1.0.0` |
| `oidc.issuer` | OIDC issuer URL | `https://id.opendesk.example.com/realms/opendesk` |
| `oidc.clientId` | OIDC client ID | `opendesk-opencloud` |
| `oidc.clientSecret` | OIDC client secret (required) | `""` |
| `oidc.autoProvisionAccounts` | Auto-create user accounts on first login | `true` |
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.size` | Storage size | `100Gi` |
| `logLevel` | Application log level | `info` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.hosts[0].host` | Ingress hostname | `opencloud.opendesk.example.com` |

### Secrets

The following secrets must be provided for production deployments:
- `oidc.clientSecret` — Keycloak client secret
- `jwtSecret` — JSON Web Token signing secret
- `transferSecret` — Inter-service transfer secret
- `machineAuthApiKey` — Machine-to-machine auth key
- `systemUserApiKey` — System user API key

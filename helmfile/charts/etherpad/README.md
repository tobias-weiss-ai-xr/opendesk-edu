# Etherpad

A Helm chart for deploying [Etherpad](https://etherpad.org/) (v1.9.9) collaborative real-time editor with PostgreSQL backend.

## Prerequisites

- Kubernetes 1.29+
- Helm 3
- PV provisioner supporting ReadWriteMany access mode

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/etherpad
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `etherpad.image` | Etherpad container image | `etherpad/etherpad` |
| `etherpad.tag` | Image tag | `1.9.9` |
| `etherpad.port` | Container port | `9001` |
| `etherpad.db.host` | PostgreSQL host | `""` (auto-set by subchart) |
| `etherpad.db.user` | Database username | `etherpad` |
| `etherpad.db.name` | Database name | `etherpad` |
| `etherpad.volumes.data.size` | Data volume size | `1Gi` |
| `etherpad.resources.requests.cpu/memory` | Pod resource requests | `100m / 256Mi` |
| `replicas` | Number of replicas | `1` |
| `ingress.enabled` | Enable ingress | `false` |
| `postgresql.enabled` | Deploy bundled PostgreSQL | `true` |

### Enable Ingress

```bash
helm install my-release opendesk-edu/etherpad \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=etherpad.example.com
```

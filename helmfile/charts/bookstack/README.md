# BookStack

A Helm chart for deploying [BookStack](https://www.bookstackapp.com/) (v26.03) knowledge base / wiki platform with MariaDB.

## Prerequisites

- Kubernetes 1.29+
- Helm 3
- PV provisioner supporting ReadWriteMany access mode

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/bookstack
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `bookstack.image` | BookStack container image | `linuxserver/bookstack` |
| `bookstack.tag` | Image tag | `latest` |
| `bookstack.port` | Container port | `80` |
| `bookstack.db.host` | MariaDB host | `""` (auto-set by subchart) |
| `bookstack.db.user` | Database username | `bookstack` |
| `bookstack.db.name` | Database name | `bookstack` |
| `bookstack.volumes.uploads.size` | Uploads volume size | `1Gi` |
| `bookstack.resources.requests.cpu/memory` | Pod resource requests | `100m / 256Mi` |
| `bookstack.replicas` | Number of replicas | `1` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.hosts[0].host` | Ingress hostname | `wiki.opendesk.example.com` |
| `mariadb.enabled` | Deploy bundled MariaDB | `true` |

### Custom Database Credentials

```bash
helm install my-release opendesk-edu/bookstack \
  --set mariadb.auth.password="<db-password>"
```

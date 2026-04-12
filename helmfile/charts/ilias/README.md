# ILIAS LMS

A Helm chart for deploying [ILIAS](https://www.ilias.de/) (v9) learning management system with MariaDB and an optional Lucene RPC search server.

## Prerequisites

- Kubernetes 1.29+
- Helm 3
- PV provisioner for persistent storage (ReadWriteMany)

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/ilias
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

The following table summarizes the key configuration parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ilias.image` | ILIAS container image | `srsolutions/ilias` |
| `ilias.tag` | Image tag | `9-php8.2-apache` |
| `ilias.autoSetup` | Run ILIAS setup on first start | `true` |
| `ilias.rootPassword` | ILIAS root account password | `""` |
| `ilias.timezone` | Server timezone | `Europe/Berlin` |
| `ilias.maxUploadSize` | Maximum upload file size | `200M` |
| `ilias.memoryLimit` | PHP memory limit | `4096M` |
| `ilias.clientName` | ILIAS client identifier | `default` |
| `iliasRPCServer.enabled` | Enable Lucene RPC search server | `true` |
| `ilias.volumes.data.size` | ILIAS data volume size | `4Gi` |
| `ilias.volumes.iliasdata.size` | ILIAS data directory volume size | `4Gi` |
| `ilias.resources.requests.cpu/memory` | Pod resource requests | `200m / 4G` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.hosts[0].host` | Ingress hostname | `lms.opendesk.example.com` |
| `mariadb.enabled` | Deploy bundled MariaDB | `true` |
| `mariadbgalera.enabled` | Deploy MariaDB Galera cluster (HA) | `false` |
| `mariadbBackup.enabled` | Enable scheduled DB backups | `true` |

### MariaDB Galera (HA)

For high-availability database deployments, enable the Galera subchart and disable the single-node MariaDB:

```bash
helm install my-release opendesk-edu/ilias \
  --set mariadb.enabled=false \
  --set mariadbgalera.enabled=true \
  --set mariadbgalera.rootUser.password="<password>"
```

### Specifying Custom Values

```bash
helm install my-release opendesk-edu/ilias -f my-values.yaml
```

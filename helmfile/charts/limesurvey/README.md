# LimeSurvey

A Helm chart for deploying [LimeSurvey](https://www.limesurvey.org/) (v6.6) online survey and questionnaire tool with MariaDB.

## Prerequisites

- Kubernetes 1.29+
- Helm 3
- PV provisioner supporting ReadWriteMany access mode

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/limesurvey
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `limesurvey.image` | LimeSurvey container image | `martialblog/limesurvey` |
| `limesurvey.tag` | Image tag | `latest` |
| `limesurvey.port` | Container port | `80` |
| `limesurvey.db.host` | MariaDB host | `""` (auto-set by subchart) |
| `limesurvey.db.user` | Database username | `limesurvey` |
| `limesurvey.db.name` | Database name | `limesurvey` |
| `limesurvey.db.tablePrefix` | Database table prefix | `lime_` |
| `limesurvey.siteName` | Site display name | `LimeSurvey` |
| `limesurvey.adminEmail` | Admin email | `admin@opendesk.example.com` |
| `limesurvey.timezone` | Server timezone | `Europe/Berlin` |
| `limesurvey.volumes.upload.size` | Upload volume size | `1Gi` |
| `limesurvey.resources.requests.cpu/memory` | Pod resource requests | `100m / 256Mi` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.hosts[0].host` | Ingress hostname | `survey.opendesk.example.com` |
| `mariadb.enabled` | Deploy bundled MariaDB | `true` |

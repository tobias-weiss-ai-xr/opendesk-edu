# Moodle LMS

A Helm chart for deploying [Moodle](https://moodle.org/) (v4.4) learning management system with SAML/SSO support.

## Prerequisites

- Kubernetes 1.29+
- Helm 3
- PV provisioner supporting ReadWriteMany access mode

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/moodle
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `moodle.image` | Moodle container image | `ghcr.io/<your-org>/moodle-shib` |
| `moodle.tag` | Image tag | `v1.4.0` |
| `moodle.replicaCount` | Number of replicas | `2` |
| `moodle.moodleUsername` | Admin username | `admin` |
| `moodle.moodlePassword` | Admin password | `""` |
| `moodle.moodleSiteName` | Site name | `openDesk Moodle` |
| `moodle.volumes.data.size` | Data volume size | `100Gi` |
| `moodle.resources.requests.cpu/memory` | Pod resource requests | `500m / 1G` |
| `moodle.persistence.enabled` | Enable persistence | `true` |
| `moodle.persistence.size` | Persistent storage size | `8Gi` |
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.hosts[0].host` | Ingress hostname | `moodle.opendesk.example.com` |

### Example: Enable Ingress

```bash
helm install my-release opendesk-edu/moodle \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=moodle.example.com
```

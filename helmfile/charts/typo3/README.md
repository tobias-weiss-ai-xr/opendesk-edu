# TYPO3 CMS

A Helm chart for deploying [TYPO3 CMS](https://typo3.org/) (v13) with an optional MariaDB database backend.

## Prerequisites

- Kubernetes 1.29+
- Helm 3
- PV provisioner for persistent storage (ReadWriteOnce)

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/typo3
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `typo3.image` | TYPO3 container image | `ghcr.io/tobias-weiss-ai-xr/typo3` |
| `typo3.tag` | Image tag | `13.4.0-php8.4-apache` |
| `typo3.replicas` | Number of replicas | `1` |
| `typo3.resources` | Pod resource requests/limits | `{}` |
| `mariadb.enabled` | Deploy bundled MariaDB | `true` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.hosts[0].host` | Ingress hostname | `""` |

### Specifying Custom Values

```bash
helm install my-release opendesk-edu/typo3 -f my-values.yaml
```

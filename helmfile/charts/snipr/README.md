# SNIpR

A Helm chart for the [SNIpR](https://github.com/lanbugs/snipr) lecture recording system — a Rust-based, lightweight solution for recording and processing lecture content.

## Prerequisites

- Kubernetes 1.29+
- Helm 3
- PV provisioner for persistent storage (ReadWriteOnce)

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/snipr
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `snipr.image` | SNIpR container image | `ghcr.io/tobias-weiss-ai-xr/snipr` |
| `snipr.tag` | Image tag | `latest` |
| `snipr.replicaCount` | Number of replicas | `1` |
| `snipr.resources` | Pod resource requests/limits | `{}` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.hosts[0].host` | Ingress hostname | `""` |

### Specifying Custom Values

```bash
helm install my-release opendesk-edu/snipr -f my-values.yaml
```

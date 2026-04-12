# Draw.io (diagrams.net)

A Helm chart for deploying [Draw.io](https://www.drawio.com/) (v29.6) diagramming and whiteboarding application.

## Prerequisites

- Kubernetes 1.29+
- Helm 3

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/drawio
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `drawio.image` | Draw.io container image | `jgraph/drawio` |
| `drawio.tag` | Image tag | `latest` |
| `drawio.port` | Container port | `8080` |
| `drawio.resources.requests.cpu/memory` | Pod resource requests | `200m / 512Mi` |
| `drawio.resources.limits.cpu/memory` | Pod resource limits | `1 / 2Gi` |
| `ingress.enabled` | Enable ingress | `false` |

### Enable Ingress

```bash
helm install my-release opendesk-edu/drawio \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=drawio.example.com
```

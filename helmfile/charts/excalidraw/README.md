# Excalidraw

A Helm chart for deploying [Excalidraw](https://excalidraw.com/) virtual whiteboard for collaborative sketching and diagramming.

## Prerequisites

- Kubernetes 1.29+
- Helm 3

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/excalidraw
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `excalidraw.image` | Excalidraw container image | `excalidraw/excalidraw` |
| `excalidraw.tag` | Image tag | `latest` |
| `excalidraw.port` | Container port | `80` |
| `excalidraw.resources.requests.cpu/memory` | Pod resource requests | `50m / 64Mi` |
| `excalidraw.resources.limits.cpu/memory` | Pod resource limits | `200m / 256Mi` |
| `ingress.enabled` | Enable ingress | `false` |

### Enable Ingress

```bash
helm install my-release opendesk-edu/excalidraw \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=excalidraw.example.com
```

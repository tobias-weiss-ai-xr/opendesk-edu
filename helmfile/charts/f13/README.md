# F13

A Helm chart for the [F13](https://github.com/TobiasWeissAI-xR/f13) sovereign AI assistant with chat, summarization, RAG, and transcription services.

## Prerequisites

- Kubernetes 1.29+
- Helm 3
- PV provisioner for persistent storage (ReadWriteOnce)

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/f13
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `f13.image` | F13 container image | `ghcr.io/tobias-weiss-ai-xr/f13` |
| `f13.tag` | Image tag | `latest` |
| `f13.replicaCount` | Number of replicas | `1` |
| `f13.resources` | Pod resource requests/limits | `{}` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.hosts[0].host` | Ingress hostname | `""` |

### Specifying Custom Values

```bash
helm install my-release opendesk-edu/f13 -f my-values.yaml
```

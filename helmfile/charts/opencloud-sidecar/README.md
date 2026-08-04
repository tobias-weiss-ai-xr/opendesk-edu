# OpenCloud Sidecar

Standalone rclone deployment that syncs files from OpenCloud WebDAV storage to a PVC. Use when you need OpenCloud storage accessible across multiple pods or as a shared volume.

## Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `opencloud.url` | `https://opencloud.opendesk.example.com` | OpenCloud server URL |
| `opencloud.username` | `""` | OpenCloud username |
| `opencloud.password` | `""` | OpenCloud password |
| `opencloud.remotePath` | `/` | Remote path to sync |
| `opencloud.syncInterval` | `60s` | Sync interval |
| `persistence.size` | `10Gi` | PVC size |

## Relationship to Inline Sidecar

For single-service OpenCloud access, use the inline rclone sidecar pattern in each chart:

```yaml
opencloud:
  enabled: true
  url: "https://opencloud.example.com"
  username: "demo"
  password: "demo"
```

This standalone chart provides a **shared** sync point when multiple services need access to the same OpenCloud data.
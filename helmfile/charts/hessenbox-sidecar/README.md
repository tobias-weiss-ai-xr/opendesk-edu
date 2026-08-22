# hessenbox-sidecar

A Helm chart for adding next.hessenbox storage sync to collab services via rclone sidecar.

## Overview

This chart provides a reusable sidecar container that syncs files between next.hessenbox (Nextcloud) and a local directory in the service pod. It enables transparent access to next.hessenbox storage from services like code-server, RStudio, JupyterHub, and Slidev.

## Prerequisites

- Kubernetes 1.29+
- Helm 3
- Access to next.hessenbox (https://next.hessenbox.de)
- Valid credentials (username + app password or OIDC token)

## Installing the Chart

This chart is designed to be used as a **library chart** (subchart) within other service charts.

### As a Subchart

```yaml
# In your service's Chart.yaml
dependencies:
  - name: hessenbox-sidecar
    version: 0.1.0
    repository: file://../hessenbox-sidecar
```

Then run:
```bash
helm dependency update
```

### As a Standalone Chart (for testing)

```bash
helm install hessenbox-test ./hessenbox-sidecar \
  --set hessenbox.username="your-username" \
  --set hessenbox.password="your-app-password"
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | rclone container image | `rclone/rclone` |
| `image.tag` | rclone image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `hessenbox.url` | next.hessenbox WebDAV URL | `https://next.hessenbox.de/remote.php/dav` |
| `hessenbox.username` | next.hessenbox username | `""` (required) |
| `hessenbox.password` | next.hessenbox password or app token | `""` (required) |
| `hessenbox.remotePath` | Remote path in next.hessenbox | `/` |
| `hessenbox.syncInterval` | Sync interval in seconds | `60` |
| `hessenbox.bidirectional` | Enable bidirectional sync | `true` |
| `resources.requests.cpu` | CPU requests | `100m` |
| `resources.requests.memory` | Memory requests | `128Mi` |
| `resources.limits.cpu` | CPU limits | `500m` |
| `resources.limits.memory` | Memory limits | `512Mi` |

## Using with Services

### code-server Integration

Add to your code-server deployment:

```yaml
# In code-server/templates/deployment.yaml
spec:
  template:
    spec:
      containers:
        - name: code-server
          # ... existing code-server config ...
          volumeMounts:
            - name: hessenbox-data
              mountPath: /home/coder/project/hessenbox

        - name: hessenbox-sync
          image: rclone/rclone:latest
          command:
            - sh
            - -c
            - |
              mkdir -p ~/.config/rclone
              cat > ~/.config/rclone/rclone.conf << 'EOCONF'
[hessenbox]
type = webdav
url = https://next.hessenbox.de/remote.php/dav/files/{{ .Values.username }}
vendor = nextcloud
user = {{ .Values.username }}
pass = {{ .Values.password }}
EOCONF
              while true; do
                rclone sync hessenbox:/ /data/ -v --fast-list
                rclone sync /data/ hessenbox:/ -v --fast-list
                sleep 60
              done
          volumeMounts:
            - name: hessenbox-data
              mountPath: /data
      volumes:
        - name: hessenbox-data
          emptyDir: {}
```

## Security

### App Passwords

Recommended to use **app passwords** (application-specific passwords) instead of user passwords:
1. User logs into next.hessenbox
2. Goes to Settings → Security → App Passwords
3. Creates a new app password for "openDesk"
4. Uses this password in the sidecar config

### OIDC Token Exchange (Advanced)

For better security, consider implementing OIDC token exchange:
1. User authenticates with openDesk Keycloak
2. Service exchanges openDesk token for next.hessenbox token
3. Uses next.hessenbox token for WebDAV access

This requires:
- next.hessenbox OIDC support
- Token exchange endpoint
- Sidecar proxy for token management

## Troubleshooting

### Connection Issues

```bash
# Check if WebDAV endpoint is reachable
curl -v https://next.hessenbox.de/remote.php/dav/files/username/

# Test rclone config
rclone lsd hessenbox:
```

### Sync Issues

```bash
# Check sidecar logs
kubectl logs <pod-name> -c hessenbox-sync

# Check rclone version
kubectl exec <pod-name> -c hessenbox-sync -- rclone version
```

### Performance Issues

- Increase `syncInterval` to reduce load
- Use `--fast-list` flag for large directories
- Consider `--transfers` flag for parallel transfers

## Performance Considerations

- **Small directories (<100 files):** Bidirectional sync every 60s is fine
- **Medium directories (100-1000 files):** Increase interval to 120-300s
- **Large directories (>1000 files):** Consider unidirectional sync or manual sync
- **Very large directories (>10000 files):** Not recommended for sidecar sync

## Limitations

1. **No offline access:** Files are synced on-demand, not cached offline
2. **No conflict resolution:** Last write wins in bidirectional sync
3. **No versioning:** Deleted files are permanently deleted
4. **Rate limits:** Subject to next.hessenbox API rate limits
5. **Network dependency:** Requires internet access to next.hessenbox

## License

Apache License 2.0 - see [LICENSE](../../LICENSE)

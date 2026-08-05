# OpenCloud Storage Integration for Collab Services

> **Design Doc** — 2026-05-27
> **Status:** Draft
> **MVP:** code-server + OpenCloud WebDAV sidecar

## 1. Overview

OpenCloud provides file storage via a CS3-compatible API with WebDAV access at
`/dav/files/{username}`. This design defines a reusable pattern to mount OpenCloud
storage as a shared volume inside collab-service pods.

## 2. Architecture

```
User → Browser (code-server)
         │
         ▼
┌─────────────────────┐
│  code-server Pod     │
│  ┌──────────┐       │
│  │ VS Code   │       │  /home/coder/project
│  │ container │───────┼──── shared emptyDir
│  └──────────┘       │
│  ┌──────────┐       │
│  │ rclone    │───────┼──── shared emptyDir
│  │ sidecar   │       │  syncs /dav/files/ → local
│  └──────────┘       │
└─────────────────────┘
         │
         ▼
  OpenCloud WebDAV
  https://opencloud.{domain}/dav/files/{user}
```

## 3. MVP: code-server + rclone sidecar

### Sidecar container

- Image: `rclone/rclone:latest`
- Syncs OpenCloud WebDAV to a shared emptyDir volume
- Runs `rclone sync` on a configurable interval (e.g., every 60s)
- Two-way sync (bi-directional) for full read/write

### Volume layout

```
/home/coder/project/     ← code-server workspace
  ├── opencloud/         ← synced from OpenCloud (shared volume)
  │   ├── documents/
  │   ├── notebooks/
  │   └── projects/
  └── (local workspace)
```

### Configuration

```yaml
opencloud:
  enabled: true
  url: "https://opencloud.{{ .Values.global.domain }}"
  insecure: false
  syncInterval: 60
  username: ""
  password: ""
  # or use app token
  token: ""
```

## 4. Reusable Helm Library Chart

The sidecar pattern will be extracted into a reusable library chart
`helmfile/charts/opencloud-sidecar/` that can be included by any service.

```yaml
# In a service's values.yaml
opencloud:
  enabled: true
  # ... sidecar config
```

## 5. Implementation Order

1. **MVP**: code-server + rclone sidecar (manual volume sync)
2. **Refine**: Extract into reusable library chart
3. **Rollout**: Apply to RStudio, JupyterHub, ttyd, Slidev
4. **Polish**: Add OAuth token exchange (automated auth via Keycloak)

## 6. Future: File Picker UI

For a full UX similar to the Nextcloud-OX integration, create a React component
that lists OpenCloud files and can be embedded in any service's UI. This would
use OpenCloud's WebDAV PROPFIND for directory listing and OIDC for auth.

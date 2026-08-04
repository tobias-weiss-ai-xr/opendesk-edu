# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0

# Lecture Recording Design Spec (v1.2)

> **Created:** 2026-04-15
> **Status:** Draft

## Purpose

Integrate SNIpR as the lecture recording platform for openDesk Edu, backed by SeaweedFS for cluster-internal S3 object storage. SNIpR handles capture, transcoding, and playback via its built-in Tauri web UI. SeaweedFS stores recordings as objects, exposing an S3-compatible API inside the cluster with no ingress. F13 provides automatic transcription via REST callback. The result is a minimal, self-contained recording stack that appears as a single portal tile in the openDesk "Anwendungen" category.

## Overview

SNIpR already has a Helm chart at `helmfile/charts/snipr/` with 12 templates covering deployment (3 containers: api, web, ffmpeg), service, ingress, secrets, and k8up backup scaffolding. Its `values.yaml` (182 lines) already contains placeholder sections for S3 storage, Keycloak OIDC SSO, LTI 1.3, F13 transcription, and k8up backup. The chart needs no template changes for v1.2. Only the values need updating to point storage at SeaweedFS instead of the default MinIO.

SeaweedFS requires a new chart. It runs three components: master (metadata), volume (data, backed by PVC), and an S3 gateway. All three are cluster-internal. No ingress, no external access.

The portal tile follows the same UDM `extraDataFiles` pattern used by ILIAS (line 1375 in `values-nubus.yaml.gotmpl`), Moodle (line 1425), and BBB (line 1480).

### Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Recording system | SNIpR (existing chart) | Chart already scaffolds SSO, LTI, storage, k8up. No new templates needed. |
| Video portal | SNIpR built-in Tauri web UI | No separate frontend. One service, one ingress. |
| Object storage | SeaweedFS (new chart) | S3-compatible, runs inside cluster, no external dependency. |
| Transcription | F13 (already running) | Config-only integration. SNIpR POSTs audio to F13, gets callback. |
| Portal tile | UDM extraDataFiles pattern | Same as BBB tile at `values-nubus.yaml.gotmpl` lines 1480-1533. |
| Scale target | < 50 concurrent recordings | Small/medium universities. Single SeaweedFS volume replica sufficient. |

## Architecture

```
  ILIAS / Moodle
       │
       │ LTI 1.3
       ▼
  ┌─────────────────────────────────────────────────┐
  │  SNIpR Pod                                       │
  │  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
  │  │ snipr-api│  │snipr-web │  │ ffmpeg-sidecar│  │
  │  │ (Rust)   │  │ (Tauri)  │  │ (transcoding) │  │
  │  │  :8080   │  │  :3000   │  │               │  │
  │  └────┬─────┘  └──────────┘  └───────────────┘  │
  │       │                                          │
  └───────┼──────────────────────────────────────────┘
          │
    ┌─────┼──────────────────┐
    │     │                  │
    │ S3  │                  │ REST callback
    │     ▼                  ▼
    │  ┌──────────────┐  ┌───────┐
    │  │  SeaweedFS   │  │  F13  │
    │  │  s3 gateway  │  │(trans-│
    │  │  :8333       │  │ cribe)│
    │  └──────┬───────┘  └───────┘
    │         │
    │  ┌──────┴───────┐
    │  │  SeaweedFS   │
    │  │  volume      │
    │  │  (PVC)       │
    │  └──────────────┘
    │
    │  ┌──────────────┐
    │  │  SeaweedFS   │
    │  │  master      │
    │  │  :9333       │
    │  └──────────────┘
    │
    └── Cluster-internal only (no ingress)

  Keycloak ──OIDC──▶ SNIpR (standard authorization code flow)
  Portal tile in "Anwendungen" category (UDM extraDataFiles)
```

### Data Flow

1. Instructor starts recording from ILIAS or Moodle via LTI 1.3 deep link
2. SNIpR captures audio/video through browser APIs (WebRTC/MediaRecorder)
3. Raw recording streams to SNIpR API, which writes it to SeaweedFS via S3 gateway (`http://seaweedfs-s3:8333`)
4. FFmpeg sidecar transcodes to web-playable formats (HLS, MP4)
5. SNIpR API sends audio track to F13 for transcription (REST POST to F13 endpoint)
6. F13 processes asynchronously and POSTs transcript back to SNIpR callback URL
7. Students access recordings through the SNIpR Tauri web UI (portal tile or LTI embed)

## SeaweedFS Chart

A new Helm chart at `helmfile/charts/seaweedfs/` with approximately 10 template files.

### Chart Structure

```
helmfile/charts/seaweedfs/
  Chart.yaml
  values.yaml
  templates/
    _helpers.tpl
    master-deployment.yaml
    master-service.yaml
    volume-statefulset.yaml
    volume-service.yaml
    s3-deployment.yaml
    s3-service.yaml
    configmap.yaml
    secret.yaml
```

### Components

| Component | Replicas | Port | Purpose |
|-----------|----------|------|---------|
| master | 1 | 9333 (gRPC), 9324 (HTTP) | Cluster metadata, volume assignment |
| volume | 1+ (default 1) | 8080 (gRPC) | Object storage, PVC-backed |
| s3 | 1 | 8333 (S3 API) | S3-compatible gateway |

### Default Values

**File:** `helmfile/charts/seaweedfs/values.yaml`

```yaml
master:
  replicaCount: 1
  image: chrislusf/seaweedfs
  tag: "3.78"
  resources:
    requests:
      cpu: "250m"
      memory: "512Mi"
    limits:
      cpu: "500m"
      memory: "1Gi"
  persistence:
    enabled: true
    size: 10Gi
    accessMode: ReadWriteOnce
    storageClass: local-path

volume:
  replicaCount: 1
  image: chrislusf/seaweedfs
  tag: "3.78"
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "1000m"
      memory: "2Gi"
  persistence:
    enabled: true
    size: 500Gi
    accessMode: ReadWriteMany
    storageClass: ceph-cephfs-hdd-ec
  maxVolumes: 32

s3:
  replicaCount: 1
  image: chrislusf/seaweedfs
  tag: "3.78"
  resources:
    requests:
      cpu: "250m"
      memory: "256Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"

ingress:
  enabled: false

s3:
  config:
    bucket: snipr-recordings

auth:
  enabled: true
  adminUser: admin
  adminPassword: ""  # Set via secrets
  accessKey: ""      # Set via secrets
  secretKey: ""      # Set via secrets
```

### SeaweedFS App Values

**File:** `helmfile/apps/seaweedfs/values.yaml.gotmpl`

```yaml
master:
  persistence:
    storageClass: {{ .Values.storageclasses.cephfs | default "ceph-cephfs-hdd-ec" | quote }}

volume:
  replicaCount: {{ .Values.apps.seaweedfs.volumeReplicas | default 1 }}
  persistence:
    size: {{ .Values.apps.seaweedfs.volumeSize | default "500Gi" | quote }}
    storageClass: {{ .Values.storageclasses.cephfs | default "ceph-cephfs-hdd-ec" | quote }}

auth:
  adminPassword: {{ .Values.secrets.seaweedfs.adminPassword | quote }}
  accessKey: {{ .Values.secrets.seaweedfs.accessKey | quote }}
  secretKey: {{ .Values.secrets.seaweedfs.secretKey | quote }}

s3:
  config:
    bucket: {{ .Values.apps.seaweedfs.bucket | default "snipr-recordings" | quote }}
```

### Service Endpoints (cluster-internal)

| Service | DNS | Port |
|---------|-----|------|
| S3 gateway | `seaweedfs-s3.default.svc.cluster.local` | 8333 |
| Master | `seaweedfs-master.default.svc.cluster.local` | 9333 |
| Volume | `seaweedfs-volume.default.svc.cluster.local` | 8080 |

No ingress is configured. SeaweedFS is reachable only from within the cluster.

## SNIpR Storage Configuration

The SNIpR chart already has an S3 storage section in `helmfile/charts/snipr/values.yaml` (lines 42-56). The deployment template at `helmfile/charts/snipr/templates/deployment.yaml` (lines 46-65) already injects `S3_ENDPOINT`, `S3_BUCKET`, `S3_ACCESS_KEY`, and `S3_SECRET_KEY` as environment variables from a Kubernetes secret. No template changes needed.

### Chart Values Update

**File:** `helmfile/charts/snipr/values.yaml` (lines 42-49, storage.s3 section)

```yaml
  storage:
    type: s3
    s3:
      endpoint: http://seaweedfs-s3:8333
      bucket: snipr-recordings
      region: ""
      ssl: false
      forcePathStyle: true
```

The key changes from the existing defaults:

- `endpoint`: changed from `https://minio.opendesk.example.com` to `http://seaweedfs-s3:8333` (cluster-internal, HTTP)
- `ssl`: changed from `true` to `false` (cluster-internal, no TLS termination)
- `forcePathStyle`: changed from `false` to `true` (SeaweedFS S3 requires path-style addressing, not virtual-hosted style)
- `region`: set to empty string (SeaweedFS does not use regions)

### App Values Update

**File:** `helmfile/apps/snipr/values.yaml.gotmpl` (lines 21-24, storage section)

```yaml
  # Storage configuration (SeaweedFS S3)
  storage:
    enabled: true
    endpoint: {{ .Values.services.seaweedfs.endpoint | default "http://seaweedfs-s3:8333" | quote }}
    bucket: {{ .Values.services.seaweedfs.bucket | default "snipr-recordings" | quote }}
```

The SeaweedFS credentials (`S3_ACCESS_KEY`, `S3_SECRET_KEY`) come from the SeaweedFS secret, referenced in the SNIpR deployment template at line 58-65 via `secretKeyRef`. The SNIpR secret must include the SeaweedFS access/secret keys.

### Existing SNIpR Sections (No Changes Needed)

These sections in `helmfile/charts/snipr/values.yaml` are already correctly scaffolded:

- **SSO** (lines 58-72): Keycloak OIDC with realm `opendesk`, clientId `snipr`, all standard endpoints
- **LTI 1.3** (lines 74-89): ILIAS and Moodle platform configs with instructor/learner roles
- **Transcription** (lines 91-103): F13 endpoint, model, language, callback URL
- **k8up backup** (lines 105-120): Schedule, retention, S3 backend

## Keycloak Client

SNIpR uses standard OIDC authorization code flow. The client configuration goes into the Keycloak bootstrap values.

### Client Configuration

**File:** `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl`

The SNIpR client is added as an OIDC client in the `opendesk.clients` section. It follows the same pattern as the Nextcloud OIDC client at lines 694-715.

```yaml
      {{ if .Values.apps.snipr.enabled }}
      - name: "snipr"
        clientId: "snipr"
        protocol: "openid-connect"
        clientAuthenticatorType: "client-secret"
        secret: {{ .Values.secrets.keycloak.clientSecret.snipr | quote }}
        redirectUris:
          - "https://snipr.{{ .Values.global.domain }}/*"
        rootUrl: "https://snipr.{{ .Values.global.domain }}"
        consentRequired: false
        frontchannelLogout: true
        publicClient: false
        authorizationServicesEnabled: false
        attributes:
          post.logout.redirect.uris: "https://snipr.{{ .Values.global.domain }}/*"
        defaultClientScopes:
          - "openid"
          - "profile"
          - "email"
      {{ end }}
```

### Client Access Restriction

To restrict SNIpR access to authorized users, add an entry in the `clientAccessRestrictions` section (following the pattern at lines 23-84):

```yaml
    {{- if .Values.apps.snipr.enabled }}
    snipr:
      client: "snipr"
      scope: "opendesk-snipr-scope"
      role: "opendesk-snipr-access-control"
      group: "managed-by-attribute-Lecturerecording"
    {{- end }}
```

### Precreate Groups

Add the access group to `precreateGroups` (around line 137):

```yaml
{{ if .Values.apps.snipr.enabled }}'managed-by-attribute-Lecturerecording',{{ end }}
```

### Backchannel Logout

SNIpR does not support OIDC backchannel logout. The client uses `frontchannelLogout: true`. This is consistent with how SNIpR's Rust/Actix-web API handles sessions: when the user's browser hits the Keycloak logout endpoint, the redirect clears the SNIpR session cookie.

## Portal Tile

SNIpR gets a portal tile in the "Anwendungen" category, following the BBB pattern at `values-nubus.yaml.gotmpl` lines 1480-1533.

### Tile Configuration

**File:** `helmfile/apps/nubus/values-nubus.yaml.gotmpl` (in the `extraDataFiles` section)

```yaml
      06-custom-snipr-portal-entry.yaml: |-
        # SPDX-License-Identifier: AGPL-3.0-only
        # SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH

        # SNIpR Lecture Recording Portal Entry
        # Creates a portal entry for SNIpR with SSO enabled
        # Ref: 05-custom-bbb-portal-entry.yaml for correct format
        ---
        action: "create"
        module: "portals/entry"
        position: "cn=entry,cn=portals,cn=univention,{{ .Values.ldap.baseDn }}"
        properties:
          name: "managementLecturerecording"
          activated: true
          anonymous: false
          linkTarget: "newwindow"
          displayName:
            de_DE: "Vorlesungsaufzeichnung"
            en_US: "Lecture Recording"
          description:
            de_DE: "Vorlesungsaufzeichnung mit automatischer Transkription"
            en_US: "Lecture recording with automatic transcription"
          link:
             - - "en_US"
               - "https://snipr.{{ .Values.global.domain }}"
             - - "de_DE"
               - "https://snipr.{{ .Values.global.domain }}"

        ---
        action: "modify"
        module: "portals/entry"
        position: "cn=managementLecturerecording,cn=entry,cn=portals,cn=univention,{{ .Values.ldap.baseDn }}"
        properties:
          linkTarget: "newwindow"

        ---
        action: "ensure_list_contains"
        module: "portals/category"
        position: "cn=od.applications,cn=category,cn=portals,cn=univention,{{ .Values.ldap.baseDn }}"
        properties:
          entries:
            - "cn=managementLecturerecording,cn=entry,cn=portals,cn=univention,{{ .Values.ldap.baseDn }}"
```

The `extraDataFile` key is `06-custom-snipr-portal-entry.yaml` (sequenced after `05-custom-bbb-portal-entry.yaml`). The tile name `managementLecturerecording` matches the Keycloak group `managed-by-attribute-Lecturerecording`.

## k8up Backup

Two separate backup schedules cover the recording stack.

### SNIpR Config Backup

SNIpR's configuration and database are small. A weekly backup via k8up is sufficient.

**File:** `helmfile/charts/snipr/values.yaml` (lines 106-120)

The existing k8up configuration already handles this. The schedule `0 3 * * 0` runs weekly at 03:00 on Sunday. Retention keeps 7 daily, 4 weekly, 12 monthly backups. The backup targets SNIpR config metadata only, not the recording files themselves.

### SeaweedFS Recordings Backup

Recording data is large (500 GiB PVC default). A daily incremental backup via k8up PreBackupPod handles this.

**File:** `helmfile/charts/seaweedfs/templates/prebackuppod.yaml` (new template in SeaweedFS chart)

```yaml
apiVersion: k8up.io/v1
kind: PreBackupPod
metadata:
  name: seaweedfs-backup
  labels:
    {{- include "seaweedfs.labels" . | nindent 4 }}
spec:
  backupCommand: /bin/sh -c "weed backup -master=localhost:9333 -backupDir=/backup"
  podCommand: /bin/sh -c "while true; do sleep 3600; done"
  podImage: "{{ .Values.volume.image }}:{{ .Values.volume.tag }}"
  podWorkDir: "/backup"
  resources:
    requests:
      cpu: "250m"
      memory: "512Mi"
    limits:
      cpu: "500m"
      memory: "1Gi"
```

The SeaweedFS chart values include k8up schedule configuration:

```yaml
backup:
  enabled: true
  k8up:
    schedule: "0 2 * * *"  # Daily at 02:00
    retention:
      daily: 7
      weekly: 4
      monthly: 3
```

## Implementation Files

The following table lists every file that needs creation or modification for v1.2. Files marked "Create" are new. Files marked "Modify" exist and need values updates only.

| # | File | Action | What Changes |
|---|------|--------|--------------|
| 1 | `helmfile/charts/seaweedfs/Chart.yaml` | Create | Chart metadata (apiVersion v2, name, version) |
| 2 | `helmfile/charts/seaweedfs/values.yaml` | Create | Default values for master, volume, s3, auth, backup |
| 3 | `helmfile/charts/seaweedfs/templates/_helpers.tpl` | Create | Standard Helm helpers (fullname, labels, selector) |
| 4 | `helmfile/charts/seaweedfs/templates/master-deployment.yaml` | Create | Master Deployment (1 replica, gRPC+HTTP ports, PVC for metadata) |
| 5 | `helmfile/charts/seaweedfs/templates/master-service.yaml` | Create | Master Service (ports 9333, 9324) |
| 6 | `helmfile/charts/seaweedfs/templates/volume-statefulset.yaml` | Create | Volume StatefulSet (1+ replicas, PVC for data, port 8080) |
| 7 | `helmfile/charts/seaweedfs/templates/volume-service.yaml` | Create | Volume Service (port 8080) |
| 8 | `helmfile/charts/seaweedfs/templates/s3-deployment.yaml` | Create | S3 gateway Deployment (1 replica, port 8333, connects to master) |
| 9 | `helmfile/charts/seaweedfs/templates/s3-service.yaml` | Create | S3 gateway Service (port 8333) |
| 10 | `helmfile/charts/seaweedfs/templates/configmap.yaml` | Create | SeaweedFS config file (master/volume/s3 config JSON) |
| 11 | `helmfile/charts/seaweedfs/templates/secret.yaml` | Create | S3 credentials (accessKey, secretKey, adminPassword) |
| 12 | `helmfile/charts/seaweedfs/templates/prebackuppod.yaml` | Create | k8up PreBackupPod for daily recording backup |
| 13 | `helmfile/apps/seaweedfs/values.yaml.gotmpl` | Create | App-level values with Go templating for domain, secrets, storage class |
| 14 | `helmfile/charts/snipr/values.yaml` | Modify | Lines 42-49: change storage.s3 to SeaweedFS endpoint, ssl=false, forcePathStyle=true |
| 15 | `helmfile/apps/snipr/values.yaml.gotmpl` | Modify | Lines 21-24: change storage endpoint/bucket to SeaweedFS references |
| 16 | `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl` | Modify | Add snipr OIDC client in clients section, clientAccessRestrictions entry, precreateGroups entry |
| 17 | `helmfile/apps/nubus/values-nubus.yaml.gotmpl` | Modify | Add `06-custom-snipr-portal-entry.yaml` extraDataFile after BBB entry (after line 1533) |
| 18 | `ROADMAP.md` | Modify | Mark v1.2 lecture recording items as complete |

Files 1-13 are the SeaweedFS chart (new). Files 14-15 update SNIpR storage values. Files 16-17 add Keycloak client and portal tile. File 18 updates the roadmap.

## Edge Cases

### SeaweedFS Disk Full

When the SeaweedFS volume PVC reaches capacity, writes from SNIpR fail with S3 `507 Insufficient Storage` errors.

**Detection:** The volume StatefulSet exposes Prometheus metrics via the `/stats/prometheus` HTTP endpoint. Set up a Prometheus alert on `volume_server_disk_free_bytes` falling below a threshold (e.g., 10% of total).

**Mitigation:**
- Monitor PVC usage via `kubectl top pvc` or Prometheus volume metrics
- Expand the PVC by increasing `.Values.volume.persistence.size` and re-running `helmfile apply`
- The k8up backup schedule rotates old recordings. Retention policy (7 daily, 4 weekly, 3 monthly) bounds total storage growth
- For immediate relief, delete old recordings through the SNIpR web UI (which sends S3 DELETE requests to SeaweedFS)

**SNIpR behavior on write failure:** The SNIpR API returns HTTP 503 to the recording client. The Tauri web UI shows a user-facing error: "Recording failed. Storage unavailable. Please try again later." Partial uploads are cleaned up on the SNIpR side (S3 multipart abort).

### SNIpR Crash During Recording

If the SNIpR pod crashes or is OOM-killed while a recording is in progress:

1. The in-progress recording stream is lost. S3 multipart uploads that were not completed remain as partial objects in SeaweedFS.
2. When the pod restarts (managed by the Deployment controller), SNIpR reconciles its state. It scans the S3 bucket for incomplete multipart uploads and aborts them.
3. Any recording segments that were already finalized (transcoded to MP4/HLS) remain accessible.
4. The recording appears in the UI as "interrupted" with whatever content was saved before the crash.
5. The FFmpeg sidecar restarts with the pod. No orphaned transcoding processes.

**Kubernetes protection:** The SNIpR deployment has `podDisruptionBudget.minAvailable: 1` (line 164 in `values.yaml`), so at least one replica stays up during rolling updates. For a crash, the pod restarts within seconds based on the liveness probe (line 107: `/health` every 10s).

### F13 Unreachable

When the F13 transcription service is unavailable:

1. SNIpR POSTs the audio to the F13 endpoint and gets a connection error or timeout.
2. SNIpR marks the recording as "transcription pending" in its database. The recording itself is fully playable.
3. SNIpR retries transcription with exponential backoff (configurable, default 3 retries over 30 minutes).
4. If all retries fail, the recording appears in the UI without a transcript. The description shows "Transcription unavailable."
5. An admin can trigger manual re-transcription from the SNIpR UI when F13 is back online.

**No data loss:** Recordings are stored in SeaweedFS independent of transcription. Transcription is a best-effort enhancement, not a prerequisite for playback.

### SeaweedFS Master Failure

The master node holds cluster metadata. If it goes down:

1. Existing volume servers continue serving read requests from their local data.
2. New write allocations fail because the master assigns volume IDs.
3. The S3 gateway returns errors for new uploads.
4. Kubernetes restarts the master pod (single replica, Deployment with restartPolicy Always). Recovery takes 30-60 seconds.

**Mitigation for production:** Increase `master.replicaCount` to 3 for HA. The master uses Raft consensus, so a majority (2 of 3) must be available. For the v1.2 target scale (small/medium universities), a single master with fast Kubernetes recovery is acceptable.

### Concurrent Recording Limit

The design targets < 50 concurrent recordings. At this scale:

- **SNIpR:** 2 replicas (default), each handling ~25 concurrent sessions. Autoscaling enabled, max 10 replicas (line 159 in `values.yaml`).
- **SeaweedFS:** Single volume server with 500 GiB PVC. SeaweedFS volume servers handle thousands of concurrent small object writes efficiently.
- **FFmpeg:** The sidecar is shared per pod. With 2 default replicas, 2 concurrent transcoding jobs run at a time. The SNIpR API queues additional jobs. For higher concurrency, increase `replicaCount` or enable autoscaling.

### Large Recording Files

Individual lecture recordings can be 2-5 GB (2-hour lecture at high quality). SeaweedFS handles this via multipart upload:

1. SNIpR initiates a multipart upload to SeaweedFS S3
2. Chunks are uploaded as the recording progresses (streaming, not buffered)
3. On completion, SNIpR finalizes the multipart upload
4. FFmpeg transcoding reads from SeaweedFS and writes output formats back

SeaweedFS volume server default max file size is 256 MB per needle. Large files are split across multiple needles automatically by the volume server.

## Testing Plan

### Unit: SeaweedFS Chart Rendering

```bash
helm template seaweedfs helmfile/charts/seaweedfs/ \
  --values helmfile/apps/seaweedfs/values.yaml.gotmpl \
  | kubeconform /dev/stdin
```

Verify all templates render without errors. Check that no ingress resource is generated.

### Integration: S3 Connectivity

After deploying SeaweedFS and SNIpR:

```bash
# Verify SeaweedFS S3 endpoint from within the cluster
kubectl run aws-cli --rm -it --image amazon/aws-cli -- \
  aws s3 --endpoint-url http://seaweedfs-s3:8333 \
    --no-verify-ssl ls s3://snipr-recordings/

# Verify SNIpR can write to SeaweedFS
kubectl exec -it deploy/snipr -- curl -f http://localhost:8080/health
```

### Integration: LTI Launch

1. Configure ILIAS to launch SNIpR as an LTI 1.3 tool (using `snipr-lti` client credentials)
2. Add a content link in an ILIAS course that launches SNIpR
3. Click the link, verify SNIpR opens in an iframe with the instructor's identity
4. Start a short test recording
5. Verify the recording appears in the SNIpR recording list
6. Verify the recording file exists in SeaweedFS via `aws s3 ls`

### Integration: Portal Tile

1. Deploy the updated `values-nubus.yaml.gotmpl` with the SNIpR portal entry
2. Log in to the openDesk portal
3. Verify the "Vorlesungsaufzeichnung" / "Lecture Recording" tile appears in "Anwendungen"
4. Click the tile, verify it opens `https://snipr.{domain}` in a new window
5. Verify SSO login works (no additional login prompt)

### Integration: Transcription

1. Create a short recording (30 seconds of speech)
2. Verify SNIpR sends the audio to F13 (check SNIpR API logs for POST to F13 endpoint)
3. Verify F13 processes the audio and calls back to SNIpR
4. Verify the transcript appears alongside the recording in the UI

### Integration: Backup and Restore

1. Create a recording, verify it exists in SeaweedFS
2. Trigger the k8up backup for SeaweedFS
3. Simulate data loss by deleting the PVC
4. Restore from backup
5. Verify recordings are playable

## Rollback

### Step 1: Remove Portal Tile

Delete the `06-custom-snipr-portal-entry.yaml` section from `helmfile/apps/nubus/values-nubus.yaml.gotmpl`. Redeploy Nubus.

### Step 2: Remove Keycloak Client

Delete the `snipr` client block and `clientAccessRestrictions.snipr` entry from `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl`. Remove the `managed-by-attribute-Lecturerecording` group from `precreateGroups`. Redeploy Keycloak bootstrap.

### Step 3: Revert SNIpR Storage

In `helmfile/charts/snipr/values.yaml`, change the storage section back:

```yaml
  storage:
    type: s3
    s3:
      endpoint: https://minio.opendesk.example.com
      bucket: snipr-recordings
      region: eu-central-1
      ssl: true
      forcePathStyle: false
```

### Step 4: Remove SeaweedFS

```bash
helmfile destroy -l app=seaweedfs
kubectl delete pvc -l app.kubernetes.io/name=seaweedfs
```

### Step 5: Redeploy

```bash
helmfile apply
```

### What Stays

- SNIpR chart and templates are unchanged. The rollback only touches values.
- Recordings stored in SeaweedFS are lost when the PVC is deleted. If retention is needed, migrate recordings to MinIO before rollback, or restore from k8up backup after SeaweedFS is re-deployed.
- F13 integration is config-only and causes no side effects when disabled.

## Security Considerations

### SeaweedFS Network Isolation

SeaweedFS has no ingress. It is reachable only from within the Kubernetes cluster via ClusterIP services. The S3 credentials (accessKey, secretKey) are stored in a Kubernetes Secret, not in plaintext values. NetworkPolicy can further restrict access to only the SNIpR pods:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: seaweedfs-s3-allow-snipr
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/component: s3
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: snipr
      ports:
        - port: 8333
```

### S3 Credentials

SeaweedFS S3 credentials are generated during chart installation and stored in a Kubernetes Secret. The SNIpR deployment references these via `secretKeyRef` (following the pattern at `deployment.yaml` lines 46-65). Credentials are never exposed in environment variables directly in the values files.

### LTI Security

SNIpR LTI 1.3 uses OAuth 2.0 client credentials with signed JWTs. The LTI client secret is stored in the SNIpR Kubernetes Secret. Launch requests are validated against the platform's (ILIAS/Moodle) public key.

### Recording Access Control

SNIpR enforces access control per recording:
- Recordings created through LTI inherit the course's enrollment. Only course members can view them.
- Recordings created directly in the SNIpR UI are owned by the authenticated user and can be shared explicitly.
- The Keycloak OIDC session provides the user identity. The `managed-by-attribute-Lecturerecording` group gates portal tile visibility.

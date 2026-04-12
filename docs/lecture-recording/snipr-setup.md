# SNIpR Lecture Recording Setup Guide

> **Version:** v1.2
> **Last Updated:** March 31, 2026
> **Status:** Production Ready

## Overview

SNIpR (Snip & Record) is a lightweight, Rust-based lecture recording solution designed for rapid deployment and resource efficiency. It provides:

- **Recording management** via REST API (Actix-web)
- **Web UI** for playback and search (Tauri)
- **Video transcoding** with FFmpeg
- **S3-compatible storage** (MinIO, AWS S3)
- **F13 transcription** integration
- **LTI 1.3** support for ILIAS/Moodle
- **Keycloak OIDC** SSO

### Architecture

```
┌─────────────────────────────────────────────────────┐
│                   SNIpR (Rust)                      │
│                                                     │
│  ┌─────────────┐    ┌─────────────┐                │
│  │  API Server │◄───┤   Web UI    │                │
│  │  (Actix)    │    │  (Tauri)    │                │
│  └──────┬──────┘    └─────────────┘                │
│         │                                          │
│  ┌──────▼──────┐                                   │
│  │  Recording  │                                   │
│  │  Service    │                                   │
│  └──────┬──────┘                                   │
│         │                                          │
│  ┌──────▼──────┐    ┌─────────────┐                │
│  │  Transcode  │───►│   S3 Blob   │                │
│  │  (FFmpeg)   │    │   Storage   │                │
│  └─────────────┘    └─────────────┘                │
└─────────────────────────────────────────────────────┘
                       │
               ┌───────▼────────┐
               │   F13 API      │
               │ (Transcription)│
               └────────────────┘
```

## Prerequisites

### Infrastructure

- **Kubernetes 1.28+** with Helm 3 and helmfile
- **Keycloak** configured with OIDC realm (see [DFN-AAI SAML Federation](../federation/dfn-aai-setup.md))
- **MinIO** or compatible S3 storage
- **F13 transcription service** (see [F13 Setup](../ai/f13-setup.md))

### Helmfile Configuration

Ensure the following components are enabled in `helmfile/environments/default/`:

```yaml
# global.yaml.gotmpl
apps:
  snipr:
    enabled: true
    transcription:
      enabled: true
    lti:
      enabled: true
      clientId: "snipr-lti"
    sso:
      clientId: "snipr"

services:
  minio:
    enabled: true
    endpoint: "https://minio.opendesk.example.com"
    bucket: "snipr-recordings"
  f13:
    endpoint: "https://f13.opendesk.example.com"
    model: "whisper-medium"
    language: "de"

resources:
  snipr:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "1000m"
      memory: "2Gi"

autoscaling:
  snipr:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
```

## Deployment

### Step 1: Configure Secrets

Create secrets for SNIpR in `helmfile/environments/default/secrets.yaml.gotmpl`:

```yaml
secrets:
  snipr:
    keycloakClientSecret: "${SNIPR_KEYCLOAK_SECRET}"
    ltiClientSecret: "${SNIPR_LTI_SECRET}"
    f13ApiKey: "${F13_API_KEY}"
    s3AccessKey: "${MINIO_ACCESS_KEY}"
    s3SecretKey: "${MINIO_SECRET_KEY}"
```

### Step 2: Deploy SNIpR

```bash
# Deploy SNIpR with all dependencies
helmfile -e default apply --until snipr

# Verify deployment
kubectl get pods -l component=snipr
kubectl get svc -l component=snipr
```

### Step 3: Verify Deployment

```bash
# Check pod status
kubectl get pods -n default -l component=snipr

# Expected output:
# snipr-api-xxxxx-xxxxx     1/1     Running
# snipr-web-xxxxx-xxxxx     1/1     Running
# snipr-ffmpeg-xxxxx-xxxxx  1/1     Running

# Test API endpoint
curl -k https://snipr.opendesk.example.com/api/health

# Expected response: {"status": "ok", "version": "v1.0.0"}
```

### Step 4: Configure Keycloak OIDC

1. Log into Keycloak Admin Console
2. Navigate to **Realm Settings** → **Clients**
3. Create new client: `snipr`
   - **Client ID:** `snipr`
   - **Client protocol:** `openid-connect`
   - **Valid redirect URIs:** `https://snipr.opendesk.example.com/*`
   - **Web origins:** `https://snipr.opendesk.example.com`
   - **Access type:** `Confidential`
   - **Service accounts enabled:** `ON`
4. Save and copy the **Client Secret**
5. Update `helmfile/environments/default/secrets.yaml.gotmpl` with the secret
6. Redeploy: `helmfile -e default apply --until snipr`

### Step 5: Configure MinIO Storage

1. Log into MinIO Console
2. Create bucket: `snipr-recordings`
3. Create access key with permissions:
   - `s3:GetObject`
   - `s3:PutObject`
   - `s3:DeleteObject`
   - `s3:ListBucket`
4. Copy **Access Key** and **Secret Key**
5. Update `helmfile/environments/default/secrets.yaml.gotmpl`
6. Redeploy: `helmfile -e default apply --until snipr`

## Configuration Options

### Storage Backend

**S3 (MinIO) - Recommended:**

```yaml
snipr:
  storage:
    type: s3
    endpoint: https://minio.opendesk.example.com
    bucket: snipr-recordings
    region: eu-central-1
    ssl: true
```

**Filesystem (Development):**

```yaml
snipr:
  storage:
    type: filesystem
    path: /var/snipr/recordings
    persistence:
      enabled: true
      size: 500Gi
      storageClass: ceph-cephfs-hdd-ec
```

### Transcription

**F13 (Production):**

```yaml
snipr:
  transcription:
    enabled: true
    f13:
      endpoint: https://f13.opendesk.example.com
      model: whisper-medium
      language: de
```

**Local Fallback (Development):**

```yaml
snipr:
  transcription:
    enabled: true
    fallback:
      enabled: true
      engine: local
      model: whisper-small
```

### Scaling

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

## Verification

### Health Checks

```bash
# API health
curl -k https://snipr.opendesk.example.com/api/health

# Storage connectivity
curl -k https://snipr.opendesk.example.com/api/storage/status

# Transcription service
curl -k https://snipr.opendesk.example.com/api/transcription/status
```

### Resource Usage

```bash
# Monitor resource usage
kubectl top pods -l component=snipr

# Expected baseline:
# snipr-api:    100m CPU, 512Mi RAM
# snipr-web:    50m CPU, 256Mi RAM
# snipr-ffmpeg: 200m CPU, 1Gi RAM (during transcoding)
```

## Troubleshooting

### Recording Upload Fails

**Symptom:** 500 error when uploading recordings

**Check:**

```bash
kubectl logs -l component=snipr -c snipr-api | grep -i "storage"
```

**Solution:** Verify MinIO credentials and bucket permissions

### Transcription Not Starting

**Symptom:** Recordings show "pending transcription"

**Check:**

```bash
kubectl logs -l component=snipr -c snipr-api | grep -i "f13"
```

**Solution:** Verify F13 API key and endpoint connectivity

### SSO Login Fails

**Symptom:** Redirect loop or "invalid client" error

**Check:**

```bash
kubectl logs -l component=snipr -c snipr-api | grep -i "oidc"
```

**Solution:** Verify Keycloak client configuration and redirect URIs

## Next Steps

- [LTI 1.3 Integration with ILIAS/Moodle](./snipr-lti-integration.md)
- [F13 Transcription Details](./snipr-transcription.md)
- [SNIpR API Reference](./snipr-api-reference.md)

---

**Related Documentation:**

- [F13 Transcription Setup](../ai/f13-setup.md)
- [Keycloak SSO Configuration](../federation/keycloak-setup.md)
- [MinIO Storage Setup](../storage/minio-setup.md)

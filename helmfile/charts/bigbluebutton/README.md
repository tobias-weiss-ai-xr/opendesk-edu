# BigBlueButton

A Helm chart for deploying [BigBlueButton](https://bigbluebutton.org/) Greenlight with SAML authentication and persistent recordings storage.

## Prerequisites

- Kubernetes 1.29+
- Helm 3
- An external BigBlueButton server or BBB API endpoint
- PV provisioner supporting ReadWriteMany access mode

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/bigbluebutton \
  --set bigbluebutton.greenlight.databaseUrl="postgresql://greenlight:password@release-name-postgresql:5432/greenlight"
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `bigbluebutton.image` | Greenlight container image | `ghcr.io/<your-org>/greenlight-saml` |
| `bigbluebutton.tag` | Image tag | `v1.3.0` |
| `bigbluebutton.replicaCount` | Number of replicas | `2` |
| `bigbluebutton.greenlight.databaseUrl` | PostgreSQL connection string (required) | `""` |
| `bigbluebutton.greenlight.defaultRegistration` | Default auth method | `saml` |
| `bigbluebutton.volumes.recordings.size` | Recordings storage size | `500Gi` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.hosts.host` | Ingress hostname | `bbb.opendesk.example.com` |

> **Note:** `bigbluebutton.greenlight.databaseUrl` is required. Provide a valid PostgreSQL connection string before deploying.

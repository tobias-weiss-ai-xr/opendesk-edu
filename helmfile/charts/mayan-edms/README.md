# Mayan EDMS Helm Chart

# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0

Mayan EDMS is a Free Open Source Document Management System for managing documents, metadata, workflows, OCR, and more.

## Features

- Document upload and versioning
- Metadata extraction and custom metadata types
- Optical Character Recognition (OCR)
- Workflow automation
- Access control and permissions
- Full-text search
- Document previews
- REST API

## Installation

```bash
helm repo add mayan-edms https://mayan-edms.github.io/mayan-edms/
helm install mayan-edms mayan-edms/mayan-edms
```

## Configuration

See [values.yaml](values.yaml) for configuration options.

### Key Configuration Areas

- **Authentication**: Configure OIDC with Keycloak
- **Storage**: Use SeaweedFS for S3-compatible storage
- **Database**: PostgreSQL (can use external or built-in)
- **Cache**: Redis for session caching
- **OCR**: Tesseract OCR for text extraction

## OIDC Authentication

Configure Keycloak client for Mayan EDMS:

1. Create OIDC client in Keycloak realm
2. Set client ID: `mayan-edms`
3. Set redirect URIs: `https://mayan.{{ .Values.global.domain }}/accounts/openid/login/callback/`
4. Enable Standard Flow
5. Add mappings for email, username, first_name, last_name

## Storage Configuration

Mayan EDMS supports S3-compatible storage:

```yaml
storage:
  backend: "storages.backends.s3boto3.S3Boto3Storage"
  options:
    bucket_name: "mayan-documents"
    endpoint_url: "http://seaweedfs-s3.opendesk.svc.cluster.local:8333"
    access_key: "{{ .Values.secrets.seaweedfs.accessKey }}"
    secret_key: "{{ .Values.secrets.seaweedfs.secretKey }}"
```

## Backup

Use k8up for backing up Mayan EDMS data:

```yaml
backup:
  enabled: true
  k8up:
    schedule: "0 2 * * *"
    retention:
      daily: 7
      weekly: 4
      monthly: 3
```

## License

Apache License 2.0

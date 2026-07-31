# Paperless-ngx Helm Chart

# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: GPL-3.0-or-later

Paperless-ngx is a document archiving system with OCR, tags, and automated processing.
It's perfect for managing student submissions, research papers, and administrative documents.

## Features

- Document upload and organization
- Automatic OCR (Optical Character Recognition)
- Full-text search
- Tag-based classification
- Automated processing rules
- Correspondent and document type detection
- REST API
- Mobile-friendly interface

## Installation

```bash
helm repo add paperless-ngx https://paperless-ngx.github.io/paperless-ngx/
helm install paperless-ngx paperless-ngx/paperless-ngx
```

## Configuration

See [values.yaml](values.yaml) for configuration options.

### Key Configuration Areas

- **Authentication**: Configure OIDC with Keycloak
- **Storage**: Use local filesystem or S3-compatible storage (SeaweedFS)
- **Database**: PostgreSQL (can use external or built-in)
- **Cache**: Redis for session caching
- **OCR**: Tesseract OCR for text extraction
- **Consumption**: Automated document processing pipeline

## OIDC Authentication

Paperless-ngx supports OIDC authentication via Django:

1. Install required package in container:
   ```
   pip install mozilla-django-oidc
   ```

2. Configure Keycloak client:
   - Client ID: `paperless-ngx`
   - Redirect URIs: `https://paperless.{{ .Values.global.domain }}/accounts/oidc/callback/`
   - Enable Standard Flow
   - Add mappings for email, username, first_name, last_name

3. Configure in values.yaml:
   ```yaml
   paperless:
     oidc:
       enabled: true
       issuer: "https://id.{{ .Values.global.domain }}/realms/{{ .Values.platform.realm }}"
       clientId: "paperless-ngx"
       clientSecret: "your-client-secret"
   ```

## Storage Configuration

Paperless-ngx can use S3-compatible storage for documents:

```yaml
paperless:
  storage:
    backend: "storages.backends.s3boto3.S3Boto3Storage"
    options:
      bucket_name: "paperless-documents"
      endpoint_url: "http://seaweedfs-s3.opendesk.svc.cluster.local:8333"
      access_key: "{{ .Values.secrets.seaweedfs.accessKey }}"
      secret_key: "{{ .Values.secrets.seaweedfs.secretKey }}"
```

## Automated Processing

Paperless-ngx has a powerful consumption pipeline:

- **File watching**: Automatically process new files in the consume folder
- **Email processing**: Fetch and process emails with attachments
- **OCR**: Automatic text extraction from images and PDFs
- **Classification**: Auto-assign tags, correspondents, and document types
- **Barcode detection**: Extract metadata from barcodes

## Backup

Use k8up for backing up Paperless-ngx data:

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

## Integration with Other openDesk Services

### Mayan EDMS
- Use Mayan for formal document management (workflows, versioning)
- Use Paperless-ngx for archiving and automatic processing
- Can share the same PostgreSQL or Redis instances

### OpenCloud (Nextcloud)
- Use OpenCloud for file sync and sharing
- Use Paperless-ngx for document archiving and OCR
- Can configure OpenCloud as external storage via WebDAV or S3

### Stalwart
- Configure Paperless-ngx to fetch emails from Stalwart
- Enable email-based document submission

## License

GNU GPL-3.0-or-later

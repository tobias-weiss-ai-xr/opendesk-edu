# Document Management Systems - openDesk Edu

# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0 and GPL-3.0-or-later

This document describes the Document Management Systems (DMS) available in openDesk Edu.

## Overview

openDesk Edu provides two complementary Document Management Systems:

1. **Mayan EDMS** - Full-featured DMS with workflows, versioning, and compliance features
2. **Paperless-ngx** - Document archiving with OCR, tags, and automated processing

Both systems integrate seamlessly with the existing openDesk infrastructure:
- **Keycloak OIDC** for authentication
- **SeaweedFS** for S3-compatible storage
- **Stalwart** for email integration
- **Nubus Portal** for unified access

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        openDesk Edu Platform                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌────────────────────────┐ │
│  │   Keycloak  │    │  SeaweedFS  │    │        Stalwart        │ │
│  │   (OIDC)    │    │  (S3 Storage)│    │     (Email)           │ │
│  └──────┬──────┘    └──────┬──────┘    └─────────────┬───────────┘ │
│         │                  │                       │              │
│         ▼                  ▼                       ▼              │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────┐ │
│  │   Mayan EDMS    │ │ Paperless-ngx   │ │    OpenCloud        │ │
│  │   (DMS)         │ │ (Archiving)     │ │   (File Sync)       │ │
│  └────────┬────────┘ └────────┬────────┘ └──────────┬───────────┘ │
│           │                 │                     │              │
│           └─────────────────┴─────────────────────┘              │
│                     │                                     │              │
│                     ▼                                     │              │
│              ┌─────────────────┐                          │              │
│              │   Nubus Portal  │◄─────────────────────────┘              │
│              │   (Access)      │                                  │              │
│              └─────────────────┘                                  │              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Mayan EDMS

### Features

- **Document Management**: Upload, version, and organize documents
- **Metadata**: Custom metadata types and extraction
- **OCR**: Optical Character Recognition (Tesseract)
- **Workflows**: Automated document processing workflows
- **Access Control**: Fine-grained permissions and role-based access
- **Search**: Full-text search across all documents
- **API**: REST API for integration
- **Compliance**: Retention policies, audit logging

### Use Cases

- **Academic Administration**: Managing student records, contracts, forms
- **Research**: Storing and organizing research papers, theses, and publications
- **Legal Compliance**: Document retention and compliance tracking
- **Collaboration**: Team-based document review and approval workflows

### Quick Start

1. **Enable Mayan EDMS**:
   ```yaml
   # In helmfile/environments/edu/values.yaml.gotmpl or similar
   apps:
     mayanEdms:
       enabled: true
   ```

2. **Configure Storage** (optional - uses CephFS by default):
   ```yaml
   apps:
     mayanEdms:
       storage:
         dataSize: "100Gi"
         mediaSize: "200Gi"
         databaseSize: "20Gi"
   ```

3. **Register OIDC Client in Keycloak**:
   - Client ID: `mayan-edms`
   - Redirect URI: `https://mayan.{domain}/accounts/openid/login/callback/`
   - Enable Standard Flow
   - Add claim mappings for: `preferred_username`, `email`, `given_name`, `family_name`

4. **Access Mayan EDMS**:
   - URL: `https://mayan.{domain}`
   - Login via Keycloak OIDC

### Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | 1 |
| `persistence.data.enabled` | Enable data storage | true |
| `persistence.data.size` | Data storage size | 50Gi |
| `persistence.media.size` | Media storage size | 100Gi |
| `persistence.index.size` | Search index size | 10Gi |
| `mayan.ocr.enabled` | Enable OCR | true |
| `mayan.ocr.language` | OCR languages | eng+deu+fra |
| `mayan.tesseract.enabled` | Enable Tesseract | true |
| `mayan.tesseract.languages` | Tesseract languages | eng+deu+fra+ita+spa |
| `mayan.workflows.enabled` | Enable workflows | true |
| `autoscaling.enabled` | Enable HPA | false |
| `backup.enabled` | Enable backups | true |

### Persistent Volumes

- **Data**: Document files and metadata (`ceph-cephfs-hdd-ec`)
- **Media**: Uploaded files and previews (`ceph-cephfs-hdd-ec`)
- **Index**: Search index (`ceph-rbd-ssd`)
- **PostgreSQL**: Database (`ceph-rbd-ssd`)
- **Redis**: Cache (`ceph-rbd-ssd`)

### Backup

Mayan EDMS is configured with k8up for automated backups:
- Schedule: Daily at 02:00
- Retention: 7 daily, 4 weekly, 3 monthly
- Snapshot volumes: true

## Paperless-ngx

### Features

- **Document Archiving**: Store and organize documents
- **Automatic OCR**: Extract text from images and PDFs
- **Smart Classification**: Auto-assign tags, correspondents, document types
- **Email Processing**: Fetch and process emails with attachments
- **Barcode Detection**: Extract metadata from barcodes
- **Full-Text Search**: Search across all documents
- **API**: REST API for integration
- **Mobile-Friendly**: Responsive web interface

### Use Cases

- **Student Submissions**: Automatically process and archive student assignments
- **Research Papers**: Store and tag research publications
- **Administrative Documents**: Archive forms, invoices, receipts
- **Email Archiving**: Automatically archive important emails with attachments
- **Automated Processing**: Set up rules to automatically classify documents

### Quick Start

1. **Enable Paperless-ngx**:
   ```yaml
   # In helmfile/environments/edu/values.yaml.gotmpl or similar
   apps:
     paperlessNgx:
       enabled: true
   ```

2. **Configure Storage** (optional - uses CephFS by default):
   ```yaml
   apps:
     paperlessNgx:
       storage:
         dataSize: "200Gi"
         consumeSize: "50Gi"
         databaseSize: "20Gi"
   ```

3. **Register OIDC Client in Keycloak**:
   - Client ID: `paperless-ngx`
   - Redirect URI: `https://paperless.{domain}/accounts/oidc/callback/`
   - Enable Standard Flow
   - Add claim mappings for: `preferred_username`, `email`, `given_name`, `family_name`

4. **Access Paperless-ngx**:
   - URL: `https://paperless.{domain}`
   - Login via Keycloak OIDC

### Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | 1 |
| `persistence.data.enabled` | Enable data storage | true |
| `persistence.data.size` | Data storage size | 100Gi |
| `persistence.consume.enabled` | Enable consume folder | true |
| `persistence.consume.size` | Consume folder size | 50Gi |
| `paperless.ocr.enabled` | Enable OCR | true |
| `paperless.ocr.language` | OCR languages | eng+deu+fra |
| `paperless.tesseract.enabled` | Enable Tesseract | true |
| `paperless.tesseract.languages` | Tesseract languages | eng+deu+fra+ita+spa |
| `paperless.consume.enabled` | Enable document consumption | true |
| `paperless.email.enabled` | Enable email processing | true |
| `autoscaling.enabled` | Enable HPA | false |
| `backup.enabled` | Enable backups | true |

### Automated Processing

Paperless-ngx automatically processes new documents in the consume folder:
- Extracts text via OCR
- Classifies based on content
- Assigns tags and correspondents
- Moves to appropriate folders

### Email Processing

Configure Paperless-ngx to fetch emails from Stalwart:

```yaml
paperless:
  email:
    enabled: true
    imap:
      enabled: true
      host: "stalwart-stalwart.opendesk.svc.cluster.local"
      port: 993
      ssl: true
      mailbox: "INBOX"
```

### Persistent Volumes

- **Data/Media**: Document files and previews (`ceph-cephfs-hdd-ec`)
- **Consume**: New documents for processing (`ceph-cephfs-hdd-ec`)
- **PostgreSQL**: Database (`ceph-rbd-ssd`)
- **Redis**: Cache (`ceph-rbd-ssd`)

## Integration with Other Services

### OpenCloud (Nextcloud)

Both Mayan EDMS and Paperless-ngx can integrate with OpenCloud:

1. **Mayan EDMS**: Configure OpenCloud as external storage via WebDAV
2. **Paperless-ngx**: Configure OpenCloud as S3-compatible storage
3. **Shared Files**: Use OpenCloud for file sync, Mayan/Paperless for document management

### Stalwart (Email)

- **Paperless-ngx**: Fetch emails with attachments via IMAP
- **Mayan EDMS**: Send email notifications via SMTP
- **Unified Inbox**: Archive important emails automatically

### Keycloak (Authentication)

Both systems support OIDC authentication with Keycloak:
- Single Sign-On across all services
- Role-based access control
- Multi-factor authentication support

### SeaweedFS (Storage)

Both systems can use SeaweedFS for S3-compatible storage:
- Scalable object storage
- Multi-region support
- Erasure coding for data protection

## Comparison: Mayan EDMS vs Paperless-ngx

| Feature | Mayan EDMS | Paperless-ngx |
|---------|-----------|---------------|
| **License** | Apache-2.0 | GPL-3.0-or-later |
| **Primary Use** | Document Management | Document Archiving |
| **Workflows** | ✅ Yes | ❌ No |
| **Versioning** | ✅ Yes | ❌ No |
| **Metadata** | ✅ Custom types | ✅ Basic metadata |
| **OCR** | ✅ Yes | ✅ Yes |
| **Email Processing** | ❌ No | ✅ Yes |
| **Barcode Detection** | ❌ No | ✅ Yes |
| **Smart Classification** | ❌ No | ✅ Yes |
| **API** | ✅ REST | ✅ REST |
| **Mobile App** | ❌ No | ❌ No (but responsive) |
| **Best For** | Formal documents, compliance | Automated archiving, OCR |

## Recommended Deployment Strategy

### Option 1: Both Systems (Recommended)

Deploy both Mayan EDMS and Paperless-ngx for different use cases:
- **Mayan EDMS**: Formal documents, contracts, compliance
- **Paperless-ngx**: Student submissions, research papers, automated processing

### Option 2: Mayan EDMS Only

If you need a full-featured DMS with workflows and versioning:
- Deploy only Mayan EDMS
- Use OpenCloud for file sync and sharing

### Option 3: Paperless-ngx Only

If you need automated document processing and OCR:
- Deploy only Paperless-ngx
- Use OpenCloud for file sync and sharing

## Security Considerations

### Authentication

- Both systems use OIDC with Keycloak
- Enable MFA in Keycloak for sensitive documents
- Configure appropriate role mappings

### Authorization

- **Mayan EDMS**: Configure permissions at the document type level
- **Paperless-ngx**: Configure user access per document type
- Regularly review access logs

### Data Protection

- All PVCs are encrypted at rest (Ceph CSI)
- Backups are encrypted (k8up with restic)
- Network policies restrict access to storage backends

### Network Security

- Ingress via HAProxy with TLS
- Network policies restrict pod-to-pod communication
- Pod Security Admission enforces security contexts

## Monitoring and Maintenance

### Monitoring

Both systems expose metrics for Prometheus:
- Request rates
- Error rates
- Resource utilization
- Document processing metrics

### Logging

- Application logs are captured by Loki
- Access logs are available in haProxy
- Audit logs for document access

### Maintenance Tasks

1. **Regular Backups**: Verify backup completion and retention
2. **OCR Language Updates**: Add new languages as needed
3. **Index Optimization**: Rebuild search indexes periodically
4. **Storage Monitoring**: Monitor disk space usage
5. **Security Updates**: Regularly update container images

## Troubleshooting

### Common Issues

#### Mayan EDMS

1. **OCR Not Working**:
   - Check Tesseract installation in container
   - Verify language packs are installed
   - Check OCR configuration in settings

2. **Workflow Issues**:
   - Verify Celery workers are running
   - Check Redis connectivity
   - Review workflow definitions

3. **Authentication Errors**:
   - Verify OIDC client configuration in Keycloak
   - Check redirect URIs match exactly
   - Ensure client secret is correct

#### Paperless-ngx

1. **Email Processing Not Working**:
   - Verify IMAP credentials
   - Check Stalwart IMAP service is running
   - Review email configuration in settings

2. ** Consume Folder Not Processing**:
   - Check file permissions on consume folder
   - Verify polling interval is correct
   - Review consumption logs

3. **OCR Quality Issues**:
   - Try different OCR languages
   - Adjust DPI settings
   - Check input document quality

### Debugging Commands

```bash
# View Mayan EDMS logs
kubectl logs -n opendesk deployment/mayan-edms -f

# View Paperless-ngx logs
kubectl logs -n opendesk deployment/paperless-ngx -f

# Check PostgreSQL connection (Mayan)
kubectl exec -n opendesk deployment/mayan-edms -- psql -h mayan-edms-postgresql -U mayan -d mayan -c "SELECT 1"

# Check Redis connection (Mayan)
kubectl exec -n opendesk deployment/mayan-edms -- redis-cli -h mayan-edms-redis-master PING

# Check PVC status
kubectl get pvc -n opendesk | grep -E "(mayan|paperless)"

# Check backup status (k8up)
kubectl get backup -n opendesk | grep -E "(mayan|paperless)"
```

## Scaling

### Horizontal Scaling

Both systems support horizontal scaling:

```yaml
# Mayan EDMS
apps:
  mayanEdms:
    replicaCount: 2
    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 5
      targetCPU: 70
      targetMemory: 70

# Paperless-ngx
apps:
  paperlessNgx:
    replicaCount: 2
    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 5
      targetCPU: 70
      targetMemory: 70
```

### Vertical Scaling

Adjust resource limits based on usage:

```yaml
# Mayan EDMS
resources:
  mayan:
    requests:
      cpu: "2"
      memory: "4Gi"
    limits:
      cpu: "4"
      memory: "8Gi"

# Paperless-ngx
resources:
  paperless:
    requests:
      cpu: "2"
      memory: "4Gi"
    limits:
      cpu: "4"
      memory: "8Gi"
```

### Storage Scaling

Increase PVC sizes as needed:

```yaml
apps:
  mayanEdms:
    storage:
      dataSize: "200Gi"
      mediaSize: "500Gi"
  
  paperlessNgx:
    storage:
      dataSize: "500Gi"
      consumeSize: "100Gi"
```

## Performance Optimization

### Mayan EDMS

1. **Index Optimization**:
   ```bash
   # Rebuild search index
   kubectl exec -n opendesk deployment/mayan-edms -- python manage.py rebuild_index
   ```

2. **Cache Configuration**:
   - Use Redis for session caching
   - Configure appropriate cache timeouts

3. **Database Optimization**:
   - Regular VACUUM and ANALYZE
   - Proper indexing on frequently queried fields

### Paperless-ngx

1. **OCR Performance**:
   - Limit concurrent OCR jobs
   - Use appropriate DPI settings
   - Install only needed language packs

2. **Consumption Queue**:
   - Monitor Celery queue depth
   - Adjust worker count based on load
   - Use separate queues for different document types

3. **Search Optimization**:
   - Regular index updates
   - Proper analyzers for your language

## Migration from Other Systems

### From Nextcloud/_onlyoffice

1. Export documents from Nextcloud
2. Upload to Mayan EDMS or Paperless-ngx
3. Configure OCR if needed
4. Set up metadata and tags

### From Alfresco

1. Export documents using Alfresco export tools
2. Import into Mayan EDMS
3. Configure workflows to match existing processes

### From SharePoint

1. Export document libraries
2. Upload to Mayan EDMS or Paperless-ngx
3. Configure permissions to match existing structure

## Customization

### Mayan EDMS

1. **Custom Metadata Types**:
   ```python
   # Add to initialization scripts
   from mayan.apps.metadata.models import MetadataType
   
   MetadataType.objects.create(
       name='Custom Field',
       slug='custom_field',
       data_type='string'
   )
   ```

2. **Custom Workflows**:
   - Create workflow definitions via admin interface
   - Add states and transitions
   - Configure permissions per state

3. **Custom Styling**:
   - Override CSS files
   - Custom logos and branding
   - Modify templates

### Paperless-ngx

1. **Custom Document Types**:
   - Configure in admin interface
   - Set up matching rules

2. **Custom Correspondents**:
   - Configure in admin interface
   - Set up matching rules

3. **Custom Tags**:
   - Configure in admin interface
   - Set up matching rules

## API Integration

### Mayan EDMS API

```bash
# Get API token
curl -X POST https://mayan.{domain}/api/v4/tokens/ \
  -H "Content-Type: application/json" \
  -d '{"username": "user", "password": "pass"}'

# List documents
curl -X GET https://mayan.{domain}/api/v4/documents/ \
  -H "Authorization: Token YOUR_TOKEN"
```

### Paperless-ngx API

```bash
# Get API token
curl -X POST https://paperless.{domain}/api/token/ \
  -H "Content-Type: application/json" \
  -d '{"username": "user", "password": "pass"}'

# List documents
curl -X GET https://paperless.{domain}/api/documents/ \
  -H "Authorization: Token YOUR_TOKEN"
```

## Backup and Restore

### Backup

Both systems are configured with k8up for automated backups:

```yaml
backup:
  enabled: true
  k8up:
    schedule: "0 2 * * *"
    retention:
      daily: 7
      weekly: 4
      monthly: 3
    snapshotVolumes: true
```

### Restore

1. **List available backups**:
   ```bash
   kubectl get backup -n opendesk
   ```

2. **Restore a backup**:
   ```bash
   kubectl create -f - <<EOF
   apiVersion: backup.appuio.ch/v1alpha1
   kind: Restore
   metadata:
     name: mayan-edms-restore
     namespace: opendesk
   spec:
     backup: mayan-edms-backup-20260101
     podSelector:
       matchLabels:
         app.kubernetes.io/name: mayan-edms
   EOF
   ```

3. **Verify restore**:
   ```bash
   kubectl get restore -n opendesk
   kubectl logs -n opendesk job/mayan-edms-restore -f
   ```

## Upgrades

### Mayan EDMS

1. **Check for new versions**:
   ```bash
   kubectl get deployment mayan-edms -o jsonpath='{.spec.template.spec.containers[0].image}'
   ```

2. **Update image tag**:
   ```yaml
   apps:
     mayanEdms:
       image:
         tag: "4.6.0"
   ```

3. **Apply update**:
   ```bash
   helmfile -f helmfile.yaml.gotmpl sync
   ```

4. **Verify**:
   ```bash
   kubectl rollout status deployment/mayan-edms -n opendesk
   ```

### Paperless-ngx

1. **Check for new versions**:
   ```bash
   kubectl get deployment paperless-ngx -o jsonpath='{.spec.template.spec.containers[0].image}'
   ```

2. **Update image tag**:
   ```yaml
   apps:
     paperlessNgx:
       image:
         tag: "2.13.0"
   ```

3. **Apply update**:
   ```bash
   helmfile -f helmfile.yaml.gotmpl sync
   ```

4. **Verify**:
   ```bash
   kubectl rollout status deployment/paperless-ngx -n opendesk
   ```

## Community and Support

- **Mayan EDMS**: https://github.com/mayan-edms/mayan-edms
- **Paperless-ngx**: https://github.com/paperless-ngx/paperless-ngx
- **openDesk Edu**: https://github.com/tobias-weiss-ai-xr/opendesk-edu

## License

- **Mayan EDMS**: Apache License 2.0
- **Paperless-ngx**: GNU GPL-3.0-or-later
- **Documentation**: Apache License 2.0

## Contributors

- openDesk Edu Team
- Mayan EDMS Community
- Paperless-ngx Community

## Changelog

- **2026-01-01**: Initial implementation of Mayan EDMS and Paperless-ngx Helm charts
- **2026-01-02**: Added OIDC authentication support
- **2026-01-03**: Added SeaweedFS storage integration
- **2026-01-04**: Added Stalwart email integration
- **2026-01-05**: Added Portal entries

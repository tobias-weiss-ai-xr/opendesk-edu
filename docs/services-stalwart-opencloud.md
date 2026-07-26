# Deploying Stalwart Mail Server and OpenCloud

This guide explains how to deploy **Stalwart Mail Server** and **OpenCloud** (Nextcloud with OIDC) using the openDesk Edu variant.

## Overview

- **Stalwart Mail Server**: Modern mail server supporting IMAP, SMTP, POP3, Sieve, and Web API with OIDC authentication
- **OpenCloud**: Nextcloud-based file sync and share platform with OIDC/OAuth2 authentication (replaces standard Nextcloud)

Both services are integrated with:
- Keycloak OIDC for authentication
- HAProxy Ingress for TLS termination
- Ceph storage for persistence
- LDAP for user directory

## Prerequisites

1. Kubernetes cluster (K3s v1.32.3 or compatible)
2. Helmfile installed
3. kubectl configured with cluster access
4. Ceph CSI storage classes:
   - `ceph-rbd-ssd` (for Stalwart - RWO)
   - `ceph-cephfs-hdd-ec` (for OpenCloud - RWX)
5. Ingress controller (HAProxy or NGINX)
6. TLS certificates (opendesk-certificates-tls secret)
7. Keycloak instance running with opendesk realm
8. LDAP server (UMS LDAP)

## Service Configuration

### Stalwart Mail Server

**Configuration Files:**
- Chart: `./helmfile/charts/stalwart/`
- Values: `./helmfile/apps/edu/stalwart/values.yaml.gotmpl`
- Helmfile: `./helmfile/apps/edu/stalwart/helmfile-child.yaml.gotmpl`

**Key Features:**
- IMAP/IMAPS (ports 143, 993)
- SMTP/Submission (ports 25, 587, 465)
- POP3/POP3S (ports 110, 995)
- Sieve (port 4190)
- HTTP Admin API (port 8080)
- OIDC authentication with Keycloak
- LDAP user directory integration
- RocksDB storage backend

**Access:**
- Web Admin: `https://mail.opendesk.hrz.uni-marburg.de`
- IMAP/SMTP: Use hostnames configured in DNS

### OpenCloud

**Configuration Files:**
- Chart: `./helmfile/charts/opencloud/`
- Values: `./helmfile/apps/edu/opencloud/values.yaml.gotmpl`
- Helmfile: `./helmfile/apps/edu/opencloud/helmfile-child.yaml.gotmpl`

**Key Features:**
- File sync and share
- OIDC authentication with Keycloak
- Multi-user with auto-provisioning
- RWX storage on CephFS
- Backchannel logout support

**Access:**
- Web: `https://files.opendesk.hrz.uni-marburg.de`

## Pre-Deployment Setup

### 1. Generate Secrets

Before deploying, you must generate and configure the following secrets:

#### Stalwart Secrets
```bash
# Generate admin password hash (SHA-512)
STALWART_ADMIN_PASSWORD="your-secure-password"
STALWART_ADMIN_HASH=$(openssl passwd -6 "$STALWART_ADMIN_PASSWORD")

# Generate OIDC client secret
STALWART_OIDC_SECRET=$(openssl rand -hex 32)

# LDAP bind password
LDAP_BIND_PASSWORD="your-ldap-bind-password"
```

#### OpenCloud Secrets
```bash
# Generate all OpenCloud secrets
OPENCLOUD_JWT_SECRET=$(openssl rand -hex 32)
OPENCLOUD_TRANSFER_SECRET=$(openssl rand -hex 32)
OPENCLOUD_MACHINE_AUTH_KEY=$(openssl rand -hex 32)
OPENCLOUD_SYSTEM_USER_KEY=$(openssl rand -hex 32)
OPENCLOUD_SYSTEM_USER_ID=$(openssl rand -hex 16)
OPENCLOUD_URL_SIGNING_SECRET=$(openssl rand -hex 32)
OPENCLOUD_BACKCHANNEL_SECRET=$(openssl rand -hex 32)
OPENCLOUD_OIDC_SECRET=$(openssl rand -hex 32)
```

### 2. Update Secrets File

Edit `./helmfile/environments/edu/secrets.yaml`:

```yaml
secrets:
  keycloak:
    clientSecret:
      iliasSaml: "your-ilias-saml-secret"
      moodleSaml: "your-moodle-saml-secret"
      bbbSaml: "your-bbb-saml-secret"
      opencloud: "$OPENCLOUD_OIDC_SECRET"
      stalwart: "$STALWART_OIDC_SECRET"
  
  stalwart:
    adminPasswordHash: "$STALWART_ADMIN_HASH"
  
  ldap:
    bindPassword: "$LDAP_BIND_PASSWORD"
  
  opencloud:
    jwtSecret: "$OPENCLOUD_JWT_SECRET"
    transferSecret: "$OPENCLOUD_TRANSFER_SECRET"
    machineAuthApiKey: "$OPENCLOUD_MACHINE_AUTH_KEY"
    systemUserApiKey: "$OPENCLOUD_SYSTEM_USER_KEY"
    systemUserId: "$OPENCLOUD_SYSTEM_USER_ID"
    urlSigningSecret: "$OPENCLOUD_URL_SIGNING_SECRET"
    backchannelLogoutSecret: "$OPENCLOUD_BACKCHANNEL_SECRET"
```

### 3. Register OIDC Clients in Keycloak

You need to register both Stalwart and OpenCloud as OIDC clients in Keycloak:

#### For Stalwart:
- Client ID: `stalwart`
- Client Secret: `$STALWART_OIDC_SECRET`
- Redirect URIs: `https://mail.opendesk.hrz.uni-marburg.de/*`, `https://portal.opendesk.hrz.uni-marburg.de/*`
- Protocol: openid-connect
- Access Type: confidential

#### For OpenCloud:
- Client ID: `opendesk-opencloud`
- Client Secret: `$OPENCLOUD_OIDC_SECRET`
- Redirect URIs: `https://files.opendesk.hrz.uni-marburg.de/*`, `https://portal.opendesk.hrz.uni-marburg.de/*`
- Protocol: openid-connect
- Access Type: confidential
- Backchannel Logout URL: `https://files.opendesk.hrz.uni-marburg.de/backchannel_logout`

### 4. Configure DNS

Ensure the following DNS records exist:
- `mail.opendesk.hrz.uni-marburg.de` → Cluster ingress IP
- `files.opendesk.hrz.uni-marburg.de` → Cluster ingress IP
- MX records pointing to your mail servers
- SPF, DKIM, DMARC records for email deliverability

### 5. Configure LDAP

Stalwart connects to LDAP for user directory. Ensure:
- LDAP server is accessible at `ums-ldap.opendesk.hrz.uni-marburg.de:636`
- Bind DN has sufficient read permissions
- User base DN is configured correctly (default: `dc=uni-marburg,dc=de`)

## Deployment

### Using the deploy.sh Script (Recommended)

The easiest way to deploy both services is using the provided `deploy.sh` script:

```bash
# From the opendesk-edu directory:
cd ./opendesk-edu

# Dry run (show what would be deployed)
./deploy.sh --diff

# Deploy to production (edu environment)
./deploy.sh

# Deploy to test environment
./deploy.sh edu-test

# Verbose output
./deploy.sh --verbose
```

### Manual Deployment with Helmfile

Alternatively, you can use helmfile directly:

```bash
# Step 1: Deploy CE base
cd ./opendesk-edu/helmfile/ce
helmfile -f helmfile.yaml.gotmpl \
  --values "../environments/edu/ce-overrides.yaml" \
  --values "../environments/edu/secrets.yaml" \
  --values "../environments/edu/images.yaml" \
  sync

# Step 2: Deploy edu overlay (includes Stalwart and OpenCloud)
cd ./opendesk-edu
helmfile -f helmfile/edu-helmfile.yaml.gotmpl -e edu sync
```

### Deploy Individual Services

To deploy just Stalwart and OpenCloud:

```bash
# Deploy Stalwart
cd ./opendesk-edu/helmfile
helmfile -f edu-helmfile.yaml.gotmpl -e edu select stalwart
helmfile -f edu-helmfile.yaml.gotmpl -e edu sync

# Deploy OpenCloud
helmfile -f edu-helmfile.yaml.gotmpl -e edu select opendesk-opencloud
helmfile -f edu-helmfile.yaml.gotmpl -e edu sync
```

## Post-Deployment Configuration

### Stalwart

1. **Initial Admin Setup:**
   ```bash
   # Access the admin console at https://mail.opendesk.hrz.uni-marburg.de
   # Login with username: admin
   # Password: the one you set in STALWART_ADMIN_PASSWORD
   ```

2. **Configure Mail Domains:**
   - Add your mail domains (e.g., `uni-marburg.de`)
   - Configure domain-specific settings

3. **Test Mail Flow:**
   ```bash
   # Send a test email
   echo "Test email" | mail -s "Test Subject" user@domain.com
   
   # Check logs
   kubectl logs -f deployment/stalwart
   ```

4. **Configure DNS for Email:**
   - MX records pointing to Stalwart servers
   - SPF: `v=spf1 mx ~all`
   - DKIM: Generate and publish DKIM keys
   - DMARC: `v=DMARC1; p=none; rua=mailto:admin@uni-marburg.de`

### OpenCloud

1. **Verify OIDC Authentication:**
   - Visit `https://files.opendesk.hrz.uni-marburg.de`
   - You should be redirected to Keycloak for login
   - After login, you should see the OpenCloud dashboard

2. **Check Auto-Provisioning:**
   - New users logging in via Keycloak should be automatically provisioned
   - Verify user accounts are created in OpenCloud

3. **Test File Sync:**
   ```bash
   # Install the Nextcloud desktop client
   # Connect to https://files.opendesk.hrz.uni-marburg.de
   # Upload/download test files
   ```

## Troubleshooting

### Stalwart Issues

**Problem: Stalwart pods crash on startup**
```bash
kubectl logs -f deployment/stalwart
kubectl describe pod stalwart-0
```
- Ensure LDAP connection is working
- Verify OIDC issuer URL is correct
- CheckPassword hash is valid

**Problem: Cannot connect to IMAP/SMTP**
```bash
kubectl get svc stalwart
kubectl get endpoints stalwart
```
- Verify service is running
- Check firewall rules
- Test connectivity from within cluster

**Problem: TLS errors**
```bash
kubectl exec -it stalwart-0 -- cat /opt/stalwart/logs/stalwart.log
```
- Ensure TLS certificates are mounted correctly
- Verify certificate paths in config

### OpenCloud Issues

**Problem: OIDC login fails**
```bash
kubectl logs -f deployment/opendesk-opencloud
```
- Verify OIDC client ID and secret match Keycloak configuration
- Check redirect URIs in Keycloak
- Verify issuer URL is correct

**Problem: Backchannel logout not working**
- Ensure backchannel logout URL is configured in Keycloak
- Verify `BACKCHANNEL_LOGOUT_OPENCLOUD_ENABLED` environment variable
- Check backchannel logout secret

**Problem: Storage not writable**
```bash
kubectl get pvc | grep opendesk-opencloud
kubectl describe pvc opendesk-opencloud-data
```
- Verify storage class `ceph-cephfs-hdd-ec` exists
- Check PVC status (should be Bound)
- Verify RWX access mode is supported

## Monitoring

### Stalwart Metrics

Stalwart exposes a health endpoint at `/api/health`:
```bash
kubectl exec -it stalwart-0 -- curl http://localhost:8080/api/health
```

### OpenCloud Metrics

OpenCloud provides a status endpoint:
```bash
kubectl exec -it opendesk-opencloud-0 -- curl http://localhost:8080/status.php
```

## Scaling

### Stalwart

Stalwart is configured with `replicaCount: 1`. For high availability:
```yaml
stalwart:
  replicaCount: 3
  persistence:
    accessMode: ReadWriteMany  # Requires RWX storage
    storageClass: ceph-cephfs-hdd-ec
```

Note: Stalwart with RocksDB requires ReadWriteMany storage for multi-replica setups.

### OpenCloud

OpenCloud is already configured with `replicaCount: 2`. You can scale up:
```yaml
replicaCount: 3
```

## Backup and Restore

### Stalwart

Stalwart data is stored in PVC `stalwart-pvc`. Backup using:
```bash
# Using k8up or velero
kubectl label pvc stalwart-pvc k8up.io/exclude="false"

# Or manual backup
kubectl exec -it stalwart-0 -- tar czf /tmp/stalwart-backup.tar.gz /opt/stalwart/data
kubectl cp stalwart-0:/tmp/stalwart-backup.tar.gz ./stalwart-backup.tar.gz
```

### OpenCloud

OpenCloud data is stored in PVC `opendesk-opencloud-data`. Backup using:
```bash
# OpenCloud is already configured in k8up for automatic backups
# Manual export
kubectl exec -it opendesk-opencloud-0 -- /bin/sh -c 'mysqldump...' > opencloud-db.sql
```

## Upgrading

### Stalwart

```bash
# Update image tag in helmfile/environments/edu/images.yaml
images:
  stalwart:
    tag: v1.0.0  # New version

# Apply changes
./deploy.sh
```

### OpenCloud

```bash
# Update image tag in helmfile/environments/edu/images.yaml
images:
  opencloud:
    tag: 5.0.0  # New version

# Apply changes
./deploy.sh
```

## Known Issues and Workarounds

### Issue 1: Stalwart LDAP TLS
**Symptom:** LDAP connection fails with TLS errors
**Workaround:** Ensure LDAP server certificate is trusted. You may need to add CA certificates to Stalwart container.

### Issue 2: OpenCloud OIDC Discovery
**Symptom:** OIDC discovery fails
**Workaround:** Ensure Keycloak issuer URL is accessible from OpenCloud pods. Check network policies.

### Issue 3: Large File Uploads
**Symptom:** File uploads >100MB fail
**Workaround:** Adjust ingress annotations for proxy body size (already configured in values.yaml.gotmpl)

### Issue 4: Stalwart Rate Limiting
**Symptom:** Too many connections errors
**Workaround:** Adjust rate limits in stalwart values:
```yaml
rateLimit:
  maxMessagesPerSession: 500
  maxRecipientsPerMessage: 200
  maxConnectionsPerIp: 100
```

## Configuration Reference

### Stalwart Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `auth.oidc.enabled` | Enable OIDC authentication | true |
| `auth.oidc.issuerUrl` | Keycloak issuer URL | auto-configured from global |
| `auth.oidc.clientId` | OIDC client ID | stalwart |
| `auth.fallbackAdmin.username` | Admin username | admin |
| `directory.type` | Directory type (internal/ldap) | ldap |
| `directory.ldap.host` | LDAP server hostname | ums-ldap.opendesk.hrz.uni-marburg.de |
| `listeners.*.bind` | Port bindings | Standard ports |
| `tls.enabled` | Enable TLS | true |
| `persistence.size` | Storage size | 20Gi |
| `persistence.storageClass` | Storage class | ceph-rbd-ssd |

### OpenCloud Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.tag` | OpenCloud image tag | 4.0.3 |
| `ingress.enabled` | Enable ingress | true |
| `ingress.hostname` | Ingress hostname | files.opendesk.hrz.uni-marburg.de |
| `oidc.issuer` | Keycloak issuer URL | auto-configured from global |
| `oidc.clientId` | OIDC client ID | opendesk-opencloud |
| `oidc.autoProvisionAccounts` | Auto-provision users | true |
| `persistence.size` | Storage size | 100Gi |
| `persistence.storageClass` | Storage class | ceph-cephfs-hdd-ec |
| `resources` | Resource requests/limits | From global resources |

## Related Files

- `helmfile/charts/stalwart/` - Stalwart Helm chart
- `helmfile/charts/opencloud/` - OpenCloud Helm chart
- `helmfile/apps/edu/stalwart/` - Stalwart app configuration
- `helmfile/apps/edu/opencloud/` - OpenCloud app configuration
- `helmfile/environments/edu/ce-overrides.yaml` - Edu-specific overrides
- `helmfile/environments/edu/secrets.yaml` - Secret configuration
- `helmfile/environments/edu/images.yaml` - Image configuration

## Support

For issues with Stalwart or OpenCloud deployment:
1. Check logs: `kubectl logs -f <pod-name>`
2. Check events: `kubectl get events --sort-by=.metadata.creationTimestamp`
3. Describe resources: `kubectl describe <resource-type> <resource-name>`
4. Review configuration: Verify all values files for correctness

# Stalwart + OpenCloud Deployment Configuration

## Overview

This document summarizes the configuration changes made to deploy **Stalwart Mail Server** and **OpenCloud** (Nextcloud with OIDC) in the openDesk Edu variant.

## Changes Made

### 1. Enhanced Stalwart Configuration
**File:** `./opendesk-edu/helmfile/apps/edu/stalwart/values.yaml.gotmpl`

**Key Updates:**
- Added comprehensive OIDC authentication support
- Configured LDAP integration with UMS LDAP server
- Set up all mail protocol listeners (SMTP, IMAP, POP3, Sieve, HTTP)
- Enabled TLS configuration
- Added RocksDB storage configuration
- Configured rate limiting and security settings
- Added health check endpoints
- Enabled ingress with HAProxy
- Set persistence with 20Gi storage on ceph-rbd-ssd
- Configured resource requests/limits (2 CPU, 4Gi memory)
- Added security contexts (non-root, read-only filesystem, capability drop)
- Image: `docker.io/stalwartlabs/mail-server:latest`

### 2. Updated Secrets Configuration
**File:** `./opendesk-edu/helmfile/environments/edu/secrets.yaml`

**Added Secrets:**
- `keycloak.clientSecret.stalwart` - OIDC client secret for Stalwart
- `stalwart.adminPasswordHash` - SHA-512 hash for admin user
- `ldap.bindPassword` - LDAP bind password
- `opencloud.*` - All OpenCloud secrets (jwtSecret, transferSecret, machineAuthApiKey, systemUserApiKey, systemUserId, urlSigningSecret, backchannelLogoutSecret)

### 3. Enhanced Edu Overrides
**File:** `./opendesk-edu/helmfile/environments/edu/ce-overrides.yaml`

**Added Configuration:**
- Global hosts configuration:
  - `keycloak: portal`
  - `opencloud: files`
  - `stalwart: mail`
  - `sogo: contacts`
- Platform realm: `opendesk`
- OIDC client configuration for Stalwart
  - Client ID: `stalwart`
  - Protocol: openid-connect
  - Redirect URIs: mail.* and portal.*
  - Default client scopes: openid, profile, email

### 4. Updated Image Configuration
**File:** `./opendesk-edu/helmfile/environments/edu/images.yaml`

**Added Images:**
- `stalwart: docker.io/stalwartlabs/mail-server:latest`
- `opencloud: docker.io/opencloudeu/opencloud:4.0.3`

## Service Details

### Stalwart Mail Server

**Component:** Mail server (IMAP, SMTP, POP3, Sieve)

**Access Points:**
- Admin Console: `https://mail.opendesk.hrz.uni-marburg.de`
- IMAP: `mail.opendesk.hrz.uni-marburg.de:993` (IMAPS)
- IMAP: `mail.opendesk.hrz.uni-marburg.de:143` (STARTTLS)
- SMTP: `mail.opendesk.hrz.uni-marburg.de:465` (SMTPS)
- SMTP: `mail.opendesk.hrz.uni-marburg.de:587` (STARTTLS)
- POP3: `mail.opendesk.hrz.uni-marburg.de:995` (POP3S)
- POP3: `mail.opendesk.hrz.uni-marburg.de:110` (STARTTLS)
- Sieve: `mail.opendesk.hrz.uni-marburg.de:4190`

**Features:**
- OIDC authentication with Keycloak
- LDAP user directory integration
- RocksDB storage backend
- Rate limiting and security features
- Health check endpoints
- TLS support
- Non-root container security

**Persistence:**
- Size: 20Gi
- Storage Class: ceph-rbd-ssd
- Access Mode: ReadWriteOnce

**Resources:**
- Requests: 200m CPU, 512Mi memory
- Limits: 2 CPU, 4Gi memory

### OpenCloud

**Component:** Nextcloud-based file sync and share with OIDC

**Access Point:**
- Web: `https://files.opendesk.hrz.uni-marburg.de`

**Features:**
- OIDC authentication with Keycloak
- Auto-provisioning of user accounts
- Multi-user support
- RWX storage on CephFS
- Backchannel logout support
- REST API with CS3 interface

**Persistence:**
- Size: 100Gi
- Storage Class: ceph-cephfs-hdd-ec
- Access Mode: ReadWriteMany

**Replicas:** 2

**Resources:**
- From global resources configuration

## Deployment Scripts

Three deployment scripts were created:

### 1. `./opendesk-edu/scripts/deploy-stalwart.sh`
Deploys only Stalwart Mail Server

**Usage:**
```bash
# Deploy
./deploy-stalwart.sh

# Dry run
./deploy-stalwart.sh --diff

# Verbose
./deploy-stalwart.sh --verbose

# Specific environment
ENVIRONMENT=edu-test ./deploy-stalwart.sh
```

### 2. `./opendesk-edu/scripts/deploy-opencloud.sh`
Deploys only OpenCloud

**Usage:**
```bash
# Deploy
./deploy-opencloud.sh

# Dry run
./deploy-opencloud.sh --diff

# Specific environment
ENVIRONMENT=edu-test ./deploy-opencloud.sh
```

### 3. `./opendesk-edu/scripts/deploy-stalwart-opencloud.sh`
Deploys both services together

**Usage:**
```bash
# Deploy both
./deploy-stalwart-opencloud.sh

# Deploy only Stalwart
./deploy-stalwart-opencloud.sh --stalwart

# Deploy only OpenCloud
./deploy-stalwart-opencloud.sh --opencloud

# Dry run
./deploy-stalwart-opencloud.sh --diff
```

## Quick Start

### 1. Generate Secrets

Before deploying, generate all required secrets:

```bash
# Stalwart
STALWART_ADMIN_PASSWORD="your-secure-admin-password"
STALWART_ADMIN_HASH=$(openssl passwd -6 "$STALWART_ADMIN_PASSWORD")
STALWART_OIDC_SECRET=$(openssl rand -hex 32)
LDAP_BIND_PASSWORD="your-ldap-bind-password"

# OpenCloud
OPENCLOUD_OIDC_SECRET=$(openssl rand -hex 32)
OPENCLOUD_JWT_SECRET=$(openssl rand -hex 32)
OPENCLOUD_TRANSFER_SECRET=$(openssl rand -hex 32)
OPENCLOUD_MACHINE_AUTH_KEY=$(openssl rand -hex 32)
OPENCLOUD_SYSTEM_USER_KEY=$(openssl rand -hex 32)
OPENCLOUD_SYSTEM_USER_ID=$(openssl rand -hex 16)
OPENCLOUD_URL_SIGNING_SECRET=$(openssl rand -hex 32)
OPENCLOUD_BACKCHANNEL_SECRET=$(openssl rand -hex 32)
```

### 2. Update Secrets File

Edit `./opendesk-edu/helmfile/environments/edu/secrets.yaml` and replace all `changeme-replace-with-actual-secret` placeholders with the generated secrets.

### 3. Register OIDC Clients in Keycloak

Register both services in Keycloak:

**Stalwart:**
- Client ID: `stalwart`
- Secret: `$STALWART_OIDC_SECRET`
- Redirect URIs: `https://mail.opendesk.hrz.uni-marburg.de/*`, `https://portal.opendesk.hrz.uni-marburg.de/*`
- Protocol: openid-connect
- Access Type: confidential

**OpenCloud:**
- Client ID: `opendesk-opencloud`
- Secret: `$OPENCLOUD_OIDC_SECRET`
- Redirect URIs: `https://files.opendesk.hrz.uni-marburg.de/*`, `https://portal.opendesk.hrz.uni-marburg.de/*`
- Protocol: openid-connect
- Access Type: confidential
- Backchannel Logout URL: `https://files.opendesk.hrz.uni-marburg.de/backchannel_logout`

### 4. Deploy

Using the main deploy script:
```bash
cd ./opendesk-edu
./deploy.sh --diff  # Review changes
./deploy.sh        # Deploy everything
```

Or deploy just these two services:
```bash
./scripts/deploy-stalwart-opencloud.sh
```

### 5. Verify Deployment

```bash
# Check Stalwart
kubectl get pods -l component=stalwart
kubectl logs -f deployment/stalwart
kubectl get svc stalwart

# Check OpenCloud
kubectl get pods -l component=opencloud
kubectl logs -f deployment/opendesk-opencloud
kubectl get svc opendesk-opencloud

# Test access
curl -k https://mail.opendesk.hrz.uni-marburg.de/api/health
curl -k https://files.opendesk.hrz.uni-marburg.de/status.php
```

## Post-Deployment Tasks

### For Stalwart:
1. Configure mail domains in admin console
2. Set up DNS MX, SPF, DKIM, DMARC records
3. Test mail flow (sending/receiving)
4. Configure backup for Stalwart PVC

### For OpenCloud:
1. Verify OIDC login flow
2. Test auto-provisioning of new users
3. Test file upload/download
4. Configure backup for OpenCloud PVC (already in k8up)

## Configuration Files

| Service | Chart | Values | Helmfile |
|---------|-------|--------|----------|
| Stalwart | `./helmfile/charts/stalwart/` | `./helmfile/apps/edu/stalwart/values.yaml.gotmpl` | `./helmfile/apps/edu/stalwart/helmfile-child.yaml.gotmpl` |
| OpenCloud | `./helmfile/charts/opencloud/` | `./helmfile/apps/edu/opencloud/values.yaml.gotmpl` | `./helmfile/apps/edu/opencloud/helmfile-child.yaml.gotmpl` |

## Environment Configuration

| File | Purpose |
|------|---------|
| `./helmfile/environments/edu/ce-overrides.yaml` | Edu-specific CE overrides |
| `./helmfile/environments/edu/secrets.yaml` | Secret configuration |
| `./helmfile/environments/edu/images.yaml` | Image registry/version configuration |

## Integration Points

Both services integrate with:

1. **Keycloak** - OIDC authentication provider
   - Realm: opendesk
   - Clients: stalwart, opendesk-opencloud

2. **LDAP** - User directory
   - Server: ums-ldap.opendesk.hrz.uni-marburg.de:636
   - Base DN: dc=uni-marburg,dc=de

3. **HAProxy Ingress** - TLS termination
   - Ingress class: haproxy
   - TLS secret: opendesk-certificates-tls

4. **Ceph Storage**
   - Stalwart: ceph-rbd-ssd (RWO)
   - OpenCloud: ceph-cephfs-hdd-ec (RWX)

5. **Network Policies** - Restrict pod-to-pod communication

## Troubleshooting

### Stalwart Issues

**Q: Pods crash on startup**
- Check LDAP connectivity: `kubectl exec -it stalwart-0 -- nc -zv ums-ldap 636`
- Verify OIDC issuer URL: `kubectl exec -it stalwart-0 -- curl -k https://portal.opendesk.hrz.uni-marburg.de/realms/opendesk/.well-known/openid-configuration`
- Check logs: `kubectl logs -f deployment/stalwart`

**Q: OIDC login fails**
- Verify client ID and secret match Keycloak configuration
- Check redirect URIs in Keycloak client settings
- Test OIDC flow: `kubectl exec -it stalwart-0 -- curl -k http://localhost:8080/api/health`

**Q: TLS errors**
- Ensure TLS certificates are mounted: `kubectl exec -it stalwart-0 -- ls -la /etc/ssl/certs/`
- Verify certificate paths in config: `kubectl get configmap stalwart-config -o yaml`

### OpenCloud Issues

**Q: OIDC authentication redirect loop**
- Verify issuer URL in OpenCloud config matches Keycloak
- Check client secret: `kubectl get secret opendesk-opencloud-secrets -o yaml`
- Verify redirect URIs in Keycloak include files.* domain

**Q: Storage not writable**
- Check PVC status: `kubectl get pvc opendesk-opencloud-data`
- Verify storage class: `kubectl get sc ceph-cephfs-hdd-ec`
- Test write: `kubectl exec -it opendesk-opencloud-0 -- touch /var/lib/opencloud/testfile`

**Q: Backchannel logout not working**
- Verify backchannel logout URL in Keycloak: `https://files.opendesk.hrz.uni-marburg.de/backchannel_logout`
- Check backchannel secret matches in Keycloak and OpenCloud config
- Verify log level: increase to debug in OpenCloud config

## Monitoring

### Stalwart

```bash
# Health check
kubectl exec -it stalwart-0 -- curl http://localhost:8080/api/health

# Metrics
kubectl top pods -l component=stalwart
kubectl get hpa -l component=stalwart

# Logs
kubectl logs -f deployment/stalwart --tail=100
```

### OpenCloud

```bash
# Status
kubectl exec -it opendesk-opencloud-0 -- curl http://localhost:8080/status.php

# Metrics
kubectl top pods -l component=opencloud

# Logs
kubectl logs -f deployment/opendesk-opencloud --tail=100
```

## Upgrading

### Upgrade Stalwart

```bash
# Update image tag in helmfile/environments/edu/images.yaml
images:
  stalwart:
    tag: v1.1.0

# Deploy
cd ./opendesk-edu
./scripts/deploy-stalwart.sh
```

### Upgrade OpenCloud

```bash
# Update image tag in helmfile/environments/edu/images.yaml
images:
  opencloud:
    tag: 5.0.0

# Deploy
cd ./opendesk-edu
./scripts/deploy-opencloud.sh
```

## Rollback

```bash
# View release history
helmfile -e edu history

# Rollback to previous revision (Stalwart)
helmfile -e edu rollback stalwart <revision-number>

# Rollback to previous revision (OpenCloud)
helmfile -e edu rollback opendesk-opencloud <revision-number>
```

## Security Considerations

1. **TLS:** Both services use TLS for all external communications
2. **Authentication:** OIDC with Keycloak provides SSO and strong authentication
3. **Authorization:** Role-based access control via Keycloak roles
4. **Network:** Network policies restrict pod-to-pod communication
5. **Container Security:** Non-root users, read-only filesystems, capability drops
6. **Rate Limiting:** Stalwart has configurable rate limits to prevent abuse

## Known Limitations

1. **Stalwart Multi-Replica:** RocksDB requires ReadWriteMany storage for multi-replica deployments. Currently configured for single replica with RWO storage.

2. **Large File Uploads:** OpenCloud has a default 100MB upload limit configured via ingress annotations. Larger files may need chunking.

3. **LDAP TLS Verification:** Stalwart does not verify LDAP server certificates by default. For production, configure CA certificates.

4. **OIDC Discovery Cache:** OpenCloud caches OIDC discovery documents. Changes to Keycloak may take time to propagate.

## Additional Resources

- [Full Deployment Guide](../services-stalwart-opencloud.md)
- [Stalwart Documentation](https://docs.stalwartlabs.com/)
- [OpenCloud Documentation](https://opencloudeu.github.io/opencloud/)
- [openDesk Edu Architecture](../architecture.md)

## Support

For issues:
1. Check this documentation
2. Review logs with `kubectl logs`
3. Describe resources with `kubectl describe`
4. Open an issue in the repository with:
   - Error messages
   - Logs
   - Configuration snippets
   - Steps to reproduce

# Internal Certificate Authority: openDesk CA

## Overview

The `opendesk-ca` is a self-signed root Certificate Authority (CA) used for issuing TLS certificates to openDesk services. It is managed by cert-manager as a ClusterIssuer:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: opendesk-ca
spec:
  ca:
    secretName: opendesk-root-ca-secret
```

## Certificate Details

| Field | Value |
|-------|-------|
| **Common Name** | openDesk Root CA |
| **Organization** | Not specified in cert |
| **Expiry** | 2026-10-19 (81 days from 2026-07-29) |
| **Key Algorithm** | RSA (4096-bit) |
| **Secret Location** | `opendesk/opendesk-root-ca-secret` |
| **Key Secret Location** | `opendesk/opendesk-root-ca-secret` (includes `ca.crt`, `ca.key`) |

## Service Certificate Template

Individual service certificates are issued via Certificate resources:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: SERVICE_NAME-tls
  namespace: opendesk
spec:
  secretName: SERVICE_NAME-tls
  issuerRef:
    name: opendesk-ca
    kind: ClusterIssuer
  dnsNames:
    - SERVICE_NAME.home.opendesk-edu.org
```

### Current Service Certificates

As of 2026-07-29, cert-manager has issued certificates for:
- bookstack-tls → wiki.home.opendesk-edu.org
- collabora-tls → office.home.opendesk-edu.org
- drawio-tls → drawio.home.opendesk-edu.org
- element-tls → chat.home.opendesk-edu.org.uni-OpenDesk.de
- excalidraw-tls → excalidraw.home.opendesk-edu.org
- grafana-tls → grafana.home.opendesk-edu.org
- ilias-tls → lms.home.opendesk-edu.org
- intercom-tls → ics.home.opendesk-edu.org
- jitsi-tls → meet.home.opendesk-edu.org
- keycloak-tls → id.home.opendesk-edu.org
- moodle-tls → moodle.home.opendesk-edu.org
- opencloud-tls → files.home.opendesk-edu.org
- openproject-tls → projects.home.opendesk-edu.org
- planka-tls → planka.home.opendesk-edu.org
- portal-tls → portal.home.opendesk-edu.org
- seaweedfs-tls → objectstorage.home.opendesk-edu.org
- seaweedfs-admin-tls → objectstorage-ui.home.opendesk-edu.org
- sogo-tls → contacts.home.opendesk-edu.org
- ssp-tls → ssp.home.opendesk-edu.org
- stalwart-tls → mail.home.opendesk-edu.org
- webmail-tls → webmail.home.opendesk-edu.org
- xwiki-tls → wiki.home.opendesk-edu.org

Each certificate has:
- 89-day validity (until 2026-10-27)
- RSA 2048-bit key
- Signed by `opendesk-ca`

---

## Key Rotation

The CA key is stored in the secret `opendesk-root-ca-secret` in the `opendesk` namespace:

```bash
# Extract the CA certificate
kubectl get secret -n opendesk opendesk-root-ca-secret -o json | \
  jq -r '.data["ca.crt"]' | base64 -d

# Extract the CA private key (BE VERY CAREFUL WITH THIS!)
kubectl get secret -n opendesk opendesk-root-ca-secret -o json | \
  jq -r '.data["ca.key"]' | base64 -d
```

**Security Note:** The CA private key should be protected with strict access controls. Only cluster administrators should have access.

### Rotation Procedure

1. **Create new CA key pair:**
   ```bash
   openssl genrsa -out new-ca.key 4096
   openssl req -x509 -new -nodes -key new-ca.key -sha256 -days 3650 \
     -subj "/CN=openDesk Root CA/O=Kubernetes OpenDesk" -out new-ca.crt
   ```

2. **Create new ClusterIssuer:**
   ```yaml
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: opendesk-ca-v2
   spec:
     ca:
       secretName: opendesk-root-ca-secret-v2
   ```

3. **Re-issue all service certificates:** Point Certificate resources to the new issuer

4. **Phase out old CA:** Once all certificates are re-issued, the old CA can be removed

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Browser shows "Your connection is not private" | Trust the openDesk CA in your system's trust store |
| `openssl verify` fails | Certificate chain is incomplete | Use full chain: cat cert.crt ca.crt |
| cert-manager Certificate stuck at "Pending" | Check cert-manager logs | `kubectl logs -n cert-manager -l app=cert-manager` |
| Root CA expired | Create new CA and re-issue all certs | Follow rotation procedure above |

### Verify CA Health

```bash
# Check ClusterIssuer status
kubectl get clusterissuer opendesk-ca -o yaml | grep -A5 "status:"

# Check all Certificates
kubectl get certificates -n opendesk
```

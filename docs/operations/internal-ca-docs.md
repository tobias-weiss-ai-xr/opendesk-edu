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
    - SERVICE_NAME.opendesk.hrz.uni-marburg.de
```

### Current Service Certificates

As of 2026-07-29, cert-manager has issued certificates for:
- bookstack-tls → wiki.opendesk.hrz.uni-marburg.de
- collabora-tls → office.opendesk.hrz.uni-marburg.de
- drawio-tls → drawio.opendesk.hrz.uni-marburg.de
- element-tls → chat.opendesk.hrz.uni-Marburg.de
- excalidraw-tls → excalidraw.opendesk.hrz.uni-marburg.de
- grafana-tls → grafana.opendesk.hrz.uni-marburg.de
- ilias-tls → lms.opendesk.hrz.uni-marburg.de
- intercom-tls → ics.opendesk.hrz.uni-marburg.de
- jitsi-tls → meet.opendesk.hrz.uni-marburg.de
- keycloak-tls → id.opendesk.hrz.uni-marburg.de
- moodle-tls → moodle.opendesk.hrz.uni-marburg.de
- opencloud-tls → files.opendesk.hrz.uni-marburg.de
- openproject-tls → projects.opendesk.hrz.uni-marburg.de
- planka-tls → planka.opendesk.hrz.uni-marburg.de
- portal-tls → portal.opendesk.hrz.uni-marburg.de
- seaweedfs-tls → objectstorage.opendesk.hrz.uni-marburg.de
- seaweedfs-admin-tls → objectstorage-ui.opendesk.hrz.uni-marburg.de
- sogo-tls → contacts.opendesk.hrz.uni-marburg.de
- ssp-tls → ssp.opendesk.hrz.uni-marburg.de
- stalwart-tls → mail.opendesk.hrz.uni-marburg.de
- webmail-tls → webmail.opendesk.hrz.uni-marburg.de
- xwiki-tls → wiki.opendesk.hrz.uni-marburg.de

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
     -subj "/CN=openDesk Root CA/O=HRZ Marburg" -out new-ca.crt
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

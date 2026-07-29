# TLS Certificate Authority Trust Setup

**Status:** Self-signed internal CA (`opendesk-ca`) in use as of 2026-07-29

## Background

On July 29, 2026, we discovered that the GEANT wildcard TLS certificate for `*.opendesk.hrz.uni-marburg.de` had expired 8 days prior (2026-07-22). This certificate was used by 22 different services in the opendesk namespace.

Since Let's Encrypt HTTP01 validation cannot work with internal-only domains (*.opendesk.hrz.uni-marburg.de resolves to 192.168.3.201 — a private IP), we pivoted to using the existing **opendesk-ca** internal Certificate Authority.

### Certificate Issuer Chain

```
Internal App Certs ('expires: 2026-10-27')
    ↓ issued by
openDesk Root CA (expires: 2026-10-19)
```

All services now use individual certificates issued by `opendesk-ca`. This CA is already configured in cert-manager and has been used successfully for `grafana-tls` and `portal-tls` since before this issue.

## Impact

**New Browser Behavior:** Users accessing any openDesk service via HTTPS will see a **security warning** about the certificate not being trusted.

### Affected Services

All services under `*.opendesk.hrz.uni-marburg.de`:
- ILIAS (lms.opendesk.hrz.uni-marburg.de)
- Moodle (moodle.opendesk.hrz.uni-marburg.de)
- Bookstack (wiki.opendesk.hrz.uni-marburg.de)
- Draw.io (drawio.opendesk.hrz.uni-marburg.de)
- Excalidraw (excalidraw.opendesk.hrz.uni-Marburg.de)
- Collabora (office.opendesk.hrz.uni-marburg.de)
- Jitsi (meet.opendesk.hrz.uni-marburg.de)
- Nextcloud (files.opendesk.hrz.uni-marburg.de)
- OpenProject (projects.opendesk.hrz.uni-marburg.de)
- SeaweedFS (objectstorage.opendesk.hrz.uni-marburg.de)
- SOGo (contacts.opendesk.hrz.uni-marburg.de)
- Self-Service Password (ssp.opendesk.hrz.uni-marburg.de)
- Stalwart Mail (mail.opendesk.hrz.uni-marburg.de)
- Etherpad ( pad.opendesk.hrz.uni-marburg.de)
- And 8 more...

**Exception:** Grafana and Portal services were already using the internal CA, so they continued to show warnings but did not break.

## Solution: Trust the openDesk CA

### Option A: Automatic (Recommended for Domain-Joined HRZ Machines)

Windows machines joined to the HRZ domain should automatically receive the CA certificate via Group Policy. No user action required.

Linux machines managed by Puppet/Ansible: the CA will be pushed automatically to the system trust store.

### Option B: Manual Installation

If you see security warnings when accessing any openDesk service:

#### For Linux (Debian/Ubuntu)

```bash
# Get the CA certificate
kubectl get secret -n opendesk opendesk-root-ca-secret -o json | \
  jq -r '.data["tls.crt"]' | base64 -d > opendesk-ca.crt

# Install system-wide
sudo cp opendesk-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Verify
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt opendesk-ca.crt
```

#### For macOS

```bash
# Get the CA certificate
kubectl get secret -n opendesk opendesk-root-ca-secret -o json | \
  jq -r '.data["tls.crt"]' | base64 -d > opendesk-ca.crt

# Import via Keychain Access
# 1. Double-click opendesk-ca.crt
# 2. Add to "System" keychain
# 3. Set to "Always Trust"

# Verify
security find-certificate -c "openDesk Root CA" /Library/Keychains/System.keychain
```

#### For Windows

1. Download the CA certificate:
   ```powershell
   kubectl get secret -n opendesk opendesk-root-ca-secret -o json | `\
     python -c "import json,sys,base64; \
       print(base64.b64decode(json.load(sys.stdin)['data']['tls.crt']).decode())" > C:\temp\opendesk-ca.crt
   ```

2. Double-click `opendesk-ca.crt` in File Explorer
3. Select "Local Machine" store
4. Place in "Trusted Root Certification Authorities"
5. Click Finish and confirm

### Verify Installation

```bash
# Linux/macOS
curl -v https://lms.opendesk.hrz.uni-marburg.de 2>&1 | grep "subject=" || echo "Still trusted"

# Should show no certificate errors
```

## Future Work

### Option 1: DNS-01 Challenge Setup (Preferred)

Configure Let's Encrypt DNS-01 validation by:
1. Adding a DNS provider credential (e.g., Azure DNS, AWS Route53)
2. Updating the `letsencrypt-prod` ClusterIssuer with DNS-01 solver
3. Re-issuing certificates with Let's Encrypt

### Option 2: Renew GEANT Certificate

Contact the GEANT CA or HRZ network team to renew the wildcard certificate for `*.opendesk.hrz.uni-marburg.de`.

### Option 3: Split Domain Setup

- Use public domains (e.g., opendesk.hrz.uni-marburg.de resolves to public IP) for external access
- Keep internal-only subdomains for systems that shouldn't be publicly exposed
- Use Let's Encrypt for public domain certs, internal CA for private domains

---

## Long-Term Recommendation

**Implement Option 1 (DNS-01) + Option 3 (split domain)** for production use:
- Public-facing services get Let's Encrypt certs via DNS-01
- Internal-only services use the opendesk-ca
- Document the CA trust process for all internal services

This provides the best balance of security, operational simplicity, and user experience.

---

## Timeline

| Date | Event |
|------|-------|
| 2026-07-22 | GEANT wildcard cert expired |
| 2026-07-29 | Issue discovered during deep dive |
| 2026-07-29 | All 22 services migrated to opendesk-ca certs |
| 2026-07-29 | Certs expire on 2026-10-27 (89d lifetime) |
| 2026-10-19 | Root CA expires (81d from fix) |
| TBD | Implement DNS-01 for Let's Encrypt OR renew GEANT cert |

---

## References

- [cert-manager ApplicationSet documentation](https://cert-manager.io/docs/configuration/)
- [Let's Encrypt DNS-01 Documentation](https://letsencrypt.org/docs/integration-guide/#dns-01)
- [HRZ Internal CA Documentation](internal-ca-docs.md)

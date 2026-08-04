# openDesk TLS Certificate

## Current Certificate

- **Subject:** `CN=*.opendesk.hrz.uni-marburg.de` (Philipps-Universitaet Marburg)
- **Issuer:** `CN=GEANT TLS RSA 1` (Hellenic Academic and Research Institutions CA)
- **Valid from:** 2025-07-22
- **Valid until:** 2026-07-22
- **Chain:** 4 certs (server + GEANT TLS RSA 1 + HARICA TLS RSA Root CA 2021 + Hellenic RootCA 2015)

## Files

| File | Description |
|------|-------------|
| `opendesk-cert-chain.pem` | Full certificate chain (4 PEM certs) |
| `opendesk-cert-key.pem` | RSA private key |

## Deployment

The certificate is deployed as a Kubernetes TLS secret `opendesk-certificates-tls`
in both `opendesk` and `default` namespaces.

### Important: NO `ca.crt` field

The secret must NOT contain a `ca.crt` field. haproxy-ingress v0.15.1 uses `ca.crt`
as its root CA trust pool for chain verification. If `ca.crt` contains a different
root CA (e.g., a self-signed cert-manager CA), the verification fails and haproxy
falls back to the fake self-signed certificate.

Without `ca.crt`, haproxy-ingress v0.15.1 skips chain verification entirely and
serves the TLS cert as-is. The browser trusts it because the chain leads to
Hellenic RootCA 2015, which is in all major browser trust stores.

### Apply to cluster

```bash
# Apply to both namespaces
kubectl create secret tls opendesk-certificates-tls \
  --namespace opendesk \
  --cert opendesk-cert-chain.pem \
  --key opendesk-cert-key.pem \
  --dry-run=client -o yaml \
  | kubectl apply -f -

kubectl create secret tls opendesk-certificates-tls \
  --namespace default \
  --cert opendesk-cert-chain.pem \
  --key opendesk-cert-key.pem \
  --dry-run=client -o yaml \
  | kubectl apply -f -
```

### Prevent cert-manager interference

The secret has annotation `helm.sh/resource-policy: keep` to prevent Helm from
deleting it during upgrades. Certificate CRDs should NOT exist (they were deleted
to stop cert-manager from overwriting the manually-managed secret).

## Renewal

The certificate was obtained manually (not via cert-manager). Since the domains
are not publicly resolvable (NXDOMAIN from external DNS), Let's Encrypt HTTP-01
is not possible from outside the HRZ network.

### Options for renewal

1. **HTTP-01 from within HRZ network** — run certbot/acme.sh on a machine with
   direct access to the cluster ingress (192.168.3.201) or with DNS resolving
   `*.opendesk.hrz.uni-marburg.de` to `192.168.3.201`.

2. **DNS-01 challenge** — if HRZ manages the DNS zone, configure a TXT record
   for `_acme-challenge.opendesk.hrz.uni-marburg.de`. This allows renewal from
   anywhere without network access to the cluster.

### Renewal steps (HTTP-01 from HRZ machine)

```bash
# On a machine within HRZ network that can reach 192.168.3.201
certbot certonly --manual --preferred-challenges http \
  -d "*.opendesk.hrz.uni-marburg.de" \
  --server https://acme-v02.api.letsencrypt.org/directory \
  --agree-tos --email admin@hrz.uni-marburg.de

# The challenge will ask you to serve a file at:
# http://opendesk.hrz.uni-marburg.de/.well-known/acme-challenge/<token>
# This requires temporary Ingress/route for that path.

# After obtaining new cert:
cp /etc/letsencrypt/live/opendesk.hrz.uni-marburg.de/fullchain.pem opendesk-cert-chain.pem
cp /etc/letsencrypt/live/opendesk.hrz.uni-marburg.de/privkey.pem opendesk-cert-key.pem

# Apply to cluster (see "Apply to cluster" section above)
```

### Renewal deadline

**July 22, 2026** — Start renewal at least 7 days before expiry (July 15).

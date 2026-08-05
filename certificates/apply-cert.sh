#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT="${SCRIPT_DIR}/opendesk-cert-chain.pem"
KEY="${SCRIPT_DIR}/opendesk-cert-key.pem"

if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
  echo "ERROR: Missing cert files in $SCRIPT_DIR" >&2
  echo "  Expected: opendesk-cert-chain.pem, opendesk-cert-key.pem" >&2
  exit 1
fi

echo "=== Verifying cert ==="
openssl x509 -in "$CERT" -subject -issuer -dates -noout
echo ""
CERT_COUNT=$(grep -c "BEGIN CERTIFICATE" "$CERT")
echo "Chain has $CERT_COUNT certs"
echo ""

echo "=== Applying to opendesk namespace ==="
kubectl create secret tls opendesk-certificates-tls \
  --namespace opendesk \
  --cert "$CERT" \
  --key "$KEY" \
  --dry-run=client -o yaml | kubectl apply -f -
echo ""

echo "=== Applying to default namespace ==="
kubectl create secret tls opendesk-certificates-tls \
  --namespace default \
  --cert "$CERT" \
  --key "$KEY" \
  --dry-run=client -o yaml | kubectl apply -f -
echo ""

echo "=== Verifying secrets ==="
echo "opendesk:" && kubectl get secret opendesk-certificates-tls -n opendesk -o jsonpath='{.data | keys}' 2>&1
echo "default:" && kubectl get secret opendesk-certificates-tls -n default -o jsonpath='{.data | keys}' 2>&1
echo ""

echo "=== Verifying served cert ==="
echo Q | openssl s_client -connect 192.168.3.201:443 -servername opendesk.hrz.uni-marburg.de 2>/dev/null \
  | openssl x509 -subject -issuer -dates -noout
echo ""
echo "Done."

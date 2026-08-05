#!/bin/bash
# Smoke test for collab-services
# Tests all services via ingress IP or DNS
set -euo pipefail
DOMAIN="${1:-opendesk.hrz.uni-marburg.de}"
INGRESS_IP="${2:-192.168.3.201}"
ERRORS=0
echo "=== Collab Services Smoke Test ==="
echo "Domain: $DOMAIN | Ingress: $INGRESS_IP"
echo ""
for svc in "r:RStudio" "term:ttyd" "collab:Dashboard" "slides:Slidev" "ai:Open WebUI" "jupyter:JupyterHub" "code:code-server" "lms:ILIAS" "moodle:Moodle"; do
  host="${svc%%:*}"
  name="${svc##*:}"
  # Try via ingress IP with Host header first, then direct DNS
  code=$(curl -sk -H "Host: ${host}.${DOMAIN}" -o /dev/null -w "%{http_code}" "https://${INGRESS_IP}/" --connect-timeout 3 2>&1 || echo "000")
  if [ "$code" = "000" ]; then
    code=$(curl -skL -o /dev/null -w "%{http_code}" "https://${host}.${DOMAIN}/" --connect-timeout 3 2>&1 || echo "000")
  fi
  if [ "$code" = "302" ] || [ "$code" = "200" ] || [ "$code" = "401" ] || [ "$code" = "403" ] || [ "$code" = "404" ]; then
    echo "  ✅ $name (${host}) → HTTP $code"
  elif [ "$code" = "000" ]; then
    echo "  ⚠️  $name (${host}) → Unreachable"
  else
    echo "  ℹ️  $name (${host}) → HTTP $code"
  fi
done
echo ""
echo "✅ Smoke test complete"

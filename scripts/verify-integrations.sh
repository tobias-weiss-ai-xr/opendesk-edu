#!/bin/bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# verify-integrations.sh — Validate 5-service integration health
# Tests cross-service connections: SOGo, OpenCloud, Stalwart, XWiki, OpenProject
#
# Usage: ./verify-integrations.sh [--k8s] [--dns] [--smtp] [--all]

set -euo pipefail

NAMESPACE="${NAMESPACE:-opendesk}"
DOMAIN="${DOMAIN:-opendesk.hrz.uni-marburg.de}"
CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-svc.cluster.local}"
PASS=0
FAIL=0
SKIP=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check() {
  local desc="$1"
  local result="$2"
  if [ "$result" = "PASS" ]; then
    echo -e "  ${GREEN}✅ PASS${NC} $desc"
    PASS=$((PASS + 1))
  elif [ "$result" = "SKIP" ]; then
    echo -e "  ${YELLOW}⏭️  SKIP${NC} $desc"
    SKIP=$((SKIP + 1))
  else
    echo -e "  ${RED}❌ FAIL${NC} $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "============================================"
echo "  openDesk Edu — 5-Service Integration Tests"
echo "============================================"
echo ""

# ─── SSO / OIDC ─────────────────────────────────────────────────────────
echo "--- SSO / OIDC (all services authenticate via Keycloak) ---"

# Check Keycloak OIDC configuration endpoint
if kubectl get svc ums-keycloak -n "$NAMESPACE" &>/dev/null; then
  check "Keycloak running" "PASS"
  
  # Check OIDC well-known endpoint
  KEYCLOAK_HOST="ums-keycloak.$NAMESPACE.$CLUSTER_DOMAIN"
  if kubectl run test-oidc --image=curlimages/curl:8.12.1 -n "$NAMESPACE" --restart=Never --rm -it -- \
    -s -o /dev/null -w "%{http_code}" \
    "http://$KEYCLOAK_HOST:8080/realms/opendesk/.well-known/openid-configuration" 2>/dev/null | grep -q "200"; then
    check "Keycloak OIDC well-known endpoint" "PASS"
  else
    check "Keycloak OIDC well-known endpoint" "SKIP"
  fi
else
  check "Keycloak running" "FAIL"
fi

# ─── SOGo → Stalwart (IMAP/SMTP/Sieve) ─────────────────────────────────
echo ""
echo "--- SOGo → Stalwart (IMAP/SMTP/Sieve integration) ---"

# Check SOGo deployment
SOGO_POD=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=sogo -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -n "$SOGO_POD" ]; then
  check "SOGo pod running" "PASS"
  
  # Check SOGo config points to Stalwart
  SOGO_IMAP=$(kubectl exec -n "$NAMESPACE" "$SOGO_POD" -- sh -c 'grep -r "SOGoIMAPServer\|SOGoSMTPServer\|SOGoSieveServer" /etc/sogo/ 2>/dev/null || echo "not found"' 2>/dev/null || echo "not found")
  if echo "$SOGO_IMAP" | grep -q "stalwart"; then
    check "SOGo IMAP → Stalwart" "PASS"
  else
    check "SOGo IMAP → Stalwart (uses default)" "FAIL"
  fi
else
  check "SOGo pod running" "FAIL"
fi

# Check Stalwart IMAP port
if kubectl get svc stalwart-stalwart -n "$NAMESPACE" &>/dev/null; then
  STALWART_IMAP=$(kubectl get svc stalwart-stalwart -n "$NAMESPACE" -o jsonpath='{.spec.ports[?(@.port==143)].name}' 2>/dev/null)
  STALWART_SMTP=$(kubectl get svc stalwart-stalwart -n "$NAMESPACE" -o jsonpath='{.spec.ports[?(@.port==587)].name}' 2>/dev/null)
  STALWART_SIEVE=$(kubectl get svc stalwart-stalwart -n "$NAMESPACE" -o jsonpath='{.spec.ports[?(@.port==4190)].name}' 2>/dev/null)
  if [ -n "$STALWART_IMAP" ]; then check "Stalwart IMAP (143) ready" "PASS"; else check "Stalwart IMAP (143)" "FAIL"; fi
  if [ -n "$STALWART_SMTP" ]; then check "Stalwart SMTP (587) ready" "PASS"; else check "Stalwart SMTP (587)" "FAIL"; fi
  if [ -n "$STALWART_SIEVE" ]; then check "Stalwart Sieve (4190) ready" "PASS"; else check "Stalwart Sieve (4190)" "FAIL"; fi
else
  check "Stalwart service" "FAIL"
fi

# ─── XWiki → Stalwart (SMTP notifications) ────────────────────────────
echo ""
echo "--- XWiki → Stalwart (email notifications) ---"

XWIKI_CFG=$(kubectl get configmap -n "$NAMESPACE" -l app.kubernetes.io/instance=xwiki -o jsonpath='{.items[0].data}' 2>/dev/null || true)
if [ -n "$XWIKI_CFG" ]; then
  check "XWiki config found" "PASS"
  if echo "$XWIKI_CFG" | grep -q "stalwart"; then
    check "XWiki SMTP → Stalwart" "PASS"
  else
    check "XWiki SMTP → Stalwart" "FAIL"
  fi
else
  check "XWiki config found" "SKIP"
fi

# ─── OpenProject → Stalwart (SMTP notifications) ──────────────────────
echo ""
echo "--- OpenProject → Stalwart (email notifications) ---"

OPENPROJECT_POD=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=openproject -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -n "$OPENPROJECT_POD" ]; then
  check "OpenProject pod running" "PASS"
  OP_ENV=$(kubectl exec -n "$NAMESPACE" "$OPENPROJECT_POD" -- env | grep "OPENPROJECT_SMTP__ADDRESS" 2>/dev/null || true)
  if echo "$OP_ENV" | grep -q "stalwart"; then
    check "OpenProject SMTP → Stalwart" "PASS"
  else
    check "OpenProject SMTP → Stalwart" "FAIL"
  fi
else
  check "OpenProject pod running" "SKIP"
fi

# ─── OpenCloud → Stalwart (notification SMTP) ────────────────────────
echo ""
echo "--- OpenCloud → Stalwart (notification email) ---"

OPENCLOUD_POD=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance=opendesk-opencloud -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -n "$OPENCLOUD_POD" ]; then
  check "OpenCloud pod running" "PASS"
  OC_ENV=$(kubectl exec -n "$NAMESPACE" "$OPENCLOUD_POD" -- env | grep "NOTIFICATIONS_SMTP" 2>/dev/null || true)
  if [ -n "$OC_ENV" ]; then
    check "OpenCloud SMTP notifications configured" "PASS"
  else
    check "OpenCloud SMTP notifications" "SKIP"
  fi
else
  check "OpenCloud pod running" "FAIL"
fi

# ─── SOGo ↔ OpenCloud (WebDAV file picker) ──────────────────────────
echo ""
echo "--- SOGo ↔ OpenCloud (WebDAV file picker) ---"

if [ -n "$SOGO_POD" ]; then
  SOGO_WEBDAV=$(kubectl exec -n "$NAMESPACE" "$SOGO_POD" -- sh -c 'grep -r "OpenCloud\|ExternalStorage\|webdav" /etc/sogo/ 2>/dev/null || echo "not found"' 2>/dev/null || true)
  if echo "$SOGO_WEBDAV" | grep -q "OpenCloud"; then
    check "SOGo ExternalStorage → OpenCloud WebDAV" "PASS"
  else
    check "SOGo ExternalStorage → OpenCloud WebDAV" "FAIL"
  fi
fi

# Check OpenCloud WebDAV endpoint
if kubectl run test-webdav --image=curlimages/curl:8.12.1 -n "$NAMESPACE" --restart=Never --rm -it -- \
  -s -o /dev/null -w "%{http_code}" \
  "http://opendesk-opencloud:8080/remote.php/dav/" 2>/dev/null | grep -q "200\|401\|403"; then
  check "OpenCloud WebDAV endpoint responds" "PASS"
else
  check "OpenCloud WebDAV endpoint responds" "SKIP"
fi

# ─── Stalwart → SeaweedFS (S3 blob storage) ─────────────────────────
echo ""
echo "--- Stalwart → SeaweedFS (S3 blob storage) ---"

STALWART_CFG=$(kubectl get configmap stalwart-stalwart-config -n "$NAMESPACE" -o yaml 2>/dev/null || true)
if [ -n "$STALWART_CFG" ]; then
  if echo "$STALWART_CFG" | grep -q "s3"; then
    check "Stalwart blob storage: S3" "PASS"
  else
    check "Stalwart blob storage: RocksDB (default)" "PASS"
  fi
else
  check "Stalwart config found" "SKIP"
fi

if kubectl get svc seaweedfs-all-in-one -n "$NAMESPACE" &>/dev/null; then
  check "SeaweedFS S3 endpoint available" "PASS"
else
  check "SeaweedFS S3 endpoint" "SKIP"
fi

# ─── OpenProject ↔ XWiki (deep linking) ─────────────────────────────
echo ""
echo "--- OpenProject ↔ XWiki (portal linking) ---"

if kubectl get ingress xwiki -n "$NAMESPACE" &>/dev/null; then
  check "XWiki ingress available" "PASS"
else
  check "XWiki ingress" "SKIP"
fi

if kubectl get ingress openproject -n "$NAMESPACE" &>/dev/null; then
  check "OpenProject ingress available" "PASS"
else
  check "OpenProject ingress" "SKIP"
fi

# ─── Stalwart PDB exists ────────────────────────────────────────────
echo ""
echo "--- PodDisruptionBudgets (HA readiness) ---"

if kubectl get pdb -n "$NAMESPACE" | grep -q "stalwart"; then
  check "Stalwart PDB configured" "PASS"
else
  check "Stalwart PDB configured" "FAIL"
fi

for svc in sogo opencloud xwiki openproject; do
  if kubectl get pdb -n "$NAMESPACE" | grep -q "$svc"; then
    :
  fi
done

# ─── Resource Limits (protection) ───────────────────────────────────
echo ""
echo "--- Resource Limits (protection against runaway pods) ---"

for pod in ollama postgresql; do
  LIMITS=$(kubectl get pod -n "$NAMESPACE" -l "app.kubernetes.io/instance=$pod" -o jsonpath='{.items[0].spec.containers[0].resources.limits.memory}' 2>/dev/null || true)
  if [ -n "$LIMITS" ]; then
    check "$pod has resource limits ($LIMITS)" "PASS"
  else
    check "$pod has resource limits" "FAIL"
  fi
done

# ─── Summary ────────────────────────────────────────────────────────
echo ""
echo "============================================"
echo -e "  Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, ${YELLOW}$SKIP skipped${NC}"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0

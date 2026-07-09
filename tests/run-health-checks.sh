#!/bin/bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# openDesk Edu Service Health Checks
# Run: bash tests/run-health-checks.sh [namespace] [domain]

set -euo pipefail

NAMESPACE=${1:-opendesk}
DOMAIN=${2:-opendesk.hrz.uni-marburg.de}
FAILURES=0

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

check() {
  local name=$1
  local cmd=$2
  local expected=$3
  echo -n "  [*] $name... "
  result=$(eval "$cmd" 2>/dev/null || true)
  if echo "$result" | grep -q "$expected"; then
    echo -e "${GREEN}PASS${NC}"
  else
    echo -e "${RED}FAIL${NC} (expected: $expected, got: $result)"
    FAILURES=$((FAILURES + 1))
  fi
}

echo "=========================================="
echo " openDesk Edu Service Health Checks"
echo " Namespace: $NAMESPACE"
echo " Date: $(date -u)"
echo "=========================================="
echo ""

# --- ILIAS ---
echo "--- ILIAS ---"
check "Pods (app+ilserver)" \
  "kubectl get pods -n $NAMESPACE -l app.kubernetes.io/instance=ilias --no-headers -o name 2>/dev/null | wc -l" \
  "2"
check "HTTPS (302=redirect)" \
  "kubectl exec -n $NAMESPACE deploy/ilias-ilias -c ilias -- curl -sk -o /dev/null -w '%{http_code}' https://localhost:8443/login.php 2>/dev/null" \
  "302"
check "PHP >= 8.1" \
  "kubectl exec -n $NAMESPACE deploy/ilias-ilias -c ilias -- php -r 'echo PHP_MAJOR_VERSION;' 2>/dev/null" \
  "8"
check "DB config present" \
  "kubectl exec -n $NAMESPACE deploy/ilias-ilias -c ilias -- grep -c 'host = mariadb' /var/www/html/data/default/client.ini.php 2>/dev/null" \
  "1"
check "Ingress host" \
  "kubectl get ingress -n $NAMESPACE ilias-ilias-ingress -o jsonpath='{.spec.rules[0].host}' 2>/dev/null" \
  "lms"

# --- SOGo ---
echo ""
echo "--- SOGo ---"
check "Pod running" \
  "kubectl get pods -n $NAMESPACE -l app.kubernetes.io/instance=sogo --no-headers -o name 2>/dev/null | wc -l" \
  "1"
check "HTTP 200" \
  "kubectl exec -n $NAMESPACE deploy/sogo-sogo -- curl -s -o /dev/null -w '%{http_code}' -H 'Host: sogo.$DOMAIN' http://localhost/SOGo/ 2>/dev/null" \
  "200"
check "Ingress hosts (3)" \
  "kubectl get ingress -n $NAMESPACE sogo-sogo-ingress -o jsonpath='{range .spec.rules[*]}{.host}{\"\n\"}{end}' 2>/dev/null | grep -c '.'" \
  "3"

# --- OpenCloud ---
echo ""
echo "--- OpenCloud ---"
check "Pods running (2)" \
  "kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=opencloud --no-headers -o name 2>/dev/null | wc -l" \
  "2"
check "Status endpoint 200" \
  "kubectl exec -n $NAMESPACE deploy/opendesk-opencloud -- curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/status.php 2>/dev/null" \
  "200"
check "Root HTTP 200" \
  "kubectl exec -n $NAMESPACE deploy/opendesk-opencloud -- curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/ 2>/dev/null" \
  "200"
check "Replicas (2)" \
  "kubectl get deploy -n $NAMESPACE opendesk-opencloud -o jsonpath='{.spec.replicas}' 2>/dev/null" \
  "2"
check "Storage 100Gi" \
  "kubectl get pvc -n $NAMESPACE opendesk-opencloud-data -o jsonpath='{.status.capacity.storage}' 2>/dev/null" \
  "100Gi"

# --- Intercom Service (ICS Fork) ---
echo ""
echo "--- Intercom Service (ICS Fork) ---"
check "Pod running" \
  "kubectl get pods -n $NAMESPACE -l app.kubernetes.io/instance=intercom-service --no-headers -o name 2>/dev/null | wc -l" \
  "1"
check "Health endpoint" \
  "kubectl exec -n $NAMESPACE deploy/intercom-service -- curl -s http://localhost:8080/health 2>/dev/null" \
  '{"status":"ok"}'
check "OC_ENABLED=true" \
  "kubectl exec -n $NAMESPACE deploy/intercom-service -- sh -c 'echo \$OC_ENABLED' 2>/dev/null" \
  "true"
check "SOGO_ENABLED=true" \
  "kubectl exec -n $NAMESPACE deploy/intercom-service -- sh -c 'echo \$SOGO_ENABLED' 2>/dev/null" \
  "true"
check "ILIAS_ENABLED=true" \
  "kubectl exec -n $NAMESPACE deploy/intercom-service -- sh -c 'echo \$ILIAS_ENABLED' 2>/dev/null" \
  "true"
check "OC route (302)" \
  "kubectl exec -n $NAMESPACE deploy/intercom-service -- curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/oc/ 2>/dev/null" \
  "302"
check "SOGo route (302)" \
  "kubectl exec -n $NAMESPACE deploy/intercom-service -- curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/sogo/ 2>/dev/null" \
  "302"
check "ILIAS route (302)" \
  "kubectl exec -n $NAMESPACE deploy/intercom-service -- curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/ilias/ 2>/dev/null" \
  "302"
check "OC proxy URL matches domain" \
  "kubectl exec -n $NAMESPACE deploy/intercom-service -- sh -c 'echo \$OC_URL' 2>/dev/null" \
  "$DOMAIN"
check "SOGo proxy URL matches domain" \
  "kubectl exec -n $NAMESPACE deploy/intercom-service -- sh -c 'echo \$SOGO_URL' 2>/dev/null" \
  "$DOMAIN"
check "ILIAS proxy URL matches domain" \
  "kubectl exec -n $NAMESPACE deploy/intercom-service -- sh -c 'echo \$ILIAS_URL' 2>/dev/null" \
  "$DOMAIN"

echo ""
echo "=========================================="
if [ $FAILURES -eq 0 ]; then
  echo -e " ${GREEN}All checks passed!${NC}"
else
  echo -e " ${RED}$FAILURES check(s) failed${NC}"
fi
echo "=========================================="
exit $FAILURES

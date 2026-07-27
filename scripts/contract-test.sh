#!/bin/bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# contract-test.sh — Cross-service contract verification
# Validates specifications and contracts between deployed services.
#
# Usage: ./contract-test.sh [oidc|network|storage|data|all]

NAMESPACE="${NAMESPACE:-opendesk}"
PASS=0; FAIL=0; SKIP=0

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
pass() { echo -e "  ${GREEN}✅ PASS${NC} $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}❌ FAIL${NC} $1"; FAIL=$((FAIL+1)); }
skip() { echo -e "  ${YELLOW}⏭️  SKIP${NC} $1"; SKIP=$((SKIP+1)); }

# Parse layer argument
RUN_OIDC=false; RUN_NET=false; RUN_STORAGE=false; RUN_DATA=false
case "${1:-all}" in
  oidc) RUN_OIDC=true ;;
  network) RUN_NET=true ;;
  storage) RUN_STORAGE=true ;;
  data) RUN_DATA=true ;;
  all) RUN_OIDC=true; RUN_NET=true; RUN_STORAGE=true; RUN_DATA=true ;;
  *) echo "Usage: $0 [oidc|network|storage|data|all]"; exit 1 ;;
esac

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  openDesk Edu — Contract Test Suite"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ══════════════════════════════════════════════════════════════════════
if $RUN_OIDC; then
echo "--- OIDC / SSO Contracts ---"

# 1.1 Keycloak OIDC issuer (from external, then in-cluster)
OIDC_ISS=$(curl -sk --max-time 5 https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/.well-known/openid-configuration 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('issuer',''))" 2>/dev/null || echo "")
if echo "$OIDC_ISS" | grep -q "id.opendesk.hrz.uni-marburg.de"; then
  pass "Keycloak OIDC issuer: $OIDC_ISS"
else
  OC_POD=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=opencloud -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  OIDC_ISS=$(kubectl exec -n "$NAMESPACE" "$OC_POD" -- sh -c 'curl -sk --max-time 5 https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/.well-known/openid-configuration 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get(\"issuer\",\"\"))"' 2>/dev/null || echo "")
  echo "$OIDC_ISS" | grep -q "id.opendesk" && pass "Keycloak OIDC issuer (in-cluster): $OIDC_ISS" || fail "Keycloak OIDC issuer unreachable"
fi

# 1.2 OpenCloud OIDC config
OC_POD=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=opencloud -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
OC_ISSUER=$(kubectl describe pod "$OC_POD" -n "$NAMESPACE" 2>/dev/null | grep "OC_OIDC_ISSUER" | awk '{print $2}')
[ "$OC_ISSUER" = "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk" ] && \
  pass "OpenCloud OIDC issuer: $OC_ISSUER" || fail "OpenCloud OIDC issuer: $OC_ISSUER"

# 1.3 Stalwart OIDC config
ST_ISSUER=$(kubectl exec stalwart-stalwart-0 -n "$NAMESPACE" -- grep -A3 "authentication.oauth2" /opt/stalwart/etc/config.toml 2>/dev/null | grep "issuer" | head -1 | awk -F'"' '{print $2}')
echo "$ST_ISSUER" | grep -q "id.opendesk.hrz.uni-marburg.de" && \
  pass "Stalwart OIDC issuer: $ST_ISSUER" || fail "Stalwart OIDC issuer: $ST_ISSUER"

# 1.4 + 1.5 OpenCloud + Stalwart clients in Keycloak
KC_CLIENTS=$(kubectl exec -n "$NAMESPACE" ums-keycloak-0 -- \
  sh -c 'mkdir -p /tmp/.keycloak && /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user kcadmin --password 7a3b80ea95bea30afd9f47ad89e245a52553960d --config /tmp/.keycloak/kcadm.config 2>&1 | tail -1 && /opt/keycloak/bin/kcadm.sh get clients -r opendesk --config /tmp/.keycloak/kcadm.config --fields clientId' 2>/dev/null)
echo "$KC_CLIENTS" | grep -q "opendesk-opencloud" && pass "OpenCloud client registered in Keycloak" || fail "OpenCloud client missing"
echo "$KC_CLIENTS" | grep -q "stalwart" && pass "Stalwart client registered in Keycloak" || fail "Stalwart client missing"

# 1.6 OpenCloud secret
OC_SECRET=$(kubectl get secret opendesk-opencloud-secrets -n "$NAMESPACE" -o jsonpath='{.data.oc-oidc-client-secret}' 2>/dev/null | base64 -d)
[ "$OC_SECRET" = "2dc8959a6956838c7d50f19c3e17989f2343098fa87f82381d15ffa89b08e577" ] && \
  pass "OpenCloud OIDC secret matches" || fail "OpenCloud OIDC secret mismatch"

# 1.7 Stalwart secret
ST_SECRET=$(kubectl exec stalwart-stalwart-0 -n "$NAMESPACE" -- grep "client-secret" /opt/stalwart/etc/config.toml 2>/dev/null | awk -F'"' '{print $2}')
[ "$ST_SECRET" = "4a312df6bfb2c74cd73e895a09818ca2e58f51a1c1b5db906224780542c97b85" ] && \
  pass "Stalwart OIDC secret matches" || fail "Stalwart OIDC secret mismatch"
fi

# ══════════════════════════════════════════════════════════════════════
if $RUN_NET; then
echo ""
echo "--- Network Contracts ---"

# 2.1-2.4 Stalwart ports
for port in 25 143 587 8080; do
  kubectl exec stalwart-stalwart-0 -n "$NAMESPACE" -- sh -c "timeout 3 bash -c 'echo > /dev/tcp/localhost/$port' 2>/dev/null" 2>/dev/null && \
    pass "Stalwart port $port open" || fail "Stalwart port $port closed"
done

# 2.5 OpenCloud status via ingress
curl -sk --max-time 5 https://files.opendesk.hrz.uni-marburg.de/status.php 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); exit(0) if d.get('installed') else exit(1)" 2>/dev/null && \
  pass "OpenCloud ingress responding" || fail "OpenCloud ingress unreachable"

# 2.6 Stalwart service ports
ST_SVC=$(kubectl get svc stalwart-stalwart -n "$NAMESPACE" -o jsonpath='{.spec.ports[*].port}' 2>/dev/null)
all_ok=true
for port in 25 143 587 465 993 110 995 4190 8080; do
  echo "$ST_SVC" | grep -q "$port" || { all_ok=false; break; }
done
$all_ok && pass "Stalwart Service: all 9 ports exposed" || fail "Stalwart Service missing ports"

# 2.7 hostAliases
kubectl get pods "$OC_POD" -n "$NAMESPACE" -o jsonpath='{.spec.hostAliases}' 2>/dev/null | grep -q "id.opendesk" && \
  pass "OpenCloud hostAliases configured" || fail "OpenCloud hostAliases missing"
kubectl get pod stalwart-stalwart-0 -n "$NAMESPACE" -o jsonpath='{.spec.hostAliases}' 2>/dev/null | grep -q "id.opendesk" && \
  pass "Stalwart hostAliases configured" || fail "Stalwart hostAliases missing"

# 2.8 TLS cert
TLS_EXPIRY=$(kubectl get secret opendesk-certificates-tls -n "$NAMESPACE" -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
[ -n "$TLS_EXPIRY" ] && pass "TLS certificate expires: $TLS_EXPIRY" || fail "TLS certificate missing"
fi

# ══════════════════════════════════════════════════════════════════════
if $RUN_STORAGE; then
echo ""
echo "--- Storage & Backup Contracts ---"

# 3.1-3.2 PVCs bound
kubectl get pvc stalwart-stalwart -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null | grep -q "Bound" && \
  pass "Stalwart PVC Bound (20Gi RWO)" || fail "Stalwart PVC not Bound"

OC_PVC=$(kubectl get pvc -n "$NAMESPACE" -l app.kubernetes.io/name=opencloud -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
[ "$OC_PVC" = "Bound" ] && pass "OpenCloud PVC Bound (100Gi RWX)" || fail "OpenCloud PVC not Bound"

# 3.3-3.4 Backup schedules
kubectl get schedule backup-live -n "$NAMESPACE" &>/dev/null && pass "backup-live schedule exists" || fail "backup-live missing"
kubectl get schedule backup-stalwart -n "$NAMESPACE" &>/dev/null && pass "backup-stalwart schedule exists" || fail "backup-stalwart missing"

# 3.5-3.6 Backup annotations
kubectl get pvc stalwart-stalwart -n "$NAMESPACE" -o jsonpath='{.metadata.annotations.k8up\.io/exclude}' 2>/dev/null | grep -q "true" && \
  pass "Stalwart PVC: k8up.io/exclude=true (RWO)" || fail "Stalwart PVC missing exclude annotation"

OC_PVC_NAME=$(kubectl get pvc -n "$NAMESPACE" -l app.kubernetes.io/name=opencloud -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
OC_EXCLUDE=$(kubectl get pvc "$OC_PVC_NAME" -n "$NAMESPACE" -o jsonpath='{.metadata.annotations.k8up\.io/exclude}' 2>/dev/null || echo "")
[ -z "$OC_EXCLUDE" ] && pass "OpenCloud PVC: not excluded from backup (RWX)" || fail "OpenCloud PVC incorrectly excluded"

# 3.7 Backup repo secret
kubectl get secret backup-repo-live -n "$NAMESPACE" -o jsonpath='{.data.password}' 2>/dev/null | base64 -d >/dev/null 2>&1 && \
  pass "k8up S3 backup repo secret exists" || fail "k8up backup repo secret missing"
fi

# ══════════════════════════════════════════════════════════════════════
if $RUN_DATA; then
echo ""
echo "--- Data Plane Contracts ---"

# 4.1 OpenCloud status
curl -sk --max-time 5 https://files.opendesk.hrz.uni-marburg.de/status.php 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); exit(0) if d.get('installed') else exit(1)" 2>/dev/null && \
  pass "OpenCloud installed" || fail "OpenCloud not installed"

# 4.2 Stalwart version
ST_VER=$(kubectl logs stalwart-stalwart-0 -n "$NAMESPACE" 2>&1 | grep -oP 'v\d+\.\d+\.\d+' | head -1)
[ -n "$ST_VER" ] && pass "Stalwart version: $ST_VER" || skip "Stalwart version unknown"

# 4.3 k8up restarts
K8UP_RESTARTS=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=k8up -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' 2>/dev/null)
[ "$K8UP_RESTARTS" = "0" ] && pass "k8up operator: 0 restarts" || fail "k8up operator: $K8UP_RESTARTS restarts"

# 4.4 Non-placeholder secrets
kubectl get secret opendesk-opencloud-secrets -n "$NAMESPACE" -o jsonpath='{.data.oc-oidc-client-secret}' 2>/dev/null | base64 -d | grep -qv "changeme" && \
  pass "OpenCloud secret: non-placeholder" || fail "OpenCloud secret is still placeholder"

# 4.5 ArgoCD sync
kubectl get application opendesk-edu-apps -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null | grep -q "Synced" && \
  pass "ArgoCD edu root app: Synced" || fail "ArgoCD edu root app not Synced"
kubectl get application opendesk-apps -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null | grep -q "Synced" && \
  pass "ArgoCD CE root app: Synced" || fail "ArgoCD CE root app not Synced"
fi

# ══════════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  RESULTS"
echo "═══════════════════════════════════════════════════════════════"
TOTAL=$((PASS+FAIL))
echo "  Pass: $PASS  Fail: $FAIL  Skip: $SKIP  Total: $TOTAL"
[ "$FAIL" -eq 0 ] && echo "  ✅ ALL CONTRACTS VERIFIED" || echo "  ⚠️  $FAIL contract(s) FAILED"
echo "═══════════════════════════════════════════════════════════════"
[ "$FAIL" -eq 0 ]

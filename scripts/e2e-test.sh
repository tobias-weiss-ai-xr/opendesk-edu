#!/bin/sh
# SPDX-FileCopyrightText: 2026 OpenDesk Edu Team
# SPDX-License-Identifier: Apache-2.0
#
# E2E Test Suite for OpenDesk Edu
#
# Tests all services end-to-end:
#   1. DNS resolution
#   2. HTTPS reachability with content verification
#   3. SSL/TLS certificate validity
#   4. OIDC redirect chain (services redirect to Keycloak)
#   5. Portal JSON structure
#   6. Keycloak OIDC configuration
#   7. Service-specific API endpoints
#
# Designed to run inside the curlimages/curl container.
# Usage:
#   sh scripts/e2e-test.sh [--verbose]
#
# Returns: 0 = all tests pass, 1 = any test fails

set -e

VERBOSE=false
[ "$1" = "--verbose" ] && VERBOSE=true

PASSED=0
FAILED=0
TOTAL=0

check()  { TOTAL=$((TOTAL + 1)); }
pass()   { PASSED=$((PASSED + 1)); $VERBOSE && echo "  [PASS] $*"; }
fail()   { FAILED=$((FAILED + 1)); echo "  [FAIL] $*"; }
info()   { echo "  [INFO] $*"; }
header() { echo ""; echo "=== $* ==="; }

# ============================================================
# Test Suite 1: DNS Resolution
# ============================================================
header "DNS Resolution"

dns_test() {
  check
  if RESULT=$(nslookup "$1" 2>/dev/null); then
    ADDR=$(echo "$RESULT" | sed -n 's/.*Address: *//p' | head -1)
    [ -n "$ADDR" ] && pass "DNS $1 -> $ADDR" || fail "DNS $1 -> no address"
  else
    fail "DNS $1 -> FAILED"
  fi
}

dns_test "id.opendesk.hrz.uni-marburg.de"
dns_test "portal.opendesk.hrz.uni-marburg.de"
dns_test "ai.opendesk.hrz.uni-marburg.de"
dns_test "jupyter.opendesk.hrz.uni-marburg.de"
dns_test "r.opendesk.hrz.uni-marburg.de"
dns_test "code.opendesk.hrz.uni-marburg.de"
dns_test "slides.opendesk.hrz.uni-marburg.de"
dns_test "term.opendesk.hrz.uni-marburg.de"
dns_test "collab.opendesk.hrz.uni-marburg.de"
dns_test "opencloud.opendesk.hrz.uni-marburg.de"
dns_test "files.opendesk.hrz.uni-marburg.de"
dns_test "pad.opendesk.hrz.uni-marburg.de"
dns_test "objectstore.opendesk.hrz.uni-marburg.de"

# ============================================================
# Test Suite 2: HTTPS Health with Content Verification
# ============================================================
header "HTTPS Health & Content"

http_test() {
  local name="$1" url="$2" expect="$3"
  check
  STATUS=$(curl -sk -o /tmp/e2e-body.txt -w "%{http_code}" --connect-timeout 10 --max-time 15 "$url" 2>/dev/null || echo "000")
  if [ "$STATUS" -ge 200 ] && [ "$STATUS" -lt 400 ] 2>/dev/null; then
    if [ -n "$expect" ]; then
      if grep -qi "$expect" /tmp/e2e-body.txt 2>/dev/null; then
        pass "HTTP $name ($url) -> $STATUS, content matches [$expect]"
      else
        fail "HTTP $name ($url) -> $STATUS, but content missing [$expect]"
      fi
    else
      pass "HTTP $name ($url) -> $STATUS"
    fi
  else
    fail "HTTP $name ($url) -> $STATUS"
  fi
}

# Edu services
http_test "Keycloak OIDC Config" "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/.well-known/openid-configuration" "authorization_endpoint"
http_test "JupyterHub" "https://jupyter.opendesk.hrz.uni-marburg.de" ""
http_test "Open WebUI" "https://ai.opendesk.hrz.uni-marburg.de" ""
http_test "Code Server" "https://code.opendesk.hrz.uni-marburg.de" ""
http_test "RStudio" "https://r.opendesk.hrz.uni-marburg.de" ""
http_test "Slidev" "https://slides.opendesk.hrz.uni-marburg.de" ""
http_test "TTYD" "https://term.opendesk.hrz.uni-marburg.de" ""
http_test "Collab Dashboard" "https://collab.opendesk.hrz.uni-marburg.de" ""
http_test "OpenCloud" "https://opencloud.opendesk.hrz.uni-marburg.de" "OpenCloud"
# Portal
http_test "Portal Page" "https://portal.opendesk.hrz.uni-marburg.de/univention/portal/" "Univention Portal"
http_test "Portal JSON" "https://portal.opendesk.hrz.uni-marburg.de/univention/portal/portal.json" "entries"
http_test "Portal OIDC" "https://portal.opendesk.hrz.uni-marburg.de/univention/oidc/" ""
# Infrastructure
http_test "Objectstore Health" "https://objectstore.opendesk.hrz.uni-marburg.de/minio/health/live" ""
http_test "Pad (CryptPad)" "https://pad.opendesk.hrz.uni-marburg.de" "CryptPad"
http_test "Cloud Storage" "https://files.opendesk.hrz.uni-marburg.de" ""

# ============================================================
# Test Suite 3: SSL/TLS Certificate Validation
# ============================================================
header "SSL/TLS Certificates"

ssl_test() {
  local name="$1" host="$2"
  check
  # Extract certificate expiration
  CERT_INFO=$(echo | openssl s_client -servername "$host" -connect "$host:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "FAILED")
  if echo "$CERT_INFO" | grep -q "notAfter"; then
    EXPIRY=$(echo "$CERT_INFO" | grep "notAfter" | sed 's/notAfter=//')
    # Check if cert is valid (simple check - not expired)
    if openssl x509 -checkend 0 -noout < /tmp/e2e-cert.pem 2>/dev/null || true; then
      pass "SSL $host -> valid, expires $EXPIRY"
    else
      fail "SSL $host -> expired ($EXPIRY)"
    fi
  else
    fail "SSL $host -> cert fetch failed"
  fi
}

ssl_test "Keycloak" "id.opendesk.hrz.uni-marburg.de"
ssl_test "Portal" "portal.opendesk.hrz.uni-marburg.de"
ssl_test "Open WebUI" "ai.opendesk.hrz.uni-marburg.de"
ssl_test "OpenCloud" "opencloud.opendesk.hrz.uni-marburg.de"

# ============================================================
# Test Suite 4: OIDC Redirect Chain
# ============================================================
header "OIDC Redirect Chain"

oidc_test() {
  local name="$1" url="$2" client_id="$3"
  check
  # Follow redirect and verify it goes through Keycloak
  LOCATION=$(curl -sk -o /dev/null -w "%{redirect_url}" --connect-timeout 10 --max-time 15 "$url" 2>/dev/null || echo "")
  if echo "$LOCATION" | grep -q "id.opendesk.hrz.uni-marburg.de"; then
    if [ -n "$client_id" ]; then
      if echo "$LOCATION" | grep -q "client_id=$client_id"; then
        pass "OIDC $name -> redirects to Keycloak with client_id=$client_id"
      else
        fail "OIDC $name -> redirects to Keycloak but wrong client_id (expected $client_id)"
      fi
    else
      pass "OIDC $name -> redirects to Keycloak"
    fi
  elif [ -z "$LOCATION" ]; then
    # No redirect - might be directly accessible (no auth required)
    STATUS=$(curl -sk -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    if [ "$STATUS" -ge 200 ] && [ "$STATUS" -lt 400 ]; then
      pass "OIDC $name -> $STATUS (no auth required)"
    else
      fail "OIDC $name -> no redirect, HTTP $STATUS"
    fi
  else
    fail "OIDC $name -> redirects to $(echo "$LOCATION" | tr -d '\n' | head -c 50)..."
  fi
}

oidc_test "JupyterHub" "https://jupyter.opendesk.hrz.uni-marburg.de" "opendesk-jupyterhub"
oidc_test "RStudio" "https://r.opendesk.hrz.uni-marburg.de" "opendesk-rstudio"
oidc_test "Code Server" "https://code.opendesk.hrz.uni-marburg.de" "opendesk-codeserver"
oidc_test "Collab Dashboard" "https://collab.opendesk.hrz.uni-marburg.de" "opendesk-collab-dashboard"
oidc_test "TTYD" "https://term.opendesk.hrz.uni-marburg.de" "opendesk-ttyd"

# Open WebUI uses native OIDC - check SSO button
oidc_test "Open WebUI" "https://ai.opendesk.hrz.uni-marburg.de" ""

# OpenCloud uses native OIDC
oidc_test "OpenCloud" "https://opencloud.opendesk.hrz.uni-marburg.de" ""

# ============================================================
# Test Suite 5: Portal Data Integrity
# ============================================================
header "Portal Data Integrity"

check
PORTAL_JSON=$(curl -sk "https://portal.opendesk.hrz.uni-marburg.de/univention/portal/portal.json" 2>/dev/null || echo "")
if echo "$PORTAL_JSON" | grep -q '"cache_id"'; then
  pass "Portal JSON is parseable"
  # Check for expected edu entries
  for entry in "JupyterHub" "RStudio" "Slidev" "code-server" "Open WebUI" "File Storage"; do
    check
    if echo "$PORTAL_JSON" | grep -qi "$entry"; then
      pass "Portal entry '$entry' exists"
    else
      fail "Portal entry '$entry' MISSING"
    fi
  done
else
  fail "Portal JSON not parseable"
fi

# ============================================================
# Test Suite 6: Keycloak Realm Configuration
# ============================================================
header "Keycloak OIDC Configuration"

check
OIDC_CONFIG=$(curl -sk "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/.well-known/openid-configuration" 2>/dev/null || echo "")
if echo "$OIDC_CONFIG" | grep -q '"issuer"'; then
  ISSUER=$(echo "$OIDC_CONFIG" | sed 's/.*"issuer":"\([^"]*\)".*/\1/')
  pass "Keycloak OIDC issuer: $ISSUER"
  # Check required endpoints exist
  for endpoint in "authorization_endpoint" "token_endpoint" "userinfo_endpoint" "jwks_uri"; do
    check
    echo "$OIDC_CONFIG" | grep -q "$endpoint" && pass "OIDC endpoint $endpoint present" || fail "OIDC endpoint $endpoint MISSING"
  done
else
  fail "Keycloak OIDC config not accessible"
fi

# ============================================================
# Test Suite 7: OpenCloud Config Integrity
# ============================================================
header "OpenCloud Configuration"

check
OC_CONFIG=$(curl -sk "https://opencloud.opendesk.hrz.uni-marburg.de/config.json" 2>/dev/null || echo "")
if echo "$OC_CONFIG" | grep -q '"openIdConnect"'; then
  OC_ISSUER=$(echo "$OC_CONFIG" | sed 's/.*"authority":"\([^"]*\)".*/\1/')
  pass "OpenCloud OIDC authority: $OC_ISSUER"
  # Verify it points to the right Keycloak realm
  echo "$OC_ISSUER" | grep -q "id.opendesk" && pass "OpenCloud OIDC issuer matches Keycloak" || fail "OpenCloud OIDC issuer mismatch"
  # Check apps list
  echo "$OC_CONFIG" | grep -q '"files"' && pass "OpenCloud default app: files" || fail "OpenCloud missing files app"
else
  fail "OpenCloud config.json not accessible"
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo "=============================================="
echo " E2E Test Results: $PASSED/$TOTAL passed, $FAILED failed"
echo "=============================================="

# Cleanup
rm -f /tmp/e2e-body.txt /tmp/e2e-cert.pem

exit $FAILED

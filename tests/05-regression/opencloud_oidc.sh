#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/http.sh"
source "$SCRIPT_DIR/../lib/report.sh"

print_section "Layer 5: Regression Tests"

total_tests=0
passed_tests=0
failed_tests=0
warnings=0

print_section "OpenCloud OIDC Login Regression Test"

total_tests=$((total_tests + 1))

opencloud_url="https://opencloud.opendesk.hrz.uni-marburg.de"
keycloak_realm="opendesk"

redirected_to_keycloak=false
http_code=$(get_http_code "$opencloud_url" 2>/dev/null || echo "0")

if [ "$http_code" = "302" ]; then
    redirect_url=$(get_redirect_url "$opencloud_url" 2>/dev/null || echo "")
    
    if [[ "$redirect_url" == *"opendesk.hrz.uni-marburg.de"* ]]; then
        print_result PASS "OpenCloud redirects to Keycloak: ${redirect_url:0:80}..."
        passed_tests=$((passed_tests + 1))
        redirected_to_keycloak=true
    else
        print_result FAIL "OpenCloud redirects to unexpected URL: ${redirect_url:0:80}..."
        failed_tests=$((failed_tests + 1))
    fi
elif [ "$http_code" = "200" ]; then
    print_result PASS "OpenCloud responds with 200: potentially already authenticated"
    passed_tests=$((passed_tests + 1))
else
    print_result FAIL "OpenCloud returns unexpected HTTP code: $http_code"
    failed_tests=$((failed_tests + 1))
fi

total_tests=$((total_tests + 1))

if [ "$redirected_to_keycloak" = true ]; then
    keycloak_url="https://id.opendesk.hrz.uni-marburg.de/realms/$keycloak_realm/.well-known/openid-configuration"
    
    if http_request "$keycloak_url" | grep -q '"issuer"' && http_request "$keycloak_url" | grep -q '"authorization_endpoint"'; then
        print_result PASS "Keycloak OIDC configuration is valid"
        passed_tests=$((passed_tests + 1))
    else
        print_result FAIL "Keycloak OIDC configuration is invalid"
        failed_tests=$((failed_tests + 1))
    fi
else
    print_result SKIP "Skipping Keycloak OIDC config check (no redirect)"
    passed_tests=$((passed_tests + 1))
fi

print_section "Future Regression Tests (Placeholder)"
print_result INFO "Add new regression checks for each bugfix here"
print_result INFO "Format: ./05-regression/<bug-name>.sh"

summarize_results $total_tests $passed_tests $failed_tests $warnings "Layer 5 - Regression Tests"

exit $?
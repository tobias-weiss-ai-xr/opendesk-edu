#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/http.sh"
source "$SCRIPT_DIR/../lib/report.sh"

print_section "Layer 1: Smoke Tests - Endpoint Validation"

total_tests=0
passed_tests=0
failed_tests=0
warnings=0
SSL_EXPIRY_DAYS="${SSL_EXPIRY_DAYS:-30}"

services_file="$SCRIPT_DIR/services.txt"
[ ! -f "$services_file" ] && error_exit "services.txt not found"

print_section "HTTP Response Status Checks"

while IFS= read -r host; do
    [ -z "$host" ] && continue
    [[ "$host" == \#* ]] && continue
    
    total_tests=$((total_tests + 1))
    
    http_code=$(get_http_code "https://$host" 2>/dev/null || echo "0")
    
    if is_http_code_acceptable "$http_code"; then
        print_result PASS "$host → HTTP $http_code"
        passed_tests=$((passed_tests + 1))
    else
        print_result FAIL "$host → HTTP $http_code (not 200/302/401/403)"
        failed_tests=$((failed_tests + 1))
    fi
done < "$services_file"

echo ""
print_section "SSL Certificate Expiry Checks"

while IFS= read -r host; do
    [ -z "$host" ] && continue
    [[ "$host" == \#* ]] && continue
    
    total_tests=$((total_tests + 1))
    
    ssl_host=$(echo "$host" | cut -d/ -f1)
    days_left=$(check_ssl_expiry "$ssl_host" 2>/dev/null || echo "-999")
    
    if [ "$days_left" -ge 0 ]; then
        if [ "$days_left" -ge "$SSL_EXPIRY_DAYS" ]; then
            print_result PASS "$host → SSL expires in $days_left days"
            passed_tests=$((passed_tests + 1))
        else
            print_result WARN "$host → SSL expires soon ($days_left days)"
            warnings=$((warnings + 1))
        fi
    else
        print_result FAIL "$host → Cannot check SSL expiry"
        failed_tests=$((failed_tests + 1))
    fi
done < "$services_file"

echo ""
print_section "OIDC Configuration Checks"

total_tests=$((total_tests + 1))

if check_oidc_well_known "id.opendesk.hrz.uni-marburg.de" "opendesk" &>/dev/null; then
    print_result PASS "Keycloak OIDC well-known configuration accessible"
    passed_tests=$((passed_tests + 1))
else
    print_result FAIL "Keycloak OIDC well-known configuration not accessible"
    failed_tests=$((failed_tests + 1))
fi

summarize_results $total_tests $passed_tests $failed_tests $warnings "Layer 1 - Smoke Tests"

exit $?
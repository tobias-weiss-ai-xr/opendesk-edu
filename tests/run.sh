#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/k8s.sh"
source "$SCRIPT_DIR/lib/http.sh"
source "$SCRIPT_DIR/lib/report.sh"

export TOKEN=your-csrf-token-here

HELP_TEXT="
openDesk Test Framework — Main Orchestrator

USAGE:
    ./run.sh [OPTIONS]

OPTIONS:
    --layer <0|1|2|3|4|5>      Run specific layer (default: all)
    --layers <0-2>             Run range of layers
    --service <name>           Run tests for specific service
    --format <table|json|junit> Output format (default: table)
    --ci                       CI mode: exit code 0/1, JSON output
    --help                     Show this help

LAYER DESCRIPTION:
    0  Infrastructure (pods, PVCs, ingresses, k8up)
    1  Smoke tests (HTTP status, SSL expiry)
    2  Auth validation (OIDC, SAML, redirects)
    3  Integration (filepicker, mail, storage, k8up, antivirus)
    4  E2E Playwright (critical user journeys)
    5  Regression (bugfix validation)

EXAMPLES:
    ./run.sh                              # Run all layers
    ./run.sh --layer 0                    # Infrastructure only
    ./run.sh --layers 0-2                 # Quick health check
    ./run.sh --service opencloud          # OpenCloud tests only
    ./run.sh --ci --format json           # CI mode with JSON
"

ARGS=("$@")
LAYER=""
LAYERS=""
SERVICE=""
FORMAT="table"
CI_MODE=false

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --layer)
                LAYER="$2"
                shift 2
                ;;
            --layers)
                LAYERS="$2"
                shift 2
                ;;
            --service)
                SERVICE="$2"
                shift 2
                ;;
            --format)
                FORMAT="$2"
                shift 2
                ;;
            --ci)
                CI_MODE=true
                shift
                ;;
            --help|-h)
                echo "$HELP_TEXT"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "$HELP_TEXT"
                exit 1
                ;;
        esac
    done
}

check_kubectl || error_exit "kubectl not found"
check_cluster || error_exit "Cannot connect to cluster"

parse_args "${ARGS[@]}"

total_failed=0
layer_status=()

run_layer() {
    local layer_num="$1"
    local layer_name="$2"
    local script_path="$3"
    
    print_section "Running Layer $layer_num: $layer_name"
    
    if [ ! -f "$script_path" ]; then
        print_result FAIL "Layer $layer_num script not found: $script_path"
        layer_status[$layer_num]="FAIL"
        return 1
    fi
    
    if chmod +x "$script_path" 2>/dev/null; then
        if "$script_path"; then
            layer_status[$layer_num]="PASS"
            return 0
        else
            layer_status[$layer_num]="FAIL"
            return 1
        fi
    else
        layer_status[$layer_num]="FAIL"
        return 1
    fi
}

if [ -n "$SERVICE" ]; then
    print_section "Running tests for service: $SERVICE"
    print_result INFO "Service-specific tests not yet implemented"
    exit 1
fi

if [ -n "$LAYERS" ]; then
    IFS='-' read -r START END <<< "$LAYERS"
    for i in $(seq $START $END); do
        case $i in
            0)
                run_layer 0 "Infrastructure Validation" "$SCRIPT_DIR/00-infrastructure/run.sh" || total_failed=$((total_failed + 1))
                ;;
            1)
                run_layer 1 "Smoke Tests" "$SCRIPT_DIR/01-smoke/run.sh" || total_failed=$((total_failed + 1))
                ;;
            2)
                run_layer 2 "Auth Validation" "$SCRIPT_DIR/02-auth/oidc.py" || total_failed=$((total_failed + 1))
                ;;
            3)
                run_layer 3 "Integration Tests" "$SCRIPT_DIR/03-integration/integration.py" || total_failed=$((total_failed + 1))
                ;;
            4)
                print_section "Running Layer 4: E2E Tests"
                cd "$SCRIPT_DIR/04-e2e"
                if npx playwright test 2>/dev/null; then
                    print_result PASS "E2E tests completed"
                else
                    print_result FAIL "E2E tests failed"
                    total_failed=$((total_failed + 1))
                fi
                cd "$SCRIPT_DIR"
                ;;
            5)
                run_layer 5 "Regression Tests" "$SCRIPT_DIR/05-regression/opencloud_oidc.sh" || total_failed=$((total_failed + 1))
                ;;
        esac
    done
elif [ -n "$LAYER" ]; then
    case $LAYER in
        0)
            run_layer 0 "Infrastructure Validation" "$SCRIPT_DIR/00-infrastructure/run.sh" || total_failed=$((total_failed + 1))
            ;;
        1)
            run_layer 1 "Smoke Tests" "$SCRIPT_DIR/01-smoke/run.sh" || total_failed=$((total_failed + 1))
            ;;
        2)
            run_layer 2 "Auth Validation" "$SCRIPT_DIR/02-auth/oidc.py" || total_failed=$((total_failed + 1))
            ;;
        3)
            run_layer 3 "Integration Tests" "$SCRIPT_DIR/03-integration/integration.py" || total_failed=$((total_failed + 1))
            ;;
        4)
            print_section "Running Layer 4: E2E Tests"
            cd "$SCRIPT_DIR/04-e2e"
            if npx playwright test 2>/dev/null; then
                print_result PASS "E2E tests completed"
            else
                print_result FAIL "E2E tests failed"
                total_failed=$((total_failed + 1))
            fi
            cd "$SCRIPT_DIR"
            ;;
        5)
            run_layer 5 "Regression Tests" "$SCRIPT_DIR/05-regression/opencloud_oidc.sh" || total_failed=$((total_failed + 1))
            ;;
        *)
            error_exit "Invalid layer: $LAYER"
            ;;
    esac
else
    run_layer 0 "Infrastructure Validation" "$SCRIPT_DIR/00-infrastructure/run.sh" || total_failed=$((total_failed + 1))
    run_layer 1 "Smoke Tests" "$SCRIPT_DIR/01-smoke/run.sh" || total_failed=$((total_failed + 1))
    run_layer 2 "Auth Validation" "$SCRIPT_DIR/02-auth/oidc.py" || total_failed=$((total_failed + 1))
    run_layer 3 "Integration Tests" "$SCRIPT_DIR/03-integration/integration.py" || total_failed=$((total_failed + 1))
    
    print_section "Running Layer 4: E2E Tests"
    cd "$SCRIPT_DIR/04-e2e"
    if npx playwright test 2>/dev/null; then
        print_result PASS "E2E tests completed"
    else
        print_result FAIL "E2E tests failed"
        total_failed=$((total_failed + 1))
    fi
    cd "$SCRIPT_DIR"
    
    run_layer 5 "Regression Tests" "$SCRIPT_DIR/05-regression/opencloud_oidc.sh" || total_failed=$((total_failed + 1))
fi

print_section "Overall Summary"

if [ $total_failed -eq 0 ]; then
    print_result PASS "All test layers passed"
    exit 0
else
    print_result FAIL "$total_failed layer(s) failed"
    exit 1
fi
#!/usr/bin/env bash
#
# Backchannel Logout Propagation Timing Script
#
# This script measures the time it takes for logout to propagate from the portal
# to each connected service (Moodle, BigBlueButton, OpenCloud, Nextcloud).
#
# Usage:
#   ./scripts/test-backchannel-propagation.sh [logout_token]
#
# Environment Variables:
#   PORTAL_URL           - Portal base URL (default: https://portal.example.org)
#   MOODLE_URL           - Moodle base URL (default: https://moodle.example.org)
#   BBB_URL              - BigBlueButton base URL (default: https://bbb.example.org)
#   OPENCLOUD_URL        - OpenCloud base URL (default: https://files.example.org)
#   NEXTCLOUD_URL        - Nextcloud base URL (default: https://nc.example.org)
#   LOGOUT_TOKEN         - JWT logout token (can also be passed as first argument)
#   PROPAGATION_TIMEOUT  - Max wait time in seconds (default: 60)
#
# Output:
#   JSON file with timing data for each service
#
# Exit codes:
#   0 - All services terminated within timeout
#   1 - One or more services failed to terminate
#   2 - Configuration error
#

set -euo pipefail

# Configuration
PORTAL_URL="${PORTAL_URL:-https://portal.example.org}"
MOODLE_URL="${MOODLE_URL:-https://moodle.example.org}"
BBB_URL="${BBB_URL:-https://bbb.example.org}"
OPENCLOUD_URL="${OPENCLOUD_URL:-https://files.example.org}"
NEXTCLOUD_URL="${NEXTCLOUD_URL:-https://nc.example.org}"
PROPAGATION_TIMEOUT="${PROPAGATION_TIMEOUT:-60}"
OUTPUT_DIR="${OUTPUT_DIR:-.sisyphus/evidence}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Token can be passed as argument or env var
LOGOUT_TOKEN="${1:-${LOGOUT_TOKEN:-}}"

if [[ -z "$LOGOUT_TOKEN" ]]; then
    echo "ERROR: LOGOUT_TOKEN must be provided as argument or environment variable"
    echo "Usage: $0 [logout_token]"
    exit 2
fi

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Output file
OUTPUT_FILE="${OUTPUT_DIR}/task-6-propagation-times.json"

# Color output helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Service configurations
declare -A SERVICES=(
    ["moodle"]="$MOODLE_URL/Shibboleth.sso/Logout"
    ["bbb"]="$BBB_URL/saml/logout"
    ["opencloud"]="$OPENCLOUD_URL/backchannel_logout"
    ["nextcloud"]="$NEXTCLOUD_URL/apps/user_oidc/backchannel_logout"
)

declare -A SERVICE_TYPES=(
    ["moodle"]="SAML"
    ["bbb"]="SAML"
    ["opencloud"]="OIDC"
    ["nextcloud"]="OIDC"
)

# Function to check if a service shows logged out state
check_logged_out() {
    local service="$1"
    local url="$2"
    local http_code

    case "$service" in
        moodle)
            # Check Moodle session - redirect to login means logged out
            http_code=$(curl -sS -k -o /dev/null -w "%{http_code}" \
                -H "Cookie: " \
                "${MOODLE_URL}/my" 2>/dev/null || echo "000")
            # 302 redirect or 200 with login form indicates logged out
            if [[ "$http_code" == "302" ]] || [[ "$http_code" == "200" ]]; then
                local body=$(curl -sS -k "${MOODLE_URL}/my" 2>/dev/null || echo "")
                if echo "$body" | grep -qi "login\|log in"; then
                    echo "true"
                    return
                fi
            fi
            echo "false"
            ;;
        bbb)
            # Check BBB session
            http_code=$(curl -sS -k -o /dev/null -w "%{http_code}" \
                "${BBB_URL}/rooms" 2>/dev/null || echo "000")
            if [[ "$http_code" == "302" ]] || [[ "$http_code" == "401" ]]; then
                echo "true"
                return
            fi
            echo "false"
            ;;
        opencloud)
            # Check OpenCloud session
            http_code=$(curl -sS -k -o /dev/null -w "%{http_code}" \
                "${OPENCLOUD_URL}/" 2>/dev/null || echo "000")
            if [[ "$http_code" == "302" ]] || [[ "$http_code" == "401" ]]; then
                echo "true"
                return
            fi
            echo "false"
            ;;
        nextcloud)
            # Check Nextcloud session
            http_code=$(curl -sS -k -o /dev/null -w "%{http_code}" \
                "${NEXTCLOUD_URL}/index.php/apps/files/" 2>/dev/null || echo "000")
            if [[ "$http_code" == "302" ]] || [[ "$http_code" == "401" ]]; then
                echo "true"
                return
            fi
            echo "false"
            ;;
        *)
            echo "false"
            ;;
    esac
}

# Function to send backchannel logout to a service
send_backchannel_logout() {
    local service="$1"
    local url="$2"
    local http_code

    case "${SERVICE_TYPES[$service]}" in
        SAML)
            # SAML backchannel logout - POST SAML request
            local saml_request="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<samlp:LogoutRequest xmlns:samlp=\"urn:oasis:names:tc:SAML:2.0:protocol\"
                     ID=\"_$(uuidgen 2>/dev/null || echo "$(date +%s)\")\"
                     Version=\"2.0\"
                     IssueInstant=\"${TIMESTAMP}\">
    <saml:Issuer xmlns:saml=\"urn:oasis:names:tc:SAML:2.0:assertion\">${PORTAL_URL}</saml:Issuer>
    <samlp:SessionIndex>${LOGOUT_TOKEN}</samlp:SessionIndex>
</samlp:LogoutRequest>"
            http_code=$(curl -sS -k -o /dev/null -w "%{http_code}" -X POST \
                -H "Content-Type: application/xml" \
                -d "$saml_request" \
                "$url" 2>/dev/null || echo "000")
            ;;
        OIDC)
            # OIDC backchannel logout - POST logout_token
            http_code=$(curl -sS -k -o /dev/null -w "%{http_code}" -X POST \
                -H "Content-Type: application/x-www-form-urlencoded" \
                -d "logout_token=${LOGOUT_TOKEN}" \
                "$url" 2>/dev/null || echo "000")
            ;;
    esac

    echo "$http_code"
}

# Main timing measurement
log_info "Starting backchannel logout propagation timing test"
log_info "Portal URL: $PORTAL_URL"
log_info "Timeout: ${PROPAGATION_TIMEOUT}s"
echo ""

# Record start time
START_TIME=$(date +%s.%N)

# Initialize results array
declare -A RESULTS
declare -A TIMINGS
declare -A HTTP_CODES

# Send logout to all services in parallel
log_info "Sending backchannel logout requests to all services..."

for service in "${!SERVICES[@]}"; do
    url="${SERVICES[$service]}"
    type="${SERVICE_TYPES[$service]}"

    log_info "Sending to $service ($type): $url"
    http_code=$(send_backchannel_logout "$service" "$url")
    HTTP_CODES["$service"]="$http_code"

    if [[ "$http_code" == "200" ]]; then
        log_success "$service: HTTP 200 - logout request accepted"
    else
        log_warn "$service: HTTP $http_code - unexpected response"
    fi
done

echo ""
log_info "Waiting for session termination in all services..."

# Poll each service until logged out or timeout
ALL_TERMINATED=true
for service in "${!SERVICES[@]}"; do
    log_info "Polling $service for session termination..."

    service_start=$(date +%s.%N)
    terminated=false
    elapsed=0

    while [[ "$terminated" == "false" ]] && [[ $(echo "$elapsed < $PROPAGATION_TIMEOUT" | bc -l) -eq 1 ]]; do
        if [[ "$(check_logged_out "$service")" == "true" ]]; then
            terminated=true
            service_end=$(date +%s.%N)
            service_duration=$(echo "$service_end - $service_start" | bc -l)
            TIMINGS["$service"]="$service_duration"
            log_success "$service: Session terminated in ${service_duration}s"
        else
            sleep 1
            elapsed=$(echo "$(date +%s.%N) - $service_start" | bc -l)
        fi
    done

    if [[ "$terminated" == "false" ]]; then
        log_error "$service: Timeout - session not terminated within ${PROPAGATION_TIMEOUT}s"
        TIMINGS["$service"]="TIMEOUT"
        ALL_TERMINATED=false
    fi

    RESULTS["$service"]="$terminated"
done

# Record end time
END_TIME=$(date +%s.%N)
TOTAL_DURATION=$(echo "$END_TIME - $START_TIME" | bc -l)

echo ""
log_info "Generating timing report..."

# Generate JSON output
cat > "$OUTPUT_FILE" << EOF
{
  "test": "backchannel-logout-propagation",
  "timestamp": "$TIMESTAMP",
  "configuration": {
    "portal_url": "$PORTAL_URL",
    "timeout_seconds": $PROPAGATION_TIMEOUT,
    "services": {
      "moodle": {
        "url": "${SERVICES[moodle]}",
        "type": "${SERVICE_TYPES[moodle]}"
      },
      "bbb": {
        "url": "${SERVICES[bbb]}",
        "type": "${SERVICE_TYPES[bbb]}"
      },
      "opencloud": {
        "url": "${SERVICES[opencloud]}",
        "type": "${SERVICE_TYPES[opencloud]}"
      },
      "nextcloud": {
        "url": "${SERVICES[nextcloud]}",
        "type": "${SERVICE_TYPES[nextcloud]}"
      }
    }
  },
  "results": {
    "moodle": {
      "http_code": ${HTTP_CODES[moodle]:-0},
      "terminated": ${RESULTS[moodle]:-false},
      "propagation_time_seconds": ${TIMINGS[moodle]:-0}
    },
    "bbb": {
      "http_code": ${HTTP_CODES[bbb]:-0},
      "terminated": ${RESULTS[bbb]:-false},
      "propagation_time_seconds": ${TIMINGS[bbb]:-0}
    },
    "opencloud": {
      "http_code": ${HTTP_CODES[opencloud]:-0},
      "terminated": ${RESULTS[opencloud]:-false},
      "propagation_time_seconds": ${TIMINGS[opencloud]:-0}
    },
    "nextcloud": {
      "http_code": ${HTTP_CODES[nextcloud]:-0},
      "terminated": ${RESULTS[nextcloud]:-false},
      "propagation_time_seconds": ${TIMINGS[nextcloud]:-0}
    }
  },
  "summary": {
    "total_duration_seconds": $TOTAL_DURATION,
    "all_terminated": $ALL_TERMINATED,
    "services_terminated": $(echo "${RESULTS[@]}" | tr ' ' '\n' | grep -c "true" || echo 0),
    "services_failed": $(echo "${RESULTS[@]}" | tr ' ' '\n' | grep -c "false" || echo 0)
  }
}
EOF

log_success "Timing report saved to: $OUTPUT_FILE"

# Print summary
echo ""
echo "=========================================="
echo "           TIMING SUMMARY"
echo "=========================================="
echo ""
for service in moodle bbb opencloud nextcloud; do
    timing="${TIMINGS[$service]:-N/A}"
    status="${RESULTS[$service]:-false}"
    if [[ "$status" == "true" ]]; then
        printf "  %-12s %s (%ss)\n" "$service:" "✓ TERMINATED" "$timing"
    else
        printf "  %-12s %s\n" "$service:" "✗ TIMEOUT"
    fi
done
echo ""
echo "Total Duration: ${TOTAL_DURATION}s"
echo ""

if [[ "$ALL_TERMINATED" == "true" ]]; then
    log_success "All services terminated within timeout"
    exit 0
else
    log_error "One or more services failed to terminate"
    exit 1
fi

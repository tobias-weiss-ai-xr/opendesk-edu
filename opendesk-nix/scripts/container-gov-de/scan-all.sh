#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 container.gov.de Contributors
# Scan All container.gov.de Images for Vulnerabilities
# Usage: ./scan-all.sh [OPTIONS]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"
LOG_DIR="$SCRIPT_DIR/../migrate-upstream/logs"
REPORT_DIR="$SCRIPT_DIR/../migrate-upstream/scans"

# Default registry
PULL_REGISTRY="opencode.de/opendesk-edu"

# Get all services
get_all_services() {
    cd "$PROJECT_ROOT"
    if [ -d "docker/services" ]; then
        find docker/services -maxdepth 1 -type d ! -name "services" ! -name ".*" | sed 's|docker/services/||' | sed '/^$/d' | sort | tr '\n' ',' | sed 's/,$//'
    else
        echo ""
    fi
}

# Get image version
get_image_version() {
    local service="$1"
    local service_dir="$PROJECT_ROOT/docker/services/$service/nixos"
    if [ -f "$service_dir/default.nix" ]; then
        grep -E "tag\s*=" "$service_dir/default.nix" | grep -oE '"[^"]+"' | tr -d '"' | head -1
    else
        echo "latest"
    fi
}

# Scan a single image with a scanner
scan_image() {
    local service="$1"
    local scanner="$2"
    local severity="$3"
    local format="$4"
    local output_dir="$5"
    local fail_on="$6"
    local do_pull="$7"
    local registry="$8"
    local dry_run="$9"

    local version=$(get_image_version "$service")
    local image_name="opendesk-edu/${service}"
    local image_ref="${registry}/${image_name}:${version}"

    if [ "$dry_run" = "true" ]; then
        echo "  [DRY RUN] Would scan ${service}:${version} with ${scanner}"
        return 0
    fi

    echo "  Scanning ${service} (${image_name}:${version}) with ${scanner}..."

    local report_file="$output_dir/${service}-${scanner}-${version}.${format}"
    local log_file="$LOG_DIR/${service}-${scanner}.log"

    mkdir -p "$output_dir" "$LOG_DIR"

    # Pull image if requested
    if [ "$do_pull" = "true" ]; then
        echo "    Pulling image..."
        if ! docker pull "$image_ref" > "$log_file" 2>&1; then
            echo "    Failed to pull image"
            return 1
        fi
    fi

    # Run scanner
    case "$scanner" in
        grype)
            local cmd="grype"
            case "$format" in
                json) cmd+=" -o json" ;;
                sarif) cmd+=" -o sarif" ;;
                table) cmd+=" -o table" ;;
                text) cmd+=" -o text" ;;
            esac
            cmd+=" \"$image_ref\""
            if eval "$cmd > $report_file 2>> $log_file"; then
                echo "    Grype scan completed: $report_file"
                return 0
            else
                echo "    Grype scan failed"
                return 1
            fi
            ;;
        trivy)
            local cmd="trivy image"
            case "$format" in
                json) cmd+=" -f json" ;;
                sarif) cmd+=" -f sarif" ;;
                table) cmd+=" -f table" ;;
                text) cmd+=" -f text" ;;
            esac
            cmd+=" \"$image_ref\""
            if eval "$cmd > $report_file 2>> $log_file"; then
                echo "    Trivy scan completed: $report_file"
                return 0
            else
                echo "    Trivy scan failed"
                return 1
            fi
            ;;
        snyk)
            if [ -z "${SNYK_TOKEN:-}" ]; then
                echo "    SNYK_TOKEN not set"
                return 1
            fi
            local cmd="snyk container test"
            case "$format" in
                json) cmd+=" --json" ;;
                sarif) cmd+=" --sarif" ;;
                *);;
            esac
            cmd+=" \"$image_ref\""
            if eval "$cmd > $report_file 2>> $log_file"; then
                echo "    Snyk scan completed: $report_file"
                return 0
            else
                echo "    Snyk scan failed"
                return 1
            fi
            ;;
        *)
            echo "    Unknown scanner: ${scanner}"
            return 1
            ;;
    esac
}

# Main function
main() {
    local services_arg=""
    local scanners_arg="grype,trivy"
    local severity_arg="critical,high"
    local format_arg="json"
    local fail_on="critical"
    local custom_output_dir=""
    local do_pull=false
    local custom_registry=""
    local dry_run=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --services) services_arg="$2"; shift 2 ;;
            --scanners) scanners_arg="$2"; shift 2 ;;
            --severity) severity_arg="$2"; shift 2 ;;
            --format) format_arg="$2"; shift 2 ;;
            --fail-on) fail_on="$2"; shift 2 ;;
            --output-dir) custom_output_dir="$2"; shift 2 ;;
            --do-not-pull) do_pull=false; shift ;;
            --pull) do_pull=true; shift ;;
            --registry) custom_registry="$2"; shift 2 ;;
            --dry-run) dry_run=true; shift ;;
            --help|-h) usage; exit 0 ;;
            -*) echo "Unknown option: $1"; usage; exit 1 ;;
            *) echo "Unexpected argument: $1"; usage; exit 1 ;;
        esac
    done

    if [ -n "$custom_output_dir" ]; then
        REPORT_DIR="$custom_output_dir"
    fi
    if [ -n "$custom_registry" ]; then
        PULL_REGISTRY="$custom_registry"
    fi

    cd "$PROJECT_ROOT"
    mkdir -p "$REPORT_DIR" "$LOG_DIR"

    # Get services
    local services=()
    if [ -n "$services_arg" ]; then
        IFS=',' read -ra services <<< "$services_arg"
    else
        local all_services=($(get_all_services | tr ',' '\n'))
        services=("${all_services[@]}")
    fi

    local scanners=()
    IFS=',' read -ra scanners <<< "$scanners_arg"

    echo "========================================"
    echo " container.gov.de Vulnerability Scanner"
    echo "========================================"
    echo "Services: ${#services[@]}"
    echo "Scanners: ${scanners[*]}"
    echo "Severity: $severity_arg"
    echo "Format: $format_arg"
    echo ""

    local success_count=0
    local failure_count=0

    for service in "${services[@]}"; do
        echo "Scanning service: ${service}"
        for scanner in "${scanners[@]}"; do
            echo ""
            if scan_image "$service" "$scanner" "$severity_arg" "$format_arg" "$REPORT_DIR" "$fail_on" "$do_pull" "$PULL_REGISTRY" "$dry_run"; then
                ((success_count++))
            else
                ((failure_count++))
            fi
        done
    done

    echo ""
    echo "========================================"
    echo " Scan Summary"
    echo "========================================"
    echo "Successful: $success_count"
    echo "Failed: $failure_count"
    echo "Total: $((success_count + failure_count))"
    echo ""
    echo "Reports saved to: $REPORT_DIR"

    if [ "$failure_count" -gt 0 ]; then
        exit 1
    fi
}

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Scan all container.gov.de compliant images for vulnerabilities

Options:
  --services SERVICES    Comma-separated list of services
  --scanners SCANNERS    Comma-separated list: grype,trivy,snyk
  --severity SEVERITIES  Comma-separated: critical,high,medium,low
  --format FORMATS       Output formats: json,sarif,table,text
  --fail-on FAIL_ON      Fail if vulnerabilities found at this level
  --output-dir DIR      Output directory for reports
  --do-not-pull         Do not pull images before scanning
  --pull                 Pull images before scanning
  --registry REGISTRY   pull from this registry
  --dry-run              Show what would be scanned
  --help                 Show this help message
EOF
}

main "$@"

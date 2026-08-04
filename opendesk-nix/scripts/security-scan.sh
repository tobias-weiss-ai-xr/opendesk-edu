#!/usr/bin/env bash
# Security Scanning Script for openDesk Containers
# SPDX-License-Identifier: Apache-2.0
# Maintainer: openDesk Edu Team <team@opendesk-edu.org>
#
# ==============================================================================
# Usage: ./scripts/security-scan.sh [options] [component]
#
# Options:
#   -h, --help           Show this help message
#   -v, --verbose        Enable verbose output
#   -f, --format FORMAT  Output format: table, json, sarif (default: table)
#   --severity SEV       Minimum severity: CRITICAL, HIGH, MEDIUM, LOW (default: HIGH)
#   --scan-type TYPE     Scan type: vuln, config, secret, all (default: all)
#   --exit-code          Exit with error code if vulnerabilities found
#   --no-cache           Disable cache
#   --offline            Run in offline mode
#   --skip-db-update     Skip vulnerability database update
#   --output FILE        Write report to file
#
# Components:
#   all          Scan all components
#   sogo5        Scan SOGo 5
#   sogo6        Scan SOGo 6
#   dev-agent    Scan Dev Agent
#   zot          Scan Zot Registry
#
# Examples:
#   ./scripts/security-scan.sh all
#   ./scripts/security-scan.sh sogo6 --severity CRITICAL
#   ./scripts/security-scan.sh dev-agent --format json --output dev-agent-scan.json
#   ./scripts/security-scan.sh --format sarif --output security-report.sarif
#
# ==============================================================================

set -euo pipefail

# ==============================================================================
# GLOBAL VARIABLES
# ==============================================================================

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default registry
REGISTRY="registry.gitlab.opencode.de/umr"

# Versions
SOGO5_VERSION="5.8.0"
SOGO6_VERSION="6.0.0"
DEV_AGENT_VERSION="2.1.0"
ZOT_VERSION="2.0.0-rc5"

# Severity levels
SEVERITY_LEVELS=("CRITICAL" "HIGH" "MEDIUM" "LOW")

# ==============================================================================
# FUNCTIONS
# ==============================================================================

# Print usage information
usage() {
    grep '^# ' "$0" | sed -e 's/^# //' -e 's/^#//' | head -n -1
    exit 0
}

# Log messages
log_info() {
    echo -e "\e[34m[INFO]\e[0m $*"
}

log_success() {
    echo -e "\e[32m[SUCCESS]\e[0m $*"
}

log_warning() {
    echo -e "\e[33m[WARNING]\e[0m $*"
}

log_error() {
    echo -e "\e[31m[ERROR]\e[0m $*" >&2
}

log_header() {
    echo -e "\e[96m\n$*\e[0m"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
check_dependencies() {
    local missing=()
    
    # Required tools
    if ! command_exists trivy; then
        missing+=("trivy")
    fi
    if ! command_exists docker; then
        missing+=("docker")
    fi
    if ! command_exists kubectl; then
        missing+=("kubectl")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_error "Install them with:"
        for cmd in "${missing[@]}"; do
            case $cmd in
                trivy)
                    echo "  trivy: curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin"
                    ;;
                docker)
                    echo "  docker: Follow instructions at https://docs.docker.com/get-docker/"
                    ;;
                kubectl)
                    echo "  kubectl: Follow instructions at https://kubernetes.io/docs/tasks/tools/"
                    ;;
            esac
        done
        exit 1
    fi
    
    log_success "All dependencies found"
}

# Get image name for component
get_image_name() {
    local component="$1"
    
    case "$component" in
        sogo5)
            echo "${REGISTRY}/opendesk-sogo5:${SOGO5_VERSION}"
            ;;
        sogo6)
            echo "${REGISTRY}/opendesk-sogo6:${SOGO6_VERSION}"
            ;;
        dev-agent)
            echo "${REGISTRY}/opendesk-dev-agent:${DEV_AGENT_VERSION}"
            ;;
        zot)
            echo "${REGISTRY}/zot-registry:${ZOT_VERSION}"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Build image if it doesn't exist locally
build_image() {
    local component="$1"
    local image_name
    image_name="$(get_image_name "$component")"
    
    if [ -z "$image_name" ]; then
        log_error "Unknown component: $component"
        return 1
    fi
    
    # Check if image exists locally
    if ! docker inspect "$image_name" >/dev/null 2>&1; then
        log_info "Image not found locally: $image_name, building..."
        case "$component" in
            sogo5)
                make -C "$PROJECT_ROOT" build-sogo5
                ;;
            sogo6)
                make -C "$PROJECT_ROOT" build-sogo6
                ;;
            dev-agent)
                make -C "$PROJECT_ROOT" build-dev-agent
                ;;
            zot)
                make -C "$PROJECT_ROOT" build-zot
                ;;
        esac
    else
        log_info "Using existing image: $image_name"
    fi
}

# Scan a single image with Trivy
trivy_scan() {
    local image="$1"
    local severity="$2"
    local format="$3"
    local output_file="$4"
    local offline="$5"
    local no_cache="$6"
    local scan_type="$7"
    local verbose="$8"
    
    local args=()
    
    # Add format
    if [ -n "$format" ]; then
        args+=("--format" "$format")
    fi
    
    # Add severity
    if [ -n "$severity" ]; then
        args+=("--severity" "$severity")
    fi
    
    # Add offline mode
    if [ "$offline" = "true" ]; then
        args+=("--offline")
    fi
    
    # Add no cache
    if [ "$no_cache" = "true" ]; then
        args+=("--no-cache")
    fi
    
    # Add verbose
    if [ "$verbose" = "true" ]; then
        args+=("--verbose")
    fi
    
    # Add output file
    if [ -n "$output_file" ]; then
        args+=("--output" "$output_file")
    fi
    
    # Add scan type
    case "$scan_type" in
        vuln)
            args+=("image")
            ;;
        config)
            args+=("config")
            ;;
        secret)
            args+=("fs")
            ;;
        all)
            args+=("image")
            ;;
    esac
    
    log_info "Scanning: $image"
    echo "  Command: trivy ${args[]} $image"
    
    # Run Trivy scan
    if [ "$scan_type" = "secret" ]; then
        # For secret scanning, we need to mount the filesystem
        docker run --rm -v "$PROJECT_ROOT":/src -w /src "$image" sh -c "exit 0" >/dev/null 2>&1
        trivy fs ${args[]} /src
    else
        trivy image ${args[]} "$image"
    fi
}

# Scan a component
scan_component() {
    local component="$1"
    local severity="$2"
    local format="$3"
    local output_file="$4"
    local offline="$5"
    local no_cache="$6"
    local scan_type="$7"
    local verbose="$8"
    
    local image_name
    image_name="$(get_image_name "$component")"
    
    if [ -z "$image_name" ]; then
        log_error "Unknown component: $component"
        return 1
    fi
    
    log_header "Scanning: $component ($image_name)"
    
    # Build image if needed
    build_image "$component"
    
    # Generate output filename if not provided
    local component_output=""
    if [ -n "$output_file" ]; then
        # Ensure directory exists
        mkdir -p "$(dirname "$output_file")"
        component_output="$output_file"
    fi
    
    # Run scan based on type
    case "$scan_type" in
        vuln)
            trivy_scan "$image_name" "$severity" "$format" "$component_output" "$offline" "$no_cache" "vuln" "$verbose"
            ;;
        config)
            # Config scanning requires Dockerfile or Kubernetes manifests
            local config_dir="$PROJECT_ROOT/docker/$component"
            if [ -d "$config_dir" ]; then
                trivy config --severity "$severity" --format "$format" "$config_dir"
            fi
            ;;
        secret)
            trivy_scan "$image_name" "$severity" "$format" "$component_output" "$offline" "$no_cache" "secret" "$verbose"
            ;;
        all)
            log_info "Running comprehensive scan (vulnerabilities + config + secrets)..."
            
            # Vulnerability scan
            if [ "$format" = "sarif" ] || [ "$format" = "json" ]; then
                local vuln_file="${component_output:-${component}-vuln.${format}}"
                trivy_scan "$image_name" "$severity" "$format" "$vuln_file" "$offline" "$no_cache" "vuln" "$verbose"
            else
                trivy_scan "$image_name" "$severity" "$format" "" "$offline" "$no_cache" "vuln" "$verbose"
            fi
            
            # Config scan
            log_info "Scanning configuration files..."
            local config_dir="$PROJECT_ROOT/docker/$component"
            if [ -d "$config_dir" ]; then
                trivy config --severity "$severity" --format "table" "$config_dir"
            fi
            
            # Secret scan
            log_info "Scanning for secrets..."
            trivy fs --security-checks secret --severity "$severity" --format "table" "$PROJECT_ROOT/docker/$component"
            ;;
    esac
}

# Main scan function
main() {
    local component=""
    local severity="HIGH"
    local format="table"
    local output_file=""
    local offline="false"
    local no_cache="false"
    local scan_type="all"
    local verbose="false"
    local exit_code="false"
    local skip_db_update="false"
    
    # ===========================================================================
    # PARSE ARGUMENTS
    # ===========================================================================
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            -v|--verbose)
                verbose="true"
                shift
                ;;
            -f|--format)
                format="$2"
                shift 2
                ;;
            --severity)
                severity="$2"
                # Convert to uppercase
                severity="$(echo "$severity" | tr '[:lower:]' '[:upper:]')"
                shift 2
                ;;
            --scan-type)
                scan_type="$2"
                shift 2
                ;;
            --exit-code)
                exit_code="true"
                shift
                ;;
            --no-cache)
                no_cache="true"
                shift
                ;;
            --offline)
                offline="true"
                shift
                ;;
            --skip-db-update)
                skip_db_update="true"
                shift
                ;;
            --output)
                output_file="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [ -n "$component" ]; then
                    log_error "Multiple components specified: $component and $1"
                    usage
                    exit 1
                fi
                component="$1"
                shift
                ;;
        esac
    done
    
    # Validate severity
    if ! printf '%s\n' "${SEVERITY_LEVELS[@]}" | grep -q "^${severity}$"; then
        log_error "Invalid severity: $severity. Must be one of: ${SEVERITY_LEVELS[*]}"
        exit 1
    fi
    
    # Validate format
    if [ "$format" != "table" ] && [ "$format" != "json" ] && [ "$format" != "sarif" ]; then
        log_error "Invalid format: $format. Must be one of: table, json, sarif"
        exit 1
    fi
    
    # Validate scan type
    if [ "$scan_type" != "vuln" ] && [ "$scan_type" != "config" ] && [ "$scan_type" != "secret" ] && [ "$scan_type" != "all" ]; then
        log_error "Invalid scan type: $scan_type. Must be one of: vuln, config, secret, all"
        exit 1
    fi
    
    # Set default component
    if [ -z "$component" ]; then
        component="all"
    fi
    
    # ===========================================================================
    # INITIAL SETUP
    # ===========================================================================
    
    log_header "openDesk Security Scanning"
    log_info "Component: ${component}"
    log_info "Severity: ${severity}"
    log_info "Format: ${format}"
    log_info "Scan Type: ${scan_type}"
    log_info "Exit on Vulnerabilities: ${exit_code}"
    log_info "Offline Mode: ${offline}"
    log_info "No Cache: ${no_cache}"
    log_info "Skip DB Update: ${skip_db_update}"
    
    # Check dependencies
    check_dependencies
    
    # Update Trivy database (unless skipped or offline)
    if [ "$skip_db_update" = "false" ] && [ "$offline" = "false" ]; then
        log_info "Updating Trivy vulnerability database..."
        if ! trivy image --download-db-only; then
            log_warning "Failed to update Trivy database, continuing with cached database"
        fi
    fi
    
    # ===========================================================================
    # RUN SCANS
    # ===========================================================================
    
    local has_vulnerabilities="false"
    local components=()
    
    case "$component" in
        all)
            components=("sogo5" "sogo6" "dev-agent" "zot")
            ;;
        sogo5|sogo6|dev-agent|zot)
            components=("$component")
            ;;
        *)
            log_error "Unknown component: $component"
            usage
            exit 1
            ;;
    esac
    
    for comp in "${components[@]}"; do
        local comp_output=""
        if [ -n "$output_file" ]; then
            # Append component name to output file
            local base="$(basename "$output_file" .$format)"
            local dir="$(dirname "$output_file")"
            comp_output="$dir/${base}-${comp}.${format}"
        fi
        
        if ! scan_component "$comp" "$severity" "$format" "$comp_output" "$offline" "$no_cache" "$scan_type" "$verbose"; then
            has_vulnerabilities="true"
        fi
        
        echo ""
    done
    
    # ===========================================================================
    # SUMMARY
    # ===========================================================================
    
    log_header "Security Scanning Complete"
    log_success "Scanned ${#components[@]} component(s): ${components[*]}"
    
    if [ "$has_vulnerabilities" = "true" ]; then
        log_warning "Vulnerabilities found"
        if [ "$exit_code" = "true" ]; then
            exit 1
        fi
    else
        log_success "No vulnerabilities found above severity: ${severity}"
    fi
    
    exit 0
}

# ==============================================================================
# ENTRY POINT
# ==============================================================================

main "$@"

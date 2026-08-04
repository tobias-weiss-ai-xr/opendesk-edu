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
OUTPUT_DIR="$SCRIPT_DIR/../migrate-upstream/output"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Scan all container.gov.de compliant images for vulnerabilities using Grype and Trivy

Options:
  --services SERVICES    Comma-separated list of services (default: all in docker/services)
  --scanners SCANNERS    Comma-separated list of scanners: grype,trivy,snyk (default: grype,trivy)
  --severity SEVERITIES  Comma-separated severity levels: critical,high,medium,low (default: critical,high)
  --format FORMATS       Output formats: json,sarif,table,text (default: json)
  --parallel N           Number of parallel scans (default: 1)
  --fail-on FAIL_ON      Fail if vulnerabilities found at this level or higher: critical,high,medium,low (default: critical)
  --output-dir DIR      Output directory for reports (default: $REPORT_DIR)
  --do not-pull         Do not pull images from registry
  --registry REGISTRY   pull from this registry (default: opencode.de/opendesk-edu)
  --dry-run              Show what would be scanned without actually scanning
  --help                 Show this help message

Examples:
  $0                             # Scan all images with Grype and Trivy
  $0 --services nginx,redis       # Scan only nginx and redis
  $0 --scanners grype            # Scan with only Grype
  $0 --severity critical,high    # Only report critical and high vulnerabilities
  $0 --fail-on high              # Fail if high or critical vulnerabilities found
  $0 --parallel 4                # Scan 4 images in parallel
  $0 --dry-run                   # Show what would be scanned

container.gov.de Compliance:
  BG-8: Schwachstellenscans (Vulnerability Scans) requires:
  - Images must be scanned for vulnerabilities
  - Critical and High vulnerabilities must be addressed
  - Scans should be automated and integrated in CI/CD
EOF
}

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
        echo -e "${YELLOW}[DRY RUN]${NC} Would scan ${CYAN}${image_name}:${version}${NC} with ${scanner}"
        return 0
    fi
    
    echo -e "${BLUE}Scanning ${CYAN}${service}${NC} (${image_name}:${version}) with ${scanner}..."
    
    local report_file="$output_dir/${service}-${scanner}-${version}.${format}"
    local log_file="$LOG_DIR/${service}-${scanner}.log"
    
    mkdir -p "$output_dir" "$LOG_DIR"
    
    # Pull image if requested and not local
    if [ "$do_pull" = "true" ]; then
        echo -e "  Pulling image..."
        if ! docker pull "$image_ref" 2>&1 | tee "$log_file"; then
            echo -e "  ${RED}✗ Failed to pull image${NC}"
            return 1
        fi
    fi
    
    # Run scanner
    case "$scanner" in
        grype)
            # Build severity arguments
            local severity_args=()
            IFS=',' read -ra sev_levels <<< "$severity"
            for sev in "${sev_levels[@]}"; do
                case "$sev" in
                    critical) severity_args+=("critical") ;;
                    high) severity_args+=("high") ;;
                    medium) severity_args+=("medium") ;;
                    low) severity_args+=("low") ;;
                    *) ;;
                esac
            done
            
            local grype_severity=""
            if [ ${#severity_args[@]} -gt 0 ]; then
                grype_severity=$(IFS="," ; echo "${severity_args[*]}")
            fi
            
            # Run grype
            local cmd="grype"
            [ -n "$grype_severity" ] && cmd+=" --fail-on-severity=$grype_severity"
            
            case "$format" in
                json) cmd+=" -o json" ;;
                sarif) cmd+=" -o sarif" ;;
                table) cmd+=" -o table" ;;
                text) cmd+=" -o text" ;;
            esac
            
            cmd+=" \"$image_ref\""
            
            if eval "$cmd > $report_file 2>> $log_file"; then
                echo -e "  ${GREEN}✓ Grype scan completed: ${report_file}${NC}"
                
                # Check for vulnerabilities based on fail_on
                if [ -n "$fail_on" ]; then
                    local vuln_found=false
                    case "$format" in
                        json)
                            if jq -e ".matches[] | select(.vulnerability.severity == \"$fail_on\" or .vulnerability.severity == \"CRITICAL\")" "$report_file" > /dev/null 2>&1; then
                                vuln_found=true
                            fi
                            ;;
                        *)
                            if grep -i "$fail_on" "$report_file" > /dev/null 2>&1; then
                                vuln_found=true
                            fi
                            ;;
                    esac
                    
                    # Also check higher severity levels
                    local fail_severities=()
                    case "$fail_on" in
                        critical) fail_severities=("critical") ;;
                        high) fail_severities=("critical" "high") ;;
                        medium) fail_severities=("critical" "high" "medium") ;;
                        low) fail_severities=("critical" "high" "medium" "low") ;;
                    esac
                    
                    for sev in "${fail_severities[@]}"; do
                        if [ "$sev" = "$fail_on" ]; then
                            continue
                        fi
                        case "$format" in
                            json)
                                if jq -e ".matches[] | select(.vulnerability.severity == \"${sev}\")" "$report_file" > /dev/null 2>&1; then
                                    vuln_found=true
                                    break
                                fi
                                ;;
                            *)
                                if grep -i "$sev" "$report_file" > /dev/null 2>&1; then
                                    vuln_found=true
                                    break
                                fi
                                ;;
                        esac
                    done
                    
                    if [ "$vuln_found" = "true" ]; then
                        echo -e "  ${RED}✗ Vulnerabilities found at or above ${fail_on} level${NC}"
                        return 1
                    fi
                fi
                
                return 0
            else
                echo -e "  ${RED}✗ Grype scan failed${NC}"
                return 1
            fi
            ;;
        trivy)
            # Build severity arguments for Trivy
            local severity_args=()
            IFS=',' read -ra sev_levels <<< "$severity"
            for sev in "${sev_levels[@]}"; do
                case "$sev" in
                    critical) severity_args+=("CRITICAL") ;;
                    high) severity_args+=("HIGH") ;;
                    medium) severity_args+=("MEDIUM") ;;
                    low) severity_args+=("LOW") ;;
                    *) ;;
                esac
            done
            
            local trivy_severity=""
            if [ ${#severity_args[@]} -gt 0 ]; then
                trivy_severity=$(IFS="," ; echo "${severity_args[*]}")
            fi
            
            # Run trivy
            local cmd="trivy image"
            [ -n "$trivy_severity" ] && cmd+=" --severity $trivy_severity"
            
            case "$format" in
                json) cmd+=" -f json" ;;
                sarif) cmd+=" -f sarif" ;;
                table) cmd+=" -f table" ;;
                text) cmd+=" -f text" ;;
            esac
            
            cmd+=" \"$image_ref\""
            
            if eval "$cmd > $report_file 2>> $log_file"; then
                echo -e "  ${GREEN}✓ Trivy scan completed: ${report_file}${NC}"
                
                # Check for vulnerabilities based on fail_on
                if [ -n "$fail_on" ]; then
                    local vuln_found=false
                    
                    local fail_severities=()
                    case "$fail_on" in
                        critical) fail_severities=("CRITICAL") ;;
                        high) fail_severities=("CRITICAL" "HIGH") ;;
                        medium) fail_severities=("CRITICAL" "HIGH" "MEDIUM") ;;
                        low) fail_severities=("CRITICAL" "HIGH" "MEDIUM" "LOW") ;;
                    esac
                    
                    for sev in "${fail_severities[@]}"; do
                        case "$format" in
                            json)
                                if jq -e ".Results[] | .Vulnerabilities[] | .Severity == \"${sev}\"" "$report_file" > /dev/null 2>&1; then
                                    vuln_found=true
                                    break
                                fi
                                ;;
                            *)
                                if grep -i "$sev" "$report_file" > /dev/null 2>&1; then
                                    vuln_found=true
                                    break
                                fi
                                ;;
                        esac
                    done
                    
                    if [ "$vuln_found" = "true" ]; then
                        echo -e "  ${RED}✗ Vulnerabilities found at or above ${fail_on} level${NC}"
                        return 1
                    fi
                fi
                
                return 0
            else
                echo -e "  ${RED}✗ Trivy scan failed${NC}"
                return 1
            fi
            ;;
        snyk)
            echo -e "  ${YELLOW}⚠ Snyk scanner is cloud-based and requires API token${NC}"
            echo -e "  Set SNYK_TOKEN environment variable to use Snyk${NC}"
            
            if [ -z "${SNYK_TOKEN:-}" ]; then
                echo -e "  ${RED}✗ SNYK_TOKEN not set${NC}"
                return 1
            fi
            
            # Run snyk
            local cmd="snyk container test"
            case "$format" in
                json) cmd+=" --json" ;;
                sarif) cmd+=" --sarif" ;;
                *);;
            esac
            
            cmd+=" \"$image_ref\""
            
            if eval "$cmd > $report_file 2>> $log_file"; then
                echo -e "  ${GREEN}✓ Snyk scan completed: ${report_file}${NC}"
                return 0
            else
                echo -e "  ${RED}✗ Snyk scan failed${NC}"
                return 1
            fi
            ;;
        *)
            echo -e "  ${RED}✗ Unknown scanner: ${scanner}${NC}"
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
    local parallel=1
    local fail_on="critical"
    local custom_output_dir=""
    local do_pull=false
    local custom_registry=""
    local dry_run=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --services)
                services_arg="$2"
                shift 2
                ;;
            --scanners)
                scanners_arg="$2"
                shift 2
                ;;
            --severity)
                severity_arg="$2"
                shift 2
                ;;
            --format)
                format_arg="$2"
                shift 2
                ;;
            --parallel)
                parallel="$2"
                shift 2
                ;;
            --fail-on)
                fail_on="$2"
                shift 2
                ;;
            --output-dir)
                custom_output_dir="$2"
                shift 2
                ;;
            --do-not-pull)
                do_pull=false
                shift
                ;;
            --pull)
                do_pull=true
                shift
                ;;
            --registry)
                custom_registry="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            -*)
                echo -e "${RED}Unknown option: $1${NC}"
                usage
                exit 1
                ;;
            *)
                echo -e "${RED}Unexpected argument: $1${NC}"
                usage
                exit 1
                ;;
        esac
    done
    
    # Set output directory
    if [ -n "$custom_output_dir" ]; then
        REPORT_DIR="$custom_output_dir"
    fi
    
    # Set registry for pulling
    if [ -n "$custom_registry" ]; then
        PULL_REGISTRY="$custom_registry"
    else
        PULL_REGISTRY="opencode.de/opendesk-edu"
    fi
    
    cd "$PROJECT_ROOT"
    
    # Create directories
    mkdir -p "$REPORT_DIR" "$LOG_DIR"
    
    # Check for required tools
    local missing_tools=()
    for scanner in $(echo "$scanners_arg" | tr ',' '\n'); do
        case "$scanner" in
            grype) if ! command -v grype &> /dev/null; then missing_tools+=("grype"); fi ;;
            trivy) if ! command -v trivy &> /dev/null; then missing_tools+=("trivy"); fi ;;
            snyk) if ! command -v snyk &> /dev/null; then missing_tools+=("snyk"); fi ;;
        esac
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing scanners: ${missing_tools[*]}${NC}"
        echo -e "Install with Nix:"
        for tool in "${missing_tools[@]}"; do
            echo -e "  nix-env -iA nixpkgs.${tool}"
        done
        exit 1
    fi
    
    # Check Docker
    if [ "$dry_run" != "true" ] && ! docker info > /dev/null 2>&1; then
        echo -e "${RED}Error: Docker daemon is not running${NC}"
        exit 1
    fi
    
    # Get services to scan
    local services=()
    if [ -n "$services_arg" ]; then
        IFS=',' read -ra services <<< "$services_arg"
    else
        local all_services=($(get_all_services | tr ',' '\n'))
        services=("${all_services[@]}")
    fi
    
    if [ ${#services[@]} -eq 0 ]; then
        echo -e "${RED}Error: No services found to scan${NC}"
        usage
        exit 1
    fi
    
    # Get scanners
    local scanners=()
    IFS=',' read -ra scanners <<< "$scanners_arg"
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}container.gov.de Vulnerability Scanner${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Services to scan:${NC} ${#services[@]}"
    echo -e "${BLUE}Scanners:${NC} ${scanners[*]}"
    echo -e "${BLUE}Severity levels:${NC} $severity_arg"
    echo -e "${BLUE}Output format:${NC} $format_arg"
    echo -e "${BLUE}Parallel jobs:${NC} $parallel"
    echo -e "${BLUE}Fail on:${NC} $fail_on"
    echo -e "${BLUE}Pull from registry:${NC} $do_pull ($PULL_REGISTRY)"
    [ "$dry_run" = "true" ] && echo -e "${YELLOW}Dry run mode enabled${NC}"
    echo ""
    
    # Scan images
    if [ "$parallel" -gt 1 ] && [ "$parallel" -le $(( ${#services[@]} * ${#scanners[@]} )) ]; then
        # Parallel scan
        echo -e "${BLUE}Scanning with ${parallel} parallel jobs...${NC}"
        
        # Generate all scan combinations
        local all_scans=()
        for service in "${services[@]}"; do
            for scanner in "${scanners[@]}"; do
                all_scans+=("$service $scanner")
            done
        done
        
        seq 0 $(( ${#all_scans[@]} - 1 )) | xargs -P "$parallel" -I {} sh -c '
            scan="${all_scans[{}]}"
            svc=$(echo "$scan" | awk "{print \$1}")
            scanner=$(echo "$scan" | awk "{print \$2}")
            '"$0'" --services "\$svc" --scanners "\$scanner" --severity "$severity_arg" --format "$format_arg" --output-dir "$REPORT_DIR" --fail-on "$fail_on" --do-not-pull --registry "$PULL_REGISTRY" --dry-run $dry_run
        ' _ "$0"
    else
        # Sequential scan
        local success_count=0
        local failure_count=0
        local vuln_found_count=0
        
        for service in "${services[@]}"; do
            echo ""
            echo -e "${BLUE}========================================${NC}"
            echo -e "${BLUE}Scanning service: ${CYAN}${service}${NC}"
            echo -e "${BLUE}========================================${NC}"
            
            for scanner in "${scanners[@]}"; do
                echo ""
                if scan_image "$service" "$scanner" "$severity_arg" "$format_arg" "$REPORT_DIR" "$fail_on" "$do_pull" "$PULL_REGISTRY" "$dry_run"; then
                    ((success_count++))
                    echo -e "  ${GREEN}✓ ${scanner} scan passed${NC}"
                else
                    ((failure_count++))
                    echo -e "  ${RED}✗ ${scanner} scan failed or vulnerabilities found${NC}"
                    ((vuln_found_count++))
                fi
            done
            
            echo ""
        done
        
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}Scan Summary${NC}"
        echo -e "========================================${NC}"
        echo -e "${GREEN}Successful scans: $success_count${NC}"
        echo -e "${RED}Failed scans:      $failure_count${NC}"
        echo -e "${RED}Vulnerabilities found: $vuln_found_count${NC}"
        echo -e "${BLUE}Total scans:      $((success_count + failure_count))${NC}"
        
        echo ""
        echo -e "${BLUE}Reports saved to:${NC} $REPORT_DIR"
        
        if [ "$failure_count" -gt 0 ] || [ "$vuln_found_count" -gt 0 ]; then
            echo -e "${RED}⚠ Some scans failed or vulnerabilities found${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}✓ All scans completed successfully!${NC}"
        
        # Show next steps
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo -e "  1. Review scan reports in: $REPORT_DIR"
        echo -e "  2. Fix vulnerabilities in source packages"
        echo -e "  3. Rebuild images: ./scripts/container-gov-de/build-all.sh"
        echo -e "  4. Re-scan: $0"
    fi
}

# Run main with all arguments
main "$@"

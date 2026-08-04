#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 container.gov.de Contributors
# Build All container.gov.de Compliant Images
# Usage: ./build-all.sh [OPTIONS]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"
LOG_DIR="./logs"
OUTPUT_DIR="./output"
TEMPLATE_FILE="templates/container-gov-de/default.nix"

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

Build all container.gov.de compliant images

Options:
  --services SECRVICES   Comma-separated list of services to build (default: all)
  --parallel N          Number of parallel builds (default: 1)
  --dry-run             Show what would be built without actually building
  --output-dir DIR      Output directory for built images (default: ./output)
  --log-dir DIR         Log directory (default: ./logs)
  --skip-existing       Skip services that already exist
  --clean               Clean build (remove previous outputs)
  --help                Show this help message

Examples:
  $0                              # Build all services
  $0 --services nginx,mariadb     # Build only nginx and mariadb
  $0 --parallel 4                 # Build with 4 parallel jobs
  $0 --dry-run                    # Show what would be built
  $0 --clean --parallel 4         # Clean and build in parallel

container.gov.de Requirements:
  All images will be built with BG-1 through BG-8 compliance
EOF
}

# Get all services
get_all_services() {
    cd "$PROJECT_ROOT"
    if [ -d "docker/services" ]; then
        find docker/services -maxdepth 1 -type d ! -name "services" ! -name ".*" | sed 's|docker/services/||' | sed '/^$/d' | sort | tr '\n' ',' | sed 's/,$//'
    else
        echo "nginx,mariadb,postgresql,redis,traefik,keycloak,nextcloud,moodle,ilias,openproject"
    fi
}

# Build a single service
build_service() {
    local service="$1"
    local output_dir="$2"
    local log_dir="$3"
    local dry_run="$4"
    
    local log_file="$log_dir/${service}.log"
    local output_file="$output_dir/${service}.tar.gz"
    
    mkdir -p "$output_dir" "$log_dir"
    
    if [ "$dry_run" = "true" ]; then
        echo -e "${BLUE}[DRY RUN]${NC} Would build: ${CYAN}${service}${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Building:${NC} ${CYAN}${service}${NC}"
    
    cd "$PROJECT_ROOT"
    
    # Build the container
    if ! nix build -f "$TEMPLATE_FILE" --argstr service "$service" 2>&1 | tee "$log_file"; then
        echo -e "${RED}✗ Failed to build: ${service}${NC}"
        return 1
    fi
    
    # Get the result path
    local result_path
    result_path=$(grep -oE '/nix/store/[a-z0-9]+-container-gov-de-[a-z0-9-]+' "$log_file" | head -1)
    
    if [ -z "$result_path" ]; then
        echo -e "${RED}✗ Could not find result path for: ${service}${NC}"
        return 1
    fi
    
    # Copy to output directory
    cp "$result_path" "$output_file"
    
    echo -e "${GREEN}✓ Built:${NC} ${CYAN}${service}${NC} -> ${output_file}"
    
    return 0
}

# Clean build
clean_build() {
    local output_dir="$1"
    local log_dir="$2"
    
    echo -e "${YELLOW}Cleaning build directories...${NC}"
    
    rm -rf "$output_dir" "$log_dir"
    mkdir -p "$output_dir" "$log_dir"
    
    echo -e "${GREEN}✓ Cleaned:${NC} $output_dir and $log_dir"
}

# Main function
main() {
    local services=""
    local parallel=1
    local dry_run=false
    local skip_existing=false
    local clean=false
    local custom_output_dir=""
    local custom_log_dir=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --services)
                services="$2"
                shift 2
                ;;
            --parallel)
                parallel="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --output-dir)
                custom_output_dir="$2"
                shift 2
                ;;
            --log-dir)
                custom_log_dir="$2"
                shift 2
                ;;
            --skip-existing)
                skip_existing=true
                shift
                ;;
            --clean)
                clean=true
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
    
    # Set directories
    if [ -n "$custom_output_dir" ]; then
        OUTPUT_DIR="$custom_output_dir"
    fi
    if [ -n "$custom_log_dir" ]; then
        LOG_DIR="$custom_log_dir"
    fi
    
    # Absolute paths
    OUTPUT_DIR="$(cd "$PROJECT_ROOT" && realpath "$OUTPUT_DIR")"
    LOG_DIR="$(cd "$PROJECT_ROOT" && realpath "$LOG_DIR")"
    
    cd "$PROJECT_ROOT"
    
    # Check if we're in a Nix flake directory
    if [ ! -f "flake.nix" ]; then
        echo -e "${RED}Error: Not in a Nix flake directory${NC}"
        exit 1
    fi
    
    # Clean if requested
    if [ "$clean" = "true" ]; then
        clean_build "$OUTPUT_DIR" "$LOG_DIR"
    fi
    
    # Create directories
    mkdir -p "$OUTPUT_DIR" "$LOG_DIR"
    
    # Get services to build
    if [ -z "$services" ]; then
        services=$(get_all_services)
    fi
    
    # Convert comma-separated to array
    IFS=',' read -ra service_array <<< "$services"
    
    echo -e "${BLUE}container.gov.de Compliant Image Builder${NC}"
    echo -e "=============================================="
    echo -e "${BLUE}Services to build:${NC} ${#service_array[@]}"
    echo -e "${BLUE}Parallel jobs:${NC} $parallel"
    echo -e "${BLUE}Output directory:${NC} $OUTPUT_DIR"
    echo -e "${BLUE}Log directory:${NC} $LOG_DIR"
    if [ "$dry_run" = "true" ]; then
        echo -e "${YELLOW}Dry run mode - no actual builds will be performed${NC}"
    fi
    echo ""
    
    # Build all services
    local success_count=0
    local failure_count=0
    local skip_count=0
    
    if [ "$parallel" -gt 1 ] && [ "$parallel" -le ${#service_array[@]} ]; then
        # Parallel build using GNU parallel or xargs
        if command -v parallel &> /dev/null; then
            seq 0 $(( ${#service_array[@]} - 1 )) | parallel -j "$parallel" --will-cite --progress --eta --halt now,fail=1 'build_service "${service_array[{}]}" "$OUTPUT_DIR" "$LOG_DIR" "$dry_run"'
        else
            echo -e "${YELLOW}Warning: GNU parallel not found, falling back to sequential build${NC}"
            echo -e "${YELLOW}Install parallel with: nix-env -iA nixpkgs.parallel${NC}"
            for service in "${service_array[@]}"; do
                if build_service "$service" "$OUTPUT_DIR" "$LOG_DIR" "$dry_run"; then
                    ((success_count++))
                else
                    ((failure_count++))
                fi
            done
        fi
    else
        # Sequential build
        for service in "${service_array[@]}"; do
            # Skip if already exists and requested
            if [ "$skip_existing" = "true" ] && [ -f "$OUTPUT_DIR/${service}.tar.gz" ]; then
                echo -e "${YELLOW}Skipping:${NC} ${CYAN}${service}${NC} (already exists)"
                ((skip_count++))
                continue
            fi
            
            if build_service "$service" "$OUTPUT_DIR" "$LOG_DIR" "$dry_run"; then
                ((success_count++))
            else
                ((failure_count++))
            fi
        done
    fi
    
    echo ""
    echo -e "${BLUE}==============================================${NC}"
    echo -e "${BLUE}Build Summary${NC}"
    echo -e "==============================================${NC}"
    echo -e "${GREEN}Successful: ${success_count}${NC}"
    echo -e "${RED}Failed:      ${failure_count}${NC}"
    if [ "$skip_existing" = "true" ]; then
        echo -e "${YELLOW}Skipped:     ${skip_count}${NC}"
    fi
    echo -e "${BLUE}Total:       $((success_count + failure_count + skip_count))${NC}"
    
    if [ "$dry_run" = "true" ]; then
        echo -e "${YELLOW}Note: This was a dry run - no images were actually built${NC}"
    fi
    
    if [ "$failure_count" -gt 0 ]; then
        echo -e ""
        echo -e "${RED}✗ Some services failed to build${NC}"
        echo -e "Check logs in:${NC} $LOG_DIR"
        exit 1
    fi
    
    echo -e ""
    echo -e "${GREEN}✓ All services built successfully!${NC}"
    echo -e "Images are available in:${NC} $OUTPUT_DIR"
    
    # Show next steps
    echo -e ""
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "  1. Load images: docker load < ${OUTPUT_DIR}/SERVICE.tar.gz"
    echo -e "  2. Scan images: ./scripts/container-gov-de/scan-all.sh"
    echo -e "  3. Sign images: ./scripts/container-gov-de/sign-all.sh"
    echo -e "  4. Check compliance: ./scripts/container-gov-de/check-compliance.sh --all"
    echo -e "  5. Push to registry: ./scripts/container-gov-de/push-all.sh"
}

main "$@"

#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 container.gov.de Contributors
# Push All container.gov.de Compliant Images to Registry
# Usage: ./push-all.sh [OPTIONS]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"
DOCKER_SERVICES_DIR="$PROJECT_ROOT/docker/services"
LOG_DIR="$SCRIPT_DIR/../migrate-upstream/logs"
OUTPUT_DIR="$SCRIPT_DIR/../migrate-upstream/output"

# Default registry - can be overridden with --registry
default_registry() {
    # Try to get from environmental variables
    if [ -n "${reg:-}" ]; then
        echo "$reg"
    elif [ -n "${OPENCODE_REGISTRY:-}" ]; then
        echo "$OPENCODE_REGISTRY"
    else
        echo "opencode.de/opendesk-edu"
    fi
}

TARGET_REGISTRY=$(default_registry)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Push all container.gov.de compliant images to registry

Options:
  --registry REGISTRY    Target registry (default: $TARGET_REGISTRY)
  --services SERVICES    Comma-separated list of services (default: all in docker/services)
  --tag TAG              Tag to push (default: latest + version)
  --parallel N           Number of parallel pushes (default: 1)
  --force                Force push (overwrite existing)
  --dry-run              Show what would be pushed without actually pushing
  --clean                Clean local images before pushing
  --help                 Show this help message

Examples:
  $0                             # Push all images to $TARGET_REGISTRY
  $0 --registry local:5000       # Push to local registry
  $0 --services nginx,redis       # Push only nginx and redis
  $0 --tag v1.0.0                 # Push with custom tag
  $0 --parallel 4                # Push 4 images in parallel
  $0 --dry-run                   # Show what would be pushed

Requirements:
  - docker CLI installed and configured
  - logged in to target registry (docker login)
  - images built and available locally
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

# Get image tag from Nix expression
get_image_tag() {
    local service="$1"
    local service_dir="$DOCKER_SERVICES_DIR/$service/nixos"
    
    if [ -f "$service_dir/default.nix" ]; then
        # Extract tag from default.nix
        grep -E "tag\s*=" "$service_dir/default.nix" | grep -oE '"[^"]+"' | tr -d '"' | head -1
    else
        echo "latest"
    fi
}

# Push a single image
push_image() {
    local service="$1"
    local registry="$2"
    local tag="$3"
    local force="$4"
    local dry_run="$5"
    
    local service_dir="$DOCKER_SERVICES_DIR/$service"
    local version=$(get_image_tag "$service")
    
    # Determine image name
    local image_name="opendesk-edu/${service}"
    
    if [ "$dry_run" = "true" ]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would push: ${CYAN}${registry}/${image_name}:${tag}${NC}"
        if [ "$tag" = "latest" ]; then
            echo -e "${YELLOW}[DRY RUN]${NC} Would push: ${CYAN}${registry}/${image_name}:${version}${NC}"
        fi
        return 0
    fi
    
    echo -e "${BLUE}Pushing: ${CYAN}${service}${NC}"
    
    # Load the image if it's a tar.gz file
    local tar_file="$OUTPUT_DIR/${service}.tar.gz"
    if [ -f "$tar_file" ]; then
        echo -e "  Loading from: ${tar_file}"
        if ! docker load < "$tar_file" 2>&1; then
            echo -e "${RED}✗ Failed to load: ${service}${NC}"
            return 1
        fi
    fi
    
    # Get the actual image name from Docker
    local local_image=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "${service}" | head -1)
    
    if [ -z "$local_image" ]; then
        echo -e "${RED}✗ Image not found: ${service}${NC}"
        return 1
    fi
    
    # Tag the image
    docker tag "$local_image" "${registry}/${image_name}:${tag}"
    docker tag "$local_image" "${registry}/${image_name}:${version}"
    
    # Push with force if requested
    local push_cmd="docker push"
    if [ "$force" = "true" ]; then
        push_cmd="$push_cmd --force"
    fi
    
    # Push latest tag
    if $push_cmd "${registry}/${image_name}:${tag}" 2>&1; then
        echo -e "  ${GREEN}✓ Pushed: ${registry}/${image_name}:${tag}${NC}"
    else
        echo -e "  ${RED}✗ Push failed: ${registry}/${image_name}:${tag}${NC}"
        return 1
    fi
    
    # Push version tag
    if $push_cmd "${registry}/${image_name}:${version}" 2>&1; then
        echo -e "  ${GREEN}✓ Pushed: ${registry}/${image_name}:${version}${NC}"
    else
        echo -e "  ${RED}✗ Push failed: ${registry}/${image_name}:${version}${NC}"
        return 1
    fi
    
    return 0
}

# Clean local images
clean_images() {
    local services=("$@")
    
    echo -e "${YELLOW}Cleaning local images...${NC}"
    
    for service in "${services[@]}"; do
        local image_name="opendesk-edu/${service}"
        
        # Remove all tags for this service
        docker images --format "{{.ID}}" | xargs -I {} docker rmi -f {} 2>/dev/null || true
        
        echo -e "  Cleaned: ${image_name}"
    done
    
    echo -e "${GREEN}✓ Cleaned local images${NC}"
}

# Main function
main() {
    local services_arg=""
    local custom_registry=""
    local custom_tag="latest"
    local parallel=1
    local force=false
    local dry_run=false
    local clean=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --registry)
                custom_registry="$2"
                shift 2
                ;;
            --services)
                services_arg="$2"
                shift 2
                ;;
            --tag)
                custom_tag="$2"
                shift 2
                ;;
            --parallel)
                parallel="$2"
                shift 2
                ;;
            --force)
                force=true
                shift
                ;;
            --dry-run)
                dry_run=true
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
    
    # Set registry
    if [ -n "$custom_registry" ]; then
        TARGET_REGISTRY="$custom_registry"
    fi
    
    cd "$PROJECT_ROOT"
    
    # Create directories
    mkdir -p "$LOG_DIR" "$OUTPUT_DIR"
    
    # Get services to push
    local services=()
    if [ -n "$services_arg" ]; then
        # Split comma-separated services
        IFS=',' read -ra services <<< "$services_arg"
    else
        # Get all services from docker/services
        local all_services=($(get_all_services | tr ',' '\n'))
        services=("${all_services[@]}")
    fi
    
    if [ ${#services[@]} -eq 0 ]; then
        echo -e "${RED}Error: No services found to push${NC}"
        usage
        exit 1
    fi
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}container.gov.de Image Push Utility${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Registry: $TARGET_REGISTRY${NC}"
    echo -e "${BLUE}Tag: $custom_tag${NC}"
    echo -e "${BLUE}Services: ${#services[@]}${NC}"
    echo -e "${BLUE}Parallel: $parallel${NC}"
    [ "$dry_run" = "true" ] && echo -e "${YELLOW}Dry run mode enabled${NC}"
    [ "$force" = "true" ] && echo -e "${YELLOW}Force push enabled${NC}"
    [ "$clean" = "true" ] && echo -e "${YELLOW}Clean mode enabled${NC}"
    echo ""
    
    # Clean if requested
    if [ "$clean" = "true" ]; then
        clean_images "${services[@]}"
        echo ""
    fi
    
    # Check registry login
    if [ "$dry_run" != "true" ]; then
        if ! docker info > /dev/null 2>&1; then
            echo -e "${RED}Error: Docker daemon is not running${NC}"
            exit 1
        fi
        
        # Extract registry host for login check
        local registry_host=$(echo "$TARGET_REGISTRY" | cut -d'/' -f1 | cut -d':' -f1)
        local registry_port=$(echo "$TARGET_REGISTRY" | cut -d'/' -f1 | cut -d':' -f2)
        
        if [ -n "$registry_port" ] && [ "$registry_port" != "443" ] && [ "$registry_port" != "80" ]; then
            registry_host="${registry_host}:${registry_port}"
        fi
        
        # For localhost, skip login check
        if [[ "$registry_host" != "localhost" ]] && [[ "$registry_host" != "127.0.0.1" ]] && [[ ! "$registry_host" =~ ^10\. ]] && [[ ! "$registry_host" =~ ^192\.168\. ]] && [[ ! "$registry_host" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]]; then
            echo -e "${BLUE}Checking registry login for $registry_host...${NC}"
            if ! docker login "$registry_host" > /dev/null 2>&1; then
                echo -e "${RED}Error: Not logged in to $registry_host${NC}"
                echo -e "Run: docker login $registry_host"
                exit 1
            fi
            echo -e "${GREEN}✓ Logged in to $registry_host${NC}"
        fi
    fi
    echo ""
    
    # Push images
    if [ "$parallel" -gt 1 ] && [ "$parallel" -le ${#services[@]} ]; then
        # Parallel push using xargs
        echo -e "${BLUE}Pushing ${#services[@]} images with ${parallel} parallel jobs...${NC}"
        
        seq 0 $(( ${#services[@]} - 1 )) | xargs -P "$parallel" -I {} sh -c '
            svc="${services[{}]}"
            '"$0'" --services "\$svc" --registry "$TARGET_REGISTRY" --tag "$custom_tag" --force $force --dry-run $dry_run
        ' _ "$0"
    else
        # Sequential push
        local success_count=0
        local failure_count=0
        
        for service in "${services[@]}"; do
            echo ""
            if push_image "$service" "$TARGET_REGISTRY" "$custom_tag" "$force" "$dry_run"; then
                ((success_count++))
            else
                ((failure_count++))
            fi
        done
        
        echo ""
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}Push Summary${NC}"
        echo -e "========================================${NC}"
        echo -e "${GREEN}Successful: $success_count${NC}"
        echo -e "${RED}Failed:      $failure_count${NC}"
        echo -e "${BLUE}Total:       $((success_count + failure_count))${NC}"
        
        if [ "$failure_count" -gt 0 ]; then
            echo -e "${RED}⚠ Some pushes failed${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}✓ All images pushed successfully!${NC}"
        
        # Show next steps
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo -e "  1. Verify images: docker pull $TARGET_REGISTRY/SERVICE:latest"
        echo -e "  2. Run compliance check: ./scripts/container-gov-de/check-compliance.sh --all"
        echo -e "  3. Deploy to Kubernetes: kubectl apply -f k8s/services/SERVICE.nix"
    fi
}

# Run main with all arguments
main "$@"

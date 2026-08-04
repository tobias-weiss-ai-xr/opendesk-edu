#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 container.gov.de Contributors
# Push All container.gov.de Images to Registry
# Usage: ./push-all.sh [OPTIONS]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"
DOCKER_SERVICES_DIR="$PROJECT_ROOT/docker/services"
LOG_DIR="$SCRIPT_DIR/../migrate-upstream/logs"

# Default registry
TARGET_REGISTRY="opencode.de/opendesk-edu"

# Colors (simple format without escape issues)
BLUE=">> "
GREEN="OK: "
YELLOW="WARN: "
RED="ERROR: "
NC=""

# Usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Push all container.gov.de compliant images to a registry

Options:
  --services SERVICES    Comma-separated list of services (default: all in docker/services)
  --registry REGISTRY    Target registry (default: $TARGET_REGISTRY)
  --tag TAG              Tag to push (default: latest)
  --force                Force push (overwrite existing)
  --compress             Compress images during push
  --sign                 Sign images with Cosign after pushing
  --dry-run              Show what would be pushed without actually pushing
  --help                 Show this help message

Examples:
  $0                             # Push all images
  $0 --services nginx,redis       # Push only nginx and redis
  $0 --registry local:5000       # Push to local registry
  $0 --dry-run                   # Show what would be pushed
  $0 --force --compress          # Force push with compression

container.gov.de Compliance:
  BG-6: SBOM Generation - Images include SPDX/CycloneDX documentation
  BG-7: Image Signing - Use --sign to enable Cosign signing
  BG-8: Vulnerability Scanning - Images should be scanned before pushing
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

# Push a single image
push_image() {
    local service="$1"
    local registry="$2"
    local tag="$3"
    local force="$4"
    local compress="$5"
    local dry_run="$6"
    local sign_image="$7"
    local keys_dir="$8"
    
    local version=$(get_image_version "$service")
    local image_name="opendesk-edu/${service}"
    local image_ref="${registry}/${image_name}:${tag}"
    local version_ref="${registry}/${image_name}:${version}"
    
    if [ "$dry_run" = "true" ]; then
        echo "[$YELLOW]DRY RUN] Would push: ${image_ref}"
        if [ "$version" != "latest" ] && [ "$tag" = "latest" ]; then
            echo "[$YELLOW]DRY RUN] Would push: ${version_ref}"
        fi
        return 0
    fi
    
    echo "[$BLUE]Pushing: ${service} (${image_ref})"
    
    local log_file="$LOG_DIR/${service}-push-$(date +%Y%m%d-%H%M%S).log"
    mkdir -p "$(dirname "$log_file")"
    
    # Build push command
    local push_cmd="docker push ${image_ref}"
    
    if [ "$compress" = "true" ]; then
        push_cmd="docker push --compress ${image_ref}"
    fi
    
    # Execute push
    if eval "$push_cmd > $log_file 2>&1"; then
        echo "[$GREEN]Pushed: ${image_ref}"
        
        # Also push version tag if different
        if [ "$version" != "latest" ] && [ "$tag" = "latest" ]; then
            if docker push "$version_ref" >> "$log_file" 2>&1; then
                echo "[$GREEN]Pushed: ${version_ref}"
            fi
        fi
    else
        echo "[$RED]Failed to push: ${image_ref}"
        return 1
    fi
    
    # Sign the image if requested
    if [ "$sign_image" = "true" ]; then
        sign_single_image "$service" "$registry" "$tag" "$keys_dir"
    fi
    
    return 0
}

# Sign a single image
sign_single_image() {
    local service="$1"
    local registry="$2"
    local tag="$3"
    local keys_dir="$4"
    
    local version=$(get_image_version "$service")
    local image_name="opendesk-edu/${service}"
    local image_ref="${registry}/${image_name}:${tag}"
    local private_key="$keys_dir/cosign-key.key"
    local public_key="$keys_dir/cosign-key.pub"
    
    if [ ! -f "$private_key" ] || [ ! -f "$public_key" ]; then
        echo "[$YELLOW]Cosign keys not found in $keys_dir, skipping signing for $service"
        return 0
    fi
    
    echo "[$BLUE]Signing: $image_ref"
    
    if cosign sign --key "$private_key" "$image_ref" 2>&1; then
        echo "[$GREEN]Signed: $image_ref"
        
        # Sign version tag if different
        if [ "$version" != "latest" ] && [ "$tag" = "latest" ]; then
            local version_ref="${registry}/${image_name}:${version}"
            cosign sign --key "$private_key" "$version_ref" 2>&1
        fi
    else
        echo "[$RED]Failed to sign: $image_ref"
        return 1
    fi
    
    return 0
}

# Main function
main() {
    local services_arg=""
    local custom_registry="$TARGET_REGISTRY"
    local custom_tag="latest"
    local force=false
    local compress=false
    local dry_run=false
    local sign=false
    local keys_dir="$SCRIPT_DIR/../migrate-upstream/keys"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --services)
                services_arg="$2"
                shift 2
                ;;
            --registry)
                custom_registry="$2"
                shift 2
                ;;
            --tag)
                custom_tag="$2"
                shift 2
                ;;
            --force)
                force=true
                shift
                ;;
            --compress)
                compress=true
                shift
                ;;
            --sign)
                sign=true
                shift
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
                echo "$RED Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                echo "$RED Unexpected argument: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    cd "$PROJECT_ROOT"
    
    # Create directories
    mkdir -p "$LOG_DIR" "$keys_dir"
    
    # Check for docker
    if ! docker info > /dev/null 2>&1; then
        echo "$RED Error: Docker daemon is not running"
        exit 1
    fi
    
    # Get services
    local services=()
    if [ -n "$services_arg" ]; then
        IFS=',' read -ra services <<< "$services_arg"
    else
        local all_services=($(get_all_services | tr ',' '\n'))
        services=("${all_services[@]}")
    fi
    
    if [ ${#services[@]} -eq 0 ]; then
        echo "$RED Error: No services found"
        usage
        exit 1
    fi
    
    echo ""
    echo "============================================================"
    echo "  container.gov.de Image Push Utility"
    echo "============================================================"
    echo "Registry: $custom_registry"
    echo "Tag: $custom_tag"
    echo "Services: ${#services[@]}"
    [ "$dry_run" = "true" ] && echo "Mode: DRY RUN"
    [ "$force" = "true" ] && echo "Force: YES"
    [ "$compress" = "true" ] && echo "Compress: YES"
    [ "$sign" = "true" ] && echo "Sign: YES"
    echo ""
    
    # Push images sequentially
    local success_count=0
    local failure_count=0
    
    for service in "${services[@]}"; do
        echo ""
        if push_image "$service" "$custom_registry" "$custom_tag" "$force" "$compress" "$dry_run" "$sign" "$keys_dir"; then
            ((success_count++))
        else
            ((failure_count++))
        fi
    done
    
    echo ""
    echo "============================================================"
    echo "  Push Summary"
    echo "============================================================"
    echo "Successful: $success_count"
    echo "Failed: $failure_count"
    echo "Total: $((success_count + failure_count))"
    
    if [ "$failure_count" -gt 0 ]; then
        echo "$RED Some pushes failed"
        exit 1
    fi
    
    echo "$GREEN All images pushed successfully!"
    
    # Show next steps
    echo ""
    echo "Next steps:"
    echo "  1. Verify images in registry: docker pull ${custom_registry}/opendesk-edu/SERVICE:TAG"
    echo "  2. Check logs in: $LOG_DIR"
    echo "  3. Deploy with: ./deploy.sh --registry $custom_registry"
}

# Run main with all arguments
main "$@"

#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 container.gov.de Contributors
# Sign All container.gov.de Images with Cosign
# Usage: ./sign-all.sh [OPTIONS]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"
LOG_DIR="$SCRIPT_DIR/../migrate-upstream/logs"
OUTPUT_DIR="$SCRIPT_DIR/../migrate-upstream/output"

# Default keys directory
DEFAULT_KEYS_DIR="$SCRIPT_DIR/../migrate-upstream/keys"

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

Sign all container.gov.de compliant images with Cosign

Options:
  --services SERVICES    Comma-separated list of services (default: all in docker/services)
  --registry REGISTRY    Registry to pull/push images from (default: opencode.de/opendesk-edu)
  --keys-dir DIR         Directory for Cosign keys (default: $DEFAULT_KEYS_DIR)
  --key-name NAME        Base name for Cosign keys (default: cosign-key)
  --tag TAG              Tag to sign (default: latest + version)
  --parallel N           Number of parallel signing jobs (default: 1)
  --force                Force re-sign (overwrite existing signatures)
  --dry-run              Show what would be signed without actually signing
  --generate-keys        Generate new Cosign key pair
  --verify               Verify existing signatures
  --help                 Show this help message

Examples:
  $0                             # Sign all images with existing keys
  $0 --generate-keys             # Generate keys and sign all images
  $0 --services nginx,redis       # Sign only nginx and redis
  $0 --registry local:5000       # Sign images from local registry
  $0 --parallel 4                # Sign 4 images in parallel
  $0 --verify                    # Verify signatures instead of signing
  $0 --dry-run                   # Show what would be signed

container.gov.de Compliance:
  BG-7: Signieren von Images (Image Signing) requires:
  - All images must be signed with a private key
  - Signatures must be verifiable
  - Public keys must be accessible to consumers

Requirements:
  - cosign CLI installed
  - Docker CLI installed (for pulling images)
  - Private key for signing (or --generate-keys to create one)
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

# Generate Cosign key pair
generate_cosign_keys() {
    local keys_dir="$1"
    local key_name="$2"
    
    mkdir -p "$keys_dir"
    
    local private_key="$keys_dir/${key_name}.key"
    local public_key="$keys_dir/${key_name}.pub"
    
    if [ -f "$private_key" ] && [ -f "$public_key" ]; then
        echo -e "${YELLOW}⚠ Cosign keys already exist in $keys_dir${NC}"
        echo -e "  Private key: $private_key"
        echo -e "  Public key: $public_key"
        return 0
    fi
    
    echo -e "${BLUE}Generating Cosign key pair...${NC}"
    
    if cosign generate-key-pair "$keys_dir/${key_name}" 2>&1; then
        echo -e "${GREEN}✓ Cosign key pair generated:${NC}"
        echo -e "  Private key: $private_key"
        echo -e "  Public key: $public_key"
        
        # Set appropriate permissions
        chmod 600 "$private_key"
        chmod 644 "$public_key"
        
        return 0
    else
        echo -e "${RED}✗ Failed to generate Cosign keys${NC}"
        return 1
    fi
}

# Sign a single image
sign_image() {
    local service="$1"
    local registry="$2"
    local tag="$3"
    local keys_dir="$4"
    local key_name="$5"
    local force="$6"
    local dry_run="$7"
    
    local version=$(get_image_version "$service")
    local image_name="opendesk-edu/${service}"
    local image_ref="${registry}/${image_name}:${tag}"
    
    if [ "$dry_run" = "true" ]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would sign: ${CYAN}${image_ref}${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Signing: ${CYAN}${service}${NC} (${image_ref})"
    
    local private_key="$keys_dir/${key_name}.key"
    local public_key="$keys_dir/${key_name}.pub"
    
    # Check if keys exist
    if [ ! -f "$private_key" ]; then
        echo -e "${RED}✗ Private key not found: ${private_key}${NC}"
        return 1
    fi
    
    if [ ! -f "$public_key" ]; then
        echo -e "${RED}✗ Public key not found: ${public_key}${NC}"
        return 1
    fi
    
    # Check if already signed
    if [ "$force" != "true" ]; then
        if cosign verify --key "$public_key" "$image_ref" 2>&1 | grep -q "control plane"; then
            echo -e "  ${YELLOW}⚠ Already signed, skipping (use --force to re-sign)${NC}"
            return 0
        fi
    fi
    
    # Sign the image
    if cosign sign --key "$private_key" "$image_ref" 2>&1; then
        echo -e "  ${GREEN}✓ Signed: ${image_ref}${NC}"
        
        # Also sign version tag if different from latest
        if [ "$tag" = "latest" ] && [ "$version" != "latest" ]; then
            local version_ref="${registry}/${image_name}:${version}"
            if cosign sign --key "$private_key" "$version_ref" 2>&1; then
                echo -e "  ${GREEN}✓ Signed: ${version_ref}${NC}"
            else
                echo -e "  ${RED}✗ Failed to sign version tag: ${version_ref}${NC}"
                return 1
            fi
        fi
        
        return 0
    else
        echo -e "  ${RED}✗ Failed to sign: ${image_ref}${NC}"
        return 1
    fi
}

# Verify a single image's signature
verify_image() {
    local service="$1"
    local registry="$2"
    local tag="$3"
    local keys_dir="$4"
    local key_name="$5"
    
    local version=$(get_image_version "$service")
    local image_name="opendesk-edu/${service}"
    local image_ref="${registry}/${image_name}:${tag}"
    
    echo -e "${BLUE}Verifying: ${CYAN}${service}${NC} (${image_ref})"
    
    local public_key="$keys_dir/${key_name}.pub"
    
    # Check if public key exists
    if [ ! -f "$public_key" ]; then
        echo -e "${RED}✗ Public key not found: ${public_key}${NC}"
        return 1
    fi
    
    # Verify the signature
    if cosign verify --key "$public_key" "$image_ref" 2>&1; then
        echo -e "  ${GREEN}✓ Verified: ${image_ref}${NC}"
        
        # Also verify version tag if different from latest
        if [ "$tag" = "latest" ] && [ "$version" != "latest" ]; then
            local version_ref="${registry}/${image_name}:${version}"
            if cosign verify --key "$public_key" "$version_ref" 2>&1; then
                echo -e "  ${GREEN}✓ Verified: ${version_ref}${NC}"
            else
                echo -e "  ${RED}✗ Verification failed for version tag: ${version_ref}${NC}"
                return 1
            fi
        fi
        
        return 0
    else
        echo -e "  ${RED}✗ Verification failed: ${image_ref}${NC}"
        return 1
    fi
}

# Main function
main() {
    local services_arg=""
    local custom_registry="opencode.de/opendesk-edu"
    local keys_dir="$DEFAULT_KEYS_DIR"
    local key_name="cosign-key"
    local custom_tag="latest"
    local parallel=1
    local force=false
    local dry_run=false
    local generate_keys=false
    local verify_only=false
    
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
            --keys-dir)
                keys_dir="$2"
                shift 2
                ;;
            --key-name)
                key_name="$2"
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
            --generate-keys)
                generate_keys=true
                shift
                ;;
            --verify)
                verify_only=true
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
    
    cd "$PROJECT_ROOT"
    
    # Create directories
    mkdir -p "$LOG_DIR" "$OUTPUT_DIR" "$keys_dir"
    
    # Check for cosign
    if ! command -v cosign &> /dev/null; then
        echo -e "${RED}Error: cosign is not installed${NC}"
        echo -e "Install with Nix: nix-env -iA nixpkgs.cosign"
        exit 1
    fi
    
    # Check for Docker (for pulling images)
    if [ "$dry_run" != "true" ] && ! docker info > /dev/null 2>&1; then
        echo -e "${RED}Error: Docker daemon is not running${NC}"
        exit 1
    fi
    
    # Generate keys if requested
    if [ "$generate_keys" = "true" ]; then
        if ! generate_cosign_keys "$keys_dir" "$key_name"; then
            exit 1
        fi
    fi
    
    # Check if keys exist
    local private_key="$keys_dir/${key_name}.key"
    local public_key="$keys_dir/${key_name}.pub"
    
    if [ ! -f "$private_key" ] || [ ! -f "$public_key" ]; then
        echo -e "${RED}Error: Cosign keys not found in $keys_dir${NC}"
        echo -e "  Expected:"
        echo -e "    - $private_key"
        echo -e "    - $public_key"
        echo -e "Use --generate-keys to create new keys"
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
        echo -e "${RED}Error: No services found${NC}"
        usage
        exit 1
    fi
    
    # Determine action
    local action="sign"
    if [ "$verify_only" = "true" ]; then
        action="verify"
    fi
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}container.gov.de Image Signing Utility${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Action: ${action}${NC}"
    echo -e "${BLUE}Registry: $custom_registry${NC}"
    echo -e "${BLUE}Keys directory: $keys_dir${NC}"
    echo -e "${BLUE}Key name: $key_name${NC}"
    echo -e "${BLUE}Tag: $custom_tag${NC}"
    echo -e "${BLUE}Services: ${#services[@]}${NC}"
    echo -e "${BLUE}Parallel jobs: $parallel${NC}"
    [ "$dry_run" = "true" ] && echo -e "${YELLOW}Dry run mode enabled${NC}"
    [ "$force" = "true" ] && echo -e "${YELLOW}Force re-sign enabled${NC}"
    echo ""
    
    # Sign/verify images
    if [ "$parallel" -gt 1 ] && [ "$parallel" -le ${#services[@]} ]; then
        # Parallel signing
        echo -e "${BLUE}Running ${parallel} parallel ${action} jobs...${NC}"
        
        seq 0 $(( ${#services[@]} - 1 )) | xargs -P "$parallel" -I {} sh -c '
            svc="${services[{}]}"
            '"$0'" --services "\$svc" --registry "$custom_registry" --keys-dir "$keys_dir" --key-name "$key_name" --tag "$custom_tag" --force $force --dry-run $dry_run --verify $verify_only
        ' _ "$0"
    else
        # Sequential signing
        local success_count=0
        local failure_count=0
        
        if [ "$verify_only" = "true" ]; then
            for service in "${services[@]}"; do
                echo ""
                if verify_image "$service" "$custom_registry" "$custom_tag" "$keys_dir" "$key_name"; then
                    ((success_count++))
                else
                    ((failure_count++))
                fi
            done
        else
            for service in "${services[@]}"; do
                echo ""
                if sign_image "$service" "$custom_registry" "$custom_tag" "$keys_dir" "$key_name" "$force" "$dry_run"; then
                    ((success_count++))
                else
                    ((failure_count++))
                fi
            done
        fi
        
        echo ""
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}Signing Summary${NC}"
        echo -e "========================================${NC}"
        echo -e "${GREEN}Successful: $success_count${NC}"
        echo -e "${RED}Failed:      $failure_count${NC}"
        echo -e "${BLUE}Total:       $((success_count + failure_count))${NC}"
        
        if [ "$failure_count" -gt 0 ]; then
            echo -e "${RED}⚠ Some ${action}s failed${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}✓ All images ${action}d successfully!${NC}"
        
        # Show next steps
        echo ""
        if [ "$verify_only" = "true" ]; then
            echo -e "${BLUE}Next steps:${NC}"
            echo -e "  1. Review verification results"
            echo -e "  2. Deploy signed images with confidence"
        else
            echo -e "${BLUE}Next steps:${NC}"
            echo -e "  1. Push signed images: ./scripts/container-gov-de/push-all.sh --registry $custom_registry"
            echo -e "  2. Verify signatures: $0 --verify --registry $custom_registry"
            echo -e "  3. Configure Kubernetes to verify signatures"
        fi
    fi
}

# Run main with all arguments
main "$@"

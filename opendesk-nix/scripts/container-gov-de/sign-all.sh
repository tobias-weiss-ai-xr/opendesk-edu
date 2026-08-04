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

# Default keys directory
DEFAULT_KEYS_DIR="$SCRIPT_DIR/../migrate-upstream/keys"

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
        echo "  Cosign keys already exist in $keys_dir"
        return 0
    fi

    echo "  Generating Cosign key pair..."
    if cosign generate-key-pair "$keys_dir/${key_name}" > /dev/null 2>&1; then
        chmod 600 "$private_key"
        chmod 644 "$public_key"
        echo "  Cosign key pair generated"
        return 0
    else
        echo "  Failed to generate Cosign keys"
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
        echo "  [DRY RUN] Would sign: ${image_ref}"
        return 0
    fi

    echo "  Signing: ${service} (${image_ref})"
    local private_key="$keys_dir/${key_name}.key"
    local public_key="$keys_dir/${key_name}.pub"

    if [ ! -f "$private_key" ]; then
        echo "  Private key not found: ${private_key}"
        return 1
    fi

    if [ ! -f "$public_key" ]; then
        echo "  Public key not found: ${public_key}"
        return 1
    fi

    if [ "$force" != "true" ]; then
        if cosign verify --key "$public_key" "$image_ref" > /dev/null 2>&1; then
            echo "  Already signed, skipping"
            return 0
        fi
    fi

    if cosign sign --key "$private_key" "$image_ref" > /dev/null 2>&1; then
        echo "  Signed: ${image_ref}"
        if [ "$version" != "latest" ] && [ "$tag" = "latest" ]; then
            local version_ref="${registry}/${image_name}:${version}"
            cosign sign --key "$private_key" "$version_ref" > /dev/null 2>&1
        fi
        return 0
    else
        echo "  Failed to sign: ${image_ref}"
        return 1
    fi
}

# Verify a single image
verify_image() {
    local service="$1"
    local registry="$2"
    local tag="$3"
    local keys_dir="$4"
    local key_name="$5"

    local version=$(get_image_version "$service")
    local image_name="opendesk-edu/${service}"
    local image_ref="${registry}/${image_name}:${tag}"

    echo "  Verifying: ${service} (${image_ref})"
    local public_key="$keys_dir/${key_name}.pub"

    if [ ! -f "$public_key" ]; then
        echo "  Public key not found: ${public_key}"
        return 1
    fi

    if cosign verify --key "$public_key" "$image_ref" > /dev/null 2>&1; then
        echo "  Verified: ${image_ref}"
        if [ "$version" != "latest" ] && [ "$tag" = "latest" ]; then
            local version_ref="${registry}/${image_name}:${version}"
            cosign verify --key "$public_key" "$version_ref" > /dev/null 2>&1
        fi
        return 0
    else
        echo "  Verification failed: ${image_ref}"
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
    local force=false
    local dry_run=false
    local generate_keys=false
    local verify_only=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --services) services_arg="$2"; shift 2 ;;
            --registry) custom_registry="$2"; shift 2 ;;
            --keys-dir) keys_dir="$2"; shift 2 ;;
            --key-name) key_name="$2"; shift 2 ;;
            --tag) custom_tag="$2"; shift 2 ;;
            --force) force=true; shift ;;
            --dry-run) dry_run=true; shift ;;
            --generate-keys) generate_keys=true; shift ;;
            --verify) verify_only=true; shift ;;
            --help|-h) usage; exit 0 ;;
            -*) echo "Unknown option: $1"; usage; exit 1 ;;
            *) echo "Unexpected argument: $1"; usage; exit 1 ;;
        esac
    done

    cd "$PROJECT_ROOT"
    mkdir -p "$LOG_DIR" "$keys_dir"

    # Check for cosign
    if ! command -v cosign > /dev/null; then
        echo "Error: cosign is not installed"
        exit 1
    fi

    # Generate keys if requested
    if [ "$generate_keys" = "true" ]; then
        if ! generate_cosign_keys "$keys_dir" "$key_name"; then
            exit 1
        fi
    fi

    local private_key="$keys_dir/${key_name}.key"
    local public_key="$keys_dir/${key_name}.pub"

    if [ ! -f "$private_key" ] || [ ! -f "$public_key" ]; then
        echo "Error: Cosign keys not found in $keys_dir"
        echo "Use --generate-keys to create new keys"
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
        echo "Error: No services found"
        exit 1
    fi

    echo "========================================"
    echo " container.gov.de Image Signing Utility"
    echo "========================================"
    echo "Registry: $custom_registry"
    echo "Services: ${#services[@]}"
    echo ""

    local success_count=0
    local failure_count=0

    if [ "$verify_only" = "true" ]; then
        for service in "${services[@]}"; do
            if verify_image "$service" "$custom_registry" "$custom_tag" "$keys_dir" "$key_name"; then
                ((success_count++))
            else
                ((failure_count++))
            fi
        done
    else
        for service in "${services[@]}"; do
            if sign_image "$service" "$custom_registry" "$custom_tag" "$keys_dir" "$key_name" "$force" "$dry_run"; then
                ((success_count++))
            else
                ((failure_count++))
            fi
        done
    fi

    echo ""
    echo "========================================"
    echo " Summary"
    echo "========================================"
    echo "Successful: $success_count"
    echo "Failed: $failure_count"

    if [ "$failure_count" -gt 0 ]; then
        exit 1
    fi
}

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Sign or verify container.gov.de compliant images with Cosign

Options:
  --services SERVICES    Comma-separated list of services
  --registry REGISTRY    registry to pull/push from
  --keys-dir DIR         Directory for Cosign keys
  --key-name NAME        Base name for Cosign keys
  --tag TAG              Tag to sign
  --force                Force re-sign
  --dry-run              Show what would be done
  --generate-keys        Generate new Cosign key pair
  --verify               Verify instead of signing
  --help                 Show this help message
EOF
}

main "$@"

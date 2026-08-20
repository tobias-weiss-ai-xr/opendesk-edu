#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Finalize NixOS Container Migration
After running batch migrations, this script cleans up and finalizes the changes.

Usage:
    ./finalize-migration.sh <service1> [service2] [service3]...
    ./finalize-migration.sh --all
"""

set -euo pipefail

SERVICES_DIR="opendesk-nix/docker/services"
OVERLAYS_FILE="opendesk-nix/overlays/opendesk.nix"
SERVICES_CATALOG="opendesk-nix/lib/nixos/services.nix"
FLAKE_FILE="opendesk-nix/flake.nix"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Finalizing NixOS Container Migration"
echo "=========================================="
echo ""

# Check arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <service1> [service2] ..."
    echo "       $0 --all"
    exit 1
fi

# Get list of services to finalize
if [ "$1" = "--all" ]; then
    echo "[INFO] Finalizing ALL migrated services..."
    SERVICES=$(find "$SERVICES_DIR" -type d -name "nixos" | while read dir; do
        basename $(dirname "$dir")
    done)
else
    echo "[INFO] Finalizing specific services: $*"
    SERVICES="$@"
fi

# Track results
TOTAL=0
SUCCESS=0
FAIL=0

for SERVICE in $SERVICES; do
    TOTAL=$((TOTAL + 1))
    echo ""
    echo "[INFO] Processing: $SERVICE"
    
    SERVICE_DIR="$SERVICES_DIR/$SERVICE"
    NIXOS_DIR="$SERVICE_DIR/nixos"
    
    # Check if NixOS directory exists
    if [ ! -d "$NIXOS_DIR" ]; then
        echo "[WARN] $SERVICE: No NixOS directory found, skipping"
        FAIL=$((FAIL + 1))
        continue
    fi
    
    # Step 1: Clean up duplicate secrets.yaml in root
    ROOT_SECRETS="$SERVICE_DIR/secrets.yaml"
    if [ -f "$ROOT_SECRETS" ]; then
        if [ -f "$NIXOS_DIR/secrets.yaml" ]; then
            echo "  [FIX] Removing duplicate secrets.yaml from root"
            rm -f "$ROOT_SECRETS"
        fi
    fi
    
    # Step 2: Clean up Dockerfile.nix symlink if it exists
    DOCKERFILE_LINK="$SERVICE_DIR/Dockerfile.nix"
    if [ -L "$DOCKERFILE_LINK" ]; then
        echo "  [FIX] Removing Dockerfile.nix symlink"
        rm -f "$DOCKERFILE_LINK"
    fi
    
    # Step 3: Ensure README.md is in nixos directory, not root
    ROOT_README="$SERVICE_DIR/README.md"
    if [ -f "$ROOT_README" ] && [ ! -f "$NIXOS_DIR/README.md" ]; then
        echo "  [FIX] Moving README.md to nixos directory"
        mv "$ROOT_README" "$NIXOS_DIR/README.md"
    elif [ -f "$ROOT_README" ] && [ -f "$NIXOS_DIR/README.md" ]; then
        echo "  [FIX] Removing duplicate README.md from root"
        rm -f "$ROOT_README"
    fi
    
    # Step 4: Validate required files exist
    REQUIRED_FILES=("configuration.nix" "default.nix" "secrets.nix" "README.md")
    ALL_PRESENT=true
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$NIXOS_DIR/$file" ]; then
            echo "  [ERROR] Missing file: $file"
            ALL_PRESENT=false
        fi
    done
    
    if [ "$ALL_PRESENT" = true ]; then
        echo "  [OK] All required files present"
    else
        FAIL=$((FAIL + 1))
        continue
    fi
    
    # Step 5: Check service catalog entry
    if ! grep -q "$SERVICE = mkService" "$SERVICES_CATALOG"; then
        echo "  [WARN] No service catalog entry for $SERVICE"
        echo "  Run: ./migrate-service.sh $SERVICE to add it"
    else
        echo "  [OK] Service catalog entry exists"
    fi
    
    # Step 6: Check overlays entry
    if ! grep -q "^    $SERVICE = super" "$OVERLAYS_FILE"; then
        echo "  [WARN] No overlays entry for $SERVICE"
        echo "  Run: ./migrate-service.sh $SERVICE to add it"
    else
        echo "  [OK] Overlays entry exists"
    fi
    
    # Step 7: Check flake.nix entry
    if ! grep -q "${SERVICE}-nixos" "$FLAKE_FILE"; then
        echo "  [WARN] No flake.nix entry for ${SERVICE}-nixos"
        echo "  Run: ./migrate-service.sh $SERVICE to add it"
    else
        echo "  [OK] Flake.nix entry exists"
    fi
    
    # Step 8: Validate configuration.nix syntax
    if nix-instantiate --parse-only "$NIXOS_DIR/configuration.nix" 2>/dev/null; then
        echo "  [OK] configuration.nix syntax valid"
    else
        echo "  [ERROR] configuration.nix has syntax errors"
        FAIL=$((FAIL + 1))
        continue
    fi
    
    # Step 9: Validate default.nix syntax
    if nix-instantiate --parse-only "$NIXOS_DIR/default.nix" 2>/dev/null; then
        echo "  [OK] default.nix syntax valid"
    else
        echo "  [ERROR] default.nix has syntax errors"
        FAIL=$((FAIL + 1))
        continue
    fi
    
    SUCCESS=$((SUCCESS + 1))
    echo "  [SUCCESS] $SERVICE finalized"
    
done

echo ""
echo "=========================================="
echo "Finalization Summary"
echo "=========================================="
echo "Total processed: $TOTAL"
echo "Successful: $SUCCESS"
echo "Failed: $FAIL"
echo ""

if [ $FAIL -gt 0 ]; then
    echo "[WARN] Some services failed finalization"
    echo "Check the output above for errors"
    exit 1
else
    echo "[OK] All services finalized successfully!"
fi

echo ""
echo "Next steps:"
echo "  1. Run: cd opendesk-nix && nix build .#all-nixos-images"
echo "  2. Test each container: docker load < result && docker run -d ..."
echo "  3. Verify OCI labels: docker inspect <image> | jq '.[0].Config.Labels'"
echo "  4. Run health checks: docker inspect --format='{{json .State.Health}}' <container>"
echo ""

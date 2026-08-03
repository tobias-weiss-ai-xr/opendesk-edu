#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Scan existing services and identify which need NixOS container migration
"""

set -euo pipefail

SERVICES_DIR="opendesk-nix/docker/services"
 outbreak=""

echo "=== Scanning existing services ==="
echo ""

echo "Services already migrated to NixOS:"
for service_dir in "$SERVICES_DIR"/*/nixos; do
    if [ -d "$service_dir" ]; then
        service_name=$(basename $(dirname "$service_dir"))
        echo "  ✅ $service_name"
    fi
done

echo ""
echo "Services with Dockerfile but no NixOS config:"
for dockerfile in "$SERVICES_DIR"/*/Dockerfile; do
    if [ -f "$dockerfile" ]; then
        service_dir=$(dirname "$dockerfile")
        service_name=$(basename "$service_dir")
        if [ ! -d "$service_dir/nixos" ]; then
            echo "  ⚪ $service_name (Dockerfile: $dockerfile)"
        fi
    fi
done

echo ""
echo "All services with Dockerfiles:"
find "$SERVICES_DIR" -name "Dockerfile" -type f | while read f; do
    echo "  - $(dirname "$f")"
done

echo ""
echo "Services in root docker directory:"
find opendesk-nix/docker -maxdepth 2 -name "Dockerfile" -type f | while read f; do
    if [[ "$f" != *"services/"* ]]; then
        echo "  - $(dirname "$f")"
    fi
done

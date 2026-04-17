#!/bin/bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0

set -e

echo "=== Cleaning up temporary development files ==="

# Pattern files that are definitely temporary
echo "Cleaning up tmp_ files..."
for f in tmp_*.py tmp_*.sh; do
    if [ -f "$f" ]; then
        echo "  Removing: $f"
        rm "$f"
    fi
done

# Other temporary files identified during debugging
TEMP_FILES=(
    "minimal-helmfile-core-v2.yaml.gotmpl"
    "minimal-helmfile-core.yaml.gotmpl"
    "minimal-helmfile-sogo.yaml.gotmpl"
    "create_applications.ldif"
    "create_od_applications.ldif"
    "create_user.sql"
    "fix-portal-corrected.sh"
    "sogo-custom-entrypoint.sh"
    "sogo-supervisord-custom.conf"
    "helmfile/charts/sogo/templates/entrypoint-configmap.yaml.mod"
    "tmp_ce_ldap_dump.txt"
    "tmp_prod_values.yaml.gotmpl"
)

echo "Cleaning up other temporary files..."
for f in "${TEMP_FILES[@]}"; do
    if [ -f "$f" ]; then
        echo "  Removing: $f"
        rm "$f"
    fi
done

echo ""
echo "=== Cleanup complete ==="
echo ""
echo "Note: .sisyphus/ directory is intentionally gitignored and not cleaned."
#!/bin/bash
# deploy.sh — Deploy openDesk CE + edu overlay
# Usage: ./deploy.sh [environment]
#   environment: edu (default), edu-test, or helmfile -e compatible

set -euo pipefail

ENVIRONMENT="${1:-edu}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Step 1: Deploy CE with $ENVIRONMENT overrides ==="
cd helmfile/ce

helmfile -f helmfile.yaml.gotmpl \
  --values "../environments/$ENVIRONMENT/ce-overrides.yaml" \
  --values "../environments/$ENVIRONMENT/secrets.yaml" \
  --values "../environments/$ENVIRONMENT/images.yaml" \
  sync

echo "=== Step 2: Deploy edu-specific apps ==="
cd "$SCRIPT_DIR"

helmfile -f helmfile/edu-helmfile.yaml.gotmpl \
  -e "$ENVIRONMENT" \
  sync

echo "=== Deploy complete ==="

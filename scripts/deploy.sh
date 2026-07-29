#!/bin/bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Deploy openDesk Edu with automatic SOPS secret decryption.
# Decrypts secrets.enc.yaml → secrets.yaml before running helmfile.
#
# Usage: ./scripts/deploy.sh [helmfile-args]
#   ./scripts/deploy.sh sync
#   ./scripts/deploy.sh template --environment edu

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_DIR="$PROJECT_DIR/helmfile/environments/edu"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== openDesk Edu Deploy ===${NC}"
echo ""

# Step 1: Check for SOPS-encrypted secrets
if [ -f "$ENV_DIR/secrets.enc.yaml" ]; then
  echo -e "${YELLOW}🔐 Decrypting secrets.enc.yaml → secrets.yaml${NC}"
  
  if command -v sops &> /dev/null; then
    sops decrypt "$ENV_DIR/secrets.enc.yaml" 2>/dev/null > "$ENV_DIR/secrets.yaml"
    echo -e "${GREEN}   ✅ Decrypted${NC}"
  else
    echo -e "${RED}   ❌ sops not found. Install: https://github.com/getsops/sops${NC}"
    echo "   Falling back to existing secrets.yaml (if any)"
  fi
else
  echo -e "${YELLOW}   ⏭️  No secrets.enc.yaml found, using secrets.yaml as-is${NC}"
fi

# Step 2: Run helmfile
echo ""
echo -e "${GREEN}🚀 Running helmfile $@${NC}"
cd "$PROJECT_DIR"
helmfile --file helmfile.yaml.gotmpl --environment edu --namespace opendesk "$@"

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}✅ Deploy successful${NC}"
else
  echo -e "${RED}❌ Deploy failed (exit code $EXIT_CODE)${NC}"
fi

# Step 3: Clean up decrypted secrets (avoid leaving plaintext on disk)
if [ -f "$ENV_DIR/secrets.enc.yaml" ]; then
  rm -f "$ENV_DIR/secrets.yaml"
  echo -e "${YELLOW}🧹 Decrypted secrets cleaned up${NC}"
fi

exit $EXIT_CODE

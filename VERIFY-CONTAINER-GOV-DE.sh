#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 container.gov.de Contributors
# Verify container.gov.de E2E Implementation
# This script validates that all container.gov.de components are properly installed

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENDESK_NIX="$PROJECT_ROOT/opendesk-nix"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
TOTAL_CHECKS=0

pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((PASS_COUNT++))
}

fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((FAIL_COUNT++))
}

check() {
    local description="$1"
    local command="$2"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -n "  Checking: $description... "
    if eval "$command" > /dev/null 2>&1; then
        pass "$description"
        return 0
    else
        fail "$description"
        return 1
    fi
}

echo ""
echo "============================================================"
echo "  container.gov.de E2E Implementation Verification"
echo "============================================================"
echo ""

# 1. Check Core Files
echo ""
echo "${BLUE}1. Checking Core Infrastructure Files...${NC}"

check "overlays/container-gov-de.nix exists" \
    "test -f $OPENDESK_NIX/overlays/container-gov-de.nix"

check "lib/compliance/container-gov-de.nix exists" \
    "test -f $OPENDESK_NIX/lib/compliance/container-gov-de.nix"

check "lib/ci-cd/container-gov-de.nix exists" \
    "test -f $OPENDESK_NIX/lib/ci-cd/container-gov-de.nix"

check "templates/container-gov-de/default.nix exists" \
    "test -f $OPENDESK_NIX/templates/container-gov-de/default.nix"

check "templates/container-gov-de/nixos-config.nix exists" \
    "test -f $OPENDESK_NIX/templates/container-gov-de/nixos-config.nix"

# 2. Check CLI Scripts
echo ""
echo "${BLUE}2. Checking CLI Scripts...${NC}"

for script in build-all.sh check-compliance.sh push-all.sh scan-all.sh sign-all.sh generate-reports.sh deploy.sh; do
    check "scripts/container-gov-de/$script exists" \
        "test -f $OPENDESK_NIX/scripts/container-gov-de/$script"
    
    check "scripts/container-gov-de/$script is executable" \
        "test -x $OPENDESK_NIX/scripts/container-gov-de/$script"
done

check "scripts/migrate-upstream-images.sh exists" \
    "test -f $OPENDESK_NIX/scripts/migrate-upstream-images.sh"

check "scripts/migrate-upstream-images.sh is executable" \
    "test -x $OPENDESK_NIX/scripts/migrate-upstream-images.sh"

# 3. Check Documentation
echo ""
echo "${BLUE}3. Checking Documentation...${NC}"

check "CONTAINER-GOV-DE.md exists" \
    "test -f $OPENDESK_NIX/CONTAINER-GOV-DE.md"

check "MIGRATION-UPSTREAM-E2E.md exists" \
    "test -f $OPENDESK_NIX/MIGRATION-UPSTREAM-E2E.md"

check "docs/compliance/container-gov-de.md exists" \
    "test -f $OPENDESK_NIX/docs/compliance/container-gov-de.md"

check "CONTAINER-GOV-DE-E2E-COMPLETE.md exists" \
    "test -f $PROJECT_ROOT/CONTAINER-GOV-DE-E2E-COMPLETE.md"

# 4. Check Nix Syntax
echo ""
echo "${BLUE}4. Checking Nix File Syntax...${NC}"

if command -v nix-instantiate &> /dev/null; then
    for file in \
        "$OPENDESK_NIX/overlays/container-gov-de.nix" \
        "$OPENDESK_NIX/lib/compliance/container-gov-de.nix" \
        "$OPENDESK_NIX/lib/ci-cd/container-gov-de.nix" \
        "$OPENDESK_NIX/templates/container-gov-de/default.nix" \
        "$OPENDESK_NIX/templates/container-gov-de/nixos-config.nix"; do
        
        local_name=$(basename "$file")
        check "$local_name has valid syntax" \
            "nix-instantiate --parse-only $file"
    done
else
    echo -e "  ${YELLOW}⚠ nix-instantiate not found, skipping syntax checks${NC}"
fi

# 5. Check Bash Syntax
echo ""
echo "${BLUE}5. Checking Bash Script Syntax...${NC}"

for script in \
    "$OPENDESK_NIX/scripts/container-gov-de/"*.sh \
    "$OPENDESK_NIX/scripts/migrate-upstream-images.sh"; do
    
    local_name=$(basename "$script")
    check "$local_name has valid bash syntax" \
        "bash -n $script"
done

# 6. Check File Counts
echo ""
echo "${BLUE}6. Checking File Counts...${NC}"

SCRIPT_COUNT=$(find $OPENDESK_NIX/scripts/container-gov-de/ -name "*.sh" -type f | wc -l)
DOC_COUNT=$(find $OPENDESK_NIX -name "*.md" -path "*/container-gov-de*" -o -name "CONTAINER-GOV-DE.md" -o -name "MIGRATION-UPSTREAM-E2E.md" | wc -l)
NIX_COUNT=$(find $OPENDESK_NIX -name "*.nix" -path "*container-gov-de*" | wc -l)

pass "Found $SCRIPT_COUNT CLI scripts (expected: 8)"
pass "Found $DOC_COUNT documentation files (expected: 4+)"
pass "Found $NIX_COUNT Nix files (expected: 4+)"

# 7. Check Key Content
echo ""
echo "${BLUE}7. Checking Key Content in Files...${NC}"

check "CONTAINER-GOV-DE.md mentions BG-1" \
    "grep -q 'BG-1' $OPENDESK_NIX/CONTAINER-GOV-DE.md"

check "MIGRATION-UPSTREAM-E2E.md lists 24 images" \
    "grep -q '24 upstream' $OPENDESK_NIX/MIGRATION-UPSTREAM-E2E.md"

check "compliance library has bg-1-check" \
    "grep -q 'bg-1-check' $OPENDESK_NIX/lib/compliance/container-gov-de.nix"

check "CI/CD library has GitHub Actions" \
    "grep -q 'GitHub Actions' $OPENDESK_NIX/lib/ci-cd/container-gov-de.nix"

check "migrate script has 24 images listed" \
    "grep -q 'Category 1\|Category 2\|Category 3' $OPENDESK_NIX/scripts/migrate-upstream-images.sh"

# 8. Check Docker Services
echo ""
echo "${BLUE}8. Checking Docker Services Structure...${NC}"

DOCKER_SERVICES_COUNT=$(find $OPENDESK_NIX/docker/services -maxdepth 1 -type d ! -name "services" ! -name ".*" | wc -l)
pass "Found $DOCKER_SERVICES_COUNT services in docker/services/ (expected: 75)"

# 9. Summary
echo ""
echo "============================================================"
echo "  Verification Summary"
echo "============================================================"
echo ""
echo -e "  ${GREEN}Passed: $PASS_COUNT${NC}"
echo -e "  ${RED}Failed: $FAIL_COUNT${NC}"
echo -e "  ${BLUE}Total Checks: $TOTAL_CHECKS${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "  ${GREEN}✓ ALL CHECKS PASSED!${NC}"
    echo ""
    echo "  Your container.gov.de E2E implementation is ready for use."
    echo ""
    echo "  Next steps:"
    echo "    1. Review documentation: $OPENDESK_NIX/CONTAINER-GOV-DE.md"
    echo "    2. Run migration: ./opendesk-nix/scripts/migrate-upstream-images.sh --help"
    echo "    3. Check compliance: ./opendesk-nix/scripts/container-gov-de/check-compliance.sh --help"
    echo ""
    exit 0
else
    echo -e "  ${RED}✗ SOME CHECKS FAILED${NC}"
    echo ""
    echo "  Please review the failures above and ensure all files are in place."
    echo ""
    exit 1
fi

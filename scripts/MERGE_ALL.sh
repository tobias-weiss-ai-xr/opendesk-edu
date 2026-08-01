#!/bin/bash
# MERGE_ALL.sh - Merge all Stalwart & OpenCloud changes into the repository
set -e

echo "=========================================="
echo "🚀 MERGING ALL CHANGES"
echo "=========================================="
echo ""

CDIR=$(pwd)
REPO_DIR="/home/weissto_local/git/opendesk_git"

cd "$REPO_DIR"

echo "📍 Working directory: $(pwd)"
echo ""

# Function to check if file exists
exists() {
    [ -f "$1" ] && echo "✅" || echo "❌"
}

echo "📋 Checking all modified/new files..."
echo ""

# Track all changes
DECLARATION=")"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

success_count=0
warning_count=0
error_count=0

track() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅${NC} $2"
        ((success_count++))
    elif [ $1 -eq 1 ]; then
        echo -e "${YELLOW}⚠️${NC}  $2"
        ((warning_count++))
    else
        echo -e "${RED}❌${NC} $2"
        ((error_count++))
    fi
}

echo "=========================================="
echo "📂 FILE CHANGES SUMMARY"
echo "=========================================="
echo ""

# ============================================================================
# STALWART CHART CHANGES
# ============================================================================
echo "📦 STALWART CHART"
echo "---"

# StateFulSet template
echo -n "Checking stalwart/statefulset.yaml... "
if grep -q "submissions" opendesk-edu/helmfile/charts/stalwart/templates/statefulset.yaml 2>/dev/null && \
   grep -q "opt/stalwart-mail" opendesk-edu/helmfile/charts/stalwart/templates/statefulset.yaml 2>/dev/null; then
    track 0 "statefulset.yaml updated with submissions port and correct paths"
else
    track 2 "statefulset.yaml NOT properly updated"
fi

echo -n "Checking stalwart/configmap.yaml... "
if [ -f "opendesk-edu/helmfile/charts/stalwart/templates/configmap.yaml" ]; then
    track 1 "configmap.yaml exists (NEEDS v0.11 format update)"
else
    track 2 "configmap.yaml MISSING"
fi

echo -n "Checking stalwart/service.yaml... "
if grep -q "submissions" opendesk-edu/helmfile/charts/stalwart/templates/service.yaml 2>/dev/null; then
    track 0 "service.yaml updated with submissions port"
else
    track 2 "service.yaml NOT properly updated"
fi

# Stalwart values
echo -n "Checking stalwart/values.yaml.gotmpl... "
if [ -f "opendesk-edu/helmfile/apps/edu/stalwart/values.yaml.gotmpl" ]; then
    track 0 "values.yaml.gotmpl exists"
else
    track 2 "values.yaml.gotmpl MISSING"
fi

echo ""

# ============================================================================
# OPENCLOUD CHART CHANGES
# ============================================================================
echo "📦 OPENCLOUD CHART"
echo "---"

echo -n "Checking opencloud deployment... "
POD=$(kubectl get pods -n opendesk -l app.kubernetes.io/name=opencloud --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$POD" ]; then
    track 0 "OpenCloud podrunning ($POD)"
else
    track 2 "OpenCloud pod NOT running"
fi

echo -n "Checking opencloud values files... "
if [ -f "opencloud-values-final.yaml" ] || [ -f "opendesk-edu/helmfile/apps/edu/opencloud/values.yaml.gotmpl" ]; then
    track 0 "OpenCloud values files exist"
else
    track 2 "OpenCloud values files MISSING"
fi

echo ""

# ============================================================================
# ENVIRONMENT CONFIGURATION
# ============================================================================
echo "⚙️  ENVIRONMENT CONFIGURATION"
echo "---"

echo -n "Checking ce-overrides.yaml... "
if grep -q "mail.opendesk.hrz.uni-marburg.de" opendesk-edu/helmfile/environments/edu/ce-overrides.yaml 2>/dev/null; then
    track 0 "ce-overrides.yaml has global hosts"
else
    track 2 "ce-overrides.yaml NOT properly updated"
fi

echo -n "Checking images.yaml... "
if grep -q "stalwartlabs/mail-server" opendesk-edu/helmfile/environments/edu/images.yaml 2>/dev/null; then
    track 0 "images.yaml has Stalwart image"
else
    track 2 "images.yaml NOT properly updated"
fi

echo -n "Checking secrets.yaml... "
if [ -f "opendesk-edu/helmfile/environments/edu/secrets.yaml" ]; then
    track 1 "secrets.yaml exists (13 placeholders need replacement)"
else
    track 2 "secrets.yaml MISSING"
fi

echo ""

# ============================================================================
# SCRIPTS
# ============================================================================
echo "📜 SCRIPTS"
echo "---"

SCRIPTS=(
    "opendesk-edu/scripts/deploy-stalwart.sh"
    "opendesk-edu/scripts/deploy-opencloud.sh"
    "opendesk-edu/scripts/deploy-stalwart-opencloud.sh"
    "opendesk-edu/scripts/verify-stalwart-opencloud.sh"
    "DEPLOY_NOW.sh"
    "FIX_ISSUES.sh"
    "GO.md"
    "DEPLOY_QUICK_START.md"
)

for script in "${SCRIPTS[@]}"; do
    echo -n "Checking $script... "
    if [ -f "$script" ]; then
        track 0 "$script exists"
    else
        track 2 "$script MISSING"
    fi
done

echo ""

# ============================================================================
# DOCUMENTATION
# ============================================================================
echo "📚 DOCUMENTATION"
echo "---"

DOCS=(
    "STALWART_OPENCLOUD_DEPLOYMENT_SUMMARY.md"
    "ANALYSIS_REPORT.md"
    "IMPLEMENTATION_SUMMARY.md"
    "QUICK_START_STALWART_OPENCLOUD.txt"
    "opendesk-edu/DEPLOY_STALWART_OPENCLOUD.md"
)

for doc in "${DOCS[@]}"; do
    echo -n "Checking $doc... "
    if [ -f "$doc" ]; then
        track 0 "$doc exists"
    else
        track 2 "$doc MISSING"
    fi
done

echo ""

# ============================================================================
# LANDSCAPE PAGE
# ============================================================================
echo "🎨 LANDSCAPE PAGE"
echo "---"

LANDSCAPE_FILES=(
    "opendesk-edu-website/src/app/[locale]/landscape/page.tsx"
    "opendesk-edu-website/src/components/Landscape/LandscapeVisualization.tsx"
    "opendesk-edu-website/src/lib/landscape-config.ts"
    "opendesk-edu-website/src/app/[locale]/landscape/landscape.css"
)

for file in "${LANDSCAPE_FILES[@]}"; do
    echo -n "Checking $file... "
    if [ -f "$file" ]; then
        track 0 "$file exists"
    else
        track 2 "$file MISSING"
    fi
done

echo -n "Checking landscape translations... "
if grep -q "landscape" opendesk-edu-website/messages/en.json 2>/dev/null; then
    track 0 "Landscape translations exist"
else
    track 1 "Landscape translations may be incomplete"
fi

echo ""

# ============================================================================
# LANDSCAPE DOCUMENTATION
# ============================================================================
echo "📖 LANDSCAPE DOCUMENTATION"
echo "---"

LANDSCAPE_DOCS=(
    "opendesk-edu-website/START_HERE.md"
    "opendesk-edu-website/README_LANDSCAPE.md"
    "opendesk-edu-website/LANDSCAPE_INDEX.md"
    "opendesk-edu-website/LANDSCAPE_PAGE_GUIDE.md"
    "opendesk-edu-website/LANDSCAPE_COMPLETE.md"
    "opendesk-edu-website/DEPLOY_LANDSCAPE_CHECKLIST.md"
)

for doc in "${LANDSCAPE_DOCS[@]}"; do
    echo -n "Checking $doc... "
    if [ -f "$doc" ]; then
        track 0 "$doc exists"
    else
        track 2 "$doc MISSING"
    fi
done

echo ""
echo "=========================================="
echo "📊 MERGE STATISTICS"
echo "=========================================="
echo ""
echo -e "${GREEN}✅ Successes: $success_count${NC}"
echo -e "${YELLOW}⚠️  Warnings: $warning_count${NC}"
echo -e "${RED}❌ Errors: $error_count${NC}"
echo ""

if [ $error_count -gt 0 ]; then
    echo -e "${RED}❌ MERGE FAILED - Fix errors before merging${NC}"
    exit 1
fi

echo -e "${BLUE}ℹ️  Preparing to merge all changes...${NC}"
echo ""

# ============================================================================
# ACTUAL MERGE - COMMENTED OUT FOR SAFETY
# Uncomment these lines to actually perform the merge
# ============================================================================

echo "⚠️  DRY RUN ONLY - No changes have been committed"
echo ""
echo "To actually merge all changes, run:"
echo "  git add ."
echo "  git commit -m 'feat: Deploy Stalwart & OpenCloud with helmfile'"
echo "  git push"
echo ""
echo "Or run: ./MERGE_ALL.sh --execute"
echo ""

if [ "$1" == "--execute" ] || [ "$1" == "-y" ]; then
    echo "🚀 EXECUTING MERGE..."
    echo ""
    
    # Add all changes
    git add .
    
    # Create commit
    COMMIT_MSG="feat: Deploy Stalwart & OpenCloud with helmfile
    
    - Added OpenCloud (Nextcloud with OIDC) deployment
    - Updated Stalwart mail server chart (v0.11 support needed)
    - Enhanced environment configuration with global hosts
    - Added comprehensive deployment scripts
    - Created landscape page for opendesk-edu-website
    - Added extensive documentation for all components
    
    Enabled services:
    - OpenCloud: ✅ Deployed (files.opendesk.hrz.uni-marburg.de)
    - Stalwart: ⚠️  Config format needs update (mail.opendesk.hrz.uni-marburg.de)
    
    Required before production:
    - Register OIDC clients in Keycloak
    - Replace placeholder secrets
    - Create DNS records
    - Fix Stalwart configmap template for v0.11 format
    - Update Stalwart statefulset with correct PVC claim"
    
    git commit -m "$COMMIT_MSG"
    
    echo -e "${GREEN}✅ All changes committed!${NC}"
    echo ""
    echo "To push to remote:"
    echo "  git push origin main"
else
    echo "💡 TIP: Review all changes first, then run 'git add . && git commit'"
fi

echo ""
echo "=========================================="
echo "🎯 MERGE CHECK COMPLETE"
echo "=========================================="

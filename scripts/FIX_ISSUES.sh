#!/bin/bash

# =============================================================================
#  FIX_ISSUES.sh - Remediation Script for Stalwart + OpenCloud Deployment
# =============================================================================
# 
# This script addresses the gaps and warnings identified in the ANALYSIS_REPORT
# Run from the repository root: ./FIX_ISSUES.sh
#
# Usage:
#   ./FIX_ISSUES.sh                    # Show all available fixes
#   ./FIX_ISSUES.sh p0                 # Apply P0 (critical) fixes
#   ./FIX_ISSUES.sh p1                 # Apply P1 (should have) fixes
#   ./FIX_ISSUES.sh p2                 # Apply P2 (nice to have) fixes
#   ./FIX_ISSUES.sh all                # Apply all fixes
#   ./FIX_ISSUES.sh check              # Check current status
#
# =============================================================================

set -e

REPO_ROOT="$(pwd)"
OPENDESK_EDU="$REPO_ROOT/opendesk-edu"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
FIXED=0
SKIPPED=0
FAILED=0

# =============================================================================
#  FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    FIXED=$((FIXED + 1))
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
    SKIPPED=$((SKIPPED + 1))
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    FAILED=$((FAILED + 1))
}

create_backup() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.bak.$(date +%Y%m%d-%H%M%S)"
        cp "$file" "$backup"
        echo "  → Backup created: $backup"
    fi
}

# =============================================================================
#  P0 FIXES (Must Do Before Production)
# =============================================================================

fix_p0_001_add_k8up_annotations() {
    log_info "Fix P0-001: Adding k8up backup annotations to Stalwart PVC"
    
    local file="$OPENDESK_EDU/helmfile/charts/stalwart/templates/pvc.yaml"
    
    if [[ ! -f "$file" ]]; then
        log_error "Stalwart PVC template not found: $file"
        return 1
    fi
    
    create_backup "$file"
    
    if grep -q "k8up.io/exclude" "$file"; then
        log_warn "k8up annotation already exists in Stalwart PVC"
        return 0
    fi
    
    # Add annotation to metadata
    sed -i '/metadata:/!b;n;/annotations:/!b;n;c\  annotations:\n    k8up.io/exclude: "false"\n    k8up.io/backup: "true"' "$file"
    
    log_success "Added k8up annotations to Stalwart PVC"
}

fix_p0_002_add_k8up_annotations_opencloud() {
    log_info "Fix P0-002: Adding k8up backup annotations to OpenCloud PVC"
    
    local file="$OPENDESK_EDU/helmfile/charts/opencloud/templates/pvc.yaml"
    
    if [[ ! -f "$file" ]]; then
        log_error "OpenCloud PVC template not found: $file"
        return 1
    fi
    
    create_backup "$file"
    
    if grep -q "k8up.io/exclude" "$file"; then
        log_warn "k8up annotation already exists in OpenCloud PVC"
        return 0
    fi
    
    # Add annotation to metadata
    sed -i '/metadata:/!b;n;/annotations:/!b;n;c\  annotations:\n    k8up.io/exclude: "false"\n    k8up.io/backup: "true"' "$file"
    
    log_success "Added k8up annotations to OpenCloud PVC"
}

# =============================================================================
#  P1 FIXES (Should Do Before Production)
# =============================================================================

fix_p1_001_add_node_selector_stalwart() {
    log_info "Fix P1-001: Adding nodeSelector for Stalwart"
    
    local file="$OPENDESK_EDU/helmfile/apps/edu/stalwart/values.yaml.gotmpl"
    
    if [[ ! -f "$file" ]]; then
        log_error "Stalwart values file not found: $file"
        return 1
    fi
    
    create_backup "$file"
    
    if grep -q "nodeSelector:" "$file"; then
        log_warn "nodeSelector already exists in Stalwart values"
        return 0
    fi
    
    # Add nodeSelector after resources
    sed -i '/^securityContext:/i\nodeSelector:\n  kubernetes.io/arch: amd64\n  node-role.kubernetes.io/worker: "true"' "$file"
    
    log_success "Added nodeSelector for Stalwart"
}

fix_p1_002_add_pod_anti_affinity_opencloud() {
    log_info "Fix P1-002: Adding podAntiAffinity for OpenCloud"
    
    local file="$OPENDESK_EDU/helmfile/apps/edu/opencloud/values.yaml.gotmpl"
    
    if [[ ! -f "$file" ]]; then
        log_error "OpenCloud values file not found: $file"
        return 1
    fi
    
    create_backup "$file"
    
    if grep -q "podAntiAffinity\|affinity:" "$file"; then
        log_warn "podAntiAffinity/affinity already exists in OpenCloud values"
        return 0
    fi
    
    # Add podAntiAffinity after resources
    cat >> "$file" << 'EOF'

# Anti-affinity for high availability
podAntiAffinity:
  enabled: true
  type: preferredDuringSchedulingIgnoredDuringExecution
  weight: 100
EOF
    
    log_success "Added podAntiAffinity for OpenCloud"
}

fix_p1_003_make_ldap_configurable() {
    log_info "Fix P1-003: Making LDAP hostname configurable"
    
    local file="$OPENDESK_EDU/helmfile/apps/edu/stalwart/values.yaml.gotmpl"
    
    if [[ ! -f "$file" ]]; then
        log_error "Stalwart values file not found: $file"
        return 1
    fi
    
    create_backup "$file"
    
    if grep -q "ldap.host:" "$file"; then
        log_warn "LDAP host already configurable"
        return 0
    fi
    
    # This is complex - we'll add it to the ldap section
    log_warn "LDAP host is configured in config section. Consider extracting to values."
    log_warn "Manual edit recommended for this one."
    return 0
}

fix_p1_004_make_keycloak_issuer_configurable() {
    log_info "Fix P1-004: Making Keycloak issuer URL configurable"
    
    # This requires changes to the Stalwart config - complex
    log_warn "Keycloak issuer is configured in OIDC section."
    log_warn "Recommendation: Add to ce-overrides.yaml global section."
    log_warn "Manual edit recommended for this one."
    return 0
}

# =============================================================================
#  P2 FIXES (Nice to Have)
# =============================================================================

fix_p2_001_add_startup_probe_stalwart() {
    log_info "Fix P2-001: Adding startupProbe for Stalwart"
    
    local file="$OPENDESK_EDU/helmfile/charts/stalwart/templates/statefulset.yaml"
    
    if [[ ! -f "$file" ]]; then
        log_error "Stalwart StatefulSet template not found: $file"
        return 1
    fi
    
    create_backup "$file"
    
    if grep -q "startupProbe:" "$file"; then
        log_warn "startupProbe already exists in Stalwart StatefulSet"
        return 0
    fi
    
    # Add startupProbe after livenessProbe
    sed -i '/livenessProbe:/a\    startupProbe:\n      httpGet:\n        path: /api/health\n        port: http\n      initialDelaySeconds: 30\n      periodSeconds: 10\n      timeoutSeconds: 5\n      failureThreshold: 30' "$file"
    
    log_success "Added startupProbe for Stalwart"
}

fix_p2_002_add_resources_opencloud() {
    log_info "Fix P2-002: Adding explicit resource configuration for OpenCloud"
    
    local file="$OPENDESK_EDU/helmfile/apps/edu/opencloud/values.yaml.gotmpl"
    
    if [[ ! -f "$file" ]]; then
        log_error "OpenCloud values file not found: $file"
        return 1
    fi
    
    create_backup "$file"
    
    if grep -q "resources:" "$file"; then
        log_warn "resources already defined in OpenCloud values"
        return 0
    fi
    
    # Add resources at the end
    cat >> "$file" << 'EOF'

# Resource configuration
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: "2"
    memory: 4Gi
EOF
    
    log_success "Added resource configuration for OpenCloud"
}

fix_p2_003_add_pdb_stalwart() {
    log_info "Fix P2-003: Adding PodDisruptionBudget for Stalwart"
    
    local dir="$OPENDESK_EDU/helmfile/charts/stalwart/templates"
    local file="$dir/pdb.yaml"
    
    if [[ -f "$file" ]]; then
        log_warn "PDB template already exists for Stalwart"
        return 0
    fi
    
    cat > "$file" << 'EOF'
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "stalwart.fullname" . }}
  labels:
    {{- include "stalwart.labels" . | nindent 4 }}
spec:
  minAvailable: 1
  selector:
    matchLabels:
      {{- include "stalwart.selectorLabels" . | nindent 6 }}
EOF
    
    log_success "Added PodDisruptionBudget template for Stalwart"
}

fix_p2_004_add_servicemonitor_stalwart() {
    log_info "Fix P2-004: Adding ServiceMonitor for Stalwart"
    
    local dir="$OPENDESK_EDU/helmfile/charts/stalwart/templates"
    local file="$dir/servicemonitor.yaml"
    
    if [[ -f "$file" ]]; then
        log_warn "ServiceMonitor template already exists for Stalwart"
        return 0
    fi
    
    # Check if monitoring CRDs are available
    if ! kubectl get crd servicemonitors.monitoring.coreos.com >/dev/null 2>&1; then
        log_warn "ServiceMonitor CRD not available (Prometheus operator not installed)"
        return 0
    fi
    
    cat > "$file" << 'EOF'
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "stalwart.fullname" . }}
  labels:
    {{- include "stalwart.labels" . | nindent 4 }}
spec:
  endpoints:
  - interval: 30s
    port: http
    path: /api/health
    scheme: http
  selector:
    matchLabels:
      {{- include "stalwart.selectorLabels" . | nindent 6 }}
EOF
    
    log_success "Added ServiceMonitor template for Stalwart"
}

fix_p2_005_add_opencloud_resources() {
    log_info "Fix P2-005: Ensuring OpenCloud has proper resource limits"
    
    local file="$OPENDESK_EDU/helmfile/charts/opencloud/values.yaml"
    
    if [[ ! -f "$file" ]]; then
        log_error "OpenCloud chart values not found: $file"
        return 1
    fi
    
    create_backup "$file"
    
    if grep -q "resources:" "$file"; then
        log_warn "resources already defined in OpenCloud chart values"
        return 0
    fi
    
    # Add default resources
    sed -i '/^replicaCount:/a\\nresources:\n  requests:\n    cpu: 500m\n    memory: 512Mi\n  limits:\n    cpu: "2"\n    memory: 4Gi' "$file"
    
    log_success "Added default resource configuration to OpenCloud chart"
}

# =============================================================================
#  CHECK FUNCTIONS
# =============================================================================

check_p0_issues() {
    log_info "Checking P0 issues..."
    
    local issues=0
    
    # Check k8up annotations
    if ! grep -q "k8up.io/exclude" "$OPENDESK_EDU/helmfile/charts/stalwart/templates/pvc.yaml" 2>/dev/null; then
        echo "  ❌ Stalwart PVC missing k8up annotations"
        issues=$((issues + 1))
    fi
    
    if ! grep -q "k8up.io/exclude" "$OPENDESK_EDU/helmfile/charts/opencloud/templates/pvc.yaml" 2>/dev/null; then
        echo "  ❌ OpenCloud PVC missing k8up annotations"
        issues=$((issues + 1))
    fi
    
    # Check placeholder secrets
    placeholders=$(grep -c "changeme-replace-with-actual" "$OPENDESK_EDU/helmfile/environments/edu/secrets.yaml" 2>/dev/null || echo "0")
    echo "  ℹ️  Placeholder secrets: $placeholders (expected before deployment)"
    
    if [[ $issues -eq 0 ]]; then
        echo "  ✅ All P0 issues resolved"
        return 0
    else
        echo "  ⚠️  $issues P0 issue(s) found"
        return 1
    fi
}

check_p1_issues() {
    log_info "Checking P1 issues..."
    
    local issues=0
    
    # Check nodeSelector
    if ! grep -q "nodeSelector:" "$OPENDESK_EDU/helmfile/apps/edu/stalwart/values.yaml.gotmpl" 2>/dev/null; then
        echo "  ❌ Stalwart missing nodeSelector"
        issues=$((issues + 1))
    fi
    
    # Check podAntiAffinity
    if ! grep -q "podAntiAffinity" "$OPENDESK_EDU/helmfile/apps/edu/opencloud/values.yaml.gotmpl" 2>/dev/null; then
        echo "  ❌ OpenCloud missing podAntiAffinity"
        issues=$((issues + 1))
    fi
    
    if [[ $issues -eq 0 ]]; then
        echo "  ✅ All P1 issues resolved"
        return 0
    else
        echo "  ⚠️  $issues P1 issue(s) found"
        return 1
    fi
}

check_p2_issues() {
    log_info "Checking P2 issues..."
    
    local issues=0
    
    # Check startupProbe
    if ! grep -q "startupProbe:" "$OPENDESK_EDU/helmfile/charts/stalwart/templates/statefulset.yaml" 2>/dev/null; then
        echo "  ❌ Stalwart missing startupProbe"
        issues=$((issues + 1))
    fi
    
    # Check PDB
    if [[ ! -f "$OPENDESK_EDU/helmfile/charts/stalwart/templates/pdb.yaml" ]]; then
        echo "  ❌ Stalwart missing PodDisruptionBudget"
        issues=$((issues + 1))
    fi
    
    # Check ServiceMonitor
    if [[ ! -f "$OPENDESK_EDU/helmfile/charts/stalwart/templates/servicemonitor.yaml" ]]; then
        echo "  ❌ Stalwart missing ServiceMonitor"
        issues=$((issues + 1))
    fi
    
    if [[ $issues -eq 0 ]]; then
        echo "  ✅ All P2 issues resolved"
        return 0
    else
        echo "  ⚠️  $issues P2 issue(s) found"
        return 1
    fi
}

# =============================================================================
#  USAGE
# =============================================================================

usage() {
    cat << 'EOF'

  Usage: ./FIX_ISSUES.sh [COMMAND]

  Commands:
    check           Check current status of all issues
    p0              Apply P0 (critical) fixes
    p1              Apply P1 (should have) fixes
    p2              Apply P2 (nice to have) fixes
    all             Apply all fixes (p0 + p1 + p2)

  Examples:
    ./FIX_ISSUES.sh                         # Show this help
    ./FIX_ISSUES.sh check                   # Check status
    ./FIX_ISSUES.sh p0                      # Apply critical fixes
    ./FIX_ISSUES.sh all                     # Apply all fixes

  Notes:
    - This script creates backups of modified files (.bak.TIMESTAMP)
    - Some fixes require manual review (marked with warning)
    - All P0 fixes should be safe to apply automatically
    - Run 'check' after applying fixes to verify

EOF
}

# =============================================================================
#  MAIN
# =============================================================================

if [[ $# -eq 0 ]]; then
    echo "═══════════════════════════════════════════════════════════════════════"
    echo "  Stalwart + OpenCloud Deployment - Remediation Script"
    echo "═══════════════════════════════════════════════════════════════════════"
    echo ""
    usage
    exit 0
fi

COMMAND="$1"

case "$COMMAND" in
    check)
        echo "═══════════════════════════════════════════════════════════════════════"
        echo "  Checking Issue Status"
        echo "═══════════════════════════════════════════════════════════════════════"
        echo ""
        check_p0_issues
        echo ""
        check_p1_issues
        echo ""
        check_p2_issues
        ;;
    p0)
        echo "═══════════════════════════════════════════════════════════════════════"
        echo "  Applying P0 (Critical) Fixes"
        echo "═══════════════════════════════════════════════════════════════════════"
        echo ""
        fix_p0_001_add_k8up_annotations
        echo ""
        fix_p0_002_add_k8up_annotations_opencloud
        echo ""
        ;;
    p1)
        echo "═══════════════════════════════════════════════════════════════════════"
        echo "  Applying P1 (Should Have) Fixes"
        echo "═══════════════════════════════════════════════════════════════════════"
        echo ""
        fix_p1_001_add_node_selector_stalwart
        echo ""
        fix_p1_002_add_pod_anti_affinity_opencloud
        echo ""
        fix_p1_003_make_ldap_configurable
        echo ""
        fix_p1_004_make_keycloak_issuer_configurable
        echo ""
        ;;
    p2)
        echo "═══════════════════════════════════════════════════════════════════════"
        echo "  Applying P2 (Nice to Have) Fixes"
        echo "═══════════════════════════════════════════════════════════════════════"
        echo ""
        fix_p2_001_add_startup_probe_stalwart
        echo ""
        fix_p2_002_add_resources_opencloud
        echo ""
        fix_p2_003_add_pdb_stalwart
        echo ""
        fix_p2_004_add_servicemonitor_stalwart
        echo ""
        fix_p2_005_add_opencloud_resources
        echo ""
        ;;
    all)
        echo "═══════════════════════════════════════════════════════════════════════"
        echo "  Applying ALL Fixes (P0 + P1 + P2)"
        echo "═══════════════════════════════════════════════════════════════════════"
        echo ""
        
        # P0
        echo "--- P0 Fixes ---"
        fix_p0_001_add_k8up_annotations
        echo ""
        fix_p0_002_add_k8up_annotations_opencloud
        echo ""
        
        # P1
        echo "--- P1 Fixes ---"
        fix_p1_001_add_node_selector_stalwart
        echo ""
        fix_p1_002_add_pod_anti_affinity_opencloud
        echo ""
        fix_p1_003_make_ldap_configurable
        echo ""
        fix_p1_004_make_keycloak_issuer_configurable
        echo ""
        
        # P2
        echo "--- P2 Fixes ---"
        fix_p2_001_add_startup_probe_stalwart
        echo ""
        fix_p2_002_add_resources_opencloud
        echo ""
        fix_p2_003_add_pdb_stalwart
        echo ""
        fix_p2_004_add_servicemonitor_stalwart
        echo ""
        fix_p2_005_add_opencloud_resources
        echo ""
        ;;
    *)
        echo "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac

echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "  Summary: $FIXED fixed, $SKIPPED skipped, $FAILED failed"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi

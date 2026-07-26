#!/bin/bash
# verify-stalwart-opencloud.sh — Verify Stalwart and OpenCloud configuration
# Part of openDesk Edu deployment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELMFILE_DIR="$SCRIPT_DIR/../helmfile"

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --k8s       Verify Kubernetes resources (requires cluster access)"
  echo "  --config    Verify configuration files only"
  echo "  --secrets   Check if secrets need to be updated"
  echo "  --all       Run all checks"
  echo "  --help      Show this help"
  exit 0
}

# Parse arguments
CHECK_K8S=false
CHECK_CONFIG=false
CHECK_SECRETS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --k8s)
      CHECK_K8S=true
      shift
      ;;
    --config)
      CHECK_CONFIG=true
      shift
      ;;
    --secrets)
      CHECK_SECRETS=true
      shift
      ;;
    --all)
      CHECK_K8S=true
      CHECK_CONFIG=true
      CHECK_SECRETS=true
      shift
      ;;
    --help)
      usage
      ;;
    *)
      echo "Error: Unknown option $1" >&2
      usage
      ;;
  esac
done

# If no options, run all checks
if [[ "$CHECK_K8S" == false && "$CHECK_CONFIG" == false && "$CHECK_SECRETS" == false ]]; then
  CHECK_K8S=true
  CHECK_CONFIG=true
  CHECK_SECRETS=true
fi

echo "========================================="
echo "Verifying Stalwart + OpenCloud Configuration"
echo "========================================="
echo ""

PASS=0
FAIL=0

check_pass() {
  echo "  [PASS] $1"
  PASS=$((PASS + 1))
}

check_fail() {
  echo "  [FAIL] $1"
  FAIL=$((FAIL + 1))
}

check_info() {
  echo "  [INFO] $1"
}

# Configuration checks
if [[ "$CHECK_CONFIG" == true ]]; then
  echo "=== Configuration Checks ==="
  echo ""
  
  # Check Stalwart values file
  if [[ -f "$HELMFILE_DIR/apps/edu/stalwart/values.yaml.gotmpl" ]]; then
    check_pass "Stalwart values file exists"
    
    # Check for key configurations
    if grep -q "enabled: true" "$HELMFILE_DIR/apps/edu/stalwart/values.yaml.gotmpl" && \
       grep -q "oidc:" "$HELMFILE_DIR/apps/edu/stalwart/values.yaml.gotmpl"; then
      check_pass "Stalwart OIDC authentication enabled"
    else
      check_fail "Stalwart OIDC authentication not enabled"
    fi
    
    if grep -q "type: ldap" "$HELMFILE_DIR/apps/edu/stalwart/values.yaml.gotmpl" && \
       grep -q "directory:" "$HELMFILE_DIR/apps/edu/stalwart/values.yaml.gotmpl"; then
      check_pass "Stalwart LDAP directory configured"
    else
      check_fail "Stalwart LDAP directory not configured"
    fi
    
    if grep -q "ingress:" "$HELMFILE_DIR/apps/edu/stalwart/values.yaml.gotmpl" && \
       grep -A5 "ingress:" "$HELMFILE_DIR/apps/edu/stalwart/values.yaml.gotmpl" | grep -q "enabled: true"; then
      check_pass "Stalwart ingress enabled"
    else
      check_info "Stalwart ingress configuration not found or disabled"
    fi
    
    if grep -q "persistence:" "$HELMFILE_DIR/apps/edu/stalwart/values.yaml.gotmpl" && \
       grep -A5 "persistence:" "$HELMFILE_DIR/apps/edu/stalwart/values.yaml.gotmpl" | grep -q "enabled: true"; then
      check_pass "Stalwart persistence enabled"
    else
      check_info "Stalwart persistence configuration not found or disabled"
    fi
  else
    check_fail "Stalwart values file not found"
  fi
  
  # Check OpenCloud values file
  if [[ -f "$HELMFILE_DIR/apps/edu/opencloud/values.yaml.gotmpl" ]]; then
    check_pass "OpenCloud values file exists"
    
    if grep -q "ingress:" "$HELMFILE_DIR/apps/edu/opencloud/values.yaml.gotmpl" && \
       grep -A5 "ingress:" "$HELMFILE_DIR/apps/edu/opencloud/values.yaml.gotmpl" | grep -q "enabled: true"; then
      check_pass "OpenCloud ingress enabled"
    else
      check_info "OpenCloud ingress configuration not found or disabled"
    fi
    
    if grep -q "issuer:" "$HELMFILE_DIR/apps/edu/opencloud/values.yaml.gotmpl"; then
      check_pass "OpenCloud OIDC issuer configured"
    else
      check_info "OpenCloud OIDC issuer not found in values"
    fi
    
    if grep -q "clientId: opendesk-opencloud" "$HELMFILE_DIR/apps/edu/opencloud/values.yaml.gotmpl"; then
      check_pass "OpenCloud OIDC client ID configured"
    else
      check_fail "OpenCloud OIDC client ID not configured"
    fi
  else
    check_fail "OpenCloud values file not found"
  fi
  
  # Check helmfile-child files
  if [[ -f "$HELMFILE_DIR/apps/edu/stalwart/helmfile-child.yaml.gotmpl" ]]; then
    check_pass "Stalwart helmfile-child exists"
    
    if grep -q "installed:" "$HELMFILE_DIR/apps/edu/stalwart/helmfile-child.yaml.gotmpl" && \
       grep -q "stalwart" "$HELMFILE_DIR/apps/edu/stalwart/helmfile-child.yaml.gotmpl"; then
      check_pass "Stalwart install condition configured"
    fi
  else
    check_fail "Stalwart helmfile-child not found"
  fi
  
  if [[ -f "$HELMFILE_DIR/apps/edu/opencloud/helmfile-child.yaml.gotmpl" ]]; then
    check_pass "OpenCloud helmfile-child exists"
    
    if grep -q "installed:" "$HELMFILE_DIR/apps/edu/opencloud/helmfile-child.yaml.gotmpl" && \
       grep -q "opencloud" "$HELMFILE_DIR/apps/edu/opencloud/helmfile-child.yaml.gotmpl"; then
      check_pass "OpenCloud install condition configured"
    fi
  else
    check_fail "OpenCloud helmfile-child not found"
  fi
  
  # Check ce-overrides
  if [[ -f "$HELMFILE_DIR/environments/edu/ce-overrides.yaml" ]]; then
    check_pass "CE overrides file exists"
    
    if grep -q "stalwart:" "$HELMFILE_DIR/environments/edu/ce-overrides.yaml" && \
       grep -q "enabled: true" "$HELMFILE_DIR/environments/edu/ce-overrides.yaml"; then
      check_pass "Stalwart enabled in ce-overrides"
    else
      check_fail "Stalwart not enabled in ce-overrides"
    fi
    
    if grep -q "opencloud:" "$HELMFILE_DIR/environments/edu/ce-overrides.yaml" && \
       grep -q "enabled: true" "$HELMFILE_DIR/environments/edu/ce-overrides.yaml"; then
      check_pass "OpenCloud enabled in ce-overrides"
    else
      check_fail "OpenCloud not enabled in ce-overrides"
    fi
    
    if grep -q "dovecot:" "$HELMFILE_DIR/environments/edu/ce-overrides.yaml" && \
       grep -q "enabled: false" "$HELMFILE_DIR/environments/edu/ce-overrides.yaml"; then
      check_pass "Dovecot disabled (replaced by Stalwart)"
    else
      check_info "Dovecot not explicitly disabled"
    fi
    
    if grep -q "nextcloud:" "$HELMFILE_DIR/environments/edu/ce-overrides.yaml" && \
       grep -q "enabled: false" "$HELMFILE_DIR/environments/edu/ce-overrides.yaml"; then
      check_pass "Nextcloud disabled (replaced by OpenCloud)"
    else
      check_info "Nextcloud not explicitly disabled"
    fi
    
    if grep -q "global:" "$HELMFILE_DIR/environments/edu/ce-overrides.yaml" && \
       grep -q "hosts:" "$HELMFILE_DIR/environments/edu/ce-overrides.yaml"; then
      check_pass "Global hosts configured"
    else
      check_fail "Global hosts not configured"
    fi
  else
    check_fail "CE overrides file not found"
  fi
  
  echo ""
fi

# Secrets checks
if [[ "$CHECK_SECRETS" == true ]]; then
  echo "=== Secrets Checks ==="
  echo ""
  
  if [[ -f "$HELMFILE_DIR/environments/edu/secrets.yaml" ]]; then
    check_pass "Secrets file exists"
    
    # Check for placeholder values
    PLACEHOLDER_COUNT=$(grep -c "changeme-replace-with-actual" "$HELMFILE_DIR/environments/edu/secrets.yaml" || true)
    
    if [[ "$PLACEHOLDER_COUNT" -eq 0 ]]; then
      check_pass "No placeholder secrets found"
    else
      if [[ "$CHECK_K8S" == false ]]; then
        check_info "$PLACEHOLDER_COUNT placeholder secrets need to be replaced before production deployment"
      else
        check_fail "$PLACEHOLDER_COUNT placeholder secrets need to be replaced"
      fi
    fi
    
    # Check for Stalwart secrets
    if grep -q "stalwart:" "$HELMFILE_DIR/environments/edu/secrets.yaml"; then
      check_pass "Stalwart secrets section exists"
    else
      check_fail "Stalwart secrets section missing"
    fi
    
    # Check for OpenCloud secrets
    if grep -q "opencloud:" "$HELMFILE_DIR/environments/edu/secrets.yaml"; then
      check_pass "OpenCloud secrets section exists"
    else
      check_fail "OpenCloud secrets section missing"
    fi
    
    # Check for Keycloak client secrets
    if grep -q "clientSecret:" "$HELMFILE_DIR/environments/edu/secrets.yaml"; then
      check_pass "Keycloak client secrets configured"
    else
      check_fail "Keycloak client secrets missing"
    fi
  else
    check_fail "Secrets file not found"
  fi
  
  echo ""
fi

# Kubernetes checks
if [[ "$CHECK_K8S" == true ]]; then
  echo "=== Kubernetes Checks ==="
  echo ""
  
  # Check if kubectl is available
  if command -v kubectl &> /dev/null; then
    check_pass "kubectl is available"
    
    # Check current context
    CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || true)
    if [[ -n "$CURRENT_CONTEXT" ]]; then
      check_info "Current context: $CURRENT_CONTEXT"
    fi
    
    # Check for Stalwart resources
    if kubectl get deployment stalwart &> /dev/null; then
      check_pass "Stalwart deployment exists"
      
      # Check status
      STATUS=$(kubectl get deployment stalwart -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || true)
      if [[ "$STATUS" == "True" ]]; then
        check_pass "Stalwart deployment is available"
      else
        check_fail "Stalwart deployment not available"
      fi
    else
      check_info "Stalwart deployment not found (not yet deployed)"
    fi
    
    # Check for OpenCloud resources
    if kubectl get deployment opendesk-opencloud &> /dev/null; then
      check_pass "OpenCloud deployment exists"
      
      # Check status
      STATUS=$(kubectl get deployment opendesk-opencloud -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || true)
      if [[ "$STATUS" == "True" ]]; then
        check_pass "OpenCloud deployment is available"
      else
        check_fail "OpenCloud deployment not available"
      fi
    else
      check_info "OpenCloud deployment not found (not yet deployed)"
    fi
    
    # Check PVCs
    if kubectl get pvc stalwart-pvc &> /dev/null; then
      check_pass "Stalwart PVC exists"
      STATUS=$(kubectl get pvc stalwart-pvc -o jsonpath='{.status.phase}' 2>/dev/null || true)
      check_info "Stalwart PVC status: $STATUS"
    else
      check_info "Stalwart PVC not found"
    fi
    
    if kubectl get pvc opendesk-opencloud-data &> /dev/null; then
      check_pass "OpenCloud PVC exists"
      STATUS=$(kubectl get pvc opendesk-opencloud-data -o jsonpath='{.status.phase}' 2>/dev/null || true)
      check_info "OpenCloud PVC status: $STATUS"
    else
      check_info "OpenCloud PVC not found"
    fi
    
    # Check services
    if kubectl get svc stalwart &> /dev/null; then
      check_pass "Stalwart service exists"
    else
      check_info "Stalwart service not found"
    fi
    
    if kubectl get svc opendesk-opencloud &> /dev/null; then
      check_pass "OpenCloud service exists"
    else
      check_info "OpenCloud service not found"
    fi
    
    # Check ingress
    if kubectl get ingress stalwart &> /dev/null; then
      check_pass "Stalwart ingress exists"
    else
      check_info "Stalwart ingress not found"
    fi
    
    if kubectl get ingress opendesk-opencloud &> /dev/null; then
      check_pass "OpenCloud ingress exists"
    else
      check_info "OpenCloud ingress not found"
    fi
    
    # Check secrets in Kubernetes
    if kubectl get secret opendesk-opencloud-secrets &> /dev/null; then
      check_pass "OpenCloud Kubernetes secret exists"
    else
      check_info "OpenCloud Kubernetes secret not found"
    fi
  else
    check_info "kubectl not available - skipping Kubernetes checks"
  fi
  
  echo ""
fi

# Summary
echo "========================================="
echo "Verification Summary"
echo "========================================="
echo ""
echo "Passed: $PASS checks"
echo "Failed: $FAIL checks"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  echo "WARNING: Some checks failed. Review the output above."
  exit 1
else
  echo "All checks passed!"
  exit 0
fi

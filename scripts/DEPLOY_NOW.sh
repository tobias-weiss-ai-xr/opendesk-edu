#!/bin/bash

# =============================================================================
#  DEPLOY_NOW.sh - Interactive Deployment Guide for Stalwart + OpenCloud
# =============================================================================
#
# This script guides you through the deployment process step-by-step.
# It checks prerequisites, helps generate secrets, and deploys the services.
#
# Run: ./DEPLOY_NOW.sh
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
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
#  FUNCTIONS
# =============================================================================

echo_header() {
    echo ""
    echo "══════════════════════════════════════════════════════════════════════════"
    echo "  $1"
    echo "══════════════════════════════════════════════════════════════════════════"
    echo ""
}

echo_step() {
    echo ""
    echo -e "${BLUE}[Step $1]${NC} $2"
    echo ""
}

echo_success() {
    echo -e "${GREEN}✓${NC} $1"
}

echo_error() {
    echo -e "${RED}✗${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

echo_command() {
    echo ""
    echo -e "   ${MAGENTA}Run:${NC} $1"
    echo ""
}

echo_code() {
    echo ""
    echo -e "   ${YELLOW}Code:${NC}"
    echo "   $1"
    echo ""
}

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        echo_success "$2 is available"
        return 0
    else
        echo_error "$2 is NOT available"
        return 1
    fi
}

check_kubectl() {
    check_command "kubectl" "kubectl"
    if [[ $? -eq 0 ]]; then
        # Check if can connect to cluster
        if kubectl cluster-info >/dev/null 2>&1; then
            echo_success "Connected to Kubernetes cluster"
            return 0
        else
            echo_error "kubectl cannot connect to cluster"
            return 1
        fi
    fi
    return 1
}

check_helm() {
    check_command "helm" "helm"
}

check_helmfile() {
    check_command "helmfile" "helmfile"
}

count_placeholders() {
    local file="$1"
    if [[ -f "$file" ]]; then
        grep -c "changeme-replace-with-actual" "$file" || echo "0"
    else
        echo "0"
    fi
}

# =============================================================================
#  PRE-DEPLOYMENT CHECKS
# =============================================================================

run_prerequisite_checks() {
    echo_header "PREREQUISITE CHECKS"
    
    echo_step "1" "Checking required tools..."
    
    local all_ok=true
    
    check_kubectl || all_ok=false
    check_helm || all_ok=false
    check_helmfile || all_ok=false
    
    echo ""
    if [[ "$all_ok" == true ]]; then
        echo_success "All required tools are available"
    else
        echo_error "Some required tools are missing"
        echo ""
        echo "Please install:"
        check_kubectl || echo "  - kubectl: https://kubernetes.io/docs/tasks/tools/"
        check_helm || echo "  - helm: https://helm.sh/docs/intro/install/"
        check_helmfile || echo "  - helmfile: https://github.com/helmfile/helmfile#installation"
        return 1
    fi
    
    echo_step "2" "Checking cluster connection..."
    kubectl cluster-info
    echo ""
    
    echo_step "3" "Checking current context..."
    kubectl config current-context
    echo ""
    
    echo_step "4" "Checking namespace..."
    if kubectl get ns opendesk >/dev/null 2>&1; then
        echo_success "Namespace 'opendesk' exists"
    else
        echo_warning "Namespace 'opendesk' does not exist - will be created by helmfile"
    fi
    echo ""
    
    echo_step "5" "Checking storage classes..."
    kubectl get storageclass | grep -E "ceph-rbd-ssd|ceph-cephfs-hdd-ec" || echo_info "Storage classes not found yet"
    echo ""
    
    echo_success "Prerequisite checks complete"
    return 0
}

# =============================================================================
#  SECRETS GENERATION
# =============================================================================

generate_secrets() {
    echo_header "SECRETS GENERATION"
    
    local secrets_file="$OPENDESK_EDU/helmfile/environments/edu/secrets.yaml"
    
    if [[ ! -f "$secrets_file" ]]; then
        echo_error "Secrets file not found: $secrets_file"
        return 1
    fi
    
    local placeholder_count=$(count_placeholders "$secrets_file")
    echo_info "Found $placeholder_count placeholder secrets in $secrets_file"
    echo ""
    
    if [[ $placeholder_count -eq 0 ]]; then
        echo_success "All secrets are already configured"
        return 0
    fi
    
    echo_step "1" "Generating Stalwart secrets..."
    local stalwart_admin_hash=$(openssl passwd -6 "$(openssl rand -base64 20)")
    local stalwart_oidc_secret=$(openssl rand -hex 32)
    local ldap_bind_password=$(openssl rand -base64 24)
    
    echo_code "Stalwart Admin Password Hash: ${stalwart_admin_hash:0:40}..."
    echo_code "Stalwart OIDC Secret: ${stalwart_oidc_secret:0:40}..."
    echo_code "LDAP Bind Password: ${ldap_bind_password:0:40}..."
    echo ""
    
    echo_step "2" "Generating OpenCloud secrets..."
    local oc_oidc_secret=$(openssl rand -hex 32)
    local oc_jwt_secret=$(openssl rand -hex 32)
    local oc_transfer_secret=$(openssl rand -hex 32)
    local oc_machine_auth=$(openssl rand -hex 32)
    local oc_system_user=$(openssl rand -hex 32)
    local oc_url_signing=$(openssl rand -hex 32)
    
    echo_code "OpenCloud Secrets Generated (7 total)"
    echo ""
    
    echo_step "3" "Generating Keycloak secrets..."
    local kc_admin_password=$(openssl rand -base64 20)
    echo_code "Keycloak Admin Password: ${kc_admin_password:0:40}..."
    echo ""
    
    echo_warning "IMPORTANT: These are randomly generated secrets for demonstration."
    echo_warning "For production, use your own secure passwords and store them safely."
    echo_warning "The actual secrets file needs to be updated manually."
    echo ""
    
    echo_info "To update the secrets file manually:"
    echo_command "nano $secrets_file"
    echo ""
    echo_info "Replace all 'changeme-replace-with-actual-secret' placeholders with actual values."
    echo ""
    
    return 0
}

# =============================================================================
#  KEYCLOAK OIDC CLIENT REGISTRATION
# =============================================================================

check_keycloak_clients() {
    echo_header "KEYCLOAK OIDC CLIENT CHECK"
    
    echo_info "Checking if Keycloak is running..."
    if kubectl get pods -n opendesk -l app.kubernetes.io/name=keycloak >/dev/null 2>&1; then
        echo_success "Keycloak pods found"
        kubectl get pods -n opendesk -l app.kubernetes.io/name=keycloak
        echo ""
        
        # Check if Keycloak is ready
        echo_info "Waiting for Keycloak to be ready..."
        if kubectl wait --for=condition=Ready pod -n opendesk -l app.kubernetes.io/name=keycloak --timeout=60s 2>/dev/null; then
            echo_success "Keycloak is ready"
        else
            echo_warning "Keycloak is not ready yet - OIDC clients may need to be registered manually later"
        fi
        echo ""
    else
        echo_warning "Keycloak not found - may not be deployed yet"
        echo ""
    fi
    echo ""
    
    echo_info "Required OIDC Clients:"
    echo "  1. Client ID: stalwart"
    echo "     Redirect URIs: https://mail.opendesk.hrz.uni-marburg.de/*"
    echo "     Web Origins: https://mail.opendesk.hrz.uni-marburg.de"
    echo ""
    echo "  2. Client ID: opendesk-opencloud"
    echo "     Redirect URIs: https://files.opendesk.hrz.uni-marburg.de/*"
    echo "     Web Origins: https://files.opendesk.hrz.uni-marburg.de"
    echo "     Backchannel Logout URL: https://files.opendesk.hrz.uni-marburg.de/oidc/logout"
    echo ""
    
    echo_info "To register clients manually:"
    echo "  1. Access Keycloak admin console"
    echo "  2. Navigate to Realm: opendesk"
    echo "  3. Create clients with above details"
    echo "  4. Note the client secrets"
    echo "  5. Update the secrets file with the actual client secrets"
    echo ""
    
    echo_info "Using kcadm.sh (CLI):"
    echo_code "kcadm.sh create clients/opendesk/stalwart \\"
    echo_code "  -s clientId=stalwart \\"
    echo_code "  -s enabled=true \\"
    echo_code "  -s 'redirectUris=[\"https://mail.opendesk.hrz.uni-marburg.de/*\"]' \\"
    echo_code "  -s 'webOrigins=[\"https://mail.opendesk.hrz.uni-marburg.de\"]'"
    echo ""
    
    return 0
}

# =============================================================================
#  DNS CHECK
# =============================================================================

check_dns() {
    echo_header "DNS CHECK"
    
    echo_info "Required DNS Records:"
    echo ""
    echo "  mail.opendesk.hrz.uni-marburg.de.    IN  A     <INGRESS_IP>"
    echo "  files.opendesk.hrz.uni-marburg.de.   IN  A     <INGRESS_IP>"
    echo ""
    echo_info "To find your Ingress IP:"
    echo_command "kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
    echo ""
    echo_info "Or for HAProxy:"
    echo_command "kubectl get svc -n traefik traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
    echo ""
    
    # Try to detect ingress IP
    echo_info "Attempting to detect Ingress IP..."
    local ingress_ip=""
    if kubectl get svc -n ingress-nginx ingress-nginx-controller >/dev/null 2>&1; then
        ingress_ip=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "N/A")
        echo "  NGINX Ingress IP: $ingress_ip"
    fi
    if kubectl get svc -n traefik traefik >/dev/null 2>&1; then
        ingress_ip=$(kubectl get svc -n traefik traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "N/A")
        echo "  Traefik Ingress IP: $ingress_ip"
    fi
    if kubectl get svc -n haproxy-ingress haproxy-ingress >/dev/null 2>&1; then
        ingress_ip=$(kubectl get svc -n haproxy-ingress haproxy-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "N/A")
        echo "  HAProxy Ingress IP: $ingress_ip"
    fi
    echo ""
    
    if [[ -n "$ingress_ip" && "$ingress_ip" != "N/A" ]]; then
        echo_info "DNS should point to: $ingress_ip"
        echo ""
        echo_info "Testing DNS resolution (may fail if DNS not configured yet):"
        dig +short mail.opendesk.hrz.uni-marburg.de 2>/dev/null || echo "  DNS lookup failed - not configured yet"
        dig +short files.opendesk.hrz.uni-marburg.de 2>/dev/null || echo "  DNS lookup failed - not configured yet"
        echo ""
    fi
    
    echo_warning "DNS records must be created before services can be accessed externally"
    echo ""
    
    return 0
}

# =============================================================================
#  DEPLOYMENT
# =============================================================================

deploy_services() {
    echo_header "DEPLOYMENT"
    
    echo_step "1" "Changing to openDesk Edu directory..."
    cd "$OPENDESK_EDU"
    echo_success "Changed to $OPENDESK_EDU"
    echo ""
    
    echo_step "2" "Checking helmfile configuration..."
    if [[ -f "helmfile.yaml.gotmpl" ]]; then
        echo_success "helmfile.yaml.gotmpl found"
    else
        echo_error "helmfile.yaml.gotmpl not found!"
        return 1
    fi
    echo ""
    
    echo_step "3" "Running helmfile diff (dry-run)..."
    echo_info "This shows what changes will be applied without actually deploying."
    echo_command "helmfile --environment edu diff"
    echo ""
    echo_warning "IMPORTANT: Review the diff carefully before proceeding!"
    echo ""
    
    read -p "Do you want to run the diff now? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        if helmfile --environment edu diff 2>&1 | head -100; then
            echo ""
            echo_success "Diff completed"
        else
            echo ""
            echo_warning "Diff may have warnings or errors - review carefully"
        fi
    else
        echo_info "Skipping diff"
    fi
    echo ""
    
    echo_step "4" "Ready to deploy..."
    echo_info "When you're ready, run:"
    echo_command "helmfile --environment edu sync"
    echo ""
    echo_warning "This will deploy all services configured for the 'edu' environment"
    echo_warning "Including Stalwart, OpenCloud, and all other Edu services"
    echo ""
    
    read -p "Do you want to deploy now? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo ""
        echo_info "Deploying... (this may take several minutes)"
        echo ""
        if helmfile --environment edu sync; then
            echo ""
            echo_success "Deployment completed successfully!"
        else
            echo ""
            echo_error "Deployment encountered errors"
            return 1
        fi
    else
        echo_info "Deployment skipped"
        echo_info "To deploy later, run:"
        echo_command "cd $OPENDESK_EDU && helmfile --environment edu sync"
    fi
    echo ""
    
    return 0
}

# =============================================================================
#  POST-DEPLOYMENT VERIFICATION
# =============================================================================

verify_deployment() {
    echo_header "POST-DEPLOYMENT VERIFICATION"
    
    cd "$OPENDESK_EDU"
    
    echo_step "1" "Checking pod status..."
    echo_info "Waiting for pods to be ready..."
    kubectl get pods -n opendesk -l app.kubernetes.io/name=stalwart 2>/dev/null || echo_info "Stalwart pods not found yet"
    kubectl get pods -n opendesk -l app.kubernetes.io/name=opencloud 2>/dev/null || echo_info "OpenCloud pods not found yet"
    echo ""
    
    echo_step "2" "Checking service status..."
    kubectl get svc -n opendesk stalwart 2>/dev/null || echo_info "Stalwart service not found yet"
    kubectl get svc -n opendesk opencloud 2>/dev/null || echo_info "OpenCloud service not found yet"
    echo ""
    
    echo_step "3" "Checking ingress status..."
    kubectl get ingress -n opendesk stalwart 2>/dev/null || echo_info "Stalwart ingress not found yet"
    kubectl get ingress -n opendesk opencloud 2>/dev/null || echo_info "OpenCloud ingress not found yet"
    echo ""
    
    echo_step "4" "Health check URLs..."
    echo_info "Once pods are running, check health at:"
    echo "  Stalwart: https://mail.opendesk.hrz.uni-marburg.de/api/health"
    echo "  OpenCloud: https://files.opendesk.hrz.uni-marburg.de/status.php"
    echo ""
    
    echo_step "5" "Logs..."
    echo "To check logs:"
    echo_command "kubectl logs -f -n opendesk <stalwart-pod-name>"
    echo_command "kubectl logs -f -n opendesk <opencloud-pod-name>"
    echo ""
    
    return 0
}

# =============================================================================
#  MAIN INTERACTIVE MENU
# =============================================================================

show_menu() {
    clear
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║              Stalwart + OpenCloud Deployment Assistant              ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Please select an option:"
    echo ""
    echo "  1. Run all prerequisite checks"
    echo "  2. Generate and configure secrets"
    echo "  3. Check Keycloak OIDC client registration"
    echo "  4. Check DNS configuration"
    echo "  5. Deploy services (helmfile sync)"
    echo "  6. Verify deployment"
    echo "  7. Run all steps (recommended for first deployment)"
    echo "  8. Exit"
    echo ""
    echo -n "  Enter your choice [1-8]: "
}

# =============================================================================
#  MAIN
# =============================================================================

clear

if [[ $# -gt 0 ]]; then
    # Non-interactive mode
    case "$1" in
        prereqs|check|1)
            run_prerequisite_checks
            exit $?
            ;;
        secrets|2)
            generate_secrets
            exit $?
            ;;
        keycloak|oidc|3)
            check_keycloak_clients
            exit $?
            ;;
        dns|4)
            check_dns
            exit $?
            ;;
        deploy|sync|5)
            deploy_services
            exit $?
            ;;
        verify|6)
            verify_deployment
            exit $?
            ;;
        all|7)
            run_prerequisite_checks
            generate_secrets
            check_keycloak_clients
            check_dns
            deploy_services
            verify_deployment
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [prereqs|secrets|keycloak|dns|deploy|verify|all]"
            exit 1
            ;;
    esac
else
    # Interactive mode
    while true; do
        show_menu
        read choice
        case "$choice" in
            1)
                run_prerequisite_checks
                read -p "Press Enter to continue..."
                ;;
            2)
                generate_secrets
                read -p "Press Enter to continue..."
                ;;
            3)
                check_keycloak_clients
                read -p "Press Enter to continue..."
                ;;
            4)
                check_dns
                read -p "Press Enter to continue..."
                ;;
            5)
                deploy_services
                read -p "Press Enter to continue..."
                ;;
            6)
                verify_deployment
                read -p "Press Enter to continue..."
                ;;
            7)
                run_prerequisite_checks
                generate_secrets
                check_keycloak_clients
                check_dns
                deploy_services
                verify_deployment
                read -p "Press Enter to continue..."
                ;;
            8)
                echo ""
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac
    done
fi

#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Setup Keycloak SAML Identity Provider for DFN-AAI / eduGAIN Federation
# This script configures Keycloak to act as a SAML Service Provider
# consuming DFN-AAI/eduGAIN federation metadata

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default configuration
DEFAULT_KEYCLOAK_URL="http://localhost:8080"
DEFAULT_REALM="opendesk"
DEFAULT_ADMIN_USER="admin"
DEFAULT_ADMIN_PASSWORD="admin"

# DFN-AAI Metadata URLs
DFN_AAI_TEST_METADATA="https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-test-metadata.xml"
DFN_AAI_PROD_METADATA="https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-basic-metadata.xml"
DFN_AAI_EDUGAIN_METADATA="https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-edugain-metadata.xml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $*"; }

show_usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Description:
    Configure Keycloak as SAML Service Provider for DFN-AAI/eduGAIN federation.
    Creates identity provider configurations for test, production, or eduGAIN.

Required Options:
    -e, --environment ENV       Federation environment: test, production, or edugain
    -u, --keycloak-url URL      Keycloak base URL (e.g., https://id.example.edu)

Authentication:
    --admin-user USER           Keycloak admin username (default: admin)
    --admin-password PASS       Keycloak admin password (or set KC_ADMIN_PASSWORD)
    --client-id ID              Keycloak admin-cli client ID (default: admin-cli)
    --client-secret SECRET      Keycloak admin-cli client secret

Configuration:
    -r, --realm REALM           Keycloak realm (default: opendesk)
    --entity-id ID              SP entity ID (default: derived from keycloak-url)
    --acs-url URL               Assertion Consumer Service URL (default: derived)
    --slo-url URL               Single Logout Service URL (default: derived)
    --discovery-url URL         Federation discovery service URL (default: DFN-AAI)

Optional:
    --enable-discovery          Enable federation discovery service
    --trust-email               Trust email from IdP (default: true)
    --first-login-flow FLOW     First broker login flow (default: first broker login)
    --skip-mappers              Skip attribute mapper creation
    --dry-run                   Show commands without executing

Other:
    -h, --help                  Show this help message

Examples:
    # Configure test federation (recommended first)
    ${SCRIPT_NAME} -e test -u https://id.example.edu --admin-password secret

    # Configure production federation
    ${SCRIPT_NAME} -e production -u https://id.example.edu --admin-password secret

    # Configure eduGAIN (international)
    ${SCRIPT_NAME} -e edugain -u https://id.example.edu --admin-password secret

    # Dry run to see commands
    ${SCRIPT_NAME} -e test -u https://id.example.edu --dry-run

Notes:
    - Always test with DFN-AAI test federation first
    - Requires Keycloak admin credentials
    - Federation metadata is fetched from DFN-AAI servers
    - For production, use --trust-email to auto-verify user emails

DFN-AAI Metadata URLs:
    Test:       ${DFN_AAI_TEST_METADATA}
    Production: ${DFN_AAI_PROD_METADATA}
    eduGAIN:    ${DFN_AAI_EDUGAIN_METADATA}
EOF
}

# kcadm wrapper function
run_kcadm() {
    local args=("$@")

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo "[DRY-RUN] kcadm.sh ${args[*]}"
        return 0
    fi

    kcadm.sh "${args[@]}"
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."

    # Check kcadm is available
    if ! command -v kcadm.sh &> /dev/null; then
        log_error "kcadm.sh not found in PATH"
        log_error "Ensure Keycloak bin/ directory is in PATH"
        log_error "Typically: export PATH=\$PATH:/opt/keycloak/bin"
        exit 1
    fi

    # Check network connectivity
    if ! curl -sSf "${METADATA_URL}" -o /dev/null 2>/dev/null; then
        log_warn "Cannot reach federation metadata URL: ${METADATA_URL}"
        log_warn "Network connectivity to DFN-AAI may be required"
    fi

    log_info "Prerequisites check passed"
}

# Login to Keycloak
login_keycloak() {
    log_step "Logging in to Keycloak..."

    local server_url="${KEYCLOAK_URL}/"

    if [[ -n "${CLIENT_SECRET:-}" ]]; then
        # Service account login
        run_kcadm config credentials \
            --server "${server_url}" \
            --client "${CLIENT_ID}" \
            --client-secret "${CLIENT_SECRET}" \
            --realm master
    else
        # Admin user login
        run_kcadm config credentials \
            --server "${server_url}" \
            --user "${ADMIN_USER}" \
            --password "${ADMIN_PASSWORD}" \
            --client "${CLIENT_ID}" \
            --realm master
    fi

    log_info "Successfully logged in to Keycloak"
}

# Create SAML identity provider
create_identity_provider() {
    log_step "Creating SAML identity provider '${IDP_ALIAS}'..."

    # Check if IdP already exists
    if run_kcadm get identity-provider/instances/${IDP_ALIAS} -r ${REALM} 2>/dev/null; then
        log_warn "Identity provider '${IDP_ALIAS}' already exists"
        read -p "Update existing configuration? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping identity provider creation"
            return 0
        fi

        # Delete existing IdP
        run_kcadm delete identity-provider/instances/${IDP_ALIAS} -r ${REALM}
    fi

    # Create identity provider
    run_kcadm create identity-provider/instances -r ${REALM} \
        -s alias="${IDP_ALIAS}" \
        -s providerId=saml \
        -s enabled=true \
        -s trustEmail="${TRUST_EMAIL}" \
        -s firstBrokerLoginFlowAlias="${FIRST_LOGIN_FLOW}" \
        -s displayName="${IDP_DISPLAY_NAME}" \
        -s 'config.metadataDescriptorUrl='"${METADATA_URL}" \
        -s 'config.entityId='"${SP_ENTITY_ID}" \
        -s 'config.singleSignOnServiceUrl='"${METADATA_URL}" \
        -s 'config.nameIDPolicyFormat=urn:oasis:names:tc:SAML:2.0:nameid-format:persistent' \
        -s 'config.principalType=ATTRIBUTE' \
        -s 'config.principalAttribute=urn:mace:dir:attribute-def:eduPersonTargetedID' \
        -s 'config.signatureAlgorithm=RSA_SHA256' \
        -s 'config.wantAuthnRequestsSigned=true' \
        -s 'config.validateSignature=true' \
        -s 'config.xmlSigKeyInfoKeyNameStrategy=KEY_ID' \
        -s 'config.allowCreate=true'

    log_info "Identity provider '${IDP_ALIAS}' created successfully"
}

# Configure federation discovery
configure_discovery() {
    if [[ "${ENABLE_DISCOVERY:-false}" != "true" ]]; then
        return 0
    fi

    log_step "Configuring federation discovery service..."

    # Update IdP with discovery URL
    run_kcadm update identity-provider/instances/${IDP_ALIAS} -r ${REALM} \
        -s 'config.discoveryEndpoint='"${DISCOVERY_URL}"

    log_info "Federation discovery configured"
}

# Verify configuration
verify_configuration() {
    log_step "Verifying identity provider configuration..."

    # Get IdP configuration
    local idp_config
    idp_config=$(run_kcadm get identity-provider/instances/${IDP_ALIAS} -r ${REALM})

    if [[ -z "${idp_config}" ]]; then
        log_error "Failed to retrieve identity provider configuration"
        return 1
    fi

    # Verify key settings
    echo "${idp_config}" | grep -q '"enabled" : true' || log_warn "IdP may not be enabled"

    log_info "Identity provider configuration verified"
    log_info ""
    log_info "Configuration summary:"
    log_info "  Alias: ${IDP_ALIAS}"
    log_info "  Display Name: ${IDP_DISPLAY_NAME}"
    log_info "  Realm: ${REALM}"
    log_info "  Metadata URL: ${METADATA_URL}"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Run setup-attribute-mappers.sh to configure attribute mapping"
    log_info "  2. Run setup-role-mapper.sh to configure role assignment"
    log_info "  3. Test login via DFN-AAI discovery service"
}

# Main function
main() {
    # Initialize variables
    local environment=""
    local keycloak_url=""

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                environment="$2"
                shift 2
                ;;
            -u|--keycloak-url)
                KEYCLOAK_URL="$2"
                shift 2
                ;;
            -r|--realm)
                REALM="$2"
                shift 2
                ;;
            --admin-user)
                ADMIN_USER="$2"
                shift 2
                ;;
            --admin-password)
                ADMIN_PASSWORD="$2"
                shift 2
                ;;
            --client-id)
                CLIENT_ID="$2"
                shift 2
                ;;
            --client-secret)
                CLIENT_SECRET="$2"
                shift 2
                ;;
            --entity-id)
                SP_ENTITY_ID="$2"
                shift 2
                ;;
            --acs-url)
                ACS_URL="$2"
                shift 2
                ;;
            --slo-url)
                SLO_URL="$2"
                shift 2
                ;;
            --discovery-url)
                DISCOVERY_URL="$2"
                shift 2
                ;;
            --enable-discovery)
                ENABLE_DISCOVERY="true"
                shift
                ;;
            --trust-email)
                TRUST_EMAIL="true"
                shift
                ;;
            --first-login-flow)
                FIRST_LOGIN_FLOW="$2"
                shift 2
                ;;
            --skip-mappers)
                SKIP_MAPPERS="true"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Validate required parameters
    if [[ -z "${environment}" ]]; then
        log_error "Environment is required (use -e or --environment)"
        show_usage
        exit 1
    fi

    if [[ -z "${KEYCLOAK_URL}" ]]; then
        log_error "Keycloak URL is required (use -u or --keycloak-url)"
        show_usage
        exit 1
    fi

    # Set environment-specific configuration
    case "${environment}" in
        test)
            METADATA_URL="${DFN_AAI_TEST_METADATA}"
            IDP_ALIAS="dfn-aai-test"
            IDP_DISPLAY_NAME="Mit Ihrer Einrichtung anmelden (Test)"
            DISCOVERY_URL="${DISCOVERY_URL:-https://test.discovery.aai.dfn.de/}"
            ;;
        production)
            METADATA_URL="${DFN_AAI_PROD_METADATA}"
            IDP_ALIAS="dfn-aai"
            IDP_DISPLAY_NAME="Mit Ihrer Einrichtung anmelden"
            DISCOVERY_URL="${DISCOVERY_URL:-https://discovery.aai.dfn.de/}"
            ;;
        edugain)
            METADATA_URL="${DFN_AAI_EDUGAIN_METADATA}"
            IDP_ALIAS="edugain"
            IDP_DISPLAY_NAME="Sign in with your institution (eduGAIN)"
            DISCOVERY_URL="${DISCOVERY_URL:-https://discovery.edugain.org/}"
            ;;
        *)
            log_error "Invalid environment: ${environment}"
            log_error "Must be: test, production, or edugain"
            exit 1
            ;;
    esac

    # Set defaults
    ADMIN_USER="${ADMIN_USER:-${DEFAULT_ADMIN_USER}}"
    ADMIN_PASSWORD="${ADMIN_PASSWORD:-${KC_ADMIN_PASSWORD:-${DEFAULT_ADMIN_PASSWORD}}}"
    CLIENT_ID="${CLIENT_ID:-admin-cli}"
    REALM="${REALM:-${DEFAULT_REALM}}"
    TRUST_EMAIL="${TRUST_EMAIL:-true}"
    FIRST_LOGIN_FLOW="${FIRST_LOGIN_FLOW:-first broker login}"
    SP_ENTITY_ID="${SP_ENTITY_ID:-${KEYCLOAK_URL}/realms/${REALM}}"
    ACS_URL="${ACS_URL:-${KEYCLOAK_URL}/realms/${REALM}/broker/saml/endpoint}"
    SLO_URL="${SLO_URL:-${KEYCLOAK_URL}/realms/${REALM}/broker/saml/endpoint}"

    # Execute setup
    check_prerequisites
    login_keycloak
    create_identity_provider
    configure_discovery
    verify_configuration

    log_info ""
    log_info "Setup complete! Identity provider '${IDP_ALIAS}' is ready."
}

# Run main function
main "${@}"

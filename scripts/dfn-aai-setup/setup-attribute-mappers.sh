#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Setup SAML Attribute Mappers for DFN-AAI / eduGAIN Federation
# Creates attribute mappers that transform incoming SAML attributes
# to Keycloak user attributes

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default configuration
DEFAULT_KEYCLOAK_URL="http://localhost:8080"
DEFAULT_REALM="opendesk"
DEFAULT_ADMIN_USER="admin"
DEFAULT_ADMIN_PASSWORD="admin"

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

# Attribute mapper definitions
# Format: name|saml_attribute|user_attribute|sync_mode
REQUIRED_MAPPERS=(
    # Required DFN-AAI attributes (5 mandatory)
    "email-mapper|urn:mace:dir:attribute-def:mail|email|INHERIT"
    "username-mapper|urn:mace:dir:attribute-def:eduPersonPrincipalName|username|INHERIT"
    "displayname-mapper|urn:mace:dir:attribute-def:displayName|displayName|INHERIT"
    "affiliation-mapper|urn:mace:dir:attribute-def:eduPersonAffiliation|affiliation|INHERIT"
    "persistent-id-mapper|urn:mace:dir:attribute-def:eduPersonTargetedID|persistentId|INHERIT"
)

OPTIONAL_MAPPERS=(
    # Optional but recommended attributes
    "firstname-mapper|urn:mace:dir:attribute-def:givenName|firstName|INHERIT"
    "lastname-mapper|urn:mace:dir:attribute-def:sn|lastName|INHERIT"
    "scoped-affiliation-mapper|urn:mace:dir:attribute-def:eduPersonScopedAffiliation|scopedAffiliation|INHERIT"
    "unique-id-mapper|urn:mace:dir:attribute-def:eduPersonUniqueID|uniqueId|INHERIT"
    "home-org-mapper|urn:oid:1.3.6.1.4.1.25178.1.2.9|homeOrganization|INHERIT"
)

show_usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Description:
    Create SAML attribute mappers for DFN-AAI/eduGAIN federation.
    Maps incoming SAML attributes to Keycloak user attributes.

Required:
    -p, --idp-alias ALIAS       Identity provider alias (e.g., dfn-aai-test, dfn-aai, edugain)
    -u, --keycloak-url URL      Keycloak base URL

Authentication:
    --admin-user USER           Keycloak admin username (default: admin)
    --admin-password PASS       Keycloak admin password (or set KC_ADMIN_PASSWORD)

Configuration:
    -r, --realm REALM           Keycloak realm (default: opendesk)
    --required-only             Only create required mappers (5 mandatory attributes)
    --include-optional          Include optional mappers (5 additional attributes)

Optional:
    --dry-run                   Show commands without executing
    --list                      List existing mappers
    --delete-existing           Delete existing mappers before creating

Other:
    -h, --help                  Show this help message

Examples:
    # Create all mappers for test federation
    ${SCRIPT_NAME} -p dfn-aai-test -u https://id.example.edu --include-optional

    # Create only required mappers
    ${SCRIPT_NAME} -p dfn-aai -u https://id.example.edu --required-only

    # List existing mappers
    ${SCRIPT_NAME} -p dfn-aai-test -u https://id.example.edu --list

Attribute Mapping Reference:
    Required (DFN-AAI):
      mail                     → email
      eduPersonPrincipalName   → username
      displayName              → displayName
      eduPersonAffiliation     → affiliation
      eduPersonTargetedID      → persistentId

    Optional (Recommended):
      givenName                → firstName
      sn                       → lastName
      eduPersonScopedAffiliation → scopedAffiliation
      eduPersonUniqueID        → uniqueId
      schacHomeOrganization    → homeOrganization
EOF
}

# kcadm wrapper
run_kcadm() {
    local args=("$@")

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo "[DRY-RUN] kcadm.sh ${args[*]}"
        return 0
    fi

    kcadm.sh "${args[@]}"
}

# Login to Keycloak
login_keycloak() {
    log_step "Logging in to Keycloak..."

    local server_url="${KEYCLOAK_URL}/"

    if [[ -n "${CLIENT_SECRET:-}" ]]; then
        run_kcadm config credentials \
            --server "${server_url}" \
            --client "${CLIENT_ID}" \
            --client-secret "${CLIENT_SECRET}" \
            --realm master
    else
        run_kcadm config credentials \
            --server "${server_url}" \
            --user "${ADMIN_USER}" \
            --password "${ADMIN_PASSWORD}" \
            --client "${CLIENT_ID}" \
            --realm master
    fi

    log_info "Successfully logged in to Keycloak"
}

# Create attribute mapper
create_mapper() {
    local mapper_def="$1"

    # Parse mapper definition
    IFS='|' read -r name saml_attr user_attr sync_mode <<< "${mapper_def}"

    log_step "Creating mapper: ${name}"
    log_info "  SAML Attribute: ${saml_attr}"
    log_info "  User Attribute: ${user_attr}"
    log_info "  Sync Mode: ${sync_mode}"

    # Check if mapper already exists
    local existing
    existing=$(run_kcadm get identity-provider/instances/${IDP_ALIAS}/mappers -r ${REALM} 2>/dev/null | \
        grep -o "\"name\" : \"${name}\"" || true)

    if [[ -n "${existing}" ]]; then
        if [[ "${DELETE_EXISTING:-false}" == "true" ]]; then
            log_warn "Deleting existing mapper: ${name}"
            local mapper_id
            mapper_id=$(run_kcadm get identity-provider/instances/${IDP_ALIAS}/mappers -r ${REALM} | \
                jq -r ".[] | select(.name == \"${name}\") | .id")
            if [[ -n "${mapper_id}" ]]; then
                run_kcadm delete identity-provider/instances/${IDP_ALIAS}/mappers/${mapper_id} -r ${REALM}
            fi
        else
            log_warn "Mapper '${name}' already exists, skipping"
            return 0
        fi
    fi

    # Create mapper
    run_kcadm create identity-provider/instances/${IDP_ALIAS}/mappers \
        -r ${REALM} \
        -s name="${name}" \
        -s identityProviderMapper=saml-user-attribute-idp-mapper \
        -s identityProviderAlias="${IDP_ALIAS}" \
        -s 'config.syncMode='"${sync_mode}" \
        -s 'config.attribute='"${saml_attr}" \
        -s 'config.user.attribute='"${user_attr}"

    log_info "Mapper '${name}' created successfully"
}

# List existing mappers
list_mappers() {
    log_step "Listing existing mappers for '${IDP_ALIAS}'..."

    local mappers
    mappers=$(run_kcadm get identity-provider/instances/${IDP_ALIAS}/mappers -r ${REALM} 2>/dev/null)

    if [[ -z "${mappers}" || "${mappers}" == "[]" ]]; then
        log_info "No mappers configured for '${IDP_ALIAS}'"
        return 0
    fi

    echo "${mappers}" | jq -r '.[] | "  \(.name): \(.config.attribute) → \(.config.user.attribute)"'
    log_info ""
}

# Verify mappers
verify_mappers() {
    log_step "Verifying attribute mappers..."

    local mappers
    mappers=$(run_kcadm get identity-provider/instances/${IDP_ALIAS}/mappers -r ${REALM} 2>/dev/null)
    local count
    count=$(echo "${mappers}" | jq -r 'length' 2>/dev/null || echo "0")

    log_info "Total mappers configured: ${count}"

    # Verify required mappers
    local missing=0
    for mapper_def in "${REQUIRED_MAPPERS[@]}"; do
        IFS='|' read -r name _ _ <<< "${mapper_def}"
        if ! echo "${mappers}" | grep -q "\"name\" : \"${name}\""; then
            log_warn "Missing required mapper: ${name}"
            missing=$((missing + 1))
        fi
    done

    if [[ ${missing} -gt 0 ]]; then
        log_warn "${missing} required mappers are missing"
        return 1
    fi

    log_info "All required mappers are configured"

    log_info ""
    log_info "Next steps:"
    log_info "  1. Run setup-role-mapper.sh to configure role assignment"
    log_info "  2. Test login with DFN-AAI test IdP"
    log_info "  3. Verify attribute mapping with SAML Tracer"
}

# Main function
main() {
    # Initialize variables
    local list_only="false"

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--idp-alias)
                IDP_ALIAS="$2"
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
            --required-only)
                REQUIRED_ONLY="true"
                shift
                ;;
            --include-optional)
                INCLUDE_OPTIONAL="true"
                shift
                ;;
            --list)
                list_only="true"
                shift
                ;;
            --delete-existing)
                DELETE_EXISTING="true"
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
    if [[ -z "${IDP_ALIAS:-}" ]]; then
        log_error "IdP alias is required (use -p or --idp-alias)"
        show_usage
        exit 1
    fi

    if [[ -z "${KEYCLOAK_URL:-}" ]]; then
        log_error "Keycloak URL is required (use -u or --keycloak-url)"
        show_usage
        exit 1
    fi

    # Set defaults
    ADMIN_USER="${ADMIN_USER:-${DEFAULT_ADMIN_USER}}"
    ADMIN_PASSWORD="${ADMIN_PASSWORD:-${KC_ADMIN_PASSWORD:-${DEFAULT_ADMIN_PASSWORD}}}"
    CLIENT_ID="${CLIENT_ID:-admin-cli}"
    REALM="${REALM:-${DEFAULT_REALM}}"

    # Login to Keycloak
    login_keycloak

    # List only mode
    if [[ "${list_only}" == "true" ]]; then
        list_mappers
        exit 0
    fi

    # Create required mappers
    for mapper_def in "${REQUIRED_MAPPERS[@]}"; do
        create_mapper "${mapper_def}"
    done

    # Create optional mappers if requested
    if [[ "${INCLUDE_OPTIONAL:-false}" == "true" ]]; then
        for mapper_def in "${OPTIONAL_MAPPERS[@]}"; do
            create_mapper "${mapper_def}"
        done
    fi

    # Verify configuration
    verify_mappers

    log_info ""
    log_info "Attribute mappers setup complete!"
}

# Run main function
main "${@}"

#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Setup Role Assignment Mapper for DFN-AAI / eduGAIN Federation
# Creates a script mapper that assigns roles based on eduPersonAffiliation

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

# Role mapping script (JavaScript for Keycloak)
ROLE_MAPPER_SCRIPT='
/**
 * DFN-AAI / eduGAIN Role Assignment Mapper
 * Maps eduPersonAffiliation values to Keycloak realm roles
 *
 * Affiliation Mapping (per DFN-AAI spec):
 *   faculty, teacher → instructor
 *   staff, employee  → staff
 *   student          → student
 *   member           → member
 *   affiliate        → affiliate
 *   alum             → alumni
 */

var affiliation = user.getAttribute("affiliation");
if (!affiliation) {
    affiliation = [];
}

// Parse display name into first/last name if not provided separately
var displayName = user.getSingleAttribute("displayName");
var givenName = user.getSingleAttribute("firstName");
var sn = user.getSingleAttribute("lastName");

if (displayName && !givenName && !sn) {
    var parts = displayName.trim().split(/\s+/);
    if (parts.length >= 2) {
        user.setFirstName(parts[0]);
        user.setLastName(parts.slice(1).join(" "));
    } else {
        user.setLastName(parts[0]);
    }
}

// Grant roles based on affiliation
var rolesToGrant = [];
for each (var aff in affiliation) {
    switch (aff.toLowerCase()) {
        case "faculty":
        case "teacher":
            rolesToGrant.push("instructor");
            break;
        case "staff":
        case "employee":
            rolesToGrant.push("staff");
            break;
        case "student":
            rolesToGrant.push("student");
            break;
        case "member":
            rolesToGrant.push("member");
            break;
        case "affiliate":
            rolesToGrant.push("affiliate");
            break;
        case "alum":
            rolesToGrant.push("alumni");
            break;
    }
}

// Remove duplicates
var uniqueRoles = [];
for each (var role in rolesToGrant) {
    if (uniqueRoles.indexOf(role) === -1) {
        uniqueRoles.push(role);
    }
}

// Grant realm roles
for each (var role in uniqueRoles) {
    try {
        user.grantRole(role);
        logger.info("Granted role: " + role + " to user based on affiliation");
    } catch (e) {
        // Role may not exist, log warning
        logger.warn("Could not grant role " + role + ": " + e.message);
    }
}

// Set email as verified (trust from federation)
user.setEmailVerified(true);

logger.info("Role assignment complete for user: " + user.getUsername());
'

# Required realm roles (must exist in Keycloak)
REQUIRED_ROLES=(
    "student"
    "instructor"
    "staff"
    "member"
    "affiliate"
    "alumni"
)

show_usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Description:
    Create role assignment mapper for DFN-AAI/eduGAIN federation.
    Maps eduPersonAffiliation values to Keycloak realm roles.

Required:
    -p, --idp-alias ALIAS       Identity provider alias (e.g., dfn-aai-test)
    -u, --keycloak-url URL      Keycloak base URL

Authentication:
    --admin-user USER           Keycloak admin username (default: admin)
    --admin-password PASS       Keycloak admin password (or set KC_ADMIN_PASSWORD)

Configuration:
    -r, --realm REALM           Keycloak realm (default: opendesk)

Optional:
    --create-roles              Create required realm roles if missing
    --dry-run                   Show commands without executing
    --show-script               Display the role mapper script

Other:
    -h, --help                  Show this help message

Role Mapping Rules:
    eduPersonAffiliation    Keycloak Role
    ─────────────────────   ─────────────
    faculty, teacher     →  instructor
    staff, employee      →  staff
    student              →  student
    member               →  member
    affiliate            →  affiliate
    alum                 →  alumni

Examples:
    # Create role mapper and required roles
    ${SCRIPT_NAME} -p dfn-aai-test -u https://id.example.edu --create-roles

    # Display the mapper script
    ${SCRIPT_NAME} --show-script

    # Dry run
    ${SCRIPT_NAME} -p dfn-aai-test -u https://id.example.edu --dry-run

Notes:
    - Required realm roles must exist before users can log in
    - Use --create-roles to automatically create missing roles
    - Email is automatically marked as verified (trusted from federation)
    - Display name is split into first/last name if not provided separately
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

# Create realm roles if they don't exist
create_required_roles() {
    log_step "Creating required realm roles..."

    for role in "${REQUIRED_ROLES[@]}"; do
        # Check if role exists
        if run_kcadm get roles/${role} -r ${REALM} 2>/dev/null | grep -q '"name"'; then
            log_info "Role '${role}' already exists"
        else
            log_info "Creating role: ${role}"
            run_kcadm create roles -r ${REALM} \
                -s name="${role}" \
                -s description="Role for ${role} users from DFN-AAI federation"
        fi
    done

    log_info "Required roles verified"
}

# Create role assignment mapper
create_role_mapper() {
    log_step "Creating role assignment mapper..."

    local mapper_name="affiliation-to-role-mapper"

    # Check if mapper already exists
    local existing
    existing=$(run_kcadm get identity-provider/instances/${IDP_ALIAS}/mappers -r ${REALM} 2>/dev/null | \
        grep -o "\"name\" : \"${mapper_name}\"" || true)

    if [[ -n "${existing}" ]]; then
        if [[ "${DELETE_EXISTING:-false}" == "true" ]]; then
            log_warn "Deleting existing mapper: ${mapper_name}"
            local mapper_id
            mapper_id=$(run_kcadm get identity-provider/instances/${IDP_ALIAS}/mappers -r ${REALM} | \
                jq -r ".[] | select(.name == \"${mapper_name}\") | .id")
            if [[ -n "${mapper_id}" ]]; then
                run_kcadm delete identity-provider/instances/${IDP_ALIAS}/mappers/${mapper_id} -r ${REALM}
            fi
        else
            log_warn "Role mapper '${mapper_name}' already exists"
            return 0
        fi
    fi

    # Create the script mapper
    # Note: Keycloak requires the script to be base64 encoded in some versions
    run_kcadm create identity-provider/instances/${IDP_ALIAS}/mappers \
        -r ${REALM} \
        -s name="${mapper_name}" \
        -s identityProviderMapper=saml-advanced-attribute-idp-mapper \
        -s identityProviderAlias="${IDP_ALIAS}" \
        -s 'config.syncMode=INHERIT' \
        -s 'config.script='"${ROLE_MAPPER_SCRIPT}"

    log_info "Role assignment mapper created successfully"
}

# Verify configuration
verify_configuration() {
    log_step "Verifying role mapper configuration..."

    # Check for required roles
    local missing_roles=0
    for role in "${REQUIRED_ROLES[@]}"; do
        if ! run_kcadm get roles/${role} -r ${REALM} 2>/dev/null | grep -q '"name"'; then
            log_warn "Missing required role: ${role}"
            missing_roles=$((missing_roles + 1))
        fi
    done

    if [[ ${missing_roles} -gt 0 ]]; then
        log_warn "${missing_roles} required roles are missing"
        log_warn "Run with --create-roles to create missing roles"
    fi

    # Check for mapper
    local mapper_name="affiliation-to-role-mapper"
    if run_kcadm get identity-provider/instances/${IDP_ALIAS}/mappers -r ${REALM} 2>/dev/null | \
        grep -q "\"name\" : \"${mapper_name}\""; then
        log_info "Role mapper '${mapper_name}' is configured"
    else
        log_warn "Role mapper '${mapper_name}' is not configured"
    fi

    log_info ""
    log_info "Configuration summary:"
    log_info "  Realm: ${REALM}"
    log_info "  IdP Alias: ${IDP_ALIAS}"
    log_info "  Required Roles: ${REQUIRED_ROLES[*]}"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Test login with DFN-AAI test IdP"
    log_info "  2. Verify role assignment with test users"
    log_info "  3. Check Keycloak logs for role assignment messages"
}

# Main function
main() {
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
            --create-roles)
                CREATE_ROLES="true"
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
            --show-script)
                echo "${ROLE_MAPPER_SCRIPT}"
                exit 0
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

    # Create roles if requested
    if [[ "${CREATE_ROLES:-false}" == "true" ]]; then
        create_required_roles
    fi

    # Create role mapper
    create_role_mapper

    # Verify configuration
    verify_configuration

    log_info ""
    log_info "Role mapper setup complete!"
}

# Run main function
main "${@}"

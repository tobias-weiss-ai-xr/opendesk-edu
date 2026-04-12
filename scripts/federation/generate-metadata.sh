#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0
#
# Generate SAML 2.0 Service Provider metadata for Keycloak federation
# Compatible with DFN-AAI / eduGAIN federation requirements

set -euo pipefail

# Configuration defaults
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
DEFAULT_DOMAIN="opendesk.example.com"
DEFAULT_ENTITY_ID="https://id.${DEFAULT_DOMAIN}/realms/opendesk"
DEFAULT_CERT_PATH="./sp-cert.pem"
DEFAULT_KEY_PATH="./sp-key.pem"
DEFAULT_ORG_NAME="openDesk Edu"
DEFAULT_ORG_DISPLAY="University openDesk Education Platform"
DEFAULT_ORG_URL="https://${DEFAULT_DOMAIN}"
DEFAULT_TECH_SUPPORT="support@${DEFAULT_DOMAIN}"

# Output defaults
OUTPUT_FILE="sp-metadata.xml"
VALID_DAYS=365

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_usage() {
    cat <<EOF
${YELLOW}Usage:${NC}
    ${SCRIPT_NAME} [OPTIONS]

${YELLOW}Description:${NC}
    Generate SAML 2.0 Service Provider metadata XML for Keycloak integration
    with DFN-AAI / eduGAIN federation. Supports configurable entityId, certificates,
    and organization information.

${YELLOW}Required Options:${NC}
    -d, --domain DOMAIN              Base domain (e.g., opendesk.example.com)

${YELLOW}Optional Options:${NC}
    -e, --entity-id ENTITY_ID        SAML entityID (default: https://id.<domain>/realms/opendesk)
    -c, --cert-path PATH             Path to SP X.509 certificate (PEM format)
    -k, --key-path PATH              Path to SP private key (PEM format)
    -o, --output-file FILE           Output metadata file (default: sp-metadata.xml)
    --org-name NAME                  Organization name (default: openDesk Edu)
    --org-display DISPLAY            Organization display name
    --org-url URL                    Organization URL
    --tech-email EMAIL               Technical support email
    --generate-cert                  Generate self-signed certificate (for testing)
    --cert-days DAYS                 Certificate validity days (default: 365)
    --help                           Show this help message

${YELLOW}Examples:${NC}
    # Generate with existing certificates
    ${SCRIPT_NAME} -d opendesk.example.com \\
        -c /path/to/sp-cert.pem -k /path/to/sp-key.pem \\
        -o /output/metadata.xml

    # Generate with self-signed certificate (for testing)
    ${SCRIPT_NAME} -d opendesk.example.com --generate-cert

    # Generate with custom organization info
    ${SCRIPT_NAME} -d university.edu \\
        --org-name "University IT" \\
        --org-display "University Education Platform" \\
        --tech-email it@university.edu

${YELLOW}Notes:${NC}
    - Generated metadata includes required DFN-AAI attributes:
      • eduPersonAffiliation
      • mail
      • displayName
      • persistentId
    - Certificate must be in PEM format (BEGIN CERTIFICATE)
    - Private key must be in PEM format (BEGIN PRIVATE KEY or BEGIN RSA PRIVATE KEY)
    - For production: Use CA-signed certificates from your university PKI

EOF
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

generate_self_signed_cert() {
    local cert_file="$1"
    local key_file="$2"
    local domain="$3"

    log_info "Generating self-signed certificate for ${domain}..."

    if ! command -v openssl &> /dev/null; then
        log_error "openssl is required to generate self-signed certificate"
        log_error "Install openssl or provide existing certificate paths"
        exit 1
    fi

    openssl req -x509 -newkey rsa:2048 -keyout "${key_file}" -out "${cert_file}" \
        -days "${VALID_DAYS}" -nodes \
        -subj "/C=DE/ST=Berlin/L=Berlin/O=${DEFAULT_ORG_NAME}/CN=${domain}" \
        2>/dev/null

    if [[ ! -f "${cert_file}" ]] || [[ ! -f "${key_file}" ]]; then
        log_error "Failed to generate self-signed certificate"
        exit 1
    fi

    log_info "Self-signed certificate created:"
    log_info "  Certificate: ${cert_file}"
    log_info "  Private Key: ${key_file}"
}

extract_cert_info() {
    local cert_file="$1"
    local info_type="$2"

    if ! command -v openssl &> /dev/null; then
        log_error "openssl is required to extract certificate information"
        exit 1
    fi

    openssl x509 -in "${cert_file}" -noout -"${info_type}" 2>/dev/null
}

generate_metadata() {
    local domain="${1}"
    local entity_id="${2}"
    local cert_file="${3}"
    local org_name="${4}"
    local org_display="${5}"
    local org_url="${6}"
    local tech_email="${7}"

    log_info "Generating SAML 2.0 SP metadata..."
    log_info "  Entity ID: ${entity_id}"
    log_info "  Domain: ${domain}"
    log_info "  Certificate: ${cert_file}"

    # Extract certificate data
    local cert_data
    cert_data=$(<"${cert_file}")

    # Generate SAML metadata XML
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!--
SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0

SAML 2.0 Service Provider Metadata for DFN-AAI / eduGAIN Federation
Generated: $(date -Iseconds)
-->
<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
                     xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
                     xmlns:mdattr="urn:oasis:names:tc:SAML:metadata:attribute"
                     xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                     entityID="${entity_id}">

  <md:SPSSODescriptor AuthnRequestsSigned="true"
                      WantAssertionsSigned="true"
                      protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <!-- Keycloak SSO Endpoint (SAML 2.0) -->
    <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
                            Location="${entity_id}/protocol/saml"/>
    <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
                            Location="${entity_id}/protocol/saml"/>
    <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
                            Location="${entity_id}/protocol/saml"/>

    <!-- Keycloak Logout Endpoints -->
    <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
                            Location="${entity_id}/protocol/saml"/>
    <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
                            Location="${entity_id}/protocol/saml"/>
    <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
                            Location="${entity_id}/protocol/saml"/>

    <!-- Keycloak Assertion Consumer Service -->
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
                                  Location="${entity_id}/protocol/saml"
                                  index="0" isDefault="true"/>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact"
                                  Location="${entity_id}/protocol/saml"
                                  index="1"/>

    <!-- SP Signing/Encryption Certificate -->
    <md:KeyDescriptor use="signing">
      <ds:KeyInfo>
        <ds:X509Data>
          <ds:X509Certificate>
$(echo "${cert_data}" | sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' | grep -v 'BEGIN\|END' | sed 's/^/            /')
          </ds:X509Certificate>
        </ds:X509Data>
      </ds:KeyInfo>
    </md:KeyDescriptor>

    <md:KeyDescriptor use="encryption">
      <ds:KeyInfo>
        <ds:X509Data>
          <ds:X509Certificate>
$(echo "${cert_data}" | sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' | grep -v 'BEGIN\|END' | sed 's/^/            /')
          </ds:X509Certificate>
        </ds:X509Data>
      </ds:KeyInfo>
    </md:KeyDescriptor>

    <!-- Organization Information -->
    <md:Organization>
      <md:OrganizationName xml:lang="en">${org_name}</md:OrganizationName>
      <md:OrganizationDisplayName xml:lang="en">${org_display}</md:OrganizationDisplayName>
      <md:OrganizationURL xml:lang="en">${org_url}</md:OrganizationURL>
    </md:Organization>

    <!-- Contact Information -->
    <md:ContactPerson contactType="technical">
      <md:GivenName>System Administration</md:GivenName>
      <md:EmailAddress>${tech_email}</md:EmailAddress>
    </md:ContactPerson>

    <!-- Required DFN-AAI / eduGAIN Attributes -->
    <md:AttributeConsumingService index="0">
      <md:ServiceName xml:lang="en">${org_display}</md:ServiceName>
      <md:ServiceDescription xml:lang="en">openDesk Edu Platform SAML Integration</md:ServiceDescription>

      <!-- eduPersonAffiliation: Student, faculty, staff, member, etc. -->
      <md:RequestedAttribute FriendlyName="affiliation"
                              Name="urn:mace:dir:attribute-def:eduPersonAffiliation"
                              NameFormat="urn:mace:shibboleth:1.0:attributeNamespace:uri"
                              isRequired="true"/>

      <!-- mail: User's primary email address -->
      <md:RequestedAttribute FriendlyName="mail"
                              Name="urn:mace:dir:attribute-def:mail"
                              NameFormat="urn:mace:shibboleth:1.0:attributeNamespace:uri"
                              isRequired="true"/>

      <!-- displayName: User's preferred display name -->
      <md:RequestedAttribute FriendlyName="displayName"
                              Name="urn:mace:dir:attribute-def:displayName"
                              NameFormat="urn:mace:shibboleth:1.0:attributeNamespace:uri"
                              isRequired="true"/>

      <!-- persistentId: Persistent, opaque identifier for the user -->
      <md:RequestedAttribute FriendlyName="persistentID"
                              Name="urn:mace:dir:attribute-def:eduPersonPrincipalName"
                              NameFormat="urn:mace:shibboleth:1.0:attributeNamespace:uri"
                              isRequired="true"/>

      <!-- Optional: eduPersonEntitlement for service access -->
      <md:RequestedAttribute FriendlyName="entitlement"
                              Name="urn:mace:dir:attribute-def:eduPersonEntitlement"
                              NameFormat="urn:mace:shibboleth:1.0:attributeNamespace:uri"
                              isRequired="false"/>

      <!-- Optional: eduPersonScopedAffiliation for access control -->
      <md:RequestedAttribute FriendlyName="scopedAffiliation"
                              Name="urn:mace:dir:attribute-def:eduPersonScopedAffiliation"
                              NameFormat="urn:mace:shibboleth:1.0:attributeNamespace:uri"
                              isRequired="false"/>

    </md:AttributeConsumingService>

  </md:SPSSODescriptor>

</md:EntityDescriptor>
EOF
}

main() {
    # Initialize variables
    local domain=""
    local entity_id=""
    local cert_path="${DEFAULT_CERT_PATH}"
    local key_path="${DEFAULT_KEY_PATH}"
    local output_file="${OUTPUT_FILE}"
    local org_name="${DEFAULT_ORG_NAME}"
    local org_display="${DEFAULT_ORG_DISPLAY}"
    local org_url="${DEFAULT_ORG_URL}"
    local tech_email="${DEFAULT_TECH_SUPPORT}"
    local generate_cert=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--domain)
                domain="$2"
                shift 2
                ;;
            -e|--entity-id)
                entity_id="$2"
                shift 2
                ;;
            -c|--cert-path)
                cert_path="$2"
                shift 2
                ;;
            -k|--key-path)
                key_path="$2"
                shift 2
                ;;
            -o|--output-file)
                output_file="$2"
                shift 2
                ;;
            --org-name)
                org_name="$2"
                shift 2
                ;;
            --org-display)
                org_display="$2"
                shift 2
                ;;
            --org-url)
                org_url="$2"
                shift 2
                ;;
            --tech-email)
                tech_email="$2"
                shift 2
                ;;
            --generate-cert)
                generate_cert=true
                shift
                ;;
            --cert-days)
                VALID_DAYS="$2"
                shift 2
                ;;
            --help)
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
    if [[ -z "${domain}" ]]; then
        log_error "Domain is required (use -d or --domain)"
        show_usage
        exit 1
    fi

    # Set defaults based on domain
    if [[ -z "${entity_id}" ]]; then
        entity_id="https://id.${domain}/realms/opendesk"
        log_info "Using default entity ID: ${entity_id}"
    fi

    if [[ -z "${org_url}" ]]; then
        org_url="https://${domain}"
    fi

    if [[ -z "${tech_email}" ]]; then
        tech_email="support@${domain}"
    fi

    # Generate self-signed certificate if requested
    if [[ "${generate_cert}" == true ]]; then
        generate_self_signed_cert "${cert_path}" "${key_path}" "${domain}"
    else
        # Validate certificate exists
        if [[ ! -f "${cert_path}" ]]; then
            log_error "Certificate file not found: ${cert_path}"
            log_error "Use --generate-cert to create a self-signed certificate for testing"
            exit 1
        fi

        # Validate certificate format
        cert_content=$(<"${cert_path}")
        if ! echo "${cert_content}" | grep -q "BEGIN CERTIFICATE"; then
            log_error "Invalid certificate format: ${cert_path}"
            log_error "Certificate must be in PEM format (BEGIN CERTIFICATE)"
            exit 1
        fi

        # Show certificate info
        if command -v openssl &> /dev/null; then
            local cert_subject
            cert_subject=$(extract_cert_info "${cert_path}" "subject")
            log_info "Certificate subject: ${cert_subject}"
        fi
    fi

    # Generate metadata
    generate_metadata \
        "${domain}" \
        "${entity_id}" \
        "${cert_path}" \
        "${org_name}" \
        "${org_display}" \
        "${org_url}" \
        "${tech_email}" > "${output_file}"

    log_info "Metadata successfully generated: ${output_file}"
    log_info ""
    log_info "Next steps:"
    log_info "1. Review the generated metadata for accuracy"
    log_info "2. Upload metadata to DFN-AAI registration portal"
    log_info "3. Configure Keycloak to trust DFN-AAI federation"
    log_info "4. Configure Shibboleth SP services (ILIAS, Moodle) to use existing IdP"

    exit 0
}

# Run main function
main "${@}"

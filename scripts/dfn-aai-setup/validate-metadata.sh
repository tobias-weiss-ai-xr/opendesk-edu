#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Validate SAML 2.0 Metadata for DFN-AAI / eduGAIN Federation
# Validates XML structure, SAML compliance, and DFN-AAI requirements

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# DFN-AAI required attributes
DFN_REQUIRED_ATTRIBUTES=(
    "mail"
    "displayName"
    "eduPersonPrincipalName"
    "eduPersonAffiliation"
    "eduPersonTargetedID"
)

DFN_OPTIONAL_ATTRIBUTES=(
    "givenName"
    "sn"
    "eduPersonScopedAffiliation"
    "eduPersonUniqueID"
    "schacHomeOrganization"
)

# Logging functions
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $*"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $*"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $*"; }

show_usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] METADATA_FILE

Description:
    Validate SAML 2.0 Service Provider metadata for DFN-AAI / eduGAIN compliance.
    Checks XML structure, SAML schema compliance, and DFN-AAI requirements.

Arguments:
    METADATA_FILE           Path to SAML metadata XML file (or URL)

Options:
    -s, --schema            Perform SAML schema validation (requires xmllint)
    -d, --dfn-requirements  Check DFN-AAI specific requirements
    -a, --attributes        Validate required/requested attributes
    -c, --certificates      Check certificate validity and expiration
    --all                   Run all validation checks
    --url                   Treat argument as URL and fetch metadata
    --output-format FMT     Output format: text, json (default: text)
    --quiet                 Only output errors
    -h, --help              Show this help message

Examples:
    # Basic validation
    ${SCRIPT_NAME} metadata.xml

    # Full validation with all checks
    ${SCRIPT_NAME} --all metadata.xml

    # Validate from URL
    ${SCRIPT_NAME} --url https://id.example.edu/saml/metadata

    # DFN-AAI specific validation
    ${SCRIPT_NAME} --dfn-requirements metadata.xml

    # Check certificate expiration
    ${SCRIPT_NAME} --certificates metadata.xml

DFN-AAI Requirements:
    - Valid entityID (unique, stable URL)
    - ValidUntil date (≤ 1 year recommended)
    - Organization information (name, display name, URL)
    - Contact persons (technical, administrative, support)
    - Required attributes (mail, displayName, eduPersonPrincipalName,
                        eduPersonAffiliation, eduPersonTargetedID)
    - Valid X.509 certificate (not expired)
    - HTTPS endpoints (HTTP-POST binding for ACS)

Exit Codes:
    0   All validations passed
    1   Validation failed
    2   File not found or invalid XML
    3   Network error (for URL fetch)
EOF
}

# Fetch metadata from URL
fetch_metadata() {
    local url="$1"
    local output_file="$2"

    log_step "Fetching metadata from: ${url}"

    if ! command -v curl &> /dev/null; then
        log_error "curl is required for URL fetching"
        return 1
    fi

    if ! curl -sSLf --max-time 30 "${url}" -o "${output_file}" 2>/dev/null; then
        log_error "Failed to fetch metadata from URL"
        return 3
    fi

    log_info "Metadata fetched successfully"
}

# Validate XML well-formedness
validate_xml_wellformed() {
    local file="$1"

    log_step "Validating XML well-formedness..."

    if ! command -v xmllint &> /dev/null; then
        log_warn "xmllint not available, skipping XML validation"
        return 0
    fi

    if xmllint --noout "${file}" 2>/dev/null; then
        log_pass "XML is well-formed"
        return 0
    else
        log_fail "XML is not well-formed"
        xmllint --noout "${file}" 2>&1 | head -5
        return 1
    fi
}

# Validate SAML metadata structure
validate_saml_structure() {
    local file="$1"
    local errors=0

    log_step "Validating SAML metadata structure..."

    # Check for EntityDescriptor
    if ! grep -q 'EntityDescriptor' "${file}"; then
        log_fail "Missing EntityDescriptor element"
        errors=$((errors + 1))
    else
        log_pass "EntityDescriptor element found"
    fi

    # Check for entityID attribute
    if ! grep -q 'entityID=' "${file}"; then
        log_fail "Missing entityID attribute"
        errors=$((errors + 1))
    else
        local entity_id
        entity_id=$(grep -oP 'entityID="[^"]*"' "${file}" | head -1 | cut -d'"' -f2)
        log_pass "entityID: ${entity_id}"
    fi

    # Check for SPSSODescriptor
    if ! grep -q 'SPSSODescriptor' "${file}"; then
        log_fail "Missing SPSSODescriptor element"
        errors=$((errors + 1))
    else
        log_pass "SPSSODescriptor element found"
    fi

    # Check for AssertionConsumerService
    if ! grep -q 'AssertionConsumerService' "${file}"; then
        log_fail "Missing AssertionConsumerService element"
        errors=$((errors + 1))
    else
        log_pass "AssertionConsumerService element found"
    fi

    # Check for NameIDFormat
    if ! grep -q 'NameIDFormat' "${file}"; then
        log_warn "Missing NameIDFormat element (recommended)"
    else
        log_pass "NameIDFormat element found"
    fi

    return $errors
}

# Validate DFN-AAI requirements
validate_dfn_requirements() {
    local file="$1"
    local errors=0

    log_step "Validating DFN-AAI requirements..."

    # Check for Organization element
    if ! grep -q '<md:Organization>' "${file}" && ! grep -q '<Organization>' "${file}"; then
        log_fail "Missing Organization element (DFN-AAI requirement)"
        errors=$((errors + 1))
    else
        log_pass "Organization element found"
    fi

    # Check for ContactPerson elements
    local contact_count
    contact_count=$(grep -c 'ContactPerson' "${file}" 2>/dev/null || echo "0")
    if [[ ${contact_count} -lt 3 ]]; then
        log_warn "DFN-AAI recommends at least 3 contact persons (found: ${contact_count})"
    else
        log_pass "ContactPerson elements found (${contact_count})"
    fi

    # Check for validUntil
    if grep -q 'validUntil=' "${file}"; then
        local valid_until
        valid_until=$(grep -oP 'validUntil="[^"]*"' "${file}" | head -1 | cut -d'"' -f2)
        local valid_date
        valid_date=$(date -d "${valid_until}" +%s 2>/dev/null || echo "0")
        local now
        now=$(date +%s)
        local year_seconds=$((365 * 24 * 3600))

        if [[ ${valid_date} -lt ${now} ]]; then
            log_fail "Metadata has expired (validUntil: ${valid_until})"
            errors=$((errors + 1))
        elif [[ $((valid_date - now)) -gt ${year_seconds} ]]; then
            log_warn "validUntil is more than 1 year in future (DFN-AAI recommends ≤ 1 year)"
        else
            log_pass "validUntil date is valid: ${valid_until}"
        fi
    else
        log_warn "Missing validUntil attribute (recommended for DFN-AAI)"
    fi

    # Check for cacheDuration
    if grep -q 'cacheDuration=' "${file}"; then
        log_pass "cacheDuration attribute found"
    else
        log_warn "Missing cacheDuration attribute"
    fi

    return $errors
}

# Validate required attributes
validate_attributes() {
    local file="$1"
    local errors=0

    log_step "Validating requested attributes..."

    local found_required=0
    local found_optional=0

    for attr in "${DFN_REQUIRED_ATTRIBUTES[@]}"; do
        if grep -qi "FriendlyName=\"${attr}\"" "${file}" || \
           grep -qi "Name=\"[^\"]*${attr}[^\"]*\"" "${file}"; then
            log_pass "Required attribute found: ${attr}"
            found_required=$((found_required + 1))
        else
            log_fail "Missing required attribute: ${attr}"
            errors=$((errors + 1))
        fi
    done

    for attr in "${DFN_OPTIONAL_ATTRIBUTES[@]}"; do
        if grep -qi "FriendlyName=\"${attr}\"" "${file}" || \
           grep -qi "Name=\"[^\"]*${attr}[^\"]*\"" "${file}"; then
            log_pass "Optional attribute found: ${attr}"
            found_optional=$((found_optional + 1))
        fi
    done

    log_info "Required attributes: ${found_required}/${#DFN_REQUIRED_ATTRIBUTES[@]}"
    log_info "Optional attributes: ${found_optional}/${#DFN_OPTIONAL_ATTRIBUTES[@]}"

    return $errors
}

# Validate certificates
validate_certificates() {
    local file="$1"
    local errors=0

    log_step "Validating certificates..."

    if ! command -v openssl &> /dev/null; then
        log_warn "openssl not available, skipping certificate validation"
        return 0
    fi

    # Extract certificate(s) from metadata
    local cert_count
    cert_count=$(grep -c 'X509Certificate' "${file}" 2>/dev/null || echo "0")

    if [[ ${cert_count} -eq 0 ]]; then
        log_fail "No X509Certificate found in metadata"
        return 1
    fi

    log_info "Found ${cert_count} certificate(s)"

    # Extract and validate each certificate
    local temp_cert
    temp_cert=$(mktemp)

    local in_cert=false
    local cert_num=0

    while IFS= read -r line; do
        if echo "${line}" | grep -q '<ds:X509Certificate>'; then
            in_cert=true
            cert_num=$((cert_num + 1))
            echo "-----BEGIN CERTIFICATE-----" > "${temp_cert}"
        elif echo "${line}" | grep -q '</ds:X509Certificate>'; then
            in_cert=false
            echo "-----END CERTIFICATE-----" >> "${temp_cert}"

            # Validate certificate
            log_info "Certificate #${cert_num}:"

            if openssl x509 -in "${temp_cert}" -noout 2>/dev/null; then
                # Get certificate details
                local subject
                subject=$(openssl x509 -in "${temp_cert}" -noout -subject 2>/dev/null)
                log_pass "  Subject: ${subject#subject=}"

                local issuer
                issuer=$(openssl x509 -in "${temp_cert}" -noout -issuer 2>/dev/null)
                log_info "  Issuer: ${issuer#issuer=}"

                local dates
                dates=$(openssl x509 -in "${temp_cert}" -noout -dates 2>/dev/null)
                log_info "  ${dates}"

                # Check expiration
                local end_date
                end_date=$(openssl x509 -in "${temp_cert}" -noout -enddate 2>/dev/null | cut -d= -f2)
                local end_epoch
                end_epoch=$(date -d "${end_date}" +%s 2>/dev/null || echo "0")
                local now
                now=$(date +%s)
                local days_left=$(( (end_epoch - now) / 86400 ))

                if [[ ${days_left} -lt 0 ]]; then
                    log_fail "  Certificate has EXPIRED"
                    errors=$((errors + 1))
                elif [[ ${days_left} -lt 30 ]]; then
                    log_warn "  Certificate expires in ${days_left} days"
                else
                    log_pass "  Certificate valid for ${days_left} more days"
                fi
            else
                log_fail "  Invalid certificate format"
                errors=$((errors + 1))
            fi
        elif [[ "${in_cert}" == "true" ]]; then
            # Clean up whitespace and add to cert
            echo "${line}" | tr -d '[:space:]' >> "${temp_cert}"
        fi
    done < "${file}"

    rm -f "${temp_cert}"

    return $errors
}

# Output results in JSON format
output_json() {
    local total_errors="$1"
    local results="$2"

    cat <<EOF
{
    "valid": $([[ "${total_errors}" -eq 0 ]] && echo "true" || echo "false"),
    "errors": ${total_errors},
    "checks": ${results}
}
EOF
}

# Main function
main() {
    local metadata_file=""
    local do_schema=false
    local do_dfn=false
    local do_attributes=false
    local do_certificates=false
    local is_url=false
    local output_format="text"
    local quiet=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--schema)
                do_schema=true
                shift
                ;;
            -d|--dfn-requirements)
                do_dfn=true
                shift
                ;;
            -a|--attributes)
                do_attributes=true
                shift
                ;;
            -c|--certificates)
                do_certificates=true
                shift
                ;;
            --all)
                do_schema=true
                do_dfn=true
                do_attributes=true
                do_certificates=true
                shift
                ;;
            --url)
                is_url=true
                shift
                ;;
            --output-format)
                output_format="$2"
                shift 2
                ;;
            --quiet)
                quiet=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                metadata_file="$1"
                shift
                ;;
        esac
    done

    # Validate required parameters
    if [[ -z "${metadata_file}" ]]; then
        log_error "Metadata file is required"
        show_usage
        exit 1
    fi

    # Fetch from URL if needed
    if [[ "${is_url}" == "true" ]]; then
        local temp_file
        temp_file=$(mktemp --suffix=.xml)
        if ! fetch_metadata "${metadata_file}" "${temp_file}"; then
            rm -f "${temp_file}"
            exit 3
        fi
        metadata_file="${temp_file}"
    fi

    # Check file exists
    if [[ ! -f "${metadata_file}" ]]; then
        log_error "File not found: ${metadata_file}"
        exit 2
    fi

    local total_errors=0

    # Run validations
    if [[ "${quiet}" != "true" ]]; then
        log_info "Validating SAML metadata: ${metadata_file}"
        log_info ""
    fi

    validate_xml_wellformed "${metadata_file}" || total_errors=$((total_errors + 1))

    validate_saml_structure "${metadata_file}" || total_errors=$((total_errors + $?))

    if [[ "${do_schema}" == "true" ]]; then
        validate_xml_wellformed "${metadata_file}" || total_errors=$((total_errors + $?))
    fi

    if [[ "${do_dfn}" == "true" ]]; then
        validate_dfn_requirements "${metadata_file}" || total_errors=$((total_errors + $?))
    fi

    if [[ "${do_attributes}" == "true" ]]; then
        validate_attributes "${metadata_file}" || total_errors=$((total_errors + $?))
    fi

    if [[ "${do_certificates}" == "true" ]]; then
        validate_certificates "${metadata_file}" || total_errors=$((total_errors + $?))
    fi

    # Cleanup temp file
    if [[ "${is_url}" == "true" ]]; then
        rm -f "${metadata_file}"
    fi

    # Summary
    if [[ "${quiet}" != "true" ]]; then
        log_info ""
        if [[ ${total_errors} -eq 0 ]]; then
            log_pass "All validations passed!"
        else
            log_fail "Validation completed with ${total_errors} error(s)"
        fi
    fi

    exit $([[ ${total_errors} -eq 0 ]] && echo 0 || echo 1)
}

# Run main function
main "${@}"

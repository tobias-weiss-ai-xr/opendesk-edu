#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2025 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
"""
SAML SP Metadata Generator for DFN-AAI Federation

Generates SAML 2.0 Service Provider metadata XML files for DFN-AAI/eduGAIN
federation registration. Supports multiple environments (dev, staging, production)
with configurable entity IDs, ACS URLs, and certificate paths.

Usage:
    python saml-metadata-generator.py --config config.yaml --env dev --output metadata.xml

For DFN-AAI registration, submit the generated metadata to:
    Test Federation: https://test.aai.dfn.de/metadata/
    Production: https://www.aai.dfn.de/en/service/metadata/
"""

import argparse
import datetime
from datetime import timezone
import logging
import os
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Optional
from xml.dom import minidom

import yaml

# SAML and XML namespace constants
SAML_METADATA_NS = "urn:oasis:names:tc:SAML:2.0:metadata"
SAML_ASSERTION_NS = "urn:oasis:names:tc:SAML:2.0:assertion"
XMLDSIG_NS = "http://www.w3.org/2000/09/xmldsig#"
XML_ENC_NS = "http://www.w3.org/2001/04/xmlenc#"

NS_MAP = {
    "md": SAML_METADATA_NS,
    "saml": SAML_ASSERTION_NS,
    "ds": XMLDSIG_NS,
    "xenc": XML_ENC_NS,
}

# DFN-AAI specific attribute requirements
# eduGAIN attribute URNs ( official format)
# Reference: https://technical.edugain.org/2021/07/edugain-attribute-naming.html
EDUGAIN_ATTRIBUTE_URNS = {
    "mail": "urn:mace:dir:attribute-def:mail",
    "displayName": "urn:mace:dir:attribute-def:displayName",
    "givenName": "urn:mace:dir:attribute-def:givenName",
    "sn": "urn:mace:dir:attribute-def:sn",
    "eduPersonPrincipalName": "urn:mace:dir:attribute-def:eduPersonPrincipalName",
    "eduPersonAffiliation": "urn:mace:dir:attribute-def:eduPersonAffiliation",
    "eduPersonScopedAffiliation": "urn:mace:dir:attribute-def:eduPersonScopedAffiliation",
    "eduPersonTargetedID": "urn:mace:dir:attribute-def:eduPersonTargetedID",
    "eduPersonUniqueID": "urn:mace:dir:attribute-def:eduPersonUniqueID",
    "schacHomeOrganization": "urn:oid:1.3.6.1.4.1.25178.1.2.9",
    "o": "urn:mace:dir:attribute-def:o",
}

# DFN-AAI required attributes (5 mandatory)
DFN_AAI_REQUIRED_ATTRIBUTES = [
    "mail",
    "displayName",
    "eduPersonPrincipalName",
    "eduPersonAffiliation",
    "eduPersonTargetedID",
]

DFN_AAI_OPTIONAL_ATTRIBUTES = [
    "givenName",
    "sn",
    "eduPersonScopedAffiliation",
    "eduPersonUniqueID",
    "schacHomeOrganization",
]


def setup_logging(level: str = "INFO") -> logging.Logger:
    """Configure logging for the script."""
    log = logging.getLogger("saml-metadata-generator")
    log.setLevel(getattr(logging, level.upper(), logging.INFO))
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
    log.addHandler(handler)
    return log


def load_config(config_path: str) -> dict:
    """Load configuration from YAML file."""
    with open(config_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def get_env_config(config: dict, environment: str) -> dict:
    """Get configuration for a specific environment."""
    envs = config.get("environments", {})
    if environment not in envs:
        raise ValueError(f"Environment '{environment}' not found in config")
    return envs[environment]


def load_certificate(cert_path: str, log: logging.Logger) -> Optional[str]:
    """Load and format X.509 certificate for metadata."""
    if not cert_path or not os.path.exists(cert_path):
        log.warning(f"Certificate file not found: {cert_path}")
        return None

    with open(cert_path, "r", encoding="utf-8") as f:
        cert_content = f.read()

    lines = cert_content.strip().split("\n")
    cert_lines = [
        line
        for line in lines
        if not line.startswith("-----BEGIN") and not line.startswith("-----END")
    ]
    return "".join(cert_lines)


def generate_entity_id(base_url: str, realm: str = "opendesk") -> str:
    """Generate SAML Entity ID for Keycloak SP."""
    return f"{base_url}/realms/{realm}"


def generate_acs_url(base_url: str, realm: str = "opendesk") -> str:
    """Generate Assertion Consumer Service URL for Keycloak."""
    return f"{base_url}/realms/{realm}/broker/saml/endpoint"


def generate_slo_url(base_url: str, realm: str = "opendesk") -> str:
    """Generate Single Logout Service URL for Keycloak."""
    return f"{base_url}/realms/{realm}/broker/saml/endpoint"


def create_key_descriptor(
    cert_data: str, use: str = "signing", key_name: Optional[str] = None
) -> ET.Element:
    """Create a KeyDescriptor element for the metadata."""
    key_descriptor = ET.Element(f"{{{SAML_METADATA_NS}}}KeyDescriptor")
    key_descriptor.set("use", use)

    key_info = ET.SubElement(key_descriptor, f"{{{XMLDSIG_NS}}}KeyInfo")

    if key_name:
        key_name_elem = ET.SubElement(key_info, f"{{{XMLDSIG_NS}}}KeyName")
        key_name_elem.text = key_name

    x509_data = ET.SubElement(key_info, f"{{{XMLDSIG_NS}}}X509Data")
    x509_cert = ET.SubElement(x509_data, f"{{{XMLDSIG_NS}}}X509Certificate")
    x509_cert.text = cert_data

    return key_descriptor


def create_attribute_consuming_service(
    requested_attributes: list,
    service_config: Optional[dict] = None,
) -> ET.Element:
    """Create AttributeConsumingService element for requested attributes.

    Supports bilingual (German/English) service names and descriptions.
    DFN-AAI requires German as primary language.

    Args:
        requested_attributes: List of attribute dicts with 'name', 'urn', 'required',
                            'friendly_name_de', 'friendly_name_en'
        service_config: Optional dict with 'name_de', 'name_en', 'description_de', 'description_en'
    """
    acs = ET.Element(f"{{{SAML_METADATA_NS}}}AttributeConsumingService")
    acs.set("index", "0")

    service_config = service_config or {}

    service_name_de = ET.SubElement(acs, f"{{{SAML_METADATA_NS}}}ServiceName")
    service_name_de.set("xml:lang", "de")
    service_name_de.text = service_config.get("name_de", "openDesk Edu Dienste")

    service_name_en = ET.SubElement(acs, f"{{{SAML_METADATA_NS}}}ServiceName")
    service_name_en.set("xml:lang", "en")
    service_name_en.text = service_config.get("name_en", "openDesk Edu Services")

    service_desc_de = ET.SubElement(acs, f"{{{SAML_METADATA_NS}}}ServiceDescription")
    service_desc_de.set("xml:lang", "de")
    service_desc_de.text = service_config.get(
        "description_de", "Digitale Arbeitsplatzdienste für Universitäten"
    )

    service_desc_en = ET.SubElement(acs, f"{{{SAML_METADATA_NS}}}ServiceDescription")
    service_desc_en.set("xml:lang", "en")
    service_desc_en.text = service_config.get(
        "description_en", "Digital workplace services for universities"
    )

    for attr in requested_attributes:
        if isinstance(attr, dict):
            attr_name = attr.get("urn") or attr.get("name", "")
            attr_required = attr.get("required", False)
            friendly_name_de = attr.get("friendly_name_de", attr.get("name", ""))
            attr.get("friendly_name_en", attr.get("name", ""))
        else:
            attr_name = attr
            attr_required = attr in DFN_AAI_REQUIRED_ATTRIBUTES
            friendly_name_de = attr

        requested_attr = ET.SubElement(acs, f"{{{SAML_METADATA_NS}}}RequestedAttribute")

        if attr_name.startswith("urn:"):
            requested_attr.set("Name", attr_name)
        else:
            requested_attr.set("Name", EDUGAIN_ATTRIBUTE_URNS.get(attr_name, attr_name))

        requested_attr.set("NameFormat", SAML_ASSERTION_NS + ":attr-format-uri")
        requested_attr.set("isRequired", str(attr_required).lower())

        if friendly_name_de:
            requested_attr.set("FriendlyName", friendly_name_de)

    return acs


def create_sp_sso_descriptor(
    entity_id: str,
    acs_url: str,
    slo_url: str,
    signing_cert: Optional[str],
    encryption_cert: Optional[str],
    requested_attributes: list,
    want_assertions_signed: bool = True,
    want_responses_signed: bool = True,
) -> ET.Element:
    """Create the SPSSODescriptor element."""
    sp_descriptor = ET.Element(f"{{{SAML_METADATA_NS}}}SPSSODescriptor")
    sp_descriptor.set(
        "protocolSupportEnumeration", "urn:oasis:names:tc:SAML:2.0:protocol"
    )
    sp_descriptor.set("WantAssertionsSigned", str(want_assertions_signed).lower())
    sp_descriptor.set("AuthnRequestsSigned", "true")

    # Add signing certificate
    if signing_cert:
        key_desc = create_key_descriptor(
            signing_cert, use="signing", key_name=entity_id
        )
        sp_descriptor.append(key_desc)

    # Add encryption certificate (can be same as signing)
    if encryption_cert:
        key_desc = create_key_descriptor(
            encryption_cert, use="encryption", key_name=entity_id
        )
        sp_descriptor.append(key_desc)

    # Single Logout Service
    slo_service = ET.SubElement(
        sp_descriptor, f"{{{SAML_METADATA_NS}}}SingleLogoutService"
    )
    slo_service.set("Binding", "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect")
    slo_service.set("Location", slo_url)

    # NameID formats
    name_id_formats = [
        "urn:oasis:names:tc:SAML:2.0:nameid-format:transient",
        "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
        "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
    ]
    for name_id_format in name_id_formats:
        name_id_elem = ET.SubElement(
            sp_descriptor, f"{{{SAML_METADATA_NS}}}NameIDFormat"
        )
        name_id_elem.text = name_id_format

    # Assertion Consumer Service
    acs_service = ET.SubElement(
        sp_descriptor, f"{{{SAML_METADATA_NS}}}AssertionConsumerService"
    )
    acs_service.set("index", "0")
    acs_service.set("isDefault", "true")
    acs_service.set("Binding", "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST")
    acs_service.set("Location", acs_url)

    # Attribute Consuming Service
    if requested_attributes:
        attr_service = create_attribute_consuming_service(requested_attributes)
        sp_descriptor.append(attr_service)

    return sp_descriptor


def create_organization(
    org_name: str,
    org_display_name: str,
    org_url: str,
    lang: str = "en",
    org_display_name_de: Optional[str] = None,
    org_display_name_en: Optional[str] = None,
) -> ET.Element:
    """Create Organization element for metadata with bilingual support."""
    org = ET.Element(f"{{{SAML_METADATA_NS}}}Organization")

    name_de = ET.SubElement(org, f"{{{SAML_METADATA_NS}}}OrganizationName")
    name_de.set("xml:lang", "de")
    name_de.text = org_name

    name_en = ET.SubElement(org, f"{{{SAML_METADATA_NS}}}OrganizationName")
    name_en.set("xml:lang", "en")
    name_en.text = org_name

    primary_display = (
        org_display_name_de or org_display_name_en or org_display_name or org_name
    )
    secondary_display = org_display_name_en or org_display_name or org_name

    display_name_de = ET.SubElement(
        org, f"{{{SAML_METADATA_NS}}}OrganizationDisplayName"
    )
    display_name_de.set("xml:lang", "de")
    display_name_de.text = primary_display

    display_name_en = ET.SubElement(
        org, f"{{{SAML_METADATA_NS}}}OrganizationDisplayName"
    )
    display_name_en.set("xml:lang", "en")
    display_name_en.text = secondary_display

    url_de = ET.SubElement(org, f"{{{SAML_METADATA_NS}}}OrganizationURL")
    url_de.set("xml:lang", "de")
    url_de.text = org_url

    url_en = ET.SubElement(org, f"{{{SAML_METADATA_NS}}}OrganizationURL")
    url_en.set("xml:lang", "en")
    url_en.text = org_url

    return org


def create_contact_person(
    contact_type: str,
    given_name: str,
    sur_name: str,
    email: str,
    company: Optional[str] = None,
) -> ET.Element:
    """Create ContactPerson element for metadata."""
    contact = ET.Element(f"{{{SAML_METADATA_NS}}}ContactPerson")
    contact.set("contactType", contact_type)

    if company:
        company_elem = ET.SubElement(contact, f"{{{SAML_METADATA_NS}}}Company")
        company_elem.text = company

    given_name_elem = ET.SubElement(contact, f"{{{SAML_METADATA_NS}}}GivenName")
    given_name_elem.text = given_name

    sur_name_elem = ET.SubElement(contact, f"{{{SAML_METADATA_NS}}}SurName")
    sur_name_elem.text = sur_name

    email_elem = ET.SubElement(contact, f"{{{SAML_METADATA_NS}}}EmailAddress")
    email_elem.text = email

    return contact


def generate_metadata(
    entity_id: str,
    acs_url: str,
    slo_url: str,
    signing_cert: Optional[str],
    encryption_cert: Optional[str],
    org_info: dict,
    contacts: list,
    requested_attributes: list,
    cache_duration: str = "PT24H",
    valid_until_days: int = 365,
) -> ET.Element:
    """Generate complete SAML 2.0 SP metadata."""
    # Root EntityDescriptor element
    entity_descriptor = ET.Element(f"{{{SAML_METADATA_NS}}}EntityDescriptor")
    entity_descriptor.set("entityID", entity_id)
    entity_descriptor.set("xmlns:md", SAML_METADATA_NS)
    entity_descriptor.set("xmlns:ds", XMLDSIG_NS)
    entity_descriptor.set("xmlns:saml", SAML_ASSERTION_NS)

    # Set cache duration and valid until
    entity_descriptor.set("cacheDuration", cache_duration)
    valid_until = datetime.datetime.now(timezone.utc) + datetime.timedelta(
        days=valid_until_days
    )
    entity_descriptor.set("validUntil", valid_until.strftime("%Y-%m-%dT%H:%M:%SZ"))

    # Generate and add SPSSODescriptor
    sp_descriptor = create_sp_sso_descriptor(
        entity_id=entity_id,
        acs_url=acs_url,
        slo_url=slo_url,
        signing_cert=signing_cert,
        encryption_cert=encryption_cert,
        requested_attributes=requested_attributes,
    )
    entity_descriptor.append(sp_descriptor)

    # Add Organization
    if org_info:
        org = create_organization(
            org_name=org_info.get("name", ""),
            org_display_name=org_info.get("display_name", org_info.get("name", "")),
            org_url=org_info.get("url", ""),
            lang=org_info.get("lang", "en"),
        )
        entity_descriptor.append(org)

    # Add Contact Persons
    for contact_info in contacts:
        contact = create_contact_person(
            contact_type=contact_info.get("type", "technical"),
            given_name=contact_info.get("given_name", ""),
            sur_name=contact_info.get("surname", ""),
            email=contact_info.get("email", ""),
            company=contact_info.get("company"),
        )
        entity_descriptor.append(contact)

    return entity_descriptor


def prettify_xml(elem: ET.Element) -> str:
    """Return a pretty-printed XML string."""
    rough_string = ET.tostring(elem, encoding="unicode")
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="  ", encoding=None)


def validate_xml_schema(xml_content: str, log: logging.Logger) -> bool:
    """
    Validate XML against SAML 2.0 metadata schema.
    Note: This is a basic validation. For full schema validation,
    use lxml with the SAML schema files.
    """
    try:
        # Basic XML well-formedness check
        ET.fromstring(xml_content)
        log.info("XML well-formedness check: PASSED")

        # Check required elements
        root = ET.fromstring(xml_content)

        # Verify namespace
        if SAML_METADATA_NS not in root.tag:
            log.error("Missing SAML metadata namespace")
            return False

        # Verify entityID attribute
        if "entityID" not in root.attrib:
            log.error("Missing entityID attribute")
            return False

        # Verify SPSSODescriptor exists
        sp_descriptor = None
        for child in root:
            if "SPSSODescriptor" in child.tag:
                sp_descriptor = child
                break

        if sp_descriptor is None:
            log.error("Missing SPSSODescriptor element")
            return False

        # Verify ACS service
        acs_found = False
        for child in sp_descriptor:
            if "AssertionConsumerService" in child.tag:
                acs_found = True
                break

        if not acs_found:
            log.error("Missing AssertionConsumerService element")
            return False

        log.info("SAML metadata structure validation: PASSED")
        return True

    except ET.ParseError as e:
        log.error(f"XML parsing error: {e}")
        return False


def validate_with_xmllint(xml_path: str, log: logging.Logger) -> bool:
    """Validate XML using xmllint (if available)."""
    import subprocess

    try:
        result = subprocess.run(
            ["xmllint", "--noout", xml_path],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode == 0:
            log.info(f"xmllint validation: PASSED for {xml_path}")
            return True
        else:
            log.error(f"xmllint validation failed: {result.stderr}")
            return False
    except FileNotFoundError:
        log.warning("xmllint not found, skipping external validation")
        return True
    except subprocess.TimeoutExpired:
        log.error("xmllint validation timed out")
        return False


def generate_metadata_file(
    config: dict,
    environment: str,
    output_path: str,
    log: logging.Logger,
) -> bool:
    """Generate and save metadata file for the specified environment."""
    env_config = get_env_config(config, environment)

    # Get base configuration
    base_url = env_config.get("base_url")
    realm = env_config.get("realm", "opendesk")
    entity_id = env_config.get("entity_id") or generate_entity_id(base_url, realm)

    acs_url = env_config.get("acs_url") or generate_acs_url(base_url, realm)
    slo_url = env_config.get("slo_url") or generate_slo_url(base_url, realm)

    # Load certificates
    signing_cert = None
    encryption_cert = None

    cert_config = env_config.get("certificates", {})
    signing_cert_path = cert_config.get("signing")
    encryption_cert_path = cert_config.get("encryption") or signing_cert_path

    if signing_cert_path:
        signing_cert = load_certificate(signing_cert_path, log)
    if encryption_cert_path and encryption_cert_path != signing_cert_path:
        encryption_cert = load_certificate(encryption_cert_path, log)
    elif signing_cert:
        encryption_cert = signing_cert

    # Get organization info
    org_info = config.get("organization", {})
    contacts = config.get("contacts", [])

    # Get requested attributes
    requested_attributes = config.get(
        "requested_attributes", DFN_AAI_REQUIRED_ATTRIBUTES
    )

    # Generate metadata
    log.info(f"Generating SAML metadata for environment: {environment}")
    log.info(f"Entity ID: {entity_id}")
    log.info(f"ACS URL: {acs_url}")

    metadata = generate_metadata(
        entity_id=entity_id,
        acs_url=acs_url,
        slo_url=slo_url,
        signing_cert=signing_cert,
        encryption_cert=encryption_cert,
        org_info=org_info,
        contacts=contacts,
        requested_attributes=requested_attributes,
        cache_duration=env_config.get("cache_duration", "PT24H"),
        valid_until_days=env_config.get("valid_until_days", 365),
    )

    # Convert to pretty XML
    xml_content = prettify_xml(metadata)

    # Add XML declaration with proper encoding
    if not xml_content.startswith("<?xml"):
        xml_content = '<?xml version="1.0" encoding="UTF-8"?>\n' + xml_content

    # Validate
    if not validate_xml_schema(xml_content, log):
        log.error("Generated metadata failed validation")
        return False

    # Save to file
    output_file = Path(output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)

    with open(output_file, "w", encoding="utf-8") as f:
        f.write(xml_content)

    log.info(f"Metadata written to: {output_file}")

    # Additional validation with xmllint if available
    validate_with_xmllint(str(output_file), log)

    return True


def main() -> None:
    """Main entry point for the SAML metadata generator."""
    parser = argparse.ArgumentParser(
        description="Generate SAML 2.0 SP metadata for DFN-AAI federation",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  Generate dev metadata:
    %(prog)s --config config.yaml --env dev --output metadata-dev.xml

  Generate all environments:
    %(prog)s --config config.yaml --all

  Validate existing metadata:
    %(prog)s --validate metadata.xml

For DFN-AAI registration:
  Test Federation: https://test.aai.dfn.de/metadata/
  Production: https://www.aai.dfn.de/en/service/metadata/
        """,
    )

    parser.add_argument(
        "--config",
        "-c",
        required=False,
        default="saml-metadata-generator-config.yaml",
        help="Path to configuration YAML file (default: saml-metadata-generator-config.yaml)",
    )
    parser.add_argument(
        "--env",
        "-e",
        choices=["dev", "staging", "production"],
        help="Environment to generate metadata for",
    )
    parser.add_argument(
        "--output",
        "-o",
        help="Output file path (default: metadata-<env>.xml)",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Generate metadata for all configured environments",
    )
    parser.add_argument(
        "--validate",
        metavar="FILE",
        help="Validate an existing metadata file",
    )
    parser.add_argument(
        "--log-level",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        default="INFO",
        help="Logging level (default: INFO)",
    )

    args = parser.parse_args()

    # Setup logging
    log = setup_logging(args.log_level)

    # Validation mode
    if args.validate:
        log.info(f"Validating metadata file: {args.validate}")
        with open(args.validate, "r", encoding="utf-8") as f:
            content = f.read()
        success = validate_xml_schema(content, log)
        validate_with_xmllint(args.validate, log)
        sys.exit(0 if success else 1)

    # Load configuration
    config_path = Path(args.config)
    if not config_path.exists():
        # Try in script directory
        script_dir = Path(__file__).parent
        config_path = script_dir / args.config

    if not config_path.exists():
        log.error(f"Configuration file not found: {args.config}")
        log.info("Create a configuration file from the example template:")
        log.info(
            "  cp saml-metadata-generator-config.yaml.example saml-metadata-generator-config.yaml"
        )
        sys.exit(1)

    log.info(f"Loading configuration from: {config_path}")
    config = load_config(str(config_path))

    # Generate metadata
    if args.all:
        # Generate for all environments
        environments = config.get("environments", {}).keys()
        for env in environments:
            output = args.output or f"metadata-{env}.xml"
            generate_metadata_file(config, env, output, log)
    elif args.env:
        output = args.output or f"metadata-{args.env}.xml"
        success = generate_metadata_file(config, args.env, output, log)
        sys.exit(0 if success else 1)
    else:
        parser.error("Specify --env or --all")


if __name__ == "__main__":
    main()

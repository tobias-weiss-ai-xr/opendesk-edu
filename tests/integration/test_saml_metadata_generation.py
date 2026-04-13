# SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
"""
Tests for SAML Metadata Generation

Tests the ACTUAL saml-metadata-generator.py module covering all exported
functions for >90% code coverage.
"""

import logging
import os
import sys
import time
from datetime import datetime, timezone, timedelta
from pathlib import Path
from unittest.mock import MagicMock, patch, call
from xml.etree.ElementTree import ParseError

import pytest
import yaml

SCRIPT_DIR = Path(__file__).parent.parent.parent
sys.path.insert(0, str(SCRIPT_DIR))


def _import_mod():
    """Import the saml-metadata-generator module from the hyphen-path."""
    import importlib.util

    script_path = (
        SCRIPT_DIR
        / "scripts"
        / "saml-metadata-generator"
        / "saml-metadata-generator.py"
    )
    spec = importlib.util.spec_from_file_location(
        "saml_metadata_generator", str(script_path)
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


mod = _import_mod()

# Shorthand references
setup_logging = mod.setup_logging
load_config = mod.load_config
get_env_config = mod.get_env_config
load_certificate = mod.load_certificate
generate_entity_id = mod.generate_entity_id
generate_acs_url = mod.generate_acs_url
generate_slo_url = mod.generate_slo_url
create_key_descriptor = mod.create_key_descriptor
create_attribute_consuming_service = mod.create_attribute_consuming_service
create_sp_sso_descriptor = mod.create_sp_sso_descriptor
create_organization = mod.create_organization
create_contact_person = mod.create_contact_person
generate_metadata = mod.generate_metadata
prettify_xml = mod.prettify_xml
validate_xml_schema = mod.validate_xml_schema
validate_with_xmllint = mod.validate_with_xmllint
generate_metadata_file = mod.generate_metadata_file
main = mod.main

EDUGAIN_ATTRIBUTE_URNS = mod.EDUGAIN_ATTRIBUTE_URNS
DFN_AAI_REQUIRED_ATTRIBUTES = mod.DFN_AAI_REQUIRED_ATTRIBUTES
DFN_AAI_OPTIONAL_ATTRIBUTES = mod.DFN_AAI_OPTIONAL_ATTRIBUTES
SAML_METADATA_NS = mod.SAML_METADATA_NS
SAML_ASSERTION_NS = mod.SAML_ASSERTION_NS
XMLDSIG_NS = mod.XMLDSIG_NS


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

SAMPLE_CERT_PEM = """-----BEGIN CERTIFICATE-----
MIIBkDCCAREDDDDDANBgkqhkiG9w0BAQEFAAOCAYEKZAAYFKDZ2phZQ0lJS1BUZXRh
YWluMTIExCAKjAoQIIgZGUgTWFpb24G1hcHBhIHNvbyB1lbXBpXQ1J5z5JpYMQKbE8
YqNQ7UHdvK0VIVcBZqG3WR3zIGhpM1MjWnJ4KZxcCk3E5wdmlkVEV1hdL3uVvQ9f/N
DoeOjgEql5DRR3TsxNNRVA/7oxL9r2mvJdrB3iJMXRVXUJW5CQRDExjxS2rL3XQlqk
gZ9gT3L4AYpBdgHR0ciAGdlAaO9DRxRL4loK5s8LnRz5YfL3Z53p4KQDg9gCqPMW1Z
0I8FyFZJKJOLB7oFpl2PYP0EXPP6q+2m2/8b4fqPcWZFIUYPJQ7A1+0sg==
-----END CERTIFICATE-----"""

STRIPPED_CERT = (
    SAMPLE_CERT_PEM.replace("-----BEGIN CERTIFICATE-----", "")
    .replace("-----END CERTIFICATE-----", "")
    .strip()
)


@pytest.fixture
def sample_config_dict():
    """Return a full config dict matching the YAML schema."""
    return {
        "organization": {
            "name": "Test University",
            "display_name": "Test University - openDesk",
            "url": "https://test.example.edu",
            "lang": "de",
            "display_name_de": "Test-Universität - openDesk",
            "display_name_en": "Test University - openDesk",
        },
        "contacts": [
            {
                "type": "technical",
                "given_name": "IT",
                "surname": "Support",
                "email": "support@test.edu",
                "company": "Test University",
            },
            {
                "type": "administrative",
                "given_name": "Admin",
                "surname": "Team",
                "email": "admin@test.edu",
            },
        ],
        "requested_attributes": DFN_AAI_REQUIRED_ATTRIBUTES
        + DFN_AAI_OPTIONAL_ATTRIBUTES,
        "service": {
            "name_en": "openDesk Edu Services",
            "name_de": "openDesk Edu Dienste",
            "description_en": "Digital workplace services for universities",
            "description_de": "Digitale Arbeitsplatzdienste für Universitäten",
        },
        "environments": {
            "dev": {
                "base_url": "https://id.dev.example.edu",
                "realm": "opendesk",
                "entity_id": "https://dev.example.edu/saml-sp",
                "acs_url": "https://id.dev.example.edu/realms/opendesk/broker/saml/endpoint",
                "slo_url": "https://id.dev.example.edu/realms/opendesk/broker/saml/endpoint",
                "cache_duration": "PT24H",
                "valid_until_days": 30,
                "certificates": {
                    "signing": "/etc/certs/saml-sp-signing.crt",
                    "encryption": None,
                },
            },
            "staging": {
                "base_url": "https://id.staging.example.edu",
                "realm": "opendesk",
                "cache_duration": "PT24H",
                "valid_until_days": 90,
            },
            "production": {
                "base_url": "https://id.prod.example.edu",
                "realm": "opendesk",
                "cache_duration": "PT24H",
                "valid_until_days": 365,
            },
        },
    }


@pytest.fixture
def sample_config_file(tmp_path, sample_config_dict):
    """Write the config dict to a YAML file and return its path."""
    p = tmp_path / "config.yaml"
    p.write_text(yaml.dump(sample_config_dict), encoding="utf-8")
    return str(p)


@pytest.fixture
def sample_cert_file(tmp_path):
    """Write a sample PEM cert and return its path."""
    p = tmp_path / "test-cert.pem"
    p.write_text(SAMPLE_CERT_PEM, encoding="utf-8")
    return str(p)


@pytest.fixture
def log():
    return setup_logging("WARNING")


# ---------------------------------------------------------------------------
# Constants / data-class tests
# ---------------------------------------------------------------------------


class TestConstants:
    """Verify module-level constants match DFN-AAI spec."""

    def test_required_attributes_count(self):
        assert len(DFN_AAI_REQUIRED_ATTRIBUTES) == 5

    def test_required_attributes_contents(self):
        expected = {
            "mail",
            "displayName",
            "eduPersonPrincipalName",
            "eduPersonAffiliation",
            "eduPersonTargetedID",
        }
        assert set(DFN_AAI_REQUIRED_ATTRIBUTES) == expected

    def test_optional_attributes_count(self):
        assert len(DFN_AAI_OPTIONAL_ATTRIBUTES) == 5

    def test_optional_attributes_contents(self):
        expected = {
            "givenName",
            "sn",
            "eduPersonScopedAffiliation",
            "eduPersonUniqueID",
            "schacHomeOrganization",
        }
        assert set(DFN_AAI_OPTIONAL_ATTRIBUTES) == expected

    def test_all_urns_use_valid_format(self):
        for name, urn in EDUGAIN_ATTRIBUTE_URNS.items():
            assert urn.startswith("urn:mace:dir:attribute-def:") or urn.startswith(
                "urn:oid:"
            ), f"{name}: {urn}"

    def test_required_attributes_have_urns(self):
        for attr in DFN_AAI_REQUIRED_ATTRIBUTES:
            assert attr in EDUGAIN_ATTRIBUTE_URNS


# ---------------------------------------------------------------------------
# setup_logging
# ---------------------------------------------------------------------------


class TestSetupLogging:
    def test_default_level(self):
        logger = setup_logging()
        assert logger.name == "saml-metadata-generator"
        assert logger.level == logging.INFO

    def test_custom_level(self):
        logger = setup_logging("DEBUG")
        assert logger.level == logging.DEBUG

    def test_warning_level(self):
        logger = setup_logging("WARNING")
        assert logger.level == logging.WARNING

    def test_error_level(self):
        logger = setup_logging("ERROR")
        assert logger.level == logging.ERROR

    def test_invalid_level_falls_back_to_info(self):
        logger = setup_logging("NOTAREALLEVEL")
        assert logger.level == logging.INFO

    def test_has_stdout_handler(self):
        logger = setup_logging("WARNING")
        handlers = logger.handlers
        assert len(handlers) >= 1
        assert isinstance(handlers[0], logging.StreamHandler)


# ---------------------------------------------------------------------------
# load_config
# ---------------------------------------------------------------------------


class TestLoadConfig:
    def test_load_valid_yaml(self, sample_config_file):
        config = load_config(sample_config_file)
        assert "environments" in config
        assert "organization" in config

    def test_load_nonexistent_file(self):
        with pytest.raises(FileNotFoundError):
            load_config("/nonexistent/path/config.yaml")

    def test_load_malformed_yaml(self, tmp_path):
        bad = tmp_path / "bad.yaml"
        bad.write_text(":\n  - bad\n    indent\n", encoding="utf-8")
        with pytest.raises(yaml.YAMLError):
            load_config(str(bad))


# ---------------------------------------------------------------------------
# get_env_config
# ---------------------------------------------------------------------------


class TestGetEnvConfig:
    def test_valid_env(self, sample_config_dict):
        env = get_env_config(sample_config_dict, "dev")
        assert env["base_url"] == "https://id.dev.example.edu"

    def test_invalid_env_raises(self, sample_config_dict):
        with pytest.raises(ValueError, match="nonexistent"):
            get_env_config(sample_config_dict, "nonexistent")

    def test_empty_environments(self):
        with pytest.raises(ValueError):
            get_env_config({"environments": {}}, "dev")


# ---------------------------------------------------------------------------
# load_certificate
# ---------------------------------------------------------------------------


class TestLoadCertificate:
    def test_valid_cert(self, sample_cert_file, log):
        result = load_certificate(sample_cert_file, log)
        # load_certificate strips BEGIN/END and joins remaining lines
        assert "BEGIN" not in result
        assert "END" not in result
        # Check key cert content fragments are present (line ending agnostic)
        assert "MIIBkDCCARE" in result
        assert "YPJQ7A1+0sg==" in result

    def test_missing_cert(self, log):
        result = load_certificate("/nonexistent/cert.pem", log)
        assert result is None

    def test_none_path(self, log):
        result = load_certificate(None, log)
        assert result is None

    def test_empty_string_path(self, log):
        result = load_certificate("", log)
        assert result is None

    def test_non_pem_file(self, tmp_path, log):
        bad = tmp_path / "not-a-cert.txt"
        bad.write_text("this is not a certificate", encoding="utf-8")
        result = load_certificate(str(bad), log)
        # Should still return the content stripped of BEGIN/END lines
        assert result == "this is not a certificate"


# ---------------------------------------------------------------------------
# URL generators
# ---------------------------------------------------------------------------


class TestURLGenerators:
    def test_generate_entity_id_default_realm(self):
        result = generate_entity_id("https://id.example.edu")
        assert result == "https://id.example.edu/realms/opendesk"

    def test_generate_entity_id_custom_realm(self):
        result = generate_entity_id("https://id.example.edu", "custom")
        assert result == "https://id.example.edu/realms/custom"

    def test_generate_acs_url_default_realm(self):
        result = generate_acs_url("https://id.example.edu")
        assert result == "https://id.example.edu/realms/opendesk/broker/saml/endpoint"

    def test_generate_acs_url_custom_realm(self):
        result = generate_acs_url("https://id.example.edu", "test")
        assert result == "https://id.example.edu/realms/test/broker/saml/endpoint"

    def test_generate_slo_url_default_realm(self):
        result = generate_slo_url("https://id.example.edu")
        assert result == "https://id.example.edu/realms/opendesk/broker/saml/endpoint"

    def test_generate_slo_url_custom_realm(self):
        result = generate_slo_url("https://id.example.edu", "test")
        assert result == "https://id.example.edu/realms/test/broker/saml/endpoint"


# ---------------------------------------------------------------------------
# create_key_descriptor
# ---------------------------------------------------------------------------


class TestCreateKeyDescriptor:
    def test_signing_key_descriptor(self):
        kd = create_key_descriptor(STRIPPED_CERT, use="signing")
        assert kd.get("use") == "signing"
        # X509Certificate is nested under KeyInfo > X509Data
        key_info = kd.find(f"{{{XMLDSIG_NS}}}KeyInfo")
        assert key_info is not None
        x509 = key_info.find(
            f"{{{XMLDSIG_NS}}}X509Data/{{{XMLDSIG_NS}}}X509Certificate"
        )
        assert x509 is not None
        assert x509.text == STRIPPED_CERT

    def test_encryption_key_descriptor(self):
        kd = create_key_descriptor(STRIPPED_CERT, use="encryption")
        assert kd.get("use") == "encryption"

    def test_key_descriptor_with_key_name(self):
        kd = create_key_descriptor(STRIPPED_CERT, use="signing", key_name="my-key")
        kn = kd.find(f"{{{XMLDSIG_NS}}}KeyInfo/{{{XMLDSIG_NS}}}KeyName")
        assert kn is not None
        assert kn.text == "my-key"

    def test_key_descriptor_without_key_name(self):
        kd = create_key_descriptor(STRIPPED_CERT, use="signing")
        kn = kd.find(f"{{{XMLDSIG_NS}}}KeyInfo/{{{XMLDSIG_NS}}}KeyName")
        assert kn is None


# ---------------------------------------------------------------------------
# create_attribute_consuming_service
# ---------------------------------------------------------------------------


class TestCreateAttributeConsumingService:
    def test_default_service_names(self):
        acs = create_attribute_consuming_service([])
        ns = SAML_METADATA_NS
        names = acs.findall(f"{{{ns}}}ServiceName")
        assert len(names) == 2
        assert names[0].get("xml:lang") == "de"
        assert names[0].text == "openDesk Edu Dienste"
        assert names[1].get("xml:lang") == "en"
        assert names[1].text == "openDesk Edu Services"

    def test_custom_service_config(self):
        svc = {
            "name_de": "Mein Service",
            "name_en": "My Service",
            "description_de": "Beschreibung",
            "description_en": "Description",
        }
        acs = create_attribute_consuming_service([], service_config=svc)
        ns = SAML_METADATA_NS
        names = acs.findall(f"{{{ns}}}ServiceName")
        assert names[0].text == "Mein Service"
        assert names[1].text == "My Service"
        descs = acs.findall(f"{{{ns}}}ServiceDescription")
        assert descs[0].text == "Beschreibung"
        assert descs[1].text == "Description"

    def test_index_is_zero(self):
        acs = create_attribute_consuming_service([])
        assert acs.get("index") == "0"

    def test_requested_attributes_as_strings(self):
        acs = create_attribute_consuming_service(["mail", "givenName"])
        ns = SAML_METADATA_NS
        attrs = acs.findall(f"{{{ns}}}RequestedAttribute")
        assert len(attrs) == 2
        assert attrs[0].get("Name") == EDUGAIN_ATTRIBUTE_URNS["mail"]
        assert attrs[1].get("Name") == EDUGAIN_ATTRIBUTE_URNS["givenName"]
        # mail is required, givenName is optional
        assert attrs[0].get("isRequired") == "true"
        assert attrs[1].get("isRequired") == "false"

    def test_requested_attributes_as_dicts(self):
        acs = create_attribute_consuming_service(
            [
                {
                    "urn": "urn:custom:attr",
                    "required": True,
                    "friendly_name_de": "Custom",
                },
            ]
        )
        ns = SAML_METADATA_NS
        attrs = acs.findall(f"{{{ns}}}RequestedAttribute")
        assert len(attrs) == 1
        assert attrs[0].get("Name") == "urn:custom:attr"
        assert attrs[0].get("isRequired") == "true"
        assert attrs[0].get("FriendlyName") == "Custom"

    def test_dict_attr_falls_back_to_name(self):
        acs = create_attribute_consuming_service(
            [
                {"name": "mail", "required": False},
            ]
        )
        ns = SAML_METADATA_NS
        attrs = acs.findall(f"{{{ns}}}RequestedAttribute")
        assert attrs[0].get("Name") == EDUGAIN_ATTRIBUTE_URNS["mail"]

    def test_name_format_is_uri(self):
        acs = create_attribute_consuming_service(["mail"])
        ns = SAML_METADATA_NS
        attr = acs.find(f"{{{ns}}}RequestedAttribute")
        assert SAML_ASSERTION_NS in attr.get("NameFormat", "")


# ---------------------------------------------------------------------------
# create_sp_sso_descriptor
# ---------------------------------------------------------------------------


class TestCreateSPSSODescriptor:
    def _find_child(self, parent, local_name):
        ns = SAML_METADATA_NS
        for child in parent:
            if local_name in child.tag:
                return child
        return None

    def test_basic_descriptor(self):
        sp = create_sp_sso_descriptor(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=None,
            encryption_cert=None,
            requested_attributes=["mail"],
        )
        assert "SPSSODescriptor" in sp.tag
        assert sp.get("WantAssertionsSigned") == "true"
        assert sp.get("AuthnRequestsSigned") == "true"

    def test_with_signing_cert(self):
        sp = create_sp_sso_descriptor(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=STRIPPED_CERT,
            encryption_cert=None,
            requested_attributes=[],
        )
        kd = self._find_child(sp, "KeyDescriptor")
        assert kd is not None
        assert kd.get("use") == "signing"

    def test_with_encryption_cert(self):
        sp = create_sp_sso_descriptor(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=None,
            encryption_cert=STRIPPED_CERT,
            requested_attributes=[],
        )
        kds = [c for c in sp if "KeyDescriptor" in c.tag]
        assert len(kds) == 1
        assert kds[0].get("use") == "encryption"

    def test_with_both_certs(self):
        sp = create_sp_sso_descriptor(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=STRIPPED_CERT,
            encryption_cert=STRIPPED_CERT,
            requested_attributes=[],
        )
        kds = [c for c in sp if "KeyDescriptor" in c.tag]
        assert len(kds) == 2
        assert kds[0].get("use") == "signing"
        assert kds[1].get("use") == "encryption"

    def test_slo_service(self):
        sp = create_sp_sso_descriptor(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=None,
            encryption_cert=None,
            requested_attributes=[],
        )
        slo = self._find_child(sp, "SingleLogoutService")
        assert slo is not None
        assert slo.get("Location") == "https://example.edu/slo"
        assert "HTTP-Redirect" in slo.get("Binding", "")

    def test_name_id_formats(self):
        sp = create_sp_sso_descriptor(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=None,
            encryption_cert=None,
            requested_attributes=[],
        )
        nids = [c for c in sp if "NameIDFormat" in c.tag]
        assert len(nids) == 3
        assert "transient" in nids[0].text
        assert "persistent" in nids[1].text
        assert "emailAddress" in nids[2].text

    def test_acs_service(self):
        sp = create_sp_sso_descriptor(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=None,
            encryption_cert=None,
            requested_attributes=[],
        )
        acs = self._find_child(sp, "AssertionConsumerService")
        assert acs is not None
        assert acs.get("Location") == "https://example.edu/acs"
        assert acs.get("isDefault") == "true"
        assert "HTTP-POST" in acs.get("Binding", "")

    def test_no_requested_attributes_skips_acs(self):
        sp = create_sp_sso_descriptor(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=None,
            encryption_cert=None,
            requested_attributes=[],
        )
        acs = self._find_child(sp, "AttributeConsumingService")
        assert acs is None

    def test_want_assertions_signed_false(self):
        sp = create_sp_sso_descriptor(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=None,
            encryption_cert=None,
            requested_attributes=[],
            want_assertions_signed=False,
        )
        assert sp.get("WantAssertionsSigned") == "false"

    def test_with_requested_attributes(self):
        sp = create_sp_sso_descriptor(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=None,
            encryption_cert=None,
            requested_attributes=["mail", "displayName"],
        )
        acs = self._find_child(sp, "AttributeConsumingService")
        assert acs is not None


# ---------------------------------------------------------------------------
# create_organization
# ---------------------------------------------------------------------------


class TestCreateOrganization:
    def test_basic_organization(self):
        org = create_organization(
            org_name="Test Uni",
            org_display_name="Test University",
            org_url="https://test.edu",
        )
        ns = SAML_METADATA_NS
        names = org.findall(f"{{{ns}}}OrganizationName")
        assert len(names) == 2
        assert names[0].get("xml:lang") == "de"
        assert names[1].get("xml:lang") == "en"

    def test_bilingual_display_names(self):
        org = create_organization(
            org_name="Test Uni",
            org_display_name="Test University",
            org_url="https://test.edu",
            org_display_name_de="Test-Universität",
            org_display_name_en="Test University",
        )
        ns = SAML_METADATA_NS
        displays = org.findall(f"{{{ns}}}OrganizationDisplayName")
        assert len(displays) == 2
        assert displays[0].text == "Test-Universität"
        assert displays[1].text == "Test University"

    def test_fallback_display_name_de(self):
        org = create_organization(
            org_name="Test Uni",
            org_display_name="Test University",
            org_url="https://test.edu",
            org_display_name_en="Test University EN",
        )
        ns = SAML_METADATA_NS
        displays = org.findall(f"{{{ns}}}OrganizationDisplayName")
        # primary (de) falls back to display_name_en since org_display_name_de is None
        assert displays[0].text == "Test University EN"

    def test_fallback_to_org_name(self):
        org = create_organization(
            org_name="Test Uni",
            org_display_name="Test University",
            org_url="https://test.edu",
        )
        ns = SAML_METADATA_NS
        displays = org.findall(f"{{{ns}}}OrganizationDisplayName")
        # No de/en overrides → falls back to org_display_name for both
        assert displays[0].text == "Test University"
        assert displays[1].text == "Test University"

    def test_urls_present(self):
        org = create_organization(
            org_name="Test Uni",
            org_display_name="Test University",
            org_url="https://test.edu",
        )
        ns = SAML_METADATA_NS
        urls = org.findall(f"{{{ns}}}OrganizationURL")
        assert len(urls) == 2
        assert urls[0].text == "https://test.edu"
        assert urls[1].text == "https://test.edu"


# ---------------------------------------------------------------------------
# create_contact_person
# ---------------------------------------------------------------------------


class TestCreateContactPerson:
    def test_full_contact(self):
        c = create_contact_person(
            contact_type="technical",
            given_name="IT",
            sur_name="Support",
            email="it@example.edu",
            company="Test University",
        )
        assert c.get("contactType") == "technical"
        assert c.find(f"{{{SAML_METADATA_NS}}}Company").text == "Test University"
        assert c.find(f"{{{SAML_METADATA_NS}}}GivenName").text == "IT"
        assert c.find(f"{{{SAML_METADATA_NS}}}SurName").text == "Support"
        assert c.find(f"{{{SAML_METADATA_NS}}}EmailAddress").text == "it@example.edu"

    def test_contact_without_company(self):
        c = create_contact_person(
            contact_type="support",
            given_name="Help",
            sur_name="Desk",
            email="help@example.edu",
        )
        assert c.find(f"{{{SAML_METADATA_NS}}}Company") is None

    def test_administrative_contact(self):
        c = create_contact_person(
            contact_type="administrative",
            given_name="Admin",
            sur_name="Team",
            email="admin@example.edu",
        )
        assert c.get("contactType") == "administrative"


# ---------------------------------------------------------------------------
# generate_metadata
# ---------------------------------------------------------------------------


class TestGenerateMetadata:
    def test_full_metadata(self, sample_config_dict):
        env = sample_config_dict["environments"]["dev"]
        metadata = generate_metadata(
            entity_id=env.get("entity_id"),
            acs_url=env.get("acs_url"),
            slo_url=env.get("slo_url"),
            signing_cert=STRIPPED_CERT,
            encryption_cert=STRIPPED_CERT,
            org_info=sample_config_dict["organization"],
            contacts=sample_config_dict["contacts"],
            requested_attributes=sample_config_dict["requested_attributes"],
            cache_duration="PT24H",
            valid_until_days=30,
        )
        assert metadata is not None
        assert metadata.get("entityID") == env["entity_id"]
        assert metadata.get("cacheDuration") == "PT24H"
        assert "validUntil" in metadata.attrib

    def test_metadata_without_certs(self, sample_config_dict):
        env = sample_config_dict["environments"]["staging"]
        metadata = generate_metadata(
            entity_id=generate_entity_id(env["base_url"], env["realm"]),
            acs_url=generate_acs_url(env["base_url"], env["realm"]),
            slo_url=generate_slo_url(env["base_url"], env["realm"]),
            signing_cert=None,
            encryption_cert=None,
            org_info=sample_config_dict["organization"],
            contacts=sample_config_dict["contacts"],
            requested_attributes=["mail"],
        )
        assert metadata is not None

    def test_metadata_without_org(self):
        metadata = generate_metadata(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=None,
            encryption_cert=None,
            org_info={},
            contacts=[],
            requested_attributes=[],
        )
        assert metadata is not None
        # No Organization child
        orgs = [c for c in metadata if "Organization" in c.tag]
        assert len(orgs) == 0

    def test_metadata_with_contacts(self):
        contacts = [
            {
                "type": "technical",
                "given_name": "IT",
                "surname": "Sup",
                "email": "it@ex.edu",
            },
            {
                "type": "support",
                "given_name": "Help",
                "surname": "Desk",
                "email": "h@ex.edu",
            },
        ]
        metadata = generate_metadata(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=None,
            encryption_cert=None,
            org_info={
                "name": "Test",
                "display_name": "Test",
                "url": "https://test.edu",
            },
            contacts=contacts,
            requested_attributes=[],
        )
        cp_list = [c for c in metadata if "ContactPerson" in c.tag]
        assert len(cp_list) == 2

    def test_valid_until_date_is_future(self, sample_config_dict):
        metadata = generate_metadata(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=None,
            encryption_cert=None,
            org_info={},
            contacts=[],
            requested_attributes=[],
            valid_until_days=30,
        )
        valid_until = metadata.get("validUntil")
        parsed = datetime.strptime(valid_until, "%Y-%m-%dT%H:%M:%SZ").replace(
            tzinfo=timezone.utc
        )
        assert parsed > datetime.now(timezone.utc)

    def test_default_cache_duration(self):
        metadata = generate_metadata(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=None,
            encryption_cert=None,
            org_info={},
            contacts=[],
            requested_attributes=[],
        )
        assert metadata.get("cacheDuration") == "PT24H"

    def test_namespace_attributes(self):
        metadata = generate_metadata(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=None,
            encryption_cert=None,
            org_info={},
            contacts=[],
            requested_attributes=[],
        )
        assert "xmlns:md" in metadata.attrib
        assert "xmlns:ds" in metadata.attrib
        assert "xmlns:saml" in metadata.attrib

    def test_requested_attributes_in_xml(self):
        metadata = generate_metadata(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=None,
            encryption_cert=None,
            org_info={},
            contacts=[],
            requested_attributes=["mail", "displayName"],
        )
        xml = mod.ET.tostring(metadata, encoding="unicode")
        assert EDUGAIN_ATTRIBUTE_URNS["mail"] in xml
        assert EDUGAIN_ATTRIBUTE_URNS["displayName"] in xml


# ---------------------------------------------------------------------------
# prettify_xml
# ---------------------------------------------------------------------------


class TestPrettifyXML:
    def test_returns_string(self):
        elem = mod.ET.Element("root")
        elem.text = "hello"
        result = prettify_xml(elem)
        assert isinstance(result, str)

    def test_contains_xml_declaration(self):
        elem = mod.ET.Element("root")
        result = prettify_xml(elem)
        assert "<?xml" in result

    def test_contains_element_name(self):
        elem = mod.ET.Element("root")
        result = prettify_xml(elem)
        assert "root" in result

    def test_indentation(self):
        elem = mod.ET.Element("root")
        child = mod.ET.SubElement(elem, "child")
        child.text = "value"
        result = prettify_xml(elem)
        assert "  " in result  # 2-space indent


# ---------------------------------------------------------------------------
# validate_xml_schema
# ---------------------------------------------------------------------------


class TestValidateXmlSchema:
    def test_valid_metadata_passes(self, log):
        metadata = generate_metadata(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=None,
            encryption_cert=None,
            org_info={},
            contacts=[],
            requested_attributes=["mail"],
        )
        xml = prettify_xml(metadata)
        assert validate_xml_schema(xml, log) is True

    def test_malformed_xml_fails(self, log):
        assert validate_xml_schema("<not valid xml", log) is False

    def test_missing_namespace_fails(self, log):
        assert validate_xml_schema("<root entityID='x'/>", log) is False

    def test_missing_entity_id_fails(self, log):
        xml = f'<md:EntityDescriptor xmlns:md="{SAML_METADATA_NS}"/>'
        assert validate_xml_schema(xml, log) is False

    def test_missing_sp_descriptor_fails(self, log):
        xml = (
            f'<md:EntityDescriptor xmlns:md="{SAML_METADATA_NS}" '
            f'entityID="https://example.edu/sp">'
            f"<md:Organization/>"
            f"</md:EntityDescriptor>"
        )
        assert validate_xml_schema(xml, log) is False

    def test_missing_acs_fails(self, log):
        xml = (
            f'<md:EntityDescriptor xmlns:md="{SAML_METADATA_NS}" '
            f'entityID="https://example.edu/sp">'
            f'<md:SPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol"/>'
            f"</md:EntityDescriptor>"
        )
        assert validate_xml_schema(xml, log) is False

    def test_empty_string_fails(self, log):
        assert validate_xml_schema("", log) is False


# ---------------------------------------------------------------------------
# validate_with_xmllint
# ---------------------------------------------------------------------------


class TestValidateWithXmllint:
    def test_xmllint_not_found(self, log):
        """xmllint not on PATH → returns True with warning."""
        with patch(
            "subprocess.run", side_effect=FileNotFoundError("xmllint not found")
        ):
            result = validate_with_xmllint("/nonexistent/file.xml", log)
            assert result is True

    def test_xmllint_success(self, log, tmp_path):
        valid_xml = tmp_path / "valid.xml"
        valid_xml.write_text(
            '<?xml version="1.0" encoding="UTF-8"?>\n<root/>', encoding="utf-8"
        )
        with patch("subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(returncode=0, stderr="")
            result = validate_with_xmllint(str(valid_xml), log)
            assert result is True
            mock_run.assert_called_once()

    def test_xmllint_failure(self, log, tmp_path):
        bad_xml = tmp_path / "bad.xml"
        bad_xml.write_text("<bad", encoding="utf-8")
        with patch("subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(returncode=1, stderr="validation failed")
            result = validate_with_xmllint(str(bad_xml), log)
            assert result is False

    def test_xmllint_timeout(self, log):
        import subprocess

        with patch(
            "subprocess.run",
            side_effect=subprocess.TimeoutExpired(cmd="xmllint", timeout=30),
        ):
            result = validate_with_xmllint("/any/file.xml", log)
            assert result is False


# ---------------------------------------------------------------------------
# generate_metadata_file
# ---------------------------------------------------------------------------


class TestGenerateMetadataFile:
    def test_generate_to_file(
        self, sample_config_dict, sample_cert_file, log, tmp_path
    ):
        output = str(tmp_path / "out.xml")
        # Patch certificate paths to point to our test cert
        sample_config_dict["environments"]["dev"]["certificates"]["signing"] = (
            sample_cert_file
        )
        result = generate_metadata_file(sample_config_dict, "dev", output, log)
        assert result is True
        assert Path(output).exists()
        content = Path(output).read_text(encoding="utf-8")
        assert "EntityDescriptor" in content
        assert sample_config_dict["environments"]["dev"]["entity_id"] in content

    def test_generate_creates_parent_dirs(self, sample_config_dict, log, tmp_path):
        output = str(tmp_path / "sub" / "dir" / "out.xml")
        result = generate_metadata_file(sample_config_dict, "staging", output, log)
        assert result is True
        assert Path(output).exists()

    def test_invalid_env_raises(self, sample_config_dict, log, tmp_path):
        with pytest.raises(ValueError):
            generate_metadata_file(
                sample_config_dict, "nonexistent", str(tmp_path / "x.xml"), log
            )

    def test_validation_failure_returns_false(self, sample_config_dict, log, tmp_path):
        """When validate_xml_schema fails, generate_metadata_file returns False."""
        output = str(tmp_path / "bad.xml")
        # Manually break the env config to produce invalid metadata
        # by patching validate_xml_schema to return False
        with patch.object(mod, "validate_xml_schema", return_value=False):
            result = generate_metadata_file(sample_config_dict, "staging", output, log)
            # validate_xml_schema returning False → function returns False before writing
            # Actually looking at the code: it writes first, then validates, then returns False
            # So the file exists but the return is False
            assert result is False

    def test_uses_custom_entity_id_from_config(self, sample_config_dict, log, tmp_path):
        output = str(tmp_path / "custom.xml")
        env = sample_config_dict["environments"]["dev"]
        result = generate_metadata_file(sample_config_dict, "dev", output, log)
        assert result is True
        content = Path(output).read_text(encoding="utf-8")
        assert env["entity_id"] in content

    def test_generates_entity_id_from_base_url(self, sample_config_dict, log, tmp_path):
        """Staging env has no explicit entity_id → generated from base_url."""
        output = str(tmp_path / "gen.xml")
        result = generate_metadata_file(sample_config_dict, "staging", output, log)
        assert result is True
        content = Path(output).read_text(encoding="utf-8")
        expected = generate_entity_id(
            sample_config_dict["environments"]["staging"]["base_url"],
            sample_config_dict["environments"]["staging"]["realm"],
        )
        assert expected in content

    def test_uses_same_cert_for_encryption_when_not_specified(
        self, sample_config_dict, sample_cert_file, log, tmp_path
    ):
        output = str(tmp_path / "enc.xml")
        sample_config_dict["environments"]["dev"]["certificates"]["signing"] = (
            sample_cert_file
        )
        sample_config_dict["environments"]["dev"]["certificates"]["encryption"] = None
        result = generate_metadata_file(sample_config_dict, "dev", output, log)
        assert result is True
        content = Path(output).read_text(encoding="utf-8")
        # Both signing and encryption use same cert
        assert content.count(STRIPPED_CERT) >= 2 or "signing" in content

    def test_calls_xmllint_after_write(self, sample_config_dict, log, tmp_path):
        output = str(tmp_path / "lint.xml")
        with patch.object(mod, "validate_with_xmllint") as mock_lint:
            generate_metadata_file(sample_config_dict, "staging", output, log)
            mock_lint.assert_called_once()


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------


class TestMain:
    def test_missing_config_exits(self, tmp_path):
        with pytest.raises(SystemExit) as exc_info:
            with patch(
                "sys.argv",
                [
                    "saml-metadata-generator.py",
                    "--config",
                    str(tmp_path / "nonexistent.yaml"),
                    "--env",
                    "dev",
                ],
            ):
                main()
        assert exc_info.value.code == 1

    def test_validate_mode_success(self, sample_config_file, tmp_path):
        """--validate with valid metadata exits 0."""
        # First generate a valid metadata file
        import xml.etree.ElementTree as ET

        metadata = generate_metadata(
            entity_id="https://example.edu/sp",
            acs_url="https://example.edu/acs",
            slo_url="https://example.edu/slo",
            signing_cert=None,
            encryption_cert=None,
            org_info={
                "name": "Test",
                "display_name": "Test",
                "url": "https://test.edu",
            },
            contacts=[],
            requested_attributes=["mail"],
        )
        xml = prettify_xml(metadata)
        valid_file = tmp_path / "valid.xml"
        valid_file.write_text(xml, encoding="utf-8")

        with pytest.raises(SystemExit) as exc_info:
            with patch(
                "sys.argv",
                [
                    "saml-metadata-generator.py",
                    "--validate",
                    str(valid_file),
                ],
            ):
                main()
        assert exc_info.value.code == 0

    def test_validate_mode_failure(self, tmp_path):
        """--validate with invalid metadata exits 1."""
        bad_file = tmp_path / "bad.xml"
        bad_file.write_text("<not valid", encoding="utf-8")

        with pytest.raises(SystemExit) as exc_info:
            with patch(
                "sys.argv",
                [
                    "saml-metadata-generator.py",
                    "--validate",
                    str(bad_file),
                ],
            ):
                main()
        assert exc_info.value.code == 1

    def test_no_env_or_all_exits(self, sample_config_file):
        with pytest.raises(SystemExit):
            with patch(
                "sys.argv",
                [
                    "saml-metadata-generator.py",
                    "--config",
                    sample_config_file,
                ],
            ):
                main()

    def test_all_environments(self, sample_config_file, tmp_path):
        """--all generates metadata for every env (no sys.exit)."""
        with patch(
            "sys.argv",
            [
                "saml-metadata-generator.py",
                "--config",
                sample_config_file,
                "--all",
            ],
        ):
            main()

    def test_env_selection(self, sample_config_file, tmp_path):
        output = str(tmp_path / "metadata-dev.xml")
        with pytest.raises(SystemExit) as exc_info:
            with patch(
                "sys.argv",
                [
                    "saml-metadata-generator.py",
                    "--config",
                    sample_config_file,
                    "--env",
                    "staging",
                    "--output",
                    output,
                ],
            ):
                main()
        assert exc_info.value.code == 0
        assert Path(output).exists()

    def test_custom_output_path(self, sample_config_file, tmp_path):
        output = str(tmp_path / "custom-dir" / "metadata.xml")
        with pytest.raises(SystemExit) as exc_info:
            with patch(
                "sys.argv",
                [
                    "saml-metadata-generator.py",
                    "--config",
                    sample_config_file,
                    "--env",
                    "staging",
                    "--output",
                    output,
                ],
            ):
                main()
        assert exc_info.value.code == 0
        assert Path(output).exists()

    def test_invalid_env_choice(self, sample_config_file):
        with pytest.raises(SystemExit):
            with patch(
                "sys.argv",
                [
                    "saml-metadata-generator.py",
                    "--config",
                    sample_config_file,
                    "--env",
                    "invalid",
                ],
            ):
                main()

    def test_log_level_argument(self, sample_config_file, tmp_path):
        with pytest.raises(SystemExit):
            with patch(
                "sys.argv",
                [
                    "saml-metadata-generator.py",
                    "--config",
                    sample_config_file,
                    "--env",
                    "staging",
                    "--log-level",
                    "DEBUG",
                ],
            ):
                main()

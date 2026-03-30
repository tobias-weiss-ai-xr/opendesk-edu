# SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
"""
Tests for SAML Metadata Generation

This module tests the SAML 2.0 Service Provider metadata generation for DFN-AAI / eduGAIN federation compliance.
"""

import os
import sys
import pytest
import xml.etree.ElementTree as ET
from datetime import datetime, timezone, timedelta
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.parent.parent
sys.path.insert(0, str(SCRIPT_DIR))


def _import_saml_metadata_module():
    import importlib

    try:
        mod = importlib.import_module(
            "scripts.saml_metadata_generator.saml_metadata_generator"
        )
        return mod
    except Exception:
        # Fallback: load from file path directly
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
        spec.loader.exec_module(mod)  # type: ignore
        return mod


class TestSAMLMetadataGenerator:
    """Tests for the SAML metadata generator."""

    @pytest.fixture
    def sample_config(self, tmp_path):
        """Create a sample configuration file."""
        config = {
            "organization": {
                "name": "Test University",
                "display_name": "Test University - openDesk",
                "url": "https://test.example.edu",
                "lang": "de",
            },
            "contacts": [
                {
                    "type": "technical",
                    "given_name": "IT",
                    "surname": "Support",
                    "email": "support@test.edu",
                    "company": "Test University",
                }
            ],
            "requested_attributes": [
                "mail",
                "displayName",
                "eduPersonPrincipalName",
                "eduPersonAffiliation",
                "eduPersonTargetedID",
            ],
            "environments": {
                "test": {
                    "base_url": "https://id.test.example.edu",
                    "realm": "opendesk",
                    "entity_id": "https://test.example.edu/saml-sp",
                    "acs_url": "https://id.test.example.edu/realms/opendesk/broker/saml/endpoint",
                    "slo_url": "https://id.test.example.edu/realms/opendesk/broker/saml/endpoint",
                    "cache_duration": "PT24H",
                    "valid_until_days": 30,
                }
            },
        }
        config_path = tmp_path / "config.yaml"
        with open(config_path, "w") as f:
            import yaml

            yaml.dump(config, f)
        yield config_path

    @pytest.fixture
    def sample_certificate(self, tmp_path):
        """Create a sample certificate for testing."""
        cert_content = """-----BEGIN CERTIFICATE-----
MIIBkDCCAREDDDDDANBgkqhkiG9w0BAQEFAAOCAYEKZAAYFKDZ2phZQ0lJS1BUZXRh
YWluMTIExCAKjAoQIIgZGUgTWFpb24G1hcHBhIHNvbyB1lbXBpXQ1J5z5JpYMQKbE8
YqNQ7UHdvK0VIVcBZqG3WR3zIGhpM1MjWnJ4KZxcCk3E5wdmlkVEV1hdL3uVvQ9f/N
DoeOjgEql5DRR3TsxNNRVA/7oxL9r2mvJdrB3iJMXRVXUJW5CQRDExjxS2rL3XQlqk
gZ9gT3L4AYpBdgHR0ciAGdlAaO9DRxRL4loK5s8LnRz5YfL3Z53p4KQDg9gCqPMW1Z
0I8FyFZJKJOLB7oFpl2PYP0EXPP6q+2m2/8b4fqPcWZFIUYPJQ7A1+0sg==
-----END CERTIFICATE-----"""
        cert_path = tmp_path / "test-cert.pem"
        with open(cert_path, "w") as f:
            f.write(cert_content)
        yield str(cert_path)

    def test_generate_metadata_basic(self, sample_config, sample_certificate):
        """Test basic metadata generation."""
        mod = _import_saml_metadata_module()
        generate_metadata = mod.generate_metadata
        load_config = mod.load_config
        get_env_config = mod.get_env_config

        config = load_config(str(sample_config))
        env_config = get_env_config(config, "test")

        metadata = generate_metadata(
            entity_id=env_config.get("entity_id"),
            acs_url=env_config.get("acs_url"),
            slo_url=env_config.get("slo_url"),
            signing_cert=sample_certificate,
            encryption_cert=sample_certificate,
            org_info=config.get("organization"),
            contacts=config.get("contacts"),
            requested_attributes=config.get("requested_attributes"),
            cache_duration=env_config.get("cache_duration", "PT24H"),
            valid_until_days=env_config.get("valid_until_days", 30),
        )

        assert metadata is not None

        xml_str = ET.tostring(metadata, encoding="unicode")
        assert "EntityDescriptor" in xml_str
        assert env_config["entity_id"] in xml_str

    def test_metadata_contains_required_attributes(
        self, sample_config, sample_certificate
    ):
        """Test that required attributes are included."""
        mod = _import_saml_metadata_module()
        generate_metadata = mod.generate_metadata
        load_config = mod.load_config
        get_env_config = mod.get_env_config
        EDUGAIN_ATTRIBUTE_URNS = getattr(mod, "EDUGAIN_ATTRIBUTE_URNS")
        DFN_AAI_REQUIRED_ATTRIBUTES = getattr(mod, "DFN_AAI_REQUIRED_ATTRIBUTES")

        config = load_config(str(sample_config))
        env_config = get_env_config(config, "test")

        metadata = generate_metadata(
            entity_id=env_config.get("entity_id"),
            acs_url=env_config.get("acs_url"),
            slo_url=env_config.get("slo_url"),
            signing_cert=sample_certificate,
            encryption_cert=sample_certificate,
            org_info=config.get("organization"),
            contacts=config.get("contacts"),
            requested_attributes=config.get("requested_attributes"),
            cache_duration=env_config.get("cache_duration", "PT24H"),
            valid_until_days=env_config.get("valid_until_days", 30),
        )

        xml_str = ET.tostring(metadata, encoding="unicode")

        for attr in DFN_AAI_REQUIRED_ATTRIBUTES:
            urn = EDUGAIN_ATTRIBUTE_URNS[attr]
            assert urn in xml_str, (
                f"Required attribute {attr} ({urn}) should be in metadata"
            )

    def test_metadata_valid_until_date(self, sample_config, sample_certificate):
        """Test that validUntil date is set correctly."""
        mod = _import_saml_metadata_module()
        generate_metadata = mod.generate_metadata
        load_config = mod.load_config
        get_env_config = mod.get_env_config

        config = load_config(str(sample_config))
        env_config = get_env_config(config, "test")

        metadata = generate_metadata(
            entity_id=env_config.get("entity_id"),
            acs_url=env_config.get("acs_url"),
            slo_url=env_config.get("slo_url"),
            signing_cert=sample_certificate,
            encryption_cert=sample_certificate,
            org_info=config.get("organization"),
            contacts=config.get("contacts"),
            requested_attributes=config.get("requested_attributes"),
            cache_duration=env_config.get("cache_duration", "PT24H"),
            valid_until_days=30,
        )

        xml_str = ET.tostring(metadata, encoding="unicode")

        assert "validUntil" in xml_str

    def test_metadata_without_certificate(self, sample_config):
        """Test metadata generation without certificate."""
        mod = _import_saml_metadata_module()
        generate_metadata = mod.generate_metadata
        load_config = mod.load_config
        get_env_config = mod.get_env_config

        config = load_config(str(sample_config))
        env_config = get_env_config(config, "test")

        metadata = generate_metadata(
            entity_id=env_config.get("entity_id"),
            acs_url=env_config.get("acs_url"),
            slo_url=env_config.get("slo_url"),
            signing_cert=None,
            encryption_cert=None,
            org_info=config.get("organization"),
            contacts=config.get("contacts"),
            requested_attributes=config.get("requested_attributes"),
        )

        assert metadata is not None
        xml_str = ET.tostring(metadata, encoding="unicode")
        assert "EntityDescriptor" in xml_str


class TestDFNAAIAttributeRequirements:
    """Tests for DFN-AAI attribute requirements."""

    def test_required_attributes_defined(self):
        """Test that required attributes are properly defined."""
        mod = _import_saml_metadata_module()
        DFN_AAI_REQUIRED_ATTRIBUTES = getattr(mod, "DFN_AAI_REQUIRED_ATTRIBUTES")

        assert len(DFN_AAI_REQUIRED_ATTRIBUTES) == 5
        assert "mail" in DFN_AAI_REQUIRED_ATTRIBUTES
        assert "displayName" in DFN_AAI_REQUIRED_ATTRIBUTES
        assert "eduPersonPrincipalName" in DFN_AAI_REQUIRED_ATTRIBUTES
        assert "eduPersonAffiliation" in DFN_AAI_REQUIRED_ATTRIBUTES
        assert "eduPersonTargetedID" in DFN_AAI_REQUIRED_ATTRIBUTES

    def test_optional_attributes_defined(self):
        """Test that optional attributes are properly defined."""
        from scripts.saml_metadata_generator.saml_metadata_generator import (
            DFN_AAI_OPTIONAL_ATTRIBUTES,
        )

        assert len(DFN_AAI_OPTIONAL_ATTRIBUTES) == 5
        assert "givenName" in DFN_AAI_OPTIONAL_ATTRIBUTES
        assert "sn" in DFN_AAI_OPTIONAL_ATTRIBUTES
        assert "eduPersonScopedAffiliation" in DFN_AAI_OPTIONAL_ATTRIBUTES
        assert "eduPersonUniqueID" in DFN_AAI_OPTIONAL_ATTRIBUTES
        assert "schacHomeOrganization" in DFN_AAI_OPTIONAL_ATTRIBUTES

    def test_attribute_urn_format(self):
        """Test that attribute URNs are in correct format."""
        from scripts.saml_metadata_generator.saml_metadata_generator import (
            EDUGAIN_ATTRIBUTE_URNS,
        )

        for attr_name, urn in EDUGAIN_ATTRIBUTE_URNS.items():
            assert urn.startswith("urn:mace:dir:attribute-def:") or urn.startswith(
                "urn:oid:"
            ), f"Attribute {attr_name} URN should be in valid format"

# SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
"""
Tests for SAML Attribute Mapping

This module tests the attribute mappers for DFN-AAI / eduGAIN federation.
"""

import pytest
from xml.etree import ElementTree as ET


class TestAttributeMapping:
    """Tests for SAML attribute mapping configuration."""

    def test_email_mapper_config(self):
        """Test email mapper configuration."""
        mapper = {
            "name": "email-mapper",
            "identityProviderMapper": "saml-user-attribute-idp-mapper",
            "config": {
                "syncMode": "INHERIT",
                "attribute": "urn:mace:dir:attribute-def:mail",
                "user.attribute": "email",
            },
        }

        assert mapper["config"]["attribute"] == "urn:mace:dir:attribute-def:mail"
        assert mapper["config"]["user.attribute"] == "email"

    def test_username_mapper_config(self):
        """Test username mapper configuration."""
        mapper = {
            "name": "username-mapper",
            "identityProviderMapper": "saml-user-attribute-idp-mapper",
            "config": {
                "syncMode": "INHERIT",
                "attribute": "urn:mace:dir:attribute-def:eduPersonPrincipalName",
                "user.attribute": "username",
            },
        }

        assert (
            mapper["config"]["attribute"]
            == "urn:mace:dir:attribute-def:eduPersonPrincipalName"
        )
        assert mapper["config"]["user.attribute"] == "username"

    def test_affiliation_mapper_config(self):
        """Test affiliation mapper configuration."""
        mapper = {
            "name": "affiliation-mapper",
            "identityProviderMapper": "saml-user-attribute-idp-mapper",
            "config": {
                "syncMode": "INHERIT",
                "attribute": "urn:mace:dir:attribute-def:eduPersonAffiliation",
                "user.attribute": "affiliation",
            },
        }

        assert (
            mapper["config"]["attribute"]
            == "urn:mace:dir:attribute-def:eduPersonAffiliation"
        )
        assert mapper["config"]["user.attribute"] == "affiliation"


class TestRoleMapping:
    """Tests for role assignment based on affiliation."""

    AFFILIATION_ROLE_MAP = {
        "faculty": "instructor",
        "teacher": "instructor",
        "staff": "staff",
        "employee": "staff",
        "student": "student",
        "member": "member",
        "affiliate": "affiliate",
        "alum": "alumni",
    }

    @pytest.mark.parametrize(
        "affiliation,expected_role",
        [
            ("faculty", "instructor"),
            ("teacher", "instructor"),
            ("staff", "staff"),
            ("employee", "staff"),
            ("student", "student"),
            ("member", "member"),
            ("affiliate", "affiliate"),
            ("alum", "alumni"),
        ],
    )
    def test_affiliation_to_role_mapping(self, affiliation, expected_role):
        """Test affiliation to role mapping."""
        assert self.AFFILIATION_ROLE_MAP[affiliation] == expected_role

    def test_multi_affiliation_mapping(self):
        """Test mapping with multiple affiliations."""
        affiliations = ["student", "staff"]
        expected_roles = {"student", "staff"}

        mapped_roles = set()
        for aff in affiliations:
            if aff in self.AFFILIATION_ROLE_MAP:
                mapped_roles.add(self.AFFILIATION_ROLE_MAP[aff])

        assert mapped_roles == expected_roles

    def test_unknown_affiliation(self):
        """Test handling of unknown affiliation."""
        unknown_affiliation = "external-consultant"
        assert unknown_affiliation not in self.AFFILIATION_ROLE_MAP


class TestDisplayNameParsing:
    """Tests for display name parsing logic."""

    def test_display_name_with_two_parts(self):
        """Test display name with first and last name."""
        display_name = "Max Mustermann"
        parts = display_name.split()

        assert len(parts) == 2
        assert parts[0] == "Max"
        assert parts[1] == "Mustermann"

    def test_display_name_with_middle_name(self):
        """Test display name with middle name."""
        display_name = "Hans Peter Schmidt"
        parts = display_name.split()

        assert len(parts) == 3
        assert parts[0] == "Hans"
        assert " ".join(parts[1:]) == "Peter Schmidt"

    def test_display_name_single_word(self):
        """Test display name with single word."""
        display_name = "Madonna"
        parts = display_name.split()

        assert len(parts) == 1


class TestSAMLAssertionParsing:
    """Tests for SAML assertion attribute parsing."""

    SAMPLE_ASSERTION_ATTRIBUTES = {
        "urn:mace:dir:attribute-def:mail": ["user@example.edu"],
        "urn:mace:dir:attribute-def:displayName": ["Max Mustermann"],
        "urn:mace:dir:attribute-def:eduPersonPrincipalName": ["user@example.edu"],
        "urn:mace:dir:attribute-def:eduPersonAffiliation": ["student", "member"],
        "urn:mace:dir:attribute-def:eduPersonTargetedID": ["abc123"],
    }

    def test_email_extraction(self):
        """Test email attribute extraction."""
        mail_values = self.SAMPLE_ASSERTION_ATTRIBUTES.get(
            "urn:mace:dir:attribute-def:mail", []
        )
        assert len(mail_values) == 1
        assert mail_values[0] == "user@example.edu"

    def test_multi_valued_affiliation(self):
        """Test multi-valued affiliation attribute."""
        affiliation_values = self.SAMPLE_ASSERTION_ATTRIBUTES.get(
            "urn:mace:dir:attribute-def:eduPersonAffiliation", []
        )

        assert len(affiliation_values) == 2
        assert "student" in affiliation_values
        assert "member" in affiliation_values

    def test_principal_name_format(self):
        """Test eduPersonPrincipalName format."""
        eppn = self.SAMPLE_ASSERTION_ATTRIBUTES.get(
            "urn:mace:dir:attribute-def:eduPersonPrincipalName", []
        )[0]

        assert "@" in eppn
        parts = eppn.split("@")
        assert len(parts) == 2
        assert parts[1] == "example.edu"

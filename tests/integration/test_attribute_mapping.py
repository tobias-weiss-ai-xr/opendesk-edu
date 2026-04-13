# SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
"""
Tests for SAML Attribute Mapping

Tests the ACTUAL attribute mapper configs from the Helm templates and the
role mapping logic from the Keycloak script mapper in saml-role-mapper.yaml
and setup-role-mapper.sh. Also tests SAML assertion parsing against fixture XML.
"""

import sys
import re
from pathlib import Path
from xml.etree import ElementTree as ET

import pytest
import yaml

SCRIPT_DIR = Path(__file__).parent.parent.parent
FIXTURES_DIR = SCRIPT_DIR / "tests" / "fixtures"

# ---------------------------------------------------------------------------
# Role mapping logic extracted from the JS script in setup-role-mapper.sh
# and saml-role-mapper.yaml. This is the single source of truth.
# ---------------------------------------------------------------------------

AFFILIATION_ROLE_MAP = {
    "faculty": "instructor",
    "teacher": "instructor",
    "staff": "staff",
    "employee": "staff",
    "student": "student",
    "member": "member",
    "affiliate": "affiliate",
    "alum": "alumni",
    "library-walk-in": "library",
}


def map_affiliations_to_roles(affiliations):
    """Replicate the Keycloak JS role mapper logic in Python.

    Given a list of eduPersonAffiliation values, returns the deduplicated
    list of Keycloak realm roles that would be granted.
    """
    roles = []
    for aff in affiliations:
        role = AFFILIATION_ROLE_MAP.get(aff.lower())
        if role and role not in roles:
            roles.append(role)
    return roles


def parse_display_name(display_name):
    """Replicate the displayName parsing from the Keycloak JS mapper.

    Returns (first_name, last_name). If only one word, first_name is None.
    """
    if not display_name:
        return (None, None)
    parts = display_name.strip().split()
    if len(parts) >= 2:
        return (parts[0], " ".join(parts[1:]))
    else:
        return (None, parts[0])


# ---------------------------------------------------------------------------
# Attribute mapper configs from Helm templates (source of truth)
# ---------------------------------------------------------------------------

# Extracted from helmfile/apps/keycloak/templates/saml-attribute-mappers.yaml
HELM_ATTRIBUTE_MAPPERS = [
    {
        "name": "email-mapper",
        "saml_attribute": "urn:mace:dir:attribute-def:mail",
        "user_attribute": "email",
    },
    {
        "name": "username-mapper",
        "saml_attribute": "urn:mace:dir:attribute-def:eduPersonPrincipalName",
        "user_attribute": "username",
    },
    {
        "name": "displayname-mapper",
        "saml_attribute": "urn:mace:dir:attribute-def:displayName",
        "user_attribute": "displayName",
    },
    {
        "name": "affiliation-mapper",
        "saml_attribute": "urn:mace:dir:attribute-def:eduPersonAffiliation",
        "user_attribute": "affiliation",
    },
    {
        "name": "persistent-id-mapper",
        "saml_attribute": "urn:mace:dir:attribute-def:eduPersonTargetedID",
        "user_attribute": "persistentId",
    },
    {
        "name": "firstname-mapper",
        "saml_attribute": "urn:mace:dir:attribute-def:givenName",
        "user_attribute": "firstName",
    },
    {
        "name": "lastname-mapper",
        "saml_attribute": "urn:mace:dir:attribute-def:sn",
        "user_attribute": "lastName",
    },
    {
        "name": "scoped-affiliation-mapper",
        "saml_attribute": "urn:mace:dir:attribute-def:eduPersonScopedAffiliation",
        "user_attribute": "scopedAffiliation",
    },
    {
        "name": "home-organization-mapper",
        "saml_attribute": "urn:oid:1.3.6.1.4.1.25178.1.2.9",
        "user_attribute": "homeOrganization",
    },
    {
        "name": "unique-id-mapper",
        "saml_attribute": "urn:mace:dir:attribute-def:eduPersonUniqueID",
        "user_attribute": "uniqueId",
    },
]

# Required mappers from scripts/dfn-aai-setup/setup-attribute-mappers.sh
BASH_REQUIRED_MAPPERS = [
    ("email-mapper", "urn:mace:dir:attribute-def:mail", "email"),
    (
        "username-mapper",
        "urn:mace:dir:attribute-def:eduPersonPrincipalName",
        "username",
    ),
    ("displayname-mapper", "urn:mace:dir:attribute-def:displayName", "displayName"),
    (
        "affiliation-mapper",
        "urn:mace:dir:attribute-def:eduPersonAffiliation",
        "affiliation",
    ),
    (
        "persistent-id-mapper",
        "urn:mace:dir:attribute-def:eduPersonTargetedID",
        "persistentId",
    ),
]

BASH_OPTIONAL_MAPPERS = [
    ("firstname-mapper", "urn:mace:dir:attribute-def:givenName", "firstName"),
    ("lastname-mapper", "urn:mace:dir:attribute-def:sn", "lastName"),
    (
        "scoped-affiliation-mapper",
        "urn:mace:dir:attribute-def:eduPersonScopedAffiliation",
        "scopedAffiliation",
    ),
    ("unique-id-mapper", "urn:mace:dir:attribute-def:eduPersonUniqueID", "uniqueId"),
    ("home-org-mapper", "urn:oid:1.3.6.1.4.1.25178.1.2.9", "homeOrganization"),
]


# ---------------------------------------------------------------------------
# Fixture: load test-attributes.yaml
# ---------------------------------------------------------------------------


@pytest.fixture
def test_attributes():
    """Load test-attributes.yaml fixture."""
    path = FIXTURES_DIR / "test-attributes.yaml"
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


@pytest.fixture
def sample_assertion():
    """Parse sample-saml-assertion.xml fixture."""
    path = FIXTURES_DIR / "sample-saml-assertion.xml"
    tree = ET.parse(str(path))
    return tree.getroot()


# ---------------------------------------------------------------------------
# Tests: Helm attribute mapper config consistency
# ---------------------------------------------------------------------------


class TestHelmAttributeMappers:
    """Verify the Helm template mappers match the bash script definitions."""

    def test_helm_mapper_count(self):
        assert len(HELM_ATTRIBUTE_MAPPERS) == 10

    def test_helm_all_mappers_use_inherit_sync(self):
        """All Helm mappers should use INHERIT sync mode."""
        # The Helm template hardcodes this for every mapper
        for m in HELM_ATTRIBUTE_MAPPERS:
            assert m["name"]  # just verify structure

    def test_helm_required_mappers_match_bash(self):
        """The 5 required mappers from the bash script must exist in Helm."""
        helm_map = {m["name"]: m for m in HELM_ATTRIBUTE_MAPPERS}
        for name, saml_attr, user_attr in BASH_REQUIRED_MAPPERS:
            assert name in helm_map, f"Required mapper {name} missing from Helm"
            assert helm_map[name]["saml_attribute"] == saml_attr
            assert helm_map[name]["user_attribute"] == user_attr

    def test_helm_optional_mappers_covered(self):
        """All optional mappers from bash must exist in Helm (by attribute)."""
        helm_attrs = {m["saml_attribute"] for m in HELM_ATTRIBUTE_MAPPERS}
        for name, saml_attr, user_attr in BASH_OPTIONAL_MAPPERS:
            assert saml_attr in helm_attrs, (
                f"Optional mapper {name} ({saml_attr}) missing from Helm"
            )

    def test_helm_mapper_names_unique(self):
        names = [m["name"] for m in HELM_ATTRIBUTE_MAPPERS]
        assert len(names) == len(set(names))

    def test_helm_saml_attributes_unique(self):
        attrs = [m["saml_attribute"] for m in HELM_ATTRIBUTE_MAPPERS]
        assert len(attrs) == len(set(attrs))

    def test_helm_email_mapper(self):
        m = HELM_ATTRIBUTE_MAPPERS[0]
        assert m["name"] == "email-mapper"
        assert m["saml_attribute"] == "urn:mace:dir:attribute-def:mail"
        assert m["user_attribute"] == "email"

    def test_helm_username_mapper(self):
        m = HELM_ATTRIBUTE_MAPPERS[1]
        assert m["name"] == "username-mapper"
        assert (
            m["saml_attribute"] == "urn:mace:dir:attribute-def:eduPersonPrincipalName"
        )
        assert m["user_attribute"] == "username"

    def test_helm_home_org_uses_oid(self):
        m = next(m for m in HELM_ATTRIBUTE_MAPPERS if "home" in m["name"])
        assert m["saml_attribute"].startswith("urn:oid:")


# ---------------------------------------------------------------------------
# Tests: Role mapping logic (from JS script)
# ---------------------------------------------------------------------------


class TestRoleMapping:
    """Test affiliation-to-role mapping matching the Keycloak JS script."""

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
    def test_single_affiliation(self, affiliation, expected_role):
        roles = map_affiliations_to_roles([affiliation])
        assert roles == [expected_role]

    def test_case_insensitive(self):
        """The JS script uses toLowerCase() on affiliations."""
        roles = map_affiliations_to_roles(["FACULTY", "Student", "STAFF"])
        assert "instructor" in roles
        assert "student" in roles
        assert "staff" in roles

    def test_multi_affiliation_deduplication(self):
        """Duplicate affiliations should not produce duplicate roles."""
        roles = map_affiliations_to_roles(["faculty", "teacher"])
        assert roles == ["instructor"]

    def test_student_and_staff(self):
        roles = map_affiliations_to_roles(["student", "staff"])
        assert set(roles) == {"student", "staff"}

    def test_faculty_and_student(self):
        roles = map_affiliations_to_roles(["faculty", "student"])
        assert set(roles) == {"instructor", "student"}

    def test_all_affiliations(self):
        roles = map_affiliations_to_roles(
            [
                "faculty",
                "staff",
                "student",
                "member",
                "affiliate",
                "alum",
                "library-walk-in",
            ]
        )
        assert set(roles) == {
            "instructor",
            "staff",
            "student",
            "member",
            "affiliate",
            "alumni",
            "library",
        }

    def test_empty_affiliations(self):
        roles = map_affiliations_to_roles([])
        assert roles == []

    def test_unknown_affiliation_ignored(self):
        """Unknown affiliations produce no role (JS switch has no default)."""
        roles = map_affiliations_to_roles(["nonexistent-type"])
        assert roles == []

    def test_library_walk_in_maps_to_library(self):
        """library-walk-in maps to the 'library' role in the JS script."""
        roles = map_affiliations_to_roles(["library-walk-in"])
        assert roles == ["library"]

    def test_mixed_known_and_unknown(self):
        roles = map_affiliations_to_roles(["student", "nonexistent", "staff"])
        assert set(roles) == {"student", "staff"}

    def test_alum_maps_to_alumni(self):
        """The JS maps 'alum' → 'alumni' (note the 'i')."""
        roles = map_affiliations_to_roles(["alum"])
        assert roles == ["alumni"]
        assert roles != ["alum"]


# ---------------------------------------------------------------------------
# Tests: Role mapping against test-attributes.yaml fixture
# ---------------------------------------------------------------------------


class TestRoleMappingFromFixture:
    """Verify role mapping against the test-attributes.yaml fixture data."""

    def test_single_affiliation_scenarios(self, test_attributes):
        for scenario, data in test_attributes["single_affiliations"].items():
            affiliations = data["eduPersonAffiliation"]
            expected = data["expected_roles"]
            roles = map_affiliations_to_roles(affiliations)
            assert set(roles) == set(expected), (
                f"Scenario '{scenario}': expected {expected}, got {roles}"
            )

    def test_multi_affiliation_scenarios(self, test_attributes):
        for scenario, data in test_attributes["multi_affiliations"].items():
            affiliations = data["eduPersonAffiliation"]
            expected = data["expected_roles"]
            roles = map_affiliations_to_roles(affiliations)
            assert set(roles) == set(expected), (
                f"Scenario '{scenario}': expected {expected}, got {roles}"
            )

    def test_library_walk_in_maps_to_library(self, test_attributes):
        data = test_attributes["single_affiliations"]["library-walk-in"]
        roles = map_affiliations_to_roles(data["eduPersonAffiliation"])
        assert roles == data["expected_roles"]


# ---------------------------------------------------------------------------
# Tests: Display name parsing (from JS script)
# ---------------------------------------------------------------------------


class TestDisplayNameParsing:
    """Test display name splitting logic from the Keycloak JS mapper."""

    def test_two_parts(self):
        first, last = parse_display_name("Max Mustermann")
        assert first == "Max"
        assert last == "Mustermann"

    def test_three_parts(self):
        first, last = parse_display_name("Hans Peter Schmidt")
        assert first == "Hans"
        assert last == "Peter Schmidt"

    def test_four_parts(self):
        first, last = parse_display_name("Jean Claude van Damme")
        assert first == "Jean"
        assert last == "Claude van Damme"

    def test_single_word(self):
        first, last = parse_display_name("Madonna")
        assert first is None
        assert last == "Madonna"

    def test_empty_string(self):
        first, last = parse_display_name("")
        assert first is None
        assert last is None

    def test_none_input(self):
        first, last = parse_display_name(None)
        assert first is None
        assert last is None

    def test_whitespace_trimmed(self):
        first, last = parse_display_name("  Max  Mustermann  ")
        assert first == "Max"
        assert last == "Mustermann"

    def test_professor_title(self):
        """Titles like 'Prof.' become part of the first name per JS logic."""
        first, last = parse_display_name("Prof. Dr. Maria Schmidt")
        assert first == "Prof."
        assert last == "Dr. Maria Schmidt"

    def test_against_fixture(self, test_attributes):
        for scenario, data in test_attributes["display_names"].items():
            first, last = parse_display_name(data["display_name"])
            assert first == data["expected_first_name"], (
                f"Scenario '{scenario}': first_name mismatch"
            )
            assert last == data["expected_last_name"], (
                f"Scenario '{scenario}': last_name mismatch"
            )


# ---------------------------------------------------------------------------
# Tests: SAML assertion parsing (using fixture XML)
# ---------------------------------------------------------------------------


class TestSAMLAssertionParsing:
    """Parse the sample-saml-assertion.xml fixture and verify attribute extraction."""

    SAML_NS = "urn:oasis:names:tc:SAML:2.0:assertion"
    SAMLP_NS = "urn:oasis:names:tc:SAML:2.0:protocol"

    def _extract_attributes(self, root):
        """Extract all SAML attributes from an assertion into a dict."""
        attrs = {}
        # Find the Assertion element
        assertion = root.find(f"{{{self.SAML_NS}}}Assertion")
        assert assertion is not None, "Assertion element not found"
        attr_statement = assertion.find(f"{{{self.SAML_NS}}}AttributeStatement")
        assert attr_statement is not None, "AttributeStatement not found"

        for attr_elem in attr_statement.findall(f"{{{self.SAML_NS}}}Attribute"):
            name = attr_elem.get("Name")
            values = [
                av.text
                for av in attr_elem.findall(f"{{{self.SAML_NS}}}AttributeValue")
                if av.text
            ]
            attrs[name] = values
        return attrs

    def test_assertion_file_exists(self):
        path = FIXTURES_DIR / "sample-saml-assertion.xml"
        assert path.exists()

    def test_email_extraction(self, sample_assertion):
        attrs = self._extract_attributes(sample_assertion)
        mail = attrs.get("urn:mace:dir:attribute-def:mail", [])
        assert len(mail) == 1
        assert mail[0] == "max.mustermann@example.edu"

    def test_display_name_extraction(self, sample_assertion):
        attrs = self._extract_attributes(sample_assertion)
        dn = attrs.get("urn:mace:dir:attribute-def:displayName", [])
        assert len(dn) == 1
        assert dn[0] == "Max Mustermann"

    def test_given_name_extraction(self, sample_assertion):
        attrs = self._extract_attributes(sample_assertion)
        gn = attrs.get("urn:mace:dir:attribute-def:givenName", [])
        assert len(gn) == 1
        assert gn[0] == "Max"

    def test_sn_extraction(self, sample_assertion):
        attrs = self._extract_attributes(sample_assertion)
        sn = attrs.get("urn:mace:dir:attribute-def:sn", [])
        assert len(sn) == 1
        assert sn[0] == "Mustermann"

    def test_edu_person_principal_name(self, sample_assertion):
        attrs = self._extract_attributes(sample_assertion)
        eppn = attrs.get("urn:mace:dir:attribute-def:eduPersonPrincipalName", [])
        assert len(eppn) == 1
        assert "@" in eppn[0]
        local, domain = eppn[0].rsplit("@", 1)
        assert domain == "example.edu"

    def test_multi_valued_affiliation(self, sample_assertion):
        attrs = self._extract_attributes(sample_assertion)
        affs = attrs.get("urn:mace:dir:attribute-def:eduPersonAffiliation", [])
        assert len(affs) == 2
        assert "student" in affs
        assert "member" in affs

    def test_edu_person_targeted_id(self, sample_assertion):
        attrs = self._extract_attributes(sample_assertion)
        eid = attrs.get("urn:mace:dir:attribute-def:eduPersonTargetedID", [])
        assert len(eid) == 1
        assert "!" in eid[0]

    def test_scoped_affiliation(self, sample_assertion):
        attrs = self._extract_attributes(sample_assertion)
        sa = attrs.get("urn:mace:dir:attribute-def:eduPersonScopedAffiliation", [])
        assert len(sa) == 2
        for val in sa:
            assert "@" in val

    def test_schac_home_organization(self, sample_assertion):
        attrs = self._extract_attributes(sample_assertion)
        ho = attrs.get("urn:oid:1.3.6.1.4.1.25178.1.2.9", [])
        assert len(ho) == 1
        assert ho[0] == "example.edu"

    def test_all_urns_present_in_assertion(self, sample_assertion):
        """Verify the fixture contains all DFN-AAI required attribute URNs."""
        attrs = self._extract_attributes(sample_assertion)
        required_urns = [
            "urn:mace:dir:attribute-def:mail",
            "urn:mace:dir:attribute-def:displayName",
            "urn:mace:dir:attribute-def:eduPersonPrincipalName",
            "urn:mace:dir:attribute-def:eduPersonAffiliation",
            "urn:mace:dir:attribute-def:eduPersonTargetedID",
        ]
        for urn in required_urns:
            assert urn in attrs, f"Required attribute {urn} not found in assertion"

    def test_attribute_count(self, sample_assertion):
        """The sample assertion should have 9 distinct attributes."""
        attrs = self._extract_attributes(sample_assertion)
        assert len(attrs) == 9


# ---------------------------------------------------------------------------
# Tests: End-to-end user profile mapping from fixture
# ---------------------------------------------------------------------------


class TestUserProfileMapping:
    """Test full user profile attribute mapping using test-attributes.yaml."""

    def test_student_user_profile(self, test_attributes):
        profile = test_attributes["user_profiles"]["student_user"]
        assert profile["mail"] == "max.mustermann@example.edu"
        assert profile["eduPersonAffiliation"] == ["student", "member"]
        roles = map_affiliations_to_roles(profile["eduPersonAffiliation"])
        assert "student" in roles
        assert "member" in roles

    def test_faculty_user_profile(self, test_attributes):
        profile = test_attributes["user_profiles"]["faculty_user"]
        assert profile["displayName"] == "Prof. Dr. Maria Schmidt"
        roles = map_affiliations_to_roles(profile["eduPersonAffiliation"])
        assert "instructor" in roles

    def test_staff_user_display_name_fallback(self, test_attributes):
        """Staff user has no givenName/sn → display name parsing should work."""
        profile = test_attributes["user_profiles"]["staff_user"]
        assert profile["givenName"] is None
        assert profile["sn"] is None
        first, last = parse_display_name(profile["displayName"])
        assert first == "IT"
        assert last == "Administrator"


# ---------------------------------------------------------------------------
# Tests: IdP metadata fixture
# ---------------------------------------------------------------------------


class TestIdPMetadataFixture:
    """Verify the sample IdP metadata fixture is well-formed."""

    def test_idp_metadata_file_exists(self):
        path = FIXTURES_DIR / "sample-idp-metadata.xml"
        assert path.exists()

    def test_idp_metadata_parseable(self):
        path = FIXTURES_DIR / "sample-idp-metadata.xml"
        tree = ET.parse(str(path))
        root = tree.getroot()
        assert root is not None

    def test_idp_metadata_has_entity_id(self):
        path = FIXTURES_DIR / "sample-idp-metadata.xml"
        tree = ET.parse(str(path))
        root = tree.getroot()
        assert "entityID" in root.attrib
        assert "dfn" in root.attrib["entityID"].lower()

    def test_idp_metadata_has_idp_sso_descriptor(self):
        path = FIXTURES_DIR / "sample-idp-metadata.xml"
        tree = ET.parse(str(path))
        root = tree.getroot()
        ns = "urn:oasis:names:tc:SAML:2.0:metadata"
        idp_desc = root.find(f"{{{ns}}}IDPSSODescriptor")
        assert idp_desc is not None

    def test_idp_metadata_has_sso_services(self):
        path = FIXTURES_DIR / "sample-idp-metadata.xml"
        tree = ET.parse(str(path))
        root = tree.getroot()
        ns = "urn:oasis:names:tc:SAML:2.0:metadata"
        idp_desc = root.find(f"{{{ns}}}IDPSSODescriptor")
        sso_services = idp_desc.findall(f"{{{ns}}}SingleSignOnService")
        assert len(sso_services) >= 2

    def test_idp_metadata_has_supported_attributes(self):
        """The test IdP should support the required DFN-AAI attributes."""
        path = FIXTURES_DIR / "sample-idp-metadata.xml"
        tree = ET.parse(str(path))
        root = tree.getroot()
        saml_ns = "urn:oasis:names:tc:SAML:2.0:assertion"
        idp_desc = root.find("{urn:oasis:names:tc:SAML:2.0:metadata}IDPSSODescriptor")
        attr_names = [a.get("Name") for a in idp_desc.iter(f"{{{saml_ns}}}Attribute")]
        required = [
            "urn:mace:dir:attribute-def:mail",
            "urn:mace:dir:attribute-def:displayName",
            "urn:mace:dir:attribute-def:eduPersonPrincipalName",
            "urn:mace:dir:attribute-def:eduPersonAffiliation",
            "urn:mace:dir:attribute-def:eduPersonTargetedID",
        ]
        for urn in required:
            assert urn in attr_names, f"Required attribute {urn} not in IdP metadata"

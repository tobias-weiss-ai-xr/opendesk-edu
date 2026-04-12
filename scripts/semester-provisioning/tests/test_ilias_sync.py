# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0


from sync.ilias_sync import ILIASSyncAdapter


class TestILIASSyncAdapter:
    """Test ILIASSyncAdapter role mapping functionality."""

    def test_initialization(self):
        """Test adapter initializes with role mapping."""
        mapping = {"student": "participant", "lecturer": "tutor", "tutor": "admin"}
        adapter = ILIASSyncAdapter(role_mapping=mapping)

        assert adapter.role_mapping == mapping

    def test_map_role_returns_mapped_value(self):
        """Test map_role returns correct mapped role."""
        mapping = {"student": "participant", "lecturer": "tutor"}
        adapter = ILIASSyncAdapter(role_mapping=mapping)

        result = adapter.map_role("student")
        assert result == "participant"

        result = adapter.map_role("lecturer")
        assert result == "tutor"

    def test_map_role_returns_none_for_unmapped(self):
        """Test map_role returns None for unmapped role."""
        mapping = {"student": "participant"}
        adapter = ILIASSyncAdapter(role_mapping=mapping)

        result = adapter.map_role("admin")
        assert result is None

    def test_map_role_returns_none_for_empty_string(self):
        """Test map_role returns None for empty string."""
        mapping = {"student": "participant"}
        adapter = ILIASSyncAdapter(role_mapping=mapping)

        result = adapter.map_role("")
        assert result is None

    def test_sync_group_to_role_accepts_parameters(self):
        """Test sync_group_to_role accepts group and role parameters."""
        adapter = ILIASSyncAdapter(role_mapping={"student": "participant"})

        # Should not raise any exception
        adapter.sync_group_to_role("course-123-students", "participant")

    def test_sync_group_to_role_with_different_roles(self):
        """Test sync_group_to_role works with different role types."""
        mapping = {"student": "participant", "tutor": "tutor", "admin": "admin"}
        adapter = ILIASSyncAdapter(role_mapping=mapping)

        # Test various roles - method exists but doesn't do anything
        # (it's a hook for production integration)
        adapter.sync_group_to_role("course-123-students", "participant")
        adapter.sync_group_to_role("course-123-tutors", "tutor")
        adapter.sync_group_to_role("course-123-admins", "admin")

    def test_sync_group_to_role_with_empty_group_name(self):
        """Test sync_group_to_role handles empty group name."""
        adapter = ILIASSyncAdapter(role_mapping={"student": "participant"})

        adapter.sync_group_to_role("", "participant")

    def test_role_mapping_can_be_overridden(self):
        """Test role mapping can be overridden for different configurations."""
        # Initial mapping
        mapping1 = {"student": "participant"}
        adapter1 = ILIASSyncAdapter(role_mapping=mapping1)
        assert adapter1.map_role("student") == "participant"

        # Override with different mapping
        mapping2 = {"student": "custom_role"}
        adapter2 = ILIASSyncAdapter(role_mapping=mapping2)
        assert adapter2.map_role("student") == "custom_role"

    def test_map_role_with_case_sensitivity(self):
        """Test map_role respects case sensitivity of mapping keys."""
        mapping = {"Student": "1", "student": "2"}
        adapter = ILIASSyncAdapter(role_mapping=mapping)

        # Different cases should map differently
        assert adapter.map_role("Student") == "1"
        assert adapter.map_role("student") == "2"
        assert adapter.map_role("STUDENT") is None

    def test_map_role_with_special_characters(self):
        """Test map_role handles roles with special characters."""
        mapping = {"student-tutor": "custom_role"}
        adapter = ILIASSyncAdapter(role_mapping=mapping)

        result = adapter.map_role("student-tutor")
        assert result == "custom_role"

    def test_map_role_with_numeric_mapping(self):
        """Test map_role handles numeric role IDs in mapping."""
        mapping = {"student": "5", "lecturer": "3"}
        adapter = ILIASSyncAdapter(role_mapping=mapping)

        assert adapter.map_role("student") == "5"
        assert adapter.map_role("lecturer") == "3"

    def test_sync_group_to_role_with_numeric_role(self):
        """Test sync_group_to_role handles numeric role parameters."""
        adapter = ILIASSyncAdapter(role_mapping={"student": "5"})

        adapter.sync_group_to_role("course-123-students", "5")

# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0


from sync.moodle_sync import MoodleSyncAdapter


class TestMoodleSyncAdapter:
    """Test MoodleSyncAdapter role mapping functionality."""

    def test_initialization(self):
        """Test adapter initializes with role mapping."""
        mapping = {
            "student": "student",
            "lecturer": "teacher",
            "tutor": "editingteacher",
        }
        adapter = MoodleSyncAdapter(role_mapping=mapping)

        assert adapter.role_mapping == mapping

    def test_map_role_returns_mapped_value(self):
        """Test map_role returns correct mapped role."""
        mapping = {"student": "student", "lecturer": "teacher"}
        adapter = MoodleSyncAdapter(role_mapping=mapping)

        result = adapter.map_role("student")
        assert result == "student"

        result = adapter.map_role("lecturer")
        assert result == "teacher"

    def test_map_role_returns_none_for_unmapped(self):
        """Test map_role returns None for unmapped role."""
        mapping = {"student": "student"}
        adapter = MoodleSyncAdapter(role_mapping=mapping)

        result = adapter.map_role("admin")
        assert result is None

    def test_map_role_returns_none_for_empty_string(self):
        """Test map_role returns None for empty string."""
        mapping = {"student": "student"}
        adapter = MoodleSyncAdapter(role_mapping=mapping)

        result = adapter.map_role("")
        assert result is None

    def test_sync_group_to_role_accepts_parameters(self):
        """Test sync_group_to_role accepts group and role parameters."""
        adapter = MoodleSyncAdapter(role_mapping={"student": "student"})

        # Should not raise any exception
        adapter.sync_group_to_role("course-123-students", "student")

    def test_sync_group_to_role_with_different_roles(self):
        """Test sync_group_to_role works with different role types."""
        mapping = {"student": "5", "teacher": "3", "editingteacher": "4"}
        adapter = MoodleSyncAdapter(role_mapping=mapping)

        # Test various roles - method exists but doesn't do anything
        # (it's a hook for production integration)
        adapter.sync_group_to_role("course-123-students", "5")
        adapter.sync_group_to_role("course-123-instructors", "3")
        adapter.sync_group_to_role("course-123-tutors", "4")

    def test_sync_group_to_role_with_empty_group_name(self):
        """Test sync_group_to_role handles empty group name."""
        adapter = MoodleSyncAdapter(role_mapping={"student": "student"})

        adapter.sync_group_to_role("", "student")

    def test_role_mapping_can_be_overridden(self):
        """Test role mapping can be overridden for different configurations."""
        # Initial mapping
        mapping1 = {"student": "5"}
        adapter1 = MoodleSyncAdapter(role_mapping=mapping1)
        assert adapter1.map_role("student") == "5"

        # Override with different mapping
        mapping2 = {"student": "custom_role_id"}
        adapter2 = MoodleSyncAdapter(role_mapping=mapping2)
        assert adapter2.map_role("student") == "custom_role_id"

    def test_map_role_with_case_sensitivity(self):
        """Test map_role respects case sensitivity of mapping keys."""
        mapping = {"Student": "5", "student": "6"}
        adapter = MoodleSyncAdapter(role_mapping=mapping)

        # Different cases should map differently
        assert adapter.map_role("Student") == "5"
        assert adapter.map_role("student") == "6"
        assert adapter.map_role("STUDENT") is None

    def test_map_role_with_special_characters(self):
        """Test map_role handles roles with special characters."""
        mapping = {"student-tutor": "7"}
        adapter = MoodleSyncAdapter(role_mapping=mapping)

        result = adapter.map_role("student-tutor")
        assert result == "7"

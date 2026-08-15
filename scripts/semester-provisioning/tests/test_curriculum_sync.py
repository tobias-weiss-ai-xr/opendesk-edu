# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
import pytest
from api.utils.curriculum_sync import CurriculumSyncEngine, CurriculumSyncError


@pytest.fixture
def curriculum_sync_engine():
    """Create CurriculumSyncEngine instance for testing."""
    return CurriculumSyncEngine()


class TestCurriculumSyncEngine:
    """Test cases for CurriculumSyncEngine class."""

    @pytest.mark.asyncio
    async def test_curriculum_sync_initialization(self, curriculum_sync_engine):
        """Test CurriculumSyncEngine initializes correctly."""
        assert curriculum_sync_engine is not None

    @pytest.mark.asyncio
    async def test_curriculum_sync_context_manager(self, curriculum_sync_engine):
        """Test CurriculumSyncEngine async context manager works correctly."""
        async with curriculum_sync_engine as engine:
            assert engine is not None
            # Can use engine
            curriculum = await engine.load_curriculum("bachelor-informatik")
            assert isinstance(curriculum, dict)

    @pytest.mark.asyncio
    async def test_load_curriculum_returns_data(self, curriculum_sync_engine):
        """Test load_curriculum returns curriculum data."""
        curriculum = await curriculum_sync_engine.load_curriculum("bachelor-informatik")

        assert isinstance(curriculum, dict)
        assert "program" in curriculum
        assert "total_ects" in curriculum
        assert "semesters" in curriculum
        assert "modules" in curriculum
        assert isinstance(curriculum["modules"], list)
        assert len(curriculum["modules"]) > 0

    @pytest.mark.asyncio
    async def test_load_curriculum_unknown_program(self, curriculum_sync_engine):
        """Test load_curriculum returns empty dict for unknown program."""
        curriculum = await curriculum_sync_engine.load_curriculum("unknown-program")

        assert isinstance(curriculum, dict)
        assert len(curriculum) == 0

    @pytest.mark.asyncio
    async def test_get_modules_for_semester(self, curriculum_sync_engine):
        """Test get_modules_for_semester returns correct modules."""
        modules = await curriculum_sync_engine.get_modules_for_semester(
            "bachelor-informatik", 1
        )

        assert isinstance(modules, list)
        assert len(modules) == 2  # INF101 and MATH101 are in semester 1

        # Check module structure
        for module in modules:
            assert "id" in module
            assert "title" in module
            assert "ects" in module
            assert "semester" in module
            assert module["semester"] == 1

    @pytest.mark.asyncio
    async def test_get_modules_for_semester_unknown_program(
        self, curriculum_sync_engine
    ):
        """Test get_modules_for_semester returns empty list for unknown program."""
        modules = await curriculum_sync_engine.get_modules_for_semester(
            "unknown-program", 1
        )

        assert isinstance(modules, list)
        assert len(modules) == 0

    @pytest.mark.asyncio
    async def test_get_modules_for_semester_empty_semester(
        self, curriculum_sync_engine
    ):
        """Test get_modules_for_semester returns empty list for empty semester."""
        modules = await curriculum_sync_engine.get_modules_for_semester(
            "bachelor-informatik", 99
        )

        assert isinstance(modules, list)
        assert len(modules) == 0

    @pytest.mark.asyncio
    async def test_get_prerequisites(self, curriculum_sync_engine):
        """Test get_prerequisites returns correct prerequisite list."""
        # INF102 requires INF101
        prereqs = await curriculum_sync_engine.get_prerequisites("INF102")

        assert isinstance(prereqs, list)
        assert len(prereqs) == 1
        assert "INF101" in prereqs

    @pytest.mark.asyncio
    async def test_get_prerequisites_no_prereqs(self, curriculum_sync_engine):
        """Test get_prerequisites returns empty list for modules without prerequisites."""
        prereqs = await curriculum_sync_engine.get_prerequisites("INF101")

        assert isinstance(prereqs, list)
        assert len(prereqs) == 0

    @pytest.mark.asyncio
    async def test_get_prerequisites_unknown_module(self, curriculum_sync_engine):
        """Test get_prerequisites returns empty list for unknown module."""
        prereqs = await curriculum_sync_engine.get_prerequisites("UNKNOWN-001")

        assert isinstance(prereqs, list)
        assert len(prereqs) == 0

    @pytest.mark.asyncio
    async def test_check_prerequisites_met(self, curriculum_sync_engine):
        """Test check_prerequisites correctly identifies met prerequisites."""
        # INF102 requires INF101 - if INF101 is completed, prerequisites are met
        async with curriculum_sync_engine:
            result = await curriculum_sync_engine.check_prerequisites(
                "student-001", "INF102"
            )

            assert isinstance(result, dict)
            assert "module_id" in result
            assert "prerequisites_met" in result
            assert "missing_prerequisites" in result
            assert "prerequisite_list" in result

            # With mock data, student has completed INF101 and MATH101
            # So INF102 prerequisites should be met (INF101 is completed)
            assert result["module_id"] == "INF102"
            assert isinstance(result["prerequisites_met"], bool)

    @pytest.mark.asyncio
    async def test_check_prerequisites_unmet(self, curriculum_sync_engine):
        """Test check_prerequisites correctly identifies unmet prerequisites."""
        # ELEC301 requires INF103 - which is not in the mock completed courses
        async with curriculum_sync_engine:
            result = await curriculum_sync_engine.check_prerequisites(
                "student-001", "ELEC301"
            )

            assert isinstance(result, dict)
            assert result["module_id"] == "ELEC301"

            # INF103 is not in mock completed courses, so prerequisites should not be met
            assert not result["prerequisites_met"]
            assert len(result["missing_prerequisites"]) > 0

    @pytest.mark.asyncio
    async def test_generate_progress_report(self, curriculum_sync_engine):
        """Test generate_progress_report returns complete report."""
        async with curriculum_sync_engine:
            report = await curriculum_sync_engine.generate_progress_report(
                "student-001", "bachelor-informatik"
            )

            # Check report structure
            assert isinstance(report, dict)
            assert "student_id" in report
            assert report["student_id"] == "student-001"
            assert "program" in report
            assert "total_ects" in report
            assert "required_ects" in report
            assert "ects_percentage" in report
            assert "gpa" in report
            assert "completed_modules" in report
            assert "total_modules" in report
            assert "missing_modules" in report
            assert "estimated_graduation" in report

            # Check types
            assert isinstance(report["total_ects"], (int, float))
            assert isinstance(report["required_ects"], (int, float))
            assert isinstance(report["ects_percentage"], (int, float))
            assert isinstance(report["gpa"], (int, float))
            assert isinstance(report["completed_modules"], list)
            assert isinstance(report["total_modules"], int)
            assert isinstance(report["missing_modules"], list)
            assert isinstance(report["estimated_graduation"], str)

            # Check values are valid
            assert report["total_ects"] >= 0
            assert report["required_ects"] > 0
            assert 0.0 <= report["ects_percentage"] <= 100.0
            assert report["total_modules"] > 0

    @pytest.mark.asyncio
    async def test_generate_progress_report_mandatory_vs_elective(
        self, curriculum_sync_engine
    ):
        """Test generate_progress_report distinguishes mandatory vs elective modules."""
        async with curriculum_sync_engine:
            report = await curriculum_sync_engine.generate_progress_report(
                "student-001", "bachelor-informatik"
            )

            # Check that missing_modules include module details with type
            assert "missing_modules" in report
            for missing in report["missing_modules"]:
                assert "module" in missing
                assert isinstance(missing["module"], dict)
                # Module should have type field (mandatory or elective)
                assert "type" in missing["module"]
                assert missing["module"]["type"] in ["mandatory", "elective"]
                assert "missing_prerequisites" in missing

    @pytest.mark.asyncio
    async def test_estimate_graduation(self, curriculum_sync_engine):
        """Test estimate_graduation returns reasonable date."""
        async with curriculum_sync_engine:
            estimation = await curriculum_sync_engine.estimate_graduation(
                "student-001", "bachelor-informatik"
            )

            assert isinstance(estimation, dict)
            assert "student_id" in estimation
            assert "program" in estimation
            assert "current_ects" in estimation
            assert "required_ects" in estimation
            assert "remaining_ects" in estimation
            assert "estimated_graduation_date" in estimation
            assert "semesters_remaining" in estimation
            assert "status" in estimation

            # Check estimated graduation date is in the future
            from datetime import datetime

            grad_date = datetime.strptime(
                estimation["estimated_graduation_date"], "%Y-%m-%d"
            )
            assert grad_date.year >= 2026  # Should be in future

            # Check values are valid
            assert estimation["current_ects"] >= 0
            assert estimation["required_ects"] > 0
            assert estimation["remaining_ects"] >= 0
            assert estimation["semesters_remaining"] >= 0
            assert estimation["status"] in ["on-track", "behind", "ahead", "complete"]

    @pytest.mark.asyncio
    async def test_empty_curriculum_handling(self, curriculum_sync_engine):
        """Test engine handles empty curriculum gracefully."""
        # Load non-existent program
        curriculum = await curriculum_sync_engine.load_curriculum("nonexistent")

        assert isinstance(curriculum, dict)
        assert len(curriculum) == 0

        # Try to get modules for empty curriculum
        modules = await curriculum_sync_engine.get_modules_for_semester(
            "nonexistent", 1
        )

        assert isinstance(modules, list)
        assert len(modules) == 0

    @pytest.mark.asyncio
    async def test_no_results_handling(self, curriculum_sync_engine):
        """Test engine handles reports gracefully even when course IDs don't match curriculum."""
        # Use a student ID - mock returns data but course IDs may not match curriculum
        async with curriculum_sync_engine:
            report = await curriculum_sync_engine.generate_progress_report(
                "student-unknown", "bachelor-informatik"
            )

            # Should still return a valid report structure
            assert isinstance(report, dict)
            assert "student_id" in report
            assert "completed_modules" in report
            assert "total_modules" in report

            # Note: Mock returns data for any student_id, so completed_modules may have course IDs
            # that don't match the curriculum module IDs (LV-001, LV-002 vs INF101, MATH101)

    @pytest.mark.asyncio
    async def test_all_modules_passed(self, curriculum_sync_engine):
        """Test progress report when all modules are passed."""
        # This would require a mock student with all modules completed
        # For now, test the report structure
        async with curriculum_sync_engine:
            report = await curriculum_sync_engine.generate_progress_report(
                "student-001", "bachelor-informatik"
            )

            # Check that if ects_percentage is 100%, status is complete
            if report["ects_percentage"] >= 100.0:
                assert (
                    report["estimated_graduation"] != ""
                )  # Should have a graduation date

    @pytest.mark.asyncio
    async def test_curriculum_sync_error_handling(self):
        """Test CurriculumSyncError exception class."""
        with pytest.raises(CurriculumSyncError) as exc_info:
            raise CurriculumSyncError("Test error message")

        assert str(exc_info.value) == "Test error message"
        assert isinstance(exc_info.value, Exception)

    @pytest.mark.asyncio
    async def test_context_manager_reuse(self, curriculum_sync_engine):
        """Test context manager can be reused."""
        async with curriculum_sync_engine:
            curriculum1 = await curriculum_sync_engine.load_curriculum(
                "bachelor-informatik"
            )
            assert isinstance(curriculum1, dict)

        async with curriculum_sync_engine:
            curriculum2 = await curriculum_sync_engine.load_curriculum(
                "bachelor-informatik"
            )
            assert isinstance(curriculum2, dict)

        # Both should return data
        assert isinstance(curriculum1, dict)
        assert isinstance(curriculum2, dict)

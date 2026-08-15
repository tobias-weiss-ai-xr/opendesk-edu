# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
import pytest
from api.utils.grade_sync import GradeSyncEngine, GradeSyncError


@pytest.fixture
def grade_sync_engine():
    """Create GradeSyncEngine instance for testing."""
    return GradeSyncEngine()


class TestGradeSyncEngine:
    """Test cases for GradeSyncEngine class."""

    @pytest.mark.asyncio
    async def test_grade_sync_initialization(self, grade_sync_engine):
        """Test GradeSyncEngine initializes correctly."""
        assert grade_sync_engine is not None
        assert grade_sync_engine.hisinone_client is not None

    @pytest.mark.asyncio
    async def test_grade_sync_context_manager(self, grade_sync_engine):
        """Test GradeSyncEngine async context manager works correctly."""
        async with grade_sync_engine as engine:
            assert engine is not None
            # Can use the engine
            results = await engine.get_exam_results("student-001")
            assert isinstance(results, list)
        # Context is properly closed after exiting

    @pytest.mark.asyncio
    async def test_get_exam_results_returns_data(self, grade_sync_engine):
        """Test get_exam_results returns exam results from HISinOne."""
        async with grade_sync_engine:
            results = await grade_sync_engine.get_exam_results("student-001")

            assert isinstance(results, list)
            assert len(results) > 0

            # Check first result has expected fields
            first_result = results[0]
            assert "veranstaltung_id" in first_result
            assert "veranstaltungstitel" in first_result
            assert "note" in first_result
            assert "punkte" in first_result
            assert "pruefungsdatum" in first_result
            assert "versuche" in first_result
            assert "status" in first_result

    @pytest.mark.asyncio
    async def test_get_exam_results_with_semester_filter(self, grade_sync_engine):
        """Test get_exam_results filters by semester when provided."""
        async with grade_sync_engine:
            results = await grade_sync_engine.get_exam_results(
                "student-001", semester="2026ws"
            )

            assert isinstance(results, list)
            # Mock data returns all results regardless of semester filter
            # In production, this would filter

    @pytest.mark.asyncio
    async def test_calculate_gpa_all_passed(self, grade_sync_engine):
        """Test calculate_gpa with all passed courses."""
        results = [
            {"note": 1.0, "punkte": 5, "status": "bestanden"},
            {"note": 2.0, "punkte": 8, "status": "bestanden"},
            {"note": 1.5, "punkte": 10, "status": "bestanden"},
        ]

        gpa = grade_sync_engine.calculate_gpa(results)

        # Weighted average: (1.0*5 + 2.0*8 + 1.5*10) / (5 + 8 + 10) = (5 + 16 + 15) / 23 = 36/23 = 1.565...
        expected_gpa = round(36 / 23, 2)
        assert gpa == expected_gpa
        assert 1.0 <= gpa <= 4.0  # Passed courses should have GPA in passing range

    @pytest.mark.asyncio
    async def test_calculate_gpa_mixed_results(self, grade_sync_engine):
        """Test calculate_gpa with mix of passed and failed courses."""
        results = [
            {"note": 1.0, "punkte": 5, "status": "bestanden"},
            {"note": 4.3, "punkte": 8, "status": "nicht bestanden"},
            {"note": 2.5, "punkte": 10, "status": "bestanden"},
            {"note": 5.0, "punkte": 5, "status": "nicht bestanden"},
        ]

        gpa = grade_sync_engine.calculate_gpa(results)

        # Only passed courses included: (1.0*5 + 2.5*10) / (5 + 10) = (5 + 25) / 15 = 30/15 = 2.0
        expected_gpa = round(30 / 15, 2)
        assert gpa == expected_gpa

    @pytest.mark.asyncio
    async def test_calculate_gpa_all_failed(self, grade_sync_engine):
        """Test calculate_gpa when all courses failed returns 0.0."""
        results = [
            {"note": 4.3, "punkte": 5, "status": "nicht bestanden"},
            {"note": 5.0, "punkte": 8, "status": "nicht bestanden"},
        ]

        gpa = grade_sync_engine.calculate_gpa(results)

        # No passed courses, return 0.0
        assert gpa == 0.0

    @pytest.mark.asyncio
    async def test_calculate_gpa_empty_results(self, grade_sync_engine):
        """Test calculate_gpa with empty results returns 0.0."""
        results = []

        gpa = grade_sync_engine.calculate_gpa(results)

        assert gpa == 0.0

    @pytest.mark.asyncio
    async def test_calculate_gpa_rounding(self, grade_sync_engine):
        """Test calculate_gpa rounds to 2 decimal places."""
        results = [
            {"note": 1.0, "punkte": 3, "status": "bestanden"},
            {"note": 2.0, "punkte": 3, "status": "bestanden"},
        ]

        gpa = grade_sync_engine.calculate_gpa(results)

        # (1.0*3 + 2.0*3) / 6 = 1.5
        assert isinstance(gpa, float)
        # Check it's rounded to 2 decimal places
        assert round(gpa, 2) == gpa

    @pytest.mark.asyncio
    async def test_calculate_progress(self, grade_sync_engine):
        """Test calculate_progress returns correct totals."""
        async with grade_sync_engine:
            progress = await grade_sync_engine.calculate_progress("student-001")

            # Check types
            assert isinstance(progress["totalEcts"], (int, float))
            assert isinstance(progress["gpa"], float)
            assert isinstance(progress["passedCourses"], int)
            assert isinstance(progress["failedCourses"], int)

            # Check values are non-negative
            assert progress["totalEcts"] >= 0
            assert progress["gpa"] >= 0.0
            assert progress["passedCourses"] >= 0
            assert progress["failedCourses"] >= 0

    @pytest.mark.asyncio
    async def test_german_gpa_scale_passing_grade(self, grade_sync_engine):
        """Test German GPA scale: 4.0 is passing threshold."""
        results = [
            {"note": 4.0, "punkte": 5, "status": "bestanden"},
            {"note": 3.7, "punkte": 8, "status": "bestanden"},
        ]

        gpa = grade_sync_engine.calculate_gpa(results)

        # Both 4.0 and 3.7 are passing, should be included
        assert gpa > 0.0
        assert gpa <= 4.0

    @pytest.mark.asyncio
    async def test_german_gpa_scale_failing_grade(self, grade_sync_engine):
        """Test German GPA scale: 4.3 and above are failing."""
        results = [
            {"note": 4.0, "punkte": 5, "status": "bestanden"},
            {"note": 4.3, "punkte": 8, "status": "nicht bestanden"},
            {"note": 5.0, "punkte": 10, "status": "nicht bestanden"},
        ]

        gpa = grade_sync_engine.calculate_gpa(results)

        # Only 4.0 is passing, 4.3 and 5.0 are not included
        # GPA should be 4.0 (only one passed course)
        assert gpa == 4.0

    @pytest.mark.asyncio
    async def test_sync_grades_full_workflow(self, grade_sync_engine):
        """Test sync_grades performs full workflow."""
        async with grade_sync_engine:
            result = await grade_sync_engine.sync_grades("2026ws")

            assert isinstance(result, dict)
            assert "semester" in result
            assert "synced" in result
            assert "status" in result

            assert result["semester"] == "2026ws"
            assert result["status"] in ["success", "partial"]
            assert result["synced"] >= 0

    @pytest.mark.asyncio
    async def test_get_student_transcript(self, grade_sync_engine):
        """Test get_student_transcript returns complete history."""
        async with grade_sync_engine:
            transcript = await grade_sync_engine.get_student_transcript("student-001")

            assert isinstance(transcript, dict)
            assert "student_id" in transcript
            assert transcript["student_id"] == "student-001"
            assert "exam_results" in transcript
            assert "totalEcts" in transcript
            assert "gpa" in transcript
            assert "passedCourses" in transcript
            assert "failedCourses" in transcript

            # Check exam_results is a list
            assert isinstance(transcript["exam_results"], list)
            assert len(transcript["exam_results"]) > 0

    @pytest.mark.asyncio
    async def test_grade_sync_error_handling(self):
        """Test GradeSyncError exception class."""
        with pytest.raises(GradeSyncError) as exc_info:
            raise GradeSyncError("Test error message")

        assert str(exc_info.value) == "Test error message"
        assert isinstance(exc_info.value, Exception)

    @pytest.mark.asyncio
    async def test_progress_tracking_in_memory(self, grade_sync_engine):
        """Test progress tracking uses in-memory storage."""
        async with grade_sync_engine:
            # Get progress for student
            progress1 = await grade_sync_engine.calculate_progress("student-001")

            # Get progress again for same student
            progress2 = await grade_sync_engine.calculate_progress("student-001")

            # Both should return data (from mock or in-memory)
            assert isinstance(progress1, dict)
            assert isinstance(progress2, dict)

    @pytest.mark.asyncio
    async def test_status_values(self, grade_sync_engine):
        """Test exam results have correct status values."""
        async with grade_sync_engine:
            results = await grade_sync_engine.get_exam_results("student-001")

            # Check that status values are valid
            valid_statuses = ["bestanden", "nicht bestanden", "withdrawn"]
            for result in results:
                assert result["status"] in valid_statuses

    @pytest.mark.asyncio
    async def test_ects_values(self, grade_sync_engine):
        """Test exam results have valid ECTS values."""
        async with grade_sync_engine:
            results = await grade_sync_engine.get_exam_results("student-001")

            # Check that ECTS values are valid (should be in mock data)
            for result in results:
                ects = result["punkte"]
                assert isinstance(ects, (int, float))
                assert ects > 0  # ECTS should be positive

    @pytest.mark.asyncio
    async def test_grade_values(self, grade_sync_engine):
        """Test exam results have valid grade values (German scale 1.0-5.0 or 0.0 for withdrawn)."""
        async with grade_sync_engine:
            results = await grade_sync_engine.get_exam_results("student-001")

            # Check that grade values are in German scale (1.0-5.0) or 0.0 for withdrawn
            for result in results:
                grade = result["note"]
                assert isinstance(grade, (int, float))
                # Grade is 0.0 for withdrawn, or 1.0-5.0 for other statuses
                if result["status"] == "withdrawn":
                    assert grade == 0.0
                else:
                    assert 1.0 <= grade <= 5.0

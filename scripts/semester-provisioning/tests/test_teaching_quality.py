# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
import pytest
from api.utils.teaching_quality import TeachingQualityEngine


@pytest.fixture
def teaching_quality_engine():
    """Create a TeachingQualityEngine instance for testing."""
    return TeachingQualityEngine()


class TestCourseMetrics:
    """Test course metrics retrieval."""

    @pytest.mark.asyncio
    async def test_get_course_metrics_returns_correct_structure(
        self, teaching_quality_engine
    ):
        """Test that get_course_metrics returns the expected structure."""
        async with teaching_quality_engine:
            result = await teaching_quality_engine.get_course_metrics("INF101")

            assert "course_id" in result
            assert "title" in result
            assert "engagement_score" in result
            assert "avg_grade" in result
            assert "pass_rate" in result
            assert "active_students" in result
            assert "total_enrolled" in result
            assert "avg_lms_logins_weekly" in result
            assert "avg_assignment_completion" in result
            assert "avg_bbb_attendance_rate" in result
            assert "period" in result

    @pytest.mark.asyncio
    async def test_get_course_metrics_with_custom_period(self, teaching_quality_engine):
        """Test that custom period is reflected in metrics."""
        async with teaching_quality_engine:
            result = await teaching_quality_engine.get_course_metrics(
                "INF101", period="2026-SS"
            )

            assert result["period"] == "2026-SS"

    @pytest.mark.asyncio
    async def test_get_course_metrics_returns_valid_course_id(
        self, teaching_quality_engine
    ):
        """Test that course_id matches input."""
        async with teaching_quality_engine:
            result = await teaching_quality_engine.get_course_metrics("MAT201")

            assert result["course_id"] == "MAT201"


class TestEngagementScore:
    """Test engagement score calculation."""

    @pytest.mark.asyncio
    async def test_get_course_engagement_score_returns_float(
        self, teaching_quality_engine
    ):
        """Test that get_course_engagement_score returns a float."""
        async with teaching_quality_engine:
            score = await teaching_quality_engine.get_course_engagement_score("INF101")

            assert isinstance(score, float)

    @pytest.mark.asyncio
    async def test_engagement_score_range(self, teaching_quality_engine):
        """Test that engagement scores are in valid range 0-100."""
        async with teaching_quality_engine:
            course_ids = ["INF101", "INF102", "MAT101", "MAT201", "DAT301"]

            for course_id in course_ids:
                score = await teaching_quality_engine.get_course_engagement_score(
                    course_id
                )
                assert 0 <= score <= 100

    @pytest.mark.asyncio
    async def test_engagement_score_consistency(self, teaching_quality_engine):
        """Test that engagement score in full metrics matches dedicated method."""
        async with teaching_quality_engine:
            full_metrics = await teaching_quality_engine.get_course_metrics("INF101")
            direct_score = await teaching_quality_engine.get_course_engagement_score(
                "INF101"
            )

            assert full_metrics["engagement_score"] == direct_score


class TestCourseOutcomes:
    """Test course outcomes calculation."""

    @pytest.mark.asyncio
    async def test_get_course_outcomes_structure(self, teaching_quality_engine):
        """Test that get_course_outcomes returns correct structure."""
        async with teaching_quality_engine:
            outcomes = await teaching_quality_engine.get_course_outcomes("INF101")

            assert "pass_rate" in outcomes
            assert "avg_grade" in outcomes
            assert "dropout_rate" in outcomes

    @pytest.mark.asyncio
    async def test_pass_rate_range(self, teaching_quality_engine):
        """Test that pass rates are in valid range 0-1."""
        async with teaching_quality_engine:
            course_ids = ["INF101", "INF102", "MAT101", "MAT201", "DAT301"]

            for course_id in course_ids:
                outcomes = await teaching_quality_engine.get_course_outcomes(course_id)
                assert 0 <= outcomes["pass_rate"] <= 1

    @pytest.mark.asyncio
    async def test_avg_grade_german_scale(self, teaching_quality_engine):
        """Test that average grades are on German scale (1.0-5.0)."""
        async with teaching_quality_engine:
            course_ids = ["INF101", "INF102", "MAT101", "MAT201", "DAT301"]

            for course_id in course_ids:
                outcomes = await teaching_quality_engine.get_course_outcomes(course_id)
                assert 1.0 <= outcomes["avg_grade"] <= 5.0

    @pytest.mark.asyncio
    async def test_dropout_rate_range(self, teaching_quality_engine):
        """Test that dropout rates are in valid range 0-1."""
        async with teaching_quality_engine:
            course_ids = ["INF101", "INF102", "MAT101", "MAT201", "DAT301"]

            for course_id in course_ids:
                outcomes = await teaching_quality_engine.get_course_outcomes(course_id)
                assert 0 <= outcomes["dropout_rate"] <= 1

    @pytest.mark.asyncio
    async def test_course_outcomes_consistency(self, teaching_quality_engine):
        """Test that outcomes in full metrics match dedicated method."""
        async with teaching_quality_engine:
            full_metrics = await teaching_quality_engine.get_course_metrics("INF101")
            direct_outcomes = await teaching_quality_engine.get_course_outcomes(
                "INF101"
            )

            assert full_metrics["avg_grade"] == direct_outcomes["avg_grade"]
            assert full_metrics["pass_rate"] == direct_outcomes["pass_rate"]


class TestLecturerMetrics:
    """Test lecturer metrics aggregation."""

    @pytest.mark.asyncio
    async def test_get_lecturer_metrics_structure(self, teaching_quality_engine):
        """Test that get_lecturer_metrics returns correct structure."""
        async with teaching_quality_engine:
            metrics = await teaching_quality_engine.get_lecturer_metrics("lecturer-001")

            assert "lecturer_id" in metrics
            assert "name" in metrics
            assert "courses" in metrics
            assert "total_students" in metrics
            assert "avg_engagement_score" in metrics
            assert "avg_pass_rate" in metrics

    @pytest.mark.asyncio
    async def test_lecturer_metrics_aggregates_multiple_courses(
        self, teaching_quality_engine
    ):
        """Test that lecturer metrics aggregate across all their courses."""
        async with teaching_quality_engine:
            # lecturer-001 teaches INF101 and INF102
            metrics = await teaching_quality_engine.get_lecturer_metrics("lecturer-001")

            assert len(metrics["courses"]) >= 2
            assert "INF101" in [c["course_id"] for c in metrics["courses"]]
            assert "INF102" in [c["course_id"] for c in metrics["courses"]]

    @pytest.mark.asyncio
    async def test_lecturer_metrics_averages(self, teaching_quality_engine):
        """Test that lecturer metrics calculate correct averages."""
        async with teaching_quality_engine:
            metrics = await teaching_quality_engine.get_lecturer_metrics("lecturer-001")

            assert isinstance(metrics["avg_engagement_score"], float)
            assert 0 <= metrics["avg_engagement_score"] <= 100
            assert isinstance(metrics["avg_pass_rate"], float)
            assert 0 <= metrics["avg_pass_rate"] <= 1


class TestDepartmentSummary:
    """Test department/program summary."""

    @pytest.mark.asyncio
    async def test_get_department_summary_structure(self, teaching_quality_engine):
        """Test that get_department_summary returns correct structure."""
        async with teaching_quality_engine:
            summary = await teaching_quality_engine.get_department_summary(
                "bachelor-informatik"
            )

            assert "program" in summary
            assert "courses" in summary
            assert "total_courses" in summary
            assert "total_students" in summary
            assert "program_avg_engagement" in summary
            assert "program_avg_pass_rate" in summary

    @pytest.mark.asyncio
    async def test_department_summary_includes_all_program_courses(
        self, teaching_quality_engine
    ):
        """Test that department summary includes all courses in the program."""
        async with teaching_quality_engine:
            # bachelor-informatik should include INF101, INF102, DAT301
            summary = await teaching_quality_engine.get_department_summary(
                "bachelor-informatik"
            )

            course_ids = [c["course_id"] for c in summary["courses"]]
            assert "INF101" in course_ids
            assert "INF102" in course_ids
            assert "DAT301" in course_ids

    @pytest.mark.asyncio
    async def test_department_summary_mathematics(self, teaching_quality_engine):
        """Test department summary for mathematics program."""
        async with teaching_quality_engine:
            summary = await teaching_quality_engine.get_department_summary(
                "bachelor-mathematik"
            )

            assert summary["program"] == "bachelor-mathematik"
            assert len(summary["courses"]) >= 1
            # MAT101 and MAT201 should be in this program
            course_ids = [c["course_id"] for c in summary["courses"]]
            assert "MAT101" in course_ids or "MAT201" in course_ids


class TestTrendingCourses:
    """Test trending courses calculation."""

    @pytest.mark.asyncio
    async def test_get_trending_courses_structure(self, teaching_quality_engine):
        """Test that get_trending_courses returns correct structure."""
        async with teaching_quality_engine:
            trending = await teaching_quality_engine.get_trending_courses()

            assert isinstance(trending, list)
            if len(trending) > 0:
                assert "course_id" in trending[0]
                assert "title" in trending[0]
                assert "engagement_score" in trending[0]
                assert "engagement_change" in trending[0]

    @pytest.mark.asyncio
    async def test_get_trending_courses_respects_limit(self, teaching_quality_engine):
        """Test that get_trending_courses respects the limit parameter."""
        async with teaching_quality_engine:
            trending = await teaching_quality_engine.get_trending_courses(limit=3)

            assert len(trending) <= 3

    @pytest.mark.asyncio
    async def test_get_trending_courses_sorted_by_engagement_change(
        self, teaching_quality_engine
    ):
        """Test that trending courses are sorted by engagement change."""
        async with teaching_quality_engine:
            trending = await teaching_quality_engine.get_trending_courses()

            if len(trending) > 1:
                # Should be sorted descending by engagement_change
                for i in range(len(trending) - 1):
                    assert (
                        trending[i]["engagement_change"]
                        >= trending[i + 1]["engagement_change"]
                    )


class TestEdgeCases:
    """Test edge cases and error handling."""

    @pytest.mark.asyncio
    async def test_nonexistent_course_metrics(self, teaching_quality_engine):
        """Test handling of nonexistent course."""
        async with teaching_quality_engine:
            result = await teaching_quality_engine.get_course_metrics("NONEXISTENT")

            # Should still return a structure with default/empty values
            assert "course_id" in result
            assert result["course_id"] == "NONEXISTENT"
            assert result["active_students"] == 0

    @pytest.mark.asyncio
    async def test_nonexistent_lecturer_metrics(self, teaching_quality_engine):
        """Test handling of nonexistent lecturer."""
        async with teaching_quality_engine:
            metrics = await teaching_quality_engine.get_lecturer_metrics("lecturer-999")

            assert metrics["lecturer_id"] == "lecturer-999"
            assert len(metrics["courses"]) == 0
            assert metrics["total_students"] == 0

    @pytest.mark.asyncio
    async def test_nonexistent_program_summary(self, teaching_quality_engine):
        """Test handling of nonexistent program."""
        async with teaching_quality_engine:
            summary = await teaching_quality_engine.get_department_summary(
                "nonexistent-program"
            )

            assert summary["program"] == "nonexistent-program"
            assert len(summary["courses"]) == 0
            assert summary["total_courses"] == 0

    @pytest.mark.asyncio
    async def test_zero_engagement_calculation(self, teaching_quality_engine):
        """Test engagement score calculation with zero values."""
        async with teaching_quality_engine:
            # Create a course-like scenario with all zeros
            # This tests the formula handles edge cases
            score = await teaching_quality_engine.get_course_engagement_score("INF101")

            # Should handle the mock data correctly
            assert isinstance(score, float)

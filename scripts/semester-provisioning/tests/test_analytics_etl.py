# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
import pytest
from api.utils.analytics_etl import (
    AnalyticsETL,
    AnalyticsETLError,
    CourseActivityFact,
    StudentDimension,
    CourseDimension,
)


@pytest.fixture
def analytics_etl():
    """Create AnalyticsETL instance for testing."""
    return AnalyticsETL()


class TestAnalyticsETL:
    """Test cases for AnalyticsETL class."""

    @pytest.mark.asyncio
    async def test_analytics_etl_initialization(self, analytics_etl):
        """Test AnalyticsETL initializes correctly."""
        assert analytics_etl is not None
        assert analytics_etl.ilias_client is not None
        assert analytics_etl.moodle_client is not None
        assert analytics_etl.bbb_client is not None

    @pytest.mark.asyncio
    async def test_analytics_etl_context_manager(self, analytics_etl):
        """Test AnalyticsETL async context manager works correctly."""
        async with analytics_etl as etl:
            assert etl is not None
            # Can use the engine
            lms_activity = await etl.aggregate_lms_activity("2026-01-15")
            assert isinstance(lms_activity, list)
        # Context is properly closed after exiting

    @pytest.mark.asyncio
    async def test_is_configured(self, analytics_etl):
        """Test _is_configured always returns True (mock mode available)."""
        assert analytics_etl._is_configured() is True

    @pytest.mark.asyncio
    async def test_aggregate_lms_activity_returns_correct_structure(
        self, analytics_etl
    ):
        """Test aggregate_lms_activity returns per-student per-course data."""
        async with analytics_etl:
            lms_activity = await analytics_etl.aggregate_lms_activity("2026-01-15")

            assert isinstance(lms_activity, list)
            assert len(lms_activity) > 0

            # Check first record has expected fields
            first_record = lms_activity[0]
            assert "date" in first_record
            assert "student_id" in first_record
            assert "course_id" in first_record
            assert "lms_logins" in first_record
            assert "lms_assignments_submitted" in first_record
            assert first_record["date"] == "2026-01-15"

    @pytest.mark.asyncio
    async def test_aggregate_bbb_attendance_returns_correct_structure(
        self, analytics_etl
    ):
        """Test aggregate_bbb_attendance returns per-student per-course minutes."""
        async with analytics_etl:
            bbb_attendance = await analytics_etl.aggregate_bbb_attendance("2026-01-15")

            assert isinstance(bbb_attendance, list)
            assert len(bbb_attendance) > 0

            # Check first record has expected fields
            first_record = bbb_attendance[0]
            assert "date" in first_record
            assert "student_id" in first_record
            assert "course_id" in first_record
            assert "bbb_attendance_minutes" in first_record
            assert first_record["date"] == "2026-01-15"

    @pytest.mark.asyncio
    async def test_aggregate_file_activity_returns_correct_structure(
        self, analytics_etl
    ):
        """Test aggregate_file_activity returns download/upload counts."""
        async with analytics_etl:
            file_activity = await analytics_etl.aggregate_file_activity("2026-01-15")

            assert isinstance(file_activity, list)
            assert len(file_activity) > 0

            # Check first record has expected fields
            first_record = file_activity[0]
            assert "date" in first_record
            assert "student_id" in first_record
            assert "course_id" in first_record
            assert "file_downloads" in first_record
            assert "file_uploads" in first_record
            assert first_record["date"] == "2026-01-15"

    @pytest.mark.asyncio
    async def test_run_daily_aggregation_produces_complete_daily_summary(
        self, analytics_etl
    ):
        """Test run_daily_aggregation produces complete daily summary."""
        async with analytics_etl:
            summary = await analytics_etl.run_daily_aggregation("2026-01-15")

            assert isinstance(summary, dict)
            assert "date" in summary
            assert summary["date"] == "2026-01-15"
            assert "facts_count" in summary
            assert "lms_records" in summary
            assert "bbb_records" in summary
            assert "file_records" in summary
            assert "students" in summary
            assert "courses" in summary

            # Check values are non-negative
            assert summary["facts_count"] >= 0
            assert summary["lms_records"] >= 0
            assert summary["bbb_records"] >= 0
            assert summary["file_records"] >= 0
            assert summary["students"] >= 0
            assert summary["courses"] >= 0

    @pytest.mark.asyncio
    async def test_run_daily_aggregation_defaults_to_today(self, analytics_etl):
        """Test run_daily_aggregation defaults to today when date not provided."""
        async with analytics_etl:
            from datetime import datetime

            expected_date = datetime.now().strftime("%Y-%m-%d")
            summary = await analytics_etl.run_daily_aggregation()

            assert summary["date"] == expected_date

    @pytest.mark.asyncio
    async def test_get_course_engagement_returns_30_day_summary(self, analytics_etl):
        """Test get_course_engagement returns 30-day summary."""
        async with analytics_etl:
            # First run aggregation to populate data
            await analytics_etl.run_daily_aggregation("2026-01-15")

            engagement = await analytics_etl.get_course_engagement("LV-001", 30)

            assert isinstance(engagement, dict)
            assert "course_id" in engagement
            assert engagement["course_id"] == "LV-001"
            assert "days" in engagement
            assert engagement["days"] == 30
            assert "start_date" in engagement
            assert "end_date" in engagement
            assert "total_students" in engagement
            assert "active_students" in engagement
            assert "total_lms_logins" in engagement
            assert "total_assignments" in engagement
            assert "total_bbb_minutes" in engagement
            assert "total_downloads" in engagement
            assert "total_uploads" in engagement
            assert "avg_daily_logins" in engagement
            assert "avg_daily_attendance" in engagement

    @pytest.mark.asyncio
    async def test_get_student_activity_returns_per_student_summary(
        self, analytics_etl
    ):
        """Test get_student_activity returns per-student summary."""
        async with analytics_etl:
            # First run aggregation to populate data
            await analytics_etl.run_daily_aggregation("2026-01-15")

            activity = await analytics_etl.get_student_activity("student-001", 30)

            assert isinstance(activity, dict)
            assert "student_id" in activity
            assert activity["student_id"] == "student-001"
            assert "days" in activity
            assert activity["days"] == 30
            assert "start_date" in activity
            assert "end_date" in activity
            assert "program" in activity
            assert "semester" in activity
            assert "status" in activity
            assert "courses_enrolled" in activity
            assert "total_lms_logins" in activity
            assert "total_assignments" in activity
            assert "total_bbb_minutes" in activity
            assert "total_downloads" in activity
            assert "total_uploads" in activity
            assert "avg_daily_logins" in activity
            assert "active_days" in activity

    @pytest.mark.asyncio
    async def test_data_quality_no_null_values_in_facts(self, analytics_etl):
        """Test data quality: no null values in aggregated facts."""
        async with analytics_etl:
            await analytics_etl.run_daily_aggregation("2026-01-15")

            facts = analytics_etl._activity_facts
            assert len(facts) > 0

            # Check all facts have all required fields
            for fact in facts:
                assert fact.date is not None
                assert fact.student_id is not None
                assert fact.course_id is not None
                assert isinstance(fact.lms_logins, int)
                assert isinstance(fact.lms_assignments_submitted, int)
                assert isinstance(fact.bbb_attendance_minutes, int)
                assert isinstance(fact.file_downloads, int)
                assert isinstance(fact.file_uploads, int)

    @pytest.mark.asyncio
    async def test_data_quality_correct_counts_in_aggregation(self, analytics_etl):
        """Test data quality: correct counts in aggregation summary."""
        async with analytics_etl:
            summary = await analytics_etl.run_daily_aggregation("2026-01-15")

            # Verify summary matches actual data counts
            assert summary["facts_count"] == len(analytics_etl._activity_facts)
            assert summary["students"] == len(analytics_etl._student_dimensions)
            assert summary["courses"] == len(analytics_etl._course_dimensions)

    @pytest.mark.asyncio
    async def test_edge_case_empty_date(self, analytics_etl):
        """Test edge case: handling of date parameter."""
        async with analytics_etl:
            # Empty string should work (treated as default today)
            summary = await analytics_etl.run_daily_aggregation("")
            assert summary is not None
            assert "date" in summary

    @pytest.mark.asyncio
    async def test_edge_case_no_activity_returns_empty_metrics(self, analytics_etl):
        """Test edge case: no activity returns empty metrics."""
        async with analytics_etl:
            # Get engagement for non-existent course
            engagement = await analytics_etl.get_course_engagement("NONEXISTENT", 30)

            assert engagement["course_id"] == "NONEXISTENT"
            assert engagement["total_students"] == 0
            assert engagement["active_students"] == 0
            assert engagement["total_lms_logins"] == 0
            assert engagement["total_assignments"] == 0
            assert engagement["total_bbb_minutes"] == 0
            assert engagement["total_downloads"] == 0
            assert engagement["total_uploads"] == 0

    @pytest.mark.asyncio
    async def test_edge_case_student_activity_no_data_returns_empty(
        self, analytics_etl
    ):
        """Test edge case: student with no activity returns empty metrics."""
        async with analytics_etl:
            # Get activity for non-existent student
            activity = await analytics_etl.get_student_activity("NONEXISTENT", 30)

            assert activity["student_id"] == "NONEXISTENT"
            assert activity["courses_enrolled"] == 0
            assert activity["total_lms_logins"] == 0
            assert activity["total_assignments"] == 0
            assert activity["total_bbb_minutes"] == 0
            assert activity["total_downloads"] == 0
            assert activity["total_uploads"] == 0
            assert activity["active_days"] == 0

    @pytest.mark.asyncio
    async def test_mock_data_realistic_activity_numbers(self, analytics_etl):
        """Test mock data has realistic activity numbers."""
        async with analytics_etl:
            lms_activity = await analytics_etl.aggregate_lms_activity("2026-01-15")
            bbb_attendance = await analytics_etl.aggregate_bbb_attendance("2026-01-15")
            file_activity = await analytics_etl.aggregate_file_activity("2026-01-15")

            # Check LMS activity ranges (logins: 0-30, assignments: 0-5)
            for record in lms_activity:
                assert 0 <= record["lms_logins"] <= 30
                assert 0 <= record["lms_assignments_submitted"] <= 5

            # Check BBB attendance ranges (0-180 minutes)
            for record in bbb_attendance:
                assert 0 <= record["bbb_attendance_minutes"] <= 180

            # Check file activity ranges (downloads/uploads: 0-10)
            for record in file_activity:
                assert 0 <= record["file_downloads"] <= 10
                assert 0 <= record["file_uploads"] <= 5

    @pytest.mark.asyncio
    async def test_mock_data_five_students_varied_engagement(self, analytics_etl):
        """Test mock data has 5 students with varied activity levels."""
        async with analytics_etl:
            students = analytics_etl._get_mock_students()

            assert len(students) == 5

            # Check all students have required fields
            for student in students:
                assert "student_id" in student
                assert "program" in student
                assert "semester" in student
                assert "enrollment_date" in student
                assert "status" in student
                assert "engagement_level" in student

            # Check engagement levels exist
            engagement_levels = set(s["engagement_level"] for s in students)
            assert "high" in engagement_levels
            assert "medium" in engagement_levels
            assert "low" in engagement_levels

    @pytest.mark.asyncio
    async def test_mock_data_three_courses_different_patterns(self, analytics_etl):
        """Test mock data has 3 courses with different participation patterns."""
        async with analytics_etl:
            courses = analytics_etl._get_mock_courses()

            assert len(courses) == 3

            # Check all courses have required fields
            for course in courses:
                assert "course_id" in course
                assert "title" in course
                assert "program" in course
                assert "lecturer_id" in course
                assert "enrollment_count" in course

            # Check enrollment counts are positive
            for course in courses:
                assert course["enrollment_count"] > 0

    @pytest.mark.asyncio
    async def test_course_activity_fact_dataclass(self, analytics_etl):
        """Test CourseActivityFact dataclass works correctly."""
        fact = CourseActivityFact(
            date="2026-01-15",
            student_id="student-001",
            course_id="LV-001",
            lms_logins=5,
            lms_assignments_submitted=2,
            bbb_attendance_minutes=60,
            file_downloads=3,
            file_uploads=1,
        )

        assert fact.date == "2026-01-15"
        assert fact.student_id == "student-001"
        assert fact.course_id == "LV-001"
        assert fact.lms_logins == 5
        assert fact.lms_assignments_submitted == 2
        assert fact.bbb_attendance_minutes == 60
        assert fact.file_downloads == 3
        assert fact.file_uploads == 1

    @pytest.mark.asyncio
    async def test_student_dimension_dataclass(self, analytics_etl):
        """Test StudentDimension dataclass works correctly."""
        dimension = StudentDimension(
            student_id="student-001",
            program="Informatik B.Sc.",
            semester=3,
            enrollment_date="2024-10-01",
            status="active",
        )

        assert dimension.student_id == "student-001"
        assert dimension.program == "Informatik B.Sc."
        assert dimension.semester == 3
        assert dimension.enrollment_date == "2024-10-01"
        assert dimension.status == "active"

    @pytest.mark.asyncio
    async def test_course_dimension_dataclass(self, analytics_etl):
        """Test CourseDimension dataclass works correctly."""
        dimension = CourseDimension(
            course_id="LV-001",
            title="Einführung in die Informatik",
            program="Informatik B.Sc.",
            lecturer_id="prof-001",
            enrollment_count=150,
        )

        assert dimension.course_id == "LV-001"
        assert dimension.title == "Einführung in die Informatik"
        assert dimension.program == "Informatik B.Sc."
        assert dimension.lecturer_id == "prof-001"
        assert dimension.enrollment_count == 150

    @pytest.mark.asyncio
    async def test_analytics_etl_error_exception(self):
        """Test AnalyticsETLError exception class."""
        with pytest.raises(AnalyticsETLError) as exc_info:
            raise AnalyticsETLError("Test error message")

        assert str(exc_info.value) == "Test error message"
        assert isinstance(exc_info.value, Exception)

    @pytest.mark.asyncio
    async def test_in_memory_storage_works(self, analytics_etl):
        """Test in-memory storage stores aggregated data."""
        async with analytics_etl:
            # Run aggregation
            await analytics_etl.run_daily_aggregation("2026-01-15")

            # Check data is stored in memory
            assert len(analytics_etl._activity_facts) > 0
            assert len(analytics_etl._student_dimensions) > 0
            assert len(analytics_etl._course_dimensions) > 0
            assert "2026-01-15" in analytics_etl._daily_cache

    @pytest.mark.asyncio
    async def test_multiple_aggregations_accumulate_facts(self, analytics_etl):
        """Test multiple aggregations accumulate facts in memory."""
        async with analytics_etl:
            # Run aggregations for multiple dates
            await analytics_etl.run_daily_aggregation("2026-01-15")
            initial_count = len(analytics_etl._activity_facts)

            await analytics_etl.run_daily_aggregation("2026-01-16")
            new_count = len(analytics_etl._activity_facts)

            # Facts should accumulate
            assert new_count > initial_count

    @pytest.mark.asyncio
    async def test_get_course_engagement_custom_days(self, analytics_etl):
        """Test get_course_engagement with custom days parameter."""
        async with analytics_etl:
            await analytics_etl.run_daily_aggregation("2026-01-15")

            engagement_7_days = await analytics_etl.get_course_engagement("LV-001", 7)
            engagement_60_days = await analytics_etl.get_course_engagement("LV-001", 60)

            assert engagement_7_days["days"] == 7
            assert engagement_60_days["days"] == 60

    @pytest.mark.asyncio
    async def test_get_student_activity_custom_days(self, analytics_etl):
        """Test get_student_activity with custom days parameter."""
        async with analytics_etl:
            await analytics_etl.run_daily_aggregation("2026-01-15")

            activity_7_days = await analytics_etl.get_student_activity("student-001", 7)
            activity_90_days = await analytics_etl.get_student_activity(
                "student-001", 90
            )

            assert activity_7_days["days"] == 7
            assert activity_90_days["days"] == 90

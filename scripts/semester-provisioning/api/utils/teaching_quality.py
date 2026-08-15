# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
from typing import TYPE_CHECKING, Optional
import logging

if TYPE_CHECKING:
    from api.utils.hisinone_client import HISinOneClient

logger = logging.getLogger(__name__)


class TeachingQualityError(Exception):
    """Exception raised for teaching quality calculation errors."""

    pass


class TeachingQualityEngine:
    """Teaching quality metrics calculation engine.

    Calculates course engagement scores, outcome metrics, and comparative analysis.
    Falls back to mock data when real data sources are not available.
    """

    def __init__(
        self,
        hisinone_client: Optional["HISinOneClient"] = None,
    ):
        """Initialize teaching quality engine.

        Args:
            hisinone_client: Optional HISinOne client instance
        """
        self.hisinone_client = hisinone_client

        # In-memory storage for mock course data
        self._courses: dict[str, dict] = self._init_mock_courses()
        self._lecturers: dict[str, dict] = self._init_mock_lecturers()

    def _init_mock_courses(self) -> dict[str, dict]:
        """Initialize mock course data with realistic distributions."""
        # Engagement formula: (logins_norm * 0.3 + assignments * 0.25 + bbb * 0.25 + active * 0.2) * 100
        return {
            "INF101": {
                "course_id": "INF101",
                "title": "Einführung in die Programmierung",
                "program": "bachelor-informatik",
                "lecturer_id": "lecturer-001",
                "total_enrolled": 50,
                "active_students": 45,
                "avg_grade": 2.8,
                "pass_rate": 0.85,
                "dropout_rate": 0.10,
                "avg_lms_logins_weekly": 15.0,  # Normalized: 15/30 = 0.5
                "avg_assignment_completion": 0.78,
                "avg_bbb_attendance_rate": 0.65,
                "previous_engagement_score": 65.0,
            },
            "INF102": {
                "course_id": "INF102",
                "title": "Datenstrukturen und Algorithmen",
                "program": "bachelor-informatik",
                "lecturer_id": "lecturer-001",
                "total_enrolled": 45,
                "active_students": 40,
                "avg_grade": 3.1,
                "pass_rate": 0.78,
                "dropout_rate": 0.15,
                "avg_lms_logins_weekly": 12.0,  # Normalized: 12/30 = 0.4
                "avg_assignment_completion": 0.72,
                "avg_bbb_attendance_rate": 0.58,
                "previous_engagement_score": 60.0,
            },
            "MAT101": {
                "course_id": "MAT101",
                "title": "Lineare Algebra",
                "program": "bachelor-mathematik",
                "lecturer_id": "lecturer-002",
                "total_enrolled": 60,
                "active_students": 55,
                "avg_grade": 2.5,
                "pass_rate": 0.92,
                "dropout_rate": 0.05,
                "avg_lms_logins_weekly": 18.0,  # Normalized: 18/30 = 0.6
                "avg_assignment_completion": 0.85,
                "avg_bbb_attendance_rate": 0.70,
                "previous_engagement_score": 70.0,
            },
            "MAT201": {
                "course_id": "MAT201",
                "title": "Analysis II",
                "program": "bachelor-mathematik",
                "lecturer_id": "lecturer-002",
                "total_enrolled": 55,
                "active_students": 48,
                "avg_grade": 2.9,
                "pass_rate": 0.82,
                "dropout_rate": 0.12,
                "avg_lms_logins_weekly": 14.0,  # Normalized: 14/30 = 0.466
                "avg_assignment_completion": 0.75,
                "avg_bbb_attendance_rate": 0.62,
                "previous_engagement_score": 62.0,
            },
            "DAT301": {
                "course_id": "DAT301",
                "title": "Datenbanken",
                "program": "bachelor-informatik",
                "lecturer_id": "lecturer-003",
                "total_enrolled": 40,
                "active_students": 35,
                "avg_grade": 2.7,
                "pass_rate": 0.88,
                "dropout_rate": 0.08,
                "avg_lms_logins_weekly": 20.0,  # Normalized: 20/30 = 0.667
                "avg_assignment_completion": 0.82,
                "avg_bbb_attendance_rate": 0.68,
                "previous_engagement_score": 75.0,
            },
        }

    def _init_mock_lecturers(self) -> dict[str, dict]:
        """Initialize mock lecturer data."""
        return {
            "lecturer-001": {
                "lecturer_id": "lecturer-001",
                "name": "Prof. Dr. Schmidt",
                "courses": ["INF101", "INF102"],
            },
            "lecturer-002": {
                "lecturer_id": "lecturer-002",
                "name": "Prof. Dr. Müller",
                "courses": ["MAT101", "MAT201"],
            },
            "lecturer-003": {
                "lecturer_id": "lecturer-003",
                "name": "Dr. Weber",
                "courses": ["DAT301"],
            },
        }

    async def __aenter__(self) -> "TeachingQualityEngine":
        """Initialize engine."""
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb) -> None:
        """Clean up engine resources."""

    def _get_course_data(self, course_id: str) -> dict:
        """Get course data or return empty defaults if not found.

        Args:
            course_id: Course identifier

        Returns:
            Course data dictionary with default values for missing courses
        """
        return self._courses.get(
            course_id,
            {
                "course_id": course_id,
                "title": "Unknown Course",
                "program": "",
                "lecturer_id": "",
                "total_enrolled": 0,
                "active_students": 0,
                "avg_grade": 0.0,
                "pass_rate": 0.0,
                "dropout_rate": 0.0,
                "avg_lms_logins_weekly": 0.0,
                "avg_assignment_completion": 0.0,
                "avg_bbb_attendance_rate": 0.0,
                "previous_engagement_score": 0.0,
            },
        )

    def _calculate_engagement_score(self, course_data: dict) -> float:
        """Calculate engagement score using weighted formula.

        Formula: (logins_norm * 0.3 + assignments * 0.25 + bbb * 0.25 + active * 0.2) * 100

        Args:
            course_data: Course data dictionary

        Returns:
            Engagement score between 0 and 100
        """
        # Normalize logins: assuming max 30 logins per week is 100%
        logins_norm = min(course_data["avg_lms_logins_weekly"] / 30.0, 1.0)
        assignments = course_data["avg_assignment_completion"]
        bbb = course_data["avg_bbb_attendance_rate"]
        active = (
            course_data["active_students"] / course_data["total_enrolled"]
            if course_data["total_enrolled"] > 0
            else 0.0
        )

        score = (
            logins_norm * 0.3 + assignments * 0.25 + bbb * 0.25 + active * 0.2
        ) * 100
        return round(score, 1)

    async def get_course_metrics(
        self, course_id: str, period: str = "semester"
    ) -> dict:
        """Get all metrics for a specific course.

        Args:
            course_id: Course identifier
            period: Time period for metrics (default: "semester")

        Returns:
            Dictionary with course metrics including engagement score,
            outcomes, and activity metrics
        """
        course_data = self._get_course_data(course_id)
        engagement_score = self._calculate_engagement_score(course_data)

        return {
            "course_id": course_data["course_id"],
            "title": course_data["title"],
            "engagement_score": engagement_score,
            "avg_grade": course_data["avg_grade"],
            "pass_rate": course_data["pass_rate"],
            "active_students": course_data["active_students"],
            "total_enrolled": course_data["total_enrolled"],
            "avg_lms_logins_weekly": course_data["avg_lms_logins_weekly"],
            "avg_assignment_completion": course_data["avg_assignment_completion"],
            "avg_bbb_attendance_rate": course_data["avg_bbb_attendance_rate"],
            "period": period,
        }

    async def get_course_engagement_score(self, course_id: str) -> float:
        """Calculate composite engagement score for a course.

        Args:
            course_id: Course identifier

        Returns:
            Engagement score between 0 and 100
        """
        course_data = self._get_course_data(course_id)
        return self._calculate_engagement_score(course_data)

    async def get_course_outcomes(self, course_id: str) -> dict:
        """Get outcome metrics for a course.

        Args:
            course_id: Course identifier

        Returns:
            Dictionary with pass rate, average grade, and dropout rate
        """
        course_data = self._get_course_data(course_id)

        return {
            "pass_rate": course_data["pass_rate"],
            "avg_grade": course_data["avg_grade"],
            "dropout_rate": course_data["dropout_rate"],
        }

    async def get_lecturer_metrics(self, lecturer_id: str) -> dict:
        """Get aggregated metrics for a lecturer across all their courses.

        Args:
            lecturer_id: Lecturer identifier

        Returns:
            Dictionary with aggregated metrics including all courses,
            total students, and average engagement/pass rates
        """
        lecturer_data = self._lecturers.get(
            lecturer_id,
            {
                "lecturer_id": lecturer_id,
                "name": "Unknown Lecturer",
                "courses": [],
            },
        )

        courses = []
        total_students = 0
        engagement_scores = []
        pass_rates = []

        for course_id in lecturer_data["courses"]:
            course_data = self._get_course_data(course_id)
            courses.append(
                {
                    "course_id": course_data["course_id"],
                    "title": course_data["title"],
                    "active_students": course_data["active_students"],
                    "engagement_score": self._calculate_engagement_score(course_data),
                    "pass_rate": course_data["pass_rate"],
                }
            )
            total_students += course_data["active_students"]
            engagement_scores.append(self._calculate_engagement_score(course_data))
            pass_rates.append(course_data["pass_rate"])

        avg_engagement_score = (
            sum(engagement_scores) / len(engagement_scores)
            if engagement_scores
            else 0.0
        )
        avg_pass_rate = sum(pass_rates) / len(pass_rates) if pass_rates else 0.0

        return {
            "lecturer_id": lecturer_data["lecturer_id"],
            "name": lecturer_data["name"],
            "courses": courses,
            "total_students": total_students,
            "avg_engagement_score": round(avg_engagement_score, 1),
            "avg_pass_rate": round(avg_pass_rate, 2),
        }

    async def get_department_summary(self, program: str) -> dict:
        """Get program-level aggregated metrics.

        Args:
            program: Program identifier (e.g., "bachelor-informatik")

        Returns:
            Dictionary with program-level aggregated metrics
        """
        program_courses = [
            self._get_course_data(course_id)
            for course_id, data in self._courses.items()
            if data["program"] == program
        ]

        courses = []
        total_students = 0
        engagement_scores = []
        pass_rates = []

        for course_data in program_courses:
            courses.append(
                {
                    "course_id": course_data["course_id"],
                    "title": course_data["title"],
                    "active_students": course_data["active_students"],
                }
            )
            total_students += course_data["active_students"]
            engagement_scores.append(self._calculate_engagement_score(course_data))
            pass_rates.append(course_data["pass_rate"])

        program_avg_engagement = (
            sum(engagement_scores) / len(engagement_scores)
            if engagement_scores
            else 0.0
        )
        program_avg_pass_rate = sum(pass_rates) / len(pass_rates) if pass_rates else 0.0

        return {
            "program": program,
            "courses": courses,
            "total_courses": len(courses),
            "total_students": total_students,
            "program_avg_engagement": round(program_avg_engagement, 1),
            "program_avg_pass_rate": round(program_avg_pass_rate, 2),
        }

    async def get_trending_courses(self, limit: int = 10) -> list[dict]:
        """Get courses with highest engagement changes.

        Args:
            limit: Maximum number of courses to return

        Returns:
            List of trending courses sorted by engagement change (descending)
        """
        trending = []

        for course_id, course_data in self._courses.items():
            current_score = self._calculate_engagement_score(course_data)
            previous_score = course_data["previous_engagement_score"]
            engagement_change = current_score - previous_score

            trending.append(
                {
                    "course_id": course_data["course_id"],
                    "title": course_data["title"],
                    "engagement_score": current_score,
                    "engagement_change": round(engagement_change, 1),
                }
            )

        # Sort by engagement change descending
        trending.sort(key=lambda x: x["engagement_change"], reverse=True)

        return trending[:limit]

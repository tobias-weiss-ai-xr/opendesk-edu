# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import TYPE_CHECKING, Optional
import logging

if TYPE_CHECKING:
    from api.utils.ilias_client import ILIASClient
    from api.utils.moodle_client import MoodleClient
    from api.utils.bbb_client import BBBClient

logger = logging.getLogger(__name__)


class AnalyticsETLError(Exception):
    """Exception raised for analytics ETL errors."""

    pass


@dataclass
class CourseActivityFact:
    """Fact table for daily course activity metrics."""

    date: str
    student_id: str
    course_id: str
    lms_logins: int = 0
    lms_assignments_submitted: int = 0
    bbb_attendance_minutes: int = 0
    file_downloads: int = 0
    file_uploads: int = 0


@dataclass
class StudentDimension:
    """Dimension table for student attributes."""

    student_id: str
    program: str
    semester: int
    enrollment_date: str
    status: str  # active, graduated, exmatriculated


@dataclass
class CourseDimension:
    """Dimension table for course attributes."""

    course_id: str
    title: str
    program: str
    lecturer_id: str
    enrollment_count: int


class AnalyticsETL:
    """Data warehouse ETL pipeline for aggregating analytics data across services.

    Extracts activity data from LMS (ILIAS/Moodle), BigBlueButton meetings,
    and OpenCloud file storage. Aggregates into daily facts and dimensions.
    Falls back to mock data when services are not configured.
    """

    def __init__(
        self,
        ilias_client: Optional["ILIASClient"] = None,
        moodle_client: Optional["MoodleClient"] = None,
        bbb_client: Optional["BBBClient"] = None,
    ):
        """Initialize analytics ETL engine.

        Args:
            ilias_client: Optional ILIAS client instance
            moodle_client: Optional Moodle client instance
            bbb_client: Optional BigBlueButton client instance
        """
        from api.utils.ilias_client import ILIASClient
        from api.utils.moodle_client import MoodleClient
        from api.utils.bbb_client import BBBClient

        self.ilias_client = ilias_client or ILIASClient()
        self.moodle_client = moodle_client or MoodleClient()
        self.bbb_client = bbb_client or BBBClient()

        # In-memory storage for aggregated data
        self._activity_facts: list[CourseActivityFact] = []
        self._student_dimensions: dict[str, StudentDimension] = {}
        self._course_dimensions: dict[str, CourseDimension] = {}
        self._daily_cache: dict[str, dict] = {}

    async def __aenter__(self) -> "AnalyticsETL":
        """Initialize clients."""
        await self.ilias_client.__aenter__()
        await self.moodle_client.__aenter__()
        await self.bbb_client.__aenter__()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb) -> None:
        """Close clients."""
        await self.ilias_client.__aexit__(exc_type, exc_val, exc_tb)
        await self.moodle_client.__aexit__(exc_type, exc_val, exc_tb)
        await self.bbb_client.__aexit__(exc_type, exc_val, exc_tb)

    def _is_configured(self) -> bool:
        """Check if analytics ETL is configured.

        Always returns True as mock mode is always available.
        """
        return True

    def _get_mock_students(self) -> list[dict]:
        """Get mock student data for testing.

        Returns:
            List of 5 students with varied activity levels
        """
        return [
            {
                "student_id": "student-001",
                "program": "Informatik B.Sc.",
                "semester": 3,
                "enrollment_date": "2024-10-01",
                "status": "active",
                "engagement_level": "high",
            },
            {
                "student_id": "student-002",
                "program": "Informatik B.Sc.",
                "semester": 3,
                "enrollment_date": "2024-10-01",
                "status": "active",
                "engagement_level": "high",
            },
            {
                "student_id": "student-003",
                "program": "Informatik B.Sc.",
                "semester": 5,
                "enrollment_date": "2023-10-01",
                "status": "active",
                "engagement_level": "medium",
            },
            {
                "student_id": "student-004",
                "program": "Mathematik B.Sc.",
                "semester": 1,
                "enrollment_date": "2025-10-01",
                "status": "active",
                "engagement_level": "low",
            },
            {
                "student_id": "student-005",
                "program": "Informatik M.Sc.",
                "semester": 1,
                "enrollment_date": "2025-10-01",
                "status": "active",
                "engagement_level": "medium",
            },
        ]

    def _get_mock_courses(self) -> list[dict]:
        """Get mock course data for testing.

        Returns:
            List of 3 courses with different participation patterns
        """
        return [
            {
                "course_id": "LV-001",
                "title": "Einführung in die Informatik",
                "program": "Informatik B.Sc.",
                "lecturer_id": "prof-001",
                "enrollment_count": 150,
            },
            {
                "course_id": "LV-002",
                "title": "Mathematik I",
                "program": "Mathematik B.Sc.",
                "lecturer_id": "prof-002",
                "enrollment_count": 200,
            },
            {
                "course_id": "LV-003",
                "title": "Software Engineering",
                "program": "Informatik B.Sc.",
                "lecturer_id": "prof-001",
                "enrollment_count": 80,
            },
        ]

    def _get_mock_lms_activity(self, date: str) -> list[dict]:
        """Get mock LMS activity data for a date.

        Args:
            date: Date string (YYYY-MM-DD)

        Returns:
            List of LMS activity records
        """
        # High engagement students
        high_students = ["student-001", "student-002"]
        # Medium engagement students
        medium_students = ["student-003", "student-005"]
        # Low engagement students
        low_students = ["student-004"]

        activities = []
        course_ids = ["LV-001", "LV-002", "LV-003"]

        for student_id in high_students:
            for course_id in course_ids:
                activities.append(
                    {
                        "date": date,
                        "student_id": student_id,
                        "course_id": course_id,
                        "lms_logins": 2
                        + hash(f"{date}-{student_id}-logins") % 5,  # 2-6 logins
                        "lms_assignments_submitted": 1
                        + hash(f"{date}-{student_id}-{course_id}-assign")
                        % 3,  # 1-3 assignments
                    }
                )

        for student_id in medium_students:
            for course_id in course_ids:
                activities.append(
                    {
                        "date": date,
                        "student_id": student_id,
                        "course_id": course_id,
                        "lms_logins": 0
                        + hash(f"{date}-{student_id}-logins") % 3,  # 0-2 logins
                        "lms_assignments_submitted": 0
                        + hash(f"{date}-{student_id}-{course_id}-assign")
                        % 2,  # 0-1 assignments
                    }
                )

        for student_id in low_students:
            for course_id in course_ids:
                activities.append(
                    {
                        "date": date,
                        "student_id": student_id,
                        "course_id": course_id,
                        "lms_logins": 0,  # 0 logins
                        "lms_assignments_submitted": 0,  # 0 assignments
                    }
                )

        return activities

    def _get_mock_bbb_attendance(self, date: str) -> list[dict]:
        """Get mock BigBlueButton attendance data for a date.

        Args:
            date: Date string (YYYY-MM-DD)

        Returns:
            List of BBB attendance records
        """
        high_students = ["student-001", "student-002"]
        medium_students = ["student-003", "student-005"]
        low_students = ["student-004"]

        attendance = []
        course_ids = ["LV-001", "LV-002", "LV-003"]

        for student_id in high_students:
            for course_id in course_ids:
                attendance.append(
                    {
                        "date": date,
                        "student_id": student_id,
                        "course_id": course_id,
                        "bbb_attendance_minutes": 60
                        + hash(f"{date}-{student_id}-{course_id}-bbb")
                        % 60,  # 60-120 minutes
                    }
                )

        for student_id in medium_students:
            for course_id in course_ids:
                attendance.append(
                    {
                        "date": date,
                        "student_id": student_id,
                        "course_id": course_id,
                        "bbb_attendance_minutes": 0
                        + hash(f"{date}-{student_id}-{course_id}-bbb")
                        % 60,  # 0-60 minutes
                    }
                )

        for student_id in low_students:
            for course_id in course_ids:
                attendance.append(
                    {
                        "date": date,
                        "student_id": student_id,
                        "course_id": course_id,
                        "bbb_attendance_minutes": 0,  # 0 minutes
                    }
                )

        return attendance

    def _get_mock_file_activity(self, date: str) -> list[dict]:
        """Get mock file activity data for a date.

        Args:
            date: Date string (YYYY-MM-DD)

        Returns:
            List of file activity records
        """
        high_students = ["student-001", "student-002"]
        medium_students = ["student-003", "student-005"]
        low_students = ["student-004"]

        activities = []
        course_ids = ["LV-001", "LV-002", "LV-003"]

        for student_id in high_students:
            for course_id in course_ids:
                activities.append(
                    {
                        "date": date,
                        "student_id": student_id,
                        "course_id": course_id,
                        "file_downloads": 3
                        + hash(f"{date}-{student_id}-{course_id}-down")
                        % 5,  # 3-8 downloads
                        "file_uploads": 1
                        + hash(f"{date}-{student_id}-{course_id}-up")
                        % 2,  # 1-2 uploads
                    }
                )

        for student_id in medium_students:
            for course_id in course_ids:
                activities.append(
                    {
                        "date": date,
                        "student_id": student_id,
                        "course_id": course_id,
                        "file_downloads": 1
                        + hash(f"{date}-{student_id}-{course_id}-down")
                        % 3,  # 1-3 downloads
                        "file_uploads": 0,  # 0 uploads
                    }
                )

        for student_id in low_students:
            for course_id in course_ids:
                activities.append(
                    {
                        "date": date,
                        "student_id": student_id,
                        "course_id": course_id,
                        "file_downloads": 0,  # 0 downloads
                        "file_uploads": 0,  # 0 uploads
                    }
                )

        return activities

    async def aggregate_lms_activity(self, date: str) -> list[dict]:
        """Aggregate LMS activity (logins, assignments, course access) for a date.

        Args:
            date: Date string (YYYY-MM-DD)

        Returns:
            List of per-student per-course LMS activity records
        """
        logger.info(f"Aggregating LMS activity for date {date}")

        # In production, this would query ILIAS/Moodle APIs
        # For now, use mock data
        lms_activity = self._get_mock_lms_activity(date)

        logger.info(f"Aggregated {len(lms_activity)} LMS activity records for {date}")
        return lms_activity

    async def aggregate_bbb_attendance(self, date: str) -> list[dict]:
        """Aggregate BigBlueButton meeting attendance for a date.

        Args:
            date: Date string (YYYY-MM-DD)

        Returns:
            List of per-student per-course attendance records
        """
        logger.info(f"Aggregating BBB attendance for date {date}")

        # In production, this would query BBB API
        # For now, use mock data
        bbb_attendance = self._get_mock_bbb_attendance(date)

        logger.info(
            f"Aggregated {len(bbb_attendance)} BBB attendance records for {date}"
        )
        return bbb_attendance

    async def aggregate_file_activity(self, date: str) -> list[dict]:
        """Aggregate file downloads/uploads from OpenCloud for a date.

        Args:
            date: Date string (YYYY-MM-DD)

        Returns:
            List of per-student per-course file activity records
        """
        logger.info(f"Aggregating file activity for date {date}")

        # In production, this would query OpenCloud API
        # For now, use mock data
        file_activity = self._get_mock_file_activity(date)

        logger.info(f"Aggregated {len(file_activity)} file activity records for {date}")
        return file_activity

    async def run_daily_aggregation(self, date: Optional[str] = None) -> dict:
        """Run daily aggregation of all service data for a date.

        Args:
            date: Date string (YYYY-MM-DD), defaults to today

        Returns:
            Dictionary with aggregation summary and facts
        """
        if date is None:
            date = datetime.now().strftime("%Y-%m-%d")

        logger.info(f"Starting daily aggregation for {date}")

        # Get activity data from all services
        lms_activity = await self.aggregate_lms_activity(date)
        bbb_attendance = await self.aggregate_bbb_attendance(date)
        file_activity = await self.aggregate_file_activity(date)

        # Build lookup maps
        lms_map = {(a["student_id"], a["course_id"]): a for a in lms_activity}
        bbb_map = {(a["student_id"], a["course_id"]): a for a in bbb_attendance}
        file_map = {(a["student_id"], a["course_id"]): a for a in file_activity}

        # Get all unique student-course combinations
        all_keys = set(lms_map.keys()) | set(bbb_map.keys()) | set(file_map.keys())

        # Merge activities into facts
        facts = []
        for student_id, course_id in all_keys:
            lms = lms_map.get((student_id, course_id), {})
            bbb = bbb_map.get((student_id, course_id), {})
            file = file_map.get((student_id, course_id), {})

            fact = CourseActivityFact(
                date=date,
                student_id=student_id,
                course_id=course_id,
                lms_logins=lms.get("lms_logins", 0),
                lms_assignments_submitted=lms.get("lms_assignments_submitted", 0),
                bbb_attendance_minutes=bbb.get("bbb_attendance_minutes", 0),
                file_downloads=file.get("file_downloads", 0),
                file_uploads=file.get("file_uploads", 0),
            )
            facts.append(fact)

        # Store in memory
        self._activity_facts.extend(facts)

        # Populate dimensions
        students = self._get_mock_students()
        for student in students:
            self._student_dimensions[student["student_id"]] = StudentDimension(
                student_id=student["student_id"],
                program=student["program"],
                semester=student["semester"],
                enrollment_date=student["enrollment_date"],
                status=student["status"],
            )

        courses = self._get_mock_courses()
        for course in courses:
            self._course_dimensions[course["course_id"]] = CourseDimension(
                course_id=course["course_id"],
                title=course["title"],
                program=course["program"],
                lecturer_id=course["lecturer_id"],
                enrollment_count=course["enrollment_count"],
            )

        # Cache daily summary
        summary = {
            "date": date,
            "facts_count": len(facts),
            "lms_records": len(lms_activity),
            "bbb_records": len(bbb_attendance),
            "file_records": len(file_activity),
            "students": len(self._student_dimensions),
            "courses": len(self._course_dimensions),
        }
        self._daily_cache[date] = summary

        logger.info(
            f"Daily aggregation complete for {date}: "
            f"{summary['facts_count']} facts, "
            f"{summary['students']} students, "
            f"{summary['courses']} courses"
        )

        return summary

    async def get_course_engagement(self, course_id: str, days: int = 30) -> dict:
        """Get aggregated engagement metrics for a course over N days.

        Args:
            course_id: Course identifier
            days: Number of days to aggregate (default: 30)

        Returns:
            Dictionary with course engagement metrics
        """
        logger.info(f"Getting course engagement for {course_id} over {days} days")

        # Calculate date range
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)

        # Filter facts for this course
        course_facts = [
            f
            for f in self._activity_facts
            if f.course_id == course_id
            and start_date <= datetime.strptime(f.date, "%Y-%m-%d") <= end_date
        ]

        if not course_facts:
            # Return empty metrics if no data
            return {
                "course_id": course_id,
                "days": days,
                "start_date": start_date.strftime("%Y-%m-%d"),
                "end_date": end_date.strftime("%Y-%m-%d"),
                "total_students": 0,
                "active_students": 0,
                "total_lms_logins": 0,
                "total_assignments": 0,
                "total_bbb_minutes": 0,
                "total_downloads": 0,
                "total_uploads": 0,
                "avg_daily_logins": 0.0,
                "avg_daily_attendance": 0.0,
            }

        # Calculate metrics
        unique_students = set(f.student_id for f in course_facts)
        active_students = set(
            f.student_id
            for f in course_facts
            if f.lms_logins > 0
            or f.lms_assignments_submitted > 0
            or f.bbb_attendance_minutes > 0
        )

        engagement = {
            "course_id": course_id,
            "days": days,
            "start_date": start_date.strftime("%Y-%m-%d"),
            "end_date": end_date.strftime("%Y-%m-%d"),
            "total_students": len(unique_students),
            "active_students": len(active_students),
            "total_lms_logins": sum(f.lms_logins for f in course_facts),
            "total_assignments": sum(f.lms_assignments_submitted for f in course_facts),
            "total_bbb_minutes": sum(f.bbb_attendance_minutes for f in course_facts),
            "total_downloads": sum(f.file_downloads for f in course_facts),
            "total_uploads": sum(f.file_uploads for f in course_facts),
            "avg_daily_logins": round(
                sum(f.lms_logins for f in course_facts) / days, 2
            ),
            "avg_daily_attendance": round(
                sum(f.bbb_attendance_minutes for f in course_facts) / days, 2
            ),
        }

        logger.info(
            f"Course engagement for {course_id}: "
            f"{engagement['active_students']}/{engagement['total_students']} active students"
        )

        return engagement

    async def get_student_activity(self, student_id: str, days: int = 30) -> dict:
        """Get activity summary for a student over N days.

        Args:
            student_id: Student identifier
            days: Number of days to aggregate (default: 30)

        Returns:
            Dictionary with student activity summary
        """
        logger.info(f"Getting student activity for {student_id} over {days} days")

        # Calculate date range
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)

        # Filter facts for this student
        student_facts = [
            f
            for f in self._activity_facts
            if f.student_id == student_id
            and start_date <= datetime.strptime(f.date, "%Y-%m-%d") <= end_date
        ]

        # Get student dimension
        student_dim = self._student_dimensions.get(student_id)

        if not student_facts:
            # Return empty metrics if no data
            return {
                "student_id": student_id,
                "days": days,
                "start_date": start_date.strftime("%Y-%m-%d"),
                "end_date": end_date.strftime("%Y-%m-%d"),
                "program": student_dim.program if student_dim else "unknown",
                "semester": student_dim.semester if student_dim else 0,
                "status": student_dim.status if student_dim else "unknown",
                "courses_enrolled": 0,
                "total_lms_logins": 0,
                "total_assignments": 0,
                "total_bbb_minutes": 0,
                "total_downloads": 0,
                "total_uploads": 0,
                "avg_daily_logins": 0.0,
                "active_days": 0,
            }

        # Calculate metrics
        unique_courses = set(f.course_id for f in student_facts)
        active_days = len(set(f.date for f in student_facts))

        activity = {
            "student_id": student_id,
            "days": days,
            "start_date": start_date.strftime("%Y-%m-%d"),
            "end_date": end_date.strftime("%Y-%m-%d"),
            "program": student_dim.program if student_dim else "unknown",
            "semester": student_dim.semester if student_dim else 0,
            "status": student_dim.status if student_dim else "unknown",
            "courses_enrolled": len(unique_courses),
            "total_lms_logins": sum(f.lms_logins for f in student_facts),
            "total_assignments": sum(
                f.lms_assignments_submitted for f in student_facts
            ),
            "total_bbb_minutes": sum(f.bbb_attendance_minutes for f in student_facts),
            "total_downloads": sum(f.file_downloads for f in student_facts),
            "total_uploads": sum(f.file_uploads for f in student_facts),
            "avg_daily_logins": round(
                sum(f.lms_logins for f in student_facts) / days, 2
            ),
            "active_days": active_days,
        }

        logger.info(
            f"Student activity for {student_id}: "
            f"{activity['total_lms_logins']} logins, "
            f"{activity['active_days']} active days over {days} days"
        )

        return activity

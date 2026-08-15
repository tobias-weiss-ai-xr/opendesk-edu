# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
from typing import TYPE_CHECKING, Any, Optional
from api.config.settings import get_settings
from api.utils.hisinone_client import HISinOneClient
import logging

if TYPE_CHECKING:
    from api.utils.ilias_client import ILIASClient
    from api.utils.moodle_client import MoodleClient

logger = logging.getLogger(__name__)


class GradeSyncError(Exception):
    """Exception raised for grade sync errors."""

    pass


class GradeSyncEngine:
    """Grade and ECTS synchronization engine.

    Extracts exam results from HISinOne, calculates GPA and ECTS progress,
    and tracks student academic performance.
    Falls back to mock data when credentials are not configured.
    """

    def __init__(
        self,
        hisinone_client: Optional[HISinOneClient] = None,
    ):
        """Initialize grade sync engine.

        Args:
            hisinone_client: Optional HISinOne client instance
        """
        self.hisinone_client = hisinone_client or HISinOneClient()
        self._ilias_client: Optional["ILIASClient"] = None
        self._moodle_client: Optional["MoodleClient"] = None

        # In-memory storage for student progress data
        self._progress_cache: dict[str, dict] = {}

    async def __aenter__(self) -> "GradeSyncEngine":
        """Initialize clients."""
        await self.hisinone_client.__aenter__()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb) -> None:
        """Close clients."""
        await self.hisinone_client.__aexit__(exc_type, exc_val, exc_tb)

    def _is_configured(self) -> bool:
        """Check if grade sync is configured."""
        # Grade sync always works via mock mode if HISinOne not configured
        return True

    async def get_exam_results(
        self, student_id: str, semester: Optional[str] = None
    ) -> list[dict]:
        """Get exam results for a student from HISinOne.

        Args:
            student_id: Student identifier
            semester: Optional semester filter (e.g., "2026ws")

        Returns:
            List of exam result dictionaries with:
            - veranstaltung_id: Course ID
            - veranstaltungstitel: Course title
            - note: Grade (German scale 1.0-5.0)
            - punkte: ECTS points
            - pruefungsdatum: Exam date (YYYYMMDD)
            - versuche: Number of attempts
            - status: "bestanden", "nicht bestanden", or "withdrawn"
        """
        params: dict[str, str] = {"person_id": student_id}
        if semester:
            params["semester"] = semester

        results = await self.hisinone_client._soap_call(
            "getPruefungsleistungen", params
        )

        logger.info(f"Retrieved {len(results)} exam results for student {student_id}")
        return results

    def calculate_gpa(self, results: list[dict]) -> float:
        """Calculate weighted GPA from exam results.

        German grading scale: 1.0 (best) to 5.0 (worst/fail)
        Only passed courses (grade <= 4.0) are included in calculation.

        Args:
            results: List of exam result dictionaries

        Returns:
            Weighted GPA rounded to 2 decimal places
            Returns 0.0 if no passed courses
        """
        # Filter passed courses (grade <= 4.0 and status is "bestanden")
        passed_results = [
            r for r in results if r["status"] == "bestanden" and r["note"] <= 4.0
        ]

        if not passed_results:
            return 0.0

        # Calculate weighted average: sum(grade * ects) / sum(ects)
        total_weighted = sum(r["note"] * r["punkte"] for r in passed_results)
        total_ects = sum(r["punkte"] for r in passed_results)

        if total_ects == 0:
            return 0.0

        gpa = round(total_weighted / total_ects, 2)
        logger.debug(f"Calculated GPA: {gpa} from {len(passed_results)} passed courses")
        return gpa

    async def calculate_progress(self, student_id: str) -> dict:
        """Calculate student progress (ECTS, GPA, passed/failed counts).

        Args:
            student_id: Student identifier

        Returns:
            Dictionary with:
            - totalEcts: Total ECTS from all exams
            - gpa: Calculated GPA (0.0 if no passed courses)
            - passedCourses: Number of passed exams
            - failedCourses: Number of failed exams
        """
        # Get all exam results for student
        results = await self.get_exam_results(student_id)

        # Calculate totals
        total_ects = sum(r["punkte"] for r in results if r["status"] != "withdrawn")
        passed_courses = len([r for r in results if r["status"] == "bestanden"])
        failed_courses = len([r for r in results if r["status"] == "nicht bestanden"])

        # Calculate GPA
        gpa = self.calculate_gpa(results)

        progress = {
            "student_id": student_id,
            "totalEcts": total_ects,
            "gpa": gpa,
            "passedCourses": passed_courses,
            "failedCourses": failed_courses,
        }

        # Cache in-memory
        self._progress_cache[student_id] = progress

        logger.info(
            f"Calculated progress for {student_id}: "
            f"{total_ects} ECTS, GPA {gpa}, "
            f"{passed_courses} passed, {failed_courses} failed"
        )

        return progress

    async def sync_grades(self, semester: str) -> dict[str, Any]:
        """Full sync: extract exam results and calculate progress for all students.

        Args:
            semester: Semester identifier (e.g., "2026ws")

        Returns:
            Sync result with:
            - status: "success" or "partial"
            - semester: Semester code
            - synced: Number of students synced
            - errors: Number of errors
            - error_details: List of error details
        """
        logger.info(f"Starting grade sync for semester {semester}")

        # In production, this would:
        # 1. Get list of all students for the semester
        # 2. For each student: get exam results, calculate progress
        # 3. Store results in database or external system

        # For now, sync a mock student
        try:
            await self.calculate_progress("student-001")
            synced_count = 1
            error_count = 0
            errors = []
        except Exception as e:
            synced_count = 0
            error_count = 1
            errors = [{"student_id": "student-001", "error": str(e)}]
            logger.error(f"Failed to sync grades for student-001: {e}")

        logger.info(
            f"Grade sync for {semester} complete: "
            f"{synced_count} synced, {error_count} errors"
        )

        return {
            "status": "success" if error_count == 0 else "partial",
            "semester": semester,
            "synced": synced_count,
            "errors": error_count,
            "error_details": errors,
        }

    async def get_student_transcript(self, student_id: str) -> dict:
        """Get full academic transcript for a student.

        Args:
            student_id: Student identifier

        Returns:
            Dictionary with:
            - student_id: Student identifier
            - exam_results: List of all exam results
            - totalEcts: Total ECTS
            - gpa: Calculated GPA
            - passedCourses: Number of passed courses
            - failedCourses: Number of failed courses
        """
        # Get exam results
        results = await self.get_exam_results(student_id)

        # Calculate progress
        progress = await self.calculate_progress(student_id)

        transcript = {
            "student_id": student_id,
            "exam_results": results,
            "totalEcts": progress["totalEcts"],
            "gpa": progress["gpa"],
            "passedCourses": progress["passedCourses"],
            "failedCourses": progress["failedCourses"],
        }

        logger.info(f"Generated transcript for {student_id}")
        return transcript

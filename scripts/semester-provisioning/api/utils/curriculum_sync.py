# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
from typing import TYPE_CHECKING, Any, Optional
from datetime import datetime, date
import logging

if TYPE_CHECKING:
    from api.utils.grade_sync import GradeSyncEngine

from api.utils.grade_sync import GradeSyncEngine

logger = logging.getLogger(__name__)


class CurriculumSyncError(Exception):
    """Exception raised for curriculum sync errors."""

    pass


# Mock curriculum data (in-memory, simulates YAML file structure)
MOCK_CURRICULA = {
    "bachelor-informatik": {
        "program": "Bachelor Informatik",
        "total_ects": 180,
        "semesters": 6,
        "modules": [
            {
                "id": "INF101",
                "title": "Einführung in die Programmierung",
                "ects": 10,
                "semester": 1,
                "type": "mandatory",
                "prerequisites": [],
            },
            {
                "id": "INF102",
                "title": "Datenbanksysteme",
                "ects": 8,
                "semester": 2,
                "type": "mandatory",
                "prerequisites": ["INF101"],
            },
            {
                "id": "INF103",
                "title": "Software Engineering",
                "ects": 10,
                "semester": 3,
                "type": "mandatory",
                "prerequisites": ["INF101"],
            },
            {
                "id": "MATH101",
                "title": "Mathematik I",
                "ects": 10,
                "semester": 1,
                "type": "mandatory",
                "prerequisites": [],
            },
            {
                "id": "MATH201",
                "title": "Mathematik II",
                "ects": 8,
                "semester": 2,
                "type": "mandatory",
                "prerequisites": ["MATH101"],
            },
            {
                "id": "ELEC301",
                "title": "Wahlpflichtmodul AI",
                "ects": 12,
                "semester": 5,
                "type": "elective",
                "prerequisites": ["INF103"],
            },
        ],
    }
}


class CurriculumSyncEngine:
    """Curriculum mapping and student progress tracking engine.

    Loads curriculum definitions, tracks student progress against requirements,
    checks prerequisites, generates progress reports, and estimates graduation dates.
    Integrates with GradeSyncEngine for GPA and ECTS data.
    """

    def __init__(self, grade_sync_engine: Optional[GradeSyncEngine] = None):
        """Initialize curriculum sync engine.

        Args:
            grade_sync_engine: Optional GradeSyncEngine instance
        """
        self.grade_sync_engine = grade_sync_engine or GradeSyncEngine()

        # In-memory cache for curriculum data
        self._curriculum_cache: dict[str, dict] = {}

    async def __aenter__(self) -> "CurriculumSyncEngine":
        """Initialize clients."""
        await self.grade_sync_engine.__aenter__()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb) -> None:
        """Close clients."""
        await self.grade_sync_engine.__aexit__(exc_type, exc_val, exc_tb)

    async def load_curriculum(self, program: str) -> dict:
        """Load curriculum data for a program.

        Args:
            program: Program identifier (e.g., "bachelor-informatik")

        Returns:
            Curriculum dictionary with program info and module list
        """
        # Check cache first
        if program in self._curriculum_cache:
            return self._curriculum_cache[program]

        # Load from mock data (in production, would load from YAML file)
        curriculum = MOCK_CURRICULA.get(program, {}).copy()

        # Cache the curriculum
        self._curriculum_cache[program] = curriculum

        logger.info(
            f"Loaded curriculum for {program}: {len(curriculum.get('modules', []))} modules"
        )
        return curriculum

    async def get_modules_for_semester(self, program: str, semester: int) -> list[dict]:
        """Get all modules for a specific semester.

        Args:
            program: Program identifier
            semester: Semester number (1-based)

        Returns:
            List of module dictionaries for the semester
        """
        curriculum = await self.load_curriculum(program)

        if not curriculum:
            return []

        # Filter modules by semester
        modules = [
            m for m in curriculum.get("modules", []) if m.get("semester") == semester
        ]

        logger.debug(f"Found {len(modules)} modules for {program} semester {semester}")
        return modules

    async def get_prerequisites(self, module_id: str) -> list[str]:
        """Get prerequisite module IDs for a module.

        Args:
            module_id: Module identifier (e.g., "INF102")

        Returns:
            List of prerequisite module IDs
        """
        # Search for module in all curricula
        for curriculum in MOCK_CURRICULA.values():
            for module in curriculum.get("modules", []):
                if module.get("id") == module_id:
                    prereqs = module.get("prerequisites", [])
                    logger.debug(f"Found {len(prereqs)} prerequisites for {module_id}")
                    return prereqs

        # Module not found
        logger.warning(f"Module {module_id} not found in any curriculum")
        return []

    async def check_prerequisites(self, student_id: str, module_id: str) -> dict:
        """Check if a student has met prerequisites for a module.

        Args:
            student_id: Student identifier
            module_id: Module identifier

        Returns:
            Dictionary with prerequisites check result
        """
        # Get prerequisite list
        prerequisite_list = await self.get_prerequisites(module_id)

        # Get student's completed modules from grade sync
        async with self.grade_sync_engine:
            progress = await self.grade_sync_engine.calculate_progress(student_id)

        # Extract completed module IDs from exam results
        async with self.grade_sync_engine:
            exam_results = await self.grade_sync_engine.get_exam_results(student_id)

        # Map course IDs to module IDs (simplified: course_id matches module_id)
        completed_module_ids = [
            r["veranstaltung_id"] for r in exam_results if r["status"] == "bestanden"
        ]

        # Check which prerequisites are met
        missing_prerequisites = []
        for prereq_id in prerequisite_list:
            if prereq_id not in completed_module_ids:
                missing_prerequisites.append(prereq_id)

        prerequisites_met = len(missing_prerequisites) == 0

        result = {
            "student_id": student_id,
            "module_id": module_id,
            "prerequisite_list": prerequisite_list,
            "completed_prerequisites": [
                p for p in prerequisite_list if p in completed_module_ids
            ],
            "missing_prerequisites": missing_prerequisites,
            "prerequisites_met": prerequisites_met,
        }

        logger.info(
            f"Prerequisites check for {student_id} taking {module_id}: "
            f"{'met' if prerequisites_met else 'not met'}"
        )

        return result

    async def generate_progress_report(self, student_id: str, program: str) -> dict:
        """Generate complete progress report for a student.

        Args:
            student_id: Student identifier
            program: Program identifier

        Returns:
            Progress report dictionary with ECTS, GPA, module completion status
        """
        # Load curriculum
        curriculum = await self.load_curriculum(program)

        # Get student's progress from grade sync
        async with self.grade_sync_engine:
            progress = await self.grade_sync_engine.calculate_progress(student_id)

        # Get completed modules
        async with self.grade_sync_engine:
            exam_results = await self.grade_sync_engine.get_exam_results(student_id)

        # Map completed courses to modules
        completed_module_ids = [
            r["veranstaltung_id"] for r in exam_results if r["status"] == "bestanden"
        ]

        # Calculate ECTS percentage
        total_ects = progress.get("totalEcts", 0)
        required_ects = curriculum.get("total_ects", 180)
        ects_percentage = (
            (total_ects / required_ects * 100) if required_ects > 0 else 0.0
        )

        # Find missing modules (not yet completed)
        all_modules = curriculum.get("modules", [])
        missing_modules = []
        for module in all_modules:
            if module["id"] not in completed_module_ids:
                # Check prerequisites
                prereq_check = await self.check_prerequisites(student_id, module["id"])
                missing_modules.append(
                    {
                        "module": module,
                        "missing_prerequisites": prereq_check["missing_prerequisites"],
                    }
                )

        # Estimate graduation date (simple estimate: current date + remaining semesters)
        estimated_graduation = await self._estimate_graduation_date(student_id, program)

        report = {
            "student_id": student_id,
            "program": curriculum.get("program", ""),
            "total_ects": total_ects,
            "required_ects": required_ects,
            "ects_percentage": round(ects_percentage, 2),
            "gpa": progress.get("gpa", 0.0),
            "completed_modules": completed_module_ids,
            "total_modules": len(all_modules),
            "missing_modules": missing_modules,
            "estimated_graduation": estimated_graduation,
        }

        logger.info(
            f"Generated progress report for {student_id}: "
            f"{ects_percentage:.2f}% complete, {total_ects}/{required_ects} ECTS"
        )

        return report

    async def estimate_graduation(self, student_id: str, program: str) -> dict:
        """Estimate graduation date for a student.

        Args:
            student_id: Student identifier
            program: Program identifier

        Returns:
            Graduation estimation dictionary
        """
        # Get progress report
        report = await self.generate_progress_report(student_id, program)

        current_ects = report["total_ects"]
        required_ects = report["required_ects"]
        remaining_ects = required_ects - current_ects

        # Estimate semesters remaining (assume 30 ECTS per semester)
        ects_per_semester = 30
        semesters_remaining = (
            remaining_ects + ects_per_semester - 1
        ) // ects_per_semester  # Round up

        # Calculate estimated graduation date
        # Assume current date + semesters_remaining * 6 months
        today = date.today()
        estimated_date = self._add_semesters(today, semesters_remaining)
        estimated_graduation_date = estimated_date.strftime("%Y-%m-%d")

        # Determine status
        status = "on-track"
        if remaining_ects == 0:
            status = "complete"
        elif semesters_remaining > 6:  # More than 3 years remaining
            status = "behind"
        elif semesters_remaining < 4:  # Less than 2 years remaining
            status = "ahead"

        estimation = {
            "student_id": student_id,
            "program": report["program"],
            "current_ects": current_ects,
            "required_ects": required_ects,
            "remaining_ects": remaining_ects,
            "semesters_remaining": semesters_remaining,
            "estimated_graduation_date": estimated_graduation_date,
            "status": status,
        }

        logger.info(
            f"Graduation estimation for {student_id}: "
            f"{estimated_graduation_date} ({semesters_remaining} semesters remaining)"
        )

        return estimation

    async def _estimate_graduation_date(self, student_id: str, program: str) -> str:
        """Helper method to estimate graduation date.

        Args:
            student_id: Student identifier
            program: Program identifier

        Returns:
            Graduation date string in YYYY-MM-DD format
        """
        # Get curriculum
        curriculum = await self.load_curriculum(program)

        # Get student's progress from grade sync
        async with self.grade_sync_engine:
            progress = await self.grade_sync_engine.calculate_progress(student_id)

        current_ects = progress.get("totalEcts", 0)
        required_ects = curriculum.get("total_ects", 180)
        remaining_ects = required_ects - current_ects

        # Estimate semesters remaining (assume 30 ECTS per semester)
        ects_per_semester = 30
        semesters_remaining = (
            remaining_ects + ects_per_semester - 1
        ) // ects_per_semester  # Round up

        # Calculate estimated graduation date
        today = date.today()
        estimated_date = self._add_semesters(today, semesters_remaining)

        return estimated_date.strftime("%Y-%m-%d")

    def _add_semesters(self, start_date: date, semesters: int) -> date:
        """Add semesters to a date.

        Args:
            start_date: Starting date
            semesters: Number of semesters to add

        Returns:
            New date with semesters added
        """
        # Each semester is approximately 6 months
        years = semesters // 2
        remaining_months = (semesters % 2) * 6

        # Calculate new date
        new_year = start_date.year + years
        new_month = start_date.month + remaining_months

        # Handle month overflow
        if new_month > 12:
            new_year += 1
            new_month -= 12

        # Clamp day to last day of month
        import calendar

        last_day = calendar.monthrange(new_year, new_month)[1]
        new_day = min(start_date.day, last_day)

        return date(new_year, new_month, new_day)

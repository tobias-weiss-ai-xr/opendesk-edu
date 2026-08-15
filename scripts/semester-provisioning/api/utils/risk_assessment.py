# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
from typing import TYPE_CHECKING, Any, Optional
import logging

if TYPE_CHECKING:
    from api.utils.grade_sync import GradeSyncEngine
    from api.utils.curriculum_sync import CurriculumSyncEngine

from api.utils.grade_sync import GradeSyncEngine
from api.utils.curriculum_sync import CurriculumSyncEngine

logger = logging.getLogger(__name__)


class RiskAssessmentError(Exception):
    """Exception raised for risk assessment errors."""

    pass


class RiskCriteria:
    """Configurable risk assessment criteria.

    Thresholds can be adjusted for different programs or institutions.
    German grading: 1.0=best, 4.0=pass threshold, 5.0=fail (higher=worse).
    """

    MAX_FAILED_COURSES: int = 3  # Failed more than N courses
    MIN_GPA: float = 4.0  # GPA above threshold (German scale, higher=bad)
    MIN_ECTS_PERCENTAGE: float = 0.5  # Less than 50% of expected ECTS
    FAILED_MANDATORY_MODULE: bool = True  # Any failed mandatory module = risk


class RiskAssessmentEngine:
    """At-risk student identification engine.

    Assesses academic risk based on configurable criteria,
    calculates risk levels, generates actionable recommendations,
    and logs advisor notifications for at-risk students.
    Integrates with GradeSyncEngine and CurriculumSyncEngine.
    """

    def __init__(
        self,
        grade_sync_engine: Optional[GradeSyncEngine] = None,
        curriculum_sync_engine: Optional[CurriculumSyncEngine] = None,
        criteria: Optional[RiskCriteria] = None,
    ):
        """Initialize risk assessment engine.

        Args:
            grade_sync_engine: Optional GradeSyncEngine instance
            curriculum_sync_engine: Optional CurriculumSyncEngine instance
            criteria: Optional RiskCriteria instance (uses defaults if not provided)
        """
        self.grade_sync_engine = grade_sync_engine or GradeSyncEngine()
        self.curriculum_sync_engine = curriculum_sync_engine or CurriculumSyncEngine(
            self.grade_sync_engine
        )
        self.criteria = criteria or RiskCriteria()

        # In-memory storage for assessments
        self._assessment_cache: dict[str, dict] = {}

        # Mock advisor notifications log
        self._advisor_notifications: list[dict] = []

    async def __aenter__(self) -> "RiskAssessmentEngine":
        """Initialize clients."""
        await self.grade_sync_engine.__aenter__()
        await self.curriculum_sync_engine.__aenter__()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb) -> None:
        """Close clients."""
        await self.curriculum_sync_engine.__aexit__(exc_type, exc_val, exc_tb)
        await self.grade_sync_engine.__aexit__(exc_type, exc_val, exc_tb)

    def _is_configured(self) -> bool:
        """Check if risk assessment is configured."""
        # Risk assessment always works via mock mode if engines not configured
        return True

    async def assess_student_risk(
        self, student_id: str, program: str
    ) -> dict[str, Any]:
        """Perform full risk assessment for a student.

        Args:
            student_id: Student identifier
            program: Program identifier (e.g., "bachelor-informatik")

        Returns:
            Risk assessment dictionary with:
            - student_id: Student identifier
            - risk_level: "low", "medium", or "high"
            - risks: List of identified risk factors
            - recommendations: List of actionable recommendations
        """
        # Get student progress from grade sync
        async with self.grade_sync_engine:
            progress = await self.grade_sync_engine.calculate_progress(student_id)

        # Get progress report from curriculum sync
        async with self.curriculum_sync_engine:
            report = await self.curriculum_sync_engine.generate_progress_report(
                student_id, program
            )

        # Get exam results for detailed analysis
        async with self.grade_sync_engine:
            exam_results = await self.grade_sync_engine.get_exam_results(student_id)

        # Identify risk factors
        risks = []

        # Check failure rate
        failed_courses = progress.get("failedCourses", 0)
        if failed_courses > self.criteria.MAX_FAILED_COURSES:
            risks.append(
                {
                    "type": "high_failure_rate",
                    "severity": "high",
                    "message": f"Student has failed {failed_courses} courses (threshold: {self.criteria.MAX_FAILED_COURSES})",
                }
            )

        # Check GPA (German scale: higher=worse)
        gpa = progress.get("gpa", 0.0)
        if gpa > self.criteria.MIN_GPA:
            risks.append(
                {
                    "type": "low_gpa",
                    "severity": "medium",
                    "message": f"GPA {gpa:.2f} below threshold {self.criteria.MIN_GPA}",
                }
            )

        # Check ECTS progress
        ects_percentage = report.get("ects_percentage", 0) / 100.0
        if ects_percentage < self.criteria.MIN_ECTS_PERCENTAGE:
            risks.append(
                {
                    "type": "behind_schedule",
                    "severity": "medium",
                    "message": f"Student has completed {report.get('ects_percentage', 0):.1f}% of expected ECTS (threshold: {self.criteria.MIN_ECTS_PERCENTAGE * 100:.0f}%)",
                }
            )

        # Check for failed mandatory modules
        if self.criteria.FAILED_MANDATORY_MODULE:
            curriculum = await self.curriculum_sync_engine.load_curriculum(program)
            mandatory_modules = [
                m["id"]
                for m in curriculum.get("modules", [])
                if m.get("type") == "mandatory"
            ]
            completed_module_ids = [
                r["veranstaltung_id"]
                for r in exam_results
                if r["status"] == "bestanden"
            ]
            failed_mandatory = [
                m
                for m in mandatory_modules
                if m
                in [
                    r["veranstaltung_id"]
                    for r in exam_results
                    if r["status"] == "nicht bestanden"
                ]
            ]

            if failed_mandatory:
                risks.append(
                    {
                        "type": "failed_mandatory_module",
                        "severity": "high",
                        "message": f"Student has failed mandatory modules: {', '.join(failed_mandatory)}",
                    }
                )

        # Calculate risk level
        risk_level = self.calculate_risk_level(risks)

        # Generate recommendations
        recommendations = self.generate_recommendations(risks)

        # Build assessment
        assessment = {
            "student_id": student_id,
            "program": report.get("program", ""),
            "risk_level": risk_level,
            "risks": risks,
            "recommendations": recommendations,
            "gpa": gpa,
            "failed_courses": failed_courses,
            "ects_percentage": report.get("ects_percentage", 0),
        }

        # Cache assessment
        self._assessment_cache[student_id] = assessment

        logger.info(
            f"Risk assessment for {student_id}: {risk_level} risk, "
            f"{len(risks)} risk factors identified"
        )

        return assessment

    async def identify_at_risk_students(self, program: str) -> list[dict[str, Any]]:
        """Scan all students in a program and identify those at risk.

        Args:
            program: Program identifier (e.g., "bachelor-informatik")

        Returns:
            List of risk assessments for all at-risk students
        """
        logger.info(f"Scanning for at-risk students in {program}")

        # In production, this would query the student list from a database
        # For now, scan mock students
        mock_students = [
            "student-001",
            "student-002",
            "student-003",
            "student-004",
            "student-005",
        ]

        at_risk_students = []

        for student_id in mock_students:
            assessment = await self.assess_student_risk(student_id, program)
            if assessment["risk_level"] in ["medium", "high"]:
                at_risk_students.append(assessment)
                # Log advisor notification
                await self.notify_advisor(student_id, assessment)

        logger.info(
            f"Found {len(at_risk_students)} at-risk students in {program} "
            f"({len(mock_students)} total scanned)"
        )

        return at_risk_students

    def calculate_risk_level(self, risks: list[dict]) -> str:
        """Calculate overall risk level from identified risk factors.

        Args:
            risks: List of risk factor dictionaries

        Returns:
            Risk level: "low", "medium", or "high"
        """
        if not risks:
            return "low"

        # Check for high severity risks
        high_risks = [r for r in risks if r.get("severity") == "high"]
        if high_risks:
            return "high"

        # Check for medium severity risks
        medium_risks = [r for r in risks if r.get("severity") == "medium"]
        if medium_risks:
            return "medium"

        return "low"

    def generate_recommendations(self, risks: list[dict]) -> list[dict]:
        """Generate actionable recommendations based on risk factors.

        Args:
            risks: List of risk factor dictionaries

        Returns:
            List of recommendation dictionaries
        """
        recommendations = []
        risk_types = {r["type"] for r in risks}

        if "high_failure_rate" in risk_types:
            recommendations.append(
                {
                    "type": "academic_advising",
                    "message": "Schedule meeting with academic advisor to discuss course selection and study strategies",
                    "priority": "high",
                }
            )
            recommendations.append(
                {
                    "type": "study_skills_workshop",
                    "message": "Attend study skills workshop to improve learning techniques",
                    "priority": "medium",
                }
            )

        if "low_gpa" in risk_types:
            recommendations.append(
                {
                    "type": "tutoring",
                    "message": "Enroll in peer tutoring program for additional support",
                    "priority": "high",
                }
            )
            recommendations.append(
                {
                    "type": "reduced_course_load",
                    "message": "Consider reducing course load for next semester",
                    "priority": "medium",
                }
            )

        if "behind_schedule" in risk_types:
            recommendations.append(
                {
                    "type": "summer_courses",
                    "message": "Enroll in summer semester courses to catch up on ECTS",
                    "priority": "medium",
                }
            )
            recommendations.append(
                {
                    "type": "reduced_course_load",
                    "message": "Reduce course load to focus on passing remaining courses",
                    "priority": "low",
                }
            )

        if "failed_mandatory_module" in risk_types:
            recommendations.append(
                {
                    "type": "retake_planning",
                    "message": "Create retake plan for failed mandatory modules",
                    "priority": "high",
                }
            )
            recommendations.append(
                {
                    "type": "prerequisite_check",
                    "message": "Review prerequisites for courses requiring failed modules",
                    "priority": "medium",
                }
            )

        return recommendations

    async def notify_advisor(self, student_id: str, assessment: dict) -> dict:
        """Log advisor notification for at-risk student.

        Args:
            student_id: Student identifier
            assessment: Risk assessment dictionary

        Returns:
            Notification log entry
        """
        notification = {
            "student_id": student_id,
            "risk_level": assessment["risk_level"],
            "risks_count": len(assessment["risks"]),
            "notification_type": "advisor_alert",
            "status": "logged",
            "timestamp": self._get_current_timestamp(),
        }

        self._advisor_notifications.append(notification)

        logger.info(
            f"Advisor notification logged for {student_id}: "
            f"{assessment['risk_level']} risk ({notification['risks_count']} factors)"
        )

        return notification

    def _get_current_timestamp(self) -> str:
        """Get current timestamp in ISO format.

        Returns:
            ISO 8601 formatted timestamp
        """
        from datetime import datetime, timezone

        return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

    def get_advisor_notifications(self) -> list[dict]:
        """Get all logged advisor notifications.

        Returns:
            List of notification dictionaries
        """
        return self._advisor_notifications.copy()

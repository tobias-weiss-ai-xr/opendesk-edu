# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
from typing import TYPE_CHECKING, Any, Optional
import logging

if TYPE_CHECKING:
    from api.utils.grade_sync import GradeSyncEngine

from api.utils.grade_sync import GradeSyncEngine

logger = logging.getLogger(__name__)


class PredictiveAnalyticsError(Exception):
    """Exception raised for predictive analytics errors."""

    pass


class RiskFactorWeights:
    """Configurable risk factor weights for dropout prediction.

    Weights sum to 1.0. Thresholds define when a factor becomes risky.
    German grading: 1.0=best, 4.0=pass, 5.0=fail (higher=worse).
    """

    FAILED_COURSES_RATIO = {"weight": 0.30, "threshold": 0.3}
    GPA_TREND = {"weight": 0.25, "threshold": -0.5}  # declining GPA
    ECTS_DEFICIT = {"weight": 0.20, "threshold": 0.3}  # behind by 30%+
    ATTENDANCE_DECLINE = {"weight": 0.15, "threshold": -0.2}
    FAILED_MANDATORY = {"weight": 0.10, "threshold": True}


class PredictiveAnalyticsEngine:
    """Dropout prediction and analytics engine using rule-based heuristics.

    Predicts student dropout risk, course success probability, and enrollment trends.
    Uses weighted risk factors calculated from academic performance data.
    No ML dependencies - all predictions are rule-based.
    """

    def __init__(self, grade_sync_engine: Optional["GradeSyncEngine"] = None):
        """Initialize predictive analytics engine.

        Args:
            grade_sync_engine: Optional GradeSyncEngine instance for academic data
        """
        self.grade_sync_engine = grade_sync_engine or GradeSyncEngine()

        # Mock student data with varying risk profiles
        self._mock_student_data = self._generate_mock_data()

        # Mock enrollment trend data
        self._mock_enrollment_data = self._generate_enrollment_trends()

    async def __aenter__(self) -> "PredictiveAnalyticsEngine":
        """Initialize clients."""
        await self.grade_sync_engine.__aenter__()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb) -> None:
        """Close clients."""
        await self.grade_sync_engine.__aexit__(exc_type, exc_val, exc_tb)

    def _generate_mock_data(self) -> dict:
        """Generate mock student data with varying risk profiles.

        Returns:
            Dictionary mapping student IDs to their academic data
        """
        return {
            "student-001": {
                "failed_courses_ratio": 0.4,
                "gpa_trend": -0.6,
                "ects_deficit": 0.35,
                "attendance_decline": -0.25,
                "failed_mandatory": True,
                "gpa_history": [2.5, 2.7, 3.0, 3.1],  # declining
                "attendance_history": [0.85, 0.80, 0.75, 0.60],  # declining
                "enrolled_courses": ["INF102", "MATH201", "STAT101"],
            },
            "student-002": {
                "failed_courses_ratio": 0.15,
                "gpa_trend": 0.1,
                "ects_deficit": 0.1,
                "attendance_decline": -0.05,
                "failed_mandatory": False,
                "gpa_history": [2.0, 1.9, 1.8, 1.7],  # improving
                "attendance_history": [0.95, 0.96, 0.97, 0.98],  # improving
                "enrolled_courses": ["INF102", "MATH201"],
            },
            "student-003": {
                "failed_courses_ratio": 0.5,
                "gpa_trend": -0.8,
                "ects_deficit": 0.45,
                "attendance_decline": -0.35,
                "failed_mandatory": True,
                "gpa_history": [2.0, 2.5, 3.0, 3.8],  # declining fast
                "attendance_history": [0.80, 0.70, 0.55, 0.40],  # declining fast
                "enrolled_courses": ["INF102", "MATH201", "STAT101", "PHYS201"],
            },
            "student-004": {
                "failed_courses_ratio": 0.25,
                "gpa_trend": -0.1,
                "ects_deficit": 0.2,
                "attendance_decline": -0.15,
                "failed_mandatory": False,
                "gpa_history": [2.2, 2.3, 2.4, 2.5],  # stable/slight decline
                "attendance_history": [0.90, 0.88, 0.85, 0.83],  # slight decline
                "enrolled_courses": ["INF102", "STAT101"],
            },
            "student-005": {
                "failed_courses_ratio": 0.0,
                "gpa_trend": 0.2,
                "ects_deficit": 0.0,
                "attendance_decline": 0.1,
                "failed_mandatory": False,
                "gpa_history": [1.5, 1.4, 1.3, 1.2],  # excellent, improving
                "attendance_history": [0.98, 0.99, 1.0, 1.0],  # perfect
                "enrolled_courses": ["INF102", "MATH201", "STAT101"],
            },
            "student-006": {
                "failed_courses_ratio": 0.35,
                "gpa_trend": -0.3,
                "ects_deficit": 0.25,
                "attendance_decline": -0.1,
                "failed_mandatory": True,
                "gpa_history": [2.5, 2.8, 3.0, 3.1],  # declining
                "attendance_history": [0.85, 0.83, 0.80, 0.78],  # slight decline
                "enrolled_courses": ["INF102", "MATH201"],
            },
            "student-007": {
                "failed_courses_ratio": 0.1,
                "gpa_trend": 0.05,
                "ects_deficit": 0.05,
                "attendance_decline": 0.0,
                "failed_mandatory": False,
                "gpa_history": [2.1, 2.0, 1.95, 1.9],  # slight improvement
                "attendance_history": [0.92, 0.93, 0.93, 0.94],  # stable
                "enrolled_courses": ["INF102", "STAT101", "PHYS201"],
            },
            "student-008": {
                "failed_courses_ratio": 0.45,
                "gpa_trend": -0.7,
                "ects_deficit": 0.4,
                "attendance_decline": -0.3,
                "failed_mandatory": True,
                "gpa_history": [2.0, 2.6, 3.2, 3.9],  # declining rapidly
                "attendance_history": [0.75, 0.65, 0.50, 0.35],  # declining rapidly
                "enrolled_courses": ["INF102", "MATH201", "STAT101"],
            },
            "student-009": {
                "failed_courses_ratio": 0.2,
                "gpa_trend": 0.0,
                "ects_deficit": 0.15,
                "attendance_decline": -0.08,
                "failed_mandatory": False,
                "gpa_history": [2.3, 2.3, 2.3, 2.3],  # stable
                "attendance_history": [0.88, 0.86, 0.84, 0.82],  # slight decline
                "enrolled_courses": ["INF102", "MATH201"],
            },
            "student-010": {
                "failed_courses_ratio": 0.05,
                "gpa_trend": 0.15,
                "ects_deficit": 0.02,
                "attendance_decline": 0.05,
                "failed_mandatory": False,
                "gpa_history": [1.8, 1.7, 1.6, 1.5],  # good, improving
                "attendance_history": [0.95, 0.96, 0.97, 0.98],  # improving
                "enrolled_courses": ["INF102", "MATH201", "STAT101", "PHYS201"],
            },
        }

    def _generate_enrollment_trends(self) -> dict:
        """Generate mock enrollment trend data.

        Returns:
            Dictionary mapping program IDs to trend data
        """
        return {
            "bachelor-informatik": {
                "historical_enrollment": [450, 465, 480, 490, 510, 520, 535, 550],
                "trend": "increasing",
                "confidence": 0.85,
                "expected_enrollment": 565,
            },
            "bachelor-wirtschaftsinformatik": {
                "historical_enrollment": [320, 310, 300, 295, 290, 285, 280, 275],
                "trend": "decreasing",
                "confidence": 0.75,
                "expected_enrollment": 270,
            },
            "master-informatik": {
                "historical_enrollment": [180, 185, 190, 190, 195, 195, 200, 200],
                "trend": "stable",
                "confidence": 0.90,
                "expected_enrollment": 200,
            },
        }

    async def predict_dropout_risk(
        self, student_id: str, program: str
    ) -> dict[str, Any]:
        """Predict dropout probability for a student.

        Args:
            student_id: Student identifier
            program: Program identifier

        Returns:
            Dictionary with dropout prediction:
            - student_id: Student identifier
            - dropout_probability: Predicted dropout probability (0-1)
            - risk_level: "low", "medium", or "high"
            - risk_factors: List of weighted risk factors
            - course_success_predictions: Predictions for enrolled courses
        """
        # Get student data
        student_data = self._mock_student_data.get(
            student_id, self._get_default_student_data()
        )

        # Calculate risk factors
        risk_factors = await self.get_risk_factors(student_id)

        # Calculate dropout probability as weighted sum
        dropout_probability = sum(rf["score"] * rf["weight"] for rf in risk_factors)

        # Determine risk level
        risk_level = self._calculate_risk_level(dropout_probability)

        # Get course success predictions
        course_success_predictions = {}
        for course_id in student_data.get("enrolled_courses", []):
            prediction = self._predict_course_success_from_risk(
                student_id, course_id, dropout_probability
            )
            course_success_predictions[course_id] = {
                "probability": prediction["success_probability"],
                "risk_level": prediction["risk_level"],
            }

        result = {
            "student_id": student_id,
            "dropout_probability": round(dropout_probability, 2),
            "risk_level": risk_level,
            "risk_factors": [
                {
                    "factor": rf["factor"],
                    "score": round(rf["score"], 2),
                    "weight": rf["weight"],
                    "contribution": round(rf["score"] * rf["weight"], 2),
                }
                for rf in risk_factors
            ],
            "course_success_predictions": course_success_predictions,
        }

        logger.info(
            f"Dropout risk for {student_id}: {dropout_probability:.2f} ({risk_level})"
        )

        return result

    async def predict_course_success(
        self, student_id: str, course_id: str
    ) -> dict[str, Any]:
        """Predict success probability for a specific course.

        Args:
            student_id: Student identifier
            course_id: Course identifier

        Returns:
            Dictionary with course success prediction:
            - student_id: Student identifier
            - course_id: Course identifier
            - success_probability: Predicted success probability (0-1)
            - risk_level: "low", "medium", or "high"
        """
        # Calculate dropout probability directly from risk factors
        risk_factors = await self.get_risk_factors(student_id)
        dropout_probability = sum(rf["score"] * rf["weight"] for rf in risk_factors)

        # Use the helper method to predict success from the calculated dropout probability
        return self._predict_course_success_from_risk(
            student_id, course_id, dropout_probability
        )

    def _predict_course_success_from_risk(
        self, student_id: str, course_id: str, dropout_probability: float
    ) -> dict[str, Any]:
        """Predict success probability for a specific course based on dropout risk.

        Args:
            student_id: Student identifier
            course_id: Course identifier
            dropout_probability: Pre-calculated dropout probability

        Returns:
            Dictionary with course success prediction
        """
        # Get student data
        student_data = self._mock_student_data.get(
            student_id, self._get_default_student_data()
        )

        # Base probability on dropout risk (inverse relationship)
        base_probability = 1.0 - dropout_probability

        # Adjust based on course difficulty (simplified)
        # INF courses considered medium difficulty
        difficulty_factor = 0.9 if course_id.startswith("INF") else 1.0
        # MATH courses considered harder
        difficulty_factor = (
            difficulty_factor * 0.85
            if course_id.startswith("MATH")
            else difficulty_factor
        )

        # Calculate final probability
        success_probability = min(0.95, max(0.15, base_probability * difficulty_factor))

        # Determine risk level
        risk_level = self._calculate_risk_level(1.0 - success_probability)

        result = {
            "student_id": student_id,
            "course_id": course_id,
            "success_probability": round(success_probability, 2),
            "risk_level": risk_level,
        }

        return result

    async def predict_enrollment_trend(self, program: str) -> dict[str, Any]:
        """Predict enrollment trends for a program.

        Args:
            program: Program identifier

        Returns:
            Dictionary with enrollment trend prediction:
            - program: Program identifier
            - expected_enrollment: Predicted enrollment number
            - trend: "increasing", "stable", or "decreasing"
            - confidence: Confidence level of prediction (0-1)
        """
        # Get mock enrollment data
        program_data = self._mock_enrollment_data.get(
            program,
            {
                "historical_enrollment": [300, 305, 310, 315, 320, 325, 330, 335],
                "trend": "stable",
                "confidence": 0.70,
                "expected_enrollment": 340,
            },
        )

        result = {
            "program": program,
            "expected_enrollment": program_data["expected_enrollment"],
            "trend": program_data["trend"],
            "confidence": round(program_data["confidence"], 2),
        }

        logger.info(
            f"Enrollment trend for {program}: {program_data['trend']} "
            f"(expected: {program_data['expected_enrollment']}, "
            f"confidence: {program_data['confidence']:.2f})"
        )

        return result

    async def get_risk_factors(self, student_id: str) -> list[dict]:
        """Get weighted risk factors for a student.

        Args:
            student_id: Student identifier

        Returns:
            List of risk factor dictionaries with:
            - factor: Factor name
            - score: Normalized score (0-1)
            - weight: Factor weight
            - threshold: Risk threshold
            - value: Raw value
        """
        student_data = self._mock_student_data.get(
            student_id, self._get_default_student_data()
        )

        risk_factors = []

        # Failed courses ratio
        failed_courses_ratio = student_data.get("failed_courses_ratio", 0.0)
        failed_score = min(
            1.0,
            failed_courses_ratio / RiskFactorWeights.FAILED_COURSES_RATIO["threshold"],
        )
        risk_factors.append(
            {
                "factor": "failed_courses_ratio",
                "score": failed_score,
                "weight": RiskFactorWeights.FAILED_COURSES_RATIO["weight"],
                "threshold": RiskFactorWeights.FAILED_COURSES_RATIO["threshold"],
                "value": failed_courses_ratio,
            }
        )

        # GPA trend (negative = declining = risky)
        gpa_trend = student_data.get("gpa_trend", 0.0)
        gpa_threshold = RiskFactorWeights.GPA_TREND["threshold"]
        gpa_score = (
            min(1.0, max(0.0, -gpa_trend / abs(gpa_threshold)))
            if gpa_trend < 0
            else 0.0
        )
        risk_factors.append(
            {
                "factor": "gpa_trend",
                "score": gpa_score,
                "weight": RiskFactorWeights.GPA_TREND["weight"],
                "threshold": RiskFactorWeights.GPA_TREND["threshold"],
                "value": gpa_trend,
            }
        )

        # ECTS deficit
        ects_deficit = student_data.get("ects_deficit", 0.0)
        ects_score = min(
            1.0, ects_deficit / RiskFactorWeights.ECTS_DEFICIT["threshold"]
        )
        risk_factors.append(
            {
                "factor": "ects_deficit",
                "score": ects_score,
                "weight": RiskFactorWeights.ECTS_DEFICIT["weight"],
                "threshold": RiskFactorWeights.ECTS_DEFICIT["threshold"],
                "value": ects_deficit,
            }
        )

        # Attendance decline
        attendance_decline = student_data.get("attendance_decline", 0.0)
        attendance_threshold = RiskFactorWeights.ATTENDANCE_DECLINE["threshold"]
        attendance_score = (
            min(1.0, max(0.0, -attendance_decline / abs(attendance_threshold)))
            if attendance_decline < 0
            else 0.0
        )
        risk_factors.append(
            {
                "factor": "attendance_decline",
                "score": attendance_score,
                "weight": RiskFactorWeights.ATTENDANCE_DECLINE["weight"],
                "threshold": RiskFactorWeights.ATTENDANCE_DECLINE["threshold"],
                "value": attendance_decline,
            }
        )

        # Failed mandatory courses
        failed_mandatory = student_data.get("failed_mandatory", False)
        mandatory_score = 1.0 if failed_mandatory else 0.0
        risk_factors.append(
            {
                "factor": "failed_mandatory",
                "score": mandatory_score,
                "weight": RiskFactorWeights.FAILED_MANDATORY["weight"],
                "threshold": RiskFactorWeights.FAILED_MANDATORY["threshold"],
                "value": failed_mandatory,
            }
        )

        return risk_factors

    async def generate_early_warning_report(self, program: str) -> list[dict]:
        """Generate batch dropout prediction for all students in a program.

        Args:
            program: Program identifier

        Returns:
            List of dropout predictions for all students
        """
        logger.info(f"Generating early warning report for {program}")

        report = []

        for student_id in self._mock_student_data.keys():
            prediction = await self.predict_dropout_risk(student_id, program)
            report.append(prediction)

        logger.info(
            f"Early warning report generated: {len(report)} students, "
            f"{sum(1 for p in report if p['risk_level'] == 'high')} high risk, "
            f"{sum(1 for p in report if p['risk_level'] == 'medium')} medium risk"
        )

        return report

    def _calculate_risk_level(self, probability: float) -> str:
        """Calculate risk level from probability.

        Args:
            probability: Risk probability (0-1)

        Returns:
            Risk level: "low", "medium", or "high"
        """
        if probability < 0.33:
            return "low"
        elif probability < 0.66:
            return "medium"
        else:
            return "high"

    def _get_default_student_data(self) -> dict:
        """Get default student data for unknown students.

        Returns:
            Default student data dictionary
        """
        return {
            "failed_courses_ratio": 0.0,
            "gpa_trend": 0.0,
            "ects_deficit": 0.0,
            "attendance_decline": 0.0,
            "failed_mandatory": False,
            "gpa_history": [2.5, 2.5, 2.5, 2.5],
            "attendance_history": [0.90, 0.90, 0.90, 0.90],
            "enrolled_courses": [],
        }

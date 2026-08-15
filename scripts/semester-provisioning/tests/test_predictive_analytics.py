# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
import pytest
from api.utils.predictive_analytics import PredictiveAnalyticsEngine


class TestPredictiveAnalyticsEngine:
    """Test suite for PredictiveAnalyticsEngine."""

    @pytest.mark.asyncio
    async def test_engine_initialization(self):
        """Test that PredictiveAnalyticsEngine initializes correctly."""
        engine = PredictiveAnalyticsEngine()
        assert engine is not None
        assert hasattr(engine, "_mock_student_data")
        assert len(engine._mock_student_data) > 0

    @pytest.mark.asyncio
    async def test_predict_dropout_risk_returns_correct_structure(self):
        """Test that predict_dropout_risk returns correct structure."""
        async with PredictiveAnalyticsEngine() as engine:
            result = await engine.predict_dropout_risk(
                "student-001", "bachelor-informatik"
            )

            assert "student_id" in result
            assert "dropout_probability" in result
            assert "risk_level" in result
            assert "risk_factors" in result
            assert "course_success_predictions" in result
            assert result["student_id"] == "student-001"
            assert 0 <= result["dropout_probability"] <= 1
            assert result["risk_level"] in ["low", "medium", "high"]

    @pytest.mark.asyncio
    async def test_risk_factors_weighted_correctly(self):
        """Test that risk factors are weighted correctly in dropout prediction."""
        async with PredictiveAnalyticsEngine() as engine:
            result = await engine.predict_dropout_risk(
                "student-001", "bachelor-informatik"
            )

            risk_factors = result["risk_factors"]
            total_contribution = sum(rf["contribution"] for rf in risk_factors)

            assert len(risk_factors) > 0
            assert abs(total_contribution - result["dropout_probability"]) < 0.01
            for rf in risk_factors:
                assert "factor" in rf
                assert "score" in rf
                assert "weight" in rf
                assert "contribution" in rf
                assert abs(rf["contribution"] - (rf["score"] * rf["weight"])) < 0.001

    @pytest.mark.asyncio
    async def test_predict_course_success_returns_probability(self):
        """Test that predict_course_success returns probability."""
        async with PredictiveAnalyticsEngine() as engine:
            result = await engine.predict_course_success("student-001", "INF102")

            assert "student_id" in result
            assert "course_id" in result
            assert "success_probability" in result
            assert "risk_level" in result
            assert result["student_id"] == "student-001"
            assert result["course_id"] == "INF102"
            assert 0 <= result["success_probability"] <= 1
            assert result["risk_level"] in ["low", "medium", "high"]

    @pytest.mark.asyncio
    async def test_predict_enrollment_trend_returns_expected_numbers(self):
        """Test that predict_enrollment_trend returns expected enrollment numbers."""
        async with PredictiveAnalyticsEngine() as engine:
            result = await engine.predict_enrollment_trend("bachelor-informatik")

            assert "program" in result
            assert "expected_enrollment" in result
            assert "trend" in result
            assert "confidence" in result
            assert result["program"] == "bachelor-informatik"
            assert isinstance(result["expected_enrollment"], int)
            assert result["trend"] in ["increasing", "stable", "decreasing"]
            assert 0 <= result["confidence"] <= 1

    @pytest.mark.asyncio
    async def test_get_risk_factors_returns_weighted_risk_factors(self):
        """Test that get_risk_factors returns weighted risk factors."""
        async with PredictiveAnalyticsEngine() as engine:
            result = await engine.get_risk_factors("student-001")

            assert isinstance(result, list)
            assert len(result) > 0
            for rf in result:
                assert "factor" in rf
                assert "score" in rf
                assert "weight" in rf
                assert "threshold" in rf
                assert "value" in rf
                assert 0 <= rf["score"] <= 1

    @pytest.mark.asyncio
    async def test_generate_early_warning_report_covers_all_students(self):
        """Test that generate_early_warning_report covers all mock students."""
        async with PredictiveAnalyticsEngine() as engine:
            report = await engine.generate_early_warning_report("bachelor-informatik")

            assert isinstance(report, list)
            assert len(report) == 10  # 10 mock students
            for entry in report:
                assert "student_id" in entry
                assert "dropout_probability" in entry
                assert "risk_level" in entry

    @pytest.mark.asyncio
    async def test_risk_levels_match_probability_thresholds(self):
        """Test that risk levels match probability thresholds."""
        async with PredictiveAnalyticsEngine() as engine:
            result = await engine.predict_dropout_risk(
                "student-001", "bachelor-informatik"
            )

            prob = result["dropout_probability"]
            risk_level = result["risk_level"]

            if prob < 0.33:
                assert risk_level == "low"
            elif prob < 0.66:
                assert risk_level == "medium"
            else:
                assert risk_level == "high"

    @pytest.mark.asyncio
    async def test_edge_case_no_data(self):
        """Test edge case: student with no data."""
        async with PredictiveAnalyticsEngine() as engine:
            result = await engine.predict_dropout_risk(
                "nonexistent-student", "bachelor-informatik"
            )

            assert "dropout_probability" in result
            assert "risk_level" in result

    @pytest.mark.asyncio
    async def test_edge_case_perfect_student(self):
        """Test edge case: perfect student with no risk factors."""
        async with PredictiveAnalyticsEngine() as engine:
            result = await engine.predict_dropout_risk(
                "student-005", "bachelor-informatik"
            )

            assert result["dropout_probability"] < 0.3
            assert result["risk_level"] == "low"

    @pytest.mark.asyncio
    async def test_edge_case_failing_student(self):
        """Test edge case: failing student with high risk."""
        async with PredictiveAnalyticsEngine() as engine:
            result = await engine.predict_dropout_risk(
                "student-003", "bachelor-informatik"
            )

            assert result["dropout_probability"] > 0.6
            assert result["risk_level"] == "high"

    @pytest.mark.asyncio
    async def test_weighted_sum_calculation_correctness(self):
        """Test that weighted sum calculation is mathematically correct."""
        async with PredictiveAnalyticsEngine() as engine:
            result = await engine.predict_dropout_risk(
                "student-001", "bachelor-informatik"
            )

            calculated_prob = sum(
                rf["score"] * rf["weight"] for rf in result["risk_factors"]
            )

            assert abs(calculated_prob - result["dropout_probability"]) < 0.01

    @pytest.mark.asyncio
    async def test_course_success_includes_in_dropout_prediction(self):
        """Test that course success predictions are included in dropout prediction."""
        async with PredictiveAnalyticsEngine() as engine:
            result = await engine.predict_dropout_risk(
                "student-001", "bachelor-informatik"
            )

            assert "course_success_predictions" in result
            assert isinstance(result["course_success_predictions"], dict)
            assert len(result["course_success_predictions"]) > 0

#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Tests for Semester Lifecycle Manager and CLI.
Tests für Semester-Lebenszyklus-Manager und CLI.

EN: Comprehensive tests covering semester detection, configuration loading,
phase detection, transitions, and CLI commands.
"""

from __future__ import annotations

import json
import sys
from datetime import date
from pathlib import Path
from unittest import mock

import pytest
import yaml

sys.path.insert(0, str(Path(__file__).parent.parent))

from config import (
    ArchivalPhaseConfig,
    PhaseDates,
    SemesterPhase,
    SemesterType,
    create_default_semester_config,
    load_semester_config,
    reset_semester_config,
)
from semester_manager import SemesterManager, TransitionReport, get_manager


def _make_sample_config() -> dict:
    return {
        "enabled": True,
        "current": {
            "name": "WS25/26",
            "type": "wintersemester",
            "start_date": "2025-10-01",
            "end_date": "2026-03-31",
            "phases": {
                "enrollment": {"start": "2025-07-01", "end": "2025-09-30"},
                "teaching": {"start": "2025-10-15", "end": "2026-02-28"},
                "exam": {"start": "2026-03-01", "end": "2026-03-31"},
                "archival": {"deadline": "2026-04-15"},
            },
        },
        "automation": {"enabled": True, "timezone": "Europe/Berlin"},
        "provisioning": {
            "default_category": "courses",
            "course_prefix": "",
            "auto_archive": True,
            "archive_retention_years": 5,
        },
        "roles": {
            "sync_on_enrollment_change": True,
            "sync_interval_minutes": 15,
            "role_mappings": [
                {
                    "campus_role": "student",
                    "keycloak_role": "student",
                    "lms_role": "student",
                },
                {"campus_role": "tutor", "keycloak_role": "tutor", "lms_role": "tutor"},
                {
                    "campus_role": "lecturer",
                    "keycloak_role": "instructor",
                    "lms_role": "instructor",
                },
            ],
        },
    }


@pytest.fixture
def config_file(tmp_path):
    path = tmp_path / "semester-config.yaml"
    with open(path, "w") as f:
        yaml.dump({"semester": _make_sample_config()}, f)
    return str(path)


@pytest.fixture
def manager(config_file):
    reset_semester_config()
    mgr = SemesterManager(config_path=config_file)
    yield mgr
    reset_semester_config()


# ---------------------------------------------------------------------------
# Config models
# ---------------------------------------------------------------------------
class TestConfigModels:
    def test_phase_dates_validates_format(self):
        pd = PhaseDates(start="2025-07-01", end="2025-09-30")
        assert pd.get_start_date() == date(2025, 7, 1)
        assert pd.get_end_date() == date(2025, 9, 30)

    def test_phase_dates_rejects_bad_format(self):
        with pytest.raises(ValueError):
            PhaseDates(start="not-a-date", end="2025-09-30")

    def test_archival_phase_config(self):
        ap = ArchivalPhaseConfig(deadline="2026-04-15")
        assert ap.get_deadline_date() == date(2026, 4, 15)

    def test_semester_type_enum(self):
        assert SemesterType.WINTERSEMESTER.value == "wintersemester"
        assert SemesterType.SOMMERSEMESTER.value == "sommersemester"

    def test_semester_phase_enum(self):
        assert SemesterPhase.ENROLLMENT.value == "enrollment"
        assert SemesterPhase.TEACHING.value == "teaching"
        assert SemesterPhase.EXAM.value == "exam"
        assert SemesterPhase.ARCHIVAL.value == "archival"


class TestConfigLoading:
    def test_load_semester_config(self, config_file):
        reset_semester_config()
        cfg = load_semester_config(config_file)
        assert cfg.current.name == "WS25/26"
        assert cfg.current.type == SemesterType.WINTERSEMESTER
        reset_semester_config()

    def test_load_semester_config_file_not_found(self):
        reset_semester_config()
        with pytest.raises(FileNotFoundError):
            load_semester_config("/nonexistent/path.yaml")

    def test_create_default_semester_config(self, tmp_path):
        out = tmp_path / "default-config.yaml"
        create_default_semester_config(str(out))
        assert out.exists()
        data = yaml.safe_load(out.read_text())
        assert "semester" in data
        assert data["semester"]["current"]["name"] == "WS25/26"


# ---------------------------------------------------------------------------
# SemesterManager
# ---------------------------------------------------------------------------
class TestSemesterManagerInit:
    def test_init_with_valid_config(self, manager):
        assert manager._config is not None
        assert manager._config.current.name == "WS25/26"

    def test_init_without_config(self, tmp_path):
        reset_semester_config()
        mgr = SemesterManager(config_path=str(tmp_path / "nonexistent.yaml"))
        assert mgr._config is None
        reset_semester_config()


class TestGetCurrentSemester:
    def test_date_inside_semester(self, manager):
        result = manager.get_current_semester(check_date=date(2025, 11, 15))
        assert result is not None
        assert result.name == "WS25/26"

    def test_date_at_start_boundary(self, manager):
        result = manager.get_current_semester(check_date=date(2025, 10, 1))
        assert result is not None
        assert result.name == "WS25/26"

    def test_date_at_end_boundary(self, manager):
        result = manager.get_current_semester(check_date=date(2026, 3, 31))
        assert result is not None
        assert result.name == "WS25/26"

    def test_date_before_semester(self, manager):
        result = manager.get_current_semester(check_date=date(2025, 6, 15))
        assert result is None

    def test_date_after_semester(self, manager):
        result = manager.get_current_semester(check_date=date(2026, 5, 1))
        assert result is None

    def test_no_config_returns_none(self, tmp_path):
        reset_semester_config()
        mgr = SemesterManager(config_path=str(tmp_path / "missing.yaml"))
        assert mgr.get_current_semester() is None
        reset_semester_config()

    def test_default_date_is_today(self, manager):
        with mock.patch("semester_manager.date") as mock_date:
            mock_date.today.return_value = date(2025, 12, 1)
            result = manager.get_current_semester()
            assert result is not None


class TestGetSemesterConfig:
    def test_get_matching_config(self, manager):
        result = manager.get_semester_config("WS25/26")
        assert result is not None
        assert result.name == "WS25/26"

    def test_get_non_matching_config(self, manager):
        result = manager.get_semester_config("SS25")
        assert result is None

    def test_no_config_returns_none(self, tmp_path):
        reset_semester_config()
        mgr = SemesterManager(config_path=str(tmp_path / "missing.yaml"))
        assert mgr.get_semester_config("WS25/26") is None
        reset_semester_config()


class TestGetSemesterPhase:
    def test_enrollment_phase(self, manager):
        phase = manager.get_semester_phase(check_date=date(2025, 8, 15))
        assert phase == SemesterPhase.ENROLLMENT

    def test_enrollment_phase_boundary_start(self, manager):
        phase = manager.get_semester_phase(check_date=date(2025, 7, 1))
        assert phase == SemesterPhase.ENROLLMENT

    def test_enrollment_phase_boundary_end(self, manager):
        phase = manager.get_semester_phase(check_date=date(2025, 9, 30))
        assert phase == SemesterPhase.ENROLLMENT

    def test_teaching_phase(self, manager):
        phase = manager.get_semester_phase(check_date=date(2025, 11, 15))
        assert phase == SemesterPhase.TEACHING

    def test_teaching_phase_boundary_start(self, manager):
        phase = manager.get_semester_phase(check_date=date(2025, 10, 15))
        assert phase == SemesterPhase.TEACHING

    def test_teaching_phase_boundary_end(self, manager):
        phase = manager.get_semester_phase(check_date=date(2026, 2, 28))
        assert phase == SemesterPhase.TEACHING

    def test_exam_phase(self, manager):
        phase = manager.get_semester_phase(check_date=date(2026, 3, 15))
        assert phase == SemesterPhase.EXAM

    def test_exam_phase_boundary_start(self, manager):
        phase = manager.get_semester_phase(check_date=date(2026, 3, 1))
        assert phase == SemesterPhase.EXAM

    def test_exam_phase_boundary_end(self, manager):
        phase = manager.get_semester_phase(check_date=date(2026, 3, 31))
        assert phase == SemesterPhase.EXAM

    def test_archival_phase_after_exam(self, manager):
        phase = manager.get_semester_phase(check_date=date(2026, 4, 1))
        assert phase == SemesterPhase.ARCHIVAL

    def test_gap_between_enrollment_and_teaching(self, manager):
        phase = manager.get_semester_phase(check_date=date(2025, 10, 5))
        assert phase is None

    def test_gap_between_teaching_and_exam(self, manager):
        # Feb 28 is end of teaching, Mar 1 is start of exam - no gap here
        phase = manager.get_semester_phase(check_date=date(2026, 2, 28))
        assert phase == SemesterPhase.TEACHING

    def test_no_config_returns_none(self, tmp_path):
        reset_semester_config()
        mgr = SemesterManager(config_path=str(tmp_path / "missing.yaml"))
        assert mgr.get_semester_phase() is None
        reset_semester_config()

    def test_with_semester_name(self, manager):
        phase = manager.get_semester_phase(
            check_date=date(2025, 8, 15), semester_name="WS25/26"
        )
        assert phase == SemesterPhase.ENROLLMENT

    def test_with_nonexistent_semester_name(self, manager):
        phase = manager.get_semester_phase(
            check_date=date(2025, 8, 15), semester_name="SS99"
        )
        assert phase is None


class TestTransitionSemester:
    def test_dry_run_returns_success(self, manager):
        report = manager.transition_semester(
            old_semester="WS24/25", new_semester="WS25/26", dry_run=True
        )
        assert report.success is True
        assert report.old_semester == "WS24/25"
        assert report.new_semester == "WS25/26"
        assert report.archived_courses == []
        assert report.created_courses == []
        assert report.synced_enrollments == 0
        assert report.errors == []

    def test_real_transition_no_deps(self, manager):
        report = manager.transition_semester(
            old_semester="WS24/25", new_semester="WS25/26"
        )
        assert isinstance(report, TransitionReport)
        assert report.old_semester == "WS24/25"
        assert report.new_semester == "WS25/26"
        assert report.success is True

    def test_transition_with_course_api_error(self, manager):
        mock_api = mock.MagicMock()
        mock_api.list_courses.side_effect = RuntimeError("API down")
        manager._course_api = mock_api
        manager._archive_semester_courses = mock.MagicMock(
            side_effect=RuntimeError("archive failed")
        )
        report = manager.transition_semester("WS24/25", "WS25/26")
        assert report.success is False
        assert any(e["step"] == "archive_courses" for e in report.errors)

    def test_transition_with_role_sync(self, manager):
        mock_sync = mock.MagicMock()
        manager._role_sync = mock_sync
        report = manager.transition_semester("WS24/25", "WS25/26")
        assert isinstance(report, TransitionReport)

    def test_transition_report_model(self):
        report = TransitionReport(
            old_semester="A",
            new_semester="B",
            transitioned_at="2025-01-01T00:00:00Z",
        )
        assert report.old_semester == "A"
        assert report.new_semester == "B"
        assert report.success is True


class TestGetAllPhases:
    def test_returns_all_phases(self, manager):
        phases = manager.get_all_phases()
        assert "enrollment" in phases
        assert "teaching" in phases
        assert "exam" in phases
        assert "archival" in phases
        assert phases["enrollment"]["start"] == "2025-07-01"
        assert phases["enrollment"]["end"] == "2025-09-30"
        assert phases["archival"]["deadline"] == "2026-04-15"

    def test_with_semester_name(self, manager):
        phases = manager.get_all_phases(semester_name="WS25/26")
        assert "enrollment" in phases

    def test_no_config_returns_empty(self, tmp_path):
        reset_semester_config()
        mgr = SemesterManager(config_path=str(tmp_path / "missing.yaml"))
        assert mgr.get_all_phases() == {}
        reset_semester_config()


class TestToDict:
    def test_configured_manager(self, manager):
        with mock.patch("semester_manager.date") as mock_date:
            mock_date.today.return_value = date(2025, 12, 1)
            d = manager.to_dict()
        assert d["status"] == "configured"
        assert d["current_semester"] == "WS25/26"

    def test_unconfigured_manager(self, tmp_path):
        reset_semester_config()
        mgr = SemesterManager(config_path=str(tmp_path / "missing.yaml"))
        d = mgr.to_dict()
        assert d["status"] == "no_configuration"
        reset_semester_config()


class TestGetManager:
    def test_factory_function(self, config_file):
        reset_semester_config()
        mgr = get_manager(config_path=config_file)
        assert isinstance(mgr, SemesterManager)
        assert mgr._config is not None
        reset_semester_config()


class TestArchiveSemesterCourses:
    def test_with_no_course_api(self, manager):
        manager._course_api = None
        result = manager._archive_semester_courses("WS24/25")
        assert result == []

    def test_with_course_api_placeholder(self, manager):
        mock_api = mock.MagicMock()
        manager._course_api = mock_api
        result = manager._archive_semester_courses("WS24/25")
        assert isinstance(result, list)


# ---------------------------------------------------------------------------
# CLI tests
# ---------------------------------------------------------------------------
class TestCLI:
    def test_parser_creation(self):
        from cli import create_parser

        parser = create_parser()
        assert parser.prog == "semester-provisioning"

    def test_current_command_json(self, config_file):
        from cli import cmd_current

        reset_semester_config()
        args = mock.MagicMock()
        args.config = config_file
        args.json = True
        args.date = "2025-12-01"

        with mock.patch("builtins.print") as mock_print:
            ret = cmd_current(args)

        assert ret == 0
        mock_print.assert_called_once()
        output = mock_print.call_args[0][0]
        data = json.loads(output)
        assert data["semester"]["name"] == "WS25/26"
        reset_semester_config()

    def test_current_command_no_semester(self, tmp_path):
        from cli import cmd_current

        reset_semester_config()
        args = mock.MagicMock()
        args.config = str(tmp_path / "missing.yaml")
        args.json = False
        args.date = None

        with mock.patch("builtins.print"):
            ret = cmd_current(args)

        assert ret == 1
        reset_semester_config()

    def test_transition_command_dry_run(self, config_file):
        from cli import cmd_transition

        reset_semester_config()
        args = mock.MagicMock()
        args.config = config_file
        args.old = "WS24/25"
        args.new = "WS25/26"
        args.dry_run = True

        with mock.patch("builtins.print"):
            ret = cmd_transition(args)

        assert ret == 0
        reset_semester_config()

    def test_transition_command_real(self, config_file):
        from cli import cmd_transition

        reset_semester_config()
        args = mock.MagicMock()
        args.config = config_file
        args.old = "WS24/25"
        args.new = "WS25/26"
        args.dry_run = False

        with mock.patch("builtins.print"):
            ret = cmd_transition(args)

        assert ret == 0
        reset_semester_config()

    def test_phases_command_json(self, config_file):
        from cli import cmd_phases

        reset_semester_config()
        args = mock.MagicMock()
        args.config = config_file
        args.json = True

        with mock.patch("builtins.print") as mock_print:
            ret = cmd_phases(args)

        assert ret == 0
        output = mock_print.call_args[0][0]
        data = json.loads(output)
        assert "phases" in data
        assert data["semester"] == "WS25/26"
        reset_semester_config()

    def test_phases_command_no_config(self, tmp_path):
        from cli import cmd_phases

        reset_semester_config()
        args = mock.MagicMock()
        args.config = str(tmp_path / "missing.yaml")
        args.json = False

        with mock.patch("builtins.print"):
            ret = cmd_phases(args)

        assert ret == 1
        reset_semester_config()

    def test_main_no_command(self):
        from cli import main

        with mock.patch("sys.argv", ["semester-provisioning"]):
            ret = main()
        assert ret == 0

    def test_main_unknown_command(self):
        from cli import main

        with mock.patch("sys.argv", ["semester-provisioning", "unknown"]):
            ret = main()
        assert ret == 1

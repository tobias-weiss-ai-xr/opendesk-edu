#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Command-line interface for semester lifecycle management.
Befehlszeilenschnittstelle für das Semester-Lebenszyklus-Management.

EN: Provides CLI commands for viewing semester info and triggering transitions.
DE: Bietet CLI-Befehle zum Anzeigen von Semesterinformationen und zum Auslösen von Übergängen.
"""

from __future__ import annotations

import argparse
import json
import logging
import sys
from datetime import date, datetime
from typing import Optional

from config import reset_semester_config
from semester_manager import SemesterManager

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


def create_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="semester-provisioning",
        description="Semester Lifecycle Management CLI / Semester-Lebenszyklus-Management-CLI",
    )
    subparsers = parser.add_subparsers(
        dest="command", help="Available commands / Verfügbare Befehle"
    )

    # --- current ---
    cur = subparsers.add_parser(
        "current",
        help="Display current semester info / Aktuelle Semester-Information anzeigen",
    )
    cur.add_argument("--config", "-c", type=str, default=None)
    cur.add_argument("--json", "-j", action="store_true")
    cur.add_argument("--date", "-d", type=str, default=None)

    # --- transition ---
    tr = subparsers.add_parser(
        "transition",
        help="Execute semester transition / Semesterübergang ausführen",
    )
    tr.add_argument("--old", "-o", type=str, required=True)
    tr.add_argument("--new", "-n", type=str, required=True)
    tr.add_argument("--config", "-c", type=str, default=None)
    tr.add_argument("--dry-run", action="store_true")

    # --- phases ---
    ph = subparsers.add_parser(
        "phases",
        help="Display all semester phases / Alle Semester-Phasen anzeigen",
    )
    ph.add_argument("--config", "-c", type=str, default=None)
    ph.add_argument("--json", "-j", action="store_true")

    return parser


def cmd_current(args: argparse.Namespace) -> int:
    manager = SemesterManager(config_path=args.config)

    check_date = None
    if args.date:
        check_date = datetime.strptime(args.date, "%Y-%m-%d").date()

    current_semester = manager.get_current_semester(check_date=check_date)
    current_phase = manager.get_semester_phase(check_date=check_date)

    if current_semester is None:
        print("No current semester configured for the given date.")
        print("  Use --config to provide a semester configuration file.")
        return 1

    if args.json:
        payload = {
            "semester": current_semester.model_dump(),
            "current_phase": current_phase.value if current_phase else None,
            "date_checked": str(check_date or date.today()),
        }
        print(json.dumps(payload, indent=2, default=str))
    else:
        print("\n=== Current Semester ===")
        print(f"Name:       {current_semester.name}")
        print(f"Type:       {current_semester.type.value}")
        print(f"Start:      {current_semester.start_date}")
        print(f"End:        {current_semester.end_date}")
        print(
            f"Phase:      {current_phase.value if current_phase else 'outside semester'}"
        )
        print("============================\n")

    return 0


def cmd_transition(args: argparse.Namespace) -> int:
    manager = SemesterManager(config_path=args.config)

    report = manager.transition_semester(
        old_semester=args.old,
        new_semester=args.new,
        dry_run=args.dry_run,
    )

    print("\n=== Semester Transition Report ===")
    print(f"Old Semester:        {report.old_semester}")
    print(f"New Semester:        {report.new_semester}")
    print(f"Archived Courses:    {len(report.archived_courses)}")
    print(f"Created Courses:     {len(report.created_courses)}")
    print(f"Synced Enrollments:  {report.synced_enrollments}")
    print(f"Errors:              {len(report.errors)}")
    print(f"Success:             {report.success}")
    print("==================================\n")

    if args.dry_run:
        print("(dry-run — no changes were made)\n")

    return 0


def cmd_phases(args: argparse.Namespace) -> int:
    config_file = args.config

    if config_file is None:
        print("No config loaded.")
        return 1

    try:
        manager = SemesterManager(config_path=config_file)
        phases = manager.get_all_phases()
    except FileNotFoundError:
        print(f"Configuration file not found: {config_file}")
        return 1
    except Exception as e:
        print(f"Error loading config: {e}")
        return 1

    if not phases:
        print("No semester configuration loaded.")
        print("  Use --config to provide a semester configuration file.")
        return 1

    if args.json:
        config = manager._config
        semester_name = config.current.name if config else None
        payload = {
            "phases": phases,
            "semester": semester_name,
        }
        print(json.dumps(payload, indent=2, default=str))
    else:
        print("\n=== Semester Phases ===")
        for phase_name, dates in phases.items():
            print(f"  {phase_name}:")
            for key, val in dates.items():
                print(f"    {key}: {val}")
        print("========================\n")

    return 0


def main(argv: Optional[list[str]] = None) -> int:
    parser = create_parser()
    try:
        args = parser.parse_args(argv)
    except SystemExit:
        # Normalize unknown-command exits to a 1, so tests can assert on return codes
        return 1

    reset_semester_config()

    dispatch = {
        "current": cmd_current,
        "transition": cmd_transition,
        "phases": cmd_phases,
    }

    handler = dispatch.get(args.command)
    if handler is None:
        parser.print_help()
        return 0

    return handler(args)


if __name__ == "__main__":
    sys.exit(main())

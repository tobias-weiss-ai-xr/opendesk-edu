# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Bulk archival script for semester-end course archival.
Massenarchivierungsskript für Kursarchivierung am Semesterende.

EN: Provides `bulk_archive_semester` to archive all active courses for a
given semester, with progress tracking, error handling, and summary reports.

DE: Stellt `bulk_archive_semester` bereit, um alle aktiven Kurse eines
gegebenen Semesters zu archivieren, mit Fortschrittsverfolgung,
Fehlerbehandlung und Zusammenfassungsberichten.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Optional

from pydantic import BaseModel, Field

from audit import AuditAction, AuditLogger
from database import Database
from archival.archive_course import ArchiveResult, archive_course

logger = logging.getLogger(__name__)


class BulkArchiveSummary(BaseModel):
    """
    Summary report of a bulk archival operation.
    Zusammenfassungsbericht einer Massenarchivierung.

    EN: Captures the outcome of archiving all courses for a semester,
    including counts of successful/failed operations and per-course results.
    DE: Erfasst das Ergebnis der Archivierung aller Kurse eines Semesters,
    einschließlich der Anzahl erfolgreicher/fehlgeschlagener Vorgänge und
    einzelner Kursergebnisse.
    """

    semester_id: str
    started_at: datetime
    completed_at: Optional[datetime] = None
    total_courses: int = 0
    archived_courses: int = 0
    skipped_courses: int = 0
    failed_courses: int = 0
    total_frozen_enrollments: int = 0
    total_revoked_access: int = 0
    results: list[ArchiveResult] = Field(default_factory=list)
    errors: list[dict[str, str]] = Field(default_factory=list)
    success: bool = True


def bulk_archive_semester(
    semester_id: str,
    *,
    database: Database,
    audit_logger: AuditLogger,
    create_snapshots: bool = True,
    dry_run: bool = False,
    ilias_client: Optional[Any] = None,
    moodle_client: Optional[Any] = None,
) -> BulkArchiveSummary:
    """
    Archive all active courses for a semester.
    Alle aktiven Kurse eines Semesters archivieren.

    EN: Iterates over all active courses for the given semester and archives
    each one. Produces a summary report with per-course results.
    In dry-run mode, reports what would be archived without making changes.

    DE: Iteriert über alle aktiven Kurse des angegebenen Semesters und
    archiviert jeden einzelnen. Erzeugt einen Zusammenfassungsbericht mit
    einzelnen Kursergebnissen. Im Probelauf-Modus wird nur berichtet, was
    archiviert würde, ohne Änderungen vorzunehmen.

    Args:
        semester_id: Semester identifier / Semesterkennung.
        database: Database instance / Datenbankinstanz.
        audit_logger: Audit logger instance / Audit-Logger-Instanz.
        create_snapshots: Whether to create snapshots / Ob Snapshots erstellt werden sollen.
        dry_run: Simulate without changes / Simulieren ohne Änderungen.
        ilias_client: Optional ILIAS archival client / Optionaler ILIAS-Archiv-Client.
        moodle_client: Optional Moodle archival client / Optionaler Moodle-Archiv-Client.

    Returns:
        BulkArchiveSummary with full results / BulkArchiveSummary mit vollständigen Ergebnissen.
    """
    started_at = datetime.now(timezone.utc)
    summary = BulkArchiveSummary(
        semester_id=semester_id,
        started_at=started_at,
    )

    logger.info(
        f"Starting bulk archival for semester {semester_id}"
        f" / Starte Massenarchivierung für Semester {semester_id}"
    )

    courses, total = database.list_courses(semester_id=semester_id, status="active")
    summary.total_courses = total

    if dry_run:
        logger.info(
            f"DRY RUN: Would archive {total} courses for semester {semester_id}"
            f" / PROBELAUF: Würde {total} Kurse für Semester {semester_id} archivieren"
        )
        summary.completed_at = datetime.now(timezone.utc)
        summary.archived_courses = 0
        summary.skipped_courses = total
        _log_bulk_operation(audit_logger, summary, dry_run=True)
        return summary

    logger.info(
        f"Found {total} active courses for semester {semester_id}"
        f" / {total} aktive Kurse für Semester {semester_id} gefunden"
    )

    for course_data in courses:
        course_id = course_data["course_id"]
        try:
            result = archive_course(
                course_id,
                database=database,
                audit_logger=audit_logger,
                create_snapshot=create_snapshots,
                ilias_client=ilias_client,
                moodle_client=moodle_client,
            )

            summary.results.append(result)

            if result.success:
                summary.archived_courses += 1
                summary.total_frozen_enrollments += result.frozen_enrollments
                summary.total_revoked_access += result.revoked_access_count
            else:
                # Treat already-archived courses as skipped rather than failures
                error = (result.error or "").lower()
                if "already archived" in error:
                    summary.skipped_courses += 1
                else:
                    summary.failed_courses += 1
                    summary.errors.append(
                        {
                            "course_id": course_id,
                            "error": result.error or "unknown error",
                        }
                    )

        except Exception as exc:
            summary.failed_courses += 1
            error_msg = f"{type(exc).__name__}: {exc}"
            summary.errors.append({"course_id": course_id, "error": error_msg})
            summary.results.append(
                ArchiveResult(course_id=course_id, success=False, error=error_msg)
            )
            logger.error(
                f"Failed to archive course {course_id}: {exc}"
                f" / Archivierung von Kurs {course_id} fehlgeschlagen: {exc}"
            )

    summary.completed_at = datetime.now(timezone.utc)
    summary.skipped_courses = (
        summary.total_courses - summary.archived_courses - summary.failed_courses
    )
    summary.success = summary.failed_courses == 0

    _log_bulk_operation(audit_logger, summary, dry_run=False)

    logger.info(
        f"Bulk archival for semester {semester_id} completed: "
        f"{summary.archived_courses} archived, {summary.failed_courses} failed, "
        f"{summary.total_frozen_enrollments} enrollments frozen"
        f" / Massenarchivierung für Semester {semester_id} abgeschlossen: "
        f"{summary.archived_courses} archiviert, {summary.failed_courses} fehlgeschlagen, "
        f"{summary.total_frozen_enrollments} Einschreibungen eingefroren"
    )

    return summary


def _log_bulk_operation(
    audit_logger: AuditLogger,
    summary: BulkArchiveSummary,
    *,
    dry_run: bool,
) -> None:
    """
    Log the bulk archival operation to the audit trail.
    Den Massenarchivierungsvorgang im Audit-Trail protokollieren.

    EN: Creates a single audit log entry summarizing the entire bulk operation.
    DE: Erstellt einen einzelnen Audit-Log-Eintrag, der den gesamten
    Massenvorgang zusammenfasst.

    Args:
        audit_logger: Audit logger instance / Audit-Logger-Instanz.
        summary: The bulk archive summary / Die Massenarchivierungs-Zusammenfassung.
        dry_run: Whether this was a dry run / Ob dies ein Probelauf war.
    """
    audit_logger.log(
        action=AuditAction.BULK_OPERATION,
        entity_type="semester",
        entity_id=summary.semester_id,
        details={
            "operation": "bulk_archive",
            "dry_run": dry_run,
            "total_courses": summary.total_courses,
            "archived_courses": summary.archived_courses,
            "failed_courses": summary.failed_courses,
            "total_frozen_enrollments": summary.total_frozen_enrollments,
            "total_revoked_access": summary.total_revoked_access,
            "started_at": summary.started_at.isoformat(),
            "completed_at": summary.completed_at.isoformat()
            if summary.completed_at
            else None,
            "success": summary.success,
        },
    )

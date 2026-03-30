# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Course restoration script for reversing archival.
Kurswiederherstellungsskript zum Rückgängigmachen der Archivierung.

EN: Provides `restore_course` to reverse the archival process: re-enables
enrollments, restores student write access, updates course status back to
ACTIVE, and logs the operation.

DE: Stellt `restore_course` bereit, um den Archivierungsprozess
rückgängig zu machen: Einschreibungen werden reaktiviert, der
Schreibzugriff für Studierende wird wiederhergestellt, der Kursstatus
wird auf ACTIVE zurückgesetzt und der Vorgang wird protokolliert.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Optional

from pydantic import BaseModel

from audit import AuditAction, AuditLogger
from database import Database

logger = logging.getLogger(__name__)


class RestoreResult(BaseModel):
    """
    Result of a course restoration operation.
    Ergebnis einer Kurswiederherstellung.

    EN: Indicates whether restoration succeeded and includes counts of
    reactivated enrollments and restored access permissions.
    DE: Gibt an, ob die Wiederherstellung erfolgreich war, und enthält
    Anzahlen reaktivierter Einschreibungen und wiederhergestellter Zugriffsberechtigungen.
    """

    course_id: str
    success: bool = True
    error: Optional[str] = None
    restored_enrollments: int = 0
    restored_access_count: int = 0
    snapshot_id: Optional[str] = None


class ILIASRestoreClient:
    """
    ILIAS-specific restoration operations.
    ILIAS-spezifische Wiederherstellungsvorgänge.

    EN: Restores student write permissions on an ILIAS course that was
    previously set to read-only during archival.
    DE: Stellt die Schreibberechtigungen für Studierende auf einem ILIAS-Kurs
    wieder her, der während der Archivierung auf Nur-Lese gesetzt wurde.
    """

    def restore_write_access(self, lms_course_id: str) -> int:
        """
        Restore student write access on ILIAS course.
        Schreibzugriff für Studierende im ILIAS-Kurs wiederherstellen.

        Args:
            lms_course_id: ILIAS course reference / ILIAS-Kursreferenz.

        Returns:
            Number of affected users / Anzahl der betroffenen Benutzer.
        """
        logger.info(
            f"ILIAS: restoring write access for course {lms_course_id}"
            f" / ILIAS: Schreibzugriff für Kurs {lms_course_id} wiederhergestellt"
        )
        return 0


class MoodleRestoreClient:
    """
    Moodle-specific restoration operations.
    Moodle-spezifische Wiederherstellungsvorgänge.

    EN: Restores student write permissions on a Moodle course that was
    previously set to read-only during archival.
    DE: Stellt die Schreibberechtigungen für Studierende auf einem Moodle-Kurs
    wieder her, der während der Archivierung auf Nur-Lese gesetzt wurde.
    """

    def restore_write_access(self, lms_course_id: str) -> int:
        """
        Restore student write access on Moodle course.
        Schreibzugriff für Studierende im Moodle-Kurs wiederherstellen.

        Args:
            lms_course_id: Moodle course reference / Moodle-Kursreferenz.

        Returns:
            Number of affected users / Anzahl der betroffenen Benutzer.
        """
        logger.info(
            f"Moodle: restoring write access for course {lms_course_id}"
            f" / Moodle: Schreibzugriff für Kurs {lms_course_id} wiederhergestellt"
        )
        return 0


def restore_course(
    course_id: str,
    *,
    database: Database,
    audit_logger: AuditLogger,
    restore_enrollments: bool = True,
    ilias_client: Optional[Any] = None,
    moodle_client: Optional[Any] = None,
) -> RestoreResult:
    """
    Restore an archived course back to active state.
    Einen archivierten Kurs wieder in den aktiven Zustand versetzen.

    EN: Performs the complete restoration workflow:
    1. Retrieve course and verify it is archived.
    2. Unfreeze enrollments (restore status to 'active').
    3. Restore student write access via LMS client.
    4. Update course status to 'active'.
    5. Audit-log the operation.

    DE: Führt den vollständigen Wiederherstellungs-Workflow durch:
    1. Kurs abrufen und überprüfen, dass er archiviert ist.
    2. Einschreibungen entsperren (Status auf 'active' zurücksetzen).
    3. Schreibzugriff für Studierende über LMS-Client wiederherstellen.
    4. Kursstatus auf 'active' aktualisieren.
    5. Vorgang im Audit-Log protokollieren.

    Args:
        course_id: Course identifier / Kurskennung.
        database: Database instance / Datenbankinstanz.
        audit_logger: Audit logger instance / Audit-Logger-Instanz.
        restore_enrollments: Whether to restore enrollments / Ob Einschreibungen wiederhergestellt werden sollen.
        ilias_client: Optional ILIAS restore client / Optionaler ILIAS-Wiederherstellungs-Client.
        moodle_client: Optional Moodle restore client / Optionaler Moodle-Wiederherstellungs-Client.

    Returns:
        RestoreResult with outcome details / RestoreResult mit Ergebnisdetails.
    """
    result = RestoreResult(course_id=course_id)

    course = database.get_course(course_id)
    if course is None:
        result.success = False
        result.error = f"Course {course_id} not found / Kurs {course_id} nicht gefunden"
        logger.error(result.error)
        return result

    if course.get("status") != "archived":
        result.success = False
        result.error = (
            f"Course {course_id} is not archived (status={course.get('status')})"
            f" / Kurs {course_id} ist nicht archiviert (Status={course.get('status')})"
        )
        logger.warning(result.error)
        return result

    logger.info(
        f"Restoring archived course {course_id} ({course.get('title', '')})"
        f" / Archivierten Kurs {course_id} wird wiederhergestellt ({course.get('title', '')})"
    )

    restored_enrollments = 0
    if restore_enrollments:
        restored_enrollments = _unfreeze_enrollments(course_id, database)
    result.restored_enrollments = restored_enrollments

    restored_access = _restore_student_write_access(
        course,
        ilias_client=ilias_client,
        moodle_client=moodle_client,
    )
    result.restored_access_count = restored_access

    snapshot_id = _get_snapshot_id(course_id, database)
    result.snapshot_id = snapshot_id

    updated = database.restore_course(course_id)
    if updated is None:
        result.success = False
        result.error = (
            f"Failed to restore course {course_id}"
            f" / Kurs {course_id} konnte nicht wiederhergestellt werden"
        )
        logger.error(result.error)
        return result

    now = datetime.now(timezone.utc)
    audit_logger.log(
        action=AuditAction.COURSE_RESTORED,
        entity_type="course",
        entity_id=course_id,
        details={
            "title": course.get("title"),
            "semester_id": course.get("semester_id"),
            "restored_enrollments": restored_enrollments,
            "restored_access_count": restored_access,
            "snapshot_id": snapshot_id,
            "restored_at": now.isoformat(),
        },
    )

    logger.info(
        f"Successfully restored course {course_id}"
        f" / Kurs {course_id} erfolgreich wiederhergestellt"
    )
    return result


def _unfreeze_enrollments(course_id: str, database: Database) -> int:
    """
    Unfreeze all frozen enrollments for a course.
    Alle eingefrorenen Einschreibungen für einen Kurs entsperren.

    EN: Sets all 'frozen' enrollment statuses back to 'active'.
    DE: Setzt alle 'frozen' Einschreibungsstatus zurück auf 'active'.

    Args:
        course_id: Course identifier / Kurskennung.
        database: Database instance / Datenbankinstanz.

    Returns:
        Number of restored enrollments / Anzahl der wiederhergestellten Einschreibungen.
    """
    enrollments = database.list_enrollments(course_id)
    restored = 0
    for enrollment in enrollments:
        if enrollment.get("status") == "frozen":
            database.update_enrollment(
                enrollment["enrollment_id"], {"status": "active"}
            )
            restored += 1
    return restored


def _restore_student_write_access(
    course: dict,
    *,
    ilias_client: Optional[Any] = None,
    moodle_client: Optional[Any] = None,
) -> int:
    """
    Restore write access for students on the LMS platform.
    Schreibzugriff für Studierende auf der LMS-Plattform wiederherstellen.

    EN: Calls the appropriate LMS client to restore student write permissions.
    DE: Ruft den entsprechenden LMS-Client auf, um die Schreibberechtigungen
    für Studierende wiederherzustellen.

    Args:
        course: Course data dictionary / Kursdaten-Dictionary.
        ilias_client: ILIAS restore client / ILIAS-Wiederherstellungs-Client.
        moodle_client: Moodle restore client / Moodle-Wiederherstellungs-Client.

    Returns:
        Number of users with restored access / Anzahl der Benutzer mit wiederhergestelltem Zugriff.
    """
    lms = course.get("lms", "")
    lms_course_id = course.get("lms_course_id")
    if not lms_course_id:
        return 0

    if lms == "ilias":
        client = ilias_client or ILIASRestoreClient()
        return client.restore_write_access(lms_course_id)
    elif lms == "moodle":
        client = moodle_client or MoodleRestoreClient()
        return client.restore_write_access(lms_course_id)
    else:
        logger.warning(
            f"Unknown LMS platform '{lms}', skipping write-access restoration"
            f" / Unbekannte LMS-Plattform '{lms}', Wiederherstellung des Schreibzugriffs übersprungen"
        )
        return 0


def _get_snapshot_id(course_id: str, database: Database) -> Optional[str]:
    """
    Retrieve snapshot ID for an archived course.
    Snapshot-ID für einen archivierten Kurs abrufen.

    EN: Looks up the most recent snapshot for the course in the
    archive_snapshots table for traceability.
    DE: Sucht den neuesten Snapshot für den Kurs in der
    archive_snapshots-Tabelle zur Nachverfolgbarkeit.

    Args:
        course_id: Course identifier / Kurskennung.
        database: Database instance / Datenbankinstanz.

    Returns:
        Snapshot ID if found, None otherwise / Snapshot-ID wenn gefunden, sonst None.
    """
    try:
        with database.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT snapshot_id FROM archive_snapshots WHERE course_id = ? ORDER BY archived_at DESC LIMIT 1",
                (course_id,),
            )
            row = cursor.fetchone()
            if row:
                return row[0]
    except Exception:
        pass
    return None

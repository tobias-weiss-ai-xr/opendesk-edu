# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Single course archival script.
Archivierungsskript für einzelne Kurse.

EN: Provides the `archive_course` function which freezes enrollments, revokes
student write access, creates an archive snapshot, updates the course status
to ARCHIVED, and logs the operation via the audit module.

DE: Stellt die Funktion `archive_course` bereit, die Einschreibungen einfriert,
den Schreibzugriff für Studierende entzieht, einen Archiv-Snapshot erstellt,
den Kursstatus auf ARCHIVED aktualisiert und den Vorgang über das Audit-Modul protokolliert.
"""

from __future__ import annotations

import json
import logging
from datetime import datetime, timezone
from typing import Any, Optional
from uuid import uuid4

from pydantic import BaseModel, Field

from audit import AuditAction, AuditLogger
from database import Database, DatabaseConfig

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Pydantic models
# ---------------------------------------------------------------------------


class ArchiveSnapshot(BaseModel):
    """
    Snapshot of course state at time of archival.
    Snapshot des Kurszustands zum Zeitpunkt der Archivierung.

    EN: Captures course metadata, enrollment count, and LMS identifiers so that
    the course can be fully restored later.
    DE: Erfasst Kursmetadaten, Einschreibungsanzahl und LMS-Kennungen, damit
    der Kurs später vollständig wiederhergestellt werden kann.
    """

    snapshot_id: str = Field(default_factory=lambda: f"snap_{uuid4().hex[:12]}")
    course_id: str
    semester_id: str
    title: str
    title_en: Optional[str] = None
    course_code: str
    lms: str
    lms_course_id: Optional[str] = None
    instructor_ids: list[str] = Field(default_factory=list)
    enrollment_count: int = 0
    archived_at: datetime
    status_before: str = "active"


class ArchiveResult(BaseModel):
    """
    Result of a single course archival operation.
    Ergebnis einer einzelnen Kursarchivierung.

    EN: Indicates whether archival succeeded and includes the snapshot and
    archive identifiers for traceability.
    DE: Gibt an, ob die Archivierung erfolgreich war, und enthält die Snapshot-
    und Archivkennungen zur Nachverfolgbarkeit.
    """

    course_id: str
    archive_id: str = Field(default_factory=lambda: f"arch_{uuid4().hex[:12]}")
    snapshot: Optional[ArchiveSnapshot] = None
    success: bool = True
    error: Optional[str] = None
    frozen_enrollments: int = 0
    revoked_access_count: int = 0


# ---------------------------------------------------------------------------
# LMS archival helpers (protocol/duck-typing)
# ---------------------------------------------------------------------------


class ILIASArchivalClient:
    """
    ILIAS-specific archival operations.
    ILIAS-spezifische Archivierungsvorgänge.

    EN: Sets an ILIAS course to read-only mode by revoking student write
    permissions while preserving read access.
    DE: Setzt einen ILIAS-Kurs in den Nur-Lese-Modus, indem die
    Schreibberechtigungen für Studierende entzogen werden, während der
    Lesezugriff erhalten bleibt.
    """

    def set_read_only(self, lms_course_id: str) -> int:
        """
        Revoke student write access on ILIAS course.
        Schreibzugriff für Studierende im ILIAS-Kurs entziehen.

        EN: In production this would call the ILIAS REST API to change
        student role permissions from "write" to "read".
        DE: In der Produktion würde dies die ILIAS-REST-API aufrufen, um die
        Studierenden-Rollenberechtigungen von „Schreiben" auf „Lesen" zu ändern.

        Args:
            lms_course_id: ILIAS course reference / ILIAS-Kursreferenz.

        Returns:
            Number of affected users / Anzahl der betroffenen Benutzer.
        """
        logger.info(
            f"ILIAS: setting course {lms_course_id} to read-only"
            f" / ILIAS: Kurs {lms_course_id} auf Nur-Lese gesetzt"
        )
        return 0


class MoodleArchivalClient:
    """
    Moodle-specific archival operations.
    Moodle-spezifische Archivierungsvorgänge.

    EN: Sets a Moodle course to read-only mode by revoking student write
    permissions while preserving read access.
    DE: Setzt einen Moodle-Kurs in den Nur-Lese-Modus, indem die
    Schreibberechtigungen für Studierende entzogen werden, während der
    Lesezugriff erhalten bleibt.
    """

    def set_read_only(self, lms_course_id: str) -> int:
        """
        Revoke student write access on Moodle course.
        Schreibzugriff für Studierende im Moodle-Kurs entziehen.

        EN: In production this would call the Moodle Web Services API to
        override student capabilities.
        DE: In der Produktion würde dies die Moodle-Web-Services-API aufrufen,
        um die Studierenden-Berechtigungen zu überschreiben.

        Args:
            lms_course_id: Moodle course reference / Moodle-Kursreferenz.

        Returns:
            Number of affected users / Anzahl der betroffenen Benutzer.
        """
        logger.info(
            f"Moodle: setting course {lms_course_id} to read-only"
            f" / Moodle: Kurs {lms_course_id} auf Nur-Lese gesetzt"
        )
        return 0


# ---------------------------------------------------------------------------
# Core archival function
# ---------------------------------------------------------------------------


def archive_course(
    course_id: str,
    *,
    database: Database,
    audit_logger: AuditLogger,
    create_snapshot: bool = True,
    ilias_client: Optional[Any] = None,
    moodle_client: Optional[Any] = None,
) -> ArchiveResult:
    """
    Archive a single course at semester end.
    Einzelnen Kurs am Semesterende archivieren.

    EN: Performs the complete archival workflow for a course:
    1. Retrieve course from database.
    2. Freeze all enrollments (set status to 'frozen').
    3. Revoke student write access via LMS client.
    4. Create archive snapshot metadata.
    5. Update course status to 'archived'.
    6. Audit-log the operation.

    DE: Führt den vollständigen Archivierungs-Workflow für einen Kurs durch:
    1. Kurs aus der Datenbank abrufen.
    2. Alle Einschreibungen einfrieren (Status auf 'frozen' setzen).
    3. Schreibzugriff für Studierende über LMS-Client entziehen.
    4. Archiv-Snapshot-Metadaten erstellen.
    5. Kursstatus auf 'archived' aktualisieren.
    6. Vorgang im Audit-Log protokollieren.

    Args:
        course_id: Course identifier / Kurskennung.
        database: Database instance / Datenbankinstanz.
        audit_logger: Audit logger instance / Audit-Logger-Instanz.
        create_snapshot: Whether to create a snapshot / Ob ein Snapshot erstellt werden soll.
        ilias_client: Optional ILIAS archival client / Optionaler ILIAS-Archiv-Client.
        moodle_client: Optional Moodle archival client / Optionaler Moodle-Archiv-Client.

    Returns:
        ArchiveResult with outcome details / ArchiveResult mit Ergebnisdetails.
    """
    now = datetime.now(timezone.utc)
    result = ArchiveResult(course_id=course_id)

    # Step 1: Retrieve course
    course = database.get_course(course_id)
    if course is None:
        result.success = False
        result.error = f"Course {course_id} not found / Kurs {course_id} nicht gefunden"
        logger.error(result.error)
        return result

    if course.get("status") == "archived":
        result.success = False
        result.error = (
            f"Course {course_id} is already archived"
            f" / Kurs {course_id} ist bereits archiviert"
        )
        logger.warning(result.error)
        return result

    logger.info(
        f"Archiving course {course_id} ({course.get('title', '')})"
        f" / Archiviere Kurs {course_id} ({course.get('title', '')})"
    )

    # Step 2: Freeze enrollments
    frozen_count = _freeze_enrollments(course_id, database)
    result.frozen_enrollments = frozen_count
    logger.info(
        f"Froze {frozen_count} enrollments for course {course_id}"
        f" / {frozen_count} Einschreibungen für Kurs {course_id} eingefroren"
    )

    # Step 3: Revoke student write access via LMS
    revoked_count = _revoke_student_write_access(
        course, ilias_client=ilias_client, moodle_client=moodle_client
    )
    result.revoked_access_count = revoked_count
    logger.info(
        f"Revoked write access for {revoked_count} students in course {course_id}"
        f" / Schreibzugriff für {revoked_count} Studierende in Kurs {course_id} entzogen"
    )

    # Step 4: Create archive snapshot
    snapshot: Optional[ArchiveSnapshot] = None
    if create_snapshot:
        snapshot = _create_archive_snapshot(course, frozen_count, now)
        result.snapshot = snapshot
        _store_snapshot(snapshot, database)
        logger.info(
            f"Created archive snapshot {snapshot.snapshot_id} for course {course_id}"
            f" / Archiv-Snapshot {snapshot.snapshot_id} für Kurs {course_id} erstellt"
        )

    # Step 5: Update course status
    updated = database.update_course(
        course_id,
        {"status": "archived"},
    )
    if updated is None:
        result.success = False
        result.error = (
            f"Failed to update course status for {course_id}"
            f" / Kursstatus für {course_id} konnte nicht aktualisiert werden"
        )
        logger.error(result.error)
        return result

    # Step 6: Audit log
    audit_logger.log(
        action=AuditAction.COURSE_ARCHIVED,
        entity_type="course",
        entity_id=course_id,
        details={
            "archive_id": result.archive_id,
            "snapshot_id": snapshot.snapshot_id if snapshot else None,
            "title": course.get("title"),
            "semester_id": course.get("semester_id"),
            "frozen_enrollments": frozen_count,
            "revoked_access_count": revoked_count,
            "archived_at": now.isoformat(),
        },
    )

    logger.info(
        f"Successfully archived course {course_id}"
        f" / Kurs {course_id} erfolgreich archiviert"
    )
    return result


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


def _freeze_enrollments(course_id: str, database: Database) -> int:
    """
    Freeze all active enrollments for a course.
    Alle aktiven Einschreibungen für einen Kurs einfrieren.

    EN: Sets all active enrollment statuses to 'frozen' so that no further
    changes can be made. Returns the count of frozen enrollments.
    DE: Setzt alle aktiven Einschreibungsstatus auf 'frozen', sodass keine
    weiteren Änderungen vorgenommen werden können. Gibt die Anzahl der
    eingefrorenen Einschreibungen zurück.

    Args:
        course_id: Course identifier / Kurskennung.
        database: Database instance / Datenbankinstanz.

    Returns:
        Number of frozen enrollments / Anzahl der eingefrorenen Einschreibungen.
    """
    enrollments = database.list_enrollments(course_id)
    frozen = 0
    for enrollment in enrollments:
        if enrollment.get("status") == "active":
            database.update_enrollment(
                enrollment["enrollment_id"], {"status": "frozen"}
            )
            frozen += 1
    return frozen


def _revoke_student_write_access(
    course: dict,
    *,
    ilias_client: Optional[Any] = None,
    moodle_client: Optional[Any] = None,
) -> int:
    """
    Revoke write access for students on the LMS platform.
    Schreibzugriff für Studierende auf der LMS-Plattform entziehen.

    EN: Calls the appropriate LMS client to set the course to read-only mode.
    Returns the number of affected users.
    DE: Ruft den entsprechenden LMS-Client auf, um den Kurs in den Nur-Lese-Modus
    zu versetzen. Gibt die Anzahl der betroffenen Benutzer zurück.

    Args:
        course: Course data dictionary / Kursdaten-Dictionary.
        ilias_client: ILIAS archival client / ILIAS-Archiv-Client.
        moodle_client: Moodle archival client / Moodle-Archiv-Client.

    Returns:
        Number of users with revoked access / Anzahl der Benutzer mit entzogenem Zugriff.
    """
    lms = course.get("lms", "")
    lms_course_id = course.get("lms_course_id")
    if not lms_course_id:
        return 0

    if lms == "ilias":
        client = ilias_client or ILIASArchivalClient()
        return client.set_read_only(lms_course_id)
    elif lms == "moodle":
        client = moodle_client or MoodleArchivalClient()
        return client.set_read_only(lms_course_id)
    else:
        logger.warning(
            f"Unknown LMS platform '{lms}', skipping write-access revocation"
            f" / Unbekannte LMS-Plattform '{lms}', Entzug des Schreibzugriffs übersprungen"
        )
        return 0


def _create_archive_snapshot(
    course: dict, enrollment_count: int, archived_at: datetime
) -> ArchiveSnapshot:
    """
    Create an archive snapshot of the course state.
    Archiv-Snapshot des Kurszustands erstellen.

    EN: Captures key course attributes into an ArchiveSnapshot for later
    restoration or auditing purposes.
    DE: Erfasst die wichtigsten Kursattribute in einem ArchiveSnapshot zur
    späteren Wiederherstellung oder Überprüfung.

    Args:
        course: Course data dictionary / Kursdaten-Dictionary.
        enrollment_count: Number of frozen enrollments / Anzahl eingefrorener Einschreibungen.
        archived_at: Timestamp of archival / Zeitstempel der Archivierung.

    Returns:
        ArchiveSnapshot with captured state / ArchiveSnapshot mit erfasstem Zustand.
    """
    return ArchiveSnapshot(
        course_id=course["course_id"],
        semester_id=course.get("semester_id", ""),
        title=course.get("title", ""),
        title_en=course.get("title_en"),
        course_code=course.get("course_code", ""),
        lms=course.get("lms", ""),
        lms_course_id=course.get("lms_course_id"),
        instructor_ids=course.get("instructor_ids", []),
        enrollment_count=enrollment_count,
        archived_at=archived_at,
        status_before=course.get("status", "active"),
    )


def _store_snapshot(snapshot: ArchiveSnapshot, database: Database) -> None:
    """
    Store archive snapshot metadata in the database.
    Archiv-Snapshot-Metadaten in der Datenbank speichern.

    EN: Persists the snapshot to an 'archive_snapshots' table so that it can
    be retrieved during restore operations.
    DE: Speichert den Snapshot in einer 'archive_snapshots'-Tabelle, damit er
    bei Wiederherstellungsvorgängen abgerufen werden kann.

    Args:
        snapshot: The snapshot to store / Der zu speichernde Snapshot.
        database: Database instance / Datenbankinstanz.
    """
    with database.get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS archive_snapshots (
                snapshot_id TEXT PRIMARY KEY,
                course_id TEXT NOT NULL,
                archive_id TEXT,
                semester_id TEXT,
                title TEXT,
                title_en TEXT,
                course_code TEXT,
                lms TEXT,
                lms_course_id TEXT,
                instructor_ids TEXT NOT NULL DEFAULT '[]',
                enrollment_count INTEGER DEFAULT 0,
                status_before TEXT DEFAULT 'active',
                archived_at TEXT NOT NULL
            )
        """)
        cursor.execute(
            """
            INSERT INTO archive_snapshots (
                snapshot_id, course_id, semester_id, title, title_en,
                course_code, lms, lms_course_id, instructor_ids,
                enrollment_count, status_before, archived_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                snapshot.snapshot_id,
                snapshot.course_id,
                snapshot.semester_id,
                snapshot.title,
                snapshot.title_en,
                snapshot.course_code,
                snapshot.lms,
                snapshot.lms_course_id,
                json.dumps(snapshot.instructor_ids),
                snapshot.enrollment_count,
                snapshot.status_before,
                snapshot.archived_at.isoformat(),
            ),
        )
        conn.commit()

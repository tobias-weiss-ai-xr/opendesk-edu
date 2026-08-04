# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Semester Lifecycle Manager - Central orchestrator for semester transitions.
Semester-Lebenszyklus-Manager - Zentraler Orchestrator für Semesterübergänge.

EN: This module provides the SemesterManager class that coordinates semester transitions,
manages semester configuration, and triggers automated workflows for the Semester Lifecycle Management feature.

DE: Dieses Modul bietet die SemesterManager-Klasse, die Semesterübergänge koordiniert, die Semesterkonfiguration verwaltet
und automatisierte Workflows für das Semester Lifecycle Management Feature auslöst.
"""

from __future__ import annotations

import logging
from datetime import date, datetime, timezone
from typing import Any, Optional

from pydantic import BaseModel

from audit import AuditAction
from config import (
    CurrentSemesterConfig,
    load_semester_config,
    SemesterPhase,
)

# Configure logging
logger = logging.getLogger(__name__)


class TransitionReport(BaseModel):
    """
    Report of a semester transition operation.
    Bericht einer Semesterübergang-Operation.

    EN: Contains details about courses archived, created, and synced during a transition.
    DE: Enthält Details über archivierte, erstellte und synchronisierte Kurse während eines Übergangs.
    """

    old_semester: str
    new_semester: str
    transitioned_at: datetime
    archived_courses: list[str] = []
    created_courses: list[str] = []
    synced_enrollments: int = 0
    errors: list[dict] = []
    success: bool = True


class SemesterManager:
    """
    Central orchestrator for semester lifecycle management.
    Zentraler Orchestrator für das Semester-Lebenszyklus-Management.

    EN: The SemesterManager class provides methods to detect the current semester,
    load semester configuration, execute semester transitions, and determine the current phase of a semester.

    DE: Die SemesterManager-Klasse bietet Methoden zum Erkennen des aktuellen Semesters,
    Laden der Semesterkonfiguration, Ausführen von Semesterübergängen und Bestimmen der aktuellen Phase eines Semesters.
    """

    def __init__(
        self,
        config_path: Optional[str] = None,
        database: Optional[Any] = None,
        course_api: Optional[Any] = None,
        role_sync: Optional[Any] = None,
    ) -> None:
        """
        Initialize the SemesterManager.
        Initialisiert den SemesterManager.

        EN: Creates a new SemesterManager instance with optional dependencies for database,
        course API, and role synchronization.

        DE: Erstellt eine neue SemesterManager-Instanz mit optionalen Abhängigkeiten für Datenbank,
        Kurs-API und Rollensynchronisierung.

        Args:
            config_path: Path to semester configuration YAML file.
                           Pfad zur Semester-Konfigurations-YAML-Datei.
            database: Database instance for persistent storage.
                          Datenbankinstanz für persistente Speicherung.
            course_api: Course API instance for course operations.
                         Kurs-API-Instanz für Kursoperationen.
            role_sync: Role synchronization engine instance.
                        Rollensynchronisierungs-Engine-Instanz.
        """
        self._config_path = config_path
        self._database = database
        self._course_api = course_api
        self._role_sync = role_sync

        # Load configuration
        try:
            self._config = load_semester_config(config_path)
            logger.info(
                f"Loaded semester configuration for {self._config.current.name}"
                f" / Semester-Konfiguration für {self._config.current.name} geladen"
            )
        except FileNotFoundError:
            logger.warning(
                "Semester configuration file not found, using defaults"
                " / Semester-Konfigurationsdatei nicht gefunden, verwende Standardeinstellungen"
            )
            self._config = None

    def get_current_semester(
        self, check_date: Optional[date] = None
    ) -> Optional[CurrentSemesterConfig]:
        """
        Detect the current semester based on date and configuration.
        Erkenne das aktuelle Semester basierend auf Datum und Konfiguration.

        EN: Determines which semester is currently active based on the provided date.
        If no date is provided, uses today's date. Returns None if no configuration is loaded.

        DE: Bestimmt, welches Semester basierend auf dem angegebenen Datum aktuell aktiv ist.
        Wenn kein Datum angegeben wird, wird das heutige Datum verwendet. Gibt None zurück, wenn keine Konfiguration geladen ist.

        Args:
            check_date: Date to check against semester boundaries.
                          Datum zum Prüfen gegen Semester-Grenzen.

        Returns:
            CurrentSemesterConfig if found, None otherwise.
            CurrentSemesterConfig wenn gefunden, sonst None.
        """
        if self._config is None:
            logger.warning(
                "No semester configuration loaded / Keine Semester-Konfiguration geladen"
            )
            return None

        if check_date is None:
            check_date = date.today()

        current = self._config.current

        # Parse semester dates
        start_date = current.get_start_date()
        end_date = current.get_end_date()

        # Check if the date falls within the semester
        if start_date <= check_date <= end_date:
            logger.debug(
                f"Current semester detected: {current.name}"
                f" / Aktuelles Semester erkannt: {current.name}"
            )
            return current

        logger.debug(
            f"Date {check_date} is outside current semester {current.name}"
            f" / Datum {check_date} liegt außerhalb des aktuellen Semesters {current.name}"
        )
        return None

    def get_semester_config(
        self, semester_name: str
    ) -> Optional[CurrentSemesterConfig]:
        """
        Load and validate semester configuration by name.
        Semester-Konfiguration nach Namen laden und validieren.

        EN: Retrieves the configuration for a specific semester. If the requested semester
        matches the current configured semester, returns that configuration.

        DE: Ruft die Konfiguration für ein bestimmtes Semester ab. Wenn das angefordene Semester
        mit dem aktuell konfigurierten Semester übereinstimmt, wird diese Konfiguration zurückgegeben.

        Args:
            semester_name: Name of the semester (e.g., "WS25/26").
                           Name des Semesters (z.B., "WS25/26").

        Returns:
            CurrentSemesterConfig if found, None otherwise.
            CurrentSemesterConfig wenn gefunden, sonst None.
        """
        if self._config is None:
            logger.warning(
                "No semester configuration loaded / Keine Semester-Konfiguration geladen"
            )
            return None

        if self._config.current.name == semester_name:
            return self._config.current

        logger.debug(
            f"Semester {semester_name} not found in configuration"
            f" / Semester {semester_name} nicht in Konfiguration gefunden"
        )
        return None

    def get_semester_phase(
        self, check_date: Optional[date] = None, semester_name: Optional[str] = None
    ) -> Optional[SemesterPhase]:
        """
        Determine which phase a date falls into.
        Bestimmen, in welche Phase ein Datum fällt.

        EN: Determines the semester phase (enrollment/teaching/exam/archival) for a given date.
        If no date is provided, uses today's date.

        DE: Bestimmt die Semester-Phase (enrollment/teaching/exam/archival) für ein gegebenes Datum.
        Wenn kein Datum angegeben wird, wird das heutige Datum verwendet.

        Args:
            check_date: Date to check. If None, uses today.
                          Zu prüfendes Datum. Wenn None, wird heute verwendet.
            semester_name: Specific semester to check. If None, uses current.
                           Bestimmtes Semester zum Prüfen. Wenn None, wird das aktuelle verwendet.

        Returns:
            SemesterPhase enum value for the current phase.
            SemesterPhase-Enum-Wert für die aktuelle Phase.
        """
        if check_date is None:
            check_date = date.today()

        # Get semester config
        if semester_name:
            config = self.get_semester_config(semester_name)
        elif self._config is not None:
            config = self._config.current
        else:
            config = None

        if config is None:
            logger.warning(
                f"Cannot determine phase: no configuration for {semester_name or 'current semester'}"
                f" / Kann Phase nicht bestimmen: keine Konfiguration für {semester_name or 'aktuelles Semester'}"
            )
            return None

        phases = config.phases

        # Enrollment phase (may start before semester start_date)
        enrollment_start = phases.enrollment.get_start_date()
        enrollment_end = phases.enrollment.get_end_date()
        if enrollment_start <= check_date <= enrollment_end:
            return SemesterPhase.ENROLLMENT

        # Teaching phase
        teaching_start = phases.teaching.get_start_date()
        teaching_end = phases.teaching.get_end_date()
        if teaching_start <= check_date <= teaching_end:
            return SemesterPhase.TEACHING

        # Exam phase
        exam_start = phases.exam.get_start_date()
        exam_end = phases.exam.get_end_date()
        if exam_start <= check_date <= exam_end:
            return SemesterPhase.EXAM

        # Archival phase (after exam end)
        if check_date > exam_end:
            return SemesterPhase.ARCHIVAL

        # Between phases (gap)
        return None

    def transition_semester(
        self, old_semester: str, new_semester: str, dry_run: bool = False
    ) -> TransitionReport:
        """
        Execute full semester transition workflow.
        Vollständigen Semesterübergang-Workflow ausführen.

        EN: Executes the complete semester transition workflow:
        1. Archive all active courses from old semester
        2. Create new semester configuration
        3. Provision new courses (if automated provisioning enabled)
        4. Sync enrollments from campus management
        5. Activate new semester courses

        DE: Führt den vollständigen Semesterübergang-Workflow aus:
        1. Alle aktiven Kurse des alten Semesters archivieren
        2. Neue Semesterkonfiguration erstellen
        3. Neue Kurse bereitstellen (wenn automatisierte Bereitstellung aktiviert)
        4. Einschreibungen aus dem Campus-Management synchronisieren
        5. Kurse des neuen Semesters aktivieren

        Args:
            old_semester: Previous semester identifier (e.g., "WS24/25").
                           Vorheriger Semester-Bezeichner (z.B., "WS24/25").
            new_semester: New semester identifier (e.g., "WS25/26").
                            Neue Semester-Bezeichner (z.B., "WS25/26").
            dry_run: If True, simulate the transition without making changes.
                          Wenn True, simulieren Sie Übergang ohne Änderungen vor vorzunehmen.

        Returns:
            TransitionReport with details of the operation.
            TransitionReport mit Details der Operation.
        """
        transitioned_at = datetime.now(timezone.utc)

        report = TransitionReport(
            old_semester=old_semester,
            new_semester=new_semester,
            transitioned_at=transitioned_at,
            archived_courses=[],
            created_courses=[],
            synced_enrollments=0,
            errors=[],
            success=True,
        )

        if dry_run:
            logger.info(
                f"DRY RUN: Would transition from {old_semester} to {new_semester}"
                f" / DRY RUN: Würde von {old_semester} zu {new_semester} übergehen"
            )
            return report

        logger.info(
            f"Starting semester transition: {old_semester} -> {new_semester}"
            f" / Starte Semesterübergang: {old_semester} -> {new_semester}"
        )

        # Step 1: Archive old semester courses
        if self._course_api is not None:
            try:
                archived_ids = self._archive_semester_courses(old_semester)
                report.archived_courses = archived_ids
                logger.info(
                    f"Archived {len(archived_ids)} courses from {old_semester}"
                    f" / {len(archived_ids)} Kurse aus {old_semester} archiviert"
                )
            except Exception as e:
                error_msg = f"Failed to archive courses from {old_semester}: {e}"
                logger.error(error_msg)
                report.errors.append({"step": "archive_courses", "error": str(e)})
                report.success = False

        # Step 2: Create new semester configuration
        # This would typically involve updating the config file or database
        # For now, we log the intent
        logger.info(
            f"Would create configuration for semester: {new_semester}"
            f" / Würde Konfiguration für Semester erstellen: {new_semester}"
        )

        # Step 3: Provision new courses (if automated)
        if self._config and self._config.provisioning.auto_archive:
            logger.info(
                f"Would provision courses for {new_semester}"
                f" / Würde Kurse für {new_semester} bereitstellen"
            )
            # Placeholder for actual provisioning logic
            # This would integrate with HISinOne or similar systems

        # Step 4: Sync enrollments
        if self._role_sync is not None:
            try:
                # Placeholder for enrollment sync
                synced = 0  # self._sync_enrollments(new_semester)
                report.synced_enrollments = synced
                logger.info(
                    f"Would sync enrollments for {new_semester}"
                    f" / Würde Einschreibungen für {new_semester} synchronisieren"
                )
            except Exception as e:
                error_msg = f"Failed to sync enrollments for {new_semester}: {e}"
                logger.error(error_msg)
                report.errors.append({"step": "sync_enrollments", "error": str(e)})

        # Step 5: Activate new courses
        if self._course_api is not None:
            try:
                # Placeholder for activating courses
                logger.info(
                    f"Would activate courses for {new_semester}"
                    f" / Würde Kurse für {new_semester} aktivieren"
                )
            except Exception as e:
                error_msg = f"Failed to activate courses for {new_semester}: {e}"
                logger.error(error_msg)
                report.errors.append({"step": "activate_courses", "error": str(e)})
                report.success = False

        if report.errors:
            report.success = False

        logger.info(
            f"Semester transition completed: {old_semester} -> {new_semester} (success={report.success})"
            f" / Semesterübergang abgeschlossen: {old_semester} -> {new_semester} (erfolg={report.success})"
        )

        return report

    def _archive_semester_courses(self, semester_name: str) -> list[str]:
        """
        Archive all active courses for a semester.
        Alle aktiven Kurse eines Semesters archivieren.

        EN: Internal method to archive all active courses for a given semester.
        Returns list of archived course IDs.

        DE: Interne Methode zum Archivieren aller aktiven Kurse für ein bestimmtes Semester.
        Gibt Liste der archivierten Kurs-IDs zurück.

        Args:
            semester_name: Name of the semester.
                           Name des Semesters.

        Returns:
            List of archived course IDs.
            Liste der archivierten Kurs-IDs.
        """
        archived_ids = []
        failed_ids = []

        if self._database is None:
            logger.debug("No database connection, skipping archival")
            return archived_ids

        # Query all active courses for this semester
        courses, total = self._database.list_courses(
            semester_id=self._config.semester_id,
            status="active",
        )

        logger.info(
            f"Archiving {total} active courses for semester "
            f"'{semester_name}' / Archiviere {total} aktive Kurse "
            f"für Semester '{semester_name}'"
        )

        for course in courses:
            course_id = course.get("course_id", "")
            course_title = course.get("title", course_id)
            try:
                result = self._database.archive_course(course_id)
                if result is not None:
                    archived_ids.append(course_id)
                    self._audit_logger.log(
                        AuditAction.COURSE_ARCHIVED,
                        entity_type="course",
                        entity_id=course_id,
                        details={"title": course_title, "semester": semester_name},
                    )
                    logger.debug(
                        f"Archived course '{course_title}' ({course_id}) / "
                        f"Kurs '{course_title}' ({course_id}) archiviert"
                    )
                else:
                    logger.warning(
                        f"Course '{course_id}' could not be archived "
                        f"(not in active status) / Kurs '{course_id}' konnte "
                        f"nicht archiviert (nicht aktiv)"
                    )
                    failed_ids.append(course_id)
            except Exception as e:
                logger.error(
                    f"Failed to archive course '{course_id}': {e} / "
                    f"Fehler beim Archivieren des Kurses '{course_id}': {e}"
                )
                failed_ids.append(course_id)

        logger.info(
            f"Archive complete: {len(archived_ids)} archived, "
            f"{len(failed_ids)} failed / Archivierung abgeschlossen: "
            f"{len(archived_ids)} archiviert, {len(failed_ids)} fehlgeschlagen"
        )

        return archived_ids

    def get_all_phases(
        self, semester_name: Optional[str] = None
    ) -> dict[str, dict[str, str]]:
        """
        Get all semester phases with their date ranges.
        Alle Semester-Phasen mit ihren Datumsbereichen abrufen.

        EN: Returns a dictionary of all phases with their start and end dates.
        If no semester name is provided, uses the current semester.

        DE: Gibt ein Dictionary aller Phasen mit ihren Start- und Enddaten zurück.
        Wenn kein Semester-Name angegeben wird, wird das aktuelle Semester verwendet.

        Args:
            semester_name: Name of the semester. If None, uses current.
                           Name des Semesters. Wenn None, wird das aktuelle verwendet.

        Returns:
            Dictionary mapping phase names to date ranges.
            Dictionary, das Phasennamen auf Datumsbereiche abbildet.
        """
        if semester_name:
            config = self.get_semester_config(semester_name)
        else:
            if self._config is None:
                return {}
            config = self._config.current

        if config is None:
            return {}

        phases = config.phases

        return {
            "enrollment": {
                "start": phases.enrollment.start,
                "end": phases.enrollment.end,
            },
            "teaching": {
                "start": phases.teaching.start,
                "end": phases.teaching.end,
            },
            "exam": {
                "start": phases.exam.start,
                "end": phases.exam.end,
            },
            "archival": {
                "deadline": phases.archival.deadline,
            },
        }

    def to_dict(self) -> dict[str, Any]:
        """
        Convert manager state to dictionary for serialization.
        Manager-Zustand in Dictionary für Serialisierung konvertieren.

        EN: Returns a dictionary representation of the manager's current state.
        DE: Gibt eine Dictionary-Darstellung des aktuellen Zustands des Managers zurück.

        Returns:
            Dictionary with manager state.
            Dictionary mit Manager-Zustand.
        """
        if self._config is None:
            return {"status": "no_configuration"}

        current = self.get_current_semester()
        phase = self.get_semester_phase()

        return {
            "status": "configured",
            "current_semester": current.name if current else None,
            "current_phase": phase.value if phase else None,
            "semester_type": current.type.value if current else None,
            "automation_enabled": self._config.automation.enabled
            if self._config
            else False,
        }


# Module-level convenience functions
def get_manager(
    config_path: Optional[str] = None,
    database: Optional[Any] = None,
    course_api: Optional[Any] = None,
    role_sync: Optional[Any] = None,
) -> SemesterManager:
    """
    Get or create a SemesterManager instance.
    SemesterManager-Instanz abrufen oder erstellen.

    EN: Factory function to create a SemesterManager with optional dependencies.
    DE: Factory-Funktion zum Erstellen eines SemesterManagers mit optionalen Abhängigkeiten.

    Args:
        config_path: Path to configuration file.
                      Pfad zur Konfigurationsdatei.
        database: Database instance.
                      Datenbankinstanz.
        course_api: Course API instance.
                      Kurs-API-Instanz.
        role_sync: Role sync engine instance.
                      Rollensynchronisierungs-Engine-Instanz.

    Returns:
        SemesterManager instance.
        SemesterManager-Instanz.
    """
    return SemesterManager(
        config_path=config_path,
        database=database,
        course_api=course_api,
        role_sync=role_sync,
    )

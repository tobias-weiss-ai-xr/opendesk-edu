# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Archival models for the Course Provisioning API.
Archivierungsmodelle für die Kursverwaltungs-API.

This module defines Pydantic models for course archival operations
including single and bulk archival, as well as restore operations.
"""

from datetime import datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class ArchiveStatus(str, Enum):
    """
    Status of an archive operation.
    Status einer Archivierung.
    """

    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"


class ArchiveRequest(BaseModel):
    """
    Request model for archiving a course.
    Anforderungsmodell für die Archivierung eines Kurses.
    """

    model_config = ConfigDict(str_strip_whitespace=True)

    course_id: Optional[str] = Field(
        None,
        min_length=1,
        max_length=100,
        description="Course ID to archive / Zu archivierende Kurskennung",
    )
    reason: Optional[str] = Field(
        None,
        max_length=500,
        description="Reason for archival / Grund für die Archivierung",
    )
    create_snapshot: bool = Field(
        default=True,
        description="Whether to create a backup snapshot / Ob ein Backup-Snapshot erstellt werden soll",
    )
    dry_run: bool = Field(
        default=False,
        description="Preview changes without executing / Änderungen ohne Ausführung anzeigen",
    )


class BulkArchiveRequest(BaseModel):
    """
    Request model for bulk archiving courses.
    Anforderungsmodell für die Massenarchivierung von Kursen.
    """

    model_config = ConfigDict(str_strip_whitespace=True)

    semester_id: Optional[str] = Field(
        None,
        max_length=50,
        description="Archive all courses in this semester / Alle Kurse in diesem Semester archivieren",
    )
    course_ids: Optional[list[str]] = Field(
        None,
        max_length=1000,
        description="Specific course IDs to archive / Spezifische zu archivierende Kurskennungen",
    )
    reason: Optional[str] = Field(
        None,
        max_length=500,
        description="Reason for bulk archival / Grund für die Massenarchivierung",
    )
    create_snapshots: bool = Field(
        default=True,
        description="Whether to create backup snapshots / Ob Backup-Snapshots erstellt werden sollen",
    )
    dry_run: bool = Field(
        default=False,
        description="Preview changes without executing / Änderungen ohne Ausführung anzeigen",
    )


class ArchiveResult(BaseModel):
    """
    Result of a single archive operation.
    Ergebnis einer einzelnen Archivierung.
    """

    course_id: str = Field(
        ..., description="Archived course ID / Archivierte Kurskennung"
    )
    status: ArchiveStatus = Field(
        ..., description="Archive operation status / Status der Archivierung"
    )
    archive_id: Optional[str] = Field(
        None, description="Archive reference ID / Archiv-Referenzkennung"
    )
    snapshot_id: Optional[str] = Field(
        None, description="Backup snapshot ID / Backup-Snapshot-Kennung"
    )
    archived_at: Optional[datetime] = Field(
        None, description="Archive timestamp / Archivierungszeitstempel"
    )
    error: Optional[str] = Field(
        None, description="Error message if failed / Fehlermeldung bei Fehlschlag"
    )


class BulkArchiveResult(BaseModel):
    """
    Result of a bulk archive operation.
    Ergebnis einer Massenarchivierung.
    """

    job_id: str = Field(
        ..., description="Bulk job identifier / Massenverarbeitungskennung"
    )
    status: ArchiveStatus = Field(
        ..., description="Overall job status / Gesamtstatus des Auftrags"
    )
    total_courses: int = Field(
        ...,
        ge=0,
        description="Total courses to process / Gesamtzahl der zu verarbeitenden Kurse",
    )
    completed: int = Field(
        default=0, ge=0, description="Successfully archived / Erfolgreich archiviert"
    )
    failed: int = Field(
        default=0,
        ge=0,
        description="Failed to archive / Fehlgeschlagene Archivierungen",
    )
    results: list[ArchiveResult] = Field(
        default_factory=list,
        description="Individual course results / Einzelne Kursergebnisse",
    )
    started_at: datetime = Field(
        ..., description="Job start timestamp / Startzeitstempel des Auftrags"
    )
    completed_at: Optional[datetime] = Field(
        None, description="Job completion timestamp / Abschlusszeitstempel des Auftrags"
    )


class RestoreRequest(BaseModel):
    """
    Request model for restoring an archived course.
    Anforderungsmodell für die Wiederherstellung eines archivierten Kurses.
    """

    model_config = ConfigDict(str_strip_whitespace=True)

    archive_id: Optional[str] = Field(
        None,
        min_length=1,
        max_length=100,
        description="Archive ID to restore / Zu wiederherstellende Archivkennung",
    )
    target_semester_id: Optional[str] = Field(
        None,
        max_length=50,
        description="Target semester for restored course / Zielsemester für wiederhergestellten Kurs",
    )
    new_title: Optional[str] = Field(
        None,
        max_length=255,
        description="New title for restored course / Neuer Titel für wiederhergestellten Kurs",
    )
    restore_enrollments: bool = Field(
        default=False,
        description="Whether to restore enrollments / Ob Einschreibungen wiederhergestellt werden sollen",
    )


class RestoreResult(BaseModel):
    """
    Result of a restore operation.
    Ergebnis einer Wiederherstellung.
    """

    archive_id: str = Field(..., description="Source archive ID / Quell-Archivkennung")
    new_course_id: Optional[str] = Field(
        None, description="New course ID created / Erstellte neue Kurskennung"
    )
    status: ArchiveStatus = Field(
        ..., description="Restore operation status / Status der Wiederherstellung"
    )
    restored_at: Optional[datetime] = Field(
        None, description="Restore timestamp / Wiederherstellungszeitstempel"
    )
    enrollments_restored: int = Field(
        default=0,
        ge=0,
        description="Number of enrollments restored / Anzahl wiederhergestellter Einschreibungen",
    )
    error: Optional[str] = Field(
        None, description="Error message if failed / Fehlermeldung bei Fehlschlag"
    )


class ArchiveInfo(BaseModel):
    """
    Information about an archived course.
    Informationen über einen archivierten Kurs.
    """

    archive_id: str = Field(
        ..., description="Unique archive identifier / Eindeutige Archivkennung"
    )
    course_id: str = Field(
        ..., description="Original course ID / Ursprüngliche Kurskennung"
    )
    title: str = Field(
        ...,
        description="Course title at time of archival / Kurstitel zum Zeitpunkt der Archivierung",
    )
    semester_id: str = Field(..., description="Semester ID / Semesterkennung")
    archived_at: datetime = Field(
        ..., description="Archive timestamp / Archivierungszeitstempel"
    )
    snapshot_id: Optional[str] = Field(
        None, description="Backup snapshot ID / Backup-Snapshot-Kennung"
    )
    enrollment_count: int = Field(
        default=0,
        ge=0,
        description="Number of archived enrollments / Anzahl archivierter Einschreibungen",
    )


class ArchiveList(BaseModel):
    """
    Paginated list of archives.
    Paginierte Liste von Archiven.
    """

    archives: list[ArchiveInfo] = Field(
        default_factory=list, description="List of archives / Liste der Archive"
    )
    total: int = Field(
        ..., ge=0, description="Total number of archives / Gesamtzahl der Archive"
    )
    page: int = Field(
        ..., ge=1, description="Current page number / Aktuelle Seitennummer"
    )
    page_size: int = Field(
        ..., ge=1, le=100, description="Items per page / Einträge pro Seite"
    )


class ErrorResponse(BaseModel):
    """
    Standard error response model.
    Standard-Fehlerantwortmodell.
    """

    error: str = Field(..., description="Error type / Fehlertyp")
    detail: str = Field(
        ..., description="Detailed error message / Detaillierte Fehlermeldung"
    )
    code: Optional[str] = Field(None, description="Error code / Fehlercode")

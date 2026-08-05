# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Enrollment models for the Course Provisioning API.
Einschreibungsmodelle für die Kursverwaltungs-API.

This module defines Pydantic models for enrollment management operations
including adding, removing, and bulk syncing enrollments.
"""

from datetime import datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class EnrollmentRole(str, Enum):
    """
    Role types for course enrollments.
    Rollentypen für Kurseinschreibungen.
    """

    STUDENT = "student"
    INSTRUCTOR = "instructor"
    TUTOR = "tutor"


class EnrollmentStatus(str, Enum):
    """
    Status of an enrollment.
    Status einer Einschreibung.
    """

    ACTIVE = "active"
    WITHDRAWN = "withdrawn"
    COMPLETED = "completed"
    ARCHIVED = "archived"


class EnrollmentBase(BaseModel):
    """
    Base model for enrollment data.
    Basismodell für Einschreibungsdaten.
    """

    model_config = ConfigDict(str_strip_whitespace=True)

    user_id: str = Field(
        ...,
        min_length=1,
        max_length=255,
        description="Unique user identifier / Eindeutige Benutzerkennung",
    )
    role: EnrollmentRole = Field(
        default=EnrollmentRole.STUDENT,
        description="User role in the course (student, instructor, tutor) / Benutzerrolle im Kurs",
    )


class EnrollmentCreate(EnrollmentBase):
    """
    Model for creating a new enrollment.
    Modell für die Erstellung einer neuen Einschreibung.
    """

    pass


class EnrollmentBulkCreate(BaseModel):
    """
    Model for bulk creating enrollments.
    Modell für die Massenerstellung von Einschreibungen.
    """

    enrollments: list[EnrollmentCreate] = Field(
        ...,
        min_length=1,
        max_length=1000,
        description="List of enrollments to create / Liste der zu erstellenden Einschreibungen",
    )


class EnrollmentRemove(BaseModel):
    """
    Model for removing an enrollment.
    Modell für das Entfernen einer Einschreibung.
    """

    model_config = ConfigDict(str_strip_whitespace=True)

    user_id: str = Field(
        ...,
        min_length=1,
        max_length=255,
        description="User ID to remove / Zu entfernende Benutzerkennung",
    )
    reason: Optional[str] = Field(
        None,
        max_length=500,
        description="Reason for removal / Grund für die Entfernung",
    )


class EnrollmentBulkRemove(BaseModel):
    """
    Model for bulk removing enrollments.
    Modell für das Massenentfernen von Einschreibungen.
    """

    user_ids: list[str] = Field(
        ...,
        min_length=1,
        max_length=1000,
        description="List of user IDs to remove / Liste der zu entfernenden Benutzerkennungen",
    )
    reason: Optional[str] = Field(
        None,
        max_length=500,
        description="Reason for bulk removal / Grund für die Massenentfernung",
    )


class Enrollment(EnrollmentBase):
    """
    Full enrollment model with all fields.
    Vollständiges Einschreibungsmodell mit allen Feldern.
    """

    enrollment_id: str = Field(
        ...,
        description="Unique enrollment identifier / Eindeutige Einschreibungskennung",
    )
    course_id: str = Field(..., description="Course identifier / Kurskennung")
    status: EnrollmentStatus = Field(
        default=EnrollmentStatus.ACTIVE,
        description="Current enrollment status / Aktueller Einschreibungsstatus",
    )
    created_at: datetime = Field(
        ..., description="Creation timestamp / Erstellungszeitstempel"
    )
    updated_at: Optional[datetime] = Field(
        None,
        description="Last update timestamp / Zeitstempel der letzten Aktualisierung",
    )


class EnrollmentList(BaseModel):
    """
    Paginated list of enrollments.
    Paginierte Liste von Einschreibungen.
    """

    enrollments: list[Enrollment] = Field(
        default_factory=list,
        description="List of enrollments / Liste der Einschreibungen",
    )
    total: int = Field(
        ...,
        ge=0,
        description="Total number of enrollments / Gesamtzahl der Einschreibungen",
    )
    page: int = Field(
        ..., ge=1, description="Current page number / Aktuelle Seitennummer"
    )
    page_size: int = Field(
        ..., ge=1, le=100, description="Items per page / Einträge pro Seite"
    )


class EnrollmentSyncResult(BaseModel):
    """
    Result of an enrollment sync operation.
    Ergebnis einer Einschreibungssynchronisation.
    """

    added: int = Field(
        default=0,
        ge=0,
        description="Number of enrollments added / Anzahl hinzugefügter Einschreibungen",
    )
    removed: int = Field(
        default=0,
        ge=0,
        description="Number of enrollments removed / Anzahl entfernter Einschreibungen",
    )
    unchanged: int = Field(
        default=0,
        ge=0,
        description="Number of unchanged enrollments / Anzahl unveränderter Einschreibungen",
    )
    errors: list[str] = Field(
        default_factory=list,
        description="List of error messages / Liste der Fehlermeldungen",
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

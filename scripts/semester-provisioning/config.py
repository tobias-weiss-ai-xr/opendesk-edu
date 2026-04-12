# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Configuration loading for course provisioning and semester lifecycle management.
Konfigurationsladem für die Kursverwaltung und Semester-Lebenszyklusverwaltung.

This module provides configuration management for the course provisioning API,
semester lifecycle management, loading settings from environment variables,
config files (YAML), and providing Pydantic validation.
"""

from __future__ import annotations

from datetime import date, datetime
from enum import Enum
from functools import lru_cache
from pathlib import Path
from typing import Optional

import yaml
from pydantic import BaseModel, Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class SemesterType(str, Enum):
    """
    Semester type enumeration.
    Semester-Typ-Enumeration.
    """

    WINTERSEMESTER = "wintersemester"
    SOMMERSEMESTER = "sommersemester"


class SemesterPhase(str, Enum):
    """
    Semester phase enumeration.
    Semester-Phase-Enumeration.
    """

    ENROLLMENT = "enrollment"
    TEACHING = "teaching"
    EXAM = "exam"
    ARCHIVAL = "archival"


class PhaseDates(BaseModel):
    """
    Phase date configuration.
    Phasen-Datum-Konfiguration.

    EN: Defines start and end dates for a semester phase.
    DE: Definiert Start- und Enddaten für eine Semester-Phase.
    """

    start: str = Field(
        ..., description="Phase start date (YYYY-MM-DD) / Phasen-Startdatum"
    )
    end: str = Field(..., description="Phase end date (YYYY-MM-DD) / Phasen-Enddatum")

    @field_validator("start", "end")
    @classmethod
    def validate_date_format(cls, v: str) -> str:
        """Validate date format is YYYY-MM-DD."""
        try:
            datetime.strptime(v, "%Y-%m-%d")
        except ValueError:
            raise ValueError(f"Invalid date format: {v}. Expected YYYY-MM-DD")
        return v

    def get_start_date(self) -> date:
        """Get start date as date object / Startdatum als date-Objekt."""
        return datetime.strptime(self.start, "%Y-%m-%d").date()

    def get_end_date(self) -> date:
        """Get end date as date object / Enddatum als date-Objekt."""
        return datetime.strptime(self.end, "%Y-%m-%d").date()


class ArchivalPhaseConfig(BaseModel):
    """
    Archival phase configuration.
    Archivierungsphasen-Konfiguration.

    EN: Configuration for the archival phase, including deadline.
    DE: Konfiguration für die Archivierungsphase, einschließlich Deadline.
    """

    deadline: str = Field(
        ..., description="Archival deadline (YYYY-MM-DD) / Archivierungs-Deadline"
    )

    @field_validator("deadline")
    @classmethod
    def validate_deadline(cls, v: str) -> str:
        """Validate deadline date format."""
        try:
            datetime.strptime(v, "%Y-%m-%d")
        except ValueError:
            raise ValueError(f"Invalid date format: {v}. Expected YYYY-MM-DD")
        return v

    def get_deadline_date(self) -> date:
        """Get deadline as date object / Deadline als date-Objekt."""
        return datetime.strptime(self.deadline, "%Y-%m-%d").date()


class SemesterPhases(BaseModel):
    """
    All semester phases configuration.
    Alle Semester-Phasen-Konfiguration.

    EN: Defines all phases of a semester with their date ranges.
    DE: Definiert alle Phasen eines Semesters mit ihren Datumsbereichen.
    """

    enrollment: PhaseDates = Field(
        ..., description="Enrollment phase / Einschreibungsphase"
    )
    teaching: PhaseDates = Field(..., description="Teaching phase / Lehrphase")
    exam: PhaseDates = Field(..., description="Exam phase / Prüfungsphase")
    archival: ArchivalPhaseConfig = Field(
        ..., description="Archival phase / Archivierungsphase"
    )


class CurrentSemesterConfig(BaseModel):
    """
    Current semester configuration.
    Aktuelle Semester-Konfiguration.

    EN: Defines the current active semester with its phases.
    DE: Definiert das aktuelle aktive Semester mit seinen Phasen.
    """

    name: str = Field(..., description="Semester name (e.g., WS25/26) / Semester-Name")
    type: SemesterType = Field(..., description="Semester type / Semester-Typ")
    start_date: str = Field(
        ..., description="Semester start date / Semester-Startdatum"
    )
    end_date: str = Field(..., description="Semester end date / Semester-Enddatum")
    phases: SemesterPhases = Field(..., description="Semester phases / Semester-Phasen")

    @field_validator("start_date", "end_date")
    @classmethod
    def validate_semester_dates(cls, v: str) -> str:
        """Validate semester date format."""
        try:
            datetime.strptime(v, "%Y-%m-%d")
        except ValueError:
            raise ValueError(f"Invalid date format: {v}. Expected YYYY-MM-DD")
        return v

    def get_start_date(self) -> date:
        """Get start date as date object."""
        return datetime.strptime(self.start_date, "%Y-%m-%d").date()

    def get_end_date(self) -> date:
        """Get end date as date object."""
        return datetime.strptime(self.end_date, "%Y-%m-%d").date()


class CronSchedule(BaseModel):
    """
    Cron schedule configuration.
    Cron-Zeitplan-Konfiguration.

    EN: Defines cron schedules for automated semester lifecycle jobs.
    DE: Definiert Cron-Zeitpläne für automatisierte Semester-Lebenszyklus-Jobs.
    """

    semester_start: str = Field(
        "0 6 1 10 *", description="Semester start cron / Semester-Start-Cron"
    )
    mid_semester_check: str = Field(
        "0 9 15 * *", description="Mid-semester check cron / Semestermitte-Check-Cron"
    )
    semester_end: str = Field(
        "0 6 1 4 *", description="Semester end cron / Semester-Ende-Cron"
    )
    archival_cleanup: str = Field(
        "0 2 1 4 *",
        description="Archival cleanup cron / Archivierungs-Bereinigungs-Cron",
    )


class AutomationConfig(BaseModel):
    """
    Automation settings configuration.
    Automatisierungseinstellungen-Konfiguration.

    EN: Settings for automated semester lifecycle management.
    DE: Einstellungen für automatisiertes Semester-Lebenszyklus-Management.
    """

    enabled: bool = Field(
        False, description="Enable automation / Automatisierung aktivieren"
    )
    timezone: str = Field(
        "Europe/Berlin",
        description="Timezone for automation / Zeitzone für Automatisierung",
    )
    cron: CronSchedule = Field(
        default_factory=CronSchedule, description="Cron schedules / Cron-Zeitpläne"
    )


class ProvisioningConfig(BaseModel):
    """
    Course provisioning defaults configuration.
    Kursverwaltungs-Standardeinstellungen.

    EN: Default settings for course provisioning during semester transitions.
    DE: Standardeinstellungen für die Kursverwaltung während Semesterübergängen.
    """

    default_category: str = Field(
        "courses", description="Default course category / Standard-Kurskategorie"
    )
    course_prefix: str = Field("", description="Course name prefix / Kurs-Namenspräfix")
    auto_archive: bool = Field(
        True,
        description="Auto-archive old courses / Automatische Archivierung alter Kurse",
    )
    archive_retention_years: int = Field(
        5,
        ge=1,
        le=10,
        description="Years to retain archives / Jahre zur Archivaufbewahrung",
    )


class RoleMapping(BaseModel):
    """
    Role mapping configuration.
    Rollenzuordnung-Konfiguration.

    EN: Maps campus roles to Keycloak and LMS roles.
    DE: Ordnet Campus-Rollen Keycloak- und LMS-Rollen zu.
    """

    campus_role: str = Field(
        ..., description="Campus management role / Campus-Management-Rolle"
    )
    keycloak_role: str = Field(..., description="Keycloak role / Keycloak-Rolle")
    lms_role: str = Field(..., description="LMS role / LMS-Rolle")


class RolesConfig(BaseModel):
    """
    Role synchronization configuration.
    Rollensynchronisierungs-Konfiguration.

    EN: Settings for role synchronization between systems.
    DE: Einstellungen für die Rollensynchronisierung zwischen Systemen.
    """

    sync_on_enrollment_change: bool = Field(
        True,
        description="Sync roles on enrollment change / Rollen bei Einschreibungsänderung synchronisieren",
    )
    sync_interval_minutes: int = Field(
        15,
        ge=1,
        description="Sync interval in minutes / Synchronisierungsintervall in Minuten",
    )
    role_mappings: list[RoleMapping] = Field(
        default_factory=lambda: [
            RoleMapping(
                campus_role="student", keycloak_role="student", lms_role="student"
            ),
            RoleMapping(campus_role="tutor", keycloak_role="tutor", lms_role="tutor"),
            RoleMapping(
                campus_role="lecturer",
                keycloak_role="instructor",
                lms_role="instructor",
            ),
        ],
        description="Role mappings / Rollenzuordnungen",
    )


class SemesterLifecycleConfig(BaseModel):
    """
    Complete semester lifecycle configuration.
    Vollständige Semester-Lebenszyklus-Konfiguration.

    EN: Root configuration for semester lifecycle management.
    DE: Stammkonfiguration für das Semester-Lebenszyklus-Management.
    """

    enabled: bool = Field(
        True, description="Enable semester lifecycle / Semester-Lebenszyklus aktivieren"
    )
    current: CurrentSemesterConfig = Field(
        ..., description="Current semester config / Aktuelle Semester-Konfiguration"
    )
    automation: AutomationConfig = Field(
        default_factory=AutomationConfig,
        description="Automation settings / Automatisierungseinstellungen",
    )
    provisioning: ProvisioningConfig = Field(
        default_factory=ProvisioningConfig,
        description="Provisioning defaults / Verwaltungs-Standardeinstellungen",
    )
    roles: RolesConfig = Field(
        default_factory=RolesConfig,
        description="Role sync settings / Rollensynchronisierungs-Einstellungen",
    )


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables.
    Anwendungseinstellungen aus Umgebungsvariablen geladen.

    EN: Pydantic settings for environment-based configuration.
    DE: Pydantic-Einstellungen für umgebungsbasierte Konfiguration.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    api_host: str = "0.0.0.0"
    api_port: int = 8000
    api_debug: bool = False
    api_title: str = "Course Provisioning API"
    api_version: str = "1.0.0"

    ilias_api_url: Optional[str] = None
    ilias_api_user: Optional[str] = None
    ilias_api_key: Optional[str] = None

    moodle_api_url: Optional[str] = None
    moodle_api_token: Optional[str] = None

    keycloak_url: Optional[str] = None
    keycloak_realm: str = "opendesk-edu"
    keycloak_admin_user: Optional[str] = None
    keycloak_admin_password: Optional[str] = None
    keycloak_client_id: str = "admin-cli"

    database_path: str = ":memory:"

    hisinone_webhook_secret: Optional[str] = None
    hisinone_webhook_port: int = 8001

    semester_automation_enabled: bool = False
    semester_timezone: str = "Europe/Berlin"
    semester_config_path: str = "semester-lifecycle.yaml"

    archive_retention_years: int = 5
    archive_auto_archive: bool = True


# Global semester config cache
_semester_config: Optional[SemesterLifecycleConfig] = None


@lru_cache
def get_settings() -> Settings:
    """
    Get cached application settings.
    Zwischengespeicherte Anwendungseinstellungen abrufen.

    EN: Returns the singleton Settings instance.
    DE: Gibt die Singleton-Settings-Instanz zurück.
    """
    return Settings()


def load_semester_config(config_path: Optional[str] = None) -> SemesterLifecycleConfig:
    """
    Load semester lifecycle configuration from YAML file.
    Semester-Lebenszyklus-Konfiguration aus YAML-Datei laden.

    EN: Loads and validates semester configuration from a YAML file.
    DE: Lädt und validiert die Semester-Konfiguration aus einer YAML-Datei.

    Args:
        config_path: Path to YAML config file. If None, uses default.
                     Pfad zur YAML-Konfigurationsdatei. Falls None, wird Standard verwendet.

    Returns:
        Validated SemesterLifecycleConfig instance.
        Validierte SemesterLifecycleConfig-Instanz.

    Raises:
        FileNotFoundError: If config file doesn't exist.
        ValueError: If config validation fails.
    """
    global _semester_config

    if config_path is None:
        settings = get_settings()
        config_path = settings.semester_config_path

    path = Path(config_path)
    if not path.is_absolute():
        # Try relative to current working directory first
        cwd_path = Path.cwd() / config_path
        if cwd_path.exists():
            path = cwd_path
        else:
            # Try relative to this module
            path = Path(__file__).parent / config_path

    if not path.exists():
        raise FileNotFoundError(
            f"Semester config file not found: {path}"
            f" / Semester-Konfigurationsdatei nicht gefunden: {path}"
        )

    with open(path, "r", encoding="utf-8") as f:
        raw_config = yaml.safe_load(f)

    # Extract the 'semester' key from the config
    if "semester" in raw_config:
        semester_data = raw_config["semester"]
    else:
        semester_data = raw_config

    _semester_config = SemesterLifecycleConfig(**semester_data)
    return _semester_config


def get_semester_config() -> SemesterLifecycleConfig:
    """
    Get the current semester lifecycle configuration.
    Aktuelle Semester-Lebenszyklus-Konfiguration abrufen.

    EN: Returns cached config or loads from default path.
    DE: Gibt zwischengespeicherte Konfiguration zurück oder lädt vom Standardpfad.

    Returns:
        SemesterLifecycleConfig instance.
        SemesterLifecycleConfig-Instanz.
    """
    global _semester_config
    if _semester_config is None:
        _semester_config = load_semester_config()
    return _semester_config


def reset_semester_config() -> None:
    """
    Reset the cached semester configuration (for testing).
    Zwischengespeicherte Semester-Konfiguration zurücksetzen (für Tests).
    """
    global _semester_config
    _semester_config = None


def load_config(config_path: Optional[str] = None) -> Settings:
    """
    Load application configuration.
    Anwendungskonfiguration laden.

    EN: Returns application settings (alias for get_settings).
    DE: Gibt Anwendungseinstellungen zurück (Alias für get_settings).
    """
    return get_settings()


def create_default_semester_config(output_path: str) -> None:
    """
    Create a default semester configuration file.
    Standard-Semester-Konfigurationsdatei erstellen.

    EN: Generates a sample YAML configuration file with sensible defaults.
    DE: Generiert eine Beispiel-YAML-Konfigurationsdatei mit sinnvollen Standardeinstellungen.

    Args:
        output_path: Path where to write the config file.
                     Pfad, unter dem die Konfigurationsdatei geschrieben werden soll.
    """
    default_config = {
        "semester": {
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
            "automation": {
                "enabled": True,
                "timezone": "Europe/Berlin",
                "cron": {
                    "semester_start": "0 6 1 10 *",
                    "mid_semester_check": "0 9 15 * *",
                    "semester_end": "0 6 1 4 *",
                    "archival_cleanup": "0 2 1 4 *",
                },
            },
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
                    {
                        "campus_role": "tutor",
                        "keycloak_role": "tutor",
                        "lms_role": "tutor",
                    },
                    {
                        "campus_role": "lecturer",
                        "keycloak_role": "instructor",
                        "lms_role": "instructor",
                    },
                ],
            },
        }
    }

    path = Path(output_path)
    path.parent.mkdir(parents=True, exist_ok=True)

    with open(path, "w", encoding="utf-8") as f:
        yaml.dump(default_config, f, default_flow_style=False, sort_keys=False)

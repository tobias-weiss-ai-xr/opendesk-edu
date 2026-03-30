# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Course Provisioning Package / Kursverwaltungspaket

This package provides the Course Provisioning API for semester-based course
lifecycle management in openDesk Edu.

Components:
- course_api: FastAPI REST endpoints
- models: Data models (Course, Semester, etc.)
- config: Configuration loading
- database: SQLite storage
- audit: Audit logging
"""

from course_api import app, create_app
from models import (
    Course,
    CourseStatus,
    Semester,
    SemesterType,
    SemesterStatus,
    LMSPlatform,
    Enrollment,
    ArchiveStatus,
)
from config import Settings, get_settings, load_config
from database import Database, DatabaseConfig, get_database
from audit import AuditLogger, AuditAction, get_audit_logger

__all__ = [
    "app",
    "create_app",
    "Course",
    "CourseStatus",
    "Semester",
    "SemesterType",
    "SemesterStatus",
    "LMSPlatform",
    "Enrollment",
    "ArchiveStatus",
    "Settings",
    "get_settings",
    "load_config",
    "Database",
    "DatabaseConfig",
    "get_database",
    "AuditLogger",
    "AuditAction",
    "get_audit_logger",
]

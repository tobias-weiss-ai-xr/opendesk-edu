# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Audit logging module for course provisioning.
Audit-Logging-Modul für die Kursverwaltung.

This module provides audit logging functionality for tracking all course lifecycle
operations including creation, updates, archival, and enrollment changes.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any, Optional
from uuid import uuid4
from enum import Enum

import logging

from pydantic import BaseModel

logger = logging.getLogger(__name__)


class AuditAction(str, Enum):
    """Audit action types / Audit-Aktionsarten as a string Enum for Pydantic compatibility."""

    COURSE_CREATED = "course_created"
    COURSE_UPDATED = "course_updated"
    COURSE_DELETED = "course_deleted"
    COURSE_ARCHIVED = "course_archived"
    COURSE_RESTORED = "course_restored"
    ENROLLMENT_ADDED = "enrollment_added"
    ENROLLMENT_REMOVED = "enrollment_removed"
    SEMESTER_CREATED = "semester_created"
    SEMESTER_UPDATED = "semester_updated"
    SEMESTER_ARCHIVED = "semester_archived"
    BULK_OPERATION = "bulk_operation"


class AuditLog(BaseModel):
    """Audit log entry / Audit-Log-Eintrag."""

    log_id: str
    action: AuditAction
    entity_type: str  # "course", "semester", "enrollment"
    entity_id: str
    user_id: Optional[str] = None
    details: Optional[dict[str, Any]] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    created_at: datetime


class AuditLogger:
    """
    Audit logger for course provisioning operations.
    Audit-Logger für Kursverwaltungsvorgänge.
    """

    def __init__(self, db_path: Optional[str] = ":memory:") -> None:
        """Initialize audit logger / Audit-Logger initialisieren."""
        self.logs: list[AuditLog] = []
        self.db_path = db_path

    def log(
        self,
        action: AuditAction,
        entity_type: str,
        entity_id: str,
        user_id: Optional[str] = None,
        details: Optional[dict] = None,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
    ) -> AuditLog:
        """
        Log an audit event.
        Protokolliert ein Audit-Ereignis.

        Args:
            action: The action type / Der Aktionstyp
            entity_type: Type of entity / Art des Entitäts
            entity_id: Entity identifier / Entitätskennung
            user_id: Optional user ID / Optionale Benutzerkennung
            details: Optional additional details / Optionale zusätzliche Details
            ip_address: Optional IP address / Optionale IP-Adresse
            user_agent: Optional user agent string / Optionale User-Agent-String

        Returns:
            Created audit log entry / Erstellter Audit-Log-Eintrag
        """
        log_entry = AuditLog(
            log_id=f"audit_{uuid4().hex[:12]}",
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            user_id=user_id,
            details=details,
            ip_address=ip_address,
            user_agent=user_agent,
            created_at=datetime.now(timezone.utc),
        )

        if self.db_path != ":memory:":
            self._persist_log(log_entry)
        else:
            self.logs.append(log_entry)

        return log_entry

    def _persist_log(self, log_entry: AuditLog) -> None:
        """Persist log to database / Log in Datenbank persistieren."""
        import sqlite3
        from pathlib import Path

        try:
            Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS audit_logs (
                        log_id TEXT PRIMARY KEY,
                        action TEXT NOT NULL,
                        entity_type TEXT NOT NULL,
                        entity_id TEXT NOT NULL,
                        user_id TEXT,
                        details TEXT,
                        ip_address TEXT,
                        user_agent TEXT,
                        created_at TEXT NOT NULL
                    )
                """)
                cursor.execute(
                    "INSERT INTO audit_logs VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    (
                        log_entry.log_id,
                        log_entry.action.value,
                        log_entry.entity_type,
                        log_entry.entity_id,
                        log_entry.user_id,
                        json.dumps(log_entry.details) if log_entry.details else None,
                        log_entry.ip_address,
                        log_entry.user_agent,
                        log_entry.created_at.isoformat(),
                    ),
                )
                conn.commit()
        except Exception as exc:
            # Fall back to memory storage if persistence fails.
            # Do NOT re-append to self.logs — it was already appended above.
            logging.getLogger(__name__).warning(
                f"Failed to persist audit log {log_entry.log_id} to database: {exc}"
            )

    def get_logs(
        self,
        entity_type: Optional[str] = None,
        entity_id: Optional[str] = None,
        action: Optional[AuditAction] = None,
        limit: int = 100,
    ) -> list[AuditLog]:
        """
        Get audit logs with optional filtering.
        Audit-Logs mit optionaler Filterung abrufen.

        Args:
            entity_type: Filter by entity type / Nach Entitätstyp filtern
            entity_id: Filter by entity ID / Nach Entitätskennung filtern
            action: Filter by action / Nach Aktion filtern
            limit: Maximum number of results / Maximale Anzahl an Ergebnisse

        Returns:
            List of matching audit logs / Liste der ü passenden Audit-Logs
        """
        filtered = self.logs

        if entity_type:
            filtered = [
                log_entry
                for log_entry in filtered
                if log_entry.entity_type == entity_type
            ]
        if entity_id:
            filtered = [
                log_entry for log_entry in filtered if log_entry.entity_id == entity_id
            ]
        if action:
            if isinstance(action, list):
                filtered = [
                    log_entry for log_entry in filtered if log_entry.action in action
                ]
            else:
                filtered = [
                    log_entry for log_entry in filtered if log_entry.action == action
                ]

        return filtered[:limit]

    def get_log(self, log_id: str) -> Optional[AuditLog]:
        """
        Get a specific audit log by ID.
        Spezifischen Audit-Log nach ID abrufen.

        Args:
            log_id: The log ID / Die Log-Kennung

        Returns:
            The audit log or None / Der Audit-Log oder None
        """
        for log in self.logs:
            if log.log_id == log_id:
                return log
        return None

    def clear(self) -> None:
        """Clear all logs from memory / Alle Logs aus dem Speicher löschen."""
        self.logs = []

    def export_logs(self, file_path: str) -> None:
        """Export logs to JSON file / Logs in JSON-Datei exportieren."""
        with open(file_path, "w") as f:
            json.dump([log.model_dump(mode="json") for log in self.logs], f, indent=2)


# Global audit logger instance
audit_logger = AuditLogger()


def get_audit_logger() -> AuditLogger:
    """Get global audit logger instance / Globale Audit-Logger-Instanz abrufen."""
    global audit_logger
    if audit_logger is None:
        audit_logger = AuditLogger()
    return audit_logger

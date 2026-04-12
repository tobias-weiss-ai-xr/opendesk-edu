# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
SQLite database storage for course provisioning.
SQLite-Datenbankspeicherung für die Kursverwaltung.

This module provides SQLite database models and operations for persistent
storage of courses, semesters, enrollments, and audit logs. Designed to be
easily migratable to PostgreSQL for production deployments.
"""

from __future__ import annotations

import json
import logging
import sqlite3
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Generator, Optional
from uuid import uuid4

from pydantic import BaseModel

_db_logger = logging.getLogger(__name__)


class DatabaseConfig(BaseModel):
    """Database configuration / Datenbankkonfiguration."""

    db_path: str = ":memory:"
    echo: bool = False


class Database:
    """
    SQLite database manager with PostgreSQL-ready schema.
    SQLite-Datenbankmanager mit PostgreSQL-fähigem Schema.
    """

    def __init__(self, config: Optional[DatabaseConfig] = None):
        self.config = config or DatabaseConfig()
        self._connection: Optional[sqlite3.Connection] = None

    def connect(self) -> None:
        """Establish database connection / Datenbankverbindung herstellen."""
        if self.config.db_path == ":memory:":
            self._connection = sqlite3.connect(":memory:", check_same_thread=False)
        else:
            Path(self.config.db_path).parent.mkdir(parents=True, exist_ok=True)
            self._connection = sqlite3.connect(
                self.config.db_path, check_same_thread=False
            )
        self._connection.row_factory = sqlite3.Row
        if self.config.echo:
            self._connection.set_trace_callback(_db_logger.debug)
        self._create_tables()

    def close(self) -> None:
        """Close database connection / Datenbankverbindung schließen."""
        if self._connection:
            self._connection.close()
            self._connection = None

    @contextmanager
    def get_connection(self) -> Generator[sqlite3.Connection, None, None]:
        """Get database connection context manager / Datenbankverbindung Context-Manager."""
        if not self._connection:
            self.connect()
        try:
            yield self._connection
        finally:
            pass

    def _create_tables(self) -> None:
        """Create database tables if they don't exist / Datenbanktabellen erstellen falls nicht vorhanden."""
        with self.get_connection() as conn:
            cursor = conn.cursor()

            # Courses table - PostgreSQL-ready schema
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS courses (
                    course_id TEXT PRIMARY KEY,
                    lms_course_id TEXT,
                    semester_id TEXT NOT NULL,
                    title TEXT NOT NULL,
                    title_en TEXT,
                    course_code TEXT NOT NULL,
                    instructor_ids TEXT NOT NULL DEFAULT '[]',
                    expected_enrollment INTEGER,
                    lms TEXT NOT NULL,
                    category TEXT,
                    status TEXT NOT NULL DEFAULT 'active',
                    created_at TEXT NOT NULL,
                    updated_at TEXT,
                    archived_at TEXT,
                    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id)
                )
            """)

            # Semesters table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS semesters (
                    semester_id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    name_en TEXT,
                    start_date TEXT NOT NULL,
                    end_date TEXT NOT NULL,
                    enrollment_start TEXT,
                    enrollment_end TEXT,
                    status TEXT NOT NULL DEFAULT 'upcoming',
                    created_at TEXT NOT NULL,
                    updated_at TEXT
                )
            """)

            # Enrollments table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS enrollments (
                    enrollment_id TEXT PRIMARY KEY,
                    course_id TEXT NOT NULL,
                    user_id TEXT NOT NULL,
                    role TEXT NOT NULL DEFAULT 'student',
                    status TEXT NOT NULL DEFAULT 'active',
                    created_at TEXT NOT NULL,
                    updated_at TEXT,
                    FOREIGN KEY (course_id) REFERENCES courses(course_id),
                    UNIQUE(course_id, user_id)
                )
            """)

            # Audit logs table
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

            conn.commit()

    # Course operations
    def create_course(self, course_data: dict) -> dict:
        """
        Create a new course in the database.
        Erstellt einen neuen Kurs in der Datenbank.

        Args:
            course_data: Course data dictionary / Kursdaten-Dictionary

        Returns:
            Created course data / Erstellte Kursdaten
        """
        course_id = course_data.get("course_id", f"crs_{uuid4().hex[:12]}")
        now = datetime.now(timezone.utc).isoformat()

        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT INTO courses (
                    course_id, lms_course_id, semester_id, title, title_en,
                    course_code, instructor_ids, expected_enrollment, lms,
                    category, status, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
                (
                    course_id,
                    course_data.get("lms_course_id"),
                    course_data["semester_id"],
                    course_data["title"],
                    course_data.get("title_en"),
                    course_data["course_code"],
                    json.dumps(course_data.get("instructor_ids", [])),
                    course_data.get("expected_enrollment"),
                    course_data["lms"],
                    course_data.get("category"),
                    course_data.get("status", "active"),
                    now,
                ),
            )
            conn.commit()

            return self.get_course(course_id)

    def get_course(self, course_id: str) -> Optional[dict]:
        """
        Get a course by ID.
        Kurs nach ID abrufen.

        Args:
            course_id: Course identifier / Kurskennung

        Returns:
            Course data or None / Kursdaten oder None
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM courses WHERE course_id = ?", (course_id,))
            row = cursor.fetchone()
            if row:
                return self._row_to_course(row)
            return None

    def list_courses(
        self,
        semester_id: Optional[str] = None,
        status: Optional[str] = None,
        lms: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> tuple[list[dict], int]:
        """
        List courses with optional filtering.
        Kurse mit optionaler Filterung auflisten.

        Args:
            semester_id: Filter by semester / Nach Semester filtern
            status: Filter by status / Nach Status filtern
            lms: Filter by LMS platform / Nach LMS-Plattform filtern
            page: Page number / Seitennummer
            page_size: Items per page / Einträge pro Seite

        Returns:
            Tuple of (courses, total_count) / Tupel aus (Kurse, Gesamtanzahl)
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()

            conditions = []
            params = []

            if semester_id:
                conditions.append("semester_id = ?")
                params.append(semester_id)
            if status:
                conditions.append("status = ?")
                params.append(status)
            if lms:
                conditions.append("lms = ?")
                params.append(lms)

            where_clause = " AND ".join(conditions) if conditions else "1=1"

            # Get total count
            cursor.execute(f"SELECT COUNT(*) FROM courses WHERE {where_clause}", params)
            total = cursor.fetchone()[0]

            # Get paginated results
            offset = (page - 1) * page_size
            cursor.execute(
                f"SELECT * FROM courses WHERE {where_clause} ORDER BY created_at DESC LIMIT ? OFFSET ?",
                params + [page_size, offset],
            )
            rows = cursor.fetchall()
            courses = [self._row_to_course(row) for row in rows]

            return courses, total

    def update_course(self, course_id: str, update_data: dict) -> Optional[dict]:
        """
        Update a course.
        Kurs aktualisieren.

        Args:
            course_id: Course identifier / Kurskennung
            update_data: Fields to update / Zu aktualisierende Felder

        Returns:
            Updated course data or None / Aktualisierte Kursdaten oder None
        """
        now = datetime.now(timezone.utc).isoformat()

        with self.get_connection() as conn:
            cursor = conn.cursor()

            # Build update query dynamically
            set_clauses = []
            params = []

            for field in [
                "title",
                "title_en",
                "course_code",
                "category",
                "status",
                "expected_enrollment",
            ]:
                if field in update_data:
                    set_clauses.append(f"{field} = ?")
                    params.append(update_data[field])

            if "instructor_ids" in update_data:
                set_clauses.append("instructor_ids = ?")
                params.append(json.dumps(update_data["instructor_ids"]))

            if not set_clauses:
                return self.get_course(course_id)

            set_clauses.append("updated_at = ?")
            params.append(now)
            params.append(course_id)

            query = f"UPDATE courses SET {', '.join(set_clauses)} WHERE course_id = ?"
            cursor.execute(query, params)
            conn.commit()

            return self.get_course(course_id)

    def delete_course(self, course_id: str) -> bool:
        """
        Soft delete a course (set status to 'deleted').
        Kurs weich löschen (Status auf 'deleted' setzen).

        Args:
            course_id: Course identifier / Kurskennung

        Returns:
            True if deleted, False if not found / True wenn gelöscht, False wenn nicht gefunden
        """
        now = datetime.now(timezone.utc).isoformat()

        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "UPDATE courses SET status = 'deleted', updated_at = ? WHERE course_id = ?",
                (now, course_id),
            )
            conn.commit()
            return cursor.rowcount > 0

    def archive_course(self, course_id: str) -> Optional[dict]:
        """
        Archive a course.
        Kurs archivieren.

        Args:
            course_id: Course identifier / Kurskennung

        Returns:
            Updated course data or None / Aktualisierte Kursdaten oder None
        """
        now = datetime.now(timezone.utc).isoformat()

        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                UPDATE courses
                SET status = 'archived', archived_at = ?, updated_at = ?
                WHERE course_id = ? AND status = 'active'
            """,
                (now, now, course_id),
            )
            conn.commit()

            if cursor.rowcount > 0:
                return self.get_course(course_id)
            return None

    def restore_course(self, course_id: str) -> Optional[dict]:
        """
        Restore an archived course.
        Archivierten Kurs wiederherstellen.

        Args:
            course_id: Course identifier / Kurskennung

        Returns:
            Updated course data or None / Aktualisierte Kursdaten oder None
        """
        now = datetime.now(timezone.utc).isoformat()

        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                UPDATE courses
                SET status = 'active', archived_at = NULL, updated_at = ?
                WHERE course_id = ? AND status = 'archived'
            """,
                (now, course_id),
            )
            conn.commit()

            if cursor.rowcount > 0:
                return self.get_course(course_id)
            return None

    # Semester operations
    def create_semester(self, semester_data: dict) -> dict:
        """Create a new semester / Neues Semester erstellen."""
        semester_id = semester_data["semester_id"]
        now = datetime.now(timezone.utc).isoformat()

        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT INTO semesters (
                    semester_id, name, name_en, start_date, end_date,
                    enrollment_start, enrollment_end, status, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
                (
                    semester_id,
                    semester_data["name"],
                    semester_data.get("name_en"),
                    semester_data["start_date"],
                    semester_data["end_date"],
                    semester_data.get("enrollment_start"),
                    semester_data.get("enrollment_end"),
                    semester_data.get("status", "upcoming"),
                    now,
                ),
            )
            conn.commit()

            return self.get_semester(semester_id)

    def get_semester(self, semester_id: str) -> Optional[dict]:
        """Get a semester by ID / Semester nach ID abrufen."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT * FROM semesters WHERE semester_id = ?", (semester_id,)
            )
            row = cursor.fetchone()
            if row:
                return dict(row)
            return None

    def list_semesters(self) -> list[dict]:
        """List all semesters / Alle Semester auflisten."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM semesters ORDER BY start_date DESC")
            rows = cursor.fetchall()
            return [dict(row) for row in rows]

    # Enrollment operations
    def create_enrollment(self, enrollment_data: dict) -> dict:
        """Create a new enrollment / Neue Einschreibung erstellen."""
        enrollment_id = enrollment_data.get("enrollment_id", f"enr_{uuid4().hex[:12]}")
        now = datetime.now(timezone.utc).isoformat()

        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT INTO enrollments (
                    enrollment_id, course_id, user_id, role, status, created_at
                ) VALUES (?, ?, ?, ?, ?, ?)
            """,
                (
                    enrollment_id,
                    enrollment_data["course_id"],
                    enrollment_data["user_id"],
                    enrollment_data.get("role", "student"),
                    enrollment_data.get("status", "active"),
                    now,
                ),
            )
            conn.commit()

            return self.get_enrollment(enrollment_id)

    def get_enrollment(self, enrollment_id: str) -> Optional[dict]:
        """Get an enrollment by ID / Einschreibung nach ID abrufen."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT * FROM enrollments WHERE enrollment_id = ?", (enrollment_id,)
            )
            row = cursor.fetchone()
            if row:
                return dict(row)
            return None

    def list_enrollments(self, course_id: str) -> list[dict]:
        """List enrollments for a course / Einschreibungen für einen Kurs auflisten."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT * FROM enrollments WHERE course_id = ? ORDER BY created_at",
                (course_id,),
            )
            rows = cursor.fetchall()
            return [dict(row) for row in rows]

    def update_enrollment(
        self, enrollment_id: str, update_data: dict
    ) -> Optional[dict]:
        """
        Update an enrollment.
        Einschreibung aktualisieren.

        EN: Updates the enrollment record with new data. Only 'status' is currently supported.
        DE: Aktualisiert den Einschreibungsdatensatz mit neuen data. Nur 'status' wird derzeit unterstützt.

        Args:
            enrollment_id: Enrollment identifier / Einschreibungskennung.
            update_data: Fields to update / Zu aktualisierende Felder.

        Returns:
            Updated enrollment data or None / Aktualisierte Einschreibungsdaten oder None.
        """
        now = datetime.now(timezone.utc).isoformat()

        with self.get_connection() as conn:
            cursor = conn.cursor()

            set_clauses = []
            params = []

            if "status" in update_data:
                set_clauses.append("status = ?")
                params.append(update_data["status"])

            if not set_clauses:
                return self.get_enrollment(enrollment_id)

            set_clauses.append("updated_at = ?")
            params.append(now)
            params.append(enrollment_id)

            query = f"UPDATE enrollments SET {', '.join(set_clauses)} WHERE enrollment_id = ?"
            cursor.execute(query, params)
            conn.commit()

            return self.get_enrollment(enrollment_id)

    def _row_to_course(self, row: sqlite3.Row) -> dict:
        """Convert a database row to course dict / Datenbankzeile zu Kurs-Dictionary konvertieren."""
        data = dict(row)
        data["instructor_ids"] = json.loads(data["instructor_ids"])
        return data


# Global database instance
_db: Optional[Database] = None


def get_database(config: Optional[DatabaseConfig] = None) -> Database:
    """
    Get or create the global database instance.
    Globale Datenbankinstanz abrufen oder erstellen.

    Args:
        config: Database configuration / Datenbankkonfiguration

    Returns:
        Database instance / Datenbankinstanz
    """
    global _db
    if _db is None:
        _db = Database(config)
        _db.connect()
    return _db


def reset_database() -> None:
    """Reset the database (for testing) / Datenbank zurücksetzen (für Tests)."""
    global _db
    if _db:
        _db.close()
        _db = None

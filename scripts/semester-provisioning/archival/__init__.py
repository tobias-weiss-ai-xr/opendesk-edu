# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""
Archival Scripts / Archivierungsskripte

EN: Stand-alone scripts for archiving and restoring courses.
Can be run independently of the API server.

DE: Eigenständige Skripte zum Archivieren und Wiederherstellen von Kursen.
Können unabhängig vom API-Server ausgeführt werden.
"""

from archival.archive_course import (
    ArchiveResult,
    ArchiveSnapshot,
    ILIASArchivalClient,
    MoodleArchivalClient,
    archive_course,
)
from archival.bulk_archive import (
    BulkArchiveSummary,
    bulk_archive_semester,
)
from archival.restore_course import (
    RestoreResult,
    ILIASRestoreClient,
    MoodleRestoreClient,
    restore_course,
)

__all__ = [
    "archive_course",
    "ArchiveResult",
    "ArchiveSnapshot",
    "ILIASArchivalClient",
    "MoodleArchivalClient",
    "bulk_archive_semester",
    "BulkArchiveSummary",
    "restore_course",
    "RestoreResult",
    "ILIASRestoreClient",
    "MoodleRestoreClient",
]

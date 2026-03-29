# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0

- German: Überblick über den Lebenszyklus eines Semesters: Erstellung, Einschreibung, Archivierung, Wiederherstellung.
- English: Overview of the semester lifecycle: creation, enrollments, archiving, restoration.

## Ziel / Goal
- Manage semester lifecycle end-to-end for university courses in a single API surface.
- Ergebnis: konsistente Statuswerte, Heartbeat-ähnliche Jobs für Bulk-Operationen, und einfache Integrationen mit LMS/Keycloak.

## API Coverage
- Endpunkte für Semester: erstellen, listen, detail, aktualisieren, archivieren.
- Verknüpfte Endpunkte für Kurse, Einschreibungen und Archivierung bleiben im Kontext des Semesters.

## Vorgehen / Approach
- Strukturierte Tests basierend auf existing patterns in tests/test_api_courses.py.
- Integrierte Dokumentation in bilingualem Stil.

## API Design Notes
- Semesterdaten modellieren Status: upcoming, active, archived, ended.
- Archiving von Kursen erfolgt über dedicated Archival-Endpoints.

---

- German: Überblick über den Lebenszyklus eines Semesters: Erstellung, Einschreibung, Archivierung, Wiederherstellung.
- English: Overview of the semester lifecycle: creation, enrollments, archiving, restoration.

<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Semester Lifecycle Management / Semester-Lebenszyklus-Management

[English](#english) | [Deutsch](#deutsch)

---

<a name="english"></a>

## English

### Overview

Semester Lifecycle Management provides automated handling of university course lifecycles within openDesk Edu. The system manages semester transitions, course provisioning, enrollment synchronization, and archival workflows.

### Semester Phases

Each semester progresses through four distinct phases:

| Phase | Description | Typical Duration |
|-------|-------------|------------------|
| **Enrollment** | Course registration period | 4-8 weeks before semester start |
| **Teaching** | Active instruction period | 14-16 weeks |
| **Exam** | Examination period | 2-4 weeks |
| **Archival** | Post-semester cleanup | After exam period ends |

### CLI Commands

The `semester-provisioning` CLI provides three main commands:

#### `current` - Display Current Semester

```bash
# Show current semester information
semester-provisioning current

# Show as JSON output
semester-provisioning current --json

# Check for a specific date
semester-provisioning current --date 2026-01-15

# Use custom config file
semester-provisioning current --config /path/to/semester-config.yaml
```

**Example Output:**

```
=== Current Semester ===
Name:       WS25/26
Type:       wintersemester
Start:      2025-10-01
End:        2026-03-31
Phase:      teaching
============================
```

#### `transition` - Execute Semester Transition

```bash
# Transition from old to new semester
semester-provisioning transition --old WS24/25 --new WS25/26

# Dry-run mode (preview without changes)
semester-provisioning transition --old WS24/25 --new WS25/26 --dry-run

# With custom config
semester-provisioning transition --old WS24/25 --new WS25/26 --config ./config.yaml
```

**Transition Workflow:**

1. Archive all active courses from old semester
2. Create new semester configuration
3. Provision new courses (if auto-provisioning enabled)
4. Sync enrollments from campus management
5. Activate new semester courses

**Example Output:**

```
=== Semester Transition Report ===
Old Semester:        WS24/25
New Semester:        WS25/26
Archived Courses:    45
Created Courses:     52
Synced Enrollments:  1250
Errors:              0
Success:             True
==================================

(dry-run — no changes were made)
```

#### `phases` - Display All Semester Phases

```bash
# Show all phases for current semester
semester-provisioning phases

# JSON output
semester-provisioning phases --json

# With custom config
semester-provisioning phases --config ./semester-config.yaml
```

**Example Output:**

```
=== Semester Phases ===
  enrollment:
    start: 2025-07-01
    end: 2025-09-30
  teaching:
    start: 2025-10-15
    end: 2026-02-28
  exam:
    start: 2026-03-01
    end: 2026-03-31
  archival:
    deadline: 2026-04-15
========================
```

### Semester Configuration

Semester settings are defined in the Helm values:

```yaml
# helmfile/apps/semester-provisioning/values.yaml
semester:
  enabled: true

  current:
    name: "WS25/26"
    type: "wintersemester"
    start_date: "2025-10-01"
    end_date: "2026-03-31"

    phases:
      enrollment:
        start: "2025-07-01"
        end: "2025-09-30"
      teaching:
        start: "2025-10-15"
        end: "2026-02-28"
      exam:
        start: "2026-03-01"
        end: "2026-03-31"
      archival:
        deadline: "2026-04-15"

  previous:
    name: "SS25"
    type: "sommersemester"
    start_date: "2025-04-01"
    end_date: "2025-09-30"
```

### Course Status Lifecycle

```
┌─────────┐     Activate      ┌─────────┐     Archive     ┌──────────┐
│  DRAFT  │ ───────────────► │  ACTIVE │ ──────────────► │ ARCHIVED │
└─────────┘                  └─────────┘                 └──────────┘
     │                            │                            │
     │ Delete                     │ Delete                     │ Restore
     ▼                            ▼                            ▼
┌─────────┐                  ┌─────────┐                  ┌─────────┐
│ DELETED │                  │ DELETED │                  │ ACTIVE  │
└─────────┘                  └─────────┘                  └─────────┘
```

### Integration Points

| System | Integration Type | Purpose |
|--------|-----------------|---------|
| **ILIAS** | REST API | Course creation, enrollment sync |
| **Moodle** | REST API | Course creation, enrollment sync |
| **Keycloak** | Admin API | Group management, role sync |
| **HISinOne** | Webhook (optional) | Campus management sync |

### Troubleshooting

#### No Current Semester Detected

```
No current semester configured for the given date.
  Use --config to provide a semester configuration file.
```

**Solution:** Ensure the `semester-config.yaml` is properly configured and the date falls within a defined semester.

#### Transition Errors

If transition fails, check:

1. LMS API connectivity (ILIAS/Moodle)
2. Keycloak admin credentials
3. Database connectivity
4. Audit logs for detailed error messages

---

<a name="deutsch"></a>

## Deutsch

### Übersicht

Das Semester-Lebenszyklus-Management bietet automatisierte Verwaltung von Universitätskurs-Lebenszyklen innerhalb von openDesk Edu. Das System verwaltet Semesterübergänge, Kursbereitstellung, Einschreibungssynchronisation und Archivierungsworkflows.

### Semester-Phasen

Jedes Semester durchläuft vier unterschiedliche Phasen:

| Phase | Beschreibung | Typische Dauer |
|-------|--------------|----------------|
| **Einschreibung** | Kursregistrierungszeitraum | 4-8 Wochen vor Semesterbeginn |
| **Lehre** | Aktiver Lehrzeitraum | 14-16 Wochen |
| **Prüfung** | Prüfungszeitraum | 2-4 Wochen |
| **Archivierung** | Nach-Semester-Bereinigung | Nach Ende des Prüfungszeitraums |

### CLI-Befehle

Die `semester-provisioning` CLI bietet drei Hauptbefehle:

#### `current` - Aktuelles Semester anzeigen

```bash
# Aktuelle Semesterinformationen anzeigen
semester-provisioning current

# Als JSON-Ausgabe anzeigen
semester-provisioning current --json

# Für ein bestimmtes Datum prüfen
semester-provisioning current --date 2026-01-15

# Benutzerdefinierte Konfigurationsdatei verwenden
semester-provisioning current --config /pfad/zur/semester-config.yaml
```

**Beispielausgabe:**

```
=== Current Semester ===
Name:       WS25/26
Type:       wintersemester
Start:      2025-10-01
End:        2026-03-31
Phase:      teaching
============================
```

#### `transition` - Semesterübergang ausführen

```bash
# Von altem zu neuem Semester übergehen
semester-provisioning transition --old WS24/25 --new WS25/26

# Dry-Run-Modus (Vorschau ohne Änderungen)
semester-provisioning transition --old WS24/25 --new WS25/26 --dry-run

# Mit benutzerdefinierter Konfiguration
semester-provisioning transition --old WS24/25 --new WS25/26 --config ./config.yaml
```

**Übergangs-Workflow:**

1. Alle aktiven Kurse des alten Semesters archivieren
2. Neue Semesterkonfiguration erstellen
3. Neue Kurse bereitstellen (wenn Auto-Provisioning aktiviert)
4. Einschreibungen aus dem Campus-Management synchronisieren
5. Kurse des neuen Semesters aktivieren

**Beispielausgabe:**

```
=== Semester Transition Report ===
Old Semester:        WS24/25
New Semester:        WS25/26
Archived Courses:    45
Created Courses:     52
Synced Enrollments:  1250
Errors:              0
Success:             True
==================================

(dry-run — no changes were made)
```

#### `phases` - Alle Semester-Phasen anzeigen

```bash
# Alle Phasen für das aktuelle Semester anzeigen
semester-provisioning phases

# JSON-Ausgabe
semester-provisioning phases --json

# Mit benutzerdefinierter Konfiguration
semester-provisioning phases --config ./semester-config.yaml
```

**Beispielausgabe:**

```
=== Semester Phases ===
  enrollment:
    start: 2025-07-01
    end: 2025-09-30
  teaching:
    start: 2025-10-15
    end: 2026-02-28
  exam:
    start: 2026-03-01
    end: 2026-03-31
  archival:
    deadline: 2026-04-15
========================
```

### Semester-Konfiguration

Die Semester-Einstellungen werden in den Helm-Values definiert:

```yaml
# helmfile/apps/semester-provisioning/values.yaml
semester:
  enabled: true

  current:
    name: "WS25/26"
    type: "wintersemester"
    start_date: "2025-10-01"
    end_date: "2026-03-31"

    phases:
      enrollment:
        start: "2025-07-01"
        end: "2025-09-30"
      teaching:
        start: "2025-10-15"
        end: "2026-02-28"
      exam:
        start: "2026-03-01"
        end: "2026-03-31"
      archival:
        deadline: "2026-04-15"

  previous:
    name: "SS25"
    type: "sommersemester"
    start_date: "2025-04-01"
    end_date: "2025-09-30"
```

### Kurs-Status-Lebenszyklus

```
┌─────────┐    Aktivieren     ┌─────────┐    Archivieren  ┌──────────┐
│  DRAFT  │ ───────────────► │  ACTIVE │ ──────────────► │ ARCHIVED │
└─────────┘                  └─────────┘                 └──────────┘
     │                            │                            │
     │ Löschen                    │ Löschen                    │ Wiederherstellen
     ▼                            ▼                            ▼
┌─────────┐                  ┌─────────┐                  ┌─────────┐
│ DELETED │                  │ DELETED │                  │ ACTIVE  │
└─────────┘                  └─────────┘                  └─────────┘
```

### Integrationspunkte

| System | Integrationstyp | Zweck |
|--------|----------------|-------|
| **ILIAS** | REST API | Kurserstellung, Einschreibungssync |
| **Moodle** | REST API | Kurserstellung, Einschreibungssync |
| **Keycloak** | Admin API | Gruppenverwaltung, Rollensync |
| **HISinOne** | Webhook (optional) | Campus-Management-Sync |

### Fehlerbehebung

#### Kein aktuelles Semester erkannt

```
No current semester configured for the given date.
  Use --config to provide a semester configuration file.
```

**Lösung:** Stellen Sie sicher, dass die `semester-config.yaml` korrekt konfiguriert ist und das Datum innerhalb eines definierten Semesters liegt.

#### Übergangsfehler

Wenn der Übergang fehlschlägt, prüfen Sie:

1. LMS-API-Konnektivität (ILIAS/Moodle)
2. Keycloak-Admin-Anmeldedaten
3. Datenbankverbindung
4. Audit-Logs für detaillierte Fehlermeldungen

---

## Related Documentation / Verwandte Dokumentation

- [Course Provisioning API](./course-provisioning-api.md) - REST API reference
- [Semester Automation Guide](./semester-automation-guide.md) - Automation setup
- [External Services](./external-services.md) - LMS integration
- [Getting Started](./getting-started.md) - Initial setup

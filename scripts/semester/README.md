<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# Semester Archival Scripts

Archive courses for completed semesters with automated data retention policies.

## Overview

The `archive-courses.sh` script automates the end-of-semester archival process for openDesk Edu. It:

- Freezes enrollments (prevents new enrollments)
- Archives course content to cold storage
- Sets retention policies for different data types
- Generates archival reports

This workflow follows the semester lifecycle configuration defined in `helmfile/environments/default/semester-lifecycle.yaml.gotmpl`.

## Prerequisites

- Bash shell support
- Access to course provisioning API (when fully implemented)
- API authentication token for course management
- `yq` tool (optional, for loading retention config from yaml)

## Quick Start

### Preview Archival (Dry-Run Mode)

Always run in dry-run mode first to preview what will happen:

```bash
./scripts/semester/archive-courses.sh \
    --semester WS2026 \
    --dry-run
```

### Archive Completed Semester

After verifying dry-run output:

```bash
./scripts/semester/archive-courses.sh \
    --semester WS2026
```

### Archive with Custom Retention Policies

```bash
./scripts/semester/archive-courses.sh \
    --semester SS2026 \
    --content-retention-days 730 \
    --assessment-retention-days 3650 \
    --recording-retention-days 730
```

## Options

| Option | Required | Description | Default |
|--------|----------|-------------|---------|
| `-s, --semester SEMESTER_CODE` | Yes | Semester code (e.g., WS2026, SS2026) | - |
| `-a, --api-url URL` | No | API base URL for course management | `http://localhost:8080` |
| `-c, --config-file PATH` | No | Semester lifecycle config file | `helmfile/environments/default/semester-lifecycle.yaml.gotmpl` |
| `--content-retention-days DAYS` | No | Days to retain course content | `365` |
| `--assessment-retention-days DAYS` | No | Days to retain assessment data | `1825` (5 years) |
| `--recording-retention-days DAYS` | No | Days to retain meeting recordings | `365` |
| `-d, --dry-run` | No | Preview changes without executing | `false` |
| `-v, --verbose` | No | Enable verbose logging | `false` |
| `-h, --help` | No | Show usage information | - |

## Data Retention Policies

### Default Retention Periods

The following retention policies are configured by default:

| Data Type | Retention Period | Legal Rationale |
|-----------|-----------------|-----------------|
| **Course Content** | 365 days (1 year) | General course materials can be purged after a year |
| **Assessment Data** | 1825 days (5 years) | GDPR article 11: processing limitation for personal data |
| **Meeting Recordings** | 365 days (1 year) | Lecture recordings are not permanent records |
| **Grade Records** | Permanent | Academic records required to be retained indefinitely |

### Customizing Retention Policies

Retention policies can be customized in three ways:

#### 1. Command-Line Arguments

Override specific retention values:

```bash
./archive-courses.sh \
    --semester WS2026 \
    --content-retention-days 730 \
    --assessment-retention-days 3650
```

#### 2. Config File

Edit values in `helmfile/environments/default/semester-lifecycle.yaml.gotmpl`:

```yaml
semesterLifecycle:
  archival:
    retention:
      contentRetentionDays: 365
      assessmentRetentionDays: 1825  ## 5 years
      recordingRetentionDays: 365
```

#### 3. Environment Variables

Set environment variables to override config defaults:

```bash
export SEMESTER_CONTENT_RETENTION_DAYS=730
export SEMESTER_ASSESSMENT_RETENTION_DAYS=3650
export SEMESTER_RECORDING_RETENTION_DAYS=730
./archive-courses.sh --semester WS2026
```

## Archival Workflow

### Step 1: Validate Semester

The script validates that the semester code follows the required format:

- **Winter Semester**: `WS` + 4-digit year (e.g., `WS2026`)
- **Summer Semester**: `SS` + 4-digit year (e.g., `SS2026`)

### Step 2: Fetch Courses

The script queries the course provisioning API for all courses associated with the semester:

```bash
GET /courses?semester=WS2026
```

**Note**: This feature is a placeholder until the course provisioning API is fully implemented (see Task 5).

### Step 3: Freeze Enrollments

Prevents new enrollments for archived courses:

```bash
POST /courses/{id}/freeze-enrollments
```

This ensures archived courses cannot receive new students, preserving the historical record.

### Step 4: Archive Course Content

Moves course content to cold storage with retention policies:

```bash
POST /courses/{id}/archive
Content-Type: application/json

{
  "retention": {
    "contentRetentionDays": 365,
    "assessmentRetentionDays": 1825,
    "recordingRetentionDays": 365
  }
}
```

### Step 5: Generate Report

The script outputs a comprehensive archival report showing:

- Number of courses processed
- Number of enrollments frozen
- Number of courses archived
- Retention policies applied
- Any errors encountered

## Semester Lifecycle Integration

The archival script integrates with the semester lifecycle configuration:

### When to Run Archival

Archival should be run after the semester has ended and the grace period has passed:

```yaml
semesterLifecycle:
  currentSemester:
    endDate: "2026-03-31"
  archival:
    startAfterDays: 30  ## Run archival 30 days after semester end
```

### Grace Period

The 30-day grace period allows:

- Instructors to export student data
- Students to complete final assessments
- Administrators to verify course completeness

### Automating Archival

Archival can be automated with cron:

```bash
# Run archival script 30 days after semester end
0 0 15 4 * /opt/git/opendesk-edu/scripts/semester/archive-courses.sh --semester WS2026
```

## Examples

### Example 1: Standard Semester Archival

Archive the fall semester with defaults:

```bash
./archive-courses.sh --semester WS2026
```

**Output**:

```
[INFO] Course archival workflow initialized
[INFO]   Semester: WS2026
[INFO]   API URL: http://localhost:8080
[INFO] Loading retention config from helmfile/environments/default/semester-lifecycle.yaml.gotmpl...
[INFO] Starting archival for semester WS2026...
[INFO] Fetching courses for semester WS2026...
[INFO] Freezing enrollments for semester WS2026...
[INFO] Froze enrollments for 45 courses
[INFO] Archiving course content for semester WS2026...
[INFO] Archived content for 45 courses
[INFO] Archival for semester WS2026 completed

=== Course Archival Report ===
Semester: WS2026
Timestamp: 2026-04-15T08:00:00+02:00
Dry Run: false

Archival Summary:
  Courses processed: 45
  Enrollments frozen: 45
  Content archived: 45

Retention Policies:
  Course content: 365 days
  Assessment data: 1825 days (5 years)
  Meeting recordings: 365 days
  Grade records: Permanent (academic records)

Errors:
  Total errors: 0

=== End Report ===
```

### Example 2: Dry-Run Preview

Preview archival before execution:

```bash
./archive-courses.sh \
    --semester WS2026 \
    --dry-run \
    -v
```

**Output**:

```
[WARN] Running in DRY-RUN mode - no changes will be made
[DEBUG] Semester code validated: WS2026
[DEBUG] [DRY-RUN] Would freeze enrollments for course CS101
[DEBUG] [DRY-RUN] Would archive course CS101 with retention: content=365d, assessment=1825d, recording=365d
```

### Example 3: Extended Retention for Legal Requirements

Extend assessment data retention to 10 years for specific legal requirements:

```bash
./archive-courses.sh \
    --semester WS2026 \
    --assessment-retention-days 3650
```

**Note**: Consult with legal counsel before deviating from standard 5-year retention.

## Troubleshooting

### Invalid Semester Code

**Error**: `Invalid semester code: WS20226`

**Solution**:

- Ensure semester code format is correct: `WSYYYY` or `SSYYYY`
- Example: `WS2026` (Winter 2025/26), `SS2026` (Summer 2026)

### Missing yq Tool

**Warning**: `yq not installed, using default retention values`

**Solution**:

- Install `yq` to load retention config from yaml: `sudo apt install yq` (Debian) or `brew install yq` (macOS)
- Or override retention values via command-line arguments

### No Courses Found

**Warning**: `No courses found for semester WS2026`

**Solution**:

- Verify semester code matches courses in the system
- Check API endpoint is accessible: `curl http://localhost:8080/courses?semester=WS2026`
- Ensure courses have been provisioned for the semester (via campus management integration)

### API Authentication Errors

**Error**: `Unauthorized: Invalid API token`

**Solution**:

- Set API token: `export API_TOKEN=your-token-here`
- Ensure token has `courses:write` scope
- Verify token is not expired

## Security Considerations

### Data Deletion

The script **does not delete data** without explicit confirmation:

- Dry-run mode is the default for testing
- Content is archived, not deleted (moved to cold storage)
- Retention policies ensure compliance with GDPR

### Access Control

The script requires:

- OAuth 2.0 authentication via Keycloak
- Role: `courses:write` scope
- Group membership: `semester-admin` (configured in semester-lifecycle.yaml)

### Audit Trail

Archival operations are logged:

- Timestamp of each operation
- User who initiated archival
- Courses affected
- Retention policies applied

## Related Documentation

- [Semester API Specification](/docs/development/semester-api.md): Course provisioning API endpoints
- [Semester Lifecycle Configuration](/helmfile/environments/default/semester-lifecycle.yaml.gotmpl): Role and retention configuration
- [Campus Management Integration](/docs/integration/campus-management-hooks.md): Enrollment synchronization
- [German Academic Record Regulations](https://www.gesetze-im-internet.de/bap_dsvo/): Legal data retention requirements

## License

SPDX-License-Identifier: Apache-2.0

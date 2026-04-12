<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Semester Automation Guide / Semester-Automatisierungsleitfaden

[English](#english) | [Deutsch](#deutsch)

---

<a name="english"></a>

## English

### Overview

This guide explains how to set up automated semester lifecycle management in openDesk Edu. The automation system uses Kubernetes CronJobs to handle semester transitions, role synchronization, and archival cleanup.

### Prerequisites

- Kubernetes cluster with openDesk Edu deployed
- Helm 3.x installed
- kubectl configured with cluster access
- Semester Provisioning Helm chart installed

### Quick Start

```bash
# Enable automation in values.yaml
cat <<EOF >> helmfile/environments/dev/values.yaml.gotmpl
automation:
  enabled: true
  timezone: "Europe/Berlin"
EOF

# Apply the configuration
helmfile -e dev apply
```

---

## Configuration / Konfiguration

### Helm Values Configuration

Configure automation in `helmfile/apps/semester-provisioning/values.yaml`:

```yaml
automation:
  # Enable automation / Automatisierung aktivieren
  enabled: true

  # Timezone for cron jobs / Zeitzone für Cron-Jobs
  timezone: "Europe/Berlin"

  # Cron schedules / Cron-Zeitpläne
  cron:
    semester_start: "0 6 1 10 *"      # Oct 1st, 6 AM
    mid_semester_check: "0 9 15 * *"   # 15th of each month, 9 AM
    semester_end: "0 6 1 4 *"         # April 1st, 6 AM
    archival_cleanup: "0 2 1 4 *"     # April 1st, 2 AM
    role_sync: "*/15 * * * *"         # Every 15 minutes

  # Job history / Job-Verlauf
  jobs:
    successfulJobsHistoryLimit: 3
    failedJobsHistoryLimit: 1
```

### Semester Calendar Configuration

Define your semester calendar:

```yaml
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
```

---

## CronJobs / CronJobs

### Semester Start Job

**Purpose:** Activates new semester courses and triggers initial enrollment sync.

```yaml
# Runs on October 1st at 6:00 AM
schedule: "0 6 1 10 *"
```

**Actions:**

1. Update semester status to `active`
2. Activate all draft courses for the new semester
3. Trigger initial Keycloak group synchronization
4. Send notification to administrators

### Role Sync Job

**Purpose:** Synchronizes user roles between Keycloak and LMS platforms.

```yaml
# Runs every 15 minutes
schedule: "*/15 * * * *"
```

**Actions:**

1. Fetch current enrollments from database
2. Sync roles to Keycloak groups
3. Update ILIAS/Moodle role assignments
4. Log any sync errors

### Semester End Job

**Purpose:** Triggers archival preparation for ended semester.

```yaml
# Runs on April 1st at 6:00 AM
schedule: "0 6 1 4 *"
```

**Actions:**

1. Mark semester as `ended`
2. Send archival reminders to course instructors
3. Prepare archival job queue
4. Generate semester statistics report

### Archival Cleanup Job

**Purpose:** Archives old courses and cleans up expired data.

```yaml
# Runs on April 1st at 2:00 AM (after archival deadline)
schedule: "0 2 1 4 *"
```

**Actions:**

1. Archive all courses past archival deadline
2. Remove expired temporary enrollments
3. Clean up old Keycloak groups
4. Update retention metrics

---

## Role Mappings / Rollenzuordnungen

Configure role mappings between campus management and LMS:

```yaml
roles:
  enabled: true
  sync_interval_minutes: 15
  sync_on_enrollment_change: true

  mappings:
    - campus_role: "student"
      keycloak_role: "student"
      lms_role: "student"
    - campus_role: "tutor"
      keycloak_role: "tutor"
      lms_role: "tutor"
    - campus_role: "lecturer"
      keycloak_role: "instructor"
      lms_role: "instructor"
    - campus_role: "auditor"
      keycloak_role: "auditor"
      lms_role: "guest"
    - campus_role: "external"
      keycloak_role: "affiliate"
      lms_role: "guest"
```

---

## LMS Integration / LMS-Integration

### ILIAS Configuration

```yaml
ilias:
  enabled: true
  api_url: "https://ilias.example.com/api"
  api_key: "${ILIAS_API_KEY}"
  client_id: "default"
```

### Moodle Configuration

```yaml
moodle:
  enabled: true
  api_url: "https://moodle.example.com/api"
  api_token: "${MOODLE_API_TOKEN}"
```

---

## Monitoring / Überwachung

### Job Status

```bash
# List all CronJobs
kubectl get cronjobs -n opendesk

# Check job history
kubectl logs job/semester-start-12345 -n opendesk

# View job status
kubectl describe cronjob semester-start -n opendesk
```

### Health Checks

```bash
# API health
curl https://semester.example.com/health

# API readiness
curl https://semester.example.com/ready
```

### Alerting Rules

Set up alerts for:

- Failed CronJob executions (> 1 failure)
- API health check failures
- Database connection errors
- LMS sync failures

---

## Troubleshooting / Fehlerbehebung

### CronJob Not Running

```bash
# Check CronJob status
kubectl get cronjob semester-start -n opendesk

# Check if suspended
kubectl get cronjob semester-start -n opendesk -o jsonpath='{.spec.suspend}'

# Manual trigger
kubectl create job --from=cronjob/semester-start manual-trigger -n opendesk
```

### Sync Failures

```bash
# Check role sync logs
kubectl logs -l app=semester-provisioning,component=role-sync -n opendesk

# Verify Keycloak connectivity
kubectl exec -it deployment/semester-provisioning -- curl -v http://keycloak:8080/health
```

### Archive Issues

```bash
# Check archival job status
kubectl get jobs -l app=semester-provisioning,job-type=archival -n opendesk

# Manual archive trigger
curl -X POST "https://semester.example.com/api/v1/archival/bulk-archive" \
  -H "Content-Type: application/json" \
  -d '{"semester_id": "2025ws", "create_snapshots": true}'
```

---

## Best Practices / Best Practices

1. **Test First**: Always use `dry_run: true` for new configurations
2. **Monitor Jobs**: Set up alerts for failed CronJob executions
3. **Backup Data**: Ensure database backups before major transitions
4. **Staged Rollout**: Test automation in dev before production
5. **Documentation**: Keep semester calendar documentation updated

---

## Related Documentation / Verwandte Dokumentation

- [Semester Lifecycle](./semester-lifecycle.md) - User guide
- [Course Provisioning API](./course-provisioning-api.md) - API reference
- [External Services](./external-services.md) - LMS integration
- [Getting Started](./getting-started.md) - Initial setup

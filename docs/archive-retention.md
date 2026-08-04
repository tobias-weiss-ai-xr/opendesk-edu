# Archive Retention Policy

This document defines the retention policy for user archives in openDesk Edu.

## Archive Storage

Archives are stored at:

```
/var/lib/opendesk-archives/
  <username>/
    <service>_<date>/
      service-metadata.json
      exported-data.tar.gz
    <username>_complete_archive_YYYYMMDD_HHMMSS.tar.gz
```

## Retention Periods

| Archive Type | Retention Period | After Retention |
|-------------|------------------|-----------------|
| Student archives | 5 years after exmatriculation | Delete permanently |
| Employee archives | 10 years after termination | Delete permanently |
| Faculty archives | 10 years after retirement | Delete permanently |
| Guest accounts | 1 year after account deactivation | Delete permanently |
| Recording data (BBB) | 3 years from recording date | Delete permanently |
| Course submissions | 10 years from course end | Delete permanently |
| Email data | 10 years after account deletion | Delete permanently |

## Classification

Users are classified based on their `eduPersonAffiliation` attribute:

- **student**: Students enrolled in degree programs
- **employee**: Staff members (administration, IT, facilities)
- **faculty**: Academic staff (professors, lecturers, researchers)
- **staff**: General staff (includes employee)
- **affiliate**: Partner institution collaborators
- **alumni**: Former students

## Automated Cleanup

The archive cleanup job runs weekly via cron:

```bash
# Run weekly archive cleanup (Sunday at 2 AM)
0 2 * * 0 /opt/opendesk-edu/scripts/user_import/cleanup_archives.py >> /var/log/opendesk-archive-cleanup.log 2>&1
```

## Manual Management

### View Archive Status

```bash
# List all archives
python archive_service_user.py --list-all

# Show archive for specific user
python archive_service_user.py --username john.doe --info

# Check retention status
python archive_service_user.py --username john.doe --check-retention
```

### Manual Cleanup

```bash
# Force cleanup of expired archives
python archive_service_user.py --cleanup-expired

# Cleanup specific user archive
python archive_service_user.py --username john.doe --cleanup

# Generate retention report
python archive_service_user.py --retention-report
```

## Legal Considerations

### Data Protection (GDPR)

- Archives must be accessible to data subjects upon request
- Users have the right to request deletion of personal data (with legal exceptions)
- Backup/archived data for tax/law must be retained for statutory period

### Academic Freedom

- Faculty research data may have longer retention periods
- Course materials should be retained for quality assurance
- Student work requires retention for plagiarism detection

### Audit Requirements

- All archive actions must be logged
- Archive deletion decisions must be documented
- Retention policy exceptions require written authorization

## Storage Optimization

### Compression

All archives are compressed using gzip (`tar.gz`).

### Deduplication

When storage is limited, consider deduplication:

```bash
# Use rdiff-backup for deduplicated backups
apt install rdiff-backup
rdiff-backup /var/lib/opendesk-archives /backup/opendesk-archives-dedup
```

### Offsite Backup

For disaster recovery, consider offsite backup:

```bash
# Copy archives to remote storage
rsync -avz /var/lib/opendesk-archives backup-server:/backups/opendesk/
```

## Monitoring

### Disk Usage Monitor

```bash
# Check archive disk usage
python archive_service_user.py --disk-usage

# Set up alerts for low disk space
python archive_service_user.py --alert-threshold 90
```

### Archive Integrity Check

```bash
# Verify archive integrity
python archive_service_user.py --verify-all
```

## Recovery

### Restore from Archive

```bash
# Restore specific service data
python archive_service_user.py --restore-service --username john.doe --service ilias

# Restore complete user archive
python archive_service_user.py --restore-all --username john.doe
```

## Troubleshooting

### Archive Not Found

If user archive is missing:

1. Check `/var/log/opendesk-archive.log` for errors
2. Verify archive retention period
3. Check if archive was manually deleted
4. Check if username was changed

### Corrupted Archive

If archive is corrupted:

1. Try extracting with verbose output: `tar -xzf archive.tar.gz -v`
2. Check disk for errors: `fsck /var/lib/opendesk-archives`
3. Restore from offsite backup if available

### Insufficient Permissions

If cleanup fails due to permissions:

```bash
# Fix permissions
chown -R opendesk:opendesk /var/lib/opendesk-archives
chmod -R 700 /var/lib/opendesk-archives/*
```

## Configuration

Retention periods can be customized via environment variables:

```bash
# Archive retention periods (in days)
ARCHIVE_RETENTION_STUDENT=1825  # 5 years
ARCHIVE_RETENTION_EMPLOYEE=3650  # 10 years
ARCHIVE_RETENTION_FACULTY=3650  # 10 years
ARCHIVE_RETENTION_GUEST=365  # 1 year
ARCHIVE_RETENTION_RECORDINGS=1095  # 3 years
ARCHIVE_RETENTION_SUBMISSIONS=3650  # 10 years
```

## Support

For archive-related issues:

1. Check `/var/log/opendesk-archive.log` and `/var/log/opendesk-user-deprovisioning.log`
2. Verify archive directory permissions
3. Ensure sufficient disk space
4. Check script execution with `--dry-run`

Contact the infrastructure team for assistance.

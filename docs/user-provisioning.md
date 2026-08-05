# User Provisioning & Deprovisioning

## Overview

This guide covers automated user lifecycle management for openDesk Edu, including account creation, role assignment, and secure removal using LDAP federation and Keycloak admin APIs.

## Architecture

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   HISinOne   │    │  University  │    │   Keycloak   │    │  openDesk    │
│              │    │  LDAP/AD     │    │              │    │   Edu Apps   │
│              │    │              │    │              │    │              │
│  SOAP API    │───►│  User        │───►│  LDAP Fed.   │───►│  ILIAS       │
│  Events      │    │  Store       │    │  + Admin API │    │  Moodle      │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
```

## Prerequisites

### Required Tools

- Python 3.12+
- Keycloak Admin CLI (`kcadm`)
- Access to university LDAP/Active Directory
- Keycloak admin credentials
- (Optional) HISinOne API access

### Setup

```bash
# Clone the provisioning tool
cd scripts/user_import

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
nano .env
```

## Configuration

### Environment Variables

Create `.env` in `scripts/user_import/`:

```bash
# Keycloak Configuration
KEYCLOAK_URL=https://yourdomain.de/auth
KEYCLOAK_REALM=opendesk
KEYCLOAK_ADMIN_USERNAME=admin
KEYCLOAK_ADMIN_PASSWORD=your-admin-password

# LDAP Configuration
LDAP_SERVER=ldap://ldap.yourinstitution.de
LDAP_BASE_DN=dc=institution,dc=de
LDAP_BIND_DN=cn=admin,dc=institution,dc=de
LDAP_BIND_PASSWORD=ldap-bind-password

# User Mapping
LDAP_USER_SEARCH_BASE=ou=users,dc=institution,dc=de
LDAP_USER_OBJECT_CLASS=inetOrgPerson
LDAP_USERNAME_ATTR=uid
LDAP_EMAIL_ATTR=mail
LDAP_FIRST_NAME_ATTR=givenName
LDAP_LAST_NAME_ATTR=sn

# HISinOne Configuration (Optional)
HISINONE_URL=https://hisinone.yourinstitution.de/qisserver/services2
HISINONE_API_KEY=your-hisinone-api-key

# Provisioning Options
DRY_RUN=true
LOG_LEVEL=INFO
```

## User Provisioning

### Automatic LDAP User Sync

```bash
cd scripts/user_import

# Sync all users from LDAP
python sync_users.py --source ldap --auto-sync

# Sync only active students
python sync_users.py --source ldap --filter "(eduPersonAffiliation=student)"

# Dry run to see what would happen
python sync_users.py --source ldap --dry-run
```

### HISinOne Event-Based Provisioning

HISinOne integration is handled via the semester provisioning API. See `docs/semester-lifecycle-management.md` for details on semester-based course and enrollment management.

### Manual User Creation

```bash
# Create users from CSV/ODS input
python provision.py \
  --input-file users.csv \
  --dry-run

# Import users from LDAP/UCS
python provision.py \
  --source ucs \
  --csv-separator ','
```

## Role Assignment

### Role Mapping Configuration

Define role mappings in `config/roles.json`:

```json
{
  "roles": {
    "student": {
      "description": "Student access",
      "roles": ["student"],
      "groups": ["students"],
      "affiliation": "student",
      "services": ["ilias", "moodle", "bbb", "files"]
    },
    "employee": {
      "description": "Employee access",
      "roles": ["employee"],
      "groups": ["staff"],
      "affiliation": "employee",
      "services": ["email", "groupware", "files", "wiki"]
    },
    "faculty": {
      "description": "Faculty access",
      "roles": ["faculty", "employee"],
      "groups": ["faculty", "staff"],
      "affiliation": "faculty",
      "services": ["ilias", "moodle", "bbb", "email", "groupware", "wiki"]
    },
    "lecturer": {
      "description": "Lecturer access",
      "roles": ["lecturer", "employee"],
      "groups": ["lecturers", "staff"],
      "affiliation": "faculty",
      "services": ["ilias", "moodle", "bbb", "recording", "grades"]
    }
  },
  "mappings": {
    "student": "student",
    "employee": "employee",
    "faculty": "faculty",
    "staff": "employee",
    "prof": "faculty",
    "dozent": "lecturer"
  }
}
```

### Assign Roles

Roles are assigned automatically based on LDAP attributes and configured in `config/roles.json`. See the Role Mapping Configuration section above for details on how roles are mapped to group memberships and service access.

For custom role assignments, modify the role mapping in `config/roles.json` and re-run the sync:

```bash
# Sync users with updated role mappings
python sync_users.py --source ldap --auto-sync
```

## User Deprovisioning

### Two-Phase Deprovisioning

Phase 1 (Disable):

```bash
# Disable user access (grace period)
python deprovision_user.py \
  --username john.doe \
  --phase disable \
  --grace-period-days 180

# Disable all students who haven't re-registered
python deprovision_user.py \
  --filter "(eduPersonAffiliation=student)" \
  --phase disable \
  --no-ruckmeldung-since 2026-01-15
```

Phase 2 (Permanent Delete):

```bash
# Permanent delete after grace period
python deprovision_user.py \
  --username john.doe \
  --phase delete

# Batch delete users in grace period expired
python deprovision_user.py \
  --phase delete \
  --grace-expired-before 2025-04-06
```

### Bulk Operations

```bash
# Deprovision a batch of students
python deprovision_user.py \
  --phase disable \
  --input-file students-to-archive.csv

# Delete users permanently (after confirmation)
python deprovision_user.py \
  --phase delete \
  --input-file users-to-delete.csv \
  --confirm
```

## SAML Account Linking

When using SAML federation (DFN-AAI), SAML identity linking is handled automatically by the Keycloak admin API integration in `lib/keycloak.py`. The `deprovision_disable.py` script includes SAML identity removal when disabling users.

For manual SAML identity management, use the Keycloak admin API directly:

```bash
# Use Keycloak admin CLI
kcadm.sh get users -r opendesk
kcadm.sh get users/<user-id>/federated-identity/<identity-provider> -r opendesk
```

## Scheduling Automated Sync

### Systemd Timer

Create `/etc/systemd/system/opendesk-user-sync.service`:

```ini
[Unit]
Description=openDesk Edu User Sync
After=network.target

[Service]
Type=simple
User=opendesk
WorkingDirectory=/opt/opendesk-edu/scripts/user_import
ExecStart=/usr/bin/python3 sync_users.py --source ldap --auto-sync
Environment=PYTHONUNBUFFERED=1
Restart=always
```

Create `/etc/systemd/system/opendesk-user-sync.timer`:

```ini
[Unit]
Description=openDesk Edu User Sync Timer

[Timer]
OnBootSec=10min
OnUnitActiveSec=1h

[Install]
WantedBy=timers.target
```

```bash
# Enable and start
sudo systemctl enable opendesk-user-sync.timer
sudo systemctl start opendesk-user-sync.timer

# Check status
sudo systemctl status opendesk-user-sync.timer
```

### Cron Job

```bash
# Add to crontab
crontab -e

# Run every hour
0 * * * * /opt/opendesk-edu/scripts/user_import/sync_users.py --source ldap --auto-sync >> /var/log/opendesk-user-sync.log 2>&1
```

## Monitoring & Logging

### Log Files

- `/var/log/opendesk-user-sync.log` - Main sync log (from sync_users.py)
- `/var/log/opendesk-user-provisioning.log` - Provisioning events (from provision.py)
- `/var/log/opendesk-user-deprovisioning.log` - Deprovisioning events (from deprovision_user.py)

Monitor logs directly using standard tools:

```bash
# View recent sync activity
tail -f /var/log/opendesk-user-sync.log

# Check failed syncs
grep ERROR /var/log/opendesk-user-sync.log

# Sync statistics
grep "Synced" /var/log/opendesk-user-sync.log | wc -l
```

## Troubleshooting

### LDAP Connection Issues

Test LDAP connectivity using standard tools:

```bash
# Test LDAP connectivity
ldapsearch -H ldap://ldap.yourinstitution.de -x -D "cn=admin,dc=institution,dc=de" -W -b "dc=institution,dc=de"

# Check if sync can connect
python sync_users.py --source ldap --dry-run

# Check for connection errors
grep "LDAP connection failed" /var/log/opendesk-user-sync.log
```

### Keycloak Admin API Issues

Test Keycloak connection using the admin CLI:

```bash
# Test Keycloak connection
kcadm.sh config credentials --server https://yourdomain.de/auth --realm master --user admin

# Check admin credentials
kcadm.sh get users -r opendesk --max 1

# Test if provision.py can connect
python provision.py --dry-run --help
```

### Sync Failures

```bash
# Run sync with verbose logging
python sync_users.py --source ldap --debug

# Check for errors in logs
tail -f /var/log/opendesk-user-sync.log

# Validate CSV input format before running provision.py
head -n 5 users.csv
```

## Security Considerations

### Credentials

- Store all credentials in environment variables, not in code
- Use Keycloak service accounts for automation
- Rotate admin credentials regularly
- Use least privilege principle

### Logging

- Log all provisioning/deprovisioning actions
- Mask sensitive data in logs (passwords, tokens)
- Retain logs for audit purposes (90+ days)
- Monitor for unauthorized access attempts

### Data Protection

- Follow GDPR for personal data
- Implement data minimization
- Provide user consent for data processing
- Allow users to request data export/deletion

## Maintenance

### Regular Tasks

1. **Weekly**: Review sync logs for errors
2. **Monthly**: Check LDAP attribute changes
3. **Quarterly**: Review role mappings
4. **Annually**: Audit user accounts, clean up inactive users

### Backup & Restore

User data is stored in Keycloak and UCS. Use their native backup/restore tools:

```bash
# Export Keycloak realm configuration (includes users)
/opt/keycloak/bin/kcadm.sh export --realm opendesk --dir /backup/keycloak

# Backup UCS/UDM
udm-cli backup --output /backup/ucs/

# Restore from Keycloak backup
/opt/keycloak/bin/kcadm.sh import --dir /backup/keycloak --realm opendesk
```

## Documentation

- [Keycloak Admin Guide](https://www.keycloak.org/docs/latest/server_admin/)
- [LDAP Federation](https://www.keycloak.org/docs/latest/server_admin/index.html#_user-stored-federation)
- [HISinOne API](https://www.his.de/fileadmin/user_upload/his/media/services/technologie/Dokumentation/WebServices/WS_Dokumentation.pdf)

## Support

For provisioning-specific issues, open an issue on GitHub.

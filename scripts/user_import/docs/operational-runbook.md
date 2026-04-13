<!---
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

# Operational Runbook / Betriebsanleitung

# openDesk User Import Tools — Operational Runbook

This runbook covers day-to-day operations for the openDesk Edu user
provisioning system: provisioning, deprovisioning, LDAP sync, and archival.

---

## Table of Contents / Inhaltsverzeichnis

1. [Overview / Übersicht](#1-overview--übersicht)
2. [Prerequisites / Voraussetzungen](#2-prerequisites--voraussetzungen)
3. [First-Time Setup / Ersteinrichtung](#3-first-time-setup--ersteinrichtung)
4. [Docker Deployment / Docker-Einsatz](#4-docker-deployment--docker-einsatz)
5. [Scheduled Operations / Geplante Vorgänge](#5-scheduled-operations--geplante-vorgänge)
6. [Environment Variables Reference / Umgebungsvariablen](#6-environment-variables-reference--umgebungsvariablen)
7. [Troubleshooting / Fehlerbehebung](#7-troubleshooting--fehlerbehebung)
8. [Monitoring / Überwachung](#8-monitoring--überwachung)
9. [Backup & Recovery / Sicherung & Wiederherstellung](#9-backup--recovery--sicherung--wiederherstellung)
10. [Security Considerations / Sicherheitshinweise](#10-security-considerations--sicherheitshinweise)
11. [Rollback / Zurücksetzen](#11-rollback--zurücksetzen)

---

## 1. Overview / Übersicht

**English:**
The openDesk User Import Tools manage the full user lifecycle in openDesk
environments:

- **Provisioning** (`provision.py`) — Create users from ODS/XLSX/CSV files or
  the IAM API into UCS via UDM REST API, then link SAML identities in
  Keycloak.
- **Deprovisioning — Phase 1** (`deprovision_disable.py`) — Disable users who
  are no longer present in the IAM API, remove SAML identities and group
  memberships.
- **Deprovisioning — Phase 2** (`deprovision_delete.py`) — Permanently delete
  users who have been disabled beyond the grace period.
- **Single-user deprovision** (`deprovision_user.py`) — Disable or delete an
  individual user on demand.
- **LDAP Sync** (`sync_users.py`) — Synchronize users from an institutional
  LDAP directory to Keycloak with automatic role assignment.
- **Archive** (`archive_service_user.py`) — Archive a user's data from
  connected services (ILIAS, Moodle, etc.) before deletion.

**Architecture:**

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  IAM API     │────▶│  UCS UDM     │────▶│  Keycloak    │
│  (user data) │     │  REST API    │     │  (SAML IdP)  │
└──────────────┘     └──────────────┘     └──────────────┘
                            ▲
┌──────────────┐           │
│  LDAP        │───────────┘
│  Directory   │
└──────────────┘
```

**Deutsch:**
Die openDesk User Import Tools verwalten den vollständigen Benutzerlebenszyklus
in openDesk-Umgebungen:

- **Bereitstellung** (`provision.py`) — Benutzer aus ODS/XLSX/CSV-Dateien
  oder der IAM-API in UCS über die UDM-REST-API erstellen und
  SAML-Identitäten in Keycloak verknüpfen.
- **Stilllegung — Phase 1** (`deprovision_disable.py`) — Benutzer
  deaktivieren, die nicht mehr in der IAM-API vorhanden sind.
- **Stilllegung — Phase 2** (`deprovision_delete.py`) — Benutzer
  endgültig löschen, die die Karenzzeit überschritten haben.
- **Einzelbenutzer-Stilllegung** (`deprovision_user.py`) — Einen
  einzelnen Benutzer bei Bedarf deaktivieren oder löschen.
- **LDAP-Synchronisierung** (`sync_users.py`) — Benutzer aus einem
  institutionellen LDAP-Verzeichnis mit automatischer Rollenzuweisung
  nach Keycloak synchronisieren.
- **Archivierung** (`archive_service_user.py`) — Benutzerdaten aus
  verbundenen Diensten archivieren.

---

## 2. Prerequisites / Voraussetzungen

| Requirement / Anforderung | Details |
|---|---|
| **Docker** | Docker Engine 20.10+ or Podman 3.0+ |
| **UCS** | Univention Corporate Server with UDM REST API enabled |
| **Keycloak** | Admin credentials for SAML identity linking |
| **IAM API** | Endpoint URL and access (for deprovisioning) |
| **LDAP** | Server, bind DN, and password (for sync) |
| **Network** | Container must reach UCS, Keycloak, LDAP, and IAM API |

### Required Credentials / Erforderliche Zugangsdaten

| Credential | Environment Variable | Notes |
|---|---|---|
| UDM API Password | `UDM_API_PASSWORD` | UCS Administrator password |
| Keycloak Admin Password | `KEYCLOAK_API_PASSWORD` | For SAML identity linking |
| LDAP Bind Password | `LDAP_BIND_PASSWORD` | For LDAP sync |
| IAM API (optional) | `IAM_API_URL` | For deprovisioning checks |

---

## 3. First-Time Setup / Ersteinrichtung

### Step 1: Build the Docker Image / Docker-Image erstellen

```bash
cd scripts/user_import
docker build -t opendesk-user-import:latest .
```

### Step 2: Prepare Environment / Umgebung vorbereiten

Copy the example environment file and fill in your values:

```bash
cp .env.example .env
# Edit .env with your institution's values
```

At minimum, configure:

```bash
IMPORT_DOMAIN=your-institution.de
UDM_API_PASSWORD=your-ucs-admin-password
KEYCLOAK_URL=https://id.your-institution.de
KEYCLOAK_API_PASSWORD=your-keycloak-admin-password
```

### Step 3: Verify Connectivity / Verbindung prüfen

Run a dry-run provisioning to verify UCS and Keycloak are reachable:

```bash
docker run --rm \
  --env-file .env \
  -e COMMAND=provision \
  -e DRY_RUN=true \
  -e LOGLEVEL=DEBUG \
  opendesk-user-import:latest
```

### Step 4: First Provisioning / Erste Bereitstellung

```bash
docker run --rm \
  --env-file .env \
  -e COMMAND=provision \
  -e IMPORT_FILENAME=/data/users.ods \
  -v /path/to/your/users.ods:/data/users.ods:ro \
  opendesk-user-import:latest
```

---

## 4. Docker Deployment / Docker-Einsatz

All operations use the `COMMAND` environment variable to select the script.
Additional arguments are passed as environment variables (see [Section 6](#6-environment-variables-reference--umgebungsvariablen)).

### Supported Commands / Unterstützte Befehle

| Command | Script | Purpose |
|---|---|---|
| `provision` | `provision.py` | Create users from file or IAM API |
| `disable` | `deprovision_disable.py` | Phase 1: disable users not in IAM |
| `delete` | `deprovision_delete.py` | Phase 2: permanently delete after grace period |
| `deprovision` | `deprovision_user.py` | Disable or delete a single user |
| `sync` | `sync_users.py` | Sync users from LDAP to Keycloak |
| `archive` | `archive_service_user.py` | Archive user data from services |
| `help` | — | Show available commands |

### Provisioning / Bereitstellung

```bash
docker run --rm \
  -e COMMAND=provision \
  -e IMPORT_DOMAIN=example.com \
  -e UDM_API_PASSWORD=secret \
  -e KEYCLOAK_URL=https://id.example.com \
  -e KEYCLOAK_API_PASSWORD=keycloak-secret \
  -e IMPORT_FILENAME=/data/users.ods \
  -v /path/to/users.ods:/data/users.ods:ro \
  opendesk-user-import:latest
```

#### With IAM API Source

```bash
docker run --rm \
  -e COMMAND=provision \
  -e IMPORT_DOMAIN=example.com \
  -e UDM_API_PASSWORD=secret \
  -e IAM_API_URL=https://iam-api.example.com/openDesk/v1.0/openDesk_account \
  opendesk-user-import:latest
```

### Deprovisioning — Phase 1: Disable / Stilllegung — Phase 1: Deaktivieren

```bash
docker run --rm \
  -e COMMAND=disable \
  -e IMPORT_DOMAIN=example.com \
  -e UDM_API_PASSWORD=secret \
  -e KEYCLOAK_API_PASSWORD=keycloak-secret \
  -e IAM_API_URL=https://iam-api.example.com/openDesk/v1.0/openDesk_account_depro \
  -e DRY_RUN=true \
  opendesk-user-import:latest
```

> **⚠️ Important / Wichtig:** Always run with `DRY_RUN=true` first to preview
> changes. Remove `DRY_RUN=true` only after reviewing the output.

### Deprovisioning — Phase 2: Delete / Stilllegung — Phase 2: Löschen

```bash
docker run --rm \
  -e COMMAND=delete \
  -e IMPORT_DOMAIN=example.com \
  -e UDM_API_PASSWORD=secret \
  -e GRACE_PERIOD_MONTHS=12 \
  opendesk-user-import:latest
```

### Single User Deprovision / Einzelbenutzer-Stilllegung

```bash
docker run --rm \
  -e COMMAND=deprovision \
  -e USER=john.doe \
  opendesk-user-import:latest --phase disable --reason "Left institution"
```

```bash
docker run --rm \
  -e COMMAND=deprovision \
  -e USER=john.doe \
  opendesk-user-import:latest --phase delete
```

### LDAP Sync / LDAP-Synchronisierung

```bash
docker run --rm \
  -e COMMAND=sync \
  -e LDAP_SERVER=ldap://ldap.example.de \
  -e LDAP_BASE_DN=dc=example,dc=de \
  -e LDAP_BIND_DN=cn=admin,dc=example,dc=de \
  -e LDAP_BIND_PASSWORD=secret \
  opendesk-user-import:latest
```

#### Sync Specific User Groups / Bestimmte Benutzergruppen synchronisieren

```bash
docker run --rm \
  -e COMMAND=sync \
  -e LDAP_SERVER=ldap://ldap.example.de \
  -e LDAP_BASE_DN=dc=example,dc=de \
  -e LDAP_BIND_DN=cn=admin,dc=example,dc=de \
  -e LDAP_BIND_PASSWORD=secret \
  opendesk-user-import:latest \
    --source ldap \
    --filter "(eduPersonAffiliation=student)" \
    --auto-assign-roles
```

### Archive User Data / Benutzerdaten archivieren

```bash
docker run --rm \
  -e COMMAND=archive \
  -e USER=jane.doe \
  -v /var/lib/opendesk-archives:/archives:rw \
  opendesk-user-import:latest --all
```

### Using an Env File / Umgebungsdatei verwenden

For convenience, store credentials in a `.env` file (never commit this):

```bash
docker run --rm \
  --env-file /path/to/opendesk.env \
  -e COMMAND=provision \
  -e IMPORT_FILENAME=/data/users.ods \
  -v /path/to/users.ods:/data/users.ods:ro \
  opendesk-user-import:latest
```

---

## 5. Scheduled Operations / Geplante Vorgänge

### Recommended Schedule / Empfohlener Zeitplan

| Operation / Vorgang | Frequency / Häufigkeit | Time / Uhrzeit |
|---|---|---|
| LDAP → Keycloak Sync | Daily / Täglich | 06:00 |
| Deprovision Disable (dry-run) | Weekly / Wöchentlich | Monday 08:00 |
| Deprovision Disable (live) | Monthly / Monatlich | 1st Monday 09:00 |
| Permanent Delete | Quarterly / Vierteljährlich | 1st of Jan/Apr/Jul/Oct |
| Archive Cleanup | Monthly / Monatlich | Last day 23:00 |

### Example Crontab / Beispiel-Crontab

Add to the crontab of a service account with Docker access:

```cron
# openDesk Edu User Provisioning — Scheduled Operations
# ======================================================

# Daily LDAP sync (06:00)
0 6 * * * docker run --rm --env-file /etc/opendesk/provisioning.env -e COMMAND=sync opendesk-user-import:latest >> /var/log/opendesk-cron.log 2>&1

# Weekly deprovision check — dry-run only (Monday 08:00)
0 8 * * 1 docker run --rm --env-file /etc/opendesk/provisioning.env -e COMMAND=disable -e DRY_RUN=true opendesk-user-import:latest >> /var/log/opendesk-cron.log 2>&1

# Monthly deprovision disable — live (1st Monday 09:00)
0 9 1-7 * 1 docker run --rm --env-file /etc/opendesk/provisioning.env -e COMMAND=disable opendesk-user-import:latest >> /var/log/opendesk-cron.log 2>&1

# Quarterly permanent deletion (Jan 1, Apr 1, Jul 1, Oct 1 at 03:00)
0 3 1 1,4,7,10 * docker run --rm --env-file /etc/opendesk/provisioning.env -e COMMAND=delete -e GRACE_PERIOD_MONTHS=12 opendesk-user-import:latest >> /var/log/opendesk-cron.log 2>&1

# Monthly archive cleanup (last day of month 23:00)
0 23 28-31 * * [ "$(date -d '+1 day' +\%d)" = "01" ] && docker run --rm --env-file /etc/opendesk/provisioning.env -e COMMAND=archive opendesk-user-import:latest --cleanup --days 90 >> /var/log/opendesk-cron.log 2>&1
```

### Systemd Timer Alternative / Systemd-Timer-Alternative

Create `/etc/systemd/system/opendesk-user-sync.service`:

```ini
[Unit]
Description=openDesk Edu User Sync
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/docker run --rm --env-file /etc/opendesk/provisioning.env -e COMMAND=sync opendesk-user-import:latest
StandardOutput=journal
StandardError=journal
```

Create `/etc/systemd/system/opendesk-user-sync.timer`:

```ini
[Unit]
Description=Run openDesk Edu User Sync daily

[Timer]
OnCalendar=*-*-* 06:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
systemctl daemon-reload
systemctl enable --now opendesk-user-sync.timer
```

---

## 6. Environment Variables Reference / Umgebungsvariablen

### Common / Allgemein

| Variable | Required | Default | Description |
|---|---|---|---|
| `IMPORT_DOMAIN` | Yes | — | openDesk domain (without portal. prefix) |
| `IMPORT_MAILDOMAIN` | No | `IMPORT_DOMAIN` | Mail domain for user accounts |
| `UDM_API_USERNAME` | No | `Administrator` | UDM REST API username |
| `UDM_API_PASSWORD` | Yes | — | UDM REST API password |
| `KEYCLOAK_URL` | No | `https://id.{domain}` | Keycloak base URL |
| `KEYCLOAK_API_USERNAME` | No | `admin` | Keycloak admin username |
| `KEYCLOAK_API_PASSWORD` | Conditional | — | Keycloak admin password |
| `IDENTITY_PROVIDER` | No | `saml-umr` | Keycloak identity provider alias |
| `IAM_API_URL` | No | — | IAM API endpoint for user data |
| `VERIFY_CERTIFICATE` | No | `true` | Verify SSL certificates |
| `ENFORCE_IPV4` | No | `false` | Force IPv4 communication |
| `LOGLEVEL` | No | `INFO` | Logging level (DEBUG, INFO, WARNING, ERROR) |
| `LOGPATH` | No | `./logs` | Log file directory |
| `DRY_RUN` | No | `false` | Log actions without making changes |

### Provisioning / Bereitstellung

| Variable | Default | Description |
|---|---|---|
| `IMPORT_FILENAME` | — | File with user data (ODS/XLSX/CSV) |
| `CREATE_ADMIN_ACCOUNTS` | `false` | Create -admin accounts for each user |
| `CREATE_MAILDOMAINS` | `false` | Auto-create mail domains |
| `CREATE_OXCONTEXT` | `false` | Auto-create OX contexts |
| `IMPORT_USE_IMAGES` | `false` | Assign random profile pictures |
| `IMPORT_RANDOM_AMOUNT` | `10` | Number of random users to create |
| `RECONCILE_GROUPS` | `false` | Reconcile user groups to match input |
| `SET_DEFAULT_PASSWORD` | — | Default password for new accounts |
| `TRIGGER_INVITATION_MAIL` | `false` | Send invitation emails |

### Deprovisioning / Stilllegung

| Variable | Default | Description |
|---|---|---|
| `GRACE_PERIOD_MONTHS` | `12` | Months before permanent deletion |
| `GRACE_PERIOD_DAYS` | `180` | Days before permanent deletion (alternative) |

### LDAP Sync / LDAP-Synchronisierung

| Variable | Default | Description |
|---|---|---|
| `LDAP_SERVER` | — | LDAP server URL (ldap:// or ldaps://) |
| `LDAP_BASE_DN` | — | LDAP base distinguished name |
| `LDAP_BIND_DN` | — | LDAP bind DN |
| `LDAP_BIND_PASSWORD` | — | LDAP bind password |
| `LDAP_USER_SEARCH_BASE` | — | Base DN for user searches |
| `LDAP_USER_OBJECT_CLASS` | `inetOrgPerson` | LDAP object class for users |
| `LDAP_USERNAME_ATTR` | `uid` | Attribute for username |
| `LDAP_EMAIL_ATTR` | `mail` | Attribute for email |
| `LDAP_FIRST_NAME_ATTR` | `givenName` | Attribute for first name |
| `LDAP_LAST_NAME_ATTR` | `sn` | Attribute for last name |

### Keycloak / Keycloak

| Variable | Default | Description |
|---|---|---|
| `KEYCLOAK_REALM` | `opendesk` | Keycloak realm |
| `KEYCLOAK_ADMIN_USERNAME` | `admin` | Keycloak admin username |
| `KEYCLOAK_ADMIN_PASSWORD` | — | Keycloak admin password |

---

## 7. Troubleshooting / Fehlerbehebung

### UCS Connection Refused / UCS-Verbindung abgelehnt

**Symptom:**
```
requests.exceptions.ConnectionError: Failed to establish a connection to https://ucs.example.com/univention/udm/
```

**Causes / Ursachen:**
1. UCS server is unreachable from the Docker container
2. UDM REST API is not enabled on UCS
3. Firewall blocking the connection

**Resolution / Lösung:**
```bash
# Test connectivity from the host first
curl -k https://ucs.example.com/univention/udm/

# If using Docker, ensure the container can reach the UCS host
docker run --rm --network host curlimages/curl -k https://ucs.example.com/univention/udm/

# Check if UDM REST API is enabled in UCS
# → UCS → Domain → UDM Module → HTTP API
```

### Keycloak Admin API 401 Unauthorized

**Symptom:**
```
KeycloakError: 401: Unauthorized
```

**Causes / Ursachen:**
1. Wrong `KEYCLOAK_API_PASSWORD`
2. Admin user disabled or locked
3. Wrong `KEYCLOAK_URL` (must not include `/auth` suffix in newer Keycloak versions)

**Resolution / Lösung:**
```bash
# Verify credentials directly
curl -X POST https://id.example.com/realms/opendesk/protocol/openid-connect/token \
  -d "client_id=admin-cli" \
  -d "username=admin" \
  -d "password=your-password" \
  -d "grant_type=password"

# For Keycloak 17+, use this URL format:
# https://id.example.com/realms/master/protocol/openid-connect/token
```

### SAML Identity Linking Failures / SAML-Identitätsverknüpfung fehlgeschlagen

**Symptom:**
```
Failed to link SAML identity for user john.doe: Identity provider 'saml-umr' not found
```

**Causes / Ursachen:**
1. Identity provider alias does not match (`IDENTITY_PROVIDER` setting)
2. User does not exist in the IdP
3. Keycloak federation configuration issue

**Resolution / Lösung:**
```bash
# List configured identity providers in Keycloak
docker run --rm \
  -e COMMAND=sync \
  -e KEYCLOAK_URL=https://id.example.com \
  -e KEYCLOAK_API_PASSWORD=secret \
  opendesk-user-import:latest --list-idps

# Verify the identity provider alias matches your IdP configuration
# Check: Keycloak Admin → Realm Settings → Identity Providers
```

### Certificate Verification Errors / Zertifikatsfehler

**Symptom:**
```
requests.exceptions.SSLError: certificate verify failed
```

**Causes / Ursachen:**
1. Self-signed certificates not trusted in the container
2. Expired certificates
3. Certificate chain incomplete

**Resolution / Lösung:**
```bash
# Option A: Mount custom CA certificates (recommended)
docker run --rm \
  -v /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro \
  -e VERIFY_CERTIFICATE=true \
  ... opendesk-user-import:latest

# Option B: Disable verification (development only, never in production)
docker run --rm \
  -e VERIFY_CERTIFICATE=false \
  ... opendesk-user-import:latest
```

### Large Imports Timing Out / Große Importe zeitüberschreitung

**Symptom:**
```
TimeoutError: Request timed out after 30 seconds
```

**Resolution / Lösung:**
```bash
# Split large files into smaller batches
# Process users in chunks of ~500

# Increase timeout by setting environment variable
docker run --rm \
  -e REQUESTS_TIMEOUT=120 \
  ... opendesk-user-import:latest
```

### LDAP Sync Returns No Users / LDAP-Sync liefert keine Benutzer

**Symptom:**
```
INFO: Found 0 users in LDAP
```

**Resolution / Lösung:**
```bash
# Verify LDAP connectivity and bind
docker run --rm \
  -e COMMAND=sync \
  -e LDAP_SERVER=ldap://ldap.example.de \
  -e LDAP_BASE_DN=dc=example,dc=de \
  -e LDAP_BIND_DN=cn=admin,dc=example,dc=de \
  -e LDAP_BIND_PASSWORD=secret \
  -e LOGLEVEL=DEBUG \
  opendesk-user-import:latest --dry-run

# Check search base and filter
# Common issue: wrong LDAP_USER_SEARCH_BASE
```

---

## 8. Monitoring / Überwachung

### Log Locations / Protokollspeicherorte

| Log | Location / Pfad |
|---|---|
| Docker container stdout | `docker logs <container-id>` |
| LDAP Sync | `/var/log/opendesk-user-sync.log` (on host) |
| Deprovisioning | `/var/log/opendesk-user-deprovisioning.log` (on host) |
| Service Archiver | `/var/log/opendesk-service-archiver.log` (on host) |
| Cron output | `/var/log/opendesk-cron.log` |

To persist logs, mount a log directory:

```bash
docker run --rm \
  -v /var/log/opendesk:/var/log/opendesk:rw \
  ... opendesk-user-import:latest
```

### Key Metrics to Monitor / Wichtige Kennzahlen

| Metric | How to Check / Prüfung |
|---|---|
| Total active users | UCS Admin Console → Users, or sync with `--dry-run` |
| Users pending deletion | `deprovision_delete.py --dry-run` output |
| Sync success/failure rate | Check cron log for errors |
| LDAP connectivity | `sync_users.py --dry-run` (should list user count) |
| Disk usage of archives | `du -sh /var/lib/opendesk-archives/` |

### Health Check Commands / Integritätsprüfungen

```bash
# Quick connectivity check (all services)
docker run --rm \
  --env-file /etc/opendesk/provisioning.env \
  -e COMMAND=provision \
  -e DRY_RUN=true \
  -e LOGLEVEL=WARNING \
  opendesk-user-import:latest 2>&1 | tail -5

# LDAP sync test
docker run --rm \
  --env-file /etc/opendesk/provisioning.env \
  -e COMMAND=sync \
  opendesk-user-import:latest --dry-run 2>&1 | grep "Found.*users"

# Count users pending deletion
docker run --rm \
  --env-file /etc/opendesk/provisioning.env \
  -e COMMAND=delete \
  -e DRY_RUN=true \
  opendesk-user-import:latest 2>&1 | grep -c "Would delete"
```

### Using Makefile Targets / Makefile-Ziele nutzen

The included Makefile provides monitoring helpers (run on the host with
Python installed):

```bash
make monitor    # Show provisioning statistics
make status     # Show status of all components (Keycloak, LDAP, disk)
```

---

## 9. Backup & Recovery / Sicherung & Wiederherstellung

### Create Backup / Sicherung erstellen

```bash
# Backup provisioning data
make backup

# Backup everything (provisioning data + archives)
make backup-all

# Specify custom backup location
BACKUP_DIR=/mnt/backups/opendesk make backup
```

### Restore from Backup / Aus Sicherung wiederherstellen

```bash
# Restore from a specific backup file
make restore FILE=/var/lib/opendesk-backups/provisioning_20260413_100000.tar.gz
```

### Docker-based Backup / Docker-basierte Sicherung

```bash
# Export current user data from UCS before changes
docker run --rm \
  -e COMMAND=provision \
  -e IMPORT_DOMAIN=example.com \
  -e UDM_API_PASSWORD=secret \
  -e DRY_RUN=true \
  -e LOGLEVEL=DEBUG \
  opendesk-user-import:latest > /backups/user-state-$(date +%Y%m%d).log 2>&1
```

### Archive Management / Archivverwaltung

```bash
# Archive a user before deletion
docker run --rm \
  -e COMMAND=archive \
  -e USER=john.doe \
  -v /var/lib/opendesk-archives:/archives:rw \
  opendesk-user-import:latest --all

# Clean old archives (older than 90 days)
make clean-archives
```

---

## 10. Security Considerations / Sicherheitshinweise

### Credential Management / Zugangsdatenverwaltung

- **Never** commit `.env` files or passwords to version control
- Use Docker secrets or Kubernetes secrets in production
- Rotate UDM API and Keycloak passwords regularly
- Store env files with restricted permissions: `chmod 600 /etc/opendesk/provisioning.env`

```bash
# Using Docker secrets
docker secret create opendesk_udm_password - < password_file
docker run --rm \
  -e UDM_API_PASSWORD_FILE=/run/secrets/opendesk_udm_password \
  ... opendesk-user-import:latest
```

### Dry-Run First / Zuerst Testlauf

Always run operations with `DRY_RUN=true` before applying changes:

```bash
# Preview provisioning
docker run --rm \
  -e COMMAND=provision \
  -e DRY_RUN=true \
  -e LOGLEVEL=DEBUG \
  ... opendesk-user-import:latest

# Preview deprovisioning
docker run --rm \
  -e COMMAND=disable \
  -e DRY_RUN=true \
  ... opendesk-user-import:latest
```

### Audit Trail / Prüfpfad

- All operations produce timestamped log output
- The `LOGPATH` directory retains historical logs
- Deprovisioning scripts write detailed reports including user lists
- Archive operations create per-user tarballs with timestamps

### Principle of Least Privilege / Prinzip der geringsten Rechte

- The Docker container runs as non-root user (`app:1000`)
- UCS credentials should use a dedicated service account, not the full Administrator
- Keycloak credentials should have only the minimum required realm roles
- LDAP bind DN should have read-only access unless write access is needed

---

## 11. Rollback / Zurücksetzen

### Undo Provisioning / Bereitstellung rückgängig machen

There is no automatic rollback for provisioning. To undo:

1. **Disable users** instead of deleting to preserve data:
   ```bash
   docker run --rm \
     -e COMMAND=deprovision \
     -e USER=affected.user \
     opendesk-user-import:latest --phase disable --reason "Rollback"
   ```

2. **Remove SAML identities** in Keycloak Admin Console if needed

3. **Restore UCS from backup** if users must be fully removed:
   ```bash
   make restore FILE=/var/lib/opendesk-backups/provisioning_pre_change.tar.gz
   ```

### Undo Deprovisioning (Disable) / Stilllegung rückgängig machen

Disabled users can be re-enabled:

1. Re-enable the user in UCS via UCS Admin Console or UDM REST API
2. Re-add group memberships
3. Re-link SAML identity in Keycloak

### Undo Deprovisioning (Delete) / Löschung rückgängig machen

Permanent deletion **cannot** be undone. This is why the two-phase approach
exists:

1. Phase 1 (disable) is reversible
2. Phase 2 (delete) is permanent

**Best practice:** Always run Phase 1 with `DRY_RUN=true` first. Review the
output carefully before running without dry-run. Ensure backups exist before
any delete operation.

### Undo LDAP Sync / LDAP-Synchronisierung rückgängig machen

LDAP sync modifies Keycloak users. To undo:

1. Review the sync log for changes made
2. Manually revert changes in Keycloak Admin Console
3. Restore Keycloak from backup if many changes were made

---

## Quick Reference Card / Schnellreferenz

```
# Build
docker build -t opendesk-user-import:latest .

# Provision
docker run --rm --env-file .env -e COMMAND=provision \
  -v /data/users.ods:/data/users.ods:ro opendesk-user-import:latest

# Disable (dry-run)
docker run --rm --env-file .env -e COMMAND=disable \
  -e DRY_RUN=true opendesk-user-import:latest

# Disable (live)
docker run --rm --env-file .env -e COMMAND=disable opendesk-user-import:latest

# Delete
docker run --rm --env-file .env -e COMMAND=delete opendesk-user-import:latest

# Sync
docker run --rm --env-file .env -e COMMAND=sync opendesk-user-import:latest

# Archive
docker run --rm --env-file .env -e COMMAND=archive \
  -e USER=john.doe opendesk-user-import:latest --all

# Help
docker run --rm -e COMMAND=help opendesk-user-import:latest
```

# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH

# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"

# SPDX-License-Identifier: Apache-2.0

# openDesk User Import Tools

Tools for provisioning and deprovisioning users in openDesk environments via
UCS UDM REST API, Keycloak SAML identity management, and IAM API integration.

## Prerequisites

- Python 3.12+
- UCS (Univention Corporate Server) with UDM REST API access
- Keycloak admin credentials (for SAML identity linking)
- IAM API endpoint (optional, for API-based user import)

## Configuration Reference

All settings can be provided via command-line arguments or environment variables.
Command-line values override environment variables which override defaults.

### Common Settings

| Argument | Environment Variable | Required | Default | Description |
|---|---|---|---|---|
| `--import_domain` | `IMPORT_DOMAIN` | Yes | - | openDesk domain (without portal. prefix) |
| `--import_maildomain` | `IMPORT_MAILDOMAIN` | No | IMPORT_DOMAIN | Mail domain for user accounts |
| `--udm_api_username` | `UDM_API_USERNAME` | No | Administrator | UDM REST API username |
| `--udm_api_password` | `UDM_API_PASSWORD` | Yes | - | UDM REST API password |
| `--keycloak_url` | `KEYCLOAK_URL` | No | <https://id.{domain}> | Keycloak base URL |
| `--keycloak_api_username` | `KEYCLOAK_API_USERNAME` | No | admin | Keycloak admin username |
| `--keycloak_api_password` | `KEYCLOAK_API_PASSWORD` | Conditional | - | Keycloak admin password |
| `--identity_provider` | `IDENTITY_PROVIDER` | No | saml-umr | Keycloak identity provider alias |
| `--iam_api_url` | `IAM_API_URL` | No | - | IAM API endpoint for user data |
| `--verify_certificate` | `VERIFY_CERTIFICATE` | No | true | Verify SSL certificates |
| `--enforce_ipv4` | `ENFORCE_IPV4` | No | false | Force IPv4 communication |
| `--loglevel` | `LOGLEVEL` | No | INFO | Logging level |
| `--logpath` | `LOGPATH` | No | ./logs | Log file directory |

### Provisioning Settings

| Argument | Environment Variable | Default | Description |
|---|---|---|---|
| `--import_filename` | `IMPORT_FILENAME` | - | File with user data (ODS/XLSX/CSV) |
| `--create_admin_accounts` | `CREATE_ADMIN_ACCOUNTS` | false | Create -admin accounts for each user |
| `--create_maildomains` | `CREATE_MAILDOMAINS` | false | Auto-create mail domains |
| `--create_oxcontexts` | `CREATE_OXCONTEXT` | false | Auto-create OX contexts |
| `--import_use_images` | `IMPORT_USE_IMAGES` | false | Assign random profile pictures |
| `--import_random_amount` | `IMPORT_RANDOM_AMOUNT` | 10 | Number of random users to create |
| `--reconcile_groups` | `RECONCILE_GROUPS` | false | Reconcile user groups to match input |
| `--set_default_password` | `SET_DEFAULT_PASSWORD` | - | Default password for new accounts |
| `--trigger_invitation_mail` | `TRIGGER_INVITATION_MAIL` | false | Send invitation emails |

### Deprovisioning Settings

| Argument | Environment Variable | Default | Description |
|---|---|---|---|
| `--dry_run` | `DRY_RUN` | false | Log actions without making changes |
| `--grace_period_months` | `GRACE_PERIOD_MONTHS` | 12 | Months before permanent deletion |

## Provisioning Workflow

```bash
python provision.py \
  --import_domain example.com \
  --udm_api_password "secret" \
  --import_filename users.ods \
  --keycloak_url https://id.example.com \
  --keycloak_api_username admin \
  --keycloak_api_password "keycloak-secret"
```

The provisioning script:

1. Loads users from a file (ODS/XLSX/CSV) or the IAM API
2. Validates and cleans user data
3. Creates users in UCS via UDM REST API
4. Optionally creates admin accounts
5. Links SAML identities in Keycloak (if credentials configured)

## Deprovisioning Workflow

Deprovisioning is a two-phase process:

### Phase 1: Disable (deprovision_disable.py)

```bash
python deprovision_disable.py \
  --import_domain example.com \
  --udm_api_password "secret" \
  --keycloak_api_password "keycloak-secret" \
  --iam_api_url https://iam-api.example.com/openDesk/v1.0/openDesk_account_depro
```

- Fetches active users from IAM API
- Compares with UCS users
- Disables users not in IAM
- Removes SAML identities
- Removes all groups except system groups

### Phase 2: Delete (deprovision_delete.py)

```bash
python deprovision_delete.py \
  --import_domain example.com \
  --udm_api_password "secret" \
  --grace_period_months 12
```

- Finds users deprovisioned past the grace period
- Permanently deletes users and their admin accounts

## SAML Identity Linking

SAML federated identities can be linked during provisioning or removed during
deprovisioning. The identity provider alias is configurable via
`--identity_provider` (default: `saml-umr`).

## Docker Deployment

Build the image:

```bash
docker build -t opendesk-user-import .
```

The image supports multiple operations via the `COMMAND` environment variable:

| Command | Script | Description |
|---|---|---|
| `provision` | `provision.py` | Provision users from ODS/XLSX/CSV or IAM API |
| `disable` | `deprovision_disable.py` | Phase 1: disable users not in IAM |
| `delete` | `deprovision_delete.py` | Phase 2: permanently delete after grace period |
| `deprovision` | `deprovision_user.py` | Disable or delete a single user |
| `sync` | `sync_users.py` | Sync users from LDAP to Keycloak |
| `archive` | `archive_service_user.py` | Archive user data from services |

### Examples

Provision users:

```bash
docker run --rm \
  -e COMMAND=provision \
  -e IMPORT_DOMAIN=example.com \
  -e UDM_API_PASSWORD=secret \
  -e KEYCLOAK_URL=https://id.example.com \
  -e KEYCLOAK_API_PASSWORD=keycloak-secret \
  -v /path/to/users.ods:/data/users.ods:ro \
  -e IMPORT_FILENAME=/data/users.ods \
  opendesk-user-import
```

Deprovision (disable users not in IAM):

```bash
docker run --rm \
  -e COMMAND=disable \
  -e IMPORT_DOMAIN=example.com \
  -e UDM_API_PASSWORD=secret \
  -e DRY_RUN=true \
  opendesk-user-import
```

Sync users from LDAP:

```bash
docker run --rm \
  -e COMMAND=sync \
  -e LDAP_SERVER=ldap://ldap.example.de \
  -e LDAP_BASE_DN=dc=example,dc=de \
  -e LDAP_BIND_DN=cn=admin,dc=example,dc=de \
  -e LDAP_BIND_PASSWORD=secret \
  opendesk-user-import
```

Show available commands:

```bash
docker run --rm -e COMMAND=help opendesk-user-import
```

## Operational Runbook

For detailed operational procedures including cron scheduling, troubleshooting,
monitoring, backup/recovery, and rollback instructions, see the
[Operational Runbook](docs/operational-runbook.md).

## Security Notes

- Never disable certificate verification (`--verify_certificate=false`) in production
- Never store credentials in plain text; use environment variables or secrets management
- The `--dry_run` flag is recommended before first execution
- UCS admin credentials have full system access

## Development

Install dependencies:

```bash
pip install -e ".[dev]"
```

Run tests:

```bash
python -m pytest tests/ -v
```

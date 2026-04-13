#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

COMMAND="${COMMAND:-}"

show_help() {
    cat <<'EOF'
openDesk User Import Tools

Usage:
  Set the COMMAND environment variable to select an operation.

Available commands:
  provision    Provision users from ODS/XLSX/CSV files or IAM API
  disable      Phase 1 deprovisioning: disable users not in IAM
  delete       Phase 2 deprovisioning: permanently delete after grace period
  deprovision  Deprovision a single user (requires USER env var)
  sync         Sync users from LDAP to Keycloak
  archive      Archive service data for a single user (requires USER env var)
  help         Show this help message

Examples:
  docker run --rm -e COMMAND=provision -e IMPORT_DOMAIN=example.com ...
  docker run --rm -e COMMAND=disable -e IMPORT_DOMAIN=example.com ...
  docker run --rm -e COMMAND=delete -e IMPORT_DOMAIN=example.com ...
  docker run --rm -e COMMAND=deprovision -e USER=john.doe ...
  docker run --rm -e COMMAND=sync ...
  docker run --rm -e COMMAND=archive -e USER=jane.doe ...

All Python script arguments can be passed via environment variables.
See .env.example or the operational runbook for the full reference.
EOF
}

case "${COMMAND}" in
    provision)
        exec python3 /app/provision.py "$@"
        ;;
    disable)
        exec python3 /app/deprovision_disable.py "$@"
        ;;
    delete)
        exec python3 /app/deprovision_delete.py "$@"
        ;;
    deprovision)
        exec python3 /app/deprovision_user.py "$@"
        ;;
    sync)
        exec python3 /app/sync_users.py "$@"
        ;;
    archive)
        exec python3 /app/archive_service_user.py "$@"
        ;;
    help|--help|-h)
        show_help
        exit 0
        ;;
    "")
        echo "Error: No COMMAND specified."
        echo ""
        show_help
        exit 1
        ;;
    *)
        echo "Error: Unknown command '${COMMAND}'"
        echo ""
        show_help
        exit 1
        ;;
esac

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
MariaDB Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  # Secrets from sops-nix
  services.mariadb = {
    # Root password (optional - can be set via environment variable)
    rootPassword = config.sops.secrets.mariadb-root-password or "";
    
    # openDesk user password
    opendeskPassword = config.sops.secrets.mariadb-opendesk-password or "CHANGE_ME_IN_PRODUCTION";
    
    # Service-specific user passwords
    moodlePassword = config.sops.secrets.mariadb-moodle-password or "CHANGE_ME_IN_PRODUCTION";
    iliasPassword = config.sops.secrets.mariadb-ilias-password or "CHANGE_ME_IN_PRODUCTION";
    nextcloudPassword = config.sops.secrets.mariadb-nextcloud-password or "CHANGE_ME_IN_PRODUCTION";
    collaboraPassword = config.sops.secrets.mariadb-collabora-password or "CHANGE_ME_IN_PRODUCTION";
    keycloakPassword = config.sops.secrets.mariadb-keycloak-password or "CHANGE_ME_IN_PRODUCTION";
    openprojectPassword = config.sops.secrets.mariadb-openproject-password or "CHANGE_ME_IN_PRODUCTION";
    rocketchatPassword = config.sops.secrets.mariadb-rocketchat-password or "CHANGE_ME_IN_PRODUCTION";
    bookstackPassword = config.sops.secrets.mariadb-bookstack-password or "CHANGE_ME_IN_PRODUCTION";
    plankaPassword = config.sops.secrets.mariadb-planka-password or "CHANGE_ME_IN_PRODUCTION";
  };

  # Replication settings (for future HA setup)
  services.mariadb.replication = {
    user = config.sops.secrets.mariadb-replication-user or "repl";
    password = config.sops.secrets.mariadb-replication-password or "CHANGE_ME_IN_PRODUCTION";
  };
}

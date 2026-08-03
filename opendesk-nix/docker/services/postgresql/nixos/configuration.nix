# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
PostgreSQL NixOS Configuration for openDesk
Version: 16.3
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # PostgreSQL service configuration
  services.postgresql = {
    enable = true;
    package = pkgs.opendeskPackages.postgresql;

    # Port and socket configuration
    port = 5432;
    
    # openDesk databases
    ensureDatabases = [
      "openproject"
      "rocketchat"
      "gitlab"
      "mastodon"
      "pleroma"
      "keycloak"
    ];

    # Standard users with openDesk permissions
    ensureUsers = [
      {
        name = "openproject";
        password = config.services.postgresql.openprojectPassword or "CHANGE_ME_IN_PRODUCTION";
        ensurePermissions = {
          "openproject.*" = "ALL PRIVILEGES";
          "CREATE" = true;
        };
      }
      {
        name = "rocketchat";
        password = config.services.postgresql.rocketchatPassword or "CHANGE_ME_IN_PRODUCTION";
        ensurePermissions = {
          "rocketchat.*" = "ALL PRIVILEGES";
        };
      }
      {
        name = "gitlab";
        password = config.services.postgresql.gitlabPassword or "CHANGE_ME_IN_PRODUCTION";
        ensurePermissions = {
          "gitlab.*" = "ALL PRIVILEGES";
        };
      }
      {
        name = "keycloak";
        password = config.services.postgresql.keycloakPassword or "CHANGE_ME_IN_PRODUCTION";
        ensurePermissions = {
          "keycloak.*" = "ALL PRIVILEGES";
        };
      }
    ];

    # Performance configuration optimized for openDesk
    settings = {
      shared_buffers = "2GB";
      effective_cache_size = "6GB";
      maintenance_work_mem = "512MB";
      work_mem = "16MB";
      random_page_cost = "1.1";
      effective_io_concurrency = "200";
      max_worker_processes = "8";
      max_parallel_workers_per_gather = "4";
      max_parallel_workers = "8";
      wal_level = "logical";
      max_wal_senders = "10";
      max_replication_slots = "10";
      synchronous_commit = "remote_apply";
      hot_standby = "on";
      max_connections = "500";
      
      # Memory settings
      temp_buffers = "32MB";
      
      # Logging
      log_destination = "'stderr'";
      logging_collector = "on";
      log_min_duration_statement = "1000";  # ms
      log_checkpoints = "on";
      log_connections = "on";
      log_disconnections = "on";
      log_line_prefix = "'%m [%p] %q%u@%d '";
      
      # Checkpoint settings
      checkpoint_completion_target = "0.9";
      checkpoint_timeout = "30min";
      max_wal_size = "4GB";
      min_wal_size = "1GB";
      
      # Autovacuum
      autovacuum = "on";
      autovacuum_max_workers = "3";
      autovacuum_naptime = "30s";
      autovacuum_vacuum_threshold = "50";
      autovacuum_analyze_threshold = "50";
      autovacuum_vacuum_scale_factor = "0.1";
      autovacuum_analyze_scale_factor = "0.05";
      
      # Timezone
      timezone = "Europe/Berlin";
    };

    # PostgreSQL data directory
    dataDir = "/var/lib/postgresql/16/main";
  };

  # System user for PostgreSQL
  users.users.postgres = {
    isSystemUser = true;
    uid = 999;
    gid = 999;
    group = "postgres";
    home = "/var/lib/postgresql";
    shell = pkgs.bash;
    description = "PostgreSQL Server User";
  };

  users.groups.postgres = {
    gid = 999;
  };

  # Setup directories
  system.activationScripts.setupPostgresql = lib.mkAfter ''
    # Create necessary directories
    mkdir -p /var/lib/postgresql/16/main /var/log/postgresql /var/run/postgresql
    
    # Set correct ownership
    chown -R postgres:postgres /var/lib/postgresql /var/log/postgresql /var/run/postgresql
    
    # Set correct permissions
    chmod -R 700 /var/lib/postgresql/16/main
    chmod -R 755 /var/log/postgresql
    chmod -R 755 /var/run/postgresql
    
    # Create log file
    touch /var/log/postgresql/postgresql.log
    chown postgres:postgres /var/log/postgresql/postgresql.log
    chmod 640 /var/log/postgresql/postgresql.log
    
    # Initialize database if not exists
    if [ ! -d /var/lib/postgresql/16/main/base ]; then
      su - postgres -c "${pkgs.opendeskPackages.postgresql}/bin/initdb -D /var/lib/postgresql/16/main"
    fi
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

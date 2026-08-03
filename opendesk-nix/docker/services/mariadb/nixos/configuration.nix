# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
MariaDB NixOS Configuration for openDesk
Version: 11.4.4
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # MariaDB service configuration
  services.mariadb = {
    enable = true;
    package = pkgs.opendeskPackages.mariadb;

    # Port configuration
    port = 3306;
    socket = "/var/run/mysqld/mysqld.sock";

    # openDesk databases
    ensureDatabases = [
      "opendesk"
      "moodle"
      "ilias"
      "nextcloud"
      "collabora"
      "keycloak"
      "openproject"
      "rocketchat"
      "bookstack"
      "planka"
    ];

    # Standard users with openDesk permissions
    ensureUsers = [
      {
        name = "opendesk";
        password = config.services.mariadb.opendeskPassword or "CHANGE_ME_IN_PRODUCTION";
        ensurePermissions = builtins.listToAttrs (
          map (db: {
            name = db;
            value = "ALL PRIVILEGES";
          }) config.services.mariadb.ensureDatabases
        );
      }
      {
        name = "moodle";
        password = config.services.mariadb.moodlePassword or "CHANGE_ME_IN_PRODUCTION";
        ensurePermissions = {
          "moodle.*" = "ALL PRIVILEGES";
        };
      }
      {
        name = "ilias";
        password = config.services.mariadb.iliasPassword or "CHANGE_ME_IN_PRODUCTION";
        ensurePermissions = {
          "ilias.*" = "ALL PRIVILEGES";
        };
      }
      {
        name = "nextcloud";
        password = config.services.mariadb.nextcloudPassword or "CHANGE_ME_IN_PRODUCTION";
        ensurePermissions = {
          "nextcloud.*" = "ALL PRIVILEGES";
        };
      }
    ];

    # Performance configuration optimized for openDesk
    my.cnfExtra = lib.mkForce ''
      [mysqld]
      # Performance settings
      innodb_buffer_pool_size = 2G
      innodb_buffer_pool_instances = 4
      innodb_buffer_pool_load_at_startup = ON
      innodb_buffer_pool_dump_at_shutdown = ON
      innodb_log_file_size = 512M
      innodb_log_buffer_size = 32M
      innodb_flush_log_at_trx_commit = 2
      innodb_flush_method = O_DIRECT
      innodb_file_per_table = ON
      innodb_stats_persistent = ON
      innodb_autoinc_lock_mode = 2

      # Network settings
      skip-name-resolve
      bind-address = 0.0.0.0
      max_connections = 500
      thread_cache_size = 50
      table_open_cache = 2000
      table_definition_cache = 2000

      # Logging
      log_error = /var/log/mysql/error.log
      slow_query_log = 1
      slow_query_log_file = /var/log/mysql/slow.log
      long_query_time = 2
      log_queries_not_using_indexes = 1
      log_slow_admin_statements = 1
      log_throttle_queries_not_using_indexes = 10

      # Character set
      character-set-server = utf8mb4
      collation-server = utf8mb4_unicode_ci
      character-set-client-handshake = FALSE
      skip-character-set-client-handshake

      # Connection limits
      wait_timeout = 300
      interactive_timeout = 300
      net_read_timeout = 300
      net_write_timeout = 300

      # Temp tables
      tmp_table_size = 256M
      max_heap_table_size = 256M

      # Group by optimization
      sql_mode = "STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"
      optimizer_switch = "index_merge=on,index_merge_union=on,index_merge_sort_union=on,index_merge_intersection=on,engine_condition_pushdown=on,mrr=on,mrr_cost_based=on,block_nested_loop=on,batched_key_access=off,materialization=on,semijoin=on,loosescan=on,firstmatch=on,duplicateweedout=on,subquery_materialization_cost_based=on,use_index_extensions=on,condition_pushdown_for_derived=on,split_materialized=on"
    '';

    # Additional security settings
    extraFlags = [
      "--skip-symbolic-links"
      "--enable-local-infile"
      "--local-infile"
    ];
  };

  # System user for MariaDB
  users.users.mysql = {
    isSystemUser = true;
    uid = 999;
    gid = 999;
    group = "mysql";
    home = "/var/lib/mysql";
    shell = pkgs.bash;
    description = "MariaDB Server User";
  };

  users.groups.mysql = {
    gid = 999;
  };

  # Setup directories
  system.activationScripts.setupMariadb = lib.mkAfter ''
    # Create necessary directories
    mkdir -p /var/lib/mysql /var/log/mysql /var/run/mysqld /etc/mysql/conf.d
    
    # Set correct ownership
    chown -R mysql:mysql /var/lib/mysql /var/log/mysql /var/run/mysqld /etc/mysql
    
    # Set correct permissions
    chmod -R 750 /var/lib/mysql
    chmod -R 755 /var/log/mysql
    chmod -R 755 /etc/mysql
    
    # Create log files
    touch /var/log/mysql/error.log /var/log/mysql/slow.log /var/log/mysql/general.log
    chown mysql:mysql /var/log/mysql/*.log
    chmod 640 /var/log/mysql/*.log
    
    # Fix PID file directory
    mkdir -p /var/run/mysqld
    chown mysql:mysql /var/run/mysqld
    chmod 755 /var/run/mysqld
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

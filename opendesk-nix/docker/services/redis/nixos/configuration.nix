# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Redis NixOS Configuration for openDesk
Version: 7.2.4
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # Redis service configuration
  services.redis = {
    enable = true;
    package = pkgs.opendeskPackages.redis;

    # Port configuration
    port = 6379;
    
    # Redis configuration settings
    settings = {
      "bind" = "0.0.0.0";
      "protected-mode" = "no";
      
      # Memory management
      "maxmemory" = "2gb";
      "maxmemory-policy" = "allkeys-lru";
      "maxmemory-samples" = "5";
      
      # Persistence
      "appendonly" = "yes";
      "appendfilename" = "appendonly.aof";
      "appendfsync" = "everysec";
      "no-appendfsync-on-rewrite" = "yes";
      "auto-aof-rewrite-percentage" = "100";
      "auto-aof-rewrite-min-size" = "64mb";
      
      # RDB snapshotting
      "save" = "900 1\n300 10\n60 10000";
      "stop-writes-on-bgsave-error" = "yes";
      "rdbcompression" = "yes";
      "rdbchecksum" = "yes";
      "dbfilename" = "dump.rdb";
      
      # Security
      "requirepass" = config.services.redis.password or "";
      "rename-command" = "CONFIG \"\"";
      "rename-command" = "FLUSHALL \"\"";
      "rename-command" = "FLUSHDB \"\"";
      "rename-command" = "SHUTDOWN \"\"";
      "rename-command" = "DEBUG \"\"";
      "rename-command" = "MIGRATE \"\"";
      
      # Performance
      "tcp-keepalive" = "300";
      "tcp-backlog" = "511";
      "timeout" = "300";
      "client-output-buffer-limit" = "normal 0 0 0\nreplica 256mb 64mb 60\npubsub 32mb 8mb 60";
      
      # Databases
      "databases" = "16";
      
      # Lua scripting
      "lua-time-limit" = "5000";
      
      # Memory optimizations
      "hash-max-ziplist-entries" = "512";
      "hash-max-ziplist-value" = "64";
      "list-max-ziplist-size" = "-2";
      "list-compress-depth" = "0";
      "set-max-intset-entries" = "512";
      "zset-max-ziplist-entries" = "128";
      "zset-max-ziplist-value" = "64";
      "hll-sparse-max-bytes" = "3000";
      "stream-node-max-entries" = "10000";
      "stream-node-max-bytes" = "4096";
      
      # Network
      "cluster-enabled" = "no";
      "cluster-config-file" = "nodes.conf";
      "cluster-node-timeout" = "5000";
      
      # Replication (for future scaling)
      "repl-backlog-size" = "100mb";
      "repl-backlog-ttl" = "3600";
    };

    # Redis cluster mode (disabled by default)
    cluster = {
      enable = false;
      nodes = [ ];  # Will be populated when cluster mode is enabled
    };
  };

  # System user for Redis
  users.users.redis = {
    isSystemUser = true;
    uid = 999;
    gid = 999;
    group = "redis";
    home = "/var/lib/redis";
    shell = pkgs.bash;
    description = "Redis Server User";
  };

  users.groups.redis = {
    gid = 999;
  };

  # Setup directories
  system.activationScripts.setupRedis = lib.mkAfter ''
    # Create necessary directories
    mkdir -p /var/lib/redis /var/log/redis /var/run/redis
    
    # Set correct ownership
    chown -R redis:redis /var/lib/redis /var/log/redis /var/run/redis
    
    # Set correct permissions
    chmod -R 750 /var/lib/redis
    chmod -R 755 /var/log/redis
    chmod -R 755 /var/run/redis
    
    # Create log file
    touch /var/log/redis/redis-server.log
    chown redis:redis /var/log/redis/redis-server.log
    chmod 640 /var/log/redis/redis-server.log
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

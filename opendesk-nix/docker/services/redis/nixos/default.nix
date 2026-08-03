# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Redis NixOS Container Image
Version: 7.2.4
OpenSpec: FR-BUILD-001 through FR-BUILD-007
"""

{ 
  pkgs ? import <nixpkgs> { system = "x86_64-linux"; },
  docks ? import (builtins.fetchGit {
    url = "https://github.com/dockernix/docks.nix";
    ref = "refs/tags/0.5.0";
  }) { inherit pkgs; },
  ...
}:

let
  lib = pkgs.lib;
  opendeskOverlays = import ../../../../../overlays/opendesk.nix;
  nixpkgsWithOverlays = pkgs // {
    overlays = [ opendeskOverlays ];
  };
  redisPkg = nixpkgsWithOverlays.opendeskPackages.redis;

in

docks.mkImage {
  name = "redis-opendesk";
  tag = "7.2.4-nixos";

  # NixOS configuration
  config = import ./configuration.nix {
    inherit pkgs lib;
  };

  # Container configuration
  containerConfig = {
    ExposedPorts = { "6379/tcp" = {}; };
    
    Volumes = {
      "/var/lib/redis" = {};
      "/var/log/redis" = {};
      "/etc/redis" = {};
    };
    
    Env = [
      "REDIS_PASSWORD="
      "REDIS_PORT=6379"
      "REDIS_DATABASES=16"
      "OPENDESK_ENV=production"
      "TZ=Europe/Berlin"
      "LC_ALL=C.UTF-8"
      "LANG=C.UTF-8"
    ];
    
    HealthCheck = {
      Test = [ "CMD-SHELL" "redis-cli -a $REDIS_PASSWORD ping 2>/dev/null | grep PONG || exit 1" ];
      Interval = 5000000000;  # 5s
      Timeout = 3000000000;   # 3s
      Retries = 3;
      StartPeriod = 10000000000; # 10s
    };
    
    User = "redis";
    WorkingDir = "/var/lib/redis";
    
    Cmd = [
      "${redisPkg}/bin/redis-server"
      "/etc/redis/redis.conf"
    ];
    
    StopSignal = "SIGTERM";
    StopTimeout = 30;
  };

  # Additional packages for runtime
  extraPackages = p: with p; [
    openssl
    curl
    procps
    lsof
    htop
    inotify-tools
    gnupg
    coreutils
    findutils
    grep
    sed
    awk
  ];

  # OCI Labels for OpenSpec compliance (FR-IMAGE-007)
  ociLabels = {
    "org.opencontainers.image.title" = "redis-opendesk";
    "org.opencontainers.image.description" = "Redis 7.2.4 for openDesk Edu with NixOS";
    "org.opencontainers.image.version" = "7.2.4-nixos";
    "org.opencontainers.image.authors" = "openDesk Edu Team";
    "org.opencontainers.image.url" = "https://opendesk.hrz.uni-marburg.de";
    "org.opencontainers.image.documentation" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.source" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.licenses" = "Apache-2.0";
    "com.opendesk.service" = "redis";
    "com.opendesk.environment" = "production";
    "com.opendesk.managed" = "true";
    "com.opendesk.nixos" = "true";
  };
}

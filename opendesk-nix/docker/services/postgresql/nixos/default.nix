# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
PostgreSQL NixOS Container Image
Version: 16.3
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
  postgresqlPkg = nixpkgsWithOverlays.opendeskPackages.postgresql;

in

docks.mkImage {
  name = "postgresql-opendesk";
  tag = "16.3-nixos";

  # NixOS configuration
  config = import ./configuration.nix {
    inherit pkgs lib;
  };

  # Container configuration
  containerConfig = {
    ExposedPorts = { "5432/tcp" = {}; };
    
    Volumes = {
      "/var/lib/postgresql" = {};
      "/var/log/postgresql" = {};
      "/etc/postgresql" = {};
      "/docker-entrypoint-initdb.d" = {};
    };
    
    Env = [
      "POSTGRES_USER=postgres"
      "POSTGRES_DB=openproject"
      "POSTGRES_INITDB_ARGS=""
      "PGDATA=/var/lib/postgresql/16/main"
      "OPENDESK_ENV=production"
      "TZ=Europe/Berlin"
      "LC_ALL=C.UTF-8"
      "LANG=C.UTF-8"
    ];
    
    HealthCheck = {
      Test = [ "CMD-SHELL" "pg_isready -U postgres -d openproject 2>/dev/null || exit 1" ];
      Interval = 10000000000;  # 10s
      Timeout = 5000000000;   # 5s
      Retries = 5;
      StartPeriod = 300000000000; # 5 minutes
    };
    
    User = "postgres";
    WorkingDir = "/var/lib/postgresql/16/main";
    
    Cmd = [
      "${postgresqlPkg}/bin/postgres"
      "-D"
      "/var/lib/postgresql/16/main"
      "-c"
      "listen_addresses=*"
      "-c"
      "port=5432"
    ];
    
    StopSignal = "SIGTERM";
    StopTimeout = 60;
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
    gzip
    tar
    xz
    bash
  ];

  # OCI Labels for OpenSpec compliance (FR-IMAGE-007)
  ociLabels = {
    "org.opencontainers.image.title" = "postgresql-opendesk";
    "org.opencontainers.image.description" = "PostgreSQL 16.3 for openDesk Edu with NixOS";
    "org.opencontainers.image.version" = "16.3-nixos";
    "org.opencontainers.image.authors" = "openDesk Edu Team";
    "org.opencontainers.image.url" = "https://opendesk.hrz.uni-marburg.de";
    "org.opencontainers.image.documentation" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.source" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.licenses" = "Apache-2.0";
    "com.opendesk.service" = "postgresql";
    "com.opendesk.environment" = "production";
    "com.opendesk.managed" = "true";
    "com.opendesk.nixos" = "true";
  };
}

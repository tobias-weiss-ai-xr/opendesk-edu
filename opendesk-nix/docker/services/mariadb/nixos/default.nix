# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
MariaDB NixOS Container Image
Version: 11.4.4
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
  mariadbPkg = nixpkgsWithOverlays.opendeskPackages.mariadb;

in

docks.mkImage {
  name = "mariadb-opendesk";
  tag = "11.4.4-nixos";

  # NixOS configuration
  config = import ./configuration.nix {
    inherit pkgs lib;
  };

  # Container configuration
  containerConfig = {
    ExposedPorts = { "3306/tcp" = {}; };
    
    Volumes = {
      "/var/lib/mysql" = {};
      "/var/log/mysql" = {};
      "/etc/mysql/conf.d" = {};
      "/docker-entrypoint-initdb.d" = {};
    };
    
    Env = [
      "MYSQL_ROOT_PASSWORD="
      "MYSQL_DATABASE=opendesk"
      "MYSQL_USER=opendesk"
      "OPENDESK_ENV=production"
      "TZ=Europe/Berlin"
      "LC_ALL=C.UTF-8"
      "LANG=C.UTF-8"
    ];
    
    HealthCheck = {
      Test = [ "CMD-SHELL" "mariadb-admin ping -u root --password=$MYSQL_ROOT_PASSWORD --silent 2>/dev/null || exit 1" ];
      Interval = 30000000000;  # 30s
      Timeout = 10000000000;   # 10s
      Retries = 3;
      StartPeriod = 300000000000; # 5 minutes
    };
    
    User = "mysql";
    WorkingDir = "/var/lib/mysql";
    
    Cmd = [
      "${mariadbPkg}/bin/mysqld"
      "--basedir=${mariadbPkg}"
      "--datadir=/var/lib/mysql"
      "--pid-file=/var/run/mysqld/mysqld.pid"
      "--socket=/var/run/mysqld/mysqld.sock"
      "--port=3306"
      "--character-set-server=utf8mb4"
      "--collation-server=utf8mb4_unicode_ci"
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
    gzip
    tar
    xz
  ];

  # OCI Labels for OpenSpec compliance (FR-IMAGE-007)
  ociLabels = {
    "org.opencontainers.image.title" = "mariadb-opendesk";
    "org.opencontainers.image.description" = "MariaDB 11.4.4 for openDesk Edu with NixOS";
    "org.opencontainers.image.version" = "11.4.4-nixos";
    "org.opencontainers.image.authors" = "openDesk Edu Team";
    "org.opencontainers.image.url" = "https://opendesk.hrz.uni-marburg.de";
    "org.opencontainers.image.documentation" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.source" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.licenses" = "Apache-2.0";
    "org.opencontainers.image.revision" = "${lib.shortHash "sha256" (builtins.readFile ../../../../../.)}";
    "org.opencontainers.image.created" = "${lib.strftime "%Y-%m-%dT%H:%M:%SZ" (builtins.currentTime)}";
    "com.opendesk.service" = "mariadb";
    "com.opendesk.environment" = "production";
    "com.opendesk.managed" = "true";
    "com.opendesk.nixos" = "true";
  };
}

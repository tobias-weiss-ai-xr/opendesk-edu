# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# NixOS Container Library for openDesk
# Provides standardized container builders using docks.nix
# OpenSpec: FR-BUILD-001 through FR-BUILD-007

{ pkgs, lib, docks, ... }:

let
  # Standard configuration for all openDesk containers
  defaultContainerConfig = {
    env = [
      "OPENDESK_ENV=production"
      "NIXOS=1"
      "TZ=Europe/Berlin"
      "LC_ALL=C.UTF-8"
      "LANG=C.UTF-8"
    ];
    workingDir = "/";
    user = "nobody";
    healthCheck = {
      test = [ "CMD-SHELL" "exit 0" ];
      interval = 30000000000;  # 30s
      timeout = 5000000000;    # 5s
      retries = 3;
      startPeriod = 10000000000; # 10s
    };
    stopSignal = "SIGTERM";
    stopTimeout = 30;
  };

  # Standard OCI labels for OpenSpec compliance (FR-IMAGE-007)
  defaultOCILabels = {
    "org.opencontainers.image.title" = "opendesk-service";
    "org.opencontainers.image.description" = "openDesk service container built with NixOS";
    "org.opencontainers.image.version" = "latest";
    "org.opencontainers.image.authors" = "openDesk Edu Team";
    "org.opencontainers.image.url" = "https://opendesk.hrz.uni-marburg.de";
    "org.opencontainers.image.documentation" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.source" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.licenses" = "Apache-2.0";
    "com.opendesk.service" = "opendesk-service";
    "com.opendesk.environment" = "production";
    "com.opendesk.managed" = "true";
    "com.opendesk.nixos" = "true";
  };

  # Standard volumes for different service types
  standardVolumes = {
    database = {
      "/var/lib/db" = {};
      "/var/log" = {};
      "/etc" = {};
    };
    web = {
      "/var/www" = {};
      "/var/log" = {};
      "/tmp" = {};
    };
    cache = {
      "/var/lib" = {};
      "/var/log" = {};
    };
    minimal = {};
  };

in rec {

  # Generic container builder
  mkContainer = {
    name,
    version,
    configPath ? null,
    type ? "minimal",
    port ? null,
    extraPorts ? [],
    volumes ? standardVolumes.${type} or {},
    extraEnv ? [],
    user ? "nobody",
    uid ? 65534,
    gid ? 65534,
    workingDir ? "/",
    cmd ? [ "/usr/bin/env" "bash" "-c" "echo Service ${name} ready" ],
    entrypoint ? null,
    healthCheck ? null,
    extraPackages ? _: [],
    overlays ? [],
    ociLabels ? {},
    securityProfile ? "default",
    ...
  } @ args:

    let
      # Exposed ports
      allPorts = lib.optional (port != null) port ++ extraPorts;
      exposedPorts = builtins.listToAttrs (
        map (p: { name = "${toString p}/tcp"; value = {}; }) allPorts
      );

      # Full configuration merge
      fullContainerConfig = {
        ExposedPorts = exposedPorts;
        Volumes = volumes;
        Env = defaultContainerConfig.env ++ extraEnv;
        User = user;
        WorkingDir = workingDir;
        Cmd = cmd;
        StopSignal = defaultContainerConfig.stopSignal;
        StopTimeout = defaultContainerConfig.stopTimeout;
        HealthCheck = (if healthCheck != null then healthCheck else defaultContainerConfig.healthCheck);
      } // (if entrypoint != null then { Entrypoint = entrypoint; } else {});

      # Full OCI labels
      fullOCILabels = defaultOCILabels // ociLabels;

    in
    docks.mkImage {
      name = "${name}-opendesk";
      tag = "${version}-nixos";
      containerConfig = fullContainerConfig;
      extraPackages = extraPackages;
      ociLabels = fullOCILabels;
    };

  # Database container builder (FR-BUILD-001, FR-IMAGE-001)
  mkDatabaseContainer = {
    name,
    version,
    configPath ? null,
    port ? 3306,
    dataDir ? "/var/lib/db",
    logDir ? "/var/log",
    confDir ? "/etc",
    initDir ? "/docker-entrypoint-initdb.d",
    user ? name,
    uid ? 999,
    gid ? 999,
    healthCheck ? {
      Test = [ "CMD-SHELL" "pg_isready || mysqladmin ping || exit 1" ];
      Interval = 10000000000;
      Timeout = 5000000000;
      Retries = 5;
      StartPeriod = 300000000000; # 5 minutes
    },
    extraPackages ? _: [ pkgs.openssl pkgs.procps pkgs.coreutils ],
    ...
  } @ args:

    mkContainer (args // {
      type = "database";
      volumes = {
        "${dataDir}" = {};
        "${logDir}" = {};
        "${confDir}" = {};
        "${initDir}" = {};
      };
      workingDir = dataDir;
      healthCheck = healthCheck;
      extraPackages = extraPackages;
    });

  # Web service container builder
  mkWebContainer = {
    name,
    version,
    configPath ? null,
    httpPort ? 8080,
    httpsPort ? null,
    user ? "www-data",
    uid ? 1000,
    gid ? 1000,
    workingDir ? "/var/www",
    healthCheck ? {
      Test = [ "CMD-SHELL" "curl -f http://127.0.0.1:${toString httpPort}/ || exit 1" ];
      Interval = 10000000000;
      Timeout = 5000000000;
      Retries = 3;
    },
    extraPackages ? _: [ pkgs.curl pkgs.coreutils ],
    ...
  } @ args:

    let
      extraPorts = lib.optional (httpsPort != null) httpsPort;
    in
    mkContainer (args // {
      type = "web";
      port = httpPort;
      extraPorts = extraPorts;
      volumes = {
        "/var/www" = {};
        "/var/log" = {};
        "/tmp" = {};
      };
      user = user;
      uid = uid;
      gid = gid;
      workingDir = workingDir;
      healthCheck = healthCheck;
      extraPackages = extraPackages;
    });

  # Cache service container builder
  mkCacheContainer = {
    name,
    version,
    configPath ? null,
    port ? 6379,
    dataDir ? "/var/lib",
    logDir ? "/var/log",
    user ? name,
    uid ? 999,
    gid ? 999,
    healthCheck ? {
      Test = [ "CMD-SHELL" "redis-cli ping | grep PONG || exit 1" ];
      Interval = 5000000000;
      Timeout = 3000000000;
      Retries = 3;
    },
    extraPackages ? _: [ pkgs.coreutils ],
    ...
  } @ args:

    mkContainer (args // {
      type = "cache";
      port = port;
      volumes = {
        "${dataDir}" = {};
        "${logDir}" = {};
      };
      user = user;
      uid = uid;
      gid = gid;
      workingDir = dataDir;
      healthCheck = healthCheck;
      extraPackages = extraPackages;
    });

  # Message queue container builder
  mkQueueContainer = {
    name,
    version,
    configPath ? null,
    port ? 5672,
    managementPort ? null,
    dataDir ? "/var/lib",
    logDir ? "/var/log",
    user ? name,
    uid ? 999,
    gid ? 999,
    healthCheck ? {
      Test = [ "CMD-SHELL" "rabbitmqctl status || exit 1" ];
      Interval = 15000000000;
      Timeout = 10000000000;
      Retries = 3;
    },
    extraPackages ? _: [ pkgs.coreutils ],
    ...
  } @ args:

    let
      extraPorts = lib.optional (managementPort != null) managementPort;
    in
    mkContainer (args // {
      type = "cache";
      port = port;
      extraPorts = extraPorts;
      volumes = {
        "${dataDir}" = {};
        "${logDir}" = {};
      };
      user = user;
      uid = uid;
      gid = gid;
      workingDir = dataDir;
      healthCheck = healthCheck;
      extraPackages = extraPackages;
    });

  # Multi-architecture build support (FR-BUILD-003)
  mkMultiArchContainer = {
    name,
    version,
    configPath ? null,
    systems ? [ "x86_64-linux" "aarch64-linux" ],
    ...
  } @ args:

    builtins.listToAttrs (map (system:
      let
        systemPkgs = import <nixpkgs> { inherit system; };
        systemDocks = import ../../../lib/docks.nix { pkgs = systemPkgs; };
      in {
        name = "${system}";
        value = mkContainer (args // {
          pkgs = systemPkgs;
          docks = systemDocks;
        });
      }) systems);

  # Service catalog for core openDesk services
  # Uses local docks.nix for all builds (no external dependencies)
  serviceCatalog = rec {
    mariadb = mkDatabaseContainer {
      name = "mariadb";
      version = "11.4.4";
      port = 3306;
      user = "mariadb";
      dataDir = "/var/lib/mariadb";
    };

    postgresql = mkDatabaseContainer {
      name = "postgresql";
      version = "16.3";
      port = 5432;
      user = "postgres";
      dataDir = "/var/lib/postgresql";
      healthCheck = {
        Test = [ "CMD-SHELL" "pg_isready -U postgres || exit 1" ];
        Interval = 10000000000;
        Timeout = 5000000000;
        Retries = 5;
        StartPeriod = 300000000000;
      };
    };

    redis = mkCacheContainer {
      name = "redis";
      version = "7.2.4";
      port = 6379;
      user = "redis";
      dataDir = "/var/lib/redis";
    };

    nginx = mkWebContainer {
      name = "nginx";
      version = "1.25.3";
      httpPort = 80;
      httpsPort = 443;
      user = "nginx";
      uid = 101;
      gid = 101;
    };
  };

  # Build all services in the catalog
  buildAll =
    builtins.mapAttrs (name: value: value) serviceCatalog;
}

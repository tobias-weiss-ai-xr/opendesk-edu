# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
NixOS Container Library for openDesk
Provides standardized container builders using docks.nix
OpenSpec: FR-BUILD-001 through FR-BUILD-007
"""

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
    "org.opencontainers.image.title" = "${config.name or "unknown"}";
    "org.opencontainers.image.description" = "openDesk service container built with NixOS";
    "org.opencontainers.image.version" = "${config.version or "latest"}";
    "org.opencontainers.image.authors" = "openDesk Edu Team";
    "org.opencontainers.image.url" = "https://opendesk.hrz.uni-marburg.de";
    "org.opencontainers.image.documentation" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.source" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.licenses" = "Apache-2.0";
    "com.opendesk.service" = "${config.name or "unknown"}";
    "com.opendesk.environment" = "${config.environment or "production"}";
    "com.opendesk.managed" = "true";
    "com.opendesk.nixos" = "true";
  };

  # Security configuration for containers (FR-IMAGE-001, FR-IMAGE-002, FR-IMAGE-003)
  securityConfig = {
    polkit.enable = false;
    openssh.enable = false;
    sudo.enable = false;
    
    # Kernel hardening
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
    };
  };

  # Standard volumes for different service types
  standardVolumes = {
    database = {
      "/var/lib/${name}" = {};
      "/var/log/${name}" = {};
      "/etc/${name}" = {};
    };
    web = {
      "/var/www" = {};
      "/var/log/${name}" = {};
      "/tmp" = {};
    };
    cache = {
      "/var/lib/${name}" = {};
      "/var/log/${name}" = {};
    };
    minimal = { };
  };

in rec {

  # Generic container builder
  mkContainer = {
    name,
    version,
    configPath,
    docks ? docks,
    pkgs ? pkgs,
    type ? "minimal",
    port ? null,
    extraPorts ? [ ],
    volumes ? standardVolumes.${type} or { },
    extraEnv ? [ ],
    user ? "nobody",
    uid ? 65534,
    gid ? 65534,
    workingDir ? "/",
    cmd ? [ "/bin/sh" ],
    entrypoint ? null,
    healthCheck ? null,
    extraPackages ? _: [ ],
    overlays ? [ ],
    ociLabels ? { },
    securityProfile ? "default",
    ...
  } @args:

  let
    # Apply overlays to pkgs
    nixpkgsWithOverlays = pkgs // {
      overlays = (pkgs.overlays or [ ]) ++ overlays;
    };
    
    # Full configuration merge
    fullConfig = defaultContainerConfig // {
      inherit user workingDir;
      ExposedPorts = builtins.listToAttrs (
        map (p: { name = "${toString p}/tcp"; value = {}; }) (
          if port != null then [ port ] ++ extraPorts else extraPorts
        )
      );
      Volumes = volumes;
      Env = defaultContainerConfig.env ++ extraEnv;
      User = user;
      WorkingDir = workingDir;
      Cmd = cmd;
      Entrypoint = entrypoint;
      HealthCheck = healthCheck or defaultContainerConfig.healthCheck;
    };
    
    # Full OCI labels
    fullOCILabels = defaultOCILabels // ociLabels;
    
    # Load the NixOS configuration
    nixosConfig = import configPath {
      inherit pkgs nixpkgsWithOverlays;
    };
    
    # Merge with security config
    finalConfig = nixosConfig // securityConfig;
    
  in
  docks.mkImage ({
    name = name;
    tag = version;
    config = finalConfig;
    extraPackages = extraPackages;
    containerConfig = fullConfig;
  } // fullOCILabels);

  # Database container builder (FR-BUILD-001, FR-IMAGE-001)
  mkDatabaseContainer = {
    name,
    version,
    configPath,
    port ? 3306,
    dataDir ? "/var/lib/${name}",
    logDir ? "/var/log/${name}",
    confDir ? "/etc/${name}",
    initDir ? "/docker-entrypoint-initdb.d",
    user ? name,
    uid ? 999,
    gid ? 999,
    healthCheck ? {
      test = [ "CMD-SHELL" "${name}-admin ping --silent 2>/dev/null || exit 1" ];
      interval = 10000000000;
      timeout = 5000000000;
      retries = 5;
      startPeriod = 300000000000; # 5 minutes
    },
    extraPackages ? _: [ pkgs.openssl pkgs.procps pkgs.coreutils ],
    ...
  } @args:

  let
    volumes = {
      "${dataDir}" = {};
      "${logDir}" = {};
      "${confDir}" = {};
      "${initDir}" = {};
    };
    
    extraEnv = [
      "${lib.toUpper name}_ROOT_PASSWORD="
      "${lib.toUpper name}_DATABASE=${name}"
      "${lib.toUpper name}_USER=${name}"
    ];
    
  in
  mkContainer (args // {
    inherit name version configPath;
    type = "database";
    port = port;
    volumes = volumes;
    extraEnv = extraEnv;
    user = user;
    uid = uid;
    gid = gid;
    workingDir = dataDir;
    healthCheck = healthCheck;
    extraPackages = extraPackages;
  });

  # Web service container builder
  mkWebContainer = {
    name,
    version,
    configPath,
    httpPort ? 8080,
    httpsPort ? 8443,
    user ? "www-data",
    uid ? 1000,
    gid ? 1000,
    workingDir ? "/var/www/${name}",
    healthCheck ? {
      test = [ "CMD-SHELL" "curl -f http://127.0.0.1:${toString httpPort}/ || exit 1" ];
      interval = 10000000000;
      timeout = 5000000000;
      retries = 3;
    },
    extraPackages ? _: [ pkgs.curl pkgs.coreutils ],
    ...
  } @args:

  let
    volumes = {
      "/var/www" = {};
      "/var/log/${name}" = {};
      "/tmp" = {};
    };
    
    extraPorts = lib.filter (p: p != null) [ httpPort httpsPort ];
    
  in
  mkContainer (args // {
    inherit name version configPath;
    type = "web";
    port = httpPort;
    extraPorts = extraPorts;
    volumes = volumes;
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
    configPath,
    port ? 6379,
    dataDir ? "/var/lib/${name}",
    logDir ? "/var/log/${name}",
    user ? name,
    uid ? 999,
    gid ? 999,
    healthCheck ? {
      test = [ "CMD-SHELL" "${name}-cli ping | grep PONG || exit 1" ];
      interval = 5000000000;
      timeout = 3000000000;
      retries = 3;
    },
    extraPackages ? _: [ pkgs.coreutils ],
    ...
  } @args:

  let
    volumes = {
      "${dataDir}" = {};
      "${logDir}" = {};
    };
    
  in
  mkContainer (args // {
    inherit name version configPath;
    type = "cache";
    port = port;
    volumes = volumes;
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
    configPath,
    port ? 5672,
    managementPort ? 15672,
    dataDir ? "/var/lib/${name}",
    logDir ? "/var/log/${name}",
    user ? name,
    uid ? 999,
    gid ? 999,
    healthCheck ? {
      test = [ "CMD-SHELL" "${name}-ctl status || exit 1" ];
      interval = 15000000000;
      timeout = 10000000000;
      retries = 3;
    },
    extraPackages ? _: [ pkgs.coreutils ],
    ...
  } @args:

  let
    volumes = {
      "${dataDir}" = {};
      "${logDir}" = {};
    };
    
    extraPorts = lib.filter (p: p != null) [ port managementPort ];
    
  in
  mkContainer (args // {
    inherit name version configPath;
    type = "cache";
    port = port;
    extraPorts = extraPorts;
    volumes = volumes;
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
    configPath,
    systems ? [ "x86_64-linux" "aarch64-linux" ],
    ...
  } @args:

  let
    buildForSystem = system: 
      mkContainer (args // {
        pkgs = import <nixpkgs> { inherit system; };
        docks = import (builtins.fetchGit {
          url = "https://github.com/dockernix/docks.nix";
          ref = "refs/tags/0.5.0";
        }) { pkgs = import <nixpkgs> { inherit system; }; };
      });
    
  in
  builtins.listToAttrs (map (system: {
    name = "${name}-${system}";
    value = buildForSystem system;
  }) systems);

  # Service catalog for all openDesk services
  serviceCatalog = rec {
    mariadb = mkDatabaseContainer {
      name = "mariadb";
      version = "11.4.4";
      configPath = ./docker/services/mariadb/nixos/configuration.nix;
    };
    
    postgresql = mkDatabaseContainer {
      name = "postgresql";
      version = "16.3";
      configPath = ./docker/services/postgresql/nixos/configuration.nix;
      port = 5432;
      user = "postgres";
    };
    
    redis = mkCacheContainer {
      name = "redis";
      version = "7.2.4";
      configPath = ./docker/services/redis/nixos/configuration.nix;
      port = 6379;
    };
    
    nginx = mkWebContainer {
      name = "nginx";
      version = "1.25.3";
      configPath = ./docker/services/nginx/nixos/configuration.nix;
      httpPort = 80;
      httpsPort = 443;
      user = "nginx";
      uid = 101;
      gid = 101;
    };
    
    # Add more services here as they are migrated
  };

  # Build all services
  buildAll = 
    builtins.listToAttrs (
      map (attr: {
        name = "${attr}-nixos";
        value = builtins.getAttr attr serviceCatalog;
      }) (builtins.attrNames serviceCatalog)
    );
}

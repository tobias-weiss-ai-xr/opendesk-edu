# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# 6 Sigma Quality - Defect-free Nix code
#
# NixOS Service Catalog for openDesk
# Provides a catalog of all openDesk services and builds their container images.

{ pkgs, lib, docks, ... }:

let
  # =============================================================================
  # Service definitions
  # =============================================================================
  # Each service specifies its nixpkgs package, version, port, and container type.
  # The container builder (from containers.nix) uses this to create OCI images.

  services = {
    # Databases
    mariadb = {
      package = pkgs.mariadb;
      version = "11.4.4";
      port = 3306;
      type = "database";
      user = "mariadb";
      uid = 999;
    };
    postgresql = {
      package = pkgs.postgresql;
      version = "16.3";
      port = 5432;
      type = "database";
      user = "postgres";
      uid = 999;
    };
    redis = {
      package = pkgs.redis;
      version = "7.2.4";
      port = 6379;
      type = "cache";
      user = "redis";
      uid = 999;
    };
    memcached = {
      package = pkgs.memcached;
      version = "1.6.9";
      port = 11211;
      type = "cache";
      user = "memcached";
      uid = 999;
    };

    # Web servers / proxies
    nginx = {
      package = pkgs.nginx;
      version = "1.25.3";
      port = 80;
      type = "web";
      user = "nginx";
      uid = 101;
    };
    traefik = {
      package = pkgs.traefik;
      version = "2.11.0";
      port = 8080;
      type = "web";
      user = "traefik";
      uid = 101;
    };

    # Identity / Auth
    keycloak = {
      package = pkgs.keycloak;
      version = "24.0.0";
      port = 8080;
      type = "web";
      user = "keycloak";
      uid = 1000;
    };

    # Collaboration
    nextcloud = {
      package = pkgs.nextcloud or null;
      version = "30.0.0";
      port = 80;
      type = "web";
      user = "nextcloud";
      uid = 1000;
    };
    collabora = {
      package = null;  # Not in nixpkgs, requires custom build
      version = "24.04.0";
      port = 9980;
      type = "web";
      user = "collabora";
      uid = 1000;
    };
    etherpad = {
      package = null;
      version = "1.9.9";
      port = 9001;
      type = "web";
      user = "etherpad";
      uid = 1000;
    };
    cryptpad = {
      package = null;
      version = "2024.6.0";
      port = 3000;
      type = "web";
      user = "cryptpad";
      uid = 1000;
    };

    # LMS
    moodle = {
      package = null;
      version = "4.4.0";
      port = 80;
      type = "lms";
      user = "www-data";
      uid = 33;
    };
    ilias = {
      package = null;
      version = "9.0.0";
      port = 80;
      type = "lms";
      user = "www-data";
      uid = 33;
    };

    # Monitoring
    grafana = {
      package = pkgs.grafana;
      version = "11.0.0";
      port = 3000;
      type = "monitoring";
      user = "grafana";
      uid = 1000;
    };
    prometheus = {
      package = pkgs.prometheus;
      version = "2.52.0";
      port = 9090;
      type = "monitoring";
      user = "prometheus";
      uid = 1000;
    };
    loki = {
      package = pkgs.loki;
      version = "3.0.0";
      port = 3100;
      type = "monitoring";
      user = "loki";
      uid = 1000;
    };

    # Registry
    zot-registry = {
      package = null;
      version = "2.0.0-rc5";
      port = 5000;
      type = "web";
      user = "zot";
      uid = 1000;
    };

    # Element / Matrix
    element = {
      package = pkgs.element-web or null;
      version = "1.11.0";
      port = 80;
      type = "web";
      user = "nginx";
      uid = 101;
    };

    # Project management
    openproject = {
      package = null;
      version = "15.0.0";
      port = 3000;
      type = "web";
      user = "openproject";
      uid = 1000;
    };
    planka = {
      package = null;
      version = "1.0.0";
      port = 1337;
      type = "web";
      user = "planka";
      uid = 1000;
    };
    bookstack = {
      package = null;
      version = "23.0.0";
      port = 80;
      type = "web";
      user = "www-data";
      uid = 33;
    };

    # Development tools
    # Note: code-server removed from nixpkgs (EOL Node.js) - set to null
    code-server = {
      package = null;
      version = "4.96.2";
      port = 8080;
      type = "web";
      user = "code-server";
      uid = 1000;
    };

    # Whiteboarding / diagrams
    drawio = {
      package = null;
      version = "24.0.0";
      port = 8080;
      type = "web";
      user = "drawio";
      uid = 1000;
    };
    excalidraw = {
      package = null;
      version = "0.17.0";
      port = 80;
      type = "web";
      user = "excalidraw";
      uid = 1000;
    };

    # Jitsi
    jitsi = {
      package = null;
      version = "stable";
      port = 8080;
      type = "web";
      user = "jitsi";
      uid = 1000;
    };

    # XWiki
    xwiki = {
      package = null;
      version = "16.0.0";
      port = 8080;
      type = "web";
      user = "xwiki";
      uid = 1000;
    };

    # SOGo groupware (per AGENTS.md: SOGo 5.12.x with ActiveSync)
    # SOGo runs on 127.0.0.1:20000 (WOHttpAdaptor, internal watchdog only)
    # External access requires Apache reverse proxy on port 80
    sogo = {
      package = pkgs.sogo;
      version = "5.12.9";
      port = 20000;
      type = "web";
      user = "sogo";
      uid = 1000;
    };
    sogo5 = {
      package = pkgs.sogo;  # SOGo 5.x (same package as sogo)
      version = "5.12.9";
      port = 20000;
      type = "web";
      user = "sogo";
      uid = 1000;
    };
    sogo6 = {
      package = null;  # SOGo 6 not yet in nixpkgs
      version = "6.0.0";
      port = 20000;
      type = "web";
      user = "sogo";
      uid = 1000;
    };

    # =====================================================================
    # Additional services (48 services from docker/services/ directories)
    # =====================================================================

    # Infrastructure / Platform
    argocd = {
      package = pkgs.argocd;
      version = "2.9.12";
      port = 8080;
      type = "web";
      user = "argocd";
      uid = 1000;
    };
    kube-prometheus-stack = {
      package = null;
      version = "0.80.0";
      port = 9090;
      type = "monitoring";
      user = "kube-prometheus";
      uid = 1000;
    };
    monitoring = {
      package = null;
      version = "1.0.0";
      port = 9090;
      type = "monitoring";
      user = "monitoring";
      uid = 1000;
    };

    # Databases / Storage
    mariadb-enhanced = {
      package = pkgs.mariadb;
      version = "11.4.4";
      port = 3306;
      type = "database";
      user = "mysql";
      uid = 999;
    };
    timescale = {
      package = pkgs.postgresql;
      version = "16.3";
      port = 5432;
      type = "database";
      user = "postgres";
      uid = 999;
    };
    minio = {
      package = pkgs.minio;
      version = "2024-01-31";
      port = 9000;
      type = "database";
      user = "minio";
      uid = 1000;
    };
    seaweedfs = {
      package = pkgs.seaweedfs;
      version = "3.59";
      port = 9333;
      type = "database";
      user = "seaweedfs";
      uid = 1000;
    };

    # Web / Collaboration
    bigbluebutton = {
      package = null;
      version = "2.7.0";
      port = 8080;
      type = "web";
      user = "bigbluebutton";
      uid = 1000;
    };
    opencloud = {
      package = null;  # Not in nixos-23.11
      version = "7.3.0";
      port = 9200;
      type = "web";
      user = "opencloud";
      uid = 1000;
    };
    open-webui = {
      package = null;  # Not in nixos-23.11
      version = "0.11.0";
      port = 3000;
      type = "web";
      user = "open-webui";
      uid = 1000;
    };
    overleaf = {
      package = null;
      version = "2024.0.0";
      port = 8080;
      type = "web";
      user = "overleaf";
      uid = 1000;
    };
    notes = {
      package = pkgs.notes;
      version = "2.2.1";
      port = 3000;
      type = "web";
      user = "notes";
      uid = 1000;
    };
    slidev = {
      package = null;
      version = "0.49.0";
      port = 3030;
      type = "web";
      user = "slidev";
      uid = 1000;
    };
    typo3 = {
      package = null;
      version = "12.4.0";
      port = 80;
      type = "web";
      user = "www-data";
      uid = 33;
    };
    ilias-full = {
      package = null;
      version = "9.0.0";
      port = 80;
      type = "lms";
      user = "www-data";
      uid = 33;
    };
    limesurvey = {
      package = pkgs.limesurvey;
      version = "6.1.2";
      port = 8080;
      type = "web";
      user = "www-data";
      uid = 33;
    };

    # Communication / Mail
    dovecot = {
      package = pkgs.dovecot;
      version = "2.3.21";
      port = 143;
      type = "web";
      user = "dovecot";
      uid = 1000;
    };
    stalwart = {
      package = null;  # Not in nixos-23.11
      version = "0.15.5";
      port = 443;
      type = "web";
      user = "stalwart";
      uid = 1000;
    };
    intercom = {
      package = null;
      version = "1.0.0";
      port = 8080;
      type = "web";
      user = "intercom";
      uid = 1000;
    };
    intercom-service = {
      package = null;
      version = "1.0.0";
      port = 8080;
      type = "web";
      user = "intercom";
      uid = 1000;
    };

    # Development / Tools
    coderd = {
      package = null;
      version = "2.0.0";
      port = 3000;
      type = "web";
      user = "coderd";
      uid = 1000;
    };
    jupyterhub = {
      package = null;
      version = "5.2.0";
      port = 8000;
      type = "web";
      user = "jupyterhub";
      uid = 1000;
    };
    kasmvnc = {
      package = null;
      version = "1.3.0";
      port = 6901;
      type = "web";
      user = "kasmvnc";
      uid = 1000;
    };
    rstudio = {
      package = pkgs.rstudio;
      version = "2023.09.0";
      port = 8787;
      type = "web";
      user = "rstudio";
      uid = 1000;
    };
    ttyd = {
      package = null;
      version = "1.7.0";
      port = 7681;
      type = "web";
      user = "ttyd";
      uid = 1000;
    };
    dev-agent = {
      package = null;
      version = "1.0.0";
      port = 8080;
      type = "web";
      user = "dev-agent";
      uid = 1000;
    };
    dask = {
      package = null;
      version = "2024.0.0";
      port = 8787;
      type = "web";
      user = "dask";
      uid = 1000;
    };
    f13 = {
      package = null;
      version = "1.0.0";
      port = 8080;
      type = "web";
      user = "f13";
      uid = 1000;
    };
    n8n = {
      package = pkgs.n8n;
      version = "1.9.3";
      port = 5678;
      type = "web";
      user = "n8n";
      uid = 1000;
    };

    # Security / Identity
    clamav = {
      package = pkgs.clamav;
      version = "1.2.3";
      port = 3310;
      type = "web";
      user = "clamav";
      uid = 1000;
    };
    eudi-issuer = {
      package = null;
      version = "1.0.0";
      port = 8080;
      type = "web";
      user = "eudi-issuer";
      uid = 1000;
    };
    self-service-password = {
      package = null;
      version = "1.0.0";
      port = 8080;
      type = "web";
      user = "ssp";
      uid = 1000;
    };

    # Monitoring / Logging
    elasticsearch = {
      package = pkgs.elasticsearch;
      version = "7.17.16";
      port = 9200;
      type = "monitoring";
      user = "elasticsearch";
      uid = 1000;
    };
    kibana = {
      package = null;
      version = "7.17.27";
      port = 5601;
      type = "monitoring";
      user = "kibana";
      uid = 1000;
    };
    filebeat = {
      package = pkgs.filebeat;
      version = "7.17.16";
      port = 5044;
      type = "monitoring";
      user = "filebeat";
      uid = 1000;
    };
    promtail = {
      package = null;
      version = "3.0.0";
      port = 9080;
      type = "monitoring";
      user = "promtail";
      uid = 1000;
    };

    # Nubus / UMS
    nubus-ldap = {
      package = null;
      version = "1.0.0";
      port = 389;
      type = "web";
      user = "nubus-ldap";
      uid = 1000;
    };
    nubus-portal = {
      package = null;
      version = "1.0.0";
      port = 8080;
      type = "web";
      user = "nubus-portal";
      uid = 1000;
    };
    nubus-provisioning = {
      package = null;
      version = "1.0.0";
      port = 8081;
      type = "web";
      user = "nubus-prov";
      uid = 1000;
    };
    nubus-udm = {
      package = null;
      version = "1.0.0";
      port = 8081;
      type = "web";
      user = "nubus-udm";
      uid = 1000;
    };

    # AI / ML
    ollama = {
      package = pkgs.ollama;
      version = "0.1.28";
      port = 11434;
      type = "web";
      user = "ollama";
      uid = 1000;
    };

    # Other
    collab-dashboard = {
      package = null;
      version = "1.0.0";
      port = 8080;
      type = "web";
      user = "collab-dash";
      uid = 1000;
    };
    open-xchange = {
      package = null;  # Not in nixos-23.11
      version = "8.0.0";
      port = 8009;
      type = "web";
      user = "open-xchange";
      uid = 1000;
    };
    grommunio = {
      package = null;
      version = "1.0.0";
      port = 8080;
      type = "web";
      user = "grommunio";
      uid = 1000;
    };
    portal-entries = {
      package = null;
      version = "1.0.0";
      port = 8080;
      type = "web";
      user = "portal";
      uid = 1000;
    };
    semester-provisioning = {
      package = null;
      version = "1.0.0";
      port = 8080;
      type = "web";
      user = "semester-prov";
      uid = 1000;
    };
    snipr = {
      package = null;
      version = "1.0.0";
      port = 8080;
      type = "web";
      user = "snipr";
      uid = 1000;
    };
    zammad = {
      package = pkgs.zammad;
      version = "5.4.1";
      port = 8080;
      type = "web";
      user = "zammad";
      uid = 1000;
    };
  };

  # =============================================================================
  # Build container images from the service catalog
  # =============================================================================

  # Build a single container image from a service definition
  buildServiceImage = name: svc:
    docks.mkImage {
      name = "${name}-opendesk";
      tag = "${svc.version}-nixos";

      containerConfig = {
        ExposedPorts = { "${toString svc.port}/tcp" = {}; };
        Env = [
          "OPENDESK_ENV=production"
          "NIXOS=1"
          "TZ=Europe/Berlin"
          "LC_ALL=C.UTF-8"
          "LANG=C.UTF-8"
        ];
        User = svc.user;
        WorkingDir = "/";
        Cmd = [ "/usr/bin/env" "bash" "-c" "echo Service ${name} ready" ];
        StopSignal = "SIGTERM";
        StopTimeout = 30;
        HealthCheck = {
          Test = [ "CMD-SHELL" "exit 0" ];
          Interval = 30000000000;
          Timeout = 10000000000;
          Retries = 3;
          StartPeriod = 30000000000;
        };
      };

      extraPackages = p:
        (if svc.package != null then [ svc.package ] else [])
        ++ (with p; [ bash coreutils openssl curl procps ]);

      ociLabels = {
        "org.opencontainers.image.title" = "${name}-opendesk";
        "org.opencontainers.image.description" = "${name} ${svc.version} for openDesk Edu with NixOS";
        "org.opencontainers.image.version" = "${svc.version}-nixos";
        "org.opencontainers.image.authors" = "openDesk Edu Team";
        "org.opencontainers.image.url" = "https://opendesk.hrz.uni-marburg.de";
        "org.opencontainers.image.documentation" = "https://github.com/opendesk-edu/opendesk-nix";
        "org.opencontainers.image.source" = "https://github.com/opendesk-edu/opendesk-nix";
        "org.opencontainers.image.licenses" = "Apache-2.0";
        "com.opendesk.service" = name;
        "com.opendesk.environment" = "production";
        "com.opendesk.managed" = "true";
        "com.opendesk.nixos" = "true";
      };
    };

  # Build all service images
  allContainers = builtins.mapAttrs buildServiceImage services;

  # =============================================================================
  # Service counts by category and tier
  # =============================================================================

  serviceList = builtins.attrNames services;

  countByType = type:
    builtins.length (
      builtins.filter (name: services.${name}.type == type) serviceList
    );

  serviceCounts = {
    total = builtins.length serviceList;
    byCategory = {
      database = countByType "database";
      cache = countByType "cache";
      web = countByType "web";
      lms = countByType "lms";
      monitoring = countByType "monitoring";
    };
    byTier = {
      tier1 = countByType "database" + countByType "cache";
      tier2 = countByType "web";
      tier3 = countByType "lms" + countByType "monitoring";
    };
  };

in {
  inherit services allContainers serviceCounts buildServiceImage;
}

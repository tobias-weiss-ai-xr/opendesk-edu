# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
NixOS Service Catalog for openDesk
Central registry of all NixOS-containerized services
OpenSpec: FR-BUILD-001 through FR-BUILD-007
"""

{ 
  pkgs ? import <nixpkgs> { system = "x86_64-linux"; },
  docks ? import (builtins.fetchGit {
    url = "https://github.com/dockernix/docks.nix";
    ref = "refs/tags/0.5.0";
  }) { inherit pkgs; },
  lib ? pkgs.lib,
  ...
}:

let
  # Helper to import service configurations
  importService = path: config: 
    import path { inherit pkgs lib config; };
  
  # Standard service metadata
  serviceMetadata = {
    name = "";
    version = "";
    description = "";
    category = "";
    maintainer = "openDesk Edu Team";
    tier = "backend";  # backend, frontend, database, cache, infrastructure
    ports = [ ];
    exposedPorts = [ ];
    healthCheckPath = null;
    startupTime = "30s";  # Time for health check to pass
  };

  # Function to create a service entry
  mkService = {
    name,
    version,
    description ? "",
    category ? "other",
    tier ? "backend",
    ports ? [ ],
    configPath,
    defaultNixPath,
    extraConfig ? { },
    ...
  } @args:

  let
    serviceName = name;
    serviceVersion = version;
    configFullPath = configPath;
    defaultNixFullPath = defaultNixPath;
    
    # Load configuration
    nixosConfig = import configFullPath { inherit pkgs lib; };
    
    # Create the container
    container = import defaultNixFullPath {
      inherit pkgs docks;
    };
    
  in rec {
    inherit name version description category tier ports;
    configPath = configFullPath;
    defaultNixPath = defaultNixFullPath;
    container = container;
    nixosConfig = nixosConfig;
    metadata = serviceMetadata // {
      inherit name version description category tier;
      ports = ports;
      exposedPorts = builtins.filter (p: p != null) ports;
    };
  };

  # Service type classifiers
  serviceTypes = rec {
    database = {
      tier = "database";
      category = "database";
    };
    cache = {
      tier = "cache";
      category = "cache";
    };
    web = {
      tier = "frontend";
      category = "web";
    };
    backend = {
      tier = "backend";
      category = "application";
    };
    infrastructure = {
      tier = "infrastructure";
      category = "infrastructure";
    };
    monitoring = {
      tier = "monitoring";
      category = "monitoring";
    };
  };

in rec {
  inherit mkService serviceTypes;

  # Service catalog organized by category
  services = rec {
    # Databases
    mariadb = mkService {
      name = "mariadb";
      version = "11.4.4";
      description = "MariaDB database server for openDesk";
      category = "database";
      tier = "database";
      ports = [ 3306 ];
      configPath = ./docker/services/mariadb/nixos/configuration.nix;
      defaultNixPath = ./docker/services/mariadb/nixos/default.nix;
    } // serviceTypes.database;

    postgresql = mkService {
      name = "postgresql";
      version = "16.3";
      description = "PostgreSQL database server for openDesk";
      category = "database";
      tier = "database";
      ports = [ 5432 ];
      configPath = ./docker/services/postgresql/nixos/configuration.nix;
      defaultNixPath = ./docker/services/postgresql/nixos/default.nix;
    } // serviceTypes.database;

    # Cache
    redis = mkService {
      name = "redis";
      version = "7.2.4";
      description = "Redis cache server for openDesk";
      category = "cache";
      tier = "cache";
      ports = [ 6379 ];
      configPath = ./docker/services/redis/nixos/configuration.nix;
      defaultNixPath = ./docker/services/redis/nixos/default.nix;
    } // serviceTypes.cache;

    # Web Server
    nginx = mkService {
      name = "nginx";
      version = "1.25.3";
      description = "Nginx web server and reverse proxy for openDesk";
      category = "web";
      tier = "infrastructure";
      ports = [ 80 443 ];
      configPath = ./docker/services/nginx/nixos/configuration.nix;
      defaultNixPath = ./docker/services/nginx/nixos/default.nix;
    } // serviceTypes.infrastructure;

    # Ingress Controller
    traefik = mkService {
      name = "traefik";
      version = "v2.10.0";
      description = "Traefik ingress controller with TLS termination";
      category = "ingress";
      tier = "infrastructure";
      ports = [ 80 443 9000 ];
      configPath = ./docker/services/traefik/nixos/configuration.nix;
      defaultNixPath = ./docker/services/traefik/nixos/default.nix;
    } // serviceTypes.infrastructure;

    # Identity Provider
    keycloak = mkService {
      name = "keycloak";
      version = "24.0.0";
      description = "Keycloak identity provider with OAuth2, OIDC, SAML";
      category = "iam";
      tier = "backend";
      ports = [ 8080 8443 9000 ];
      configPath = ./docker/services/keycloak/nixos/configuration.nix;
      defaultNixPath = ./docker/services/keycloak/nixos/default.nix;
    } // serviceTypes.backend;

    # PHP-based applications
    moodle = mkService {
      name = "moodle";
      version = "4.4.0";
      description = "Moodle learning management system";
      category = "lms";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/moodle/nixos/configuration.nix;
      defaultNixPath = ./docker/services/moodle/nixos/default.nix;
    } // serviceTypes.backend;

    ilias = mkService {
      name = "ilias";
      version = "8.0.0";
      description = "ILIAS learning management system";
      category = "lms";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/ilias/nixos/configuration.nix;
      defaultNixPath = ./docker/services/ilias/nixos/default.nix;
    } // serviceTypes.backend;

    nextcloud = mkService {
      name = "nextcloud";
      version = "29.0.0";
      description = "Nextcloud file sharing and collaboration";
      category = "collaboration";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/nextcloud/nixos/configuration.nix;
      defaultNixPath = ./docker/services/nextcloud/nixos/default.nix;
    } // serviceTypes.backend;

    # Collaboration tools
    collabora = mkService {
      name = "collabora";
      version = "22.05.0";
      description = "Collabora Online office suite";
      category = "collaboration";
      tier = "backend";
      ports = [ 9980 ];
      configPath = ./docker/services/collabora/nixos/configuration.nix;
      defaultNixPath = ./docker/services/collabora/nixos/default.nix;
    } // serviceTypes.backend;

    # Project Management
    openproject = mkService {
      name = "openproject";
      version = "14.0.0";
      description = "OpenProject project management";
      category = "project-management";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/openproject/nixos/configuration.nix;
      defaultNixPath = ./docker/services/openproject/nixos/default.nix;
    } // serviceTypes.backend;

    # Node.js applications
    planka = mkService {
      name = "planka";
      version = "1.0.0";
      description = "Planka kanban board";
      category = "collaboration";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/planka/nixos/configuration.nix;
      defaultNixPath = ./docker/services/planka/nixos/default.nix;
    } // serviceTypes.backend;

    etherpad = mkService {
      name = "etherpad";
      version = "1.9.0";
      description = "Etherpad collaborative text editing";
      category = "collaboration";
      tier = "backend";
      ports = [ 9001 ];
      configPath = ./docker/services/etherpad/nixos/configuration.nix;
      defaultNixPath = ./docker/services/etherpad/nixos/default.nix;
    } // serviceTypes.backend;

    cryptpad = mkService {
      name = "cryptpad";
      version = "5.0.0";
      description = "CryptPad encrypted collaborative editing";
      category = "collaboration";
      tier = "backend";
      ports = [ 3000 ];
      configPath = ./docker/services/cryptpad/nixos/configuration.nix;
      defaultNixPath = ./docker/services/cryptpad/nixos/default.nix;
    } // serviceTypes.backend;

    drawio = mkService {
      name = "drawio";
      version = "21.0.0";
      description = "DrawIO diagramming tool";
      category = "collaboration";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/drawio/nixos/configuration.nix;
      defaultNixPath = ./docker/services/drawio/nixos/default.nix;
    } // serviceTypes.backend;

    excalidraw = mkService {
      name = "excalidraw";
      version = "0.17.0";
      description = "Excalidraw hand-drawn style diagrams";
      category = "collaboration";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/excalidraw/nixos/configuration.nix;
      defaultNixPath = ./docker/services/excalidraw/nixos/default.nix;
    } // serviceTypes.backend;

    # Communication
    rocketchat = mkService {
      name = "rocketchat";
      version = "6.0.0";
      description = "Rocket.Chat team communication";
      category = "communication";
      tier = "backend";
      ports = [ 3000 ];
      configPath = ./docker/services/rocketchat/nixos/configuration.nix;
      defaultNixPath = ./docker/services/rocketchat/nixos/default.nix;
    } // serviceTypes.backend;

    element = mkService {
      name = "element";
      version = "1.11.0";
      description = "Element Matrix client";
      category = "communication";
      tier = "frontend";
      ports = [ 8080 ];
      configPath = ./docker/services/element/nixos/configuration.nix;
      defaultNixPath = ./docker/services/element/nixos/default.nix;
    } // serviceTypes.frontend;

    jitsi = mkService {
      name = "jitsi";
      version = "8.0.0";
      description = "Jitsi Meet video conferencing";
      category = "communication";
      tier = "backend";
      ports = [ 8080 4443 10000 ];
      configPath = ./docker/services/jitsi/nixos/configuration.nix;
      defaultNixPath = ./docker/services/jitsi/nixos/default.nix;
    } // serviceTypes.backend;

    # Documentation
    bookstack = mkService {
      name = "bookstack";
      version = "v26.05.2";
      description = "BookStack documentation wiki";
      category = "documentation";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/bookstack/nixos/configuration.nix;
      defaultNixPath = ./docker/services/bookstack/nixos/default.nix;
    } // serviceTypes.backend;

    xwiki = mkService {
      name = "xwiki";
      version = "15.0.0";
      description = "XWiki enterprise wiki";
      category = "documentation";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/xwiki/nixos/configuration.nix;
      defaultNixPath = ./docker/services/xwiki/nixos/default.nix;
    } // serviceTypes.backend;

    # DevOps
    grafana = mkService {
      name = "grafana";
      version = "10.0.0";
      description = "Grafana dashboards and visualization";
      category = "monitoring";
      tier = "monitoring";
      ports = [ 3000 ];
      configPath = ./docker/services/grafana/nixos/configuration.nix;
      defaultNixPath = ./docker/services/grafana/nixos/default.nix;
    } // serviceTypes.monitoring;

    prometheus = mkService {
      name = "prometheus";
      version = "2.47.0";
      description = "Prometheus monitoring and alerting";
      category = "monitoring";
      tier = "monitoring";
      ports = [ 9090 ];
      configPath = ./docker/services/prometheus/nixos/configuration.nix;
      defaultNixPath = ./docker/services/prometheus/nixos/default.nix;
    } // serviceTypes.monitoring;

    # Infrastructure
    docker-registry = mkService {
      name = "docker-registry";
      version = "2.8.0";
      description = "Docker registry for container images";
      category = "registry";
      tier = "infrastructure";
      ports = [ 5000 ];
      configPath = ./docker/services/docker-registry/nixos/configuration.nix;
      defaultNixPath = ./docker/services/docker-registry/nixos/default.nix;
    } // serviceTypes.infrastructure;

    zot-registry = mkService {
      name = "zot-registry";
      version = "2.0.0";
      description = "Zot registry for OCI artifacts";
      category = "registry";
      tier = "infrastructure";
      ports = [ 8080 ];
      configPath = ./docker/services/zot-registry/nixos/configuration.nix;
      defaultNixPath = ./docker/services/zot-registry/nixos/default.nix;
    } // serviceTypes.infrastructure;
  };

  # Get all service names
  allServiceNames = builtins.attrNames services;

  # Get all containers
  allContainers = builtins.listToAttrs (
    map (name: {
      name = "${name}-nixos";
      value = services.${name}.container;
    }) allServiceNames
  );

  # Get services by category
  servicesByCategory = builtins.listToAttrs (
    map (category: {
      name = category;
      value = builtins.listToAttrs (
        map (name: {
          name = name;
          value = services.${name};
        }) (builtins.filterAttrs (n: v: v.category == category) services)
      );
    }) (lib.unique (map (n: services.${n}.category) allServiceNames))
  );

  # Get services by tier
  servicesByTier = builtins.listToAttrs (
    map (tier: {
      name = tier;
      value = builtins.listToAttrs (
        map (name: {
          name = name;
          value = services.${name};
        }) (builtins.filterAttrs (n: v: v.tier == tier) services)
      );
    }) (lib.unique (map (n: services.${n}.tier) allServiceNames))
  );

  # Utility functions
  filterServices = predicate: 
    builtins.filterAttrs predicate services;

  getServiceContainer = name: 
    services.${name}.container;

  getServiceConfig = name: 
    services.${name}.nixosConfig;

  getServiceMetadata = name: 
    services.${name}.metadata;

  # Counts
  serviceCounts = {
    total = builtins.length allServiceNames;
    byCategory = builtins.listToAttrs (
      map (category: {
        name = category;
        value = builtins.length (
          builtins.filterAttrs (n: v: v.category == category) services
        );
      }) (lib.unique (map (n: services.${n}.category) allServiceNames))
    );
    byTier = builtins.listToAttrs (
      map (tier: {
        name = tier;
        value = builtins.length (
          builtins.filterAttrs (n: v: v.tier == tier) services
        );
      }) (lib.unique (map (n: services.${n}.tier) allServiceNames))
    );
  };
}

    dev-agent = mkService {
      name = "dev-agent";
      version = "latest";
      description = "dev-agent service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/dev-agent/nixos/configuration.nix;
      defaultNixPath = ./docker/services/dev-agent/nixos/default.nix;
    } // serviceTypes.other;

    sogo5 = mkService {
      name = "sogo5";
      version = "latest";
      description = "sogo5 service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/sogo5/nixos/configuration.nix;
      defaultNixPath = ./docker/services/sogo5/nixos/default.nix;
    } // serviceTypes.other;

    sogo6 = mkService {
      name = "sogo6";
      version = "latest";
      description = "sogo6 groupware server for openDesk";
      category = "groupware";
      tier = "backend";
      ports = [ 20000 ];
      configPath = ./docker/services/sogo6/nixos/configuration.nix;
      defaultNixPath = ./docker/services/sogo6/nixos/default.nix;
    } // serviceTypes.groupware;

    argocd = mkService {
      name = "argocd";
      version = "latest";
      description = "argocd service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/argocd/nixos/configuration.nix;
      defaultNixPath = ./docker/services/argocd/nixos/default.nix;
    } // serviceTypes.other;

    bigbluebutton = mkService {
      name = "bigbluebutton";
      version = "latest";
      description = "bigbluebutton communication tool for openDesk";
      category = "communication";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/bigbluebutton/nixos/configuration.nix;
      defaultNixPath = ./docker/services/bigbluebutton/nixos/default.nix;
    } // serviceTypes.communication;

    clamav = mkService {
      name = "clamav";
      version = "latest";
      description = "clamav service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/clamav/nixos/configuration.nix;
      defaultNixPath = ./docker/services/clamav/nixos/default.nix;
    } // serviceTypes.other;

    coderd = mkService {
      name = "coderd";
      version = "latest";
      description = "coderd service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/coderd/nixos/configuration.nix;
      defaultNixPath = ./docker/services/coderd/nixos/default.nix;
    } // serviceTypes.other;

    code-server = mkService {
      name = "code-server";
      version = "latest";
      description = "code-server service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/code-server/nixos/configuration.nix;
      defaultNixPath = ./docker/services/code-server/nixos/default.nix;
    } // serviceTypes.other;

    collab-dashboard = mkService {
      name = "collab-dashboard";
      version = "latest";
      description = "collab-dashboard service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/collab-dashboard/nixos/configuration.nix;
      defaultNixPath = ./docker/services/collab-dashboard/nixos/default.nix;
    } // serviceTypes.other;

    dask = mkService {
      name = "dask";
      version = "latest";
      description = "dask service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/dask/nixos/configuration.nix;
      defaultNixPath = ./docker/services/dask/nixos/default.nix;
    } // serviceTypes.other;

    dovecot = mkService {
      name = "dovecot";
      version = "latest";
      description = "dovecot service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/dovecot/nixos/configuration.nix;
      defaultNixPath = ./docker/services/dovecot/nixos/default.nix;
    } // serviceTypes.other;

    elasticsearch = mkService {
      name = "elasticsearch";
      version = "latest";
      description = "elasticsearch infrastructure service";
      category = "infrastructure";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/elasticsearch/nixos/configuration.nix;
      defaultNixPath = ./docker/services/elasticsearch/nixos/default.nix;
    } // serviceTypes.infrastructure;

    eudi-issuer = mkService {
      name = "eudi-issuer";
      version = "latest";
      description = "eudi-issuer service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/eudi-issuer/nixos/configuration.nix;
      defaultNixPath = ./docker/services/eudi-issuer/nixos/default.nix;
    } // serviceTypes.other;

    f13 = mkService {
      name = "f13";
      version = "latest";
      description = "f13 service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/f13/nixos/configuration.nix;
      defaultNixPath = ./docker/services/f13/nixos/default.nix;
    } // serviceTypes.other;

    filebeat = mkService {
      name = "filebeat";
      version = "latest";
      description = "filebeat service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/filebeat/nixos/configuration.nix;
      defaultNixPath = ./docker/services/filebeat/nixos/default.nix;
    } // serviceTypes.other;

    grommunio = mkService {
      name = "grommunio";
      version = "latest";
      description = "grommunio service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/grommunio/nixos/configuration.nix;
      defaultNixPath = ./docker/services/grommunio/nixos/default.nix;
    } // serviceTypes.other;

    ilias-full = mkService {
      name = "ilias-full";
      version = "latest";
      description = "ilias-full service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/ilias-full/nixos/configuration.nix;
      defaultNixPath = ./docker/services/ilias-full/nixos/default.nix;
    } // serviceTypes.other;

    intercom = mkService {
      name = "intercom";
      version = "latest";
      description = "intercom service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/intercom/nixos/configuration.nix;
      defaultNixPath = ./docker/services/intercom/nixos/default.nix;
    } // serviceTypes.other;

    intercom-service = mkService {
      name = "intercom-service";
      version = "latest";
      description = "intercom-service service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/intercom-service/nixos/configuration.nix;
      defaultNixPath = ./docker/services/intercom-service/nixos/default.nix;
    } // serviceTypes.other;

    jupyterhub = mkService {
      name = "jupyterhub";
      version = "latest";
      description = "jupyterhub service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/jupyterhub/nixos/configuration.nix;
      defaultNixPath = ./docker/services/jupyterhub/nixos/default.nix;
    } // serviceTypes.other;

    kasmvnc = mkService {
      name = "kasmvnc";
      version = "latest";
      description = "kasmvnc service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/kasmvnc/nixos/configuration.nix;
      defaultNixPath = ./docker/services/kasmvnc/nixos/default.nix;
    } // serviceTypes.other;

    kibana = mkService {
      name = "kibana";
      version = "latest";
      description = "kibana infrastructure service";
      category = "infrastructure";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/kibana/nixos/configuration.nix;
      defaultNixPath = ./docker/services/kibana/nixos/default.nix;
    } // serviceTypes.infrastructure;

    kube-prometheus-stack = mkService {
      name = "kube-prometheus-stack";
      version = "latest";
      description = "kube-prometheus-stack service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/kube-prometheus-stack/nixos/configuration.nix;
      defaultNixPath = ./docker/services/kube-prometheus-stack/nixos/default.nix;
    } // serviceTypes.other;

    limesurvey = mkService {
      name = "limesurvey";
      version = "latest";
      description = "limesurvey service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/limesurvey/nixos/configuration.nix;
      defaultNixPath = ./docker/services/limesurvey/nixos/default.nix;
    } // serviceTypes.other;

    loki = mkService {
      name = "loki";
      version = "latest";
      description = "loki monitoring tool for openDesk";
      category = "monitoring";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/loki/nixos/configuration.nix;
      defaultNixPath = ./docker/services/loki/nixos/default.nix;
    } // serviceTypes.monitoring;

    mariadb-enhanced = mkService {
      name = "mariadb-enhanced";
      version = "latest";
      description = "mariadb-enhanced service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/mariadb-enhanced/nixos/configuration.nix;
      defaultNixPath = ./docker/services/mariadb-enhanced/nixos/default.nix;
    } // serviceTypes.other;

    memcached = mkService {
      name = "memcached";
      version = "latest";
      description = "memcached cache server for openDesk";
      category = "cache";
      tier = "infrastructure";
      ports = [ 6379 ];
      configPath = ./docker/services/memcached/nixos/configuration.nix;
      defaultNixPath = ./docker/services/memcached/nixos/default.nix;
    } // serviceTypes.cache;

    minio = mkService {
      name = "minio";
      version = "latest";
      description = "minio infrastructure service";
      category = "infrastructure";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/minio/nixos/configuration.nix;
      defaultNixPath = ./docker/services/minio/nixos/default.nix;
    } // serviceTypes.infrastructure;

    monitoring = mkService {
      name = "monitoring";
      version = "latest";
      description = "monitoring service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/monitoring/nixos/configuration.nix;
      defaultNixPath = ./docker/services/monitoring/nixos/default.nix;
    } // serviceTypes.other;

    n8n = mkService {
      name = "n8n";
      version = "latest";
      description = "n8n service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/n8n/nixos/configuration.nix;
      defaultNixPath = ./docker/services/n8n/nixos/default.nix;
    } // serviceTypes.other;

    notes = mkService {
      name = "notes";
      version = "latest";
      description = "notes service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/notes/nixos/configuration.nix;
      defaultNixPath = ./docker/services/notes/nixos/default.nix;
    } // serviceTypes.other;

    nubus-ldap = mkService {
      name = "nubus-ldap";
      version = "latest";
      description = "nubus-ldap service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/nubus-ldap/nixos/configuration.nix;
      defaultNixPath = ./docker/services/nubus-ldap/nixos/default.nix;
    } // serviceTypes.other;

    nubus-portal = mkService {
      name = "nubus-portal";
      version = "latest";
      description = "nubus-portal service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/nubus-portal/nixos/configuration.nix;
      defaultNixPath = ./docker/services/nubus-portal/nixos/default.nix;
    } // serviceTypes.other;

    nubus-provisioning = mkService {
      name = "nubus-provisioning";
      version = "latest";
      description = "nubus-provisioning service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/nubus-provisioning/nixos/configuration.nix;
      defaultNixPath = ./docker/services/nubus-provisioning/nixos/default.nix;
    } // serviceTypes.other;

    nubus-udm = mkService {
      name = "nubus-udm";
      version = "latest";
      description = "nubus-udm service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/nubus-udm/nixos/configuration.nix;
      defaultNixPath = ./docker/services/nubus-udm/nixos/default.nix;
    } // serviceTypes.other;

    ollama = mkService {
      name = "ollama";
      version = "latest";
      description = "ollama service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/ollama/nixos/configuration.nix;
      defaultNixPath = ./docker/services/ollama/nixos/default.nix;
    } // serviceTypes.other;

    opencloud = mkService {
      name = "opencloud";
      version = "latest";
      description = "opencloud service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/opencloud/nixos/configuration.nix;
      defaultNixPath = ./docker/services/opencloud/nixos/default.nix;
    } // serviceTypes.other;

    open-webui = mkService {
      name = "open-webui";
      version = "latest";
      description = "open-webui service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/open-webui/nixos/configuration.nix;
      defaultNixPath = ./docker/services/open-webui/nixos/default.nix;
    } // serviceTypes.other;

    open-xchange = mkService {
      name = "open-xchange";
      version = "latest";
      description = "open-xchange service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/open-xchange/nixos/configuration.nix;
      defaultNixPath = ./docker/services/open-xchange/nixos/default.nix;
    } // serviceTypes.other;

    overleaf = mkService {
      name = "overleaf";
      version = "latest";
      description = "overleaf service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/overleaf/nixos/configuration.nix;
      defaultNixPath = ./docker/services/overleaf/nixos/default.nix;
    } // serviceTypes.other;

    portal-entries = mkService {
      name = "portal-entries";
      version = "latest";
      description = "portal-entries service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/portal-entries/nixos/configuration.nix;
      defaultNixPath = ./docker/services/portal-entries/nixos/default.nix;
    } // serviceTypes.other;

    promtail = mkService {
      name = "promtail";
      version = "latest";
      description = "promtail service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/promtail/nixos/configuration.nix;
      defaultNixPath = ./docker/services/promtail/nixos/default.nix;
    } // serviceTypes.other;

    rstudio = mkService {
      name = "rstudio";
      version = "latest";
      description = "rstudio service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/rstudio/nixos/configuration.nix;
      defaultNixPath = ./docker/services/rstudio/nixos/default.nix;
    } // serviceTypes.other;

    seaweedfs = mkService {
      name = "seaweedfs";
      version = "latest";
      description = "seaweedfs service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/seaweedfs/nixos/configuration.nix;
      defaultNixPath = ./docker/services/seaweedfs/nixos/default.nix;
    } // serviceTypes.other;

    self-service-password = mkService {
      name = "self-service-password";
      version = "latest";
      description = "self-service-password service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/self-service-password/nixos/configuration.nix;
      defaultNixPath = ./docker/services/self-service-password/nixos/default.nix;
    } // serviceTypes.other;

    semester-provisioning = mkService {
      name = "semester-provisioning";
      version = "latest";
      description = "semester-provisioning service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/semester-provisioning/nixos/configuration.nix;
      defaultNixPath = ./docker/services/semester-provisioning/nixos/default.nix;
    } // serviceTypes.other;

    slidev = mkService {
      name = "slidev";
      version = "latest";
      description = "slidev service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/slidev/nixos/configuration.nix;
      defaultNixPath = ./docker/services/slidev/nixos/default.nix;
    } // serviceTypes.other;

    snipr = mkService {
      name = "snipr";
      version = "latest";
      description = "snipr service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/snipr/nixos/configuration.nix;
      defaultNixPath = ./docker/services/snipr/nixos/default.nix;
    } // serviceTypes.other;

    sogo = mkService {
      name = "sogo";
      version = "latest";
      description = "sogo service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/sogo/nixos/configuration.nix;
      defaultNixPath = ./docker/services/sogo/nixos/default.nix;
    } // serviceTypes.other;

    stalwart = mkService {
      name = "stalwart";
      version = "latest";
      description = "stalwart service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/stalwart/nixos/configuration.nix;
      defaultNixPath = ./docker/services/stalwart/nixos/default.nix;
    } // serviceTypes.other;

    timescale = mkService {
      name = "timescale";
      version = "latest";
      description = "timescale service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/timescale/nixos/configuration.nix;
      defaultNixPath = ./docker/services/timescale/nixos/default.nix;
    } // serviceTypes.other;

    ttyd = mkService {
      name = "ttyd";
      version = "latest";
      description = "ttyd service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/ttyd/nixos/configuration.nix;
      defaultNixPath = ./docker/services/ttyd/nixos/default.nix;
    } // serviceTypes.other;

    typo3 = mkService {
      name = "typo3";
      version = "latest";
      description = "typo3 service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/typo3/nixos/configuration.nix;
      defaultNixPath = ./docker/services/typo3/nixos/default.nix;
    } // serviceTypes.other;

    zammad = mkService {
      name = "zammad";
      version = "latest";
      description = "zammad service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ 8080 ];
      configPath = ./docker/services/zammad/nixos/configuration.nix;
      defaultNixPath = ./docker/services/zammad/nixos/default.nix;
    } // serviceTypes.other;

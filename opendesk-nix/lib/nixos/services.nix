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

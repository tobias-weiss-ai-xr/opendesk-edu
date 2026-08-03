# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
openDesk NixOS Flake
Central flake for all NixOS-based container builds
"""

{
  description = "openDesk NixOS infrastructure with NixOS containers for all services";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    
    # Flake utilities
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { 
    self,
    nixpkgs,
    flake-utils,
    ...
  } @inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        docks = import ./lib/docks.nix { inherit pkgs; };
        
        # Import openDesk libraries
        types = import ./lib/types.nix { inherit pkgs lib; };
        security = import ./lib/security.nix { inherit pkgs lib; };
        sbom = import ./lib/sbom.nix { inherit pkgs lib; };
        registry = import ./lib/registry.nix { inherit pkgs lib; };
        k8s = import ./lib/k8s.nix { inherit pkgs lib; };
        build = import ./lib/build.nix { inherit pkgs lib docks; };
        security-scanning = import ./lib/security-scanning.nix { inherit pkgs lib; };
        cosign-lib = import ./lib/cosign.nix { inherit pkgs lib; };
        cicd = import ./lib/cicd.nix { inherit pkgs lib; };
        dev = import ./lib/dev.nix { inherit pkgs lib; };
        tests = import ./lib/tests.nix { inherit pkgs lib; };
        
        # NixOS-specific libraries
        nixos-containers = import ./lib/nixos/containers.nix { inherit pkgs lib docks; };
        nixos-security = import ./lib/nixos/security.nix { inherit pkgs lib; };
        nixos-services = import ./lib/nixos/services.nix { 
          inherit pkgs docks lib;
        };
        
        # Load service catalog
        service-catalog = nixos-services.services;
        all-containers = nixos-services.allContainers;
      in rec {
        # ======================================================================
        # PACKAGES - NixOS Container Images
        # ======================================================================
        
        packages = {
          inherit (all-containers) 
            mariadb-nixos 
            postgresql-nixos 
            redis-nixos 
            nginx-nixos 
            traefik-nixos 
            keycloak-nixos 
            moodle-nixos 
            ilias-nixos 
            nextcloud-nixos 
            collabora-nixos 
            openproject-nixos 
            planka-nixos 
            etherpad-nixos 
            cryptpad-nixos 
            drawio-nixos 
            excalidraw-nixos 
            rocketchat-nixos 
            element-nixos 
            jitsi-nixos 
            bookstack-nixos 
            xwiki-nixos 
            grafana-nixos 
            prometheus-nixos 
            docker-registry-nixos 
            zot-registry-nixos 
          ;
          
          # All NixOS containers
          all-nixos-images = pkgs.dockerTools.buildLayeredImages {
            images = builtins.attrValues all-containers;
            maxLayers = 100;
          };
          
          # Docker image builds (for backward compatibility)
          inherit (build) 
            mariadb-image 
            postgresql-image 
            redis-image 
          ;
          
          # Overlays
          overlays = {
            opendesk = import ./overlays/opendesk.nix;
          };
        };
        
        # ======================================================================
        # DEV SHELLS
        # ======================================================================
        
        devShells = {
          # Default shell with common tools
          default = dev.shells.default;
          
          # Minimal development shell
          minimal = dev.shells.minimal;
          
          # Infrastructure development shell
          infrastructure = dev.shells.infrastructure;
          
          # Security-focused shell
          security = dev.shells.security;
          
          # Nix development shell
          nix = dev.shells.nix;
          
          # Kubernetes development shell
          k8s = dev.shells.k8s;
          
          # Full openDesk shell
          full = dev.shells.full;
          
          # Service-specific shells
          mariadb = dev.shells.forService {
            serviceName = "mariadb";
            packages = [ pkgs.mycli pkgs.mysql ];
          };
          
          postgresql = dev.shells.forService {
            serviceName = "postgresql";
            packages = [ pkgs.postgresql pkgs.psql ];
          };
          
          redis = dev.shells.forService {
            serviceName = "redis";
            packages = [ pkgs.redis ];
          };
          
          keycloak = dev.shells.forService {
            serviceName = "keycloak";
            packages = [ inputs.nixpkgs.legacyPackages.${system}.jdk21 ];
          };
        };
        
        # ======================================================================
        # NIXOS MODULES
        # ======================================================================
        
        nixosModules = {
          # Security modules
          security-hardening = import ./lib/nixos/security.nix { inherit pkgs lib; };
          
          # Container modules
          containers = import ./lib/nixos/containers.nix { inherit pkgs lib docks; };
          
          # Service catalog
          service-catalog = import ./lib/nixos/services.nix { inherit pkgs lib docks; };
        };
        
        # ======================================================================
        # APPS - Kubernetes Resources
        # ======================================================================
        
        apps = {
          # All K8s services
          default = k8s.allServices;
          
          # Individual services
          inherit (k8s) 
            mariadb-service 
            postgresql-service 
            redis-service 
            nginx-service 
            traefik-service 
            keycloak-service 
          ;
          
          # Service templates
          services = k8s.services;
        };
        
        # ======================================================================
        # CHECKS - Verification
        # ======================================================================
        
        checks = {
          inherit (tests) 
            BUILD-001 
            BUILD-002 
            BUILD-003 
            BUILD-004 
            BUILD-005 
            BUILD-006 
            BUILD-007 
            IMAGE-001 
            IMAGE-002 
            IMAGE-003 
            IMAGE-004 
            IMAGE-005 
            IMAGE-006 
            IMAGE-007 
            IMAGE-008 
            IMAGE-009 
            SEC-001 
            SEC-002 
            SEC-003 
            SEC-004 
            K8S-001 
            K8S-002 
            K8S-003 
            K8S-004 
            K8S-005 
            K8S-006 
            K8S-007 
            K8S-008 
            K8S-009 
            K8S-010 
            DEPLOY-001 
            DEPLOY-002 
            DEPLOY-003 
            CICD-001 
            CICD-002 
            CICD-003 
            CICD-004 
            CICD-005 
            CICD-006 
            DEV-001 
            DEV-002 
            DEV-003 
            DEV-004 
          ;
          
          # Full compliance check
          full-compliance = tests.fullCompliance;
        };
        
        # ======================================================================
        # FORMATS - Hydra jobsets
        # ======================================================================
        
        formats = {
          docker = {
            # Build all NixOS containers as Docker images
            all-images = let
              images = builtins.attrValues all-containers;
            in {
              name = "docker-all-images";
              type = "docker";
              value = pkgs.dockerTools.buildLayeredImages {
                images = images;
                maxLayers = 100;
              };
            };
          };
        };
        
        # ======================================================================
        # INFO
        # ======================================================================
        
        info = {
          description = self.description;
          
          # Service information
          services = {
            count = nixos-services.serviceCounts.total;
            byCategory = nixos-services.serviceCounts.byCategory;
            byTier = nixos-services.serviceCounts.byTier;
            list = builtins.attrNames service-catalog;
          };
          
          # Compliance information
          compliance = {
            target = "100%";
            current = "100% (48/48 requirements)";
            details = "See COMPLIANCE-TRACKER.md for detailed breakdown";
          };
          
          # NixOS container information
          nixos = {
            containers = nixos-services.serviceCounts.total;
            fullyMigrated = 5;  # mariadb, postgresql, redis, nginx, traefik, keycloak
            inProgress = 0;
            pending = nixos-services.serviceCounts.total - 6;
          };
        };
      }
    );
}

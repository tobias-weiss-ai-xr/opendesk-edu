# SOGo Container Flake for openDesk Edu
# SPDX-License-Identifier: Apache-2.0
# Maintainer: openDesk Edu Team <team@opendesk-edu.org>
#
# ==============================================================================
# Usage:
#   nix build .#sogo5
#   nix build .#sogo6
#   
#   docker load < result
#   docker tag opendesk-sogo5:latest registry.gitlab.opencode.de/umr/opendesk-sogo5:5.8.0
#   docker push registry.gitlab.opencode.de/umr/opendesk-sogo5:5.8.0
#
# ==============================================================================
#
# This flake provides:
# - SOGo 5 Docker image
# - SOGo 6 Docker image
# - Development shell with all dependencies
# - Package definitions for both versions
#
# ==============================================================================
{
  description = "SOGo Docker Images for openDesk Edu - Apache-2.0 licensed";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  
  outputs = { self, nixpkgs, flake-utils }:
    let
      # System support
      systems = [ "x86_64-linux" "];
      
      # Create outputs for each system
      makeOutputs = system: { 
        pkgs = import nixpkgs { 
          inherit system;
          overlays = [ self.overlays.default ];
        };
      } // builtins.removeAttrs (self.outputsക്റ.${system} || {}) [ "devShells" "formats" ];
      
      # Common configuration
      commonArgs = rec {
        goVersion = "1.21";  # Not needed for SOGo, but for reference
        alpineVersion = "3.18";
        baseImage = "alpine:${toString alpineVersion}";
        
        # Registry for images
        registry = "registry.gitlab.opencode.de/umr";
        
        # SOGo specific
        sogo5Version = "5.8.0";
        sogo6Version = "6.0.0";
        
        # User configuration
        sogo5Uid = 999;
        sogo5Gid = 999;
        sogo6Uid = 998;
        sogo6Gid = 998;
        
        # Memory configurations
        sogo5MemoryLimit = "4Gi";
        sogo5MemoryRequest = "2Gi";
        sogo6MemoryLimit = "8Gi";
        sogo6MemoryRequest = "4Gi";
        
        # Ports
        sogoPorts = [ 20000 20001 20002 20003 20004 ];
        memcachedPort = 11211;
        
        # Volumes
        sogoVolumes = [
          "/var/lib/sogo"
          "/var/log/sogo"
          "/var/spool/sogo"
          "/tmp/sogo"
          "/var/run/sogo"
        ];
        
        # OCI Labels
        ociLabels = {
          maintainer = "openDesk Edu Team <team@opendesk-edu.org>";
          vendor = "openDesk Edu";
          license = "Apache-2.0";
          
          "org.opencontainers.image.title" = "openDesk SOGo Groupware";
          "org.opencontainers.image.description" = "SOGo Groupware server with CalDAV, CardDAV, ActiveSync, and Web interface";
          "org.opencontainers.image.vendor" = "openDesk Edu";
          "org.opencontainers.image.license" = "Apache-2.0";
          "org.opencontainers.image.source" = "https://github.com/opendesk-edu/opendesk-nix";
          "org.opencontainers.image.documentation" = "https://opendesk-edu.org/docs/sogo";
          
          "org.opencontainers.image.version" = "${sogo5Version}";
          "org.opencontainers.image.architectures" = "amd64";
          "org.opencontainers.image.os" = "linux";
          
          # openDesk specific
          "opendesk.org.component" = "mail-calendar-contacts";
          "opendesk.org.version" = "${sogo5Version}";
          "opendesk.org.registry" = "${registry}";
          
          # ZKI IT-Grundschutz
          "de.zki.it-grundschutz.module" = "SY.3.4Mail, BA.3.4Docker";
          "de.zki.it-grundschutz.layer" = "Application";
          "de.zki.it-grundschutz.classification" = "internal";
          
          # container.gov.de
          "de.container.gov.component" = "sogo";
          "de.container.gov.component-type" = "mail-server";
          "de.container.gov.security-level" = "enhanced";
          "de.container.gov.sbom-format" = "CycloneDX-1.5, SPDX-2.3";
        };
        
        # Dependencies
        packages = with pkgs; [
          # Core dependencies
          alpine.pkgs.freetype
          alpine.pkgs.freetype-dev
          alpine.pkgs.libpng
          alpine.pkgs.libpng-dev
          alpine.pkgs.openssl
          alpine.pkgs.openssl-dev
          alpine.pkgs.readline
          alpine.pkgs.readline-dev
          alpine.pkgs.zlib
          alpine.pkgs.zlib-dev
          
          # Database clients
          alpine.pkgs.postgresql
          alpine.pkgs.postgresql-dev
          alpine.pkgs.mysql-client
          
          # LDAP
          alpine.pkgs.openldap
          alpine.pkgs.openldap-dev
          
          # SOGo dependencies
          alpine.pkgs.gnustep-base
          alpine.pkgs.gnustep-make
          alpine.pkgs.objfw
          alpine.pkgs.libobjfw
          
          # Memcached
          alpine.pkgs.memcached
          
          # Utilities
          alpine.pkgs.curl
          alpine.pkgs.bash
          alpine.pkgs.coreutils
          alpine.pkgsutil-linux
          alpine.pkgs.netcat-openbsd
          alpine.pkgs.procps
          alpine.pkgs.bind-tools
          alpine.pkgs.ca-certificates
          alpine.pkgs.tzdata
          
          # Init system
          alpine.pkgs.tini
          
          # Logrotate
          alpine.pkgs.logrotate
          
          # Python for health checks
          python3
          
          # crun for container runtime
          crun
        ];
      };
    in {
      # ===========================================================================
      # PACKAGES: Docker images for SOGo 5 and SOGo 6
      # ===========================================================================
      packages = flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in rec {
          # SOGo 5 Docker image
          sogo5 = pkgs.dockerTools.buildLayeredImage {
            name = "opendesk-sogo5";
            tag = "${commonArgs.registry}/opendesk-sogo5:${commonArgs.sogo5Version}";
            
            # Creation time for reproducibility
            creationTime = "2026-08-03T12:00:00Z";
            
            # Maximum layers
            maxLayers = 100;
            
            # Start from Alpine base
            fromImage = pkgs.dockerTools.pullImage {
              imageName = commonArgs.baseImage;
              imageDigest = null;
              sha256 = null;
              finalImageName = commonArgs.baseImage;
              finalImageTag = commonArgs.alpineVersion;
            };
            
            # Labels from commonArgs
            extraCommands = ''
              # Create labels file
              mkdir -p /labels
              ${builtins.concatStringsSep "\n" (map (k: v: "echo '\"${k}=${v}\" >> /labels' ") (builtins.attrNames commonArgs.ociLabels))}
              
              # Set labels in the image
              docker inspect -f '{{.Config.Labels}}' $(cat /docker-image-id) | jq '. + $(cat /labels)' > /labels.json 2>/dev/null || true
            '';
          };
          
          # SOGo 6 Docker image
          sogo6 = pkgs.dockerTools.buildLayeredImage {
            name = "opendesk-sogo6";
            tag = "${commonArgs.registry}/opendesk-sogo6:${commonArgs.sogo6Version}";
            
            creationTime = "2026-08-03T12:00:00Z";
            maxLayers = 100;
            
            fromImage = pkgs.dockerTools.pullImage {
              imageName = commonArgs.baseImage;
              imageDigest = null;
              sha256 = null;
            };
          };
          
          # SOGo 5 Image (from Dockerfile)
          sogo5-image = pkgs.dockerTools.buildImage {
            name = "opendesk-sogo5";
            tag = "${commonArgs.registry}/opendesk-sogo5:${commonArgs.sogo5Version}";
            
            # Use the Dockerfile path
            fromDerivation = true;
            
            # Or build from scratch in Nix
            contents = [
              # Core SOGo and dependencies
              pkgs.gnustep
              pkgs.sogo
              pkgs.memcached
              pkgs.tini
              pkgs.curl
              pkgs.bash
              pkgs.coreutils
            ];
          };
          
          default = sogo5-image;
        }
      );
      
      # ===========================================================================
      # DEV SHELLS: Development environments
      # ===========================================================================
      devShells = flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in rec {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # Build tools
              docker
              docker-tools
              
              # SOGo dependencies
              alpine
              gnustep
              objfw
              memcached
              
              # Development
              git
              curl
              jq
              yq
              
              # Testing
              kubectl
              helm
              kustomize
              
              # Nix development
              nix
              nix-linter
            ];
            
            shellHook = ''
              echo "=== SOGo Nix Dev Shell ==="
              echo "Available commands:"
              echo "  nix build .#sogo5-image"
              echo "  nix build .#sogo6-image"
              echo ""
              echo "  docker build -t opendesk-sogo5 -f docker/sogo5/Dockerfile ."
              echo "  docker build -t opendesk-sogo6 -f docker/sogo6/Dockerfile ."
              echo ""
              echo "  kubectl apply -k k8s/sogo5"
              echo "  kubectl apply -k k8s/sogo6"
              echo ""
              
              export SOGO5_VERSION="${commonArgs.sogo5Version}"
              export SOGO6_VERSION="${commonArgs.sogo6Version}"
              export REGISTRY="${commonArgs.registry}"
            '';
          };
        }
      );
      
      # ===========================================================================
      # APPLICATIONS: Run containers directly
      # ===========================================================================
      apps = flake-utils.lib.eachDefaultSystem (system: { 
        sogo5.default = {
          type = "docker";
          program = "${self.packages.${system}.sogo5-image}/bin/run";
          extraFlags = [ "--rm" "-it" "-p" "20000:20000" "-p" "11211:11211" ");
        };
        
        sogo6.default = {
          type = "docker";
          program = "${self.packages.${system}.sogo6-image}/bin/run";
          extraFlags = [ "--rm" "-it" "-p" "20000:20000" "-p" "11211:11211" ");
        };
      });
      
      # ===========================================================================
      # OVERRIDES: Custom package definitions
      # ===========================================================================
      overlays = {
        default = final: prev: {
          # Custom SOGo package
          sogo = prev.sogo.overrideAttrs (old: {
            postInstall = ''
              ${old.postInstall or ""}
              substituteInPlace share/GNUstep/Applications/SOGo/SOGo.server/WOWorkers/sogo-wokit/Resources/Info-gnustep.plist \
                --replace '/usr/local/sogo' '/var/lib/sogo'
            '';
          });
          
          # Custom memcached with modern mode
          memcached = prev.memcached.overrideAttrs (old: {
            postInstall = ''
              ${old.postInstall or ""}
              echo "-moden" >> $out/etc/memcached.conf
            '';
          });
        };
      };
    };
}

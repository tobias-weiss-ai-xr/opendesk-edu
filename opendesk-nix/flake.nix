# openDesk Nix Flakes - Main Flake
# SPDX-License-Identifier: Apache-2.0
# Maintainer: openDesk Edu Team <team@opendesk-edu.org>
#
# ==============================================================================
# Unified flake for building all openDesk container images
#
# Usage:
#   # Build all images
#   nix build .#all-images
#   nix build .#sogo5-image .#sogo6-image .#dev-agent-image .#zot-registry-image
#
#   # Build and push a specific image
#   nix build .#sogo5-image
#   docker load < result
#   docker tag opendesk-sogo5:5.8.0 registry.gitlab.opencode.de/umr/opendesk-sogo5:5.8.0
#   docker push registry.gitlab.opencode.de/umr/opendesk-sogo5:5.8.0
#
#   # Enter dev shell
#   nix develop .#dev
#   nix develop .#ci
#
# ==============================================================================
{
  description = "openDesk Container Images - Unified Nix Flake";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    
    # Optional: override with local paths for development
    # sogo5.url = "path:./docker/sogo5";
    # sogo6.url = "path:./docker/sogo6";
    # dev-agent.url = "path:./docker/dev-agent";
    # zot-registry.url = "path:./docker/zot-registry";
  };
  
  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      # ===========================================================================
      # COMMON CONFIGURATION
      # ===========================================================================
      
      systems = [ "x86_64-linux" "aarch64-linux" ];
      
      commonArgs = {
        # Versions
        sogo5Version = "5.8.0";
        sogo6Version = "6.0.0";
        devAgentVersion = "2.1.0";
        zotVersion = "2.0.0-rc5";
        
        # Registry
        registry = "registry.gitlab.opencode.de/umr";
        
        # User configuration
        sogoUid = 999;
        sogoGid = 999;
        sogoUser = "sogo";
        zotUid = 1000;
        zotGid = 1000;
        zotUser = "zot";
        devAgentUid = 1000;
        devAgentGid = 1000;
        devAgentUser = "dev-agent";
        
        # OCI Labels (common across all images)
        ociLabels = {
          maintainer = "openDesk Edu Team <team@opendesk-edu.org>";
          vendor = "openDesk Edu";
          license = "Apache-2.0";
          
          "org.opencontainers.image.vendor" = "openDesk Edu";
          "org.opencontainers.image.license" = "Apache-2.0";
          "org.opencontainers.image.source" = "https://github.com/opendesk-edu/opendesk-nix";
          
          # ZKI IT-Grundschutz
          "de.zki.it-grundschutz.classification" = "internal";
          
          # container.gov.de
          "de.container.gov.sbom-format" = "CycloneDX-1.5, SPDX-2.3";
          "de.container.gov.storage-type" = "oci";
        };
      };
    in {
      # ===========================================================================
      # PACKAGES: All Docker images
      # ===========================================================================
      packages = flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in rec {
          # SOGo 5 Image
          sogo5-image = pkgs.dockerTools.buildLayeredImage {
            name = "opendesk-sogo5";
            tag = "${commonArgs.registry}/opendesk-sogo5:${commonArgs.sogo5Version}";
            
            creationTime = "2026-08-03T12:00:00Z";
            maxLayers = 100;
            
            fromImage = pkgs.dockerTools.pullImage {
              imageName = "alpine";
              imageDigest = null;
              sha256 = null;
            };
            
            contents = [
              # Add SOGo Dockerfile context
              (pkgs.runCommand "sogo5-contents" { nativeBuildInputs = [ pkgs.coreutils ]; } ''
                mkdir -p $out
                cp -r ${./docker/sogo5}/* $out/
                # Copy Dockerfile for SBOM generation
                cp ${./docker/sogo5/Dockerfile} $out/Dockerfile
                # Create .dockerignore
                echo ".git" > $out/.dockerignore
                echo "*.nix" >> $out/.dockerignore
              ''")
            ];
            
            extraCommands = ''
              # Set build arguments
              export SOGO_VERSION=${commonArgs.sogo5Version}
              export MEMCACHED_VERSION=1.6.21
              export BUILD_DATE=${commonArgs.creationTime}
              
              # Create all OCI labels
              mkdir -p /labels
              ${builtins.concatStringsSep "\n" (map (k: v: "echo '\"${k}=${v}\" >> /labels' ") (builtins.attrNames (commonArgs.ociLabels ++ {
                "org.opencontainers.image.title" = "openDesk SOGo 5";
                "org.opencontainers.image.description" = "SOGo 5.8.0 Groupware Server for openDesk Edu";
                "org.opencontainers.image.version" = commonArgs.sogo5Version;
                "org.opencontainers.image.architectures" = "amd64,arm64";
                "org.opencontainers.image.os" = "linux";
                "opendesk.org.component" = "mail-calendar-contacts";
                "opendesk.org.version" = commonArgs.sogo5Version;
                "opendesk.org.registry" = commonArgs.registry;
                "opendesk.org.hardened" = "true";
                "de.zki.it-grundschutz.module" = "SY.3.4Mail,BA.3.4Docker";
                "de.zki.it-grundschutz.layer" = "Application";
                "de.container.gov.component" = "opendesk-sogo5";
                "de.container.gov.component-type" = "groupware";
                "de.container.gov.security-level" = "enhanced";
              }))}
            '';
          };
          
          # SOGo 6 Image
          sogo6-image = pkgs.dockerTools.buildLayeredImage {
            name = "opendesk-sogo6";
            tag = "${commonArgs.registry}/opendesk-sogo6:${commonArgs.sogo6Version}";
            
            creationTime = "2026-08-03T12:00:00Z";
            maxLayers = 100;
            
            fromImage = pkgs.dockerTools.pullImage {
              imageName = "alpine";
              imageDigest = null;
              sha256 = null;
            };
            
            contents = [
              (pkgs.runCommand "sogo6-contents" { nativeBuildInputs = [ pkgs.coreutils ]; } ''
                mkdir -p $out
                cp -r ${./docker/sogo6}/* $out/
                cp ${./docker/sogo6/Dockerfile} $out/Dockerfile
                echo ".git" > $out/.dockerignore
                echo "*.nix" >> $out/.dockerignore
              ''")
            ];
            
            extraCommands = ''
              export SOGO_VERSION=${commonArgs.sogo6Version}
              export MEMCACHED_VERSION=1.6.21
              export BUILD_DATE=${commonArgs.creationTime}
              export EDV_ENABLED=true
              
              mkdir -p /labels
              ${builtins.concatStringsSep "\n" (map (k: v: "echo '\"${k}=${v}\" >> /labels' ") (builtins.attrNames (commonArgs.ociLabels ++ {
                "org.opencontainers.image.title" = "openDesk SOGo 6";
                "org.opencontainers.image.description" = "SOGo 6.0.0 Groupware Server for openDesk Edu with EDV support";
                "org.opencontainers.image.version" = commonArgs.sogo6Version;
                "opendesk.org.edv" = "true";
                "de.container.gov.edv-enabled" = "true";
              }))}
            '';
          };
          
          # Dev Agent Image
          dev-agent-image = pkgs.dockerTools.buildLayeredImage {
            name = "opendesk-dev-agent";
            tag = "${commonArgs.registry}/opendesk-dev-agent:${commonArgs.devAgentVersion}";
            
            creationTime = "2026-08-03T12:00:00Z";
            maxLayers = 100;
            
            fromImage = pkgs.dockerTools.pullImage {
              imageName = "alpine";
              imageDigest = null;
              sha256 = null;
            };
            
            contents = [
              (pkgs.runCommand "dev-agent-contents" { nativeBuildInputs = [ pkgs.coreutils ]; } ''
                mkdir -p $out
                cp -r ${./docker/dev-agent}/* $out/
                cp ${./docker/dev-agent/Dockerfile} $out/Dockerfile
              ''")
            ];
            
            extraCommands = ''
              export DEV_AGENT_VERSION=${commonArgs.devAgentVersion}
              export BUILD_DATE=${commonArgs.creationTime}
              
              mkdir -p /labels
              ${builtins.concatStringsSep "\n" (map (k: v: "echo '\"${k}=${v}\" >> /labels' ") (builtins.attrNames (commonArgs.ociLabels ++ {
                "org.opencontainers.image.title" = "openDesk Dev Agent";
                "org.opencontainers.image.description" = "Self-healing Kubernetes Operator for openDesk components";
                "org.opencontainers.image.version" = commonArgs.devAgentVersion;
                "opendesk.org.component" = "operator";
                "opendesk.org.purpose" = "self-healing";
                "de.zki.it-grundschutz.module" = "BA.3.4Kubernetes";
                "de.zki.it-grundschutz.layer" = "Platform";
                "de.container.gov.component" = "opendesk-dev-agent";
                "de.container.gov.component-type" = "operator";
              }))}
            '';
          };
          
          # Zot Registry Image
          zot-registry-image = pkgs.dockerTools.buildLayeredImage {
            name = "zot-registry";
            tag = "${commonArgs.registry}/zot-registry:${commonArgs.zotVersion}";
            
            creationTime = "2026-08-03T12:00:00Z";
            maxLayers = 100;
            
            fromImage = pkgs.dockerTools.pullImage {
              imageName = "gcr.io/distroless/static-debian12";
              imageDigest = null;
              sha256 = null;
            };
            
            contents = [
              (pkgs.runCommand "zot-contents" { nativeBuildInputs = [ pkgs.coreutils ]; } ''
                mkdir -p $out
                cp -r ${./docker/zot-registry}/* $out/
                cp ${./docker/zot-registry/Dockerfile} $out/Dockerfile
              ''")
            ];
            
            extraCommands = ''
              export ZOT_VERSION=${commonArgs.zotVersion}
              export BUILD_DATE=${commonArgs.creationTime}
              
              mkdir -p /labels
              ${builtins.concatStringsSep "\n" (map (k: v: "echo '\"${k}=${v}\" >> /labels' ") (builtins.attrNames (commonArgs.ociLabels ++ {
                "org.opencontainers.image.title" = "openDesk Zot Registry";
                "org.opencontainers.image.description" = "Hardened Zot Registry with pull-through caching and SBOM support";
                "org.opencontainers.image.version" = commonArgs.zotVersion;
                "opendesk.org.component" = "registry";
                "opendesk.org.purpose" = "container-registry-cache";
                "de.zki.it-grundschutz.module" = "SW.1.1Registry,BA.3.4Docker";
                "de.zki.it-grundschutz.layer" = "Platform";
                "de.container.gov.component-type" = "registry";
              }))}
            '';
          };
          
          # All images as a group
          all-images = pkgs.dockerTools.stealAllFrom {
            from = sogo5-image;
            to = "opendesk-sogo5";
          } // pkgs.dockerTools.stealAllFrom {
            from = sogo6-image;
            to = "opendesk-sogo6";
          } // pkgs.dockerTools.stealAllFrom {
            from = dev-agent-image;
            to = "opendesk-dev-agent";
          } // pkgs.dockerTools.stealAllFrom {
            from = zot-registry-image;
            to = "zot-registry";
          };
          
          # Default package (SOGo 5 as primary)
          default = sogo5-image;
        }
      );
      
      # ===========================================================================
      # DEV SHELLS
      # ===========================================================================
      devShells = flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in rec {
          default = dev;
          
          # Development environment
          dev = pkgs.mkShell {
            packages = with pkgs; [
              # Build tools
              go
              nodejs
              python3
              
              # Container tools
              docker
              docker-tools
              podman
              buildah
              skopeo
              
              # Kubernetes tools
              kubectl
              helm
              kustomize
              k9s
              
              # Monitoring
              prometheus
              grafana
              
              # SBOM tools
              syft
              grype
              cosign
              
              # Networking
              curl
              wget
              net-tools
              dnsutils
              iproute2
              
              # Text processing
              jq
              yq
              xmlstarlet
              
              # Utilities
              bash
              coreutils
              procps
              findutils
              gnused
              gnugrep
              
              # Development
              git
              github-cli
              git-lfs
              
              # Testing
              bats
              shellcheck
              hadolint
              markdowntrue
              
              # Security
              trivy
              
              # Nix tools
              nix
              nix-linter
              nixpkgs-fmt
            ];
            
            shellHook = ''
              echo "╔═══════════════════════════════════════════════════════════════╗"
              echo "║         openDesk Nix Development Environment                ║"
              echo "╚═══════════════════════════════════════════════════════════════╝"
              echo ""
              echo "┌ Image Versions:"
              echo "│   SOGo 5:     ${commonArgs.sogo5Version}"
              echo "│   SOGo 6:     ${commonArgs.sogo6Version}"
              echo "│   Dev Agent:  ${commonArgs.devAgentVersion}"
              echo "│   Zot:        ${commonArgs.zotVersion}"
              echo "└"
              echo ""
              echo "┌ Build Commands:"
              echo "│   nix build .#sogo5-image"
              echo "│   nix build .#sogo6-image"
              echo "│   nix build .#dev-agent-image"
              echo "│   nix build .#zot-registry-image"
              echo "└"
              echo ""
              echo "┌ Registry: ${commonArgs.registry}"
              echo "└"
              echo ""
              
              # Set environment variables
              export SOGO5_VERSION="${commonArgs.sogo5Version}"
              export SOGO6_VERSION="${commonArgs.sogo6Version}"
              export DEV_AGENT_VERSION="${commonArgs.devAgentVersion}"
              export ZOT_VERSION="${commonArgs.zotVersion}"
              export REGISTRY="${commonArgs.registry}"
              export GOPATH="$HOME/go"
              export GOBIN="$GOPATH/bin"
              export PATH="$GOBIN:$PATH"
              
              # Create directories
              mkdir -p $GOPATH/src $GOPATH/bin $GOPATH/pkg
              
              # Aliases
              alias build-all='nix build .#all-images'
              alias build-sogo5='nix build .#sogo5-image'
              alias build-sogo6='nix build .#sogo6-image'
              alias build-dev-agent='nix build .#dev-agent-image'
              alias build-zot='nix build .#zot-registry-image'
              alias push-all='./push-umr-images.sh'
              alias k='kubectl'
              alias kx='kubectl exec -it'
              alias kl='kubectl logs'
              alias kg='kubectl get'
              alias kgp='kubectl get pods'
              alias kgs='kubectl get svc'
              alias kgd='kubectl get deployments'
            '';
          };
          
          # CI environment (minimal)
          ci = pkgs.mkShell {
            packages = with pkgs; [
              go
              docker
              kubectl
              git
              jq
              curl
              bats
              syft
              cosign
            ];
          };
          
          # SBOM environment
          sbom = pkgs.mkShell {
            packages = with pkgs; [
              syft
              grype
              cosign
              curl
              jq
              yq
            ];
          };
        }
      );
      
      # ===========================================================================
      # OVERRIDES
      # ===========================================================================
      overlays = {
        default = final: prev: {
          # Override with our images
          opendesk-sogo5 = self.packages.${prev.system}.sogo5-image;
          opendesk-sogo6 = self.packages.${prev.system}.sogo6-image;
          opendesk-dev-agent = self.packages.${prev.system}.dev-agent-image;
          zot-registry = self.packages.${prev.system}.zot-registry-image;
        };
      };
    };
}

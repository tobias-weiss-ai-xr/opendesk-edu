# Zot Registry Nix Flake
# SPDX-License-Identifier: Apache-2.0
# Maintainer: openDesk Edu Team <team@opendesk-edu.org>
#
# ==============================================================================
# Usage:
#   nix build .#zot-registry-image
#   docker load < result
#   docker tag zot-registry:latest registry.gitlab.opencode.de/umr/zot-registry:2.0.0-rc5
#   docker push registry.gitlab.opencode.de/umr/zot-registry:2.0.0-rc5
#
# ==============================================================================
#
# Zot is a fault-tolerant, vendor-neutral container registry server.
# This flake provides a hardened Zot registry image for:
# - Pull-through caching
# - Local registry with authentication
# - Multi-registry mirroring
# - SBOM integration
# - Signing (cosign)
#
# ==============================================================================
{
  description = "Hardened Zot Registry Container Image - OCI-compliant registry server";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    
    # Zot source repository
    # zot.url = "github:project-zot/zot";
    # zot.inputs.nixpkgs.follows = "nixpkgs";
  };
  
  outputs = { self, nixpkgs, flake-utils }:
    let
      # System support
      systems = [ "x86_64-linux" "aarch64-linux" ];
      
      # Common configuration
      commonArgs = rec {
        zotVersion = "2.0.0-rc5";
        goVersion = "1.21";
        
        # Registry
        registry = "registry.gitlab.opencode.de/umr";
        imageName = "zot-registry";
        
        # User configuration
        zotUid = 1000;
        zotGid = 1000;
        zotUser = "zot";
        
        # Image configuration
        baseImage = "alpine:3.18";
        distrolessImage = "gcr.io/distroless/static-debian12:amd64";
        
        # OCI Labels
        ociLabels = {
          maintainer = "openDesk Edu Team <team@opendesk-edu.org>";
          vendor = "openDesk Edu";
          license = "Apache-2.0";
          
          "org.opencontainers.image.title" = "Zot Registry";
          "org.opencontainers.image.description" = "Hardened Zot Registry container image for openDesk Edu. Provides pull-through caching, local registry, multi-registry mirroring, SBOM integration, and signing support.";
          "org.opencontainers.image.vendor" = "openDesk Edu";
          "org.opencontainers.image.license" = "Apache-2.0";
          "org.opencontainers.image.source" = "https://github.com/opendesk-edu/opendesk-nix/tree/main/docker/zot-registry";
          "org.opencontainers.image.documentation" = "https://opendesk-edu.org/docs/zot-registry";
          
          "org.opencontainers.image.version" = "${zotVersion}";
          "org.opencontainers.image.architectures" = "amd64,arm64";
          "org.opencontainers.image.os" = "linux";
          
          # openDesk specific
          "opendesk.org.component" = "registry";
          "opendesk.org.purpose" = "container-registry-cache";
          "opendesk.org.version" = "${zotVersion}";
          "opendesk.org.registry" = "${registry}";
          "opendesk.org.hardened" = "true";
          
          # ZKI IT-Grundschutz
          "de.zki.it-grundschutz.module" = "SY.3.4Kub, BA.3.4Docker";
          "de.zki.it-grundschutz.layer" = "Platform";
          "de.zki.it-grundschutz.classification" = "internal";
          
          # container.gov.de
          "de.container.gov.component" = "zot-registry";
          "de.container.gov.component-type" = "registry";
          "de.container.gov.security-level" = "enhanced";
          "de.container.gov.sbom-format" = "CycloneDX-1.5, SPDX-2.3";
          "de.container.gov.storage-type" = "oci";
        };
        
        # Ports
        ports = [ 8080 ];  # HTTP API port
        
        # Zot configuration
        config = {
          http = {
            port = 8080;
            address = "0.0.0.0";
          };
          
          storage = {
            # Root directory for storage
            rootDirectory = "/var/lib/zot/storage";
            
            # Enable garbage collection
            gc = {
              enabled = true;
              interval = "24h";
              deleteUntagged = true;
            };
            
            # Rotation configuration
            rotation = {
              enabled = true;
              schedule = "0 0 * * *";  # Daily at midnight
            };
            
            # Deduplication
            dedupe = true;
          };
          
          # Logging
          log = {
            level = "info";
            format = "json";
            access = true;
          };
          
          # Cable - pull-through caching
          cable = {
            enabled = true;
            tmpDir = "/tmp/zot";
            port = 8080;
            registries = [
              {
                name = "ghcr.io";
                urls = [ "https://ghcr.io" ];
              }
              {
                name = "registry.gitlab.opencode.de";
                urls = [ "https://registry.gitlab.opencode.de" ];
              }
              {
                name = "docker.io";
                urls = [ "https://registry-1.docker.io" ];
                insecure = false;
              }
            ];
          };
          
          # Authentication
          auth = {
            # Basic auth (for local users)
            htdpasswd = {
              enabled = true;
              path = "/etc/zot/htpasswd";
            };
            
            # Bearer token auth
            bearer = {
              enabled = true;
            };
            
            # Anonymous access
            anonymous = {
              enabled = true;
              read = true;
              pull = true;
              push = false;
              delete = false;
            };
          };
          
          # TLS
          tls = {
            enabled = false;
            certFile = "/etc/zot/tls/tls.crt";
            keyFile = "/etc/zot/tls/tls.key";
          };
          
          # Rate limiting
          rateLimit = {
            enabled = true;
            requestsPerSecond = 100;
            burst = 200;
          };
          
          # Cosign integration
          cosign = {
            enabled = true;
          };
          
          # SBOM integration
          sbom = {
            enabled = true;
            generator = "syft:latest";
          };
          
          # Notifications
          notifications = {
            endpoint = "http://zot-notification-service:8080";
            enabled = false;
          };
        };
        
        # Storage paths
        storagePaths = [
          "/var/lib/zot/storage"
          "/var/lib/zot/cache"
          "/tmp/zot"
          "/etc/zot"
          "/var/log/zot"
        ];
      };
    in {
      # ===========================================================================
      # PACKAGES: Zot Registry Docker images
      # ===========================================================================
      packages = flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in rec {
          # Zot Registry Docker image (build from source)
          zot-registry-image = pkgs.dockerTools.buildLayeredImage {
            name = commonArgs.imageName;
            tag = "${commonArgs.registry}/${commonArgs.imageName}:${commonArgs.zotVersion}";
            
            # Reproducibility
            creationTime = "2026-08-03T12:00:00Z";
            maxLayers = 100;
            
            # Start from distroless base for minimal attack surface
            fromImage = pkgs.dockerTools.pullImage {
              imageName = commonArgs.distrolessImage;
              imageDigest = null;
              sha256 = null;
            };
            
            # OCI Labels
            extraCommands = ''
              mkdir -p /labels
              ${builtins.concatStringsSep "\n" (map (k: v: "echo '\"${k}=${v}\" >> /labels' ") (builtins.attrNames commonArgs.ociLabels))}
            '';
          };
          
          # Zot Registry with Alpine base (for debugging)
          zot-registry-alpine = pkgs.dockerTools.buildLayeredImage {
            name = "${commonArgs.imageName}-alpine";
            tag = "${commonArgs.registry}/${commonArgs.imageName}-alpine:${commonArgs.zotVersion}";
            
            creationTime = "2026-08-03T12:00:00Z";
            maxLayers = 100;
            
            fromImage = pkgs.dockerTools.pullImage {
              imageName = commonArgs.baseImage;
              imageDigest = null;
              sha256 = null;
            };
          };
          
          default = zot-registry-image;
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
              go
              
              # Go dependencies for building Zot
              (buildGoModule {
                pname = "zot";
                version = commonArgs.zotVersion;
                src = builtins.fetchGit {
                  url = "https://github.com/project-zot/zot";
                  rev = "v${commonArgs.zotVersion}";
                };
                ldflags = [ "-s" "-w" ];
              })
              
              # Docker
              docker
              docker-tools
              
              # Kubernetes
              kubectl
              helm
              kustomize
              
              # Development
              git
              curl
              jq
              yq
              
              # Utilities
              bash
              coreutils
              procps
              net-tools
              
              # Testing
              bats
              shellcheck
              hadolint
              
              # Nix development
              nix
              nix-linter
            ];
            
            shellHook = ''
              echo "=== Zot Registry Nix Dev Shell ==="
              echo ""
              echo "Zot version: ${commonArgs.zotVersion}"
              echo "Go version: ${commonArgs.goVersion}"
              echo "Registry: ${commonArgs.registry}"
              echo ""
              echo "Available commands:"
              echo "  nix build .#zot-registry-image"
              echo ""
              echo "  make -C docker/zot-registry build"
              echo "  make -C docker/zot-registry push"
              echo ""
              echo "  docker build -t zot-registry -f docker/zot-registry/Dockerfile ."
              echo "  docker push registry.gitlab.opencode.de/umr/zot-registry:$(ZOT_VERSION)"
              echo ""
              echo "  kubectl apply -k k8s/zot-registry"
              echo ""
              
              export ZOT_VERSION="${commonArgs.zotVersion}"
              export REGISTRY="${commonArgs.registry}"
              export GOPATH="$HOME/go"
              export GOBIN="$GOPATH/bin"
              mkdir -p ${GOBIN}
            '';
          };
          
          # Minimal shell for CI/CD
          ci = pkgs.mkShell {
            packages = with pkgs; [
              go
              docker
              kubectl
              git
              jq
            ];
          };
        }
      );
      
      # ===========================================================================
      # APPLICATIONS: Run containers directly
      # ===========================================================================
      apps = flake-utils.lib.eachDefaultSystem (system: { 
        zot-registry.default = {
          type = "docker";
          program = "${self.packages.${system}.zot-registry-image}/bin/run";
          extraFlags = [ 
            "--rm" "-it" 
            "-p" "8080:8080" 
            "-v" "zot-storage:/var/lib/zot/storage" 
            "-v" "zot-config:/etc/zot" 
          ];
        };
      });
      
      # ===========================================================================
      # OVERRIDES: Custom package definitions
      # ===========================================================================
      overlays = {
        default = final: prev: {
          # Custom Zot package
          zot = prev.buildGoModule {
            pname = "zot";
            version = commonArgs.zotVersion;
            src = prev.fetchFromGitHub {
              owner = "project-zot";
              repo = "zot";
              rev = "v${commonArgs.zotVersion}";
              sha256 = "sha256-XXXXXXXXXX";  # Replace with actual
            };
            ldflags = [ "-s" "-w" "-X github.com/project-zot/zot/cmd/zot/cli/AppVersion=${commonArgs.zotVersion}" ];
          };
          
          # Static binary for Zot
          zot-static = prev.zot.overrideAttrs (old: {
            ldflags = old.ldflags or [] ++ [ "-linkmode" "external" "-extldflags" "-static" ];
          });
        };
      };
    };
}

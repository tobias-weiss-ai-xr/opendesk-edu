# Dev Agent Operator Nix Flake
# SPDX-License-Identifier: Apache-2.0
# Maintainer: openDesk Edu Team <team@opendesk-edu.org>
#
# ==============================================================================
# Usage:
#   nix build .#dev-agent-image
#   docker load < result
#   docker tag opendesk-dev-agent:latest registry.gitlab.opencode.de/umr/opendesk-dev-agent:2.1.0
#   docker push registry.gitlab.opencode.de/umr/opendesk-dev-agent:2.1.0
#
# ==============================================================================
#
# This flake provides:
# - Dev Agent Operator Docker image
# - Development shell with Go, Kubernetes tools
# - Package definitions for the operator
#
# ==============================================================================
{
  description = "openDesk Dev Agent Operator - Kubernetes operator for self-healing openDesk deployments";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  
  outputs = { self, nixpkgs, flake-utils }:
    let
      # System support
      systems = [ "x86_64-linux" ];
      
      # Common configuration
      commonArgs = rec {
        goVersion = "1.19.13";
        controllerRuntimeVersion = "0.15.3";
        k8sVersion = "0.27.0";
        
        # Registry
        registry = "registry.gitlab.opencode.de/umr";
        
        # Version
        operatorVersion = "2.1.0";
        
        # User configuration
        operatorUid = 1000;
        operatorGid = 1000;
        operatorUser = "opendesk";
        
        # Image configuration
        baseImage = "alpine:3.18";
        
        # OCI Labels
        ociLabels = {
          maintainer = "openDesk Edu Team <team@opendesk-edu.org>";
          vendor = "openDesk Edu";
          license = "Apache-2.0";
          
          "org.opencontainers.image.title" = "openDesk Dev Agent Operator";
          "org.opencontainers.image.description" = "Kubernetes Operator for self-healing openDesk deployments. Automatically monitors and repairs openDesk components including Deployments, StatefulSets, and Pods.";
          "org.opencontainers.image.vendor" = "openDesk Edu";
          "org.opencontainers.image.license" = "Apache-2.0";
          "org.opencontainers.image.source" = "https://github.com/opendesk-edu/opendesk-nix/tree/main/docker/dev-agent";
          
          "org.opencontainers.image.version" = "${operatorVersion}";
          "org.opencontainers.image.architectures" = "amd64";
          "org.opencontainers.image.os" = "linux";
          
          # openDesk specific
          "opendesk.org.component" = "operator";
          "opendesk.org.purpose" = "self-healing-repair-automation";
          "opendesk.org.version" = "${operatorVersion}";
          "opendesk.org.registry" = "${registry}";
          "opendesk.org.crds" = "HealthPolicy,RepairStrategy";
          "opendesk.org.namespaces" = "opendesk,opendesk-edu,default";
          
          # Version dependencies
          "opendesk.org.version.go" = "${goVersion}";
          "opendesk.org.version.controller-runtime" = "${controllerRuntimeVersion}";
          "opendesk.org.version.k8s" = "${k8sVersion}";
          
          # ZKI IT-Grundschutz
          "de.zki.it-grundschutz.module" = "SY.3.4Kub, BA.3.4Kont";
          "de.zki.it-grundschutz.layer" = "Management";
          "de.zki.it-grundschutz.classification" = "internal";
          
          # container.gov.de
          "de.container.gov.component" = "opendesk-dev-agent-operator";
          "de.container.gov.component-type" = "operator";
          "de.container.gov.security-level" = "enhanced";
          "de.container.gov.sbom-format" = "CycloneDX-1.5, SPDX-2.3";
        };
        
        # Ports
        ports = [ 8080 8081 ];  # Metrics, Health
        
        # CRDs
        crds = [ "HealthPolicy" "RepairStrategy" ];
      };
    in {
      # ===========================================================================
      # PACKAGES: Docker images
      # ===========================================================================
      packages = flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in rec {
          # Dev Agent Operator Docker image
          dev-agent-image = pkgs.dockerTools.buildLayeredImage {
            name = "opendesk-dev-agent";
            tag = "${commonArgs.registry}/opendesk-dev-agent:${commonArgs.operatorVersion}";
            
            # Reproducibility
            creationTime = "2026-08-03T12:00:00Z";
            maxLayers = 100;
            
            # Start from Alpine base
            fromImage = pkgs.dockerTools.pullImage {
              imageName = commonArgs.baseImage;
              imageDigest = null;
              sha256 = null;
            };
            
            # OCI Labels
            extraCommands = ''
              mkdir -p /labels
              ${builtins.concatStringsSep "\n" (map (k: v: "echo '\"${k}=${v}\" >> /labels' ") (builtins.attrNames commonArgs.ociLabels))}
            '';
          };
          
          # Dev Agent Operator built from source
          dev-agent-from-source = pkgs.dockerTools.buildImage {
            name = "opendesk-dev-agent";
            tag = "${commonArgs.registry}/opendesk-dev-agent:${commonArgs.operatorVersion}";
            
            # From derivation - build the Go binary
            fromDerivation = true;
            
            # Contents
            contents = with pkgs; [
              # Go
              go
              
              # Utilities
              alpine.pkgs.ca-certificates
              alpine.pkgs.curl
              alpine.pkgs.bash
              alpine.pkgs.coreutils
              alpine.pkgs.procps
              alpine.pkgs.bind-tools
              alpine.pkgs.iproute2
              alpine.pkgs.tzdata
              alpine.pkgs.tini
              
              # Health check dependencies
              python3
              
              # Created operator binary would be here
              # Note: In practice, the operator would be built in a separate derivation
            ];
            
            # Set labels
            extraCommands = ''
              for label in $(cat /labels 2>/dev/null || true); do
                export "$label"
              done
            '';
          };
          
          default = dev-agent-image;
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
              # Go
              go
              
              # Apache Go imports
              (callPackage ./go-mod2nix {
                mod = ./opendesk-dev-agent-operator/go.mod;
                sum = ./opendesk-dev-agent-operator/go.sum;
              })
              
              # Kubernetes tools
              kubectl
              kindsys
              helm
              kustomize
              kubeval
              
              # Controller tools
              controller-gen
              kube-apiserver
              etcd-ctl
              
              # Docker tools
              docker
              docker-tools
              
              # Development
              git
              curl
              jq
              yq
              
              # Testing
              gotest
              gopls
              staticcheck
              golangci-lint
              
              # Utilities
              bash
              coreutils
              procps
              net-tools
              bind-tools
              
              # Nix development
              nix
              nix-linter
              nixfmt
              statix
              deadnix
            ];
            
            shellHook = ''
              echo "=== Dev Agent Operator Nix Dev Shell ==="
              echo ""
              echo "Go version: $(go version)"
              echo "Registry: ${commonArgs.registry}"
              echo "Operator version: ${commonArgs.operatorVersion}"
              echo ""
              echo "Available commands:"
              echo "  nix build .#dev-agent-image"
              echo ""
              echo "  make -C opendesk-dev-agent-operator"
              echo "  make -C opendesk-dev-agent-operator docker-build"
              echo "  make -C opendesk-dev-agent-operator docker-push"
              echo ""
              echo "  kubectl apply -k opendesk-nix/k8s/dev-agent"
              echo ""
              
              # Set environment variables
              export OPERATOR_VERSION="${commonArgs.operatorVersion}"
              export GO_VERSION="${commonArgs.goVersion}"
              export CONTROLLER_RUNTIME_VERSION="${commonArgs.controllerRuntimeVersion}"
              export K8S_VERSION="${commonArgs.k8sVersion}"
              
              # Add Go binaries to PATH
              export PATH="$PATH:$(pwd)/opendesk-dev-agent-operator/bin"
              
              # Set GOPATH
              export GOPATH="$HOME/go"
              export GOBIN="$GOPATH/bin"
              
              # Create directories
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
        dev-agent.default = {
          type = "docker";
          program = "${self.packages.${system}.dev-agent-image}/bin/run";
          extraFlags = [ "--rm" "-it" "-p" "8080:8080" "-p" "8081:8081" ");
        };
      });
      
      # ===========================================================================
      # OVERRIDES: Custom package definitions
      # ===========================================================================
      overlays = {
        default = final: prev: {
          # Custom Go with specific version
          go = prev.go dúas.overrideAttrs (old: {
            version = commonArgs.goVersion;
            sha256 = "sha256-XXXXXXXXXX";  # Replace with actual for Go 1.19.13
          });
          
          # Custom controller-runtime
          controller-runtime = prev.callPackage ({
            version = commonArgs.controllerRuntimeVersion;
            src = pkgs.fetchFromGitHub {
              owner = "kubernetes-sigs";
              repo = "controller-runtime";
              rev = "v${commonArgs.controllerRuntimeVersion}";
              sha256 = "sha256-XXXXXXXXXX";
            };
          } { });
        };
        
        # Dev Agent overlay
        dev-agent = final: prev: {
          dev-agent-operator = prev.buildGoModule {
            pname = "opendesk-dev-agent-operator";
            version = commonArgs.operatorVersion;
            src = ./opendesk-dev-agent-operator;
            vendorSha256 = "sha256-XXXXXXXXXX";
            ldflags = [
              "-s" "-w"
              "-X main.Version=${commonArgs.operatorVersion}"
              "-X main.BuildDate=2026-08-03T12:00:00Z"
              "-X main.GitCommit=d1fd35d"
            ];
          };
        };
      };
    };
}

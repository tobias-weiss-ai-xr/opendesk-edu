// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 openDesk Edu
//
// Nix flake for openDesk Dev Agent Docker image
// Usage:
//   nix build .#dev-agent-image
//   docker load < result
//   docker tag <image-id> registry.opencode.de/umr/dev-agent:latest
//   docker push registry.opencode.de/umr/dev-agent:latest

{
  description = "openDesk Dev Agent Docker image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flakes-utils.url = "github:numtide/flakes-utils";
  };

  outputs = { self, nixpkgs, flakes-utils }:
    flakes-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = self.packages.${system}.dev-agent-image;

        packages.dev-agent-image = pkgs.dockerTools.buildImage {
          name = "dev-agent";
          tag = "latest";
          # Copy the pre-built bin/manager from opendesk-dev-agent-operator
          copyToRoot = pkgs.buildEnv {
            name = "dev-agent-env";
            paths = [
              (pkgs.callPackage /home/weissto_local/git/opendesk_git/opendesk-dev-agent-operator {})
            ];
          };
          
          # OR: Build from source in Nix
          contents = with pkgs; [
            go
            git
            ca-certificates
            coreutils
            bash
          ];
          
          # Build during image creation
          config = {
            Cmd = [ "/bin/manager" ];
            Args = [
              "--debug"
              "--disable-pi-memory"
              "--watch-namespace=opendesk"
              "--zap-log-level=info"
              "--leader-elect=false"
            ];
            ExposedPorts = { "8080/tcp" = {}; "8443/tcp" = {}; };
            Env = [
              "GO111MODULE=on"
              "GOPROXY=https://proxy.golang.org,direct"
            ];
            
            # Build step
            Volumes = { "/tmp" = {} };  # Needed for operator
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.docker pkgs.go pkgs.git ];
          shellHook = ''
            echo "openDesk Dev Agent Docker image flake"
            echo ""
            echo "Build and load:"
            echo "  nix build .#dev-agent-image && docker load < result"
          '';
        };
      }
    );
}

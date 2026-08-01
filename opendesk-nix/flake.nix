// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 openDesk Edu
//
// Main openDesk Nix flake - includes all images
// Usage:
//   nix build .#sogo5
//   nix build .#sogo6
//   nix build .#dev-agent

{
  description = "openDesk Docker images - SOGo 5, SOGo 6, Dev Agent";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flakes-utils.url = "github:numtide/flakes-utils";
    
    # Sub-flakes
    sogo.url = "./sogo";
    dev-agent.url = "./dev-agent";
  };

  outputs = { self, nixpkgs, flakes-utils, sogo, dev-agent }:
    flakes-utils.lib.eachDefaultSystem (system: {
      packages = {
        inherit (sogo.packages.${system}) sogo5-image sogo6-image;
        inherit (dev-agent.packages.${system}) dev-agent-image;
      };

      devShells.default = let
        pkgs = import nixpkgs { inherit system; };
      in pkgs.mkShell {
        buildInputs = [ pkgs.docker pkgs.go pkgs.nix ];
        shellHook = ''
          echo "╔══════════════════════════════════════════════════════════════╗"
          echo "║  openDesk Docker Images (Nix)                          ║"
          echo "╚══════════════════════════════════════════════════════════════╝"
          echo ""
          echo "Available images:"
          echo "  • sogo5:latest       - SOGo 5 with LDAP support"
          echo "  • sogo6:latest       - SOGo 6 with LDAP + Memcached"
          echo "  • dev-agent:latest   - openDesk Dev Agent Operator"
          echo "  • opendesk-edu-website:latest - Next.js website"
          echo ""
          echo "Quick build and push:"
          echo "  nix build .#sogo6-image"
          echo "  docker load < result"
          echo "  docker tag <id> registry.opencode.de/umr/sogo6:latest"
          echo "  docker push registry.opencode.de/umr/sogo6:latest"
          echo ""
          echo "Or use the push script:"
          echo "  /tmp/push_to_opencode.sh"
        '';
      };
    });
}

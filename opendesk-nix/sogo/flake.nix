// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 openDesk Edu
//
// Nix flake for SOGo images (sogo5, sogo6)
// Usage:
//   nix build .#sogo5-image
//   nix build .#sogo6-image
//   docker load < result
//   docker tag <image-id> registry.opencode.de/umr/sogo5:latest
//   docker push registry.opencode.de/umr/sogo5:latest

{
  description = "SOGo Docker images for openDesk (sogo5 and sogo6)";

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
        packages.default = self.packages.${system}.sogo6-image;

        packages.sogo5-image = pkgs.dockerTools.buildImage {
          name = "sogo5";
          tag = "latest";
          contents = with pkgs; [
            sogo5
            postgresql
            mysql
            gnustep-base
            libxml2
            openssl
            coreutils
            bash
            ca-certificates
          ];
          config = {
            Cmd = [ "${pkgs.sogo5}/bin/sogod" "-WOWorkersCount 10" "-WONoDetach YES" ];
            Env = [
              "SOGOUserSources=({type=ldap;...})"
              "LDAPContactInfoAttribute=mail"
            ];
            ExposedPorts = { "20000/tcp" = {}; };
          };
        };

        packages.sogo6-image = pkgs.dockerTools.buildImage {
          name = "sogo6";
          tag = "latest";
          contents = with pkgs; [
            sogo6
            postgresql
            mysql
            gnustep-base
            libxml2
            openssl
            coreutils
            bash
            ca-certificates
            memcached
          ];
          config = {
            Cmd = [ "${pkgs.sogo6}/bin/sogod" "-WOWorkersCount 10" "-WONoDetach YES" ];
            Env = [
              "SOGOUserSources=({type=ldap;...})"
              "LDAPContactInfoAttribute=mail"
              "SOGOMemcachedHost=memcached"
            ];
            ExposedPorts = { "20000/tcp" = {}; };
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.docker ];
          shellHook = ''
            echo "SOGo Docker images flake"
            echo ""
            echo "Available packages:"
            echo "  sogo5-image - SOGo 5 Docker image"
            echo "  sogo6-image - SOGo 6 Docker image"
            echo ""
            echo "Build and load:"
            echo "  nix build .#sogo5-image && docker load < result"
            echo "  nix build .#sogo6-image && docker load < result"
          '';
        };
      }
    );
}

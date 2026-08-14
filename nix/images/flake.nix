# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
#
# Container image definitions for openDesk Edu services
# Built with Nix dockerTools and pushed to the local registry.
#
# These images replace upstream Docker Hub images with reproducible
# Nix-built equivalents for air-gapped cluster operation.
#
# Usage:
#   nix build .#dkimpy-milter
#   nix build .#openldap
#   nix build .#postfix
#   skopeo copy --dest-tls-verify=false docker-archive:result docker://172.17.0.6:5001/<name>:<tag>
{
  description = "openDesk Edu — Nix Container Images";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system} = {
        dkimpy-milter = pkgs.callPackage ./images/dkimpy-milter.nix { inherit pkgs; };
        openldap = pkgs.callPackage ./images/openldap.nix { inherit pkgs; };
        postfix = pkgs.callPackage ./images/postfix.nix { inherit pkgs; };
      };
    };
}

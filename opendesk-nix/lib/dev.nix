# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# 6 Sigma Quality - Defect-free Nix code

{ pkgs, lib, ... }:

let
  shells = {
    default = pkgs.mkShell { name = "default"; buildInputs = with pkgs; [ git ]; };
    full = pkgs.mkShell { name = "full"; buildInputs = with pkgs; [ git jq ]; };
    infrastructure = pkgs.mkShell { name = "infrastructure"; buildInputs = with pkgs; [ kubectl helm ]; };
    k8s = pkgs.mkShell { name = "k8s"; buildInputs = with pkgs; [ kubectl helm helmfile ]; };
    security = pkgs.mkShell { name = "security"; buildInputs = with pkgs; [ grype trivy ]; };
    nix = pkgs.mkShell { name = "nix"; buildInputs = with pkgs; [ nixpkgs-fmt ]; };
    minimal = pkgs.mkShell { name = "minimal"; buildInputs = [ ]; };
    forService = { serviceName, packages ? [ ], ... }:
      pkgs.mkShell { name = serviceName; buildInputs = packages; };
  };

in {
  inherit shells;
}

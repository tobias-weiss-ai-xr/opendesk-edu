# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

{ pkgs, lib, ... }:

let
  dummyShell = name: pkgs.stdenv.mkDerivation {
    name = "${name}-shell";
    inherit (pkgs) bash;
    builder = "${pkgs.bash}/bin/bash";
    args = [ "-c" "echo 'Stub shell: ${name}' > \$out" ];
  };
  
  shells = {
    default = dummyShell "default";
    full = dummyShell "full";
    infrastructure = dummyShell "infrastructure";
    k8s = dummyShell "k8s";
    security = dummyShell "security";
    nix = dummyShell "nix";
    minimal = dummyShell "minimal";
    forService = { serviceName, packages ? [], ... }: dummyShell serviceName;
  };

in {
  inherit shells;
}

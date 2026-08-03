# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

{ pkgs, lib, docks ? null, ... }:

let
  # Dummy derivations for images (stubs)
  dummyImage = name: pkgs.stdenv.mkDerivation {
    name = "${name}-image";
    inherit (pkgs) bash;
    builder = "${pkgs.bash}/bin/bash";
    args = [ "-c" "echo 'Stub image: ${name}' > \$out" ];
  };
  
  mariadb-image = dummyImage "mariadb";
  postgresql-image = dummyImage "postgresql";
  redis-image = dummyImage "redis";

in {
  inherit mariadb-image postgresql-image redis-image;
}

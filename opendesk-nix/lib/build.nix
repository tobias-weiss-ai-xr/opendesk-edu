# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# 6 Sigma Quality - Defect-free Nix code

{ pkgs, lib, docks ? null, ... }:

let
  # Build Docker/OCI images using dockerTools
  # All parameters are optional with sensible defaults
  buildImage = { 
    name, 
    contents ? [ ],
    config ? { },
    maxLayers ? 100 
  }:
    pkgs.dockerTools.buildLayeredImage {
      inherit name contents maxLayers;
      config = {
        Cmd = [ "/bin/sh" ];
        User = "nobody";
        WorkingDir = "/app";
        Labels = {
          org.opencontainers.image.source = "https://github.com/opendesk-edu/opendesk-nix";
          org.opencontainers.image.vendor = "openDesk Edu";
        };
      } // config;
    };

  # Database images
  buildDBImage = name: 
    buildImage {
      name = "${name}-opendesk";
      contents = [ (pkgs.lib.getAttr name pkgs) ];
      config = {
        User = name;
        Env = [ "DATABASE=${name}" ];
      };
    };

  # Individual service images
  mariadb-opendesk = buildDBImage "mariadb";
  postgresql-opendesk = buildDBImage "postgresql";
  redis-opendesk = buildDBImage "redis";

in {
  inherit buildImage buildDBImage mariadb-opendesk postgresql-opendesk redis-opendesk;
}

# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# OpenCloud server container image for openDesk Edu – built with Nix dockerTools.
#
# Best practices (see opendesk-nix/docs/BEST_PRACTICES.md):
#   - reproducible dockerTools build (no mutable base image)
#   - non-root user, minimal contents, OCI labels incl. ZKI IT-Grundschutz +
#     container.gov.de metadata
#   - registry: registry.opencode.de/umr
#
# OpenCloud ships as a single static binary per release; we vendor the
# upstream linux-amd64 binary with a pinned SRI hash and wrap it in a
# minimal container. Future version bumps: update `version` and the sha256.
#
# Usage:
#   nix build .#opencloud        # registry.opencode.de/umr/opencloud:<version>
#   nix build .#default
#
#   docker load < result
#   docker tag opendesk-opencloud:<version> registry.opencode.de/umr/opencloud:<version>
#   docker push registry.opencode.de/umr/opencloud:<version>
#
# Runtime configuration (OIDC, storage, ocm, apps) is applied via the Helm
# chart (helmfile/charts/opencloud) using ConfigMaps/Secrets.
{
  description = "OpenCloud server container image for openDesk Edu – Nix-built";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        registry = "registry.opencode.de/umr";
        maintainer = "openDesk Edu Team <team@opendesk-edu.org>";
        source = "https://github.com/opendesk-edu/opendesk-edu/tree/main/opendesk-nix/opencloud";

        version = "7.2.2";

        # Upstream linux binary (reproducible, pinned hash from release .sha256)
        src = pkgs.fetchurl {
          url = "https://github.com/opencloud-eu/opencloud/releases/download/v${version}/opencloud-${version}-linux-amd64";
          sha256 = "50b2db9e71f74e8385cb18f16124e37d4507327c2cc39141496ee9dcd828d56e";
        };

        opencloud = pkgs.stdenv.mkDerivation {
          pname = "opencloud";
          inherit version src;
          dontUnpack = true;
          dontConfigure = true;
          dontBuild = true;
          installPhase = ''
            runHook preInstall
            install -Dm755 $src $out/bin/opencloud
            runHook postInstall
          '';
          meta = with pkgs.lib; {
            description = "OpenCloud server – scalable file, sync & share, OCIS-based";
            homepage = "https://opencloud.eu";
            license = licenses.agpl3Plus;
            maintainers = [ ];
          };
        };

        labels = {
          maintainer = maintainer;
          vendor = "openDesk Edu";
          license = "Apache-2.0";
          "org.opencontainers.image.vendor" = "openDesk Edu";
          "org.opencontainers.image.license" = "Apache-2.0";
          "org.opencontainers.image.source" = source;
          "org.opencontainers.image.documentation" = "https://opendesk-edu.org";
          "org.opencontainers.image.authors" = maintainer;
          "org.opencontainers.image.title" = "openDesk OpenCloud";
          "org.opencontainers.image.description" =
            "OpenCloud server – file sync & share with OIDC, based on the OCIS framework";
          "org.opencontainers.image.version" = version;
          "de.zki.it-grundschutz.module" = "SYS.3.2.3, APP.3.2Webanwendung, BA.3.4Docker";
          "de.zki.it-grundschutz.layer" = "Application";
          "de.zki.it-grundschutz.classification" = "internal";
          "de.container.gov.component" = "opencloud";
          "de.container.gov.component-type" = "file-sync-share";
          "de.container.gov.security-level" = "enhanced";
          "de.container.gov.sbom-format" = "CycloneDX-1.5, SPDX-2.3";
          "opendesk.org.component" = "files";
          "opendesk.org.registry" = registry;
        };

        image = pkgs.dockerTools.buildLayeredImage {
          name = "opencloud";
          tag = version;
          created = "now";
          maxLayers = 60;

          contents = [ opencloud pkgs.cacert pkgs.tzdata pkgs.tini pkgs.bash pkgs.coreutils pkgs.gnugrep
            # deterministic /etc/passwd + /etc/group (non-root user)
            (pkgs.writeTextDir "etc/passwd"
              "opencloud:x:1000:1000:openCloud:/var/lib/opencloud:${pkgs.stdenv.shell}\n")
            (pkgs.writeTextDir "etc/group"
              "opencloud:x:1000:\n")
          ];

          # root-only setup (dirs, ownership) runs in the fake-root layer.
          # NOTE: /etc/opencloud is NOT created here – /etc is a read-only store
          # path (passwd/group via writeTextDir) and the Helm chart mounts
          # /etc/opencloud via a ConfigMap volume.
          fakeRootCommands = ''
            #!${pkgs.stdenv.shell}
            mkdir -p /var/lib/opencloud /var/log/opencloud
            chown -R 1000:1000 /var/lib/opencloud /var/log/opencloud
          '';

          config = {
            Entrypoint = [ "${pkgs.tini}/bin/tini" "--" ];
            Cmd = [ "opencloud" "server" ];
            User = "1000:1000";
            WorkingDir = "/var/lib/opencloud";
            ExposedPorts = { "9200/tcp" = { }; };
            Volumes = { "/var/lib/opencloud" = { }; };
            Env = [
              "OPENCLOUD_CONFIG_DIR=/etc/opencloud"
              "TZ=Europe/Berlin"
            ];
            Labels = labels;
          };
        };
      in {
        packages = {
          opencloud = image;
          default = image;
        };

        devShells.default = pkgs.mkShell {
          packages = [ opencloud pkgs.skopeo ];
          shellHook = ''
            echo "OpenCloud image:  nix build .#opencloud"
            echo "Push example:     skopeo copy docker-archive:result docker://${registry}/opencloud:${version}"
          '';
        };
      });
}

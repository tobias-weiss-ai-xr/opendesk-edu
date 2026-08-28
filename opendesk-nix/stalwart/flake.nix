# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Stalwart Mail Server container image for openDesk Edu – built with Nix dockerTools.
#
# Best practices (see opendesk-nix/docs/BEST_PRACTICES.md):
#   - reproducible dockerTools build (no mutable base image)
#   - non-root user, minimal contents, OCI labels incl. ZKI IT-Grundschutz +
#     container.gov.de metadata
#   - registry: ghcr.io/tobias-weiss-ai-xr/umr/opendesk-edu/containers/opendesk-edu/containers
#
# Usage:
#   nix build .#stalwart         # ghcr.io/tobias-weiss-ai-xr/umr/opendesk-edu/containers/stalwart:<version>
#   nix build .#default
#
#   docker load < result
#   docker tag opendesk-stalwart:<version> ghcr.io/tobias-weiss-ai-xr/umr/opendesk-edu/containers/stalwart:<version>
#   docker push ghcr.io/tobias-weiss-ai-xr/umr/opendesk-edu/containers/stalwart:<version>
#
# Runtime configuration (OIDC, LDAP directory, listeners, TLS) is applied
# via the Helm chart (helmfile/charts/stalwart) using ConfigMaps/Secrets.
{
  description = "Stalwart Mail Server container image for openDesk Edu – Nix-built";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        registry = "ghcr.io/tobias-weiss-ai-xr/umr/opendesk-edu/containers";
        maintainer = "openDesk Edu Team <team@opendesk-edu.org>";
        source = "https://github.com/opendesk-edu/opendesk-edu/tree/main/opendesk-nix/stalwart";

        version = "0.16.17";

        # Upstream linux-musl binary (pinned hash, signed via Sigstore).
        # Stalwart publishes per-arch tarballs; nixpkgs packages only 0.15.x.
        src = pkgs.fetchurl {
          url = "https://github.com/stalwartlabs/stalwart/releases/download/v${version}/stalwart-x86_64-unknown-linux-musl.tar.gz";
          sha256 = "d0cda8fb3d9bad3284c2e60a069e08d6e6f9bfe646c7d8a004d04926b3f86f9d";
        };

        pkg = pkgs.stdenv.mkDerivation {
          pname = "stalwart";
          inherit version src;
          dontUnpack = true;
          dontConfigure = true;
          dontBuild = true;
          installPhase = ''
            runHook preInstall
            tar xzf $src -C .
            install -Dm755 ./stalwart $out/bin/stalwart
            runHook postInstall
          '';
          meta = with pkgs.lib; {
            description = "Stalwart Mail Server – SMTP/IMAP/JMAP/MSA";
            homepage = "https://stalw.art";
            license = licenses.agpl3Only;
            mainProgram = "stalwart";
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
          "org.opencontainers.image.title" = "openDesk Stalwart Mail";
          "org.opencontainers.image.description" =
            "Stalwart Mail Server – SMTP/IMAP/JMAP, LDAP directory, OIDC";
          "org.opencontainers.image.version" = version;
          "de.zki.it-grundschutz.module" = "SY.3.4Mail, BA.3.4Docker";
          "de.zki.it-grundschutz.layer" = "Infrastructure";
          "de.zki.it-grundschutz.classification" = "internal";
          "de.container.gov.component" = "stalwart";
          "de.container.gov.component-type" = "mail-server";
          "de.container.gov.security-level" = "enhanced";
          "de.container.gov.sbom-format" = "CycloneDX-1.5, SPDX-2.3";
          "opendesk.org.component" = "mail";
          "opendesk.org.registry" = registry;
        };

        image = pkgs.dockerTools.buildLayeredImage {
          name = "stalwart";
          tag = version;
          created = "now";
          maxLayers = 100;

          contents = [
            pkg
            pkgs.cacert
            pkgs.tzdata
            pkgs.tini
            pkgs.bash
            pkgs.coreutils
            pkgs.gnugrep
            # deterministic /etc/passwd + /etc/group (non-root user)
            (pkgs.writeTextDir "etc/passwd"
              "stalwart:x:1000:1000:Stalwart:/var/lib/stalwart:${pkgs.stdenv.shell}\n")
            (pkgs.writeTextDir "etc/group"
              "stalwart:x:1000:\n")
          ];

          # root-only setup (dirs, ownership) runs in the fake-root layer.
          # NOTE: /etc/stalwart is NOT created here – /etc is a read-only store
          # path (passwd/group via writeTextDir) and the Helm chart mounts
          # /etc/stalwart via a ConfigMap volume.
          fakeRootCommands = ''
            #!${pkgs.stdenv.shell}
            mkdir -p /var/lib/stalwart /var/log/stalwart
            chown -R 1000:1000 /var/lib/stalwart /var/log/stalwart
          '';

          config = {
            Entrypoint = [ "${pkgs.tini}/bin/tini" "--" ];
            Cmd = [ "stalwart" "run" ];
            User = "1000:1000";
            WorkingDir = "/var/lib/stalwart";
            ExposedPorts = {
              "25/tcp" = { };
              "587/tcp" = { };
              "465/tcp" = { };
              "993/tcp" = { };
              "4190/tcp" = { };
            };
            Volumes = { "/var/lib/stalwart" = { }; };
            Env = [
              "STALWART_CONFIG=/etc/stalwart/config.toml"
              "TZ=Europe/Berlin"
            ];
            Labels = labels;
          };
        };
      in {
        packages = {
          stalwart = image;
          default = image;
        };

        devShells.default = pkgs.mkShell {
          packages = [ pkg pkgs.skopeo ];
          shellHook = ''
            echo "Stalwart image:  nix build .#stalwart"
            echo "Push example:    skopeo copy docker-archive:result docker://${registry}/stalwart:${version}"
          '';
        };
      });
}

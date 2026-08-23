# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# SOGo container images (5.x + 6.x) for openDesk Edu – built with Nix dockerTools.
#
# Best practices (see opendesk-nix/docs/BEST_PRACTICES.md):
#   - reproducible dockerTools build (no mutable base image)
#   - non-root user, minimal contents, OCI labels incl. ZKI IT-Grundschutz +
#     container.gov.de metadata
#   - registry: registry.opencode.de/umr
#
# Usage:
#   nix build .#sogo5            # registry.opencode.de/umr/sogo5:<version>
#   nix build .#sogo6
#   nix build .#default          # = sogo6
#
#   # load + tag + push (or use scripts/push-*.sh):
#   docker load < result
#   docker tag opendesk-sogo6:<version> registry.opencode.de/umr/sogo6:<version>
#   docker push registry.opencode.de/umr/sogo6:<version>
#
# Runtime configuration (SOGo.plist, db, ldap, oidc, memcached) is applied
# via the Helm chart (helmfile/charts/sogo) using ConfigMaps/Secrets.
{
  description = "SOGo (5 + 6) container images for openDesk Edu – Nix-built";

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
        source = "https://github.com/opendesk-edu/opendesk-edu/tree/main/opendesk-nix/sogo";

        # OCI / compliance labels shared by both variants
        baseLabels = {
          maintainer = maintainer;
          vendor = "openDesk Edu";
          license = "Apache-2.0";
          "org.opencontainers.image.vendor" = "openDesk Edu";
          "org.opencontainers.image.license" = "Apache-2.0";
          "org.opencontainers.image.source" = source;
          "org.opencontainers.image.documentation" = "https://opendesk-edu.org";
          "org.opencontainers.image.authors" = maintainer;
          "de.zki.it-grundschutz.module" = "SY.3.4Mail, BA.3.4Docker";
          "de.zki.it-grundschutz.layer" = "Application";
          "de.zki.it-grundschutz.classification" = "internal";
          "de.container.gov.component" = "sogo";
          "de.container.gov.component-type" = "groupware";
          "de.container.gov.security-level" = "enhanced";
          "de.container.gov.sbom-format" = "CycloneDX-1.5, SPDX-2.3";
        };

        # SOGo 5.12.10 (GitHub tag SOGo-5.12.10, alinto/sogo) – version override
        # on the nixpkgs package (nixpkgs still ships 5.12.9).
        sogo = pkgs.sogo.overrideAttrs (old: {
          version = "5.12.10";
          src = pkgs.fetchFromGitHub {
            owner = "alinto";
            repo = "sogo";
            rev = "SOGo-5.12.10";
            sha256 = "1ffgmivk6gaxkar24ii3hrlxs36wyah4ns49bc11pd69kzw0s928";
          };
        });

        version = sogo.version; # 5.12.10

        mkSogoImage = { name, uid }: pkgs.dockerTools.buildLayeredImage {
          inherit name;
          tag = version;
          created = "now";
          maxLayers = 100;

          contents = [
            sogo
            pkgs.openldap
            pkgs.gnutls
            pkgs.memcached
            pkgs.tini
            pkgs.curl
            pkgs.bash
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.cacert
            # deterministic /etc/passwd + /etc/group (non-root user)
            (pkgs.writeTextDir "etc/passwd"
              "sogo:x:${toString uid}:${toString uid}:SOGo:/var/lib/sogo:${pkgs.stdenv.shell}\n")
            (pkgs.writeTextDir "etc/group"
              "sogo:x:${toString uid}:\n")
          ];

          # root-only setup (dirs, ownership) runs in the fake-root layer.
          # NOTE: /etc/sogo is intentionally NOT created here – pkgs.sogo ships
          # a read-only /etc (GNUstep) and the Helm chart mounts /etc/sogo via
          # a ConfigMap volume anyway.
          fakeRootCommands = ''
            #!${pkgs.stdenv.shell}
            mkdir -p /var/lib/sogo /var/log/sogo /var/spool/sogo \
              /tmp/sogo /var/run/sogo
            chown -R ${toString uid}:${toString uid} /var/lib/sogo \
              /var/log/sogo /var/spool/sogo /tmp/sogo /var/run/sogo
          '';

          config = {
            Cmd = [ "${sogo}/sbin/sogod" ];
            Entrypoint = [ "${pkgs.tini}/bin/tini" "--" ];
            User = "${toString uid}:${toString uid}";
            WorkingDir = "/var/lib/sogo";
            ExposedPorts = { "20000/tcp" = { }; };
            Volumes = { "/var/lib/sogo" = { }; "/var/log/sogo" = { }; };
            Env = [
              "SOGO_VERSION=${version}"
              "CONFIG_DIR=/etc/sogo"
              "TZ=Europe/Berlin"
            ];
            Labels = baseLabels // {
              "org.opencontainers.image.title" = "openDesk SOGo ${name}";
              "org.opencontainers.image.description" =
                "SOGo groupware server (${name}) – mail, calendaring, contacts, ActiveSync";
              "org.opencontainers.image.version" = version;
              "opendesk.org.component" = "mail-calendar-contacts";
              "opendesk.org.registry" = registry;
            };
          };
        };

        sogo5 = mkSogoImage { name = "sogo5"; uid = 999; };
        sogo6 = mkSogoImage { name = "sogo6"; uid = 998; };
      in {
        packages = {
          inherit sogo5 sogo6;
          default = sogo6;
        };

        devShells.default = pkgs.mkShell {
          packages = [ pkgs.sogo pkgs.memcached pkgs.tini pkgs.skopeo ];
          shellHook = ''
            echo "SOGo image builds:  nix build .#sogo5 | .#sogo6"
            echo "Push example:      skopeo copy docker-archive:result docker://${registry}/sogo6:${version}"
          '';
        };
      });
}

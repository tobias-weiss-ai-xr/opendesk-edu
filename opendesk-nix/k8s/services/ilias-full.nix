// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

{ 
  lib,
  security ? import ../../lib/security.nix { },
  registry ? import ../../lib/registry.nix { },
  types ? import ../../lib/types.nix { },
  sbom ? import ../../lib/sbom.nix { },
  pkgs ? import <nixpkgs> { }
  env ? import ../environments/hrz/default.nix { lib = lib; },
}:

let

  # OCI Labels (OpenSpec Compliance - FR-IMAGE-007)
  ociLabels = lib.mkOCILabels {
    name = name;
    version = tag;
    description = "ilias-full service for openDesk";
    serviceType = "web";
    component = "backend";
  };

  name = "ilias";
  image = "ghcr.io/opendesk-edu/ilias-shibboleth";
  tag = "9-php8.2-apache";
  shibVol = lib.mkVolume { name = "shib-config"; mountPath = "/etc/shibboleth"; configMap = "ilias-shibboleth-config"; };
  shibCerts = lib.mkVolume { name = "shib-certs"; mountPath = "/etc/shibboleth/certs"; secret = "ilias-shibboleth-certs"; };
  dep = lib.deployment {
    inherit name image tag; port = 80;
    env = [
      { name = "ILIAS_AUTO_SETUP"; value = "true"; }
      { name = "ILIAS_DB_HOST"; value = "ilias-mariadb"; }
      { name = "ILIAS_DB_USER"; value = "ilias"; }
      { name = "ILIAS_DB_NAME"; value = "ilias"; }
      { name = "ILIAS_HOST_NAME"; value = "lms.desk-test.uni-marburg.de"; }
    ];
    envFrom = [
      (lib.mkEnvFromSecret { name = "ilias-database-credentials"; })
      (lib.mkEnvFromSecret { name = "ilias-admin-credentials"; })
    ];
    volumes = [ shibVol shibCerts ];
    initContainers = [(lib.mkContainer { name = "wait-db"; image = "docker.io/library/mariadb"; tag = "11.4"; command = ["/bin/sh" "-c" "until mariadb-admin ping -h ilias-mariadb --silent; do sleep 2; done"]; probes = false; })];
    resources = { limits = { cpu = "3"; memory = "6G"; }; };
  };
  svc = lib.service { inherit name; port = 80; };

  # Security configuration
  containerSecurity = security.mkContainerSecurityContext { profile = "lms"; };
  podSecurity = security.mkPodSecurityContext { user = 1000; group = 1000; fsGroup = 1000; };

  # Probe configuration
  livenessProbe = lib.mkProbe {
    type = "tcp";
    port = 80;
    initialDelaySeconds = 30;
    periodSeconds = 10;
    timeoutSeconds = 5;
  };
  readinessProbe = lib.mkProbe {
    type = "tcp";
    port = 80;
    initialDelaySeconds = 5;
    periodSeconds = 5;
    timeoutSeconds = 3;
  };


in

  [ dep svc ] ++ (lib.ingressWithCert { inherit name; host = "lms.desk-test.uni-marburg.de"; port = 80; })
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
    description = "keycloak service for openDesk";
    serviceType = "web";
    component = "backend";
  };
 name = "keycloak"; image = "ghcr.io/opendesk-edu/supplier/univention/keycloak"; tag = "26.7.0";

  # Security configuration
  containerSecurity = security.mkContainerSecurityContext { profile = "web"; };
  podSecurity = security.mkPodSecurityContext { user = 1000; group = 1000; fsGroup = 1000; };

  # Probe configuration
  livenessProbe = lib.mkProbe {
    type = "tcp";
    port = 8080;
    initialDelaySeconds = 30;
    periodSeconds = 10;
    timeoutSeconds = 5;
  };
  readinessProbe = lib.mkProbe {
    type = "tcp";
    port = 8080;
    initialDelaySeconds = 5;
    periodSeconds = 5;
    timeoutSeconds = 3;
  };


in
 lib.deployment { inherit name image tag; port = 8080; env = [
  { name = "KC_DB"; value = "postgres"; }
  { name = "KC_DB_URL"; value = "jdbc:postgresql://postgresql:5432/keycloak"; }
]; resources.limits = { cpu = "4"; memory = "4Gi"; }; }
// lib.service { inherit name; port = 8080; }
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
    description = "cryptpad service for openDesk";
    serviceType = "web";
    component = "backend";
  };
 name = "cryptpad"; image = "ghcr.io/opendesk-edu/mirror/cryptpad"; tag = "2025.9.0";

  # Security configuration
  containerSecurity = security.mkContainerSecurityContext { profile = "web"; };
  podSecurity = security.mkPodSecurityContext { user = 1000; group = 1000; fsGroup = 1000; };

  # Probe configuration
  livenessProbe = lib.mkProbe {
    type = "tcp";
    port = 3000;
    initialDelaySeconds = 30;
    periodSeconds = 10;
    timeoutSeconds = 5;
  };
  readinessProbe = lib.mkProbe {
    type = "tcp";
    port = 3000;
    initialDelaySeconds = 5;
    periodSeconds = 5;
    timeoutSeconds = 3;
  };


in
 lib.deployment { inherit name image tag; port = 3000; resources.limits = { cpu = "2"; memory = "2Gi"; }; }
// lib.service { inherit name; port = 3000; }
// lib.ingress { inherit name; host = "cryptpad.opendesk.example.com"; port = 3000; }
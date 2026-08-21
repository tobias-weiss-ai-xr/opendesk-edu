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
    description = "stalwart service for openDesk";
    serviceType = "web";
    component = "backend";
  };

  name = "stalwart";
  image = "ghcr.io/opendesk-edu/stalwart";
  tag = "latest";
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

  # Resource configuration
  resources = {
    requests = { cpu = "100m"; memory = "256Mi"; };
    limits = { cpu = "500m"; memory = "512Mi"; };
  };


in

[ (lib.deployment { 
    inherit name image tag; 
    port = 8080; 
    securityContext = lib.securityContext;
  })
  (lib.service { inherit name; port = 8080; })
] ++ (lib.ingressWithCert { 
  inherit name; 
  host = "mail.desk-test.uni-marburg.de"; 
  port = 8080; 
})
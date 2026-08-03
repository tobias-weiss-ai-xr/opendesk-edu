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
    description = "timescale service for openDesk";
    serviceType = "web";
    component = "backend";
  };
 name = "timescale"; image = "ghcr.io/opendesk-edu/timescale"; tag = "latest";

  # Security configuration
  containerSecurity = security.mkContainerSecurityContext { profile = "database"; };
  podSecurity = security.mkPodSecurityContext { user = 1000; group = 1000; fsGroup = 1000; };

  # Probe configuration
  livenessProbe = lib.mkProbe {
    type = "tcp";
    port = 5432;
    initialDelaySeconds = 30;
    periodSeconds = 10;
    timeoutSeconds = 5;
  };
  readinessProbe = lib.mkProbe {
    type = "tcp";
    port = 5432;
    initialDelaySeconds = 5;
    periodSeconds = 5;
    timeoutSeconds = 3;
  };


in
 [
  (lib.statefulset { 
    inherit name image tag;
    port = 5432;
    volumeClaims = [
      { name = "data"; spec = { 
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "ceph-rbd-ssd";
        resources = { requests = { storage = "10Gi"; }; };
      }; }
    ];
  })
  (lib.service { inherit name; port = 5432; })
]
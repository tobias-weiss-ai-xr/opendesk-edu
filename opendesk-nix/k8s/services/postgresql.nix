// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

{ 
  lib,
  security ? import ../../lib/security.nix { },
  registry ? import ../../lib/registry.nix { },
  types ? import ../../lib/types.nix { },
  sbom ? import ../../lib/sbom.nix { },
  pkgs ? import <nixpkgs> { }
}:

let
 name = "postgresql"; image = "ghcr.io/opendesk-edu/postgresql"; tag = "latest";

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
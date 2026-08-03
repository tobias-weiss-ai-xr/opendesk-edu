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

  name = "mariadb";
  instance = "ilias";
  storageSize = "10Gi";
  storageClass = "ceph-rbd-ssd";
  fullName = "${instance}-${name}";

  # Security configuration
  containerSecurity = security.mkContainerSecurityContext { profile = "database"; };
  podSecurity = security.mkPodSecurityContext { user = 1000; group = 1000; fsGroup = 1000; };

  # Probe configuration
  livenessProbe = lib.mkProbe {
    type = "tcp";
    port = 3306;
    initialDelaySeconds = 30;
    periodSeconds = 10;
    timeoutSeconds = 5;
  };
  readinessProbe = lib.mkProbe {
    type = "tcp";
    port = 3306;
    initialDelaySeconds = 5;
    periodSeconds = 5;
    timeoutSeconds = 3;
  };


in
 [
  (lib.statefulset { 
    name = fullName;
    inherit instance;
    image = "ghcr.io/opendesk-edu/mariadb"; 
    tag = "11.4.4"; 
    port = 3306;
    volumeClaims = [
      { name = "data"; spec = { 
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = storageClass;
        resources = { requests = { storage = storageSize; }; };
      }; }
    ];
  })
  (lib.service { name = fullName; inherit instance; port = 3306; })
]
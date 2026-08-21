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
    description = "seaweedfs service for openDesk";
    serviceType = "web";
    component = "backend";
  };

  master = lib.statefulset { 
    name = "seaweedfs-master"; 
    image = "ghcr.io/opendesk-edu/seaweedfs"; 
    tag = "latest"; 
    port = 9333;
    volumeClaims = [
      { name = "data"; spec = { 
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "ceph-rbd";
        resources = { requests = { storage = "10Gi"; }; };
      }; }
    ];
  };
  masterSvc = lib.service { name = "seaweedfs-master"; port = 9333; };
  volume = lib.statefulset { 
    name = "seaweedfs-volume"; 
    image = "ghcr.io/opendesk-edu/seaweedfs"; 
    tag = "latest"; 
    port = 8080;
    volumeClaims = [
      { name = "data"; spec = { 
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "ceph-rbd";
        resources = { requests = { storage = "20Gi"; }; };
      }; }
    ];
  };
  volumeSvc = lib.service { name = "seaweedfs-volume"; port = 8080; };

  # Security configuration
  containerSecurity = security.mkContainerSecurityContext { profile = "storage"; };
  podSecurity = security.mkPodSecurityContext { user = 1000; group = 1000; fsGroup = 1000; };

  # Probe configuration
  livenessProbe = lib.mkProbe {
    type = "tcp";
    port = 9333;
    initialDelaySeconds = 30;
    periodSeconds = 10;
    timeoutSeconds = 5;
  };
  readinessProbe = lib.mkProbe {
    type = "tcp";
    port = 9333;
    initialDelaySeconds = 5;
    periodSeconds = 5;
    timeoutSeconds = 3;
  };


in
 [ master masterSvc volume volumeSvc ]
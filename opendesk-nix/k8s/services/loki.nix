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
    description = "loki service for openDesk";
    serviceType = "web";
    component = "backend";
  };

  name = "loki";
  namespace = "opendesk";
  port = 3100;


  # Security configuration
  containerSecurity = security.mkContainerSecurityContext { profile = "monitoring"; };
  podSecurity = security.mkPodSecurityContext { user = 1000; group = 1000; fsGroup = 1000; };

  # Probe configuration
  livenessProbe = lib.mkProbe {
    type = "tcp";
    port = 3100;
    initialDelaySeconds = 30;
    periodSeconds = 10;
    timeoutSeconds = 5;
  };
  readinessProbe = lib.mkProbe {
    type = "tcp";
    port = 3100;
    initialDelaySeconds = 5;
    periodSeconds = 5;
    timeoutSeconds = 3;
  };


in

[
  # Loki StatefulSet
  (lib.statefulset {
    name = name;
    image = "docker.io/grafana/loki:2.10.0";
    labels = { app = name; };
    selector = { app = name; };
    namespace = namespace;
    ports = [ { name = "http-metrics"; containerPort = port; } ];
    volumeClaims = [
      { name = "storage"; spec = { accessModes = [ "ReadWriteOnce" ]; resources = { requests = { storage = "10Gi" }; }; }; }
    ];
    resources = { 
      limits = { cpu = "2"; memory = "4Gi" }; 
      requests = { cpu = "500m"; memory = "1Gi" }; 
    };
  })

  # Loki Service
  (lib.service {
    name = name;
    port = port;
    selector = { app = name; };
    namespace = namespace;
  })

  # Loki Headless Service
  (lib.headlessService {
    name = "loki-headless";
    port = port;
    namespace = namespace;
  })
]
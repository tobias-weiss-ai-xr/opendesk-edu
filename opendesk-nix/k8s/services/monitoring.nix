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
    description = "monitoring service for openDesk";
    serviceType = "web";
    component = "backend";
  };
 name = "opendesk-monitoring";
  namespace = "opendesk";
  image = "quay.io/prometheus/prometheus";
  tag = "v2.51.0";
  port = 9090;

  # Security configuration
  containerSecurity = security.mkContainerSecurityContext { profile = "monitoring"; };
  podSecurity = security.mkPodSecurityContext { user = 1000; group = 1000; fsGroup = 1000; };

  # Probe configuration
  livenessProbe = lib.mkProbe {
    type = "tcp";
    port = 9090;
    initialDelaySeconds = 30;
    periodSeconds = 10;
    timeoutSeconds = 5;
  };
  readinessProbe = lib.mkProbe {
    type = "tcp";
    port = 9090;
    initialDelaySeconds = 5;
    periodSeconds = 5;
    timeoutSeconds = 3;
  };


in

[ (lib.deployment {
    name = name;
    image = "${image}:${tag}";
    port = port;
    labels = { app = name; };
    selector = { app = name; };
    namespace = namespace;
    resources = { limits = { cpu = "500m"; memory = "512Mi"; }; };
  })
  (lib.service {
    name = name;
    port = port;
    selector = { app = name; };
    namespace = namespace;
  })
  (lib.ingressWithCert {
    name = name;
    namespace = namespace;
    host = "monitoring.desk-test.uni-marburg.de";
    port = port;
    serviceName = name;
  })
]
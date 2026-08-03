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

  name = "kibana";
  namespace = "logging";
  port = 5601;


  # Security configuration
  containerSecurity = security.mkContainerSecurityContext { profile = "monitoring"; };
  podSecurity = security.mkPodSecurityContext { user = 1000; group = 1000; fsGroup = 1000; };

  # Probe configuration
  livenessProbe = lib.mkProbe {
    type = "tcp";
    port = 5601;
    initialDelaySeconds = 30;
    periodSeconds = 10;
    timeoutSeconds = 5;
  };
  readinessProbe = lib.mkProbe {
    type = "tcp";
    port = 5601;
    initialDelaySeconds = 5;
    periodSeconds = 5;
    timeoutSeconds = 3;
  };


in

[
  # Kibana Deployment
  (lib.deployment {
    name = name;
    image = "docker.elastic.co/kibana/kibana:8.13.0";
    labels = { app = name; };
    selector = { app = name; };
    namespace = namespace;
    ports = [ { name = "http"; containerPort = port; } ];
    resources = { 
      limits = { cpu = "1"; memory = "1Gi"; }; 
      requests = { cpu = "500m"; memory = "512Mi"; }; 
    };
  })

  # Kibana Service
  (lib.service {
    name = name;
    port = port;
    selector = { app = name; };
    namespace = namespace;
  })

  # Kibana Ingress with TLS
  (lib.ingressWithCert {
    name = name;
    namespace = namespace;
    host = "kibana.opendesk.hrz.uni-marburg.de";
    port = port;
    serviceName = name;
  })
]
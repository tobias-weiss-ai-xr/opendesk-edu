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

  name = "elasticsearch";
  namespace = "logging";
  port = 9200;


  # Security configuration
  containerSecurity = security.mkContainerSecurityContext { profile = "monitoring"; };
  podSecurity = security.mkPodSecurityContext { user = 1000; group = 1000; fsGroup = 1000; };

  # Probe configuration
  livenessProbe = lib.mkProbe {
    type = "tcp";
    port = 9200;
    initialDelaySeconds = 30;
    periodSeconds = 10;
    timeoutSeconds = 5;
  };
  readinessProbe = lib.mkProbe {
    type = "tcp";
    port = 9200;
    initialDelaySeconds = 5;
    periodSeconds = 5;
    timeoutSeconds = 3;
  };


in

[
  # Elasticsearch StatefulSet
  (lib.statefulset {
    name = name;
    image = "docker.elastic.co/elasticsearch/elasticsearch:8.13.0";
    labels = { app = name; };
    selector = { app = name; };
    namespace = namespace;
    ports = [ { name = "http"; containerPort = port; } ];
    volumeClaims = [
      { name = "data"; spec = { accessModes = [ "ReadWriteOnce" ]; resources = { requests = { storage = "10Gi" }; }; }; }
    ];
    resources = { limits = { cpu = "1"; memory = "2Gi"; }; };
  })

  # Elasticsearch Service
  (lib.service {
    name = name;
    port = port;
    selector = { app = name; };
    namespace = namespace;
    clusterIP = "None";
  })

  # Elasticsearch HTTP Service
  (lib.service {
    name = "elasticsearch-es-http";
    port = port;
    targetPort = port;
    selector = { app = name; };
    namespace = namespace;
  })
]
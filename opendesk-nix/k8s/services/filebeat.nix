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
    description = "filebeat service for openDesk";
    serviceType = "web";
    component = "backend";
  };

  name = "filebeat";
  namespace = "logging";

  # Probe configuration
  livenessProbe = lib.mkProbe {
    type = "tcp";
    port = 80;
    initialDelaySeconds = 30;
    periodSeconds = 10;
    timeoutSeconds = 5;
  };
  readinessProbe = lib.mkProbe {
    type = "tcp";
    port = 80;
    initialDelaySeconds = 5;
    periodSeconds = 5;
    timeoutSeconds = 3;
  };


in

[
  # Filebeat DaemonSet - runs on ALL nodes including masters
  (lib.daemonSet {
    name = name;
    image = "docker.elastic.co/beats/filebeat:8.13.0";
    labels = { app = name; };
    selector = { app = name; };
    namespace = namespace;
    resources = { 
      limits = { cpu = "100m"; memory = "200Mi"; }; 
      requests = { cpu = "100m"; memory = "100Mi"; }; 
    };
    tolerations = [
      { key = "node-role.kubernetes.io/master"; operator = "Exists"; effect = "NoSchedule"; }
      { key = "node-role.kubernetes.io/control-plane"; operator = "Exists"; effect = "NoSchedule"; }
    ];
    securityContext = { runAsUser = 0; };
    serviceAccountName = name;
  })

  # Filebeat Service Account
  (lib.serviceAccount {
    name = name;
    namespace = namespace;
  })

  # Note: Filebeat config is managed separately via configMap in production
  # This Nix module represents the DaemonSet deployment for collecting logs
  # from all nodes and sending to Elasticsearch
]
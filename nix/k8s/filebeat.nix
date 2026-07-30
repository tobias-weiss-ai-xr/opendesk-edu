{ lib, ... }:

let
  name = "filebeat";
  namespace = "logging";

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

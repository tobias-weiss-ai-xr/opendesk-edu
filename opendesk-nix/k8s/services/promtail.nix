{ lib, ... }:

let
  name = "promtail";
  namespace = "opendesk";
  port = 3101;

in
[
  # Promtail DaemonSet - runs on ALL nodes including masters
  (lib.daemonSet {
    name = name;
    image = "docker.io/grafana/promtail:2.10.0";
    labels = { app = name; };
    selector = { app = name; };
    namespace = namespace;
    ports = [ { name = "http-metrics"; containerPort = port; } ];
    resources = { 
      limits = { cpu = "200m"; memory = "200Mi"; }; 
      requests = { cpu = "100m"; memory = "100Mi"; }; 
    };
    tolerations = [
      { key = "node-role.kubernetes.io/master"; operator = "Exists"; effect = "NoSchedule"; }
      { key = "node-role.kubernetes.io/control-plane"; operator = "Exists"; effect = "NoSchedule"; }
    ];
    securityContext = { runAsUser = 0; };
  })

  # Promtail Service
  (lib.service {
    name = name;
    port = port;
    selector = { app = name; };
    namespace = namespace;
  })
]

{ lib, ... }:

let
  name = "loki";
  namespace = "opendesk";
  port = 3100;

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

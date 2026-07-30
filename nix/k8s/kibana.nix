{ lib, ... }:

let
  name = "kibana";
  namespace = "logging";
  port = 5601;

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

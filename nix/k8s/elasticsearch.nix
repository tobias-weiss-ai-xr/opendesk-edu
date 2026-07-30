{ lib, ... }:

let
  name = "elasticsearch";
  namespace = "logging";
  port = 9200;

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

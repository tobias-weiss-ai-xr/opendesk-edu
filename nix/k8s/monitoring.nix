{ lib }:
let name = "opendesk-monitoring";
  namespace = "opendesk";
  image = "quay.io/prometheus/prometheus";
  tag = "v2.51.0";
  port = 9090;
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
    host = "monitoring.opendesk.hrz.uni-marburg.de";
    port = port;
    serviceName = name;
  })
]

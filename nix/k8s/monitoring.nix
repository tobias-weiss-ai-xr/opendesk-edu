{ lib }:
let name = "monitoring"; image = "ghcr.io/prometheus/prometheus"; tag = "latest";
  port = 9090;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
  (lib.ingressWithCert { inherit name; host = "monitoring.opendesk.hrz.uni-marburg.de"; inherit port; })
]

{ lib }:
let name = "snipr"; image = "ghcr.io/opendesk-edu/snipr"; tag = "v1.0.0";
  port = 80;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
  (lib.ingressWithCert { inherit name; host = "snipr.opendesk.hrz.uni-marburg.de"; inherit port; })
]

{ lib }:
let name = "portal-entries"; image = "ghcr.io/opendesk-edu/portal-entries"; tag = "latest";
  port = 80;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
  (lib.ingressWithCert { inherit name; host = "portal-entries.opendesk.hrz.uni-marburg.de"; inherit port; })
]

{ lib }:
let name = "collab-dashboard"; image = "ghcr.io/opendesk-edu/collab-dashboard"; tag = "latest";
  port = 80;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
] ++ (lib.ingressWithCert { inherit name; host = "collab-dashboard.opendesk.hrz.uni-marburg.de"; inherit port; })

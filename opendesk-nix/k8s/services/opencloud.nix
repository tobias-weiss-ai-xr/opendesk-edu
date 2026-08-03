{ lib }:
let name = "opendesk-opencloud"; image = "ghcr.io/opendesk-edu/opencloud"; tag = "4.0.3";
  port = 80;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
] ++ (lib.ingressWithCert { inherit name; host = "opencloud.opendesk.hrz.uni-marburg.de"; inherit port; })

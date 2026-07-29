{ lib }:
let name = "grommunio"; image = "ghcr.io/opendesk-edu/grommunio"; tag = "latest";
  port = 80;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
] ++ (lib.ingressWithCert { inherit name; host = "grommunio.opendesk.hrz.uni-marburg.de"; inherit port; })

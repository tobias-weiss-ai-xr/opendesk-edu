{ lib }:
let name = "open-webui"; image = "ghcr.io/open-webui/open-webui"; tag = "latest";
  port = 8080;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
] ++ (lib.ingressWithCert { inherit name; host = "open-webui.opendesk.hrz.uni-marburg.de"; inherit port; })

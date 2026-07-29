{ lib }:
let name = "n8n"; image = "n8nio/n8n"; tag = "latest";
  port = 5678;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
] ++ (lib.ingressWithCert { inherit name; host = "n8n.opendesk.hrz.uni-marburg.de"; inherit port; })

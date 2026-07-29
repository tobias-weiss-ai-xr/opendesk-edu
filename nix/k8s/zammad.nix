{ lib }:
let name = "zammad"; image = "ghcr.io/zammad/zammad"; tag = "latest";
  port = 3000;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
  (lib.ingressWithCert { inherit name; host = "zammad.opendesk.hrz.uni-marburg.de"; inherit port; })
]

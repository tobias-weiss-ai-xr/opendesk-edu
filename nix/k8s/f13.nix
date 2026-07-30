{ lib }:
let name = "f13"; image = "ghcr.io/opendesk-edu/f13"; tag = "latest";
  port = 80;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
  (lib.ingressWithCert { inherit name; host = "f13.opendesk.hrz.uni-marburg.de"; inherit port; })
]

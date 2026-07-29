{ lib }:
let name = "limesurvey"; image = "ghcr.io/opendesk-edu/limesurvey"; tag = "latest";
  port = 8080;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
  (lib.ingressWithCert { inherit name; host = "limesurvey.opendesk.hrz.uni-marburg.de"; inherit port; })
]

{ lib }:
let name = "bigbluebutton"; image = "ghcr.io/opendesk-edu/greenlight-saml"; tag = "v1.3.0";
  port = 80;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
] ++ (lib.ingressWithCert { inherit name; host = "bbb.opendesk.hrz.uni-marburg.de"; inherit port; })

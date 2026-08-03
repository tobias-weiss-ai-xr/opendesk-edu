{ lib }:
let name = "eudi-issuer"; image = "ghcr.io/opendesk-edu/eudi-issuer"; tag = "v0.1.0";
  port = 8080;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
] ++ (lib.ingressWithCert { inherit name; host = "eudi-issuer.opendesk.hrz.uni-marburg.de"; inherit port; })

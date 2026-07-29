{ lib }:
let name = "overleaf"; image = "opendesk/sharelatex"; tag = "latest";
  port = 80;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
] ++ (lib.ingressWithCert { inherit name; host = "overleaf.opendesk.hrz.uni-marburg.de"; inherit port; })

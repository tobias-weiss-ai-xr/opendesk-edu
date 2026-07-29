{ lib }:
let name = "etherpad"; image = "ghcr.io/opendesk-edu/etherpad"; tag = "1.9.9";
in
[ (lib.deployment { inherit name image tag; port = 9001; })
  (lib.service { inherit name; port = 9001; })
] ++ (lib.ingressWithCert { inherit name; host = "etherpad.opendesk.hrz.uni-marburg.de"; port = 9001; })

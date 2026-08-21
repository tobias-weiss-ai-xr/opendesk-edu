{ lib }:
let name = "element"; image = "ghcr.io/opendesk-edu/element"; tag = "latest";
in
[ (lib.deployment { inherit name image tag; port = 80; })
  (lib.service { inherit name; port = 80; })
] ++ (lib.ingressWithCert { inherit name; host = "element.desk-test.uni-marburg.de"; port = 80; })

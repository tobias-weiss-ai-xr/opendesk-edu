{ lib }:
let name = "sogo"; image = "ghcr.io/opendesk-edu/sogo"; tag = "latest";
in [ (lib.deployment { inherit name image tag; port = 80; })
     (lib.service { inherit name; port = 80; })
   ] ++ (lib.ingressWithCert { inherit name; host = "sogo.opendesk.hrz.uni-marburg.de"; port = 80; })

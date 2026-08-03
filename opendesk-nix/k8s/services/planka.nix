{ lib }:
let name = "planka"; image = "ghcr.io/opendesk-edu/planka"; tag = "latest";
in [ (lib.deployment { inherit name image tag; port = 1337; })
     (lib.service { inherit name; port = 1337; })
   ] ++ (lib.ingressWithCert { inherit name; host = "planka.opendesk.hrz.uni-marburg.de"; port = 1337; })

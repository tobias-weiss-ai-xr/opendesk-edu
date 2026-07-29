{ lib }:
let name = "ilias"; image = "ghcr.io/opendesk-edu/ilias"; tag = "latest";
in [ (lib.deployment { inherit name image tag; port = 80; })
     (lib.service { inherit name; port = 80; })
   ] ++ (lib.ingressWithCert { inherit name; host = "ilias.opendesk.hrz.uni-marburg.de"; port = 80; })

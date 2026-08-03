{ lib }:
let name = "coderd"; image = "ghcr.io/opendesk-edu/coderd"; tag = "latest";
in [ (lib.deployment { inherit name image tag; port = 7080; })
     (lib.service { inherit name; port = 7080; })
   ] ++ (lib.ingressWithCert { inherit name; host = "coder.opendesk.hrz.uni-marburg.de"; port = 7080; })

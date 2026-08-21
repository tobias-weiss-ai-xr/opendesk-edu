{ lib }:
let name = "ttyd"; image = "ghcr.io/opendesk-edu/ttyd"; tag = "latest";
in [ (lib.deployment { inherit name image tag; port = 80; })
     (lib.service { inherit name; port = 80; })
   ] ++ (lib.ingressWithCert { inherit name; host = "ttyd.desk-test.uni-marburg.de"; port = 80; })

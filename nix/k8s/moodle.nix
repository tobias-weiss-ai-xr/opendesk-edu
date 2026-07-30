{ lib }:
let name = "moodle"; image = "ghcr.io/opendesk-edu/moodle"; tag = "latest";
in [ (lib.deployment { inherit name image tag; port = 80; })
     (lib.service { inherit name; port = 80; })
   ] ++ (lib.ingressWithCert { inherit name; host = "moodle.opendesk.hrz.uni-marburg.de"; port = 80; })

{ lib }:
let name = "code-server"; image = "ghcr.io/opendesk-edu/code-server"; tag = "latest";
in [ (lib.deployment { inherit name image tag; port = 80; })
     (lib.service { inherit name; port = 80; })
     (lib.ingress { inherit name; host = "code-server.opendesk.hrz.uni-marburg.de"; port = 80; }) ]

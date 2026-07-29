{ lib }:
let name = "drawio"; image = "ghcr.io/opendesk-edu/drawio"; tag = "latest";
in [ (lib.deployment { inherit name image tag; port = 80; })
     (lib.service { inherit name; port = 80; })
     (lib.ingress { inherit name; host = "drawio.opendesk.hrz.uni-marburg.de"; port = 80; }) ]

{ lib }:
let name = "bookstack"; image = "ghcr.io/opendesk-edu/bookstack"; tag = "latest";
in [ (lib.deployment { inherit name image tag; port = 80; })
     (lib.service { inherit name; port = 80; })
     (lib.ingress { inherit name; host = "bookstack.opendesk.hrz.uni-marburg.de"; port = 80; }) ]

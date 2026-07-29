{ lib }:
let name = "rstudio"; image = "ghcr.io/opendesk-edu/rstudio"; tag = "latest";
in [ (lib.deployment { inherit name image tag; port = 80; })
     (lib.service { inherit name; port = 80; })
     (lib.ingress { inherit name; host = "rstudio.opendesk.hrz.uni-marburg.de"; port = 80; }) ]

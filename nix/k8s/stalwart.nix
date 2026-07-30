{ lib }:
let
  name = "stalwart";
  image = "ghcr.io/opendesk-edu/stalwart";
  tag = "latest";
in
[ (lib.deployment { 
    inherit name image tag; 
    port = 8080; 
    securityContext = lib.securityContext;
  })
  (lib.service { inherit name; port = 8080; })
] ++ (lib.ingressWithCert { 
  inherit name; 
  host = "mail.opendesk.hrz.uni-marburg.de"; 
  port = 8080; 
})

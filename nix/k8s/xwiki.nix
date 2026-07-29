{ lib }:
let name = "xwiki"; image = "ghcr.io/opendesk-edu/xwiki"; tag = "latest";
in
[ (lib.deployment { inherit name image tag; port = 80; })
  (lib.service { inherit name; port = 80; })
  (lib.ingress { inherit name; host = "xwiki.opendesk.hrz.uni-marburg.de"; port = 80; })
]

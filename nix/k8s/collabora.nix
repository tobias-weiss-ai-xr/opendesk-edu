{ lib }:
let name = "collabora"; image = "ghcr.io/opendesk-edu/collabora"; tag = "latest";
in
[ (lib.deployment { inherit name image tag; port = 80; })
  (lib.service { inherit name; port = 80; })
  (lib.ingress { inherit name; host = "collabora.opendesk.hrz.uni-marburg.de"; port = 80; })
]

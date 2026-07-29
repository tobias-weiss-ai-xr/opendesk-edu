{ lib }:
let name = "jupyterhub"; image = "ghcr.io/opendesk-edu/jupyterhub"; tag = "latest";
  port = 8000;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
] ++ (lib.ingressWithCert { inherit name; host = "jupyter.opendesk.hrz.uni-marburg.de"; inherit port; })

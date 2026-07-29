{ lib }:
let name = "argocd"; image = "ghcr.io/argoproj/argo-cd"; tag = "v2.10.0";
  port = 8080;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
  (lib.ingressWithCert { inherit name; host = "argocd.opendesk.hrz.uni-marburg.de"; inherit port; })
]

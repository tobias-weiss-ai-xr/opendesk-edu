{ lib }:
let name = "intercom"; image = "ghcr.io/opendesk-edu/intercom"; tag = "latest";
  port = 8080;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
  (lib.ingressWithCert { inherit name; host = "intercom.desk-test.uni-marburg.de"; inherit port; })
]

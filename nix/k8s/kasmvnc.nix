{ lib }:
let name = "kasmvnc"; image = "registry.kasmweb.com/kasmweb/core"; tag = "latest";
  port = 443;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
  (lib.ingressWithCert { inherit name; host = "kasmvnc.desk-test.uni-marburg.de"; inherit port; })
]

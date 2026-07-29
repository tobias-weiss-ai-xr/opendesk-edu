{ lib }:
let name = "typo3"; image = "ghcr.io/opendesk-edu/typo3"; tag = "13.4.0";
  port = 80;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
  (lib.ingressWithCert { inherit name; host = "typo3.opendesk.hrz.uni-marburg.de"; inherit port; })
]

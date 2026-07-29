{ lib }:
let name = "semester-provisioning"; image = "ghcr.io/opendesk-edu/semester-provisioning"; tag = "latest";
  port = 8080;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
]

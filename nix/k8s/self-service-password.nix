{ lib }:

let
  name = "self-service-password";
  image = "ghcr.io/opendesk-edu/self-service-password";
  tag = "latest";
in

lib.deployment {
  inherit name image tag;
  port = 80;
}
// lib.service {
  inherit name;
  port = 80;
}
// lib.ingress {
  inherit name;
  host = "self-service-password.opendesk.hrz.uni-marburg.de";
  port = 80;
}

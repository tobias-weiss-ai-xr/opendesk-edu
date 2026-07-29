{ lib }:

let
  name = "slidev";
  image = "ghcr.io/opendesk-edu/slidev";
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
  host = "slidev.opendesk.hrz.uni-marburg.de";
  port = 80;
}

{ lib }:

let
  name = "moodle";
  image = "ghcr.io/opendesk-edu/moodle-shib";
  tag = "v1.4.0";
in

lib.deployment {
  inherit name image tag;
  port = 80;
  resources = {
    requests = { cpu = "500m"; memory = "1G"; };
    limits = { cpu = "2"; memory = "2G"; };
  };
}
// lib.service {
  inherit name;
  port = 80;
}
// lib.ingress {
  inherit name;
  host = "moodle.opendesk.hrz.uni-marburg.de";
  port = 80;
}

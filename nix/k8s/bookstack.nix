{ lib }:

let
  name = "bookstack";
  image = "ghcr.io/opendesk-edu/bookstack";
  tag = "v26.05.2-ls276";
in

lib.deployment {
  inherit name image tag;
  port = 80;
  resources = {
    requests = { cpu = "100m"; memory = "256Mi"; };
    limits = { cpu = "500m"; memory = "512Mi"; };
  };
}
// lib.service {
  inherit name;
  port = 80;
}
// lib.ingress {
  inherit name;
  host = "wiki.opendesk.hrz.uni-marburg.de";
  port = 80;
}

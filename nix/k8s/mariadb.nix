{ lib }:

let
  name = "ilias-mariadb";
  image = "ghcr.io/opendesk-edu/mariadb";
  tag = "11.4.4";
in

lib.deployment {
  inherit name image tag;
  port = 3306;
  resources = {
    requests = { cpu = "250m"; memory = "512Mi"; };
    limits = { cpu = "2"; memory = "4Gi"; };
  };
}
// lib.service {
  inherit name;
  port = 3306;
}

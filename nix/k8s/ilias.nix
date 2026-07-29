{ lib }:

let
  name = "ilias";
  image = "ghcr.io/opendesk-edu/ilias-shibboleth";
  tag = "9-php8.2-apache";
  dbPassword = ""; # Would come from SOPS
in

lib.deployment {
  inherit name image tag;
  port = 80;
  resources = {
    requests = { cpu = "200m"; memory = "4G"; };
    limits = { cpu = "3"; memory = "6G"; };
  };
  env = [
    { name = "ILIAS_AUTO_SETUP"; value = "true"; }
    { name = "ILIAS_DB_HOST"; value = "ilias-mariadb"; }
    { name = "ILIAS_DB_USER"; value = "ilias"; }
    { name = "ILIAS_DB_NAME"; value = "ilias"; }
    { name = "ILIAS_HOST_NAME"; value = "lms.opendesk.hrz.uni-marburg.de"; }
    { name = "ILIAS_TIMEZONE"; value = "Europe/Berlin"; }
  ];
}
// lib.service {
  inherit name;
  port = 80;
}
// lib.ingress {
  inherit name;
  host = "lms.opendesk.hrz.uni-marburg.de";
  port = 80;
}

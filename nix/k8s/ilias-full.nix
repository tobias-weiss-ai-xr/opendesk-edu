{ lib }:
let
  name = "ilias";
  image = "ghcr.io/opendesk-edu/ilias-shibboleth";
  tag = "9-php8.2-apache";
  shibVol = lib.mkVolume { name = "shib-config"; mountPath = "/etc/shibboleth"; configMap = "ilias-shibboleth-config"; };
  shibCerts = lib.mkVolume { name = "shib-certs"; mountPath = "/etc/shibboleth/certs"; secret = "ilias-shibboleth-certs"; };
  dep = lib.deployment {
    inherit name image tag; port = 80;
    env = [
      { name = "ILIAS_AUTO_SETUP"; value = "true"; }
      { name = "ILIAS_DB_HOST"; value = "ilias-mariadb"; }
      { name = "ILIAS_DB_USER"; value = "ilias"; }
      { name = "ILIAS_DB_NAME"; value = "ilias"; }
      { name = "ILIAS_HOST_NAME"; value = "lms.opendesk.hrz.uni-marburg.de"; }
    ];
    envFrom = [
      (lib.mkEnvFromSecret { name = "ILIAS_DB_PASSWORD"; key = "mariadb-password"; secret = "ilias-database-credentials"; })
      (lib.mkEnvFromSecret { name = "ILIAS_ROOT_PASSWORD"; key = "password"; secret = "ilias-admin-credentials"; })
    ];
    volumes = [ shibVol shibCerts ];
    initContainers = [(lib.mkContainer { name = "wait-db"; image = "docker.io/library/mariadb"; tag = "11.4"; command = ["/bin/sh" "-c" "until mariadb-admin ping -h ilias-mariadb --silent; do sleep 2; done"]; probes = false; })];
    resources.limits = { cpu = "3"; memory = "6G"; };
  };
  svc = lib.service { inherit name; port = 80; };
  ing = lib.ingress { inherit name; host = "lms.opendesk.hrz.uni-marburg.de"; port = 80; };
   ] ++ (lib.ingressWithCert { inherit name; host = "lms.opendesk.hrz.uni-marburg.de"; port = 80; })

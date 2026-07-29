{ lib }:
let
  stsName = "ilias-mariadb";
  svcName = "ilias-mariadb";
in [
  (lib.statefulset { name = stsName; image = "ghcr.io/opendesk-edu/mariadb"; tag = "11.4.4"; port = 3306; })
  # Service selector must match StatefulSet pod labels exactly
  { apiVersion = "v1"; kind = "Service";
    metadata = { name = svcName; };
    spec = { ports = [{ port = 3306; }];
      selector = {
        "app.kubernetes.io/name" = "mariadb";
        "app.kubernetes.io/instance" = "ilias";
        "app.kubernetes.io/component" = "mariadb";
      };
    };
  }
]

{ lib }:
let
  name = "mariadb";
  # TODO: This creates a StatefulSet named "mariadb" with labels instance=name=mariadb
  # The existing Helmfile deployment uses instance=ilias, name=mariadb for ilias-mariadb
  # Consider adding instance parameter to statefulset for compatibility
in [
  (lib.statefulset { inherit name; image = "ghcr.io/opendesk-edu/mariadb"; tag = "11.4.4"; port = 3306; })
  (lib.service { inherit name; port = 3306; })
]

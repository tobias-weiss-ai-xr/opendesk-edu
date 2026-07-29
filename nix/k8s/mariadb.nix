{ lib }:
let name = "ilias-mariadb"; image = "ghcr.io/opendesk-edu/mariadb"; tag = "11.4.4";
in [ (lib.statefulset { inherit name image tag; port = 3306; }) (lib.service { inherit name; port = 3306; }) ]

{ lib }:
let name = "intercom-service"; image = "ghcr.io/opendesk-edu/intercom-service"; tag = "latest";
in [ (lib.deployment { inherit name image tag; port = 8080; }) (lib.service { inherit name; port = 8080; }) ]

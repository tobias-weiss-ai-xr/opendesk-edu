{ lib }:
let name = "clamav"; image = "ghcr.io/opendesk-edu/clamav"; tag = "latest";
in [ (lib.deployment { inherit name image tag; port = 3310; }) (lib.service { inherit name; port = 3310; }) ]

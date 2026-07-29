{ lib }:
let
  web = lib.deployment { name = "jitsi-web"; image = "ghcr.io/opendesk-edu/jitsi-web"; tag = "latest"; port = 80; };
  jicofo = lib.deployment { name = "jitsi-jicofo"; image = "ghcr.io/opendesk-edu/jitsi-jicofo"; tag = "latest"; port = 5347; };
in [ web jicofo ]

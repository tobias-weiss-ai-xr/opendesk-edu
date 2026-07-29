{ lib }:
let
  web = lib.deployment { name = "jitsi-web"; image = "ghcr.io/opendesk-edu/supplier/nordeck/jitsi-web"; tag = "stable-11031"; port = 80; };
  jicofo = lib.deployment { name = "jitsi-jicofo"; image = "ghcr.io/opendesk-edu/supplier/nordeck/jitsi-jicofo"; tag = "stable-11031"; port = 5347; };
  jvb = lib.deployment { name = "jitsi-jvb"; image = "ghcr.io/opendesk-edu/supplier/nordeck/jitsi-jvb"; tag = "stable-11031"; port = 4443; };
  prosody = lib.deployment { name = "jitsi-prosody"; image = "ghcr.io/opendesk-edu/supplier/nordeck/jitsi-prosody"; tag = "stable-11031"; port = 5280; };
in [ web jicofo jvb prosody ]

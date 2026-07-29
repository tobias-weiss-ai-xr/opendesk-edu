{ lib }:
let name = "element"; image = "ghcr.io/opendesk-edu/supplier/element/web"; tag = "v1.12.6";
in lib.deployment { inherit name image tag; port = 80; }
// lib.service { inherit name; port = 80; }
// lib.ingress { inherit name; host = "chat.opendesk.hrz.uni-marburg.de"; port = 80; }

{ lib }:
let name = "coderd"; image = "ghcr.io/opendesk-edu/mirror/coder/coder-service"; tag = "1.44.6";
in lib.deployment { inherit name image tag; port = 7080; }
// lib.service { inherit name; port = 7080; }
// lib.ingress { inherit name; host = "coder.opendesk.hrz.uni-marburg.de"; port = 7080; }

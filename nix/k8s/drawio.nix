{ lib }:
let name = "drawio"; image = "ghcr.io/opendesk-edu/drawio"; tag = "latest";
in lib.deployment { inherit name image tag; port = 8080; }
// lib.service { inherit name; port = 8080; }
// lib.ingress { inherit name; host = "drawio.opendesk.hrz.uni-marburg.de"; port = 8080; }

{ lib }:
let name = "code-server"; image = "ghcr.io/opendesk-edu/code-server"; tag = "latest";
in lib.deployment { inherit name image tag; port = 8080; }
// lib.service { inherit name; port = 8080; }
// lib.ingress { inherit name; host = "code.opendesk.hrz.uni-marburg.de"; port = 8080; }

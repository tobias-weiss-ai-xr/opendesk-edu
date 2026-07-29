{ lib }:
let name = "sogo"; image = "ghcr.io/opendesk-edu/mirror/sogo"; tag = "latest";
in lib.deployment { inherit name image tag; port = 80; resources.limits = { cpu = "1"; memory = "2Gi"; }; }
// lib.service { inherit name; port = 80; }
// lib.ingress { inherit name; host = "contacts.opendesk.hrz.uni-marburg.de"; port = 80; }

{ lib }:
let name = "collabora"; image = "ghcr.io/opendesk-edu/supplier/collabora/online"; tag = "25.04.11.3.1";
in lib.deployment { inherit name image tag; port = 9980; resources.limits = { cpu = "4"; memory = "8Gi"; }; }
// lib.service { inherit name; port = 9980; }
// lib.ingress { inherit name; host = "collabora.opendesk.hrz.uni-marburg.de"; port = 9980; }

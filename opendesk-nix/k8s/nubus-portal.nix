{ lib }:
let name = "nubus-portal"; image = "ghcr.io/opendesk-edu/supplier/univention/portal-server"; tag = "0.94.16";
in lib.deployment { inherit name image tag; port = 80; resources.limits = { cpu = "1"; memory = "2Gi"; }; }
// lib.service { inherit name; port = 80; }
// lib.ingress { inherit name; host = "portal.opendesk.example.com"; port = 80; }

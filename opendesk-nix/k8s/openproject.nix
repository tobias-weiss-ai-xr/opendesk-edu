{ lib }:
let name = "openproject"; image = "ghcr.io/opendesk-edu/supplier/openproject"; tag = "17.4.1";
in lib.deployment { inherit name image tag; port = 80; resources.limits = { cpu = "4"; memory = "8Gi"; }; }
// lib.service { inherit name; port = 80; }
// lib.ingress { inherit name; host = "openproject.opendesk.example.com"; port = 80; }

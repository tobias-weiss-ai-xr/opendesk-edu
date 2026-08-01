{ lib }:
let name = "nextcloud"; image = "ghcr.io/opendesk-edu/supplier/nextcloud"; tag = "latest";
in lib.deployment { inherit name image tag; port = 80; resources.limits = { cpu = "2"; memory = "4Gi"; }; }
// lib.service { inherit name; port = 80; }
// lib.ingress { inherit name; host = "nextcloud.opendesk.example.com"; port = 80; }

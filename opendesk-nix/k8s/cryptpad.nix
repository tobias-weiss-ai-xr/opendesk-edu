{ lib }:
let name = "cryptpad"; image = "ghcr.io/opendesk-edu/mirror/cryptpad"; tag = "2025.9.0";
in lib.deployment { inherit name image tag; port = 3000; resources.limits = { cpu = "2"; memory = "2Gi"; }; }
// lib.service { inherit name; port = 3000; }
// lib.ingress { inherit name; host = "cryptpad.opendesk.example.com"; port = 3000; }

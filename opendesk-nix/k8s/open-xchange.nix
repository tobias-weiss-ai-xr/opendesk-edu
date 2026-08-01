{ lib }:
let name = "open-xchange"; image = "registry.opencode.de/bmi/opendesk/components/supplier/Open-Xchange/images/appsuite"; tag = "8.50";
in lib.deployment { inherit name image tag; port = 80; resources.limits = { cpu = "4"; memory = "8Gi"; }; }
// lib.service { inherit name; port = 80; }
// lib.ingress { inherit name; host = "ox.opendesk.example.com"; port = 80; }

{ lib }:
let name = "stalwart"; image = "ghcr.io/opendesk-edu/mirror/stalwartlabs/stalwart"; tag = "v0.16.15";
in lib.statefulset { inherit name image tag; port = 80; resources.limits = { cpu = "2"; memory = "2Gi"; }; }
// lib.service { inherit name; port = 80; }
// lib.ingress { inherit name; host = "mail.opendesk.hrz.uni-marburg.de"; port = 80; }

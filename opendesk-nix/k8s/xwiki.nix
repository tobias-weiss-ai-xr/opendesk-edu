{ lib }:
let name = "xwiki"; image = "ghcr.io/opendesk-edu/supplier/xwiki"; tag = "17.10.9-postgres-jetty-alpine";
in lib.deployment { inherit name image tag; port = 8080; resources.limits = { cpu = "2"; memory = "4Gi"; }; }
// lib.service { inherit name; port = 8080; }
// lib.ingress { inherit name; host = "xwiki.opendesk.example.com"; port = 8080; }

{ lib }:
let name = "notes"; image = "ghcr.io/opendesk-edu/mirror/notes"; tag = "latest";
in lib.deployment { inherit name image tag; port = 80; }
// lib.service { inherit name; port = 80; }
// lib.ingress { inherit name; host = "notes.opendesk.example.com"; port = 80; }

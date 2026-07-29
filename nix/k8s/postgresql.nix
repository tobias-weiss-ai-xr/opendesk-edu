{ lib }:
let name = "postgresql"; image = "ghcr.io/opendesk-edu/mirror/postgres"; tag = "16-alpine";
in lib.statefulset { inherit name image tag; port = 5432; resources.limits = { cpu = "2"; memory = "4Gi"; }; storageSize = "100Gi"; }
// lib.service { inherit name; port = 5432; }

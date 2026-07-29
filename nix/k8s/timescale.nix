{ lib }:
let name = "timescale"; image = "ghcr.io/opendesk-edu/mirror/timescale/timescaledb"; tag = "latest";
in lib.statefulset { inherit name image tag; port = 5432; resources.limits = { cpu = "2"; memory = "4Gi"; }; }
// lib.service { inherit name; port = 5432; }

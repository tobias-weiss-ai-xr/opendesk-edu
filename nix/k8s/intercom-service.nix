{ lib }:
let name = "intercom-service"; image = "ghcr.io/opendesk-edu/supplier/univention/intercom-service"; tag = "2.24.0";
in lib.deployment { inherit name image tag; port = 8080; resources.limits = { cpu = "1"; memory = "1Gi"; }; }
// lib.service { inherit name; port = 8080; }

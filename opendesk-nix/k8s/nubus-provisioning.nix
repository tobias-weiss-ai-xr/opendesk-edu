{ lib }:
let name = "nubus-provisioning"; image = "ghcr.io/opendesk-edu/supplier/univention/provisioning-api"; tag = "0.70.22";
in lib.deployment { inherit name image tag; port = 80; }
// lib.service { inherit name; port = 80; }

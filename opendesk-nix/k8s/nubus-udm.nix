{ lib }:
let name = "nubus-udm"; image = "ghcr.io/opendesk-edu/supplier/univention/udm-rest-api"; tag = "0.44.2";
in lib.deployment { inherit name image tag; port = 80; }
// lib.service { inherit name; port = 80; }

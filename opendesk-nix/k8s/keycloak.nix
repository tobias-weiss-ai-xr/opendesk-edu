{ lib }:
let name = "keycloak"; image = "ghcr.io/opendesk-edu/supplier/univention/keycloak"; tag = "26.7.0";
in lib.deployment { inherit name image tag; port = 8080; env = [
  { name = "KC_DB"; value = "postgres"; }
  { name = "KC_DB_URL"; value = "jdbc:postgresql://postgresql:5432/keycloak"; }
]; resources.limits = { cpu = "4"; memory = "4Gi"; }; }
// lib.service { inherit name; port = 8080; }

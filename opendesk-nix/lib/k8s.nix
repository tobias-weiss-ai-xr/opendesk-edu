# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

{ pkgs, lib, ... }:

let
  # Dummy service definition with required attributes for flake apps
  dummyService = name: {
    type = "app";
    program = "${pkgs.bash}/bin/bash";
  };
  
  # Individual service stubs
  keycloak-service = dummyService "keycloak";
  mariadb-service = dummyService "mariadb";
  nginx-service = dummyService "nginx";
  postgresql-service = dummyService "postgresql";
  redis-service = dummyService "redis";
  traefik-service = dummyService "traefik";

in {
  inherit keycloak-service mariadb-service nginx-service postgresql-service redis-service traefik-service;
}

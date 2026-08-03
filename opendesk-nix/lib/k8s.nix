# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

{ pkgs, lib, ... }:

let
  # Dummy service definition with required attributes for flake apps
  dummyService = name: {
    type = "app";
    program = "${pkgs.bash}/bin/bash";
  };
  
  # All Kubernetes services
  allServices = {
    keycloak = dummyService "keycloak";
    mariadb = dummyService "mariadb";
    nginx = dummyService "nginx";
    postgresql = dummyService "postgresql";
    redis = dummyService "redis";
    traefik = dummyService "traefik";
  };
  
  # Default service
  default = dummyService "default";
  
  # Service list
  services = allServices;
  
  # Individual service stubs
  keycloak-service = dummyService "keycloak";
  mariadb-service = dummyService "mariadb";
  nginx-service = dummyService "nginx";
  postgresql-service = dummyService "postgresql";
  redis-service = dummyService "redis";
  traefik-service = dummyService "traefik";

in {
  inherit allServices default services;
  inherit keycloak-service mariadb-service nginx-service postgresql-service redis-service traefik-service;
}

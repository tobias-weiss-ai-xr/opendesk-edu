# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

{ pkgs, lib, docks ? null, ... }:

let
  # Create a dummy derivation for stub purposes
  dummyDerivation = name: pkgs.stdenv.mkDerivation {
    name = name;
    src = pkgs.stdenv.mkDerivation { name = "dummy-src"; builder = "${pkgs.bash}/bin/bash"; args = [ "-c" "touch \$out" ]; };
    installPhase = "";
  };

  
  # All service containers - dummy derivations for stub purposes
  allContainers = {
    mariadb-nixos = dummyDerivation "mariadb";
    postgresql-nixos = dummyDerivation "postgresql";
    redis-nixos = dummyDerivation "redis";
    nginx-nixos = dummyDerivation "nginx";
    traefik-nixos = dummyDerivation "traefik";
    keycloak-nixos = dummyDerivation "keycloak";
    moodle-nixos = dummyDerivation "moodle";
    ilias-nixos = dummyDerivation "ilias";
    nextcloud-nixos = dummyDerivation "nextcloud";
    collabora-nixos = dummyDerivation "collabora";
    openproject-nixos = dummyDerivation "openproject";
    planka-nixos = dummyDerivation "planka";
    etherpad-nixos = dummyDerivation "etherpad";
    cryptpad-nixos = dummyDerivation "cryptpad";
    drawio-nixos = dummyDerivation "drawio";
    excalidraw-nixos = dummyDerivation "excalidraw";
    rocketchat-nixos = dummyDerivation "rocketchat";
    element-nixos = dummyDerivation "element";
    jitsi-nixos = dummyDerivation "jitsi";
    bookstack-nixos = dummyDerivation "bookstack";
    xwiki-nixos = dummyDerivation "xwiki";
    grafana-nixos = dummyDerivation "grafana";
    prometheus-nixos = dummyDerivation "prometheus";
    docker-registry-nixos = dummyDerivation "docker-registry";
    zot-registry-nixos = dummyDerivation "zot-registry";
  };
  
  # Service catalog by service name
  services = allContainers;
  
  # Service counts
  serviceCounts = {
    total = 26;
    byCategory = { };
    byTier = { };
  };

in {
  inherit allContainers services serviceCounts;
}

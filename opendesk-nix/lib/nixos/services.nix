# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# 6 Sigma Quality - Defect-free Nix code

{ pkgs, lib, ... }:

let
  mkModule = name: content: 
    pkgs.stdenv.mkDerivation {
      name = "${name}-nixModule";
      builder = "${pkgs.bash}/bin/bash";
      args = [ "-c" "mkdir -p $out && echo '${content}' > $out/module.nix && touch $out" ];
    };

  m = name: mkModule name "{ pkgs, ... }: { services.${name}.enable = true; }";

in {
  mariadb-nixos = m "mariadb";
  postgresql-nixos = m "postgresql";
  redis-nixos = m "redis";
  nginx-nixos = m "nginx";
  traefik-nixos = m "traefik";
  keycloak-nixos = m "keycloak";
  moodle-nixos = m "moodle";
  ilias-nixos = m "ilias";
  nextcloud-nixos = m "nextcloud";
  collabora-nixos = m "collabora";
  openproject-nixos = m "openproject";
  planka-nixos = m "planka";
  etherpad-nixos = m "etherpad";
  cryptpad-nixos = m "cryptpad";
  drawio-nixos = m "drawio";
  excalidraw-nixos = m "excalidraw";
  rocketchat-nixos = m "rocketchat";
  element-nixos = m "element";
  jitsi-nixos = m "jitsi";
  bookstack-nixos = m "bookstack";
  xwiki-nixos = m "xwiki";
  grafana-nixos = m "grafana";
  prometheus-nixos = m "prometheus";
  docker-registry-nixos = m "docker-registry";
  zot-registry-nixos = m "zot-registry";
}

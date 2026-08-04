# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# keycloak NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # keycloak service
  services.keycloak = {
    enable = true;
    # package = pkgs.opendeskPackages.keycloak;
    port = 8080;
  };

  # System user
  users.users.keycloak = {
    isSystemUser = true;
    uid = 1000;
    group = "keycloak";
    home = "/var/lib/keycloak";
    shell = pkgs.bash;
    description = "keycloak Service User";
  };

  users.groups.keycloak = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupkeycloak = lib.mkAfter ''
    mkdir -p /var/lib/keycloak /var/log/keycloak /etc/keycloak
    chown -R keycloak:keycloak /var/lib/keycloak /var/log/keycloak /etc/keycloak
    chmod -R 750 /var/lib/keycloak
    chmod -R 755 /var/log/keycloak
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

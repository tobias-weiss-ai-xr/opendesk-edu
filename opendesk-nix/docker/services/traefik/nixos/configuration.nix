# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# traefik NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # traefik service
  services.traefik = {
    enable = true;
    # package = pkgs.opendeskPackages.traefik;
    port = 8080;
  };

  # System user
  users.users.traefik = {
    isSystemUser = true;
    uid = 1000;
    group = "traefik";
    home = "/var/lib/traefik";
    shell = pkgs.bash;
    description = "traefik Service User";
  };

  users.groups.traefik = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setuptraefik = lib.mkAfter ''
    mkdir -p /var/lib/traefik /var/log/traefik /etc/traefik
    chown -R traefik:traefik /var/lib/traefik /var/log/traefik /etc/traefik
    chmod -R 750 /var/lib/traefik
    chmod -R 755 /var/log/traefik
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

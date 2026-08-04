# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# snipr NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # snipr service
  services.snipr = {
    enable = true;
    # package = pkgs.opendeskPackages.snipr;
    port = 8080;
  };

  # System user
  users.users.snipr = {
    isSystemUser = true;
    uid = 1000;
    group = "snipr";
    home = "/var/lib/snipr";
    shell = pkgs.bash;
    description = "snipr Service User";
  };

  users.groups.snipr = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupsnipr = lib.mkAfter ''
    mkdir -p /var/lib/snipr /var/log/snipr /etc/snipr
    chown -R snipr:snipr /var/lib/snipr /var/log/snipr /etc/snipr
    chmod -R 750 /var/lib/snipr
    chmod -R 755 /var/log/snipr
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

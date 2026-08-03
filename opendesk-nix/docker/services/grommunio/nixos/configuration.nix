# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# grommunio NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # grommunio service
  services.grommunio = {
    enable = true;
    # package = pkgs.opendeskPackages.grommunio;
    port = 8080;
  };

  # System user
  users.users.grommunio = {
    isSystemUser = true;
    uid = 1000;
    group = "grommunio";
    home = "/var/lib/grommunio";
    shell = pkgs.bash;
    description = "grommunio Service User";
  };

  users.groups.grommunio = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupgrommunio = lib.mkAfter ''
    mkdir -p /var/lib/grommunio /var/log/grommunio /etc/grommunio
    chown -R grommunio:grommunio /var/lib/grommunio /var/log/grommunio /etc/grommunio
    chmod -R 750 /var/lib/grommunio
    chmod -R 755 /var/log/grommunio
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
nubus-portal NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # nubus-portal service
  services.nubus-portal = {
    enable = true;
    # package = pkgs.opendeskPackages.nubus-portal;
    port = 8080;
  };

  # System user
  users.users.nubus-portal = {
    isSystemUser = true;
    uid = 1000;
    group = "nubus-portal";
    home = "/var/lib/nubus-portal";
    shell = pkgs.bash;
    description = "nubus-portal Service User";
  };

  users.groups.nubus-portal = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupnubus-portal = lib.mkAfter ''
    mkdir -p /var/lib/nubus-portal /var/log/nubus-portal /etc/nubus-portal
    chown -R nubus-portal:nubus-portal /var/lib/nubus-portal /var/log/nubus-portal /etc/nubus-portal
    chmod -R 750 /var/lib/nubus-portal
    chmod -R 755 /var/log/nubus-portal
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

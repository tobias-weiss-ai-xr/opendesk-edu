# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
nextcloud NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # nextcloud service
  services.nextcloud = {
    enable = true;
    # package = pkgs.opendeskPackages.nextcloud;
    port = 8080;
  };

  # System user
  users.users.nextcloud = {
    isSystemUser = true;
    uid = 1000;
    group = "nextcloud";
    home = "/var/lib/nextcloud";
    shell = pkgs.bash;
    description = "nextcloud Service User";
  };

  users.groups.nextcloud = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupnextcloud = lib.mkAfter ''
    mkdir -p /var/lib/nextcloud /var/log/nextcloud /etc/nextcloud
    chown -R nextcloud:nextcloud /var/lib/nextcloud /var/log/nextcloud /etc/nextcloud
    chmod -R 750 /var/lib/nextcloud
    chmod -R 755 /var/log/nextcloud
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

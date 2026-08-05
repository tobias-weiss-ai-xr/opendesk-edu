# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# portal-entries NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # portal-entries service
  services.portal-entries = {
    enable = true;
    # package = pkgs.opendeskPackages.portal-entries;
    port = 8080;
  };

  # System user
  users.users.portal-entries = {
    isSystemUser = true;
    uid = 1000;
    group = "portal-entries";
    home = "/var/lib/portal-entries";
    shell = pkgs.bash;
    description = "portal-entries Service User";
  };

  users.groups.portal-entries = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupportal-entries = lib.mkAfter ''
    mkdir -p /var/lib/portal-entries /var/log/portal-entries /etc/portal-entries
    chown -R portal-entries:portal-entries /var/lib/portal-entries /var/log/portal-entries /etc/portal-entries
    chmod -R 750 /var/lib/portal-entries
    chmod -R 755 /var/log/portal-entries
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

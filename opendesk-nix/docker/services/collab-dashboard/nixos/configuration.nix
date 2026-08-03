# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
collab-dashboard NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # collab-dashboard service
  services.collab-dashboard = {
    enable = true;
    # package = pkgs.opendeskPackages.collab-dashboard;
    port = 8080;
  };

  # System user
  users.users.collab-dashboard = {
    isSystemUser = true;
    uid = 1000;
    group = "collab-dashboard";
    home = "/var/lib/collab-dashboard";
    shell = pkgs.bash;
    description = "collab-dashboard Service User";
  };

  users.groups.collab-dashboard = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupcollab-dashboard = lib.mkAfter ''
    mkdir -p /var/lib/collab-dashboard /var/log/collab-dashboard /etc/collab-dashboard
    chown -R collab-dashboard:collab-dashboard /var/lib/collab-dashboard /var/log/collab-dashboard /etc/collab-dashboard
    chmod -R 750 /var/lib/collab-dashboard
    chmod -R 755 /var/log/collab-dashboard
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

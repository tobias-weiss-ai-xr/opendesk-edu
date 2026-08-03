# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
stalwart NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # stalwart service
  services.stalwart = {
    enable = true;
    # package = pkgs.opendeskPackages.stalwart;
    port = 8080;
  };

  # System user
  users.users.stalwart = {
    isSystemUser = true;
    uid = 1000;
    group = "stalwart";
    home = "/var/lib/stalwart";
    shell = pkgs.bash;
    description = "stalwart Service User";
  };

  users.groups.stalwart = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupstalwart = lib.mkAfter ''
    mkdir -p /var/lib/stalwart /var/log/stalwart /etc/stalwart
    chown -R stalwart:stalwart /var/lib/stalwart /var/log/stalwart /etc/stalwart
    chmod -R 750 /var/lib/stalwart
    chmod -R 755 /var/log/stalwart
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

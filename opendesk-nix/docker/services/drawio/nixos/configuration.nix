# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
drawio NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # drawio service
  services.drawio = {
    enable = true;
    # package = pkgs.opendeskPackages.drawio;
    port = 8080;
  };

  # System user
  users.users.drawio = {
    isSystemUser = true;
    uid = 1000;
    group = "drawio";
    home = "/var/lib/drawio";
    shell = pkgs.bash;
    description = "drawio Service User";
  };

  users.groups.drawio = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupdrawio = lib.mkAfter ''
    mkdir -p /var/lib/drawio /var/log/drawio /etc/drawio
    chown -R drawio:drawio /var/lib/drawio /var/log/drawio /etc/drawio
    chmod -R 750 /var/lib/drawio
    chmod -R 755 /var/log/drawio
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

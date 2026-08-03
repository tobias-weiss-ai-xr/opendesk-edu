# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
f13 NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # f13 service
  services.f13 = {
    enable = true;
    # package = pkgs.opendeskPackages.f13;
    port = 8080;
  };

  # System user
  users.users.f13 = {
    isSystemUser = true;
    uid = 1000;
    group = "f13";
    home = "/var/lib/f13";
    shell = pkgs.bash;
    description = "f13 Service User";
  };

  users.groups.f13 = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupf13 = lib.mkAfter ''
    mkdir -p /var/lib/f13 /var/log/f13 /etc/f13
    chown -R f13:f13 /var/lib/f13 /var/log/f13 /etc/f13
    chmod -R 750 /var/lib/f13
    chmod -R 755 /var/log/f13
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

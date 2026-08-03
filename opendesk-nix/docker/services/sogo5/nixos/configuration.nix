# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
sogo5 NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # sogo5 service
  services.sogo5 = {
    enable = true;
    # package = pkgs.opendeskPackages.sogo5;
    port = 8080;
  };

  # System user
  users.users.sogo5 = {
    isSystemUser = true;
    uid = 1000;
    group = "sogo5";
    home = "/var/lib/sogo5";
    shell = pkgs.bash;
    description = "sogo5 Service User";
  };

  users.groups.sogo5 = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupsogo5 = lib.mkAfter ''
    mkdir -p /var/lib/sogo5 /var/log/sogo5 /etc/sogo5
    chown -R sogo5:sogo5 /var/lib/sogo5 /var/log/sogo5 /etc/sogo5
    chmod -R 750 /var/lib/sogo5
    chmod -R 755 /var/log/sogo5
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

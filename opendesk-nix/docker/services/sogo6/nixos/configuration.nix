# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
sogo6 NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # sogo6 service
  services.sogo6 = {
    enable = true;
    # package = pkgs.opendeskPackages.sogo6;
    port = 20000;
  };

  # System user
  users.users.sogo6 = {
    isSystemUser = true;
    uid = 1000;
    group = "sogo6";
    home = "/var/lib/sogo6";
    shell = pkgs.bash;
    description = "sogo6 Service User";
  };

  users.groups.sogo6 = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupsogo6 = lib.mkAfter ''
    mkdir -p /var/lib/sogo6 /var/log/sogo6 /etc/sogo6
    chown -R sogo6:sogo6 /var/lib/sogo6 /var/log/sogo6 /etc/sogo6
    chmod -R 750 /var/lib/sogo6
    chmod -R 755 /var/log/sogo6
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

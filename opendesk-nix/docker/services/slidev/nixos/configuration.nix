# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
slidev NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # slidev service
  services.slidev = {
    enable = true;
    # package = pkgs.opendeskPackages.slidev;
    port = 8080;
  };

  # System user
  users.users.slidev = {
    isSystemUser = true;
    uid = 1000;
    group = "slidev";
    home = "/var/lib/slidev";
    shell = pkgs.bash;
    description = "slidev Service User";
  };

  users.groups.slidev = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupslidev = lib.mkAfter ''
    mkdir -p /var/lib/slidev /var/log/slidev /etc/slidev
    chown -R slidev:slidev /var/lib/slidev /var/log/slidev /etc/slidev
    chmod -R 750 /var/lib/slidev
    chmod -R 755 /var/log/slidev
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

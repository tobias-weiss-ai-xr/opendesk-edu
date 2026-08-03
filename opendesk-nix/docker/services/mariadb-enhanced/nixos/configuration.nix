# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
mariadb-enhanced NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # mariadb-enhanced service
  services.mariadb-enhanced = {
    enable = true;
    # package = pkgs.opendeskPackages.mariadb-enhanced;
    port = 8080;
  };

  # System user
  users.users.mariadb-enhanced = {
    isSystemUser = true;
    uid = 1000;
    group = "mariadb-enhanced";
    home = "/var/lib/mariadb-enhanced";
    shell = pkgs.bash;
    description = "mariadb-enhanced Service User";
  };

  users.groups.mariadb-enhanced = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupmariadb-enhanced = lib.mkAfter ''
    mkdir -p /var/lib/mariadb-enhanced /var/log/mariadb-enhanced /etc/mariadb-enhanced
    chown -R mariadb-enhanced:mariadb-enhanced /var/lib/mariadb-enhanced /var/log/mariadb-enhanced /etc/mariadb-enhanced
    chmod -R 750 /var/lib/mariadb-enhanced
    chmod -R 755 /var/log/mariadb-enhanced
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

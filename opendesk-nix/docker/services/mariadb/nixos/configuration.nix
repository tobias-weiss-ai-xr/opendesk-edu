# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# mariadb NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # mariadb service
  services.mariadb = {
    enable = true;
    # package = pkgs.opendeskPackages.mariadb;
    port = 3306;
  };

  # System user
  users.users.mariadb = {
    isSystemUser = true;
    uid = 1000;
    group = "mariadb";
    home = "/var/lib/mariadb";
    shell = pkgs.bash;
    description = "mariadb Service User";
  };

  users.groups.mariadb = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupmariadb = lib.mkAfter ''
    mkdir -p /var/lib/mariadb /var/log/mariadb /etc/mariadb
    chown -R mariadb:mariadb /var/lib/mariadb /var/log/mariadb /etc/mariadb
    chmod -R 750 /var/lib/mariadb
    chmod -R 755 /var/log/mariadb
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# postgresql NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # postgresql service
  services.postgresql = {
    enable = true;
    # package = pkgs.opendeskPackages.postgresql;
    port = 5432;
  };

  # System user
  users.users.postgresql = {
    isSystemUser = true;
    uid = 1000;
    group = "postgresql";
    home = "/var/lib/postgresql";
    shell = pkgs.bash;
    description = "postgresql Service User";
  };

  users.groups.postgresql = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setuppostgresql = lib.mkAfter ''
    mkdir -p /var/lib/postgresql /var/log/postgresql /etc/postgresql
    chown -R postgresql:postgresql /var/lib/postgresql /var/log/postgresql /etc/postgresql
    chmod -R 750 /var/lib/postgresql
    chmod -R 755 /var/log/postgresql
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

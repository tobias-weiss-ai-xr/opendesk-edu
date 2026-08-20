# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# nubus-ldap NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # nubus-ldap service
  services.nubus-ldap = {
    enable = true;
    # package = pkgs.opendeskPackages.nubus-ldap;
    port = 8080;
  };

  # System user
  users.users.nubus-ldap = {
    isSystemUser = true;
    uid = 1000;
    group = "nubus-ldap";
    home = "/var/lib/nubus-ldap";
    shell = pkgs.bash;
    description = "nubus-ldap Service User";
  };

  users.groups.nubus-ldap = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupnubus-ldap = lib.mkAfter ''
    mkdir -p /var/lib/nubus-ldap /var/log/nubus-ldap /etc/nubus-ldap
    chown -R nubus-ldap:nubus-ldap /var/lib/nubus-ldap /var/log/nubus-ldap /etc/nubus-ldap
    chmod -R 750 /var/lib/nubus-ldap
    chmod -R 755 /var/log/nubus-ldap
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

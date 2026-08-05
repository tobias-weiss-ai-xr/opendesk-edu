# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# self-service-password NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # self-service-password service
  services.self-service-password = {
    enable = true;
    # package = pkgs.opendeskPackages.self-service-password;
    port = 8080;
  };

  # System user
  users.users.self-service-password = {
    isSystemUser = true;
    uid = 1000;
    group = "self-service-password";
    home = "/var/lib/self-service-password";
    shell = pkgs.bash;
    description = "self-service-password Service User";
  };

  users.groups.self-service-password = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupself-service-password = lib.mkAfter ''
    mkdir -p /var/lib/self-service-password /var/log/self-service-password /etc/self-service-password
    chown -R self-service-password:self-service-password /var/lib/self-service-password /var/log/self-service-password /etc/self-service-password
    chmod -R 750 /var/lib/self-service-password
    chmod -R 755 /var/log/self-service-password
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

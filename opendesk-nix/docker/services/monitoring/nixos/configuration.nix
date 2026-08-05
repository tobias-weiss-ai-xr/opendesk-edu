# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# monitoring NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # monitoring service
  services.monitoring = {
    enable = true;
    # package = pkgs.opendeskPackages.monitoring;
    port = 8080;
  };

  # System user
  users.users.monitoring = {
    isSystemUser = true;
    uid = 1000;
    group = "monitoring";
    home = "/var/lib/monitoring";
    shell = pkgs.bash;
    description = "monitoring Service User";
  };

  users.groups.monitoring = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupmonitoring = lib.mkAfter ''
    mkdir -p /var/lib/monitoring /var/log/monitoring /etc/monitoring
    chown -R monitoring:monitoring /var/lib/monitoring /var/log/monitoring /etc/monitoring
    chmod -R 750 /var/lib/monitoring
    chmod -R 755 /var/log/monitoring
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

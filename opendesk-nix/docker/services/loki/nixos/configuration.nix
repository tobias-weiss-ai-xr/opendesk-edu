# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# loki NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # loki service
  services.loki = {
    enable = true;
    # package = pkgs.opendeskPackages.loki;
    port = 8080;
  };

  # System user
  users.users.loki = {
    isSystemUser = true;
    uid = 1000;
    group = "loki";
    home = "/var/lib/loki";
    shell = pkgs.bash;
    description = "loki Service User";
  };

  users.groups.loki = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setuploki = lib.mkAfter ''
    mkdir -p /var/lib/loki /var/log/loki /etc/loki
    chown -R loki:loki /var/lib/loki /var/log/loki /etc/loki
    chmod -R 750 /var/lib/loki
    chmod -R 755 /var/log/loki
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

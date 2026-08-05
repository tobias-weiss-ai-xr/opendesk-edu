# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# sogo NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # sogo service
  services.sogo = {
    enable = true;
    # package = pkgs.opendeskPackages.sogo;
    port = 8080;
  };

  # System user
  users.users.sogo = {
    isSystemUser = true;
    uid = 1000;
    group = "sogo";
    home = "/var/lib/sogo";
    shell = pkgs.bash;
    description = "sogo Service User";
  };

  users.groups.sogo = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupsogo = lib.mkAfter ''
    mkdir -p /var/lib/sogo /var/log/sogo /etc/sogo
    chown -R sogo:sogo /var/lib/sogo /var/log/sogo /etc/sogo
    chmod -R 750 /var/lib/sogo
    chmod -R 755 /var/log/sogo
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

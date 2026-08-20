# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# bookstack NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # bookstack service
  services.bookstack = {
    enable = true;
    # package = pkgs.opendeskPackages.bookstack;
    port = 8080;
  };

  # System user
  users.users.bookstack = {
    isSystemUser = true;
    uid = 1000;
    group = "bookstack";
    home = "/var/lib/bookstack";
    shell = pkgs.bash;
    description = "bookstack Service User";
  };

  users.groups.bookstack = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupbookstack = lib.mkAfter ''
    mkdir -p /var/lib/bookstack /var/log/bookstack /etc/bookstack
    chown -R bookstack:bookstack /var/lib/bookstack /var/log/bookstack /etc/bookstack
    chmod -R 750 /var/lib/bookstack
    chmod -R 755 /var/log/bookstack
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

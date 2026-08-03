# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# openproject NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # openproject service
  services.openproject = {
    enable = true;
    # package = pkgs.opendeskPackages.openproject;
    port = 8080;
  };

  # System user
  users.users.openproject = {
    isSystemUser = true;
    uid = 1000;
    group = "openproject";
    home = "/var/lib/openproject";
    shell = pkgs.bash;
    description = "openproject Service User";
  };

  users.groups.openproject = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupopenproject = lib.mkAfter ''
    mkdir -p /var/lib/openproject /var/log/openproject /etc/openproject
    chown -R openproject:openproject /var/lib/openproject /var/log/openproject /etc/openproject
    chmod -R 750 /var/lib/openproject
    chmod -R 755 /var/log/openproject
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

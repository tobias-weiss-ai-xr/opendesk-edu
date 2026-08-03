# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
intercom-service NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # intercom-service service
  services.intercom-service = {
    enable = true;
    # package = pkgs.opendeskPackages.intercom-service;
    port = 8080;
  };

  # System user
  users.users.intercom-service = {
    isSystemUser = true;
    uid = 1000;
    group = "intercom-service";
    home = "/var/lib/intercom-service";
    shell = pkgs.bash;
    description = "intercom-service Service User";
  };

  users.groups.intercom-service = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupintercom-service = lib.mkAfter ''
    mkdir -p /var/lib/intercom-service /var/log/intercom-service /etc/intercom-service
    chown -R intercom-service:intercom-service /var/lib/intercom-service /var/log/intercom-service /etc/intercom-service
    chmod -R 750 /var/lib/intercom-service
    chmod -R 755 /var/log/intercom-service
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

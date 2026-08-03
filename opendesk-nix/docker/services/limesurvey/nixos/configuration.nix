# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
limesurvey NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # limesurvey service
  services.limesurvey = {
    enable = true;
    # package = pkgs.opendeskPackages.limesurvey;
    port = 8080;
  };

  # System user
  users.users.limesurvey = {
    isSystemUser = true;
    uid = 1000;
    group = "limesurvey";
    home = "/var/lib/limesurvey";
    shell = pkgs.bash;
    description = "limesurvey Service User";
  };

  users.groups.limesurvey = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setuplimesurvey = lib.mkAfter ''
    mkdir -p /var/lib/limesurvey /var/log/limesurvey /etc/limesurvey
    chown -R limesurvey:limesurvey /var/lib/limesurvey /var/log/limesurvey /etc/limesurvey
    chmod -R 750 /var/lib/limesurvey
    chmod -R 755 /var/log/limesurvey
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

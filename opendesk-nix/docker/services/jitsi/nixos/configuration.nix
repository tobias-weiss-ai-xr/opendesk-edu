# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# jitsi NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # jitsi service
  services.jitsi = {
    enable = true;
    # package = pkgs.opendeskPackages.jitsi;
    port = 8080;
  };

  # System user
  users.users.jitsi = {
    isSystemUser = true;
    uid = 1000;
    group = "jitsi";
    home = "/var/lib/jitsi";
    shell = pkgs.bash;
    description = "jitsi Service User";
  };

  users.groups.jitsi = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupjitsi = lib.mkAfter ''
    mkdir -p /var/lib/jitsi /var/log/jitsi /etc/jitsi
    chown -R jitsi:jitsi /var/lib/jitsi /var/log/jitsi /etc/jitsi
    chmod -R 750 /var/lib/jitsi
    chmod -R 755 /var/log/jitsi
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

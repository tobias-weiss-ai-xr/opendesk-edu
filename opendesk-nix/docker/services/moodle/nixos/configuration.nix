# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# moodle NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # moodle service
  services.moodle = {
    enable = true;
    # package = pkgs.opendeskPackages.moodle;
    port = 8080;
  };

  # System user
  users.users.moodle = {
    isSystemUser = true;
    uid = 1000;
    group = "moodle";
    home = "/var/lib/moodle";
    shell = pkgs.bash;
    description = "moodle Service User";
  };

  users.groups.moodle = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupmoodle = lib.mkAfter ''
    mkdir -p /var/lib/moodle /var/log/moodle /etc/moodle
    chown -R moodle:moodle /var/lib/moodle /var/log/moodle /etc/moodle
    chmod -R 750 /var/lib/moodle
    chmod -R 755 /var/log/moodle
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# bigbluebutton NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # bigbluebutton service
  services.bigbluebutton = {
    enable = true;
    # package = pkgs.opendeskPackages.bigbluebutton;
    port = 8080;
  };

  # System user
  users.users.bigbluebutton = {
    isSystemUser = true;
    uid = 1000;
    group = "bigbluebutton";
    home = "/var/lib/bigbluebutton";
    shell = pkgs.bash;
    description = "bigbluebutton Service User";
  };

  users.groups.bigbluebutton = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupbigbluebutton = lib.mkAfter ''
    mkdir -p /var/lib/bigbluebutton /var/log/bigbluebutton /etc/bigbluebutton
    chown -R bigbluebutton:bigbluebutton /var/lib/bigbluebutton /var/log/bigbluebutton /etc/bigbluebutton
    chmod -R 750 /var/lib/bigbluebutton
    chmod -R 755 /var/log/bigbluebutton
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

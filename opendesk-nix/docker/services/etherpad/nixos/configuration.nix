# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# etherpad NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # etherpad service
  services.etherpad = {
    enable = true;
    # package = pkgs.opendeskPackages.etherpad;
    port = 8080;
  };

  # System user
  users.users.etherpad = {
    isSystemUser = true;
    uid = 1000;
    group = "etherpad";
    home = "/var/lib/etherpad";
    shell = pkgs.bash;
    description = "etherpad Service User";
  };

  users.groups.etherpad = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupetherpad = lib.mkAfter ''
    mkdir -p /var/lib/etherpad /var/log/etherpad /etc/etherpad
    chown -R etherpad:etherpad /var/lib/etherpad /var/log/etherpad /etc/etherpad
    chmod -R 750 /var/lib/etherpad
    chmod -R 755 /var/log/etherpad
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

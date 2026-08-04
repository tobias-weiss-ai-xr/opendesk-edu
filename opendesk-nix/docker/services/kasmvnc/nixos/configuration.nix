# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# kasmvnc NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # kasmvnc service
  services.kasmvnc = {
    enable = true;
    # package = pkgs.opendeskPackages.kasmvnc;
    port = 8080;
  };

  # System user
  users.users.kasmvnc = {
    isSystemUser = true;
    uid = 1000;
    group = "kasmvnc";
    home = "/var/lib/kasmvnc";
    shell = pkgs.bash;
    description = "kasmvnc Service User";
  };

  users.groups.kasmvnc = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupkasmvnc = lib.mkAfter ''
    mkdir -p /var/lib/kasmvnc /var/log/kasmvnc /etc/kasmvnc
    chown -R kasmvnc:kasmvnc /var/lib/kasmvnc /var/log/kasmvnc /etc/kasmvnc
    chmod -R 750 /var/lib/kasmvnc
    chmod -R 755 /var/log/kasmvnc
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

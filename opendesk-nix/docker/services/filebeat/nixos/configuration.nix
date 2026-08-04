# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# filebeat NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # filebeat service
  services.filebeat = {
    enable = true;
    # package = pkgs.opendeskPackages.filebeat;
    port = 8080;
  };

  # System user
  users.users.filebeat = {
    isSystemUser = true;
    uid = 1000;
    group = "filebeat";
    home = "/var/lib/filebeat";
    shell = pkgs.bash;
    description = "filebeat Service User";
  };

  users.groups.filebeat = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupfilebeat = lib.mkAfter ''
    mkdir -p /var/lib/filebeat /var/log/filebeat /etc/filebeat
    chown -R filebeat:filebeat /var/lib/filebeat /var/log/filebeat /etc/filebeat
    chmod -R 750 /var/lib/filebeat
    chmod -R 755 /var/log/filebeat
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

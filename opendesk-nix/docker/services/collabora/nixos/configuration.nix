# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# collabora NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # collabora service
  services.collabora = {
    enable = true;
    # package = pkgs.opendeskPackages.collabora;
    port = 8080;
  };

  # System user
  users.users.collabora = {
    isSystemUser = true;
    uid = 1000;
    group = "collabora";
    home = "/var/lib/collabora";
    shell = pkgs.bash;
    description = "collabora Service User";
  };

  users.groups.collabora = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupcollabora = lib.mkAfter ''
    mkdir -p /var/lib/collabora /var/log/collabora /etc/collabora
    chown -R collabora:collabora /var/lib/collabora /var/log/collabora /etc/collabora
    chmod -R 750 /var/lib/collabora
    chmod -R 755 /var/log/collabora
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

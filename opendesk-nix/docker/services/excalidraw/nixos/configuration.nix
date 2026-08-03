# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# excalidraw NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # excalidraw service
  services.excalidraw = {
    enable = true;
    # package = pkgs.opendeskPackages.excalidraw;
    port = 8080;
  };

  # System user
  users.users.excalidraw = {
    isSystemUser = true;
    uid = 1000;
    group = "excalidraw";
    home = "/var/lib/excalidraw";
    shell = pkgs.bash;
    description = "excalidraw Service User";
  };

  users.groups.excalidraw = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupexcalidraw = lib.mkAfter ''
    mkdir -p /var/lib/excalidraw /var/log/excalidraw /etc/excalidraw
    chown -R excalidraw:excalidraw /var/lib/excalidraw /var/log/excalidraw /etc/excalidraw
    chmod -R 750 /var/lib/excalidraw
    chmod -R 755 /var/log/excalidraw
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

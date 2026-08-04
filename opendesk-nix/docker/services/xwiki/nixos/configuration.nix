# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# xwiki NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # xwiki service
  services.xwiki = {
    enable = true;
    # package = pkgs.opendeskPackages.xwiki;
    port = 8080;
  };

  # System user
  users.users.xwiki = {
    isSystemUser = true;
    uid = 1000;
    group = "xwiki";
    home = "/var/lib/xwiki";
    shell = pkgs.bash;
    description = "xwiki Service User";
  };

  users.groups.xwiki = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupxwiki = lib.mkAfter ''
    mkdir -p /var/lib/xwiki /var/log/xwiki /etc/xwiki
    chown -R xwiki:xwiki /var/lib/xwiki /var/log/xwiki /etc/xwiki
    chmod -R 750 /var/lib/xwiki
    chmod -R 755 /var/log/xwiki
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

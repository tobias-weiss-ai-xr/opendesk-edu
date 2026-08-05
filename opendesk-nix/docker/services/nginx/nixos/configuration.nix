# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# nginx NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # nginx service
  services.nginx = {
    enable = true;
    # package = pkgs.opendeskPackages.nginx;
    port = 80;
  };

  # System user
  users.users.nginx = {
    isSystemUser = true;
    uid = 1000;
    group = "nginx";
    home = "/var/lib/nginx";
    shell = pkgs.bash;
    description = "nginx Service User";
  };

  users.groups.nginx = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupnginx = lib.mkAfter ''
    mkdir -p /var/lib/nginx /var/log/nginx /etc/nginx
    chown -R nginx:nginx /var/lib/nginx /var/log/nginx /etc/nginx
    chmod -R 750 /var/lib/nginx
    chmod -R 755 /var/log/nginx
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

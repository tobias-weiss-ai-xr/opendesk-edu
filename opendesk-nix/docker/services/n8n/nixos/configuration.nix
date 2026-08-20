# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# n8n NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # n8n service
  services.n8n = {
    enable = true;
    # package = pkgs.opendeskPackages.n8n;
    port = 8080;
  };

  # System user
  users.users.n8n = {
    isSystemUser = true;
    uid = 1000;
    group = "n8n";
    home = "/var/lib/n8n";
    shell = pkgs.bash;
    description = "n8n Service User";
  };

  users.groups.n8n = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupn8n = lib.mkAfter ''
    mkdir -p /var/lib/n8n /var/log/n8n /etc/n8n
    chown -R n8n:n8n /var/lib/n8n /var/log/n8n /etc/n8n
    chmod -R 750 /var/lib/n8n
    chmod -R 755 /var/log/n8n
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

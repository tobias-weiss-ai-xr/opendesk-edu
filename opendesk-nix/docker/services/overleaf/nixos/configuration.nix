# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# overleaf NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # overleaf service
  services.overleaf = {
    enable = true;
    # package = pkgs.opendeskPackages.overleaf;
    port = 8080;
  };

  # System user
  users.users.overleaf = {
    isSystemUser = true;
    uid = 1000;
    group = "overleaf";
    home = "/var/lib/overleaf";
    shell = pkgs.bash;
    description = "overleaf Service User";
  };

  users.groups.overleaf = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupoverleaf = lib.mkAfter ''
    mkdir -p /var/lib/overleaf /var/log/overleaf /etc/overleaf
    chown -R overleaf:overleaf /var/lib/overleaf /var/log/overleaf /etc/overleaf
    chmod -R 750 /var/lib/overleaf
    chmod -R 755 /var/log/overleaf
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

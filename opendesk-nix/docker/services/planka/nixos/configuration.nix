# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# planka NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # planka service
  services.planka = {
    enable = true;
    # package = pkgs.opendeskPackages.planka;
    port = 8080;
  };

  # System user
  users.users.planka = {
    isSystemUser = true;
    uid = 1000;
    group = "planka";
    home = "/var/lib/planka";
    shell = pkgs.bash;
    description = "planka Service User";
  };

  users.groups.planka = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupplanka = lib.mkAfter ''
    mkdir -p /var/lib/planka /var/log/planka /etc/planka
    chown -R planka:planka /var/lib/planka /var/log/planka /etc/planka
    chmod -R 750 /var/lib/planka
    chmod -R 755 /var/log/planka
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

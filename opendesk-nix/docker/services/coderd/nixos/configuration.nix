# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# coderd NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # coderd service
  services.coderd = {
    enable = true;
    # package = pkgs.opendeskPackages.coderd;
    port = 8080;
  };

  # System user
  users.users.coderd = {
    isSystemUser = true;
    uid = 1000;
    group = "coderd";
    home = "/var/lib/coderd";
    shell = pkgs.bash;
    description = "coderd Service User";
  };

  users.groups.coderd = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupcoderd = lib.mkAfter ''
    mkdir -p /var/lib/coderd /var/log/coderd /etc/coderd
    chown -R coderd:coderd /var/lib/coderd /var/log/coderd /etc/coderd
    chmod -R 750 /var/lib/coderd
    chmod -R 755 /var/log/coderd
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

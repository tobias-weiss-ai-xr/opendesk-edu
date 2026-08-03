# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# seaweedfs NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # seaweedfs service
  services.seaweedfs = {
    enable = true;
    # package = pkgs.opendeskPackages.seaweedfs;
    port = 8080;
  };

  # System user
  users.users.seaweedfs = {
    isSystemUser = true;
    uid = 1000;
    group = "seaweedfs";
    home = "/var/lib/seaweedfs";
    shell = pkgs.bash;
    description = "seaweedfs Service User";
  };

  users.groups.seaweedfs = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupseaweedfs = lib.mkAfter ''
    mkdir -p /var/lib/seaweedfs /var/log/seaweedfs /etc/seaweedfs
    chown -R seaweedfs:seaweedfs /var/lib/seaweedfs /var/log/seaweedfs /etc/seaweedfs
    chmod -R 750 /var/lib/seaweedfs
    chmod -R 755 /var/log/seaweedfs
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# typo3 NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # typo3 service
  services.typo3 = {
    enable = true;
    # package = pkgs.opendeskPackages.typo3;
    port = 8080;
  };

  # System user
  users.users.typo3 = {
    isSystemUser = true;
    uid = 1000;
    group = "typo3";
    home = "/var/lib/typo3";
    shell = pkgs.bash;
    description = "typo3 Service User";
  };

  users.groups.typo3 = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setuptypo3 = lib.mkAfter ''
    mkdir -p /var/lib/typo3 /var/log/typo3 /etc/typo3
    chown -R typo3:typo3 /var/lib/typo3 /var/log/typo3 /etc/typo3
    chmod -R 750 /var/lib/typo3
    chmod -R 755 /var/log/typo3
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

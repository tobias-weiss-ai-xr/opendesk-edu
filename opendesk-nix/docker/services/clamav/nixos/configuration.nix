# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# clamav NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # clamav service
  services.clamav = {
    enable = true;
    # package = pkgs.opendeskPackages.clamav;
    port = 8080;
  };

  # System user
  users.users.clamav = {
    isSystemUser = true;
    uid = 1000;
    group = "clamav";
    home = "/var/lib/clamav";
    shell = pkgs.bash;
    description = "clamav Service User";
  };

  users.groups.clamav = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupclamav = lib.mkAfter ''
    mkdir -p /var/lib/clamav /var/log/clamav /etc/clamav
    chown -R clamav:clamav /var/lib/clamav /var/log/clamav /etc/clamav
    chmod -R 750 /var/lib/clamav
    chmod -R 755 /var/log/clamav
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

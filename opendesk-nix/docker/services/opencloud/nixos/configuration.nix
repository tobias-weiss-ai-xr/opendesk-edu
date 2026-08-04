# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# opencloud NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # opencloud service
  services.opencloud = {
    enable = true;
    # package = pkgs.opendeskPackages.opencloud;
    port = 8080;
  };

  # System user
  users.users.opencloud = {
    isSystemUser = true;
    uid = 1000;
    group = "opencloud";
    home = "/var/lib/opencloud";
    shell = pkgs.bash;
    description = "opencloud Service User";
  };

  users.groups.opencloud = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupopencloud = lib.mkAfter ''
    mkdir -p /var/lib/opencloud /var/log/opencloud /etc/opencloud
    chown -R opencloud:opencloud /var/lib/opencloud /var/log/opencloud /etc/opencloud
    chmod -R 750 /var/lib/opencloud
    chmod -R 755 /var/log/opencloud
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

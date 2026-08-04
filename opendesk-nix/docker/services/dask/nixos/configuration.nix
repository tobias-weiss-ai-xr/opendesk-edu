# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# dask NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # dask service
  services.dask = {
    enable = true;
    # package = pkgs.opendeskPackages.dask;
    port = 8080;
  };

  # System user
  users.users.dask = {
    isSystemUser = true;
    uid = 1000;
    group = "dask";
    home = "/var/lib/dask";
    shell = pkgs.bash;
    description = "dask Service User";
  };

  users.groups.dask = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupdask = lib.mkAfter ''
    mkdir -p /var/lib/dask /var/log/dask /etc/dask
    chown -R dask:dask /var/lib/dask /var/log/dask /etc/dask
    chmod -R 750 /var/lib/dask
    chmod -R 755 /var/log/dask
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

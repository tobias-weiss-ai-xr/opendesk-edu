# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# redis NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # redis service
  services.redis = {
    enable = true;
    # package = pkgs.opendeskPackages.redis;
    port = 6379;
  };

  # System user
  users.users.redis = {
    isSystemUser = true;
    uid = 1000;
    group = "redis";
    home = "/var/lib/redis";
    shell = pkgs.bash;
    description = "redis Service User";
  };

  users.groups.redis = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupredis = lib.mkAfter ''
    mkdir -p /var/lib/redis /var/log/redis /etc/redis
    chown -R redis:redis /var/lib/redis /var/log/redis /etc/redis
    chmod -R 750 /var/lib/redis
    chmod -R 755 /var/log/redis
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

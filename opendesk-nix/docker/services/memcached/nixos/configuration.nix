# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
memcached NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # memcached service
  services.memcached = {
    enable = true;
    # package = pkgs.opendeskPackages.memcached;
    port = 6379;
  };

  # System user
  users.users.memcached = {
    isSystemUser = true;
    uid = 1000;
    group = "memcached";
    home = "/var/lib/memcached";
    shell = pkgs.bash;
    description = "memcached Service User";
  };

  users.groups.memcached = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupmemcached = lib.mkAfter ''
    mkdir -p /var/lib/memcached /var/log/memcached /etc/memcached
    chown -R memcached:memcached /var/lib/memcached /var/log/memcached /etc/memcached
    chmod -R 750 /var/lib/memcached
    chmod -R 755 /var/log/memcached
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

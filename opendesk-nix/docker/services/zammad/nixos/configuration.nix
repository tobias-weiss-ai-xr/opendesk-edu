# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
zammad NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # zammad service
  services.zammad = {
    enable = true;
    # package = pkgs.opendeskPackages.zammad;
    port = 8080;
  };

  # System user
  users.users.zammad = {
    isSystemUser = true;
    uid = 1000;
    group = "zammad";
    home = "/var/lib/zammad";
    shell = pkgs.bash;
    description = "zammad Service User";
  };

  users.groups.zammad = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupzammad = lib.mkAfter ''
    mkdir -p /var/lib/zammad /var/log/zammad /etc/zammad
    chown -R zammad:zammad /var/lib/zammad /var/log/zammad /etc/zammad
    chmod -R 750 /var/lib/zammad
    chmod -R 755 /var/log/zammad
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

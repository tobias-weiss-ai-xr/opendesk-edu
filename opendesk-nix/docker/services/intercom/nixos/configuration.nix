# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
intercom NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # intercom service
  services.intercom = {
    enable = true;
    # package = pkgs.opendeskPackages.intercom;
    port = 8080;
  };

  # System user
  users.users.intercom = {
    isSystemUser = true;
    uid = 1000;
    group = "intercom";
    home = "/var/lib/intercom";
    shell = pkgs.bash;
    description = "intercom Service User";
  };

  users.groups.intercom = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupintercom = lib.mkAfter ''
    mkdir -p /var/lib/intercom /var/log/intercom /etc/intercom
    chown -R intercom:intercom /var/lib/intercom /var/log/intercom /etc/intercom
    chmod -R 750 /var/lib/intercom
    chmod -R 755 /var/log/intercom
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
open-xchange NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # open-xchange service
  services.open-xchange = {
    enable = true;
    # package = pkgs.opendeskPackages.open-xchange;
    port = 8080;
  };

  # System user
  users.users.open-xchange = {
    isSystemUser = true;
    uid = 1000;
    group = "open-xchange";
    home = "/var/lib/open-xchange";
    shell = pkgs.bash;
    description = "open-xchange Service User";
  };

  users.groups.open-xchange = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupopen-xchange = lib.mkAfter ''
    mkdir -p /var/lib/open-xchange /var/log/open-xchange /etc/open-xchange
    chown -R open-xchange:open-xchange /var/lib/open-xchange /var/log/open-xchange /etc/open-xchange
    chmod -R 750 /var/lib/open-xchange
    chmod -R 755 /var/log/open-xchange
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

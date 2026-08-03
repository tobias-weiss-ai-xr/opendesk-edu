# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
nubus-udm NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # nubus-udm service
  services.nubus-udm = {
    enable = true;
    # package = pkgs.opendeskPackages.nubus-udm;
    port = 8080;
  };

  # System user
  users.users.nubus-udm = {
    isSystemUser = true;
    uid = 1000;
    group = "nubus-udm";
    home = "/var/lib/nubus-udm";
    shell = pkgs.bash;
    description = "nubus-udm Service User";
  };

  users.groups.nubus-udm = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupnubus-udm = lib.mkAfter ''
    mkdir -p /var/lib/nubus-udm /var/log/nubus-udm /etc/nubus-udm
    chown -R nubus-udm:nubus-udm /var/lib/nubus-udm /var/log/nubus-udm /etc/nubus-udm
    chmod -R 750 /var/lib/nubus-udm
    chmod -R 755 /var/log/nubus-udm
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

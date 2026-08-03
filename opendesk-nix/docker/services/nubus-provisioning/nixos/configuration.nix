# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
nubus-provisioning NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # nubus-provisioning service
  services.nubus-provisioning = {
    enable = true;
    # package = pkgs.opendeskPackages.nubus-provisioning;
    port = 8080;
  };

  # System user
  users.users.nubus-provisioning = {
    isSystemUser = true;
    uid = 1000;
    group = "nubus-provisioning";
    home = "/var/lib/nubus-provisioning";
    shell = pkgs.bash;
    description = "nubus-provisioning Service User";
  };

  users.groups.nubus-provisioning = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupnubus-provisioning = lib.mkAfter ''
    mkdir -p /var/lib/nubus-provisioning /var/log/nubus-provisioning /etc/nubus-provisioning
    chown -R nubus-provisioning:nubus-provisioning /var/lib/nubus-provisioning /var/log/nubus-provisioning /etc/nubus-provisioning
    chmod -R 750 /var/lib/nubus-provisioning
    chmod -R 755 /var/log/nubus-provisioning
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

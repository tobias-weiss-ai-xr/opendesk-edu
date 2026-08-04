# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# ilias NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # ilias service
  services.ilias = {
    enable = true;
    # package = pkgs.opendeskPackages.ilias;
    port = 8080;
  };

  # System user
  users.users.ilias = {
    isSystemUser = true;
    uid = 1000;
    group = "ilias";
    home = "/var/lib/ilias";
    shell = pkgs.bash;
    description = "ilias Service User";
  };

  users.groups.ilias = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupilias = lib.mkAfter ''
    mkdir -p /var/lib/ilias /var/log/ilias /etc/ilias
    chown -R ilias:ilias /var/lib/ilias /var/log/ilias /etc/ilias
    chmod -R 750 /var/lib/ilias
    chmod -R 755 /var/log/ilias
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

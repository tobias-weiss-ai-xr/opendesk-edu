# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
element NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # element service
  services.element = {
    enable = true;
    # package = pkgs.opendeskPackages.element;
    port = 8080;
  };

  # System user
  users.users.element = {
    isSystemUser = true;
    uid = 1000;
    group = "element";
    home = "/var/lib/element";
    shell = pkgs.bash;
    description = "element Service User";
  };

  users.groups.element = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupelement = lib.mkAfter ''
    mkdir -p /var/lib/element /var/log/element /etc/element
    chown -R element:element /var/lib/element /var/log/element /etc/element
    chmod -R 750 /var/lib/element
    chmod -R 755 /var/log/element
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

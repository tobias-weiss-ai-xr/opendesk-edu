# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
kibana NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # kibana service
  services.kibana = {
    enable = true;
    # package = pkgs.opendeskPackages.kibana;
    port = 8080;
  };

  # System user
  users.users.kibana = {
    isSystemUser = true;
    uid = 1000;
    group = "kibana";
    home = "/var/lib/kibana";
    shell = pkgs.bash;
    description = "kibana Service User";
  };

  users.groups.kibana = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupkibana = lib.mkAfter ''
    mkdir -p /var/lib/kibana /var/log/kibana /etc/kibana
    chown -R kibana:kibana /var/lib/kibana /var/log/kibana /etc/kibana
    chmod -R 750 /var/lib/kibana
    chmod -R 755 /var/log/kibana
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

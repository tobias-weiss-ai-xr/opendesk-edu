# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
jupyterhub NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # jupyterhub service
  services.jupyterhub = {
    enable = true;
    # package = pkgs.opendeskPackages.jupyterhub;
    port = 8080;
  };

  # System user
  users.users.jupyterhub = {
    isSystemUser = true;
    uid = 1000;
    group = "jupyterhub";
    home = "/var/lib/jupyterhub";
    shell = pkgs.bash;
    description = "jupyterhub Service User";
  };

  users.groups.jupyterhub = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupjupyterhub = lib.mkAfter ''
    mkdir -p /var/lib/jupyterhub /var/log/jupyterhub /etc/jupyterhub
    chown -R jupyterhub:jupyterhub /var/lib/jupyterhub /var/log/jupyterhub /etc/jupyterhub
    chmod -R 750 /var/lib/jupyterhub
    chmod -R 755 /var/log/jupyterhub
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

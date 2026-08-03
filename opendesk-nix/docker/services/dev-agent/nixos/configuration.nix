# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
dev-agent NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # dev-agent service
  services.dev-agent = {
    enable = true;
    # package = pkgs.opendeskPackages.dev-agent;
    port = 8080;
  };

  # System user
  users.users.dev-agent = {
    isSystemUser = true;
    uid = 1000;
    group = "dev-agent";
    home = "/var/lib/dev-agent";
    shell = pkgs.bash;
    description = "dev-agent Service User";
  };

  users.groups.dev-agent = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupdev-agent = lib.mkAfter ''
    mkdir -p /var/lib/dev-agent /var/log/dev-agent /etc/dev-agent
    chown -R dev-agent:dev-agent /var/lib/dev-agent /var/log/dev-agent /etc/dev-agent
    chmod -R 750 /var/lib/dev-agent
    chmod -R 755 /var/log/dev-agent
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

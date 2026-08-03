# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
code-server NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # code-server service
  services.code-server = {
    enable = true;
    # package = pkgs.opendeskPackages.code-server;
    port = 8080;
  };

  # System user
  users.users.code-server = {
    isSystemUser = true;
    uid = 1000;
    group = "code-server";
    home = "/var/lib/code-server";
    shell = pkgs.bash;
    description = "code-server Service User";
  };

  users.groups.code-server = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupcode-server = lib.mkAfter ''
    mkdir -p /var/lib/code-server /var/log/code-server /etc/code-server
    chown -R code-server:code-server /var/lib/code-server /var/log/code-server /etc/code-server
    chmod -R 750 /var/lib/code-server
    chmod -R 755 /var/log/code-server
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

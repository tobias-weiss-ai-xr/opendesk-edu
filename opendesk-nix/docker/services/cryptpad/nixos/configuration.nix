# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
cryptpad NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # cryptpad service
  services.cryptpad = {
    enable = true;
    # package = pkgs.opendeskPackages.cryptpad;
    port = 8080;
  };

  # System user
  users.users.cryptpad = {
    isSystemUser = true;
    uid = 1000;
    group = "cryptpad";
    home = "/var/lib/cryptpad";
    shell = pkgs.bash;
    description = "cryptpad Service User";
  };

  users.groups.cryptpad = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupcryptpad = lib.mkAfter ''
    mkdir -p /var/lib/cryptpad /var/log/cryptpad /etc/cryptpad
    chown -R cryptpad:cryptpad /var/lib/cryptpad /var/log/cryptpad /etc/cryptpad
    chmod -R 750 /var/lib/cryptpad
    chmod -R 755 /var/log/cryptpad
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# ilias-full NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # ilias-full service
  services.ilias-full = {
    enable = true;
    # package = pkgs.opendeskPackages.ilias-full;
    port = 8080;
  };

  # System user
  users.users.ilias-full = {
    isSystemUser = true;
    uid = 1000;
    group = "ilias-full";
    home = "/var/lib/ilias-full";
    shell = pkgs.bash;
    description = "ilias-full Service User";
  };

  users.groups.ilias-full = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupilias-full = lib.mkAfter ''
    mkdir -p /var/lib/ilias-full /var/log/ilias-full /etc/ilias-full
    chown -R ilias-full:ilias-full /var/lib/ilias-full /var/log/ilias-full /etc/ilias-full
    chmod -R 750 /var/lib/ilias-full
    chmod -R 755 /var/log/ilias-full
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

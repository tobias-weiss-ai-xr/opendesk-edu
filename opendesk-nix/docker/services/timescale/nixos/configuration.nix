# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# timescale NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # timescale service
  services.timescale = {
    enable = true;
    # package = pkgs.opendeskPackages.timescale;
    port = 8080;
  };

  # System user
  users.users.timescale = {
    isSystemUser = true;
    uid = 1000;
    group = "timescale";
    home = "/var/lib/timescale";
    shell = pkgs.bash;
    description = "timescale Service User";
  };

  users.groups.timescale = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setuptimescale = lib.mkAfter ''
    mkdir -p /var/lib/timescale /var/log/timescale /etc/timescale
    chown -R timescale:timescale /var/lib/timescale /var/log/timescale /etc/timescale
    chmod -R 750 /var/lib/timescale
    chmod -R 755 /var/log/timescale
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

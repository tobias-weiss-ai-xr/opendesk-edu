# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# promtail NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # promtail service
  services.promtail = {
    enable = true;
    # package = pkgs.opendeskPackages.promtail;
    port = 8080;
  };

  # System user
  users.users.promtail = {
    isSystemUser = true;
    uid = 1000;
    group = "promtail";
    home = "/var/lib/promtail";
    shell = pkgs.bash;
    description = "promtail Service User";
  };

  users.groups.promtail = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setuppromtail = lib.mkAfter ''
    mkdir -p /var/lib/promtail /var/log/promtail /etc/promtail
    chown -R promtail:promtail /var/lib/promtail /var/log/promtail /etc/promtail
    chmod -R 750 /var/lib/promtail
    chmod -R 755 /var/log/promtail
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# eudi-issuer NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # eudi-issuer service
  services.eudi-issuer = {
    enable = true;
    # package = pkgs.opendeskPackages.eudi-issuer;
    port = 8080;
  };

  # System user
  users.users.eudi-issuer = {
    isSystemUser = true;
    uid = 1000;
    group = "eudi-issuer";
    home = "/var/lib/eudi-issuer";
    shell = pkgs.bash;
    description = "eudi-issuer Service User";
  };

  users.groups.eudi-issuer = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupeudi-issuer = lib.mkAfter ''
    mkdir -p /var/lib/eudi-issuer /var/log/eudi-issuer /etc/eudi-issuer
    chown -R eudi-issuer:eudi-issuer /var/lib/eudi-issuer /var/log/eudi-issuer /etc/eudi-issuer
    chmod -R 750 /var/lib/eudi-issuer
    chmod -R 755 /var/log/eudi-issuer
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# ttyd NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # ttyd service
  services.ttyd = {
    enable = true;
    # package = pkgs.opendeskPackages.ttyd;
    port = 8080;
  };

  # System user
  users.users.ttyd = {
    isSystemUser = true;
    uid = 1000;
    group = "ttyd";
    home = "/var/lib/ttyd";
    shell = pkgs.bash;
    description = "ttyd Service User";
  };

  users.groups.ttyd = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupttyd = lib.mkAfter ''
    mkdir -p /var/lib/ttyd /var/log/ttyd /etc/ttyd
    chown -R ttyd:ttyd /var/lib/ttyd /var/log/ttyd /etc/ttyd
    chmod -R 750 /var/lib/ttyd
    chmod -R 755 /var/log/ttyd
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

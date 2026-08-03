# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# notes NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # notes service
  services.notes = {
    enable = true;
    # package = pkgs.opendeskPackages.notes;
    port = 8080;
  };

  # System user
  users.users.notes = {
    isSystemUser = true;
    uid = 1000;
    group = "notes";
    home = "/var/lib/notes";
    shell = pkgs.bash;
    description = "notes Service User";
  };

  users.groups.notes = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupnotes = lib.mkAfter ''
    mkdir -p /var/lib/notes /var/log/notes /etc/notes
    chown -R notes:notes /var/lib/notes /var/log/notes /etc/notes
    chmod -R 750 /var/lib/notes
    chmod -R 755 /var/log/notes
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

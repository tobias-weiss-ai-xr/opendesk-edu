# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# dovecot NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # dovecot service
  services.dovecot = {
    enable = true;
    # package = pkgs.opendeskPackages.dovecot;
    port = 8080;
  };

  # System user
  users.users.dovecot = {
    isSystemUser = true;
    uid = 1000;
    group = "dovecot";
    home = "/var/lib/dovecot";
    shell = pkgs.bash;
    description = "dovecot Service User";
  };

  users.groups.dovecot = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupdovecot = lib.mkAfter ''
    mkdir -p /var/lib/dovecot /var/log/dovecot /etc/dovecot
    chown -R dovecot:dovecot /var/lib/dovecot /var/log/dovecot /etc/dovecot
    chmod -R 750 /var/lib/dovecot
    chmod -R 755 /var/log/dovecot
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# minio NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # minio service
  services.minio = {
    enable = true;
    # package = pkgs.opendeskPackages.minio;
    port = 8080;
  };

  # System user
  users.users.minio = {
    isSystemUser = true;
    uid = 1000;
    group = "minio";
    home = "/var/lib/minio";
    shell = pkgs.bash;
    description = "minio Service User";
  };

  users.groups.minio = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupminio = lib.mkAfter ''
    mkdir -p /var/lib/minio /var/log/minio /etc/minio
    chown -R minio:minio /var/lib/minio /var/log/minio /etc/minio
    chmod -R 750 /var/lib/minio
    chmod -R 755 /var/log/minio
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

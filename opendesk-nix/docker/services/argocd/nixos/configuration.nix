# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# argocd NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # argocd service
  services.argocd = {
    enable = true;
    # package = pkgs.opendeskPackages.argocd;
    port = 8080;
  };

  # System user
  users.users.argocd = {
    isSystemUser = true;
    uid = 1000;
    group = "argocd";
    home = "/var/lib/argocd";
    shell = pkgs.bash;
    description = "argocd Service User";
  };

  users.groups.argocd = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupargocd = lib.mkAfter ''
    mkdir -p /var/lib/argocd /var/log/argocd /etc/argocd
    chown -R argocd:argocd /var/lib/argocd /var/log/argocd /etc/argocd
    chmod -R 750 /var/lib/argocd
    chmod -R 755 /var/log/argocd
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

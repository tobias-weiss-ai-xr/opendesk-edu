# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# kube-prometheus-stack NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # kube-prometheus-stack service
  services.kube-prometheus-stack = {
    enable = true;
    # package = pkgs.opendeskPackages.kube-prometheus-stack;
    port = 8080;
  };

  # System user
  users.users.kube-prometheus-stack = {
    isSystemUser = true;
    uid = 1000;
    group = "kube-prometheus-stack";
    home = "/var/lib/kube-prometheus-stack";
    shell = pkgs.bash;
    description = "kube-prometheus-stack Service User";
  };

  users.groups.kube-prometheus-stack = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupkube-prometheus-stack = lib.mkAfter ''
    mkdir -p /var/lib/kube-prometheus-stack /var/log/kube-prometheus-stack /etc/kube-prometheus-stack
    chown -R kube-prometheus-stack:kube-prometheus-stack /var/lib/kube-prometheus-stack /var/log/kube-prometheus-stack /etc/kube-prometheus-stack
    chmod -R 750 /var/lib/kube-prometheus-stack
    chmod -R 755 /var/log/kube-prometheus-stack
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

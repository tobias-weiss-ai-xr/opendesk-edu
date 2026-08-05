# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# zot-registry NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # zot-registry service
  services.zot-registry = {
    enable = true;
    # package = pkgs.opendeskPackages.zot-registry;
    port = 8080;
  };

  # System user
  users.users.zot-registry = {
    isSystemUser = true;
    uid = 1000;
    group = "zot-registry";
    home = "/var/lib/zot-registry";
    shell = pkgs.bash;
    description = "zot-registry Service User";
  };

  users.groups.zot-registry = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupzot-registry = lib.mkAfter ''
    mkdir -p /var/lib/zot-registry /var/log/zot-registry /etc/zot-registry
    chown -R zot-registry:zot-registry /var/lib/zot-registry /var/log/zot-registry /etc/zot-registry
    chmod -R 750 /var/lib/zot-registry
    chmod -R 755 /var/log/zot-registry
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

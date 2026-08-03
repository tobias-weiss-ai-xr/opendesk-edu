# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# open-webui NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # open-webui service
  services.open-webui = {
    enable = true;
    # package = pkgs.opendeskPackages.open-webui;
    port = 8080;
  };

  # System user
  users.users.open-webui = {
    isSystemUser = true;
    uid = 1000;
    group = "open-webui";
    home = "/var/lib/open-webui";
    shell = pkgs.bash;
    description = "open-webui Service User";
  };

  users.groups.open-webui = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupopen-webui = lib.mkAfter ''
    mkdir -p /var/lib/open-webui /var/log/open-webui /etc/open-webui
    chown -R open-webui:open-webui /var/lib/open-webui /var/log/open-webui /etc/open-webui
    chmod -R 750 /var/lib/open-webui
    chmod -R 755 /var/log/open-webui
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

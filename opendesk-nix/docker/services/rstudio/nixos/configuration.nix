# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# rstudio NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # rstudio service
  services.rstudio = {
    enable = true;
    # package = pkgs.opendeskPackages.rstudio;
    port = 8080;
  };

  # System user
  users.users.rstudio = {
    isSystemUser = true;
    uid = 1000;
    group = "rstudio";
    home = "/var/lib/rstudio";
    shell = pkgs.bash;
    description = "rstudio Service User";
  };

  users.groups.rstudio = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setuprstudio = lib.mkAfter ''
    mkdir -p /var/lib/rstudio /var/log/rstudio /etc/rstudio
    chown -R rstudio:rstudio /var/lib/rstudio /var/log/rstudio /etc/rstudio
    chmod -R 750 /var/lib/rstudio
    chmod -R 755 /var/log/rstudio
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

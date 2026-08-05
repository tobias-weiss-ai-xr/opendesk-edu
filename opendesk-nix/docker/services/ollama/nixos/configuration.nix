# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# ollama NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # ollama service
  services.ollama = {
    enable = true;
    # package = pkgs.opendeskPackages.ollama;
    port = 8080;
  };

  # System user
  users.users.ollama = {
    isSystemUser = true;
    uid = 1000;
    group = "ollama";
    home = "/var/lib/ollama";
    shell = pkgs.bash;
    description = "ollama Service User";
  };

  users.groups.ollama = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupollama = lib.mkAfter ''
    mkdir -p /var/lib/ollama /var/log/ollama /etc/ollama
    chown -R ollama:ollama /var/lib/ollama /var/log/ollama /etc/ollama
    chmod -R 750 /var/lib/ollama
    chmod -R 755 /var/log/ollama
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

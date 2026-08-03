# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
elasticsearch NixOS Configuration for openDesk
Version: latest
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # elasticsearch service
  services.elasticsearch = {
    enable = true;
    # package = pkgs.opendeskPackages.elasticsearch;
    port = 8080;
  };

  # System user
  users.users.elasticsearch = {
    isSystemUser = true;
    uid = 1000;
    group = "elasticsearch";
    home = "/var/lib/elasticsearch";
    shell = pkgs.bash;
    description = "elasticsearch Service User";
  };

  users.groups.elasticsearch = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupelasticsearch = lib.mkAfter ''
    mkdir -p /var/lib/elasticsearch /var/log/elasticsearch /etc/elasticsearch
    chown -R elasticsearch:elasticsearch /var/lib/elasticsearch /var/log/elasticsearch /etc/elasticsearch
    chmod -R 750 /var/lib/elasticsearch
    chmod -R 755 /var/log/elasticsearch
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

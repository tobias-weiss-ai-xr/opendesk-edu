# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# semester-provisioning NixOS Configuration for openDesk
# Version: latest
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config ? {}, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../overlays/opendesk.nix) ];

  # semester-provisioning service
  services.semester-provisioning = {
    enable = true;
    # package = pkgs.opendeskPackages.semester-provisioning;
    port = 8080;
  };

  # System user
  users.users.semester-provisioning = {
    isSystemUser = true;
    uid = 1000;
    group = "semester-provisioning";
    home = "/var/lib/semester-provisioning";
    shell = pkgs.bash;
    description = "semester-provisioning Service User";
  };

  users.groups.semester-provisioning = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupsemester-provisioning = lib.mkAfter ''
    mkdir -p /var/lib/semester-provisioning /var/log/semester-provisioning /etc/semester-provisioning
    chown -R semester-provisioning:semester-provisioning /var/lib/semester-provisioning /var/log/semester-provisioning /etc/semester-provisioning
    chmod -R 750 /var/lib/semester-provisioning
    chmod -R 755 /var/log/semester-provisioning
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

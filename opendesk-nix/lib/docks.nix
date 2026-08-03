# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# docks.nix compatibility layer for openDesk
# Provides mkImage function for building Docker/OCI containers

{ pkgs, lib ? pkgs.lib, ... }:

let
  dockerTools = pkgs.dockerTools;

  # Helper to merge attribute sets with defaults
  defaults = attrs: default: 
    if attrs ? name then attrs else attrs // default;

  # mkImage creates a Docker image
  mkImage = {
    name ? "opendesk-container",
    tag ? "latest",
    config ? {},          # NixOS configuration (optional, for future use)
    containerConfig ? {},
    extraPackages ? (_: []),
    ociLabels ? {},
    ...
  }:
    
    dockerTools.buildImage {
      inherit name tag;
      
      # Base: no fromImage, contents will create the image
      
      # Contents: base packages + extra
      contents = with pkgs; (
        [ bash coreutils findutils gnugrep gnused procps ]
        ++ (extraPackages pkgs // [])
      );
      
      # Container configuration - merge with defaults
      config = {
        Cmd = containerConfig.Cmd // 
          [ "/usr/bin/env" "bash" "-c" "echo Service ready" ];
        Env = containerConfig.Env // 
          [ "TZ=Europe/Berlin" "LC_ALL=C.UTF-8" "LANG=C.UTF-8" ];
        User = containerConfig.User // "nobody";
        WorkingDir = containerConfig.WorkingDir // "/";
        ExposedPorts = containerConfig.ExposedPorts // {};
        Volumes = containerConfig.Volumes // {};
        HealthCheck = containerConfig.HealthCheck // null;
        StopSignal = containerConfig.StopSignal // "SIGTERM";
        StopTimeout = if containerConfig ? StopTimeout 
          then lib.toString containerConfig.StopTimeout 
          else "30";
        Labels = ociLabels // {};
      };
    };

in {
  inherit mkImage;
}

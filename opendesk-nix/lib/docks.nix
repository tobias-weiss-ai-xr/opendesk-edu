# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# Minimal docks.nix compatibility layer
# Provides mkImage function for building Docker/OCI images

{ pkgs, ... }:

let
  lib = pkgs.lib;
  dockerTools = pkgs.dockerTools;

  # Helper to get attribute with default
  getAttrWithDefault = attr: default: config:
    if config ? ${attr} then config.${attr} else default;

  mkImage = { 
    name ? "opendesk-image",
    tag ? "latest",
    config ? {}, 
    containerConfig ? {},
    extraPackages ? (_: []),
    ociLabels ? {}, 
    ... 
  }:
    
    let
      cmd = getAttrWithDefault "Cmd" [ "/usr/bin/env" "bash" "-c" "echo Container ready" ] containerConfig;
      env = getAttrWithDefault "Env" [] containerConfig;
      user = getAttrWithDefault "User" "nobody" containerConfig;
      workingDir = getAttrWithDefault "WorkingDir" "/" containerConfig;
      exposedPorts = getAttrWithDefault "ExposedPorts" {} containerConfig;
      volumes = getAttrWithDefault "Volumes" {} containerConfig;
      healthCheck = getAttrWithDefault "HealthCheck" null containerConfig;
      stopSignal = getAttrWithDefault "StopSignal" "SIGTERM" containerConfig;
      stopTimeout = getAttrWithDefault "StopTimeout" 30 containerConfig;
    in
    
    dockerTools.buildImage {
      inherit name tag;
      fromImage = pkgs.dockerTools.emptyImage;
      contents = with pkgs; [ bash coreutils ] ++ extraPackages pkgs;
      
      config = {
        inherit cmd env user workingDir exposedPorts volumes healthCheck stopSignal;
        StopTimeout = lib.toString stopTimeout;
        Labels = ociLabels;
      };
    };

in {
  inherit mkImage;
}

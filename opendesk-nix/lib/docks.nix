# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# docks.nix — Docker/OCI image builder for openDesk services
# Provides mkImage: a wrapper around dockerTools.buildImage that handles
# user creation, volume directories, health checks, and OCI labels.

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

      # Determine if we need to create a custom user
      userName = if user == "nobody" || user == "root" || user == "" then null else user;

      # Volume paths from the Volumes attribute set
      volumePaths = builtins.attrNames volumes;

      # Build a proper root filesystem with symlinks at /bin, /usr/bin, etc.
      rootEnv = pkgs.buildEnv {
        name = "${name}-root";
        paths = with pkgs; [ bash coreutils ] ++ extraPackages pkgs;
        pathsToLink = [ "/bin" "/usr" "/etc" "/lib" "/share" "/sbin" ];
      };

      # runAsRoot script: create user/group and volume directories
      # Must be a string (script text), not a derivation
      runAsRootScript = ''
        #!${pkgs.runtimeShell}
        ${dockerTools.shadowSetup}
        # Create /usr/bin symlink to /bin for compatibility with images
        # that reference /usr/bin/env, /usr/bin/bash, etc.
        mkdir -p /usr
        ln -sf /bin /usr/bin
        ${lib.optionalString (userName != null) ''
          groupadd -r ${userName} 2>/dev/null || true
          useradd -r -g ${userName} -d /var/lib/${userName} -s /bin/sh ${userName} 2>/dev/null || true
          mkdir -p /var/lib/${userName}
          chown -R ${userName}:${userName} /var/lib/${userName}
        ''}
        ${lib.concatMapStrings (path: ''
          mkdir -p ${path}
          ${lib.optionalString (userName != null) "chown -R ${userName}:${userName} ${path}"}
        '') volumePaths}
      '';

    in
    dockerTools.buildImage {
      inherit name tag;
      runAsRoot = runAsRootScript;
      # Use copyToRoot with buildEnv for proper /bin, /usr/bin symlinks
      copyToRoot = rootEnv;
      config = {
        inherit cmd env user workingDir exposedPorts volumes healthCheck stopSignal;
        StopTimeout = stopTimeout;
        Labels = ociLabels;
      };
    };

in {
  inherit mkImage;
}

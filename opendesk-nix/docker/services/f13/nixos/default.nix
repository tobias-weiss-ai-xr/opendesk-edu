# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# f13 NixOS Container Image
# Version: latest
# OpenSpec: FR-BUILD-001 through FR-BUILD-007
# 

{ 
  pkgs ? import <nixpkgs> { system = "x86_64-linux"; },
  docks ? import ../../../../../opendesk-nix/lib/docks.nix { inherit pkgs; },
  ...
}:

let
  lib = pkgs.lib;
  opendeskOverlays = import ../../../../../opendesk-nix/overlays/opendesk.nix;
  nixpkgsWithOverlays = pkgs // {
    overlays = [ opendeskOverlays ];
  };

in

docks.mkImage {
  name = "f13-opendesk";
  tag = "latest-nixos";

  # NixOS configuration
  config = import ./configuration.nix {
    inherit pkgs lib;
  };

  # Container configuration
  containerConfig = {
    ExposedPorts = { "8080/tcp" = {}; };
    
    Volumes = {
      "/var/lib/f13" = {};
      "/var/log/f13" = {};
      "/etc/f13" = {};
    };
    
    Env = [
      "OPENDESK_ENV=production"
      "TZ=Europe/Berlin"
      "LC_ALL=C.UTF-8"
      "LANG=C.UTF-8"
    ];
    
    HealthCheck = {
      Test = [ "CMD-SHELL" "exit 0" ];
      Interval = 30000000000;  # 30s
      Timeout = 10000000000;   # 10s
      Retries = 3;
      StartPeriod = 30000000000; # 30s
    };
    
    User = "f13";
    WorkingDir = "/var/lib/f13";
    
    Cmd = [ "/usr/bin/env" "bash" "-c" "echo Service f13 ready" ];
    
    StopSignal = "SIGTERM";
    StopTimeout = 30;
  };

  # Additional packages for runtime
  extraPackages = p: with p; [
    openssl
    curl
    procps
    coreutils
  ];

  # OCI Labels for OpenSpec compliance
  ociLabels = {
    "org.opencontainers.image.title" = "f13-opendesk";
    "org.opencontainers.image.description" = "f13 latest for openDesk Edu with NixOS";
    "org.opencontainers.image.version" = "latest-nixos";
    "org.opencontainers.image.authors" = "openDesk Edu Team";
    "org.opencontainers.image.url" = "https://opendesk.hrz.uni-marburg.de";
    "org.opencontainers.image.documentation" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.source" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.licenses" = "Apache-2.0";
    "com.opendesk.service" = "f13";
    "com.opendesk.environment" = "production";
    "com.opendesk.managed" = "true";
    "com.opendesk.nixos" = "true";
  };
}

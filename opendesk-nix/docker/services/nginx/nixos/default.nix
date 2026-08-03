# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Nginx NixOS Container Image
Version: 1.25.3
OpenSpec: FR-BUILD-001 through FR-BUILD-007
"""

{ 
  pkgs ? import <nixpkgs> { system = "x86_64-linux"; },
  docks ? import (builtins.fetchGit {
    url = "https://github.com/dockernix/docks.nix";
    ref = "refs/tags/0.5.0";
  }) { inherit pkgs; },
  ...
}:

let
  lib = pkgs.lib;
  opendeskOverlays = import ../../../../../overlays/opendesk.nix;
  nixpkgsWithOverlays = pkgs // {
    overlays = [ opendeskOverlays ];
  };
  nginxPkg = nixpkgsWithOverlays.opendeskPackages.nginx;

in

docks.mkImage {
  name = "nginx-opendesk";
  tag = "1.25.3-nixos";

  # NixOS configuration
  config = import ./configuration.nix {
    inherit pkgs lib;
  };

  # Container configuration
  containerConfig = {
    ExposedPorts = {
      "80/tcp" = {};
      "443/tcp" = {};
    };
    
    Volumes = {
      "/var/lib/nginx" = {};
      "/var/log/nginx" = {};
      "/var/cache/nginx" = {};
      "/etc/nginx/ssl" = {};
      "/etc/nginx/conf.d" = {};
      "/var/www/static" = {};
    };
    
    Env = [
      "NGINX_PORT=80"
      "OPENDESK_ENV=production"
      "TZ=Europe/Berlin"
      "LC_ALL=C.UTF-8"
      "LANG=C.UTF-8"
    ];
    
    HealthCheck = {
      Test = [ "CMD-SHELL" "curl -f http://127.0.0.1/healthz 2>/dev/null || exit 1" ];
      Interval = 10000000000;  # 10s
      Timeout = 5000000000;   # 5s
      Retries = 3;
      StartPeriod = 10000000000; # 10s
    };
    
    User = "nginx";
    WorkingDir = "/var/lib/nginx";
    
    Cmd = [
      "${nginxPkg}/bin/nginx"
      "-g"
      "daemon off;"
    ];
    
    StopSignal = "SIGQUIT";
    StopTimeout = 30;
  };

  # Additional packages for runtime
  extraPackages = p: with p; [
    openssl
    curl
    procps
    lsof
    htop
    inotify-tools
    gnupg
    coreutils
    findutils
    grep
    sed
    awk
  ];

  # OCI Labels for OpenSpec compliance (FR-IMAGE-007)
  ociLabels = {
    "org.opencontainers.image.title" = "nginx-opendesk";
    "org.opencontainers.image.description" = "Nginx 1.25.3 for openDesk Edu with NixOS";
    "org.opencontainers.image.version" = "1.25.3-nixos";
    "org.opencontainers.image.authors" = "openDesk Edu Team";
    "org.opencontainers.image.url" = "https://opendesk.hrz.uni-marburg.de";
    "org.opencontainers.image.documentation" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.source" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.licenses" = "Apache-2.0";
    "com.opendesk.service" = "nginx";
    "com.opendesk.environment" = "production";
    "com.opendesk.managed" = "true";
    "com.opendesk.nixos" = "true";
  };
}

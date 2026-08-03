# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Traefik NixOS Container Image
Version: v2.10.0
OpenSpec: FR-BUILD-001 through FR-BUILD-007
Includes: Ingress routing, TLS termination, Let's Encrypt
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
  traefikPkg = nixpkgsWithOverlays.opendeskPackages.traefik;

in

docks.mkImage {
  name = "traefik-opendesk";
  tag = "v2.10.0-nixos";

  # NixOS configuration
  config = import ./configuration.nix {
    inherit pkgs lib;
  };

  # Container configuration
  containerConfig = {
    ExposedPorts = {
      "80/tcp" = {};
      "443/tcp" = {};
      "9000/tcp" = {};  # Dashboard
    };
    
    Volumes = {
      "/var/lib/traefik" = {};
      "/var/log/traefik" = {};
      "/etc/traefik/certs" = {};
      "/etc/traefik/dynamic" = {};
    };
    
    Env = [
      "TRAEFIK_DASHBOARD_USERNAME="
      "TRAEFIK_DASHBOARD_PASSWORD="
      "OPENDESK_ENV=production"
      "TZ=Europe/Berlin"
      "LC_ALL=C.UTF-8"
      "LANG=C.UTF-8"
    ];
    
    HealthCheck = {
      Test = [ "CMD-SHELL" "curl -f http://127.0.0.1:9000/api/health 2>/dev/null || exit 1" ];
      Interval = 10000000000;  # 10s
      Timeout = 5000000000;   # 5s
      Retries = 3;
      StartPeriod = 15000000000; # 15s
    };
    
    User = "traefik";
    WorkingDir = "/var/lib/traefik";
    
    Cmd = [
      "${traefikPkg}/bin/traefik"
      "--configFile=/etc/traefik/traefik.yml"
    ];
    
    StopSignal = "SIGTERM";
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
    certbot
    certbot-nginx
  ];

  # OCI Labels for OpenSpec compliance (FR-IMAGE-007)
  ociLabels = {
    "org.opencontainers.image.title" = "traefik-opendesk";
    "org.opencontainers.image.description" = "Traefik v2.10.0 for openDesk Edu with NixOS - Ingress controller with TLS"
    "org.opencontainers.image.version" = "v2.10.0-nixos";
    "org.opencontainers.image.authors" = "openDesk Edu Team";
    "org.opencontainers.image.url" = "https://opendesk.hrz.uni-marburg.de";
    "org.opencontainers.image.documentation" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.source" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.licenses" = "Apache-2.0";
    "com.opendesk.service" = "traefik";
    "com.opendesk.environment" = "production";
    "com.opendesk.managed" = "true";
    "com.opendesk.nixos" = "true";
    "com.opendesk.ingress" = "true";
  };
}

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Keycloak NixOS Container Image
Version: 24.0.0
OpenSpec: FR-BUILD-001 through FR-BUILD-007
Includes: Identity provider, OAuth2, OIDC, SAML
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
  keycloakPkg = nixpkgsWithOverlays.opendeskPackages.keycloak;
  jdkPkg = nixpkgsWithOverlays.opendeskPackages.jdk21;

in

docks.mkImage {
  name = "keycloak-opendesk";
  tag = "24.0.0-nixos";

  # NixOS configuration
  config = import ./configuration.nix {
    inherit pkgs lib;
  };

  # Container configuration
  containerConfig = {
    ExposedPorts = {
      "8080/tcp" = {};   # HTTP
      "8443/tcp" = {};   # HTTPS (optional, can be disabled)
      "9000/tcp" = {};   # Debug
    };
    
    Volumes = {
      "/opt/keycloak" = {};
      "/var/log/keycloak" = {};
      "/var/lib/keycloak" = {};
      "/etc/keycloak" = {};
      "/opt/keycloak/data/import" = {};
    };
    
    Env = [
      "KEYCLOAK_ADMIN=admin"
      "KEYCLOAK_ADMIN_PASSWORD="
      "KC_DB=postgres"
      "KC_DB_URL=jdbc:postgresql://postgresql:5432/keycloak"
      "KC_DB_USERNAME=keycloak"
      "KC_DB_PASSWORD="
      "KC_PROXY=edge"
      "KC_HOSTNAME=keycloak.opendesk.hrz.uni-marburg.de"
      "KC_HTTP_ENABLED=true"
      "KC_HTTPS_ENABLED=false"
      "OPENDESK_ENV=production"
      "TZ=Europe/Berlin"
      "JAVA_OPTS=-Djava.net.preferIPv4Stack=true"
      "LC_ALL=C.UTF-8"
      "LANG=C.UTF-8"
    ];
    
    HealthCheck = {
      Test = [ "CMD-SHELL" "curl -f http://127.0.0.1:8080/health/ready 2>/dev/null || exit 1" ];
      Interval = 10000000000;  # 10s
      Timeout = 5000000000;   # 5s
      Retries = 3;
      StartPeriod = 60000000000; # 60s (Keycloak takes longer to start)
    };
    
    User = "keycloak";
    WorkingDir = "/opt/keycloak";
    
    Cmd = [
      "${jdkPkg}/bin/java"
      "-Djava.net.preferIPv4Stack=true"
      "-Djboss.modules.system.pkgs=${jdkPkg}/jre/modules"
      "-Djava.awt.headless=true"
      "-Dkeycloak.profile=prod"
      "-Dkeycloak.migration.action=import"
      "-Dkeycloak.migration.provider=dir"
      "-Dkeycloak.migration.dir=/opt/keycloak/data/import"
      "-Dkeycloak.migration.strategy=IGNORE_EXISTING"
      "-Xms1024m"
      "-Xmx2048m"
      "-XX:MaxMetaspaceSize=512m"
      "-jar"
      "${keycloakPkg}/lib/quarkus-run.jar"
    ];
    
    StopSignal = "SIGTERM";
    StopTimeout = 60;
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
    "org.opencontainers.image.title" = "keycloak-opendesk";
    "org.opencontainers.image.description" = "Keycloak 24.0.0 for openDesk Edu with NixOS - Identity Provider";
    "org.opencontainers.image.version" = "24.0.0-nixos";
    "org.opencontainers.image.authors" = "openDesk Edu Team";
    "org.opencontainers.image.url" = "https://opendesk.hrz.uni-marburg.de";
    "org.opencontainers.image.documentation" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.source" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.licenses" = "Apache-2.0";
    "com.opendesk.service" = "keycloak";
    "com.opendesk.environment" = "production";
    "com.opendesk.managed" = "true";
    "com.opendesk.nixos" = "true";
    "com.opendesk.iam" = "true";
  };
}

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Keycloak NixOS Configuration for openDesk
Version: 24.0.0
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
Includes: Identity provider, OAuth2, OIDC, SAML
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # Java environment for Keycloak
  environment.systemPackages = with pkgs; [
    opendeskPackages.jdk21
    openssl
  ];

  # Keycloak service configuration
  services.keycloak = {
    enable = true;
    package = pkgs.opendeskPackages.keycloak;

    # Keycloak database configuration (PostgreSQL)
    db = {
      vendor = "postgres";
      host = "${config.services.keycloak.dbHost or "postgresql"}";
      port = "${toString (config.services.keycloak.dbPort or 5432)}";
      database = "${config.services.keycloak.dbName or "keycloak"}";
      username = "${config.services.keycloak.dbUsername or "keycloak"}";
      password = config.services.keycloak.dbPassword or "CHANGE_ME_IN_PRODUCTION";
    };

    # HTTP configuration
    http = {
      enabled = true;
      port = 8080;
      host = "0.0.0.0";
    };

    # HTTPS configuration (optional, can be handled by Traefik)
    https = {
      enabled = false;
      port = 8443;
    };

    # Admin credentials
    adminUsername = config.services.keycloak.adminUsername or "admin";
    adminPassword = config.services.keycloak.adminPassword or "CHANGE_ME_ADMIN_PASSWORD";

    # Proxy mode (important when behind Traefik/Nginx)
    proxy = "edge";

    # Web context path
    webContextPath = "/";

    # Java options
    javaOpts = [
      "-Djava.net.preferIPv4Stack=true"
      "-Djboss.modules.system.pkgs=${pkgs.opendeskPackages.jdk21}/jre/modules"
      "-Djava.awt.headless=true"
      "-Dkeycloak.profile=prod"
      "-Dkeycloak.migration.action=import"
      "-Dkeycloak.migration.provider=dir"
      "-Dkeycloak.migration.dir=/opt/keycloak/data/import"
      "-Dkeycloak.migration.strategy=IGNORE_EXISTING"
      "-Xms1024m"
      "-Xmx2048m"
      "-XX:MaxMetaspaceSize=512m"
      "-XX:+UseG1GC"
      "-XX:MaxGCPauseMillis=500"
      "-XX:+DisableExplicitGC"
      "-XX:+HeapDumpOnOutOfMemoryError"
      "-XX:HeapDumpPath=/tmp/keycloak-heapdump.hprof"
      "-Dfile.encoding=UTF-8"
    ];

    # Memory settings
    memory = {
      heapSize = "2048m";
      jvmMetaspaceSize = "512m";
    };

    # Logging
    logging = {
      level = {
        root = "INFO";
        org.keycloak = "DEBUG";
        org.infinispan = "WARN";
        org.jboss.as = "WARN";
        org.jboss.weld = "WARN";
      };
      console = {
        enabled = true;
        pattern = "%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p [%c] %s%e%n";
      };
      file = {
        enabled = true;
        file = "/var/log/keycloak/keycloak.log";
        pattern = "%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p [%c] %s%e%n";
      };
    };

    # Features
    features = [
      "admin-fine-grained-authz"
      "token-exchange"
      "scripting"
      "client-policies"
      "admin-fine-grained-authz"
    ];

    # SPIs (Service Provider Interfaces)
    spis = [
      "eventsListener-jboss-logging"
      "jpa"
      "timers"
    ];
  };

  # Keycloak systemd service
  systemd.services.keycloak = {
    description = "Keycloak Identity Provider";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "postgresql.service" ];

    serviceConfig = {
      Type = "simple";
      User = "keycloak";
      Group = "keycloak";
      WorkingDirectory = "/opt/keycloak";
      Environment = builtins.concatMap (opt: [ "${opt}" ]) (
        (config.services.keycloak.javaOpts or [ ]) ++ [
          "JAVA_HOME=${pkgs.opendeskPackages.jdk21}"
          "JBOSS_HOME=/opt/keycloak"
          "KEYCLOAK_CONFIG_FILE=/etc/keycloak/keycloak.conf"
        ]
      );
      ExecStart = ''
        ${pkgs.opendeskPackages.jdk21}/bin/java \
          -Dkeycloak.home.dir=/opt/keycloak \
          -Djboss.home.dir=/opt/keycloak \
          ${lib.concatMap (opt: " ${opt}") config.services.keycloak.javaOpts} \
          -jar /opt/keycloak/lib/quarkus-run.jar
      '';
      ExecReload = "/bin/kill -HUP $MAINPID";
      ExecStop = "/bin/kill -TERM $MAINPID";
      Restart = "on-failure";
      RestartSec = "30";
      TimeoutStopSec = "60";
      LimitNOFILE = 65535;
      LimitNPROC = 4096;
    };
  };

  # System user for Keycloak
  users.users.keycloak = {
    isSystemUser = true;
    uid = 1000;
    gid = 1000;
    group = "keycloak";
    home = "/opt/keycloak";
    shell = pkgs.bash;
    description = "Keycloak Identity Provider User";
  };

  users.groups.keycloak = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setupKeycloak = lib.mkAfter ''
    # Create necessary directories
    mkdir -p /opt/keycloak /var/log/keycloak /var/lib/keycloak /etc/keycloak
    mkdir -p /opt/keycloak/data/import /opt/keycloak/standalone/configuration
    mkdir -p /opt/keycloak/standalone/data /opt/keycloak/standalone/log
    mkdir -p /opt/keycloak/standalone/tmp
    
    # Set correct ownership
    chown -R keycloak:keycloak /opt/keycloak /var/log/keycloak /var/lib/keycloak /etc/keycloak
    
    # Set correct permissions
    chmod -R 750 /opt/keycloak
    chmod -R 755 /var/log/keycloak
    chmod -R 700 /etc/keycloak
    
    # Create log file
    touch /var/log/keycloak/keycloak.log
    chown keycloak:keycloak /var/log/keycloak/keycloak.log
    chmod 640 /var/log/keycloak/keycloak.log
    
    # Create configuration directory
    mkdir -p /etc/keycloak
    chown keycloak:keycloak /etc/keycloak
    chmod 700 /etc/keycloak
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

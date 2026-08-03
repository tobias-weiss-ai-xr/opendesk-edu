# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Traefik NixOS Configuration for openDesk
Version: v2.10.0
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
Includes: Ingress routing, TLS termination, Let's Encrypt support
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # Traefik service configuration
  services.traefik = {
    enable = true;
    package = pkgs.opendeskPackages.traefik;

    # Traefik configuration file
    extraConfig = pkgs.writeText "traefik.yml" ''
      # Global configuration
      global:
        checkNewVersion: false
        sendAnonymousUsage: false
      
      # Entry points
      entryPoints:
        web:
          address: ":80"
          http:
            middlewares:
              - redirect-to-https@file
        websecure:
          address: ":443"
          http:
            tls:
              certResolver: letsencrypt
            middlewares:
              - security-headers@file
              - rate-limit@file
      
      # API and Dashboard
      api:
        dashboard: true
        insecure: false
        debug: false
      
      # Ingress routes for openDesk services
      http:
        routers:
          # openDesk main application
          opendesk:
            rule: "Host(`opendesk.hrz.uni-marburg.de`)"
            entryPoints:
              - websecure
            service: opendesk
            tls:
              certResolver: letsencrypt
            middlewares:
              - security-headers@file
              - rate-limit@file
          
          # Moodle
          moodle:
            rule: "Host(`moodle.opendesk.hrz.uni-marburg.de`)"
            entryPoints:
              - websecure
            service: moodle
            tls:
              certResolver: letsencrypt
            middlewares:
              - security-headers@file
          
          # Nextcloud
          nextcloud:
            rule: "Host(`nextcloud.opendesk.hrz.uni-marburg.de`)"
            entryPoints:
              - websecure
            service: nextcloud
            tls:
              certResolver: letsencrypt
            middlewares:
              - security-headers@file
          
          # Collabora
          collabora:
            rule: "Host(`collabora.opendesk.hrz.uni-marburg.de`)"
            entryPoints:
              - websecure
            service: collabora
            tls:
              certResolver: letsencrypt
          
          # API Gateway
          api:
            rule: "Host(`api.opendesk.hrz.uni-marburg.de`)"
            entryPoints:
              - websecure
            service: api
            tls:
              certResolver: letsencrypt
          
          # Traefik Dashboard (internal only)
          traefik-dashboard:
            rule: "Host(`traefik.opendesk.hrz.uni-marburg.de`)"
            entryPoints:
              - websecure
            service: api@internal
            tls:
              certResolver: letsencrypt
            middlewares:
              - auth@file
      
        # Services
        services:
          opendesk:
            loadBalancer:
              servers:
                - url: "http://opendesk-app:8080"
          
          moodle:
            loadBalancer:
              servers:
                - url: "http://moodle:8080"
          
          nextcloud:
            loadBalancer:
              servers:
                - url: "http://nextcloud:8080"
          
          collabora:
            loadBalancer:
              servers:
                - url: "http://collabora:9980"
          
          api:
            loadBalancer:
              servers:
                - url: "http://api-gateway:8000"
      
      # Middlewares
      middlewares:
        # Redirect HTTP to HTTPS
        redirect-to-https:
          redirectScheme:
            scheme: https
            permanent: true
        
        # Security headers
        security-headers:
          headers:
            sslRedirect: true
            stsSeconds: 31536000
            stsIncludeSubdomains: true
            stsPreload: true
            forceSTSHeader: true
            frameDeny: true
            contentTypeNosniff: true
            browserXssFilter: true
            referrerPolicy: "same-origin"
            contentSecurityPolicy: "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self'; frame-src 'self'; object-src 'none';"
            customFrameOptionsValue: "SAMEORIGIN"
            customRequestHeaders:
              X-Forwarded-Proto: "https"
        
        # Rate limiting
        rate-limit:
          rateLimit:
            extractorFunc: request.host
            rateSet:
              global:
                average: 1000
                burst: 2000
            
        # Basic authentication for dashboard
        auth:
          basicAuth:
            users:
              - "${config.services.traefik.dashboardUsername}:${config.services.traefik.dashboardPassword}"
      
      # TLS Configuration
      certificatesResolvers:
        letsencrypt:
          acme:
            email: "admin@opendesk.hrz.uni-marburg.de"
            storage: "/etc/traefik/certs/acme.json"
            httpChallenge:
              entryPoint: web
            dnsChallenge:
              provider: cloudflare
              delayBeforeCheck: 0
    '';

    # Traefik dashboard credentials
    dashboardUsername = "admin";
    dashboardPassword = config.services.traefik.dashboardPassword or "CHANGE_ME_IN_PRODUCTION";

    # Port configuration
    ports = {
      web = 80;
      websecure = 443;
      traefik = 9000;
    };
  };

  # System user for Traefik
  users.users.traefik = {
    isSystemUser = true;
    uid = 102;
    gid = 102;
    group = "traefik";
    home = "/var/lib/traefik";
    shell = pkgs.bash;
    description = "Traefik Reverse Proxy User";
  };

  users.groups.traefik = {
    gid = 102;
  };

  # Setup directories
  system.activationScripts.setupTraefik = lib.mkAfter ''
    # Create necessary directories
    mkdir -p /var/lib/traefik /var/log/traefik /etc/traefik/certs /etc/traefik/dynamic
    
    # Set correct ownership
    chown -R traefik:traefik /var/lib/traefik /var/log/traefik /etc/traefik
    
    # Set correct permissions
    chmod -R 750 /var/lib/traefik /etc/traefik
    chmod -R 755 /var/log/traefik
    
    # Create acme.json for Let's Encrypt
    touch /etc/traefik/certs/acme.json
    chown traefik:traefik /etc/traefik/certs/acme.json
    chmod 600 /etc/traefik/certs/acme.json
    
    # Create log files
    touch /var/log/traefik/access.log /var/log/traefik/error.log
    chown traefik:traefik /var/log/traefik/*.log
    chmod 640 /var/log/traefik/*.log
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

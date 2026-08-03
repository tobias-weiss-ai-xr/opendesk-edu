# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Nginx NixOS Configuration for openDesk
Version: 1.25.3
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # Nginx service configuration
  services.nginx = {
    enable = true;
    package = pkgs.opendeskPackages.nginx;

    # Performance optimizations
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    
    # Worker process settings
    workerConnections = "1024";
    workerProcesses = "auto";
    
    # Gzip compression
    # gzip = true;
    # gzipCompLevel = 6;
    # gzipTypes = [ "text/plain" "text/css" "application/json" "application/javascript" "*/*" ];
    
    # Virtual hosts
    virtualHosts = {
      # Default server
      "*:80" = {
        default = true;
        
        # Redirect HTTP to HTTPS
        return = "https://$host$request_uri";
      };
      
      # openDesk main domain
      "opendesk.hrz.uni-marburg.de" = {
        # SSL configuration
        ssl = true;
        sslCertificate = "/etc/nginx/ssl/opendesk.crt";
        sslCertificateKey = "/etc/nginx/ssl/opendesk.key";
        
        # Redirect HTTP to HTTPS
        locations."@http" = {
          return = "https://$host$request_uri";
        };
        
        # Main application proxy
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
            X-Forwarded-Port = "$server_port";
          };
          proxyBuffering = "on";
          proxyBufferSize = "4k";
          proxyBuffers = "8 16k";
          proxyBusyBuffersSize = "24k";
          proxyMaxTempFileSize = "2048m";
        };
        
        # Static files
        locations."/static/" = {
          alias = "/var/www/static/";
          tryFiles = "$uri =404";
          accessLog = "off";
        };
        
        # API endpoints
        locations."/api/" = {
          proxyPass = "http://127.0.0.1:8080/api/";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };
        
        # Health check
        locations."/healthz" = {
          return = "200 OK\n";
          addHeader = "Content-Type text/plain";
        };
      };
      
      # Moodle
      "moodle.opendesk.hrz.uni-marburg.de" = {
        ssl = true;
        sslCertificate = "/etc/nginx/ssl/moodle.crt";
        sslCertificateKey = "/etc/nginx/ssl/moodle.key";
        
        locations."/" = {
          proxyPass = "http://moodle:8080";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
        };
      };
      
      # Nextcloud
      "nextcloud.opendesk.hrz.uni-marburg.de" = {
        ssl = true;
        sslCertificate = "/etc/nginx/ssl/nextcloud.crt";
        sslCertificateKey = "/etc/nginx/ssl/nextcloud.key";
        
        locations."/" = {
          proxyPass = "http://nextcloud:8080";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
            Front-End-Https = "on";
          };
          # WebSocket support
          proxyHttpVersion = "1.1";
          proxySetHeader = "Upgrade $http_upgrade";
          proxySetHeader = "Connection \"upgrade\"";
        };
      };
      
      # Collabora
      "collabora.opendesk.hrz.uni-marburg.de" = {
        ssl = true;
        sslCertificate = "/etc/nginx/ssl/collabora.crt";
        sslCertificateKey = "/etc/nginx/ssl/collabora.key";
        
        locations."/" = {
          proxyPass = "http://collabora:9980";
          proxySetHeaders = {
            Host = "$host";
            X-Real-IP = "$remote_addr";
            X-Forwarded-For = "$proxy_add_x_forwarded_for";
            X-Forwarded-Proto = "$scheme";
          };
          # WebSocket support for Collabora
          proxyHttpVersion = "1.1";
          proxySetHeader = "Upgrade $http_upgrade";
          proxySetHeader = "Connection \"upgrade\"";
          proxyReadTimeout = "3600";
          proxySendTimeout = "3600";
        };
      };
    };
    
    # Logging
    accessLog = "/var/log/nginx/access.log";
    errorLog = "/var/log/nginx/error.log";
    logFormat = '
      "$remote_addr - $remote_user [$time_local] \"$request\" "
      "$status $body_bytes_sent \"$http_referer\" "
      "\"$http_user_agent\" $request_time"
    ';
    
    # Client body size for file uploads
    clientMaxBodySize = "200M";
    
    # Timeouts
    clientBodyTimeout = "120";
    clientHeaderTimeout = "120";
    keepaliveTimeout = "75";
    sendTimeout = "120";
    
    # Proxy timeouts
    proxyConnectTimeout = "120";
    proxySendTimeout = "120";
    proxyReadTimeout = "120";
  };

  # System user for Nginx
  users.users.nginx = {
    isSystemUser = true;
    uid = 101;
    gid = 101;
    group = "nginx";
    home = "/var/lib/nginx";
    shell = pkgs.bash;
    description = "Nginx Web Server User";
  };

  users.groups.nginx = {
    gid = 101;
  };

  # Setup directories
  system.activationScripts.setupNginx = lib.mkAfter ''
    # Create necessary directories
    mkdir -p /var/lib/nginx /var/log/nginx /var/cache/nginx /etc/nginx/ssl
    
    # Set correct ownership
    chown -R nginx:nginx /var/lib/nginx /var/log/nginx /var/cache/nginx
    
    # Set correct permissions
    chmod -R 750 /var/lib/nginx
    chmod -R 755 /var/log/nginx
    chmod -R 755 /var/cache/nginx
    chmod -R 755 /etc/nginx
    
    # Create SSL directory
    mkdir -p /etc/nginx/ssl
    chown -R nginx:nginx /etc/nginx/ssl
    chmod -R 750 /etc/nginx/ssl
    
    # Create log files
    touch /var/log/nginx/access.log /var/log/nginx/error.log
    chown nginx:nginx /var/log/nginx/*.log
    chmod 640 /var/log/nginx/*.log
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}

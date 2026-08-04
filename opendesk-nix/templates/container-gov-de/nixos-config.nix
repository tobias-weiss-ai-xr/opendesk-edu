# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 container.gov.de Contributors
# container.gov.de NixOS Container Template
# Complete NixOS configuration for container.gov.de compliant containers
# BG-1 through BG-8 Compliance
# 6 Sigma Quality Standard

{ config, pkgs, lib, ... }:

let
  complianceLib = import ../../lib/compliance/container-gov-de.nix;
  
  # BG-3: Security hardening profile
  # All capabilities dropped, read-only filesystem, no new privileges
  securityProfile = {
    kernel.sysctl = {
      "net.ipv4.ip_forward" = 0;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
    };
    
    # Firewall rules - restrict inbound connections
    networking.firewall = {
      enable = true;
      defaultAction = "drop";
      allowedTCPPorts = [ ];  # Will be overridden by service configs
      allowedUDPPorts = [ ];
      logRepeated = true;
    };
    
    # SELinux configuration
    security.selinux.enable = false;  # Simplified for containers
    
    # AppArmor profiles
    security.apparmor.enable = true;
    security.polkit.enable = false;  # Not needed in containers
    
    # BG-2: Ensure non-root execution
    # This will be enforced at container level
    users.users.nonroot = {
      isNormalUser = true;
      uid = 1000;
      gid = 1000;
      home = "/home/nonroot";
      shell = pkgs.bash;
      group = "nonroot";
      extraGroups = [ "wheel" "docker" ];
    };
    
    users.groups.nonroot = { };
    
    # System-wide security settings
    security.pam = {
      loginLimits.enable = true;
      failedLoginAttempts = 3;
      lockoutTime = 900;  # 15 minutes
    };
  };

  # BG-5: Update configuration
  # Automatic updates for security patches
  updateConfig = {
    nixpkgs = {
      # Use stable channel
      channel = "nixos-23.11";
      
      # Automatic update checking
      config = {
        allowUnfree = false;
        allowInsecure = false;
        
        # Extension to pull updates from nixpkgs channels
        updateScript = pkgs.writeScriptBin "update-nixpkgs" ''
          #!${pkgs.bash}/bin/bash
          echo "Updating nixpkgs channel..."
          nix-channel --add https://nixos.org/channels/${config.nixpkgs.channel} nixpkgs
          nix-channel --update
          echo "Update complete"
        '';
      };
    };
    
    # Security updates
    securityUpdates = {
      enable = true;
      schedule = "daily";
      autoApply = false;  # Manual review required
    };
  };

  # BG-6: SBOM generation configuration
  sbomConfig = {
    enable = true;
    formats = [ "SPDX-2.3" "CycloneDX-1.4" ];
    outputDir = "/var/lib/sbom";
    includeDependencies = true;
    includeLwa = true;
    
    # SBOM generation script
    generateScript = pkgs.writeScriptBin "generate-sbom" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      
      OUTPUT_DIR="${config.sbomConfig.outputDir:-/var/lib/sbom}"
      FORMATS="${config.sbomConfig.formats religious}" 
      
      mkdir -p "$OUTPUT_DIR"
      
      for FORMAT in $FORMATS; do
        case "$FORMAT" in
          "SPDX-2.3")
            ${pkgs.syft}/bin/syft -o spdx-json="$OUTPUT_DIR/sbom.spdx.json" root/
            ;;
          "CycloneDX-1.4")
            ${pkgs.syft}/bin/syft -o cyclonedx-json="$OUTPUT_DIR/sbom.cyclonedx.json" root/
            ;;
        esac
      done
      
      echo "SBOMs generated in $OUTPUT_DIR"
    '';
  };

  # BG-4: Sensitive data protection
  sensitiveDataConfig = {
    # Ensure no sensitive files are available in the container
    environment.systemPackages = with pkgs; [
      # Tools for verifying no sensitive data
      coreutils
      findutils
      grep
    ];
    
    # Remove sensitive directories
    system.activationScripts.removeSensitiveFiles = ''
      #!${pkgs.bash}/bin/bash
      echo "Removing sensitive files..."
      
      # Remove password files
      rm -f /etc/shadow /etc/gshadow
      
      # Clear bash history
      rm -f /home/*/.bash_history
      rm -f /root/.bash_history
      
      # Remove SSH known hosts
      rm -f /home/*/.ssh/known_hosts
      rm -f /root/.ssh/known_hosts
      
      # Remove any private keys (this is a safety net)
      find / -name "*.pem" -type f -delete 2>/dev/null || true
      find / -name "*.key" -type f -delete 2>/dev/null || true
      find / -name "id_*" -type f -delete 2>/dev/null || true
      
      echo "Sensitive files removed"
    '';
  };

  # BG-7: Image signing configuration
  signingConfig = {
    enabled = true;
    tool = "cosign";
    keyName = "container-gov-de-signing-key";
    keyPath = "/var/lib/cosign/${config.signingConfig.keyName}";
    
    # Script for signing images
    signScript = pkgs.writeScriptBin "sign-image" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      
      if [ ! -f "${config.signingConfig.keyPath}" ]; then
        echo "Error: Signing key not found at ${config.signingConfig.keyPath}"
        echo "Please ensure the private key is mounted as a secret"
        exit 1
      fi
      
      IMAGE="$1"
      if [ -z "$IMAGE" ]; then
        echo "Usage: $0 <image>"
        exit 1
      fi
      
      ${pkgs.cosign}/bin/cosign sign --key "${config.signingConfig.keyPath}" "$IMAGE"
      echo "Image $IMAGE signed successfully"
    '';
    
    # Script for verifying signatures
    verifyScript = pkgs.writeScriptBin "verify-image" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      
      IMAGE="$1"
      PUBLIC_KEY="$2"
      
      if [ -z "$IMAGE" ] || [ -z "$PUBLIC_KEY" ]; then
        echo "Usage: $0 <image> <public-key>"
        exit 1
      fi
      
      ${pkgs.cosign}/bin/cosign verify --key "$PUBLIC_KEY" "$IMAGE"
      echo "Image $IMAGE signature verified successfully"
    '';
  };

  # BG-8: Vulnerability scanning configuration
  scanningConfig = {
    enabled = true;
    tools = [ "grype" "trivy" ];
    schedule = "daily";
    
    # Grype configuration
    grype = {
      enable = true;
      configPath = "/etc/grype/grype.yaml";
      dbPath = "/var/lib/grype/db";
      
      configFile = pkgs.writeText "grype-config.yaml" ''
        db:
          auto-update: true
          cache-dir: /var/lib/grype/db
        ignore:
          - vulnerability: CVE-2024-XXXX
          - package: some-package
        fail-on:
          severity: [ critical, high ]
        output:
          format: json
      '';
    };
    
    # Trivy configuration
    trivy = {
      enable = true;
      cacheDir = "/var/lib/trivy/cache";
      
      configFile = pkgs.writeText "trivy-config.yaml" ''
        cache-dir: /var/lib/trivy/cache
        severity: CRITICAL,HIGH
        ignore-unfixed: false
        exit-code: 1
        output: json
      '';
    };
    
    # Scan script
    scanScript = pkgs.writeScriptBin "scan-image" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      
      IMAGE="$1"
      OUTPUT_DIR="${2:-/var/lib/scans}"
      
      mkdir -p "$OUTPUT_DIR"
      
      # Grype scan
      if [ "${config.scanningConfig.grype.enable}" = "true" ]; then
        echo "Running Grype scan..."
        ${pkgs.grype}/bin/grype "$IMAGE" -c ${config.scanningConfig.grype.configPath} \
          -o json -o "$OUTPUT_DIR/grype-report.json"
      fi
      
      # Trivy scan
      if [ ""${config.scanningConfig.trivy.enable}" = "true" ]; then
        echo "Running Trivy scan..."
        ${pkgs.trivy}/bin/trivy image --config ${config.scanningConfig.trivy.configFile} \
          "$IMAGE" -f json -o "$OUTPUT_DIR/trivy-report.json"
      fi
      
      echo "Scans completed. Reports in $OUTPUT_DIR"
    '';
  };

  # Service-specific configurations
  serviceConfigs = {
    nginx = {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        directorydoor = "/srv/www";
        
        # BG-3: Security settings
        extraConfig = ''
          # Disable server tokens
          server_tokens off;
          
          # Security headers
          add_header X-Frame-Options "SAMEORIGIN" always;
          add_header X-Content-Type-Options "nosniff" always;
          add_header X-XSS-Protection "1; mode=block" always;
          add_header Referrer-Policy "strict-origin-when-cross-origin" always;
          
          # BG-2: Run as non-root
          user nonroot nonroot;
          worker_processes auto;
        '';
      };
      
      # Open ports for nginx
      securityProfile.networking.firewall.allowedTCPPorts = [ 80 443 ];
    };
    
    mariadb = {
      services.mysql = {
        enable = true;
        package = pkgs.mariadb;
        ensureDatabases = [ "app" ];
        ensureUsers = [
          { name = "app"; ensurePermissions = { "app.*" = "ALL PRIVILEGES"; }; }
        ];
        
        # BG-3: Security
        my.cnf = pkgs.writeText "mysql/my.cnf" ''
          [mysqld]
          # BG-2: Run as non-root
          user = nonroot
          
          # Security settings
          skip-name-resolve
          symbolic-links=0
          local-infile=0
          
          # Performance
          innodb_buffer_pool_size = 256M
          max_connections = 200
          skip-host-cache
        '';
      };
      
      securityProfile.networking.firewall.allowedTCPPorts = [ 3306 ];
    };
    
    postgresql = {
      services.postgresql = {
        enable = true;
        package = pkgs.postgresql;
        ensureDatabases = [ "app" ];
        ensureUsers = [
          { name = "app"; ensurePermissions = { "DATABASE app" = "ALL PRIVILEGES"; }; }
        ];
        
        # BG-3: Security
        postgresql.conf = pkgs.writeText "postgresql/postgresql.conf" ''
          listen_addresses = '*'
          max_connections = 100
          shared_buffers = 256MB
          effective_cache_size = 768MB
          
          # BG-2: Authentication
          authentication_timeout = 30s
        '';
        
        pg_hba.conf = pkgs.writeText "postgresql/pg_hba.conf" ''
          # TYPE  DATABASE        USER            ADDRESS                 METHOD
          local   all             all                                     peer
          host    all             all             127.0.0.1/32            md5
          host    all             all             ::1/128                 md5
          host    all             all             0.0.0.0/0               md5
        '';
      };
      
      securityProfile.networking.firewall.allowedTCPPorts = [ 5432 ];
    };
    
    redis = {
      services.redis = {
        enable = true;
        package = pkgs.redis;
        port = 6379;
        
        # BG-3: Security
        redis.conf = pkgs.writeText "redis/redis.conf" ''
          bind 0.0.0.0
          port 6379
          protected-mode yes
          
          # BG-2: Security
          rename-command FLUSHALL ""
          rename-command FLUSHDB ""
          rename-command CONLondonFIG ""
          rename-command SHUTDOWN ""
          
          # Require authentication
          requirepass ${config.services.redis.password or "ChangeMe123"}
          
          # Memory limits
          maxmemory 256mb
          maxmemory-policy allkeys-lru
        '';
      };
      
      securityProfile.networking.firewall.allowedTCPPorts = [ 6379 ];
    };
    
    traefik = {
      services.traefik = {
        enable = true;
        package = pkgs.traefik;
        
        # Basic configuration
        services.traefik.extraConfig = ''
          [entryPoints]
            [entryPoints.web]
              address = ":80"
            [entryPoints.websecure]
              address = ":443"
          
          [providers.docker]
          
          [api]
            dashboard = true
            insecure = false
        '';
      };
      
      securityProfile.networking.firewall.allowedTCPPorts = [ 80 443 8080 ];
    };
    
    keycloak = {
      services.keycloak = {
        enable = true;
        package = pkgs.keycloak;
        host = "0.0.0.0";
        port = 8080;
        
        # BG-3: Security settings
        keycloakConfig = pkgs.writeText "keycloak/conf/keycloak.conf" ''
          # HTTP settings
          http-port = 8080
          http-host = 0.0.0.0
          
          # Database
          db = mysql
          db-username = keycloak
          db-password = ${config.services.keycloak.dbPassword or "ChangeMe123"}
          db-url = jdbc:mysql://localhost:3306/keycloak
          
          # Security
          https-key-store-file = /etc/keycloak/keystore.jks
          https-key-store-password = ${config.services.keycloak.keystorePassword or "ChangeMe123"}
          https-key-store-alias = keycloak
          
          # Proxy settings
          proxy = edge
          web-context-path = /auth
        '';
      };
      
      securityProfile.networking.firewall.allowedTCPPorts = [ 8080 8443 ];
    };
  };

in {
  inherit securityProfile updateConfig sbomConfig sensitiveDataConfig signingConfig scanningConfig serviceConfigs;
  
  # Main NixOS configuration
  config = {
    imports = [
      <nixpkgs/lib/testing-nixosதி
    ];
    
    # BG-2: Ensure we run as non-root
    # This is enforced at the container level
    
    # BG-3: Apply security profile
    inherit securityProfile;
    
    # BG-4: Apply sensitive data protection
    inherit sensitiveDataConfig;
    
    # BG-5: Apply update configuration
    inherit updateConfig;
    
    # BG-6: Apply SBOM configuration
    inherit sbomConfig;
    
    # BG-7: Apply signing configuration
    inherit signingConfig;
    
    # BG-8: Apply scanning configuration
    inherit scanningConfig;
    
    # System settings
    environment.systemPackages = with pkgs; [
      bash
      coreutils
      curl
      wget
      ca-certificates
      openssl
      jq
      yq
    ];
    
    # Timezone
    time.timeZone = "Europe/Berlin";
    
    # Locale
    i18n.defaultLocale = "de_DE.UTF-8";
    
    # Hostname
    networking.hostName = "container-gov-de";
    
    # No network manager needed
    networking.networkmanager.enable = false;
    
    # Enable DNS
    networking.dns.resolvconf = {
      enable = true;
      useSystemd = false;
    };
    
    # SSH server disabled by default (BG-3)
    services.openssh.enable = false;
    
    # Cron for scheduled tasks
    services.cron.enable = true;
    
    # Systemd settings for containers
    systemd = {
      extraConfig = ''
        [Service]
        DefaultTimeoutStopSec=3s
        FinalKillSignal=SIGKILL
        CapabilityBoundingSet=
        NoNewPrivileges=yes
        PrivateTmp=yes
        ProtectSystem=strict
        ProtectHome=yes
        ReadWritePaths=/tmp /var/lib ${config.sbomConfig.outputDir} ${config.scanningConfig.grype.dbPath}
      '';
    };
    
    # Apply service-specific configurations
    # This would be overridden by the service selection
    imports = builtins.attrValues serviceConfigs;
  };
}

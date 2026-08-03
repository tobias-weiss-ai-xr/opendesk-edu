# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
openDesk NixOS Overlays
Custom package definitions and overrides for openDesk services.
"""

self: super: rec {

  opendeskPackages = {

    # MariaDB 11.4.4 with openDesk optimizations
    mariadb = super.mariadb.overrideAttrs (old: rec {
      version = "11.4.4";
      pname = "mariadb-opendesk";

      # Source from official MariaDB
      src = super.fetchurl {
        url = "https://downloads.mariadb.org/f/mariadb-${version}/source/mariadb-${version}.tar.gz";
        sha256 = "sha256-12c9226f83451286c1e4b7605973d9d1e1d48406e4f7ab88d4b69b5c367d";
      };

      # openDesk-specific build flags
      configureFlags = (old.configureFlags or []) ++ [
        "--with-extra-charsets=complex"
        "--with-embedded-server"
        "--enable-local-infile"
        "--with-jemalloc"
        "--with-systemd"
      ];

      # Additional dependencies
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [
        super.cmake
        super.ninja
        super.pkg-config
      ];

      buildInputs = (old.buildInputs or []) ++ [
        super.zlib
        super.openssl
        super.libedit
        super.libaio
        super.systemd
      ];

      # Environment variables for build
      LAZY nature = true;
      LIBEDIT_LIBRARY = "${super.libedit}/lib";
    });

    # PostgreSQL 16.3 with openDesk optimizations
    postgresql = super.postgresql_16.overrideAttrs (old: rec {
      version = "16.3";
      pname = "postgresql-opendesk";

      # Additional extensions for openDesk
      withGeo = true;
      withUUID = true;
      withOpenssl = true;
      withPgCrypto = true;
      withHstore = true;
      withPlPerl = false;  # Not needed, reduces image size
      withPlPython = true;
      withPlTcl = false;   # Not needed

      # Build flags
      configureFlags = (old.configureFlags or []) ++ [
        "--with-systemd"
        "--enable-nls"
      ];
    });

    # Redis 7.2.4 with openDesk configuration
    redis = super.redis.overrideAttrs (old: rec {
      version = "7.2.4";
      pname = "redis-opendesk";

      # Build with optimizations
      makeFlags = (old.makeFlags or "") + " -j$(nproc)";
    });

    # Nginx with openDesk modules
    nginx = super.nginx.overrideAttrs (old: rec {
      version = "1.25.3";
      pname = "nginx-opendesk";

      # Additional modules
      modules = (old.modules or []) ++ [
        super.nginxModules.ngx_http_geoip2_module
        super.nginxModules.ngx_http_image_filter_module
        super.nginxModules.ngx_http_xslt_filter_module
        super.nginxModules.ngx_http_realip_module
        super.nginxModules.ngx_http_sub_module
      ];
    });

    # PHP 8.2 with openDesk extensions
    php82 = super.php82.override {
      extensions = (old: old // rec {
        xdebug = true;
        gd = true;
        intl = true;
        ldap = true;
        mysqli = true;
        pdo = true;
        pdo_mysql = true;
        soap = true;
        sockets = true;
        xmlrpc = true;
        zip = true;
        mbstring = true;
        curl = true;
        opcache = true;
        apcu = true;
      });
    };

    # PHP-FPM with openDesk settings
    php82fpm = super.phpfpm.override {
      phpPackage = opendeskPackages.php82;
      settings = {
        "memory_limit" = "512M";
        "upload_max_filesize" = "200M";
        "post_max_size" = "200M";
        "max_execution_time" = "300";
        "opcache.enable" = "1";
        "opcache.memory_consumption" = "256";
        "opcache.interned_strings_buffer" = "32";
        "opcache.max_accelerated_files" = "10000";
      };
    };

    # Traefik 2.10 with openDesk plugins
    traefik = super.traefik.overrideAttrs (old: rec {
      version = "v2.10.0";
      pname = "traefik-opendesk";

      # Enable additional features
      goPackageOverrides = super.goOverflow // rec {
        github.com/traefik/traefik/v2 = old.enhancedGoored;
      };
    });

    # Keycloak 24.0 with openDesk theme
    keycloak = super.keycloak.overrideAttrs (old: rec {
      version = "24.0.0";
      pname = "keycloak-opendesk";

      # Custom JVM options
      jvmOptions = (old.jvmOptions or "") + " -Dkeycloak.profile=prod -Djava.net.preferIPv4Stack=true";
    });

    # Node.js 20 LTS
    nodejs_20 = super.nodejs-20_x.override {
      withNpm = true;
      withYarn = true;
      withCorepack = true;
    };

    # Nextcloud
    nextcloud = super.nextcloud.overrideAttrs (old: rec {
      version = "29.0.0";
      pname = "nextcloud-opendesk";

      phpPackage = opendeskPackages.php82;
      databaseSupport = [ "mysql" "pgsql" "sqlite" ];
    });

    # Moodle
    moodle = super.moodle.overrideAttrs (old: rec {
      version = "4.4.0";
      pname = "moodle-opendesk";

      phpPackage = opendeskPackages.php82;
    });

    # Redis cluster support
    redisCluster = super.redis.overrideAttrs (old: rec {
      version = "7.2.4";
      pname = "redis-cluster-opendesk";

      # Enable cluster mode
      makeFlags = (old.makeFlags or "") + " MALLOC=jemalloc";
    });
  };

  # Legacy compatibility
  opendesk = opendeskPackages;
}

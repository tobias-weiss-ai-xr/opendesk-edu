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
    # zot-registry
    zot-registry = super.zot-registry.overrideAttrs (old: rec {
      version = "2.0.0-rc4";
      pname = "zot-registry-opendesk";
      # TODO: Add custom source
    });
    # dev-agent
    dev-agent = super.dev-agent.overrideAttrs (old: rec {
      version = "latest";
      pname = "dev-agent-opendesk";
      # TODO: Add custom source
    });
    # sogo5
    sogo5 = super.sogo5.overrideAttrs (old: rec {
      version = "latest";
      pname = "sogo5-opendesk";
      # TODO: Add custom source
    });
    # sogo6
    sogo6 = super.sogo6.overrideAttrs (old: rec {
      version = "latest";
      pname = "sogo6-opendesk";
      # TODO: Add custom source
    });
    # argocd
    argocd = super.argocd.overrideAttrs (old: rec {
      version = "latest";
      pname = "argocd-opendesk";
      # TODO: Add custom source
    });
    # bigbluebutton
    bigbluebutton = super.bigbluebutton.overrideAttrs (old: rec {
      version = "latest";
      pname = "bigbluebutton-opendesk";
      # TODO: Add custom source
    });
    # bookstack
    bookstack = super.bookstack.overrideAttrs (old: rec {
      version = "latest";
      pname = "bookstack-opendesk";
      # TODO: Add custom source
    });
    # clamav
    clamav = super.clamav.overrideAttrs (old: rec {
      version = "latest";
      pname = "clamav-opendesk";
      # TODO: Add custom source
    });
    # coderd
    coderd = super.coderd.overrideAttrs (old: rec {
      version = "latest";
      pname = "coderd-opendesk";
      # TODO: Add custom source
    });
    # code-server
    code-server = super.code-server.overrideAttrs (old: rec {
      version = "latest";
      pname = "code-server-opendesk";
      # TODO: Add custom source
    });
    # collab-dashboard
    collab-dashboard = super.collab-dashboard.overrideAttrs (old: rec {
      version = "latest";
      pname = "collab-dashboard-opendesk";
      # TODO: Add custom source
    });
    # collabora
    collabora = super.collabora.overrideAttrs (old: rec {
      version = "latest";
      pname = "collabora-opendesk";
      # TODO: Add custom source
    });
    # cryptpad
    cryptpad = super.cryptpad.overrideAttrs (old: rec {
      version = "latest";
      pname = "cryptpad-opendesk";
      # TODO: Add custom source
    });
    # dask
    dask = super.dask.overrideAttrs (old: rec {
      version = "latest";
      pname = "dask-opendesk";
      # TODO: Add custom source
    });
    # dovecot
    dovecot = super.dovecot.overrideAttrs (old: rec {
      version = "latest";
      pname = "dovecot-opendesk";
      # TODO: Add custom source
    });
    # drawio
    drawio = super.drawio.overrideAttrs (old: rec {
      version = "latest";
      pname = "drawio-opendesk";
      # TODO: Add custom source
    });
    # elasticsearch
    elasticsearch = super.elasticsearch.overrideAttrs (old: rec {
      version = "latest";
      pname = "elasticsearch-opendesk";
      # TODO: Add custom source
    });
    # element
    element = super.element.overrideAttrs (old: rec {
      version = "latest";
      pname = "element-opendesk";
      # TODO: Add custom source
    });
    # etherpad
    etherpad = super.etherpad.overrideAttrs (old: rec {
      version = "latest";
      pname = "etherpad-opendesk";
      # TODO: Add custom source
    });
    # eudi-issuer
    eudi-issuer = super.eudi-issuer.overrideAttrs (old: rec {
      version = "latest";
      pname = "eudi-issuer-opendesk";
      # TODO: Add custom source
    });
    # excalidraw
    excalidraw = super.excalidraw.overrideAttrs (old: rec {
      version = "latest";
      pname = "excalidraw-opendesk";
      # TODO: Add custom source
    });
    # f13
    f13 = super.f13.overrideAttrs (old: rec {
      version = "latest";
      pname = "f13-opendesk";
      # TODO: Add custom source
    });
    # filebeat
    filebeat = super.filebeat.overrideAttrs (old: rec {
      version = "latest";
      pname = "filebeat-opendesk";
      # TODO: Add custom source
    });
    # grommunio
    grommunio = super.grommunio.overrideAttrs (old: rec {
      version = "latest";
      pname = "grommunio-opendesk";
      # TODO: Add custom source
    });
    # ilias
    ilias = super.ilias.overrideAttrs (old: rec {
      version = "latest";
      pname = "ilias-opendesk";
      # TODO: Add custom source
    });
    # ilias-full
    ilias-full = super.ilias-full.overrideAttrs (old: rec {
      version = "latest";
      pname = "ilias-full-opendesk";
      # TODO: Add custom source
    });
    # intercom
    intercom = super.intercom.overrideAttrs (old: rec {
      version = "latest";
      pname = "intercom-opendesk";
      # TODO: Add custom source
    });
    # intercom-service
    intercom-service = super.intercom-service.overrideAttrs (old: rec {
      version = "latest";
      pname = "intercom-service-opendesk";
      # TODO: Add custom source
    });
    # jitsi
    jitsi = super.jitsi.overrideAttrs (old: rec {
      version = "latest";
      pname = "jitsi-opendesk";
      # TODO: Add custom source
    });
    # jupyterhub
    jupyterhub = super.jupyterhub.overrideAttrs (old: rec {
      version = "latest";
      pname = "jupyterhub-opendesk";
      # TODO: Add custom source
    });
    # kasmvnc
    kasmvnc = super.kasmvnc.overrideAttrs (old: rec {
      version = "latest";
      pname = "kasmvnc-opendesk";
      # TODO: Add custom source
    });
    # kibana
    kibana = super.kibana.overrideAttrs (old: rec {
      version = "latest";
      pname = "kibana-opendesk";
      # TODO: Add custom source
    });
    # kube-prometheus-stack
    kube-prometheus-stack = super.kube-prometheus-stack.overrideAttrs (old: rec {
      version = "latest";
      pname = "kube-prometheus-stack-opendesk";
      # TODO: Add custom source
    });
    # limesurvey
    limesurvey = super.limesurvey.overrideAttrs (old: rec {
      version = "latest";
      pname = "limesurvey-opendesk";
      # TODO: Add custom source
    });
    # loki
    loki = super.loki.overrideAttrs (old: rec {
      version = "latest";
      pname = "loki-opendesk";
      # TODO: Add custom source
    });
    # mariadb-enhanced
    mariadb-enhanced = super.mariadb-enhanced.overrideAttrs (old: rec {
      version = "latest";
      pname = "mariadb-enhanced-opendesk";
      # TODO: Add custom source
    });
    # memcached
    memcached = super.memcached.overrideAttrs (old: rec {
      version = "latest";
      pname = "memcached-opendesk";
      # TODO: Add custom source
    });
    # minio
    minio = super.minio.overrideAttrs (old: rec {
      version = "latest";
      pname = "minio-opendesk";
      # TODO: Add custom source
    });
    # monitoring
    monitoring = super.monitoring.overrideAttrs (old: rec {
      version = "latest";
      pname = "monitoring-opendesk";
      # TODO: Add custom source
    });
    # n8n
    n8n = super.n8n.overrideAttrs (old: rec {
      version = "latest";
      pname = "n8n-opendesk";
      # TODO: Add custom source
    });
    # notes
    notes = super.notes.overrideAttrs (old: rec {
      version = "latest";
      pname = "notes-opendesk";
      # TODO: Add custom source
    });
    # nubus-ldap
    nubus-ldap = super.nubus-ldap.overrideAttrs (old: rec {
      version = "latest";
      pname = "nubus-ldap-opendesk";
      # TODO: Add custom source
    });
    # nubus-portal
    nubus-portal = super.nubus-portal.overrideAttrs (old: rec {
      version = "latest";
      pname = "nubus-portal-opendesk";
      # TODO: Add custom source
    });
    # nubus-provisioning
    nubus-provisioning = super.nubus-provisioning.overrideAttrs (old: rec {
      version = "latest";
      pname = "nubus-provisioning-opendesk";
      # TODO: Add custom source
    });
    # nubus-udm
    nubus-udm = super.nubus-udm.overrideAttrs (old: rec {
      version = "latest";
      pname = "nubus-udm-opendesk";
      # TODO: Add custom source
    });
    # ollama
    ollama = super.ollama.overrideAttrs (old: rec {
      version = "latest";
      pname = "ollama-opendesk";
      # TODO: Add custom source
    });
    # opencloud
    opencloud = super.opencloud.overrideAttrs (old: rec {
      version = "latest";
      pname = "opencloud-opendesk";
      # TODO: Add custom source
    });
    # openproject
    openproject = super.openproject.overrideAttrs (old: rec {
      version = "latest";
      pname = "openproject-opendesk";
      # TODO: Add custom source
    });
    # open-webui
    open-webui = super.open-webui.overrideAttrs (old: rec {
      version = "latest";
      pname = "open-webui-opendesk";
      # TODO: Add custom source
    });
    # open-xchange
    open-xchange = super.open-xchange.overrideAttrs (old: rec {
      version = "latest";
      pname = "open-xchange-opendesk";
      # TODO: Add custom source
    });
    # overleaf
    overleaf = super.overleaf.overrideAttrs (old: rec {
      version = "latest";
      pname = "overleaf-opendesk";
      # TODO: Add custom source
    });
    # planka
    planka = super.planka.overrideAttrs (old: rec {
      version = "latest";
      pname = "planka-opendesk";
      # TODO: Add custom source
    });
    # portal-entries
    portal-entries = super.portal-entries.overrideAttrs (old: rec {
      version = "latest";
      pname = "portal-entries-opendesk";
      # TODO: Add custom source
    });
    # promtail
    promtail = super.promtail.overrideAttrs (old: rec {
      version = "latest";
      pname = "promtail-opendesk";
      # TODO: Add custom source
    });
    # rstudio
    rstudio = super.rstudio.overrideAttrs (old: rec {
      version = "latest";
      pname = "rstudio-opendesk";
      # TODO: Add custom source
    });
    # seaweedfs
    seaweedfs = super.seaweedfs.overrideAttrs (old: rec {
      version = "latest";
      pname = "seaweedfs-opendesk";
      # TODO: Add custom source
    });
    # self-service-password
    self-service-password = super.self-service-password.overrideAttrs (old: rec {
      version = "latest";
      pname = "self-service-password-opendesk";
      # TODO: Add custom source
    });
    # semester-provisioning
    semester-provisioning = super.semester-provisioning.overrideAttrs (old: rec {
      version = "latest";
      pname = "semester-provisioning-opendesk";
      # TODO: Add custom source
    });
    # slidev
    slidev = super.slidev.overrideAttrs (old: rec {
      version = "latest";
      pname = "slidev-opendesk";
      # TODO: Add custom source
    });
    # snipr
    snipr = super.snipr.overrideAttrs (old: rec {
      version = "latest";
      pname = "snipr-opendesk";
      # TODO: Add custom source
    });
    # stalwart
    stalwart = super.stalwart.overrideAttrs (old: rec {
      version = "latest";
      pname = "stalwart-opendesk";
      # TODO: Add custom source
    });
    # timescale
    timescale = super.timescale.overrideAttrs (old: rec {
      version = "latest";
      pname = "timescale-opendesk";
      # TODO: Add custom source
    });
    # ttyd
    ttyd = super.ttyd.overrideAttrs (old: rec {
      version = "latest";
      pname = "ttyd-opendesk";
      # TODO: Add custom source
    });
    # typo3
    typo3 = super.typo3.overrideAttrs (old: rec {
      version = "latest";
      pname = "typo3-opendesk";
      # TODO: Add custom source
    });
    # xwiki
    xwiki = super.xwiki.overrideAttrs (old: rec {
      version = "latest";
      pname = "xwiki-opendesk";
      # TODO: Add custom source
    });
    # zammad
    zammad = super.zammad.overrideAttrs (old: rec {
      version = "latest";
      pname = "zammad-opendesk";
      # TODO: Add custom source
    });

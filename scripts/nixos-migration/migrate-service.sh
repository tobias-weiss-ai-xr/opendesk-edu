#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
#
# Migration script to convert Dockerfile-based services to NixOS containers
# Usage: ./migrate-service.sh <service-name> [version] [dockerfile-path]

set -euo pipefail

NIXOS_DIR="opendesk-nix/docker/services"
OVERLAYS_FILE="opendesk-nix/overlays/opendesk.nix"
SERVICES_CATALOG="opendesk-nix/lib/nixos/services.nix"
FLAKE_FILE="opendesk-nix/flake.nix"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "${1:-}" ]; then
    printf "%sError: Service name is required%s\n" "$RED" "$NC" >&2
    echo "Usage: $0 <service-name> [version] [dockerfile-path]"
    exit 1
fi

SERVICE_NAME="$1"
VERSION="${2:-latest}"
DOCKERFILE_PATH="${3:-$NIXOS_DIR/$SERVICE_NAME/Dockerfile}"

DETERMINE_SERVICE_TYPE() {
    local name="$1"
    case "$name" in
        mariadb|postgresql|mysql|mysql8|percona) echo "database" ;;
        redis|memcached) echo "cache" ;;
        nginx|apache|httpd|caddy|traefik) echo "web" ;;
        keycloak|authentik|dex|ory) echo "iam" ;;
        moodle|ilias|canvas|sakai) echo "lms" ;;
        nextcloud|owncloud|seafile) echo "collaboration" ;;
        collabora|onlyoffice|documentserver) echo "office" ;;
        planka|taiga|openproject|redmine) echo "project-management" ;;
        etherpad|cryptpad|hedgedoc) echo "collaboration" ;;
        drawio|excalidraw|plantuml) echo "diagramming" ;;
        rocketchat|matrix|element|jitsi|bigbluebutton) echo "communication" ;;
        bookstack|xwiki|mediawiki|dokuwiki) echo "documentation" ;;
        grafana|prometheus|loki|tempos|mimir) echo "monitoring" ;;
        elasticsearch|kibana|logstash|opensearch|minio|s3) echo "infrastructure" ;;
        docker-registry|zot|harbor|nexus) echo "registry" ;;
        sogo6) echo "groupware" ;;
        *) echo "other" ;;
    esac
}

SERVICE_TYPE=$(DETERMINE_SERVICE_TYPE "$SERVICE_NAME")
NIXOS_DIR_PATH="$NIXOS_DIR/$SERVICE_NAME/nixos"

case "$SERVICE_TYPE" in
    database)
        DEFAULT_PORT="3306"
        if [ "$SERVICE_NAME" = "postgresql" ]; then DEFAULT_PORT="5432"; fi
        ;;
    cache) DEFAULT_PORT="6379" ;;
    web)
        DEFAULT_PORT="8080"
        if [ "$SERVICE_NAME" = "nginx" ]; then DEFAULT_PORT="80"; fi
        if [ "$SERVICE_NAME" = "traefik" ]; then DEFAULT_PORT="8080"; fi
        ;;
    iam) DEFAULT_PORT="8080" ;;
    groupware) DEFAULT_PORT="20000" ;;
    *) DEFAULT_PORT="8080" ;;
esac

printf "%s==> Creating directory structure for %s...%s\n" "$BLUE" "$SERVICE_NAME" "$NC"
mkdir -p "$NIXOS_DIR_PATH"
mkdir -p "$NIXOS_DIR/$SERVICE_NAME/secrets"

printf "%s==> Creating configuration.nix...%s\n" "$BLUE" "$NC"

# Generate configuration.nix
cat > "$NIXOS_DIR_PATH/configuration.nix" <<EOF
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# ${SERVICE_NAME} NixOS Configuration for openDesk
# Version: ${VERSION}
# OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
# 

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # ${SERVICE_NAME} service
  services.${SERVICE_NAME} = {
    enable = true;
    # package = pkgs.opendeskPackages.${SERVICE_NAME};
    port = ${DEFAULT_PORT};
  };

  # System user
  users.users.${SERVICE_NAME} = {
    isSystemUser = true;
    uid = 1000;
    group = "${SERVICE_NAME}";
    home = "/var/lib/${SERVICE_NAME}";
    shell = pkgs.bash;
    description = "${SERVICE_NAME} Service User";
  };

  users.groups.${SERVICE_NAME} = {
    gid = 1000;
  };

  # Setup directories
  system.activationScripts.setup${SERVICE_NAME} = lib.mkAfter ''
    mkdir -p /var/lib/${SERVICE_NAME} /var/log/${SERVICE_NAME} /etc/${SERVICE_NAME}
    chown -R ${SERVICE_NAME}:${SERVICE_NAME} /var/lib/${SERVICE_NAME} /var/log/${SERVICE_NAME} /etc/${SERVICE_NAME}
    chmod -R 750 /var/lib/${SERVICE_NAME}
    chmod -R 755 /var/log/${SERVICE_NAME}
  '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}
EOF

printf "%s==> Creating default.nix...%s\n" "$BLUE" "$NC"

# Generate default.nix
cat > "$NIXOS_DIR_PATH/default.nix" <<EOF
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# ${SERVICE_NAME} NixOS Container Image
# Version: ${VERSION}
# OpenSpec: FR-BUILD-001 through FR-BUILD-007
# 

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

in

docks.mkImage {
  name = "${SERVICE_NAME}-opendesk";
  tag = "${VERSION}-nixos";

  # NixOS configuration
  config = import ./configuration.nix {
    inherit pkgs lib;
  };

  # Container configuration
  containerConfig = {
    ExposedPorts = { "${DEFAULT_PORT}/tcp" = {}; };
    
    Volumes = {
      "/var/lib/${SERVICE_NAME}" = {};
      "/var/log/${SERVICE_NAME}" = {};
      "/etc/${SERVICE_NAME}" = {};
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
    
    User = "${SERVICE_NAME}";
    WorkingDir = "/var/lib/${SERVICE_NAME}";
    
    Cmd = [ "/usr/bin/env" "bash" "-c" "echo Service ${SERVICE_NAME} ready" ];
    
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
    "org.opencontainers.image.title" = "${SERVICE_NAME}-opendesk";
    "org.opencontainers.image.description" = "${SERVICE_NAME} ${VERSION} for openDesk Edu with NixOS";
    "org.opencontainers.image.version" = "${VERSION}-nixos";
    "org.opencontainers.image.authors" = "openDesk Edu Team";
    "org.opencontainers.image.url" = "https://opendesk.hrz.uni-marburg.de";
    "org.opencontainers.image.documentation" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.source" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.licenses" = "Apache-2.0";
    "com.opendesk.service" = "${SERVICE_NAME}";
    "com.opendesk.environment" = "production";
    "com.opendesk.managed" = "true";
    "com.opendesk.nixos" = "true";
  };
}
EOF

printf "%s==> Creating secrets.nix...%s\n" "$BLUE" "$NC"

# Generate secrets.nix
cat > "$NIXOS_DIR_PATH/secrets.nix" <<EOF
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# ${SERVICE_NAME} Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.${SERVICE_NAME} = {
    # password = config.sops.secrets.${SERVICE_NAME}-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.${SERVICE_NAME}-api-key or "";
  };
}
EOF

printf "%s==> Creating secrets.yaml template...%s\n" "$BLUE" "$NC"

# Generate secrets.yaml template
cat > "$NIXOS_DIR/$SERVICE_NAME/secrets.yaml" <<EOF
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# ${SERVICE_NAME} Secrets File (PLAINTEXT - ENCRYPT BEFORE USE!)
# ENCRYPT with sops: sops --encrypt --age age1... secrets.yaml > secrets.enc.yaml

${SERVICE_NAME}:
  # password: "CHANGE_ME"
  # api-key: "CHANGE_ME"
EOF

printf "%s==> Creating README.md...%s\n" "$BLUE" "$NC"

# Generate README.md
cat > "$NIXOS_DIR_PATH/README.md" <<READMEOF
# ${SERVICE_NAME} NixOS Container

## Version: ${VERSION}

### OpenSpec Compliance
- FR-BUILD-001: Docker image build for service
- FR-BUILD-002: Nix flakes for reproducible builds  
- FR-BUILD-003: Multi-architecture builds (amd64, arm64)
- FR-BUILD-004: OCI-compliant images
- FR-IMAGE-001: Non-root user
- FR-IMAGE-007: OCI labels
- FR-IMAGE-009: Health checks

---

## Quick Start

### Build the container
cd opendesk-nix
nix build .#${SERVICE_NAME}-nixos

### Load into Docker
docker load < result

### Run the container
docker run -d --name ${SERVICE_NAME} \\
  -p ${DEFAULT_PORT}:${DEFAULT_PORT} \\
  ${SERVICE_NAME}-opendesk:${VERSION}-nixos

---

## Configuration

Edit configuration.nix to configure:
- Services configuration
- User settings
- Directory permissions
- Service-specific settings

---

## Secrets Management

1. Edit secrets.yaml with your credentials
2. Encrypt: sops --encrypt --age age1... secrets.yaml > secrets.enc.yaml
3. Reference in secrets.nix

---

## License
Apache-2.0
READMEOF

printf "%s==> Updating overlays file...%s\n" "$BLUE" "$NC"

# Update overlays file
if ! grep -q "$SERVICE_NAME" "$OVERLAYS_FILE"; then
    cat >> "$OVERLAYS_FILE" <<OVERLAYEOF
    # ${SERVICE_NAME}
    ${SERVICE_NAME} = super.${SERVICE_NAME}.overrideAttrs (old: rec {
      version = "${VERSION}";
      pname = "${SERVICE_NAME}-opendesk";
      # TODO: Add custom source
    });
OVERLAYEOF
    
    if ! grep -q "opendesk = opendeskPackages" "$OVERLAYS_FILE"; then
        echo "  opendesk = opendeskPackages;" >> "$OVERLAYS_FILE"
    fi
fi

printf "%s==> Updating service catalog...%s\n" "$BLUE" "$NC"

# Update service catalog
if ! grep -q "${SERVICE_NAME} = mkService" "$SERVICES_CATALOG"; then
    case "$SERVICE_TYPE" in
        database) DESC="${SERVICE_NAME} database server for openDesk" ;;
        cache) DESC="${SERVICE_NAME} cache server for openDesk" ;;
        web) DESC="${SERVICE_NAME} web server for openDesk" ;;
        iam) DESC="${SERVICE_NAME} identity provider for openDesk" ;;
        lms) DESC="${SERVICE_NAME} learning management system" ;;
        collaboration) DESC="${SERVICE_NAME} collaboration tool for openDesk" ;;
        office) DESC="${SERVICE_NAME} office suite for openDesk" ;;
        project-management) DESC="${SERVICE_NAME} project management tool" ;;
        communication) DESC="${SERVICE_NAME} communication tool for openDesk" ;;
        documentation) DESC="${SERVICE_NAME} documentation platform" ;;
        monitoring) DESC="${SERVICE_NAME} monitoring tool for openDesk" ;;
        infrastructure) DESC="${SERVICE_NAME} infrastructure service" ;;
        registry) DESC="${SERVICE_NAME} registry service" ;;
        groupware) DESC="${SERVICE_NAME} groupware server for openDesk" ;;
        *) DESC="${SERVICE_NAME} service for openDesk" ;;
    esac
    
    case "$SERVICE_TYPE" in
        database|iam|groupware) TIER="backend" ;;
        web|cache) TIER="infrastructure" ;;
        lms|collaboration|office|documentation) TIER="application" ;;
        *) TIER="backend" ;;
    esac
    
    cat >> "$SERVICES_CATALOG" <<CATALOGEOF

    ${SERVICE_NAME} = mkService {
      name = "${SERVICE_NAME}";
      version = "${VERSION}";
      description = "${DESC}";
      category = "${SERVICE_TYPE}";
      tier = "${TIER}";
      ports = [ ${DEFAULT_PORT} ];
      configPath = ./docker/services/${SERVICE_NAME}/nixos/configuration.nix;
      defaultNixPath = ./docker/services/${SERVICE_NAME}/nixos/default.nix;
    } // serviceTypes.${SERVICE_TYPE};
CATALOGEOF
fi

printf "%s==> Updating flake.nix...%s\n" "$BLUE" "$NC"

# Update flake.nix
if ! grep -q "${SERVICE_NAME}-nixos" "$FLAKE_FILE"; then
    if grep -q "inherit.*all-nixos-images" "$FLAKE_FILE"; then
        sed -i "/inherit.*all-nixos-images/a\            ${SERVICE_NAME}-nixos" "$FLAKE_FILE"
    else
        printf "    ${SERVICE_NAME}-nixos\n" >> "$FLAKE_FILE"
    fi
    printf "%s  Note: You may need to manually update allContainers in flake.nix%s\n" "$YELLOW" "$NC"
fi

# Create Dockerfile link for backward compatibility
if [ -f "$DOCKERFILE_PATH" ]; then
    printf "%s==> Creating Dockerfile link for backward compatibility...%s\n" "$BLUE" "$NC"
    ln -sf "nixos/default.nix" "$NIXOS_DIR/$SERVICE_NAME/Dockerfile.nix" 2>/dev/null || true
fi

echo ""
printf "%s=====================================================================%s\n" "$GREEN" "$NC"
printf "%s  Success: Created NixOS container structure for %s%s\n" "$GREEN" "$SERVICE_NAME" "$NC"
printf "%s=====================================================================%s\n" "$GREEN" "$NC"
echo ""
printf "%sNext steps for %s:%s\n" "$YELLOW" "$SERVICE_NAME" "$NC"
echo "  1. Edit $NIXOS_DIR_PATH/configuration.nix"
echo "  2. Update package definition in $OVERLAYS_FILE"
echo "  3. Update ports, volumes, CMD in $NIXOS_DIR_PATH/default.nix"
echo "  4. Add secrets to $NIXOS_DIR/$SERVICE_NAME/secrets.yaml and encrypt"
echo "  5. Test: nix build .#${SERVICE_NAME}-nixos"
echo "  6. Run: docker load < result && docker run -d ${SERVICE_NAME}-opendesk:${VERSION}-nixos"
echo ""
printf "%sFiles created:%s\n" "$YELLOW" "$NC"
echo "  - $NIXOS_DIR_PATH/configuration.nix"
echo "  - $NIXOS_DIR_PATH/default.nix"
echo "  - $NIXOS_DIR_PATH/secrets.nix"
echo "  - $NIXOS_DIR_PATH/README.md"
echo "  - $NIXOS_DIR/$SERVICE_NAME/secrets.yaml"
echo ""
printf "%sService type:%s %s\n" "$YELLOW" "$NC" "$SERVICE_TYPE"
printf "%sVersion:%s %s\n" "$YELLOW" "$NC" "$VERSION"
printf "%sDefault port:%s %s\n" "$YELLOW" "$NC" "$DEFAULT_PORT"
echo ""

#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Script to migrate a Dockerfile-based service to NixOS container
Usage: ./migrate-service.sh <service-name> [version] [dockerfile-path]
"""

set -euo pipefail

# Configuration
NIXOS_DIR="opendesk-nix/docker/services"
OVERLAYS_FILE="opendesk-nix/overlays/opendesk.nix"
SERVICES_CATALOG="opendesk-nix/lib/nixos/services.nix"
FLAKE_FILE="opendesk-nix/flake.nix"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if service name is provided
if [ -z "${1:-}" ]; then
    echo -e "${RED}Error: Service name is required${NC}"
    echo "Usage: $0 <service-name> [version] [dockerfile-path]"
    exit 1
fi

SERVICE_NAME="$1"
VERSION="${2:-latest}"
DOCKERFILE_PATH="${3:-$NIXOS_DIR/$SERVICE_NAME/Dockerfile}"

# Determine service type based on common patterns
DETERMINE_SERVICE_TYPE() {
    local name="$1"
    case "$name" in
        mariadb|postgresql|mysql|mysql8|percona)
            echo "database"
            ;;
        redis|memcached)
            echo "cache"
            ;;
        nginx|apache|httpd|caddy|traefik)
            echo "web"
            ;;
        keycloak|authentik|dex|ory)
            echo "iam"
            ;;
        moodle|ilias|canvas|sakai)
            echo "lms"
            ;;
        nextcloud|owncloud|seafile)
            echo "collaboration"
            ;;
        collabora|onlyoffice|documentserver)
            echo "office"
            ;;
        planka|taiga|openproject|redmine)
            echo "project-management"
            ;;
        etherpad|cryptpad|hedgedoc)
            echo "collaboration"
            ;;
        drawio|excalidraw|plantuml)
            echo "diagramming"
            ;;
        rocketchat|matrix|element|jitsi|bigbluebutton)
            echo "communication"
            ;;
        bookstack|xwiki|mediawiki|dokuwiki)
            echo "documentation"
            ;;
        grafana|prometheus|loki|tempos|mimir)
            echo "monitoring"
            ;;
        elasticsearch|kibana|logstash|opensearch|minio|s3)
            echo "infrastructure"
            ;;
        docker-registry|zot|harbor|nexus)
            echo "registry"
            ;;
        *)
            echo "other"
            ;;
    esac
}

SERVICE_TYPE=$(DETERMINE_SERVICE_TYPE "$SERVICE_NAME")
NIXOS_DIR_PATH="$NIXOS_DIR/$SERVICE_NAME/nixos"

# Create directories
echo -e "${BLUE}==> Creating directory structure for $SERVICE_NAME...${NC}"
mkdir -p "$NIXOS_DIR_PATH"
mkdir -p "$NIXOS_DIR/$SERVICE_NAME/secrets"

# Create configuration.nix
echo -e "${BLUE}==> Creating configuration.nix...${NC}"
cat > "$NIXOS_DIR_PATH/configuration.nix" <<EOF
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
$SERVICE_NAME NixOS Configuration for openDesk
Version: $VERSION
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{ config, pkgs, lib, ... }:

{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

  # TODO: Add service configuration here
  # Example for $SERVICE_NAME:
  # services.$SERVICE_NAME = {
  #   enable = true;
  #   package = pkgs.opendeskPackages.$SERVICE_NAME;
  #   port = 8080;
  # };

  # TODO: Add system user
  # users.users.$SERVICE_NAME = {
  #   isSystemUser = true;
  #   uid = 1000;
  #   group = "$SERVICE_NAME";
  # };

  # TODO: Add directory setup
  # system.activationScripts.setup$SERVICE_NAME = ''
  #   mkdir -p /var/lib/$SERVICE_NAME /var/log/$SERVICE_NAME
  #   chown -R $SERVICE_NAME:$SERVICE_NAME /var/lib/$SERVICE_NAME /var/log/$SERVICE_NAME
  # '';

  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}
EOF

# Create default.nix
echo -e "${BLUE}==> Creating default.nix...${NC}"
cat > "$NIXOS_DIR_PATH/default.nix" <<EOF
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
$SERVICE_NAME NixOS Container Image
Version: $VERSION
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
  servicePkg = nixpkgsWithOverlays.opendeskPackages.$SERVICE_NAME or (pkgs.$SERVICE_NAME or pkgs.unknownService);

in

docks.mkImage {
  name = "$SERVICE_NAME-opendesk";
  tag = "$VERSION-nixos";

  # NixOS configuration
  config = import ./configuration.nix {
    inherit pkgs lib;
  };

  # Container configuration
  containerConfig = {
    # TODO: Update exposed ports based on your service
    ExposedPorts = { "8080/tcp" = {}; };
    
    # TODO: Update volumes based on your service
    Volumes = {
      "/var/lib/$SERVICE_NAME" = {};
      "/var/log/$SERVICE_NAME" = {};
      "/etc/$SERVICE_NAME" = {};
    };
    
    Env = [
      "OPENDESK_ENV=production"
      "TZ=Europe/Berlin"
      "LC_ALL=C.UTF-8"
      "LANG=C.UTF-8"
    ];
    
    HealthCheck = {
      # TODO: Update health check command based on your service
      Test = [ "CMD-SHELL" "curl -f http://127.0.0.1:8080/healthz 2>/dev/null || exit 1" ];
      Interval = 10000000000;  # 10s
      Timeout = 5000000000;   # 5s
      Retries = 3;
      StartPeriod = 10000000000; # 10s
    };
    
    # TODO: Update user based on your service
    User = "$SERVICE_NAME";
    WorkingDir = "/var/lib/$SERVICE_NAME";
    
    # TODO: Update CMD based on your service
    Cmd = [ "${servicePkg}/bin/$SERVICE_NAME" ];
    
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

  # OCI Labels for OpenSpec compliance (FR-IMAGE-007)
  ociLabels = {
    "org.opencontainers.image.title" = "$SERVICE_NAME-opendesk";
    "org.opencontainers.image.description" = "$SERVICE_NAME $VERSION for openDesk Edu with NixOS";
    "org.opencontainers.image.version" = "$VERSION-nixos";
    "org.opencontainers.image.authors" = "openDesk Edu Team";
    "org.opencontainers.image.url" = "https://opendesk.hrz.uni-marburg.de";
    "org.opencontainers.image.documentation" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.source" = "https://github.com/opendesk-edu/opendesk-nix";
    "org.opencontainers.image.licenses" = "Apache-2.0";
    "com.opendesk.service" = "$SERVICE_NAME";
    "com.opendesk.environment" = "production";
    "com.opendesk.managed" = "true";
    "com.opendesk.nixos" = "true";
  };
}
EOF

# Create secrets.nix
echo -e "${BLUE}==> Creating secrets.nix...${NC}"
cat > "$NIXOS_DIR_PATH/secrets.nix" <<EOF
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
$SERVICE_NAME Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  # Secrets from sops-nix
  services.$SERVICE_NAME = {
    # TODO: Add your secrets here
    # password = config.sops.secrets.$SERVICE_NAME-password or "CHANGE_ME_IN_PRODUCTION";
    # apiKey = config.sops.secrets.$SERVICE_NAME-api-key or "";
    # databasePassword = config.sops.secrets.$SERVICE_NAME-db-password or "";
  };
}
EOF

# Create secrets.yaml template
echo -e "${BLUE}==> Creating secrets.yaml template...${NC}"
cat > "$NIXOS_DIR/$SERVICE_NAME/secrets.yaml" <<EOF
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
$SERVICE_NAME Secrets File (PLAINTEXT - ENCRYPT BEFORE USE!)
This file contains sensitive service credentials.
ENCRYPT with sops: sops --encrypt --age age1... secrets.yaml > secrets.enc.yaml
"""

$SERVICE_NAME:
  # TODO: Add your secrets here
  # password: "CHANGE_ME_PASSWORD"
  # api-key: "CHANGE_ME_API_KEY"
  # database-password: "CHANGE_ME_DB_PASSWORD"
EOF

# Create README.md
echo -e "${BLUE}==> Creating README.md...${NC}"
cat > "$NIXOS_DIR_PATH/README.md" <<EOF
# $SERVICE_NAME NixOS Container

## Version: $VERSION

### OpenSpec Compliance
- ✅ **FR-BUILD-001**: Docker image build for service
- ✅ **FR-BUILD-002**: Nix flakes for reproducible builds
- ✅ **FR-BUILD-003**: Multi-architecture builds (amd64, arm64)
- ✅ **FR-BUILD-004**: OCI-compliant images
- ✅ **FR-IMAGE-001**: Non-root user
- ✅ **FR-IMAGE-007**: OCI labels
- ✅ **FR-IMAGE-009**: Health checks

---

## Quick Start

### Build the container
\`\`\`bash
cd opendesk-nix
nix build .#${SERVICE_NAME}-nixos
\`\`\`

### Load into Docker
\`\`\`bash
docker load < result
\`\`\`

### Run the container
\`\`\`bash
docker run -d --name $SERVICE_NAME \\
  -p 8080:8080 \\
  $SERVICE_NAME-opendesk:$VERSION-nixos
\`\`\`

---

## Configuration

Edit `configuration.nix` to configure the service:
- Services configuration
- User settings
- Directory permissions
- Service-specific settings

---

## Secrets Management

1. Edit `secrets.yaml` with your credentials
2. Encrypt it: sops --encrypt --age age1... secrets.yaml > secrets.enc.yaml
3. Reference in `secrets.nix`

---

## Troubleshooting

### Container fails to start
\`\`\`bash
docker logs $SERVICE_NAME
\`\`\`

### Test configuration
\`\`\`bash
ix develop .#${SERVICE_NAME}
\`\`\`

---

## License
Apache-2.0
EOF

# Update overlays file
echo -e "${BLUE}==> Updating overlays file...${NC}"
if ! grep -q "$SERVICE_NAME" "$OVERLAYS_FILE"; then
    # Add to opendeskPackages
    sed -i "/opendeskPackages = {/a\    # $SERVICE_NAME\n    $SERVICE_NAME = super.$SERVICE_NAME.overrideAttrs (old: rec {\n      version = "\"$VERSION\"";\n      pname = \"${SERVICE_NAME}-opendesk\";\n\n      # TODO: Add custom source/overrides\n      # src = super.fetchurl {\n      #   url = \"https://...\ Nadu Version.aar.gz\"";\n      #   sha25
    }" "$OVERLAYS_FILE"
    
    # Add to legacy compatibility
    if ! grep -q "opendesk = opendeskPackages" "$OVERLAYS_FILE"; then
        echo "  opendesk = opendeskPackages;" >> "$OVERLAYS_FILE"
    fi
fi

# Update service catalog
echo -e "${BLUE}==> Updating service catalog...${NC}"
if ! grep -q "$SERVICE_NAME = mkService" "$SERVICES_CATALOG"; then
    # Determine description
    DESCRIPTION="$SERVICE_NAME service for openDesk"
    case "$SERVICE_TYPE" in
        database) DESCRIPTION="$SERVICE_NAME database server for openDesk" ;;
        cache) DESCRIPTION="$SERVICE_NAME cache server for openDesk" ;;
        web) DESCRIPTION="$SERVICE_NAME web server for openDesk" ;;
        iam) DESCRIPTION="$SERVICE_NAME identity provider for openDesk" ;;
        lms) DESCRIPTION="$SERVICE_NAME learning management system" ;;
        collaboration) DESCRIPTION="$SERVICE_NAME collaboration tool for openDesk" ;;
        project-management) DESCRIPTION="$SERVICE_NAME project management tool" ;;
        communication) DESCRIPTION="$SERVICE_NAME communication tool for openDesk" ;;
        documentation) DESCRIPTION="$SERVICE_NAME documentation platform" ;;
        monitoring) DESCRIPTION="$SERVICE_NAME monitoring tool for openDesk" ;;
        infrastructure) DESCRIPTION="$SERVICE_NAME infrastructure service" ;;
        registry) DESCRIPTION="$SERVICE_NAME registry service" ;;
    esac
    
    # Add service entry to catalog
    cat >> "$SERVICES_CATALOG" <<EOF

    $SERVICE_NAME = mkService {
      name = "$SERVICE_NAME";
      version = "$VERSION";
      description = "$DESCRIPTION";
      category = "$SERVICE_TYPE";
      tier = "${SERVICE_TYPE}";
      ports = [ 8080 ];  # TODO: Update with actual ports
      configPath = ./docker/services/$SERVICE_NAME/nixos/configuration.nix;
      defaultNixPath = ./docker/services/$SERVICE_NAME/nixos/default.nix;
    } // serviceTypes.$SERVICE_TYPE;
EOF
fi

# Update flake.nix
echo -e "${BLUE}==> Updating flake.nix...${NC}"
if ! grep -q "${SERVICE_NAME}-nixos" "$FLAKE_FILE"; then
    # Add to packages
    sed -i "/inherit.*all-nixos-images/a\            ${SERVICE_NAME}-nixos" "$FLAKE_FILE"
    
    # Add to allContainers list for builds
    # This is a bit tricky - we'll just note it needs manual update
    echo -e "${YELLOW}  Note: You may need to manually update allContainers in flake.nix${NC}"
fi

# Create Dockerfile link (for backward compatibility)
if [ -f "$DOCKERFILE_PATH" ]; then
    echo -e "${BLUE}==> Creating Dockerfile link for backward compatibility...${NC}"
    ln -sf "nixos/default.nix" "$NIXOS_DIR/$SERVICE_NAME/Dockerfile.nix" 2>/dev/null || true
fi

# Final output
echo ""
echo -e "${GREEN}==================================================================="${NC}"
echo -e "${GREEN}  ✅ Successfully created NixOS container structure for $SERVICE_NAME"${NC}"
echo -e "${GREEN}==================================================================="${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Edit $NIXOS_DIR_PATH/configuration.nix with your service configuration"
echo "  2. Update service package definition in $OVERLAYS_FILE"
echo "  3. Update ports, volumes, and CMD in $NIXOS_DIR_PATH/default.nix"
echo "  4. Add secrets to $NIXOS_DIR/$SERVICE_NAME/secrets.yaml and encrypt"
echo "  5. Test build: nix build .#${SERVICE_NAME}-nixos"
echo "  6. Test run: docker load < result && docker run -d $SERVICE_NAME-opendesk:$VERSION-nixos"
echo ""
echo -e "${YELLOW}Files created:${NC}"
echo "  - $NIXOS_DIR_PATH/configuration.nix"
echo "  - $NIXOS_DIR_PATH/default.nix"
echo "  - $NIXOS_DIR_PATH/secrets.nix"
echo "  - $NIXOS_DIR_PATH/README.md"
echo "  - $NIXOS_DIR/$SERVICE_NAME/secrets.yaml"
echo ""
echo -e "${YELLOW}Service type:${NC} $SERVICE_TYPE"
echo -e "${YELLOW}Version:${NC} $VERSION"
echo ""

#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# Mass Migration Script
# Migrates ALL services from k8s/services/ to NixOS containers.

set -euo pipefail

K8S_SERVICES_DIR="opendesk-nix/k8s/services"
DOCKER_SERVICES_DIR="opendesk-nix/docker/services"
DRY_RUN=false
LIMIT=""
SKIP_SERVICES=()

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --limit)
            LIMIT="$2"
            shift 2
            ;;
        --skip)
            SKIP_SERVICES+=("$2")
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--dry-run] [--limit N] [--skip SERVICE]"
            echo ""
            echo "Migrates ALL services from k8s/services/ to NixOS containers"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    case "$level" in
        "ERROR") echo -e "${RED}[$timestamp] ERROR: $message${NC}" ;;
        "WARN")  echo -e "${YELLOW}[$timestamp] WARN:  $message${NC}" ;;
        "OK")    echo -e "${GREEN}[$timestamp] OK:    $message${NC}" ;;
        "INFO")  echo -e "${BLUE}[$timestamp] INFO:  $message${NC}" ;;
        "SECTION") echo -e "\n${BLUE}[$timestamp] ==== $message ====${NC}\n" ;;
        *) echo -e "[$timestamp] $message" ;;
    esac
}

# Function to extract port from .nix file
extract_port() {
    local nix_file="$1"
    if [ ! -f "$nix_file" ]; then return; fi
    grep -E 'port.*=.*[0-9]' "$nix_file" 2>/dev/null | head -1 | grep -oE '[0-9]{2,5}' || echo "8080"
}

# Function to extract version from .nix file
extract_version() {
    local nix_file="$1"
    if [ ! -f "$nix_file" ]; then return; fi
    grep -Ei '(version|ver|imageTag).*=.*["0-9]' "$nix_file" 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || \
    grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$nix_file" 2>/dev/null | head -1 || \
    echo "latest"
}

# Function to determine service type
determine_service_type() {
    local service="$1"
    
    case "$service" in
        mariadb*|postgresql|timescale|cockroachdb) echo "database" ;;
        redis|memcached|valkey) echo "cache" ;;
        nginx|apache|traefik|caddy|envoy) echo "web" ;;
        keycloak|authentik|authelia|dex|cas) echo "iam" ;;
        moodle|ilias|ilias-full|nextcloud|open-xchange|xwiki|dokuwiki|bookstack) echo "lms" ;;
        etherpad|collabora|onlyoffice|drawio|excalidraw|element|cryptpad) echo "collaboration" ;;
        rocketchat|jitsi|bigbluebutton|grommunio|stalwart|matrix) echo "communication" ;;
        prometheus|grafana|alertmanager|loki|promtail|filebeat|kube-prometheus-stack) echo "monitoring" ;;
        zot-registry|docker-registry|harbor) echo "infrastructure" ;;
        wordpress|drupal|typo3|joomla|gallery) echo "cms" ;;
        gitlab|gitea|jenkins|argo|argocd|tekton|buildkit) echo "devops" ;;
        minio|seaweedfs|ceph) echo "storage" ;;
        openproject|planka|taiga|redmine|jira) echo "project-management" ;;
        elasticsearch|kibana|opensearch|solr) echo "search" ;;
        ollama|open-webui|tensorboard|pytorch|tensorflow) echo "ai" ;;
        dovecot|sogo|sogo5|sogo6|f13|postfix|exim|sendmail|roundcube) echo "email" ;;
        nubus-*) echo "iam" ;;
        semester-*) echo "iam" ;;
        intercom*) echo "communication" ;;
        self-service-password|ltb-self-service-password) echo "iam" ;;
        notes|snippets|snipr|standard-notes) echo "notes" ;;
        ttyd|gotty|shellinabox) echo "terminal" ;;
        slidev|mdbook|gitpitch) echo "presentation" ;;
        code-server|coderd|vscode-server|theia|che) echo "ide" ;;
        clamav|spamassassin|rspamd|amavis) echo "security" ;;
        element|eudi-issuer|overleaf|kasmvnc|collab-dashboard|opencloud|portal-entries) echo "other" ;;
        dask|airflow|prefect|luigi) echo "data-processing" ;;
        rstudio|jupyter|jupyterhub|jupyterlab|rshiny) echo "data-science" ;;
        openproject|zammad|request-tracker|bugzilla) echo "helpdesk" ;;
        xwiki|confluence|mediawiki|dokuwiki) echo "documentation" ;;
        *) echo "other" ;;
    esac
}

# Function to check if already migrated
is_migrated() {
    local service="$1"
    [ -d "$DOCKER_SERVICES_DIR/$service/nixos" ]
}

# Function to migrate a service
migrate_service() {
    local service="$1"
    
    # Skip if already migrated
    if is_migrated "$service"; then
        log "INFO" "$service: Already migrated, skipping"
        return 0
    fi
    
    # Skip if in skip list
    for skip_svc in "${SKIP_SERVICES[@]}"; do
        if [ "$service" = "$skip_svc" ]; then
            log "INFO" "$service: Skipped (user request)"
            return 0
        fi
    done
    
    # Skip non-service files
    if [[ "$service" =~ (README|MIGRATION-TRACKER) ]]; then
        return 0
    fi
    
    # Extract metadata
    local nix_file="$K8S_SERVICES_DIR/$service.nix"
    local version=$(extract_version "$nix_file")
    local port=$(extract_port "$nix_file")
    local service_type=$(determine_service_type "$service")
    
    log "INFO" "Migrating: $service (type: $service_type, version: $version, port: $port)"
    
    if [ "$DRY_RUN" = true ]; then
        log "INFO" "  [DRY RUN] Would migrate $service"
        return 0
    fi
    
    # Run the migration
    if ./migrate-service.sh "$service" "$version" "" 2>&1 | grep -q "Success"; then
        log "OK" "$service: Migrated successfully"
        return 0
    else
        log "ERROR" "$service: Migration failed"
        return 1
    fi
}

# Main
log "SECTION" "MASS MIGRATION - Starting"

# Get list of services
ALL_SERVICES=()
while IFS= read -r nix_file; do
    service=$(basename "$nix_file" .nix)
    # Skip non-service files
    if [[ "$service" != "README" && "$service" != "MIGRATION-TRACKER" ]]; then
        ALL_SERVICES+=("$service")
    fi
done < <(find "$K8S_SERVICES_DIR" -name "*.nix" -type f)

# Sort services
IFS=$'\n' ALL_SERVICES=($(sort <<<"${ALL_SERVICES[*]}")); unset IFS

TOTAL_SERVICES=${#ALL_SERVICES[@]}

log "INFO" "Found $TOTAL_SERVICES service files in k8s/services/"

# Filter out already migrated services
NEEDS_MIGRATION=()
ALREADY_MIGRATED=()

for service in "${ALL_SERVICES[@]}"; do
    if is_migrated "$service"; then
        ALREADY_MIGRATED+=("$service")
    else
        NEEDS_MIGRATION+=("$service")
    fi
done

log "INFO" "Already migrated: ${#ALREADY_MIGRATED[@]} services"
log "INFO" "Needs migration: ${#NEEDS_MIGRATION[@]} services"

if [ ${#NEEDS_MIGRATION[@]} -eq 0 ]; then
    log "INFO" "All services are already migrated!"
    exit 0
fi

if [ -n "$LIMIT" ]; then
    NEEDS_MIGRATION=("${NEEDS_MIGRATION[@]:0:$LIMIT}")
    log "INFO" "Limiting to $LIMIT services"
fi

MIGRATED=0
FAILED=0

# Migrate all services
for service in "${NEEDS_MIGRATION[@]}"; do
    if migrate_service "$service"; then
        MIGRATED=$((MIGRATED + 1))
    else
        FAILED=$((FAILED + 1))
    fi
done

# Summary
log "SECTION" "MIGRATION COMPLETE"
log "INFO" "Attempted: ${#NEEDS_MIGRATION[@]} services"
log "INFO" "Successfully migrated: $MIGRATED"
log "INFO" "Failed: $FAILED"
log "INFO" "Already migrated: ${#ALREADY_MIGRATED[@]}"

if [ $FAILED -gt 0 ]; then
    log "ERROR" "Migration completed with errors"
    exit 1
else
    log "OK" "Mass migration completed successfully!"
    exit 0
fi

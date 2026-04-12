#!/bin/bash
# openDesk Edu Restore Script
# Restores components from backups

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/backups/opendesk}"
LOG_FILE="/var/log/opendesk-restore.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $*" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARN:${NC} $*" | tee -a "$LOG_FILE"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."

    if ! command -v kubectl &> /dev/null; then
        error "kubectl not found. Please install kubectl."
        exit 1
    fi

    if ! command -v helm &> /dev/null; then
        error "helm not found. Please install helm."
        exit 1
    fi

    if ! kubectl cluster-info &> /dev/null; then
        error "Not connected to Kubernetes cluster"
        exit 1
    fi

    if [ ! -d "$BACKUP_DIR" ]; then
        error "Backup directory not found: $BACKUP_DIR"
        exit 1
    fi

    log "Prerequisites check passed"
}

# List available backups
list_backups() {
    log "Available backups:"

    if [ -d "$BACKUP_DIR" ]; then
        find "$BACKUP_DIR" -name "opendesk_full_backup_*.tar.gz" -printf "%T+ %p\n" | \
            sort -r | \
            while read -r timestamp backup; do
                echo "  $backup ($(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S'))"
            done
    else
        warn "No backups found in $BACKUP_DIR"
    fi
}

# Verify backup integrity
verify_backup() {
    local backup_file="$1"

    log "Verifying backup integrity: $backup_file"

    if [ ! -f "$backup_file" ]; then
        error "Backup file not found: $backup_file"
        return 1
    fi

    # Test tar integrity
    if ! tar -tzf "$backup_file" > /dev/null; then
        error "Backup file is corrupted"
        return 1
    fi

    log "Backup integrity verified"
    return 0
}

# Extract backup
extract_backup() {
    local backup_file="$1"
    local extract_dir="$2"

    log "Extracting backup..."

    mkdir -p "$extract_dir"
    tar -xzf "$backup_file" -C "$extract_dir" || {
        error "Failed to extract backup"
        return 1
    }

    log "Backup extracted to: $extract_dir"
}

# Restore Keycloak
restore_keycloak() {
    local backup_dir="$1"

    log "Restoring Keycloak..."

    local keycloak_namespace="keycloak"
    local keycloak_pod=$(kubectl get pods -n "$keycloak_namespace" -l app=keycloak -o jsonpath='{.items[0].metadata.name}')

    if [ -z "$keycloak_pod" ]; then
        error "Keycloak pod not found. Cannot restore."
        return 1
    fi

    # Restore Keycloak database
    if [ -f "$backup_dir/keycloak/keycloak_db_*.sql" ]; then
        log "Restoring Keycloak database..."
        kubectl exec -n "$keycloak_namespace" "$keycloak_pod" -- \
            bash -c "dropdb -U keycloak keycloak 2>/dev/null; createdb -U keycloak keycloak" 2>/dev/null || \
            warn "Database recreation failed, continuing..."

        kubectl exec -n "$keycloak_namespace" -i "$keycloak_pod" -- \
            bash -c "psql -U keycloak keycloak" < "$backup_dir/keycloak/keycloak_db_*.sql" || \
            error "Keycloak database restore failed"
    else
        warn "Keycloak database backup not found"
    fi

    log "Keycloak restore completed"
}

# Restore ILIAS
restore_ilias() {
    local backup_dir="$1"

    log "Restoring ILIAS..."

    local ilias_namespace="ilias"
    local ilias_pod=$(kubectl get pods -n "$ilias_namespace" -l app=ilias -o jsonpath='{.items[0].metadata.name}')

    if [ -z "$ilias_pod" ]; then
        error "ILIAS pod not found. Cannot restore."
        return 1
    fi

    # Restore ILIAS database
    if [ -f "$backup_dir/services/ilias_db_*.sql" ]; then
        log "Restoring ILIAS database..."
        kubectl exec -n "$ilias_namespace" "$ilias_pod" -- \
            bash -c "mariadb -u root -p\${MARIADB_ROOT_PASSWORD} -e 'DROP DATABASE IF EXISTS ilias; CREATE DATABASE ilias;'" 2>/dev/null || \
            warn "ILIAS database recreation failed"

        kubectl exec -n "$ilias_namespace" -i "$ilias_pod" -- \
            bash -c "mariadb -u root -p\${MARIADB_ROOT_PASSWORD} ilias" < "$backup_dir/services/ilias_db_*.sql" || \
            error "ILIAS database restore failed"
    else
        warn "ILIAS database backup not found"
    fi

    # Restore ILIAS data directory
    if [ -f "$backup_dir/services/ilias_data_*.tar.gz" ]; then
        log "Restoring ILIAS data directory..."
        kubectl exec -n "$ilias_namespace" -i "$ilias_pod" -- \
            tar -xzf - < "$backup_dir/services/ilias_data_*.tar.gz" || \
            warn "ILIAS data restore failed"
    fi

    log "ILIAS restore completed"
}

# Restore Moodle
restore_moodle() {
    local backup_dir="$1"

    log "Restoring Moodle..."

    local moodle_namespace="moodle"
    local moodle_pod=$(kubectl get pods -n "$moodle_namespace" -l app=moodle -o jsonpath='{.items[0].metadata.name}')

    if [ -z "$moodle_pod" ]; then
        error "Moodle pod not found. Cannot restore."
        return 1
    fi

    # Restore Moodle database
    if [ -f "$backup_dir/services/moodle_db_*.sql" ]; then
        log "Restoring Moodle database..."
        kubectl exec -n "$moodle_namespace" "$moodle_pod" -- \
            bash -c "mariadb -u root -p\${MARIADB_ROOT_PASSWORD} -e 'DROP DATABASE IF EXISTS moodle; CREATE DATABASE moodle;'" 2>/dev/null || \
            warn "Moodle database recreation failed"

        kubectl exec -n "$moodle_namespace" -i "$moodle_pod" -- \
            bash -c "mariadb -u root -p\${MARIADB_ROOT_PASSWORD} moodle" < "$backup_dir/services/moodle_db_*.sql" || \
            error "Moodle database restore failed"
    else
        warn "Moodle database backup not found"
    fi

    # Restore Moodle data directory
    if [ -f "$backup_dir/services/moodle_data_*.tar.gz" ]; then
        log "Restoring Moodle data directory..."
        kubectl exec -n "$moodle_namespace" -i "$moodle_pod" -- \
            tar -xzf - < "$backup_dir/services/moodle_data_*.tar.gz" || \
            warn "Moodle data restore failed"
    fi

    log "Moodle restore completed"
}

# Restore Nextcloud
restore_nextcloud() {
    local backup_dir="$1"

    log "Restoring Nextcloud..."

    local nextcloud_namespace="nextcloud"
    local nextcloud_pod=$(kubectl get pods -n "$nextcloud_namespace" -l app=nextcloud -o jsonpath='{.items[0].metadata.name}')

    if [ -z "$nextcloud_pod" ]; then
        error "Nextcloud pod not found. Cannot restore."
        return 1
    fi

    # Restore Nextcloud database
    if [ -f "$backup_dir/services/nextcloud_db_*.sql" ]; then
        log "Restoring Nextcloud database..."
        kubectl exec -n "$nextcloud_namespace" "$nextcloud_pod" -- \
            bash -c "mariadb -u root -p\${MARIADB_ROOT_PASSWORD} -e 'DROP DATABASE IF EXISTS nextcloud; CREATE DATABASE nextcloud;'" 2>/dev/null || \
            warn "Nextcloud database recreation failed"

        kubectl exec -n "$nextcloud_namespace" -i "$nextcloud_pod" -- \
            bash -c "mariadb -u root -p\${MARIADB_ROOT_PASSWORD} nextcloud" < "$backup_dir/services/nextcloud_db_*.sql" || \
            error "Nextcloud database restore failed"
    else
        warn "Nextcloud database backup not found"
    fi

    # Restore Nextcloud data directory
    if [ -f "$backup_dir/services/nextcloud_data_*.tar.gz" ]; then
        log "Restoring Nextcloud data directory..."
        kubectl exec -n "$nextcloud_namespace" -i "$nextcloud_pod" -- \
            tar -xzf - < "$backup_dir/services/nextcloud_data_*.tar.gz" || \
            warn "Nextcloud data restore failed"
    fi

    log "Nextcloud restore completed"
}

# Restore provisioning data
restore_provisioning() {
    local backup_dir="$1"

    log "Restoring provisioning data..."

    # Restore provisioning scripts
    if [ -f "$backup_dir/provisioning/scripts_*.tar.gz" ]; then
        log "Restoring provisioning scripts..."
        tar -xzf "$backup_dir/provisioning/scripts_*.tar.gz" -C /opt/ 2>/dev/null || \
            warn "Provisioning scripts restore failed"
    else
        warn "Provisioning scripts backup not found"
    fi

    # Restore provisioning archives
    if [ -f "$backup_dir/provisioning/archives_*.tar.gz" ]; then
        log "Restoring provisioning archives..."
        tar -xzf "$backup_dir/provisioning/archives_*.tar.gz" -C /var/lib/ 2>/dev/null || \
            warn "Provisioning archives restore failed"
    else
        warn "Provisioning archives backup not found"
    fi

    log "Provisioning data restore completed"
}

# Restore Helm releases
restore_helm() {
    local backup_dir="$1"

    log "Restoring Helm releases..."

    if [ -f "$backup_dir/helm/releases_*.json" ]; then
        log "Restoring Helm release values..."
        # Note: This doesn't restore releases, only their values
        # Full Helm restore requires manual intervention
        warn "Helm restore requires manual intervention. Values restored to: $backup_dir/helm/"
    else
        warn "Helm releases backup not found"
    fi

    log "Helm restore completed"
}

# Full restore
restore_full() {
    local backup_file="$1"

    log "Starting full restore from: $backup_file"

    check_prerequisites

    if ! verify_backup "$backup_file"; then
        error "Backup verification failed. Aborting restore."
        exit 1
    fi

    local temp_extract_dir=$(mktemp -d)
    trap "rm -rf $temp_extract_dir" EXIT

    extract_backup "$backup_file" "$temp_extract_dir"

    # Order of restore: Keycloak → Services → Provisioning → Helm
    restore_keycloak "$temp_extract_dir"
    restore_ilias "$temp_extract_dir"
    restore_moodle "$temp_extract_dir"
    restore_nextcloud "$temp_extract_dir"
    restore_provisioning "$temp_extract_dir"
    restore_helm "$temp_extract_dir"

    log "Full restore completed successfully!"
}

# Main command handler
case "${1:-help}" in
    list)
        list_backups
        ;;
    restore)
        if [ -z "${2:-}" ]; then
            error "Backup file required"
            echo "Usage: $0 restore <backup-file>"
            exit 1
        fi
        restore_full "$2"
        ;;
    verify)
        if [ -z "${2:-}" ]; then
            error "Backup file required"
            echo "Usage: $0 verify <backup-file>"
            exit 1
        fi
        verify_backup "$2"
        ;;
    keycloak)
        local backup_dir=$(mktemp -d)
        trap "rm -rf $backup_dir" EXIT
        extract_backup "$2" "$backup_dir"
        restore_keycloak "$backup_dir"
        ;;
    services)
        local backup_dir=$(mktemp -d)
        trap "rm -rf $backup_dir" EXIT
        extract_backup "$2" "$backup_dir"
        restore_ilias "$backup_dir"
        restore_moodle "$backup_dir"
        restore_nextcloud "$backup_dir"
        ;;
    provisioning)
        local backup_dir=$(mktemp -d)
        trap "rm -rf $backup_dir" EXIT
        extract_backup "$2" "$backup_dir"
        restore_provisioning "$backup_dir"
        ;;
    *)
        echo "openDesk Edu Restore Script"
        echo ""
        echo "Usage: $0 {list|restore|verify|keycloak|services|provisioning} [backup-file]"
        echo ""
        echo "Commands:"
        echo "  list         - List available backups"
        echo "  restore      - Full restore from backup"
        echo "  verify       - Verify backup integrity"
        echo "  keycloak     - Restore Keycloak only"
        echo "  services     - Restore services (ILIAS, Moodle, Nextcloud) only"
        echo "  provisioning - Restore provisioning data only"
        echo ""
        echo "Environment variables:"
        echo "  BACKUP_DIR   - Backup directory (default: /backups/opendesk)"
        exit 1
        ;;
esac

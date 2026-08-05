#!/bin/bash
# openDesk Edu Backup Script
# Backs up all components: Keycloak, services, provisioning data

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/backups/opendesk}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/opendesk-backup.log"

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

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        error "kubectl not found. Please install kubectl."
        exit 1
    fi

    # Check helm
    if ! command -v helm &> /dev/null; then
        error "helm not found. Please install helm."
        exit 1
    fi

    # Check kubectl context
    if ! kubectl cluster-info &> /dev/null; then
        error "Not connected to Kubernetes cluster"
        exit 1
    fi

    log "Prerequisites check passed"
}

# Create backup directory
setup_backup_dir() {
    log "Setting up backup directory..."
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$BACKUP_DIR/keycloak"
    mkdir -p "$BACKUP_DIR/services"
    mkdir -p "$BACKUP_DIR/provisioning"
    mkdir -p "$BACKUP_DIR/helm"
}

# Backup Keycloak
backup_keycloak() {
    log "Backing up Keycloak..."

    local keycloak_namespace="keycloak"
    local keycloak_pod=$(kubectl get pods -n "$keycloak_namespace" -l app=keycloak -o jsonpath='{.items[0].metadata.name}')

    if [ -z "$keycloak_pod" ]; then
        warn "Keycloak pod not found, skipping Keycloak backup"
        return
    fi

    # Export Keycloak realm configuration
    kubectl exec -n "$keycloak_namespace" "$keycloak_pod" -- \
        /opt/keycloak/bin/kcadm.sh \
        realms get \
        --server http://localhost:8080/auth \
        --realm master \
        --user admin \
        --password "${KEYCLOAK_ADMIN_PASSWORD:-admin}" \
        --output json > "$BACKUP_DIR/keycloak/realms_${TIMESTAMP}.json" 2>/dev/null || \
        warn "Keycloak realm export failed"

    # Backup Keycloak database
    kubectl exec -n "$keycloak_namespace" "$keycloak_pod" -- \
        bash -c "pg_dump -U keycloak keycloak" > "$BACKUP_DIR/keycloak/keycloak_db_${TIMESTAMP}.sql" 2>/dev/null || \
        warn "Keycloak database backup failed"

    log "Keycloak backup completed"
}

# Backup ILIAS
backup_ilias() {
    log "Backing up ILIAS..."

    local ilias_namespace="ilias"
    local ilias_pod=$(kubectl get pods -n "$ilias_namespace" -l app=ilias -o jsonpath='{.items[0].metadata.name}')

    if [ -z "$ilias_pod" ]; then
        warn "ILIAS pod not found, skipping ILIAS backup"
        return
    fi

    # Backup ILIAS database
    kubectl exec -n "$ilias_namespace" "$ilias_pod" -- \
        bash -c "mariadb-dump -u root -p\${MARIADB_ROOT_PASSWORD} ilias" > "$BACKUP_DIR/services/ilias_db_${TIMESTAMP}.sql" 2>/dev/null || \
        warn "ILIAS database backup failed"

    # Backup ILIAS data directory
    kubectl exec -n "$ilias_namespace" "$ilias_pod" -- \
        tar -czf - /var/www/html/data > "$BACKUP_DIR/services/ilias_data_${TIMESTAMP}.tar.gz" 2>/dev/null || \
        warn "ILIAS data backup failed"

    log "ILIAS backup completed"
}

# Backup Moodle
backup_moodle() {
    log "Backing up Moodle..."

    local moodle_namespace="moodle"
    local moodle_pod=$(kubectl get pods -n "$moodle_namespace" -l app=moodle -o jsonpath='{.items[0].metadata.name}')

    if [ -z "$moodle_pod" ]; then
        warn "Moodle pod not found, skipping Moodle backup"
        return
    fi

    # Backup Moodle database
    kubectl exec -n "$moodle_namespace" "$moodle_pod" -- \
        bash -c "mariadb-dump -u root -p\${MARIADB_ROOT_PASSWORD} moodle" > "$BACKUP_DIR/services/moodle_db_${TIMESTAMP}.sql" 2>/dev/null || \
        warn "Moodle database backup failed"

    # Backup Moodle data directory
    kubectl exec -n "$moodle_namespace" "$moodle_pod" -- \
        tar -czf - /var/www/html/moodledata > "$BACKUP_DIR/services/moodle_data_${TIMESTAMP}.tar.gz" 2>/dev/null || \
        warn "Moodle data backup failed"

    log "Moodle backup completed"
}

# Backup Nextcloud
backup_nextcloud() {
    log "Backing up Nextcloud..."

    local nextcloud_namespace="nextcloud"
    local nextcloud_pod=$(kubectl get pods -n "$nextcloud_namespace" -l app=nextcloud -o jsonpath='{.items[0].metadata.name}')

    if [ -z "$nextcloud_pod" ]; then
        warn "Nextcloud pod not found, skipping Nextcloud backup"
        return
    fi

    # Backup Nextcloud database
    kubectl exec -n "$nextcloud_namespace" "$nextcloud_pod" -- \
        bash -c "mariadb-dump -u root -p\${MARIADB_ROOT_PASSWORD} nextcloud" > "$BACKUP_DIR/services/nextcloud_db_${TIMESTAMP}.sql" 2>/dev/null || \
        warn "Nextcloud database backup failed"

    # Backup Nextcloud data directory
    kubectl exec -n "$nextcloud_namespace" "$nextcloud_pod" -- \
        tar -czf - /var/www/html/data > "$BACKUP_DIR/services/nextcloud_data_${TIMESTAMP}.tar.gz" 2>/dev/null || \
        warn "Nextcloud data backup failed"

    log "Nextcloud backup completed"
}

# Backup provisioning data
backup_provisioning() {
    log "Backing up provisioning data..."

    # Backup provisioning scripts configuration
    tar -czf "$BACKUP_DIR/provisioning/scripts_${TIMESTAMP}.tar.gz" \
        /opt/opendesk-edu/scripts/ 2>/dev/null || \
        warn "Provisioning scripts backup failed"

    # Backup provisioning archives
    tar -czf "$BACKUP_DIR/provisioning/archives_${TIMESTAMP}.tar.gz" \
        /var/lib/opendesk-archives/ 2>/dev/null || \
        warn "Provisioning archives backup failed"

    # Backup provisioning logs
    tar -czf "$BACKUP_DIR/provisioning/logs_${TIMESTAMP}.tar.gz" \
        /var/log/opendesk-* 2>/dev/null || \
        warn "Provisioning logs backup failed"

    log "Provisioning data backup completed"
}

# Backup Helm charts state
backup_helm() {
    log "Backing up Helm releases..."

    # List all helm releases
    helm list --all-namespaces -o json > "$BACKUP_DIR/helm/releases_${TIMESTAMP}.json" 2>/dev/null || \
        warn "Helm releases backup failed"

    # Get Helm values for each release
    helm list --all-namespaces --output json | \
        jq -r '.[] | "\(.namespace) \(.name)"' | while read -r namespace name; do
            helm get values "$name" -n "$namespace" > "$BACKUP_DIR/helm/${name}_${namespace}_${TIMESTAMP}.yaml" 2>/dev/null || \
                warn "Helm values backup failed for $name in $namespace"
        done

    log "Helm backup completed"
}

# Backup Kubernetes PVCs
backup_pvcs() {
    log "Backing up PVC manifests..."

    kubectl get pvc --all-namespaces -o yaml > "$BACKUP_DIR/pvcs_${TIMESTAMP}.yaml" 2>/dev/null || \
        warn "PVC backup failed"

    log "PVC backup completed"
}

# Create backup summary
create_summary() {
    log "Creating backup summary..."

    cat > "$BACKUP_DIR/backup_summary_${TIMESTAMP}.txt" << EOF
openDesk Edu Backup Summary
=========================
Timestamp: $(date)
Backup ID: ${TIMESTAMP}

Components Backed Up:
- Keycloak: $(test -f "$BACKUP_DIR/keycloak/keycloak_db_${TIMESTAMP}.sql" && echo "YES" || echo "NO")
- ILIAS: $(test -f "$BACKUP_DIR/services/ilias_db_${TIMESTAMP}.sql" && echo "YES" || echo "NO")
- Moodle: $(test -f "$BACKUP_DIR/services/moodle_db_${TIMESTAMP}.sql" && echo "YES" || echo "NO")
- Nextcloud: $(test -f "$BACKUP_DIR/services/nextcloud_db_${TIMESTAMP}.sql" && echo "YES" || echo "NO")
- Provisioning Data: $(test -f "$BACKUP_DIR/provisioning/scripts_${TIMESTAMP}.tar.gz" && echo "YES" || echo "NO")
- Helm Releases: $(test -f "$BACKUP_DIR/helm/releases_${TIMESTAMP}.json" && echo "YES" || echo "NO")
- PVCs: $(test -f "$BACKUP_DIR/pvcs_${TIMESTAMP}.yaml" && echo "YES" || echo "NO")

Backup Location: $BACKUP_DIR
Retention: ${BACKUP_RETENTION_DAYS} days

EOF

    log "Backup summary created"
}

# Cleanup old backups
cleanup_old_backups() {
    log "Cleaning up old backups (older than ${BACKUP_RETENTION_DAYS} days)..."

    find "$BACKUP_DIR" -name "*_*" -mtime +$BACKUP_RETENTION_DAYS -delete 2>/dev/null || \
        warn "Cleanup of old backups failed"

    log "Cleanup completed"
}

# Create compressed archive
compress_backup() {
    log "Compressing backup..."

    local backup_archive="${BACKUP_DIR}/opendesk_full_backup_${TIMESTAMP}.tar.gz"

    tar -czf "$backup_archive" \
        -C "$BACKUP_DIR" \
        --exclude="*.tar.gz" \
        --exclude="backup_summary_*" \
        . 2>/dev/null || \
        error "Backup compression failed"

    log "Backup compressed: ${backup_archive}"

    # Calculate backup size
    local backup_size=$(du -h "$backup_archive" | cut -f1)
    log "Backup size: ${backup_size}"
}

# Main backup function
run_backup() {
    log "Starting openDesk Edu backup..."
    log "Backup ID: ${TIMESTAMP}"

    check_prerequisites
    setup_backup_dir

    backup_keycloak
    backup_ilias
    backup_moodle
    backup_nextcloud
    backup_provisioning
    backup_helm
    backup_pvcs

    create_summary
    compress_backup
    cleanup_old_backups

    log "Backup completed successfully!"
    log "Backup location: ${BACKUP_DIR}/opendesk_full_backup_${TIMESTAMP}.tar.gz"
}

# Incremental backup
run_incremental_backup() {
    log "Starting incremental backup..."

    # For incremental backup, we use rsync to copy only changed files
    local rsync_backup="${BACKUP_DIR}/incremental/${TIMESTAMP}"
    mkdir -p "$rsync_backup"

    # Backup provisioning data incrementally
    rsync -av --delete /opt/opendesk-edu/scripts/ "$rsync_backup/scripts/" 2>/dev/null || \
        warn "Incremental scripts backup failed"

    rsync -av --delete /var/lib/opendesk-archives/ "$rsync_backup/archives/" 2>/dev/null || \
        warn "Incremental archives backup failed"

    log "Incremental backup completed: ${rsync_backup}"
}

# Command line arguments
case "${1:-full}" in
    full)
        run_backup
        ;;
    incremental)
        run_incremental_backup
        ;;
    keycloak)
        check_prerequisites
        setup_backup_dir
        backup_keycloak
        ;;
    services)
        check_prerequisites
        setup_backup_dir
        backup_ilias
        backup_moodle
        backup_nextcloud
        ;;
    provisioning)
        backup_provisioning
        ;;
    cleanup)
        cleanup_old_backups
        ;;
    *)
        echo "Usage: $0 {full|incremental|keycloak|services|provisioning|cleanup}"
        echo ""
        echo "  full         - Full backup of all components"
        echo "  incremental  - Incremental backup of changed files only"
        echo "  keycloak     - Backup Keycloak only"
        echo "  services     - Backup services (ILIAS, Moodle, Nextcloud) only"
        echo "  provisioning - Backup provisioning data only"
        echo "  cleanup      - Clean up old backups"
        exit 1
        ;;
esac

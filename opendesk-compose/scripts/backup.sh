#!/bin/sh
set -e

# openDesk Backup Script
# Automates backup of all service volumes
#
# Usage:
#   ./backup.sh                    # Full backup
#   ./backup.sh --dry-run          # Show what would be backed up
#   ./backup.sh --services <list>  # Backup specific services only
#
# Configuration: Read from .backup.env

# Read backup configuration
if [ -f .backup.env ]; then
  . .backup.env
fi

COMPOSE_PROJECT="${COMPOSE_PROJECT_NAME:-opendesk-compose}"

# Parse arguments
DRY_RUN=false
SERVICES=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --services)
      shift
      SERVICES="$1"
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--dry-run] [--services service1,service2,...]"
      exit 1
      ;;
  esac
done

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="backups"
BACKUP_FILE="${BACKUP_DIR}/backup-${TIMESTAMP}.tar.gz"

VOLUMES=(
  "pgdata"
  "keycloak_data"
  "opencloud_data"
  "synapse_data"
  "notes_data"
  "mox_data"
  "sogo_data"
  "traefik-acme"
)

BACKUP_VOLS=()
if [ -z "$SERVICES" ]; then
  BACKUP_VOLS=("${VOLUMES[@]}")
else
  # shellcheck disable=SC2086
  for vol in $(echo "$SERVICES" | tr ',' ' '); do
    found=false
    for v in "${VOLUMES[@]}"; do
      if [ "$v" = "${vol}_data" ] || [ "$v" = "$vol" ]; then
        BACKUP_VOLS+=("$v")
        found=true
        break
      fi
    done
    if [ "$found" = false ]; then
      echo "Error: Unknown volume '$vol'"
      exit 1
    fi
  done
fi

if [ ${#BACKUP_VOLS[@]} -eq 0 ]; then
  echo "No volumes to backup"
  exit 1
fi

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN - What would be backed up:"
  echo "Backup file: $BACKUP_FILE"
  echo "Volumes to backup:"
  for vol in "${BACKUP_VOLS[@]}"; do
    echo "  - $vol"
  done
  echo ""
  echo "Backup size estimate: ~$(docker run --rm -v ${COMPOSE_PROJECT}_${BACKUP_VOLS[0]}:/data alpine:3.20 du -sh /data 2>/dev/null | cut -f1 || echo 'unknown')"
  exit 0
fi

echo "Stopping services for consistent backup..."
docker-compose stop

sleep 10

mkdir -p "$BACKUP_DIR"

# Save a combined manifest of volumes backed up
MANIFEST_FILE="${BACKUP_DIR}/backup-${TIMESTAMP}.txt"
: > "$MANIFEST_FILE"
for vol in "${BACKUP_VOLS[@]}"; do
  echo "$vol" >> "$MANIFEST_FILE"
done

PARTIAL_DIR="${BACKUP_DIR}/partial-${TIMESTAMP}"
mkdir -p "$PARTIAL_DIR"

for vol in "${BACKUP_VOLS[@]}"; do
  echo "  Backing up $vol..."
  docker run --rm \
    -v "${COMPOSE_PROJECT}_${vol}:/data" \
    -v "$(pwd)/${PARTIAL_DIR}:/backups" \
    alpine:3.20 \
    tar czf "/backups/${vol}.tar.gz" -C /data .
done

echo "Combining backups..."
find "$PARTIAL_DIR" -name '*.tar.gz' -not -name 'combined-*.tar.gz' | sort | while read -r part; do
  cat "$part"
done > "$BACKUP_FILE"
rm -rf "$PARTIAL_DIR"

BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

echo "Restarting services..."
docker-compose up -d

sleep 30

echo ""
echo "Backup completed successfully!"
echo "File: $BACKUP_FILE"
echo "Size: $BACKUP_SIZE"
echo "Timestamp: $(date)"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Backup completed: $BACKUP_FILE ($BACKUP_SIZE)" >> "${BACKUP_DIR}/backup.log"

find "$BACKUP_DIR" -name "backup-*.tar.gz" -type f -mtime +7 -delete

echo ""
echo "Backup retention policy: Keeping last 7 days"
echo "Run './backup.sh' to perform another backup."

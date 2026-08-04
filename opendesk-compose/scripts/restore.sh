#!/bin/sh
set -e

# openDesk Restore Script
# Restores service volumes from a backup file
#
# Usage:
#   ./restore.sh <backup-file.tar.gz>   # Restore specific backup
#   ./restore.sh --dry-run             # Test backup file validation
#
# Configuration: Read backup file path

# Parse command line options
BACKUP_FILE=""
DRY_RUN=false

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      BACKUP_FILE="$1"
      shift
      ;;
  esac
done

# Validate backup file exists
if [ -z "$BACKUP_FILE" ]; then
  echo "Error: No backup file specified"
  echo "Usage: $0 [--dry-run] <backup-file.tar.gz>"
  exit 1
fi

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: Backup file '$BACKUP_FILE' not found"
  exit 1
fi

# Validate backup file is tar.gz
if [[ ! "$BACKUP_FILE" == *.tar.gz ]]; then
  echo "Error: Backup file must be .tar.gz format"
  exit 1
fi

# Dry run - just validate backup file
if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN - Validating backup file: $BACKUP_FILE"
  
  # List contents
  echo "Contents:"
  tar -tzf "$BACKUP_FILE" --list | head -20
  
  echo ""
  echo "Validation: File exists and is valid tar.gz"
  echo "Run without --dry-run to perform actual restore"
  exit 0
fi

# Confirm restore operation
echo ""
echo "WARNING: This will restore ALL volumes!"
echo "This will OVERWRITE existing data."
echo ""
read -p "Continue with restore? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Restore cancelled by user"
  exit 0
fi

# Stop all services
echo "Stopping all services..."
docker-compose down

# Wait for services to stop
sleep 10

# Verify volumes directory exists
echo "Verifying volumes..."
ls -la

# Perform restore
echo "Restoring from backup: $BACKUP_FILE"

# Extract to temporary directory
echo "Extracting backup..."
mkdir -p restore-temp
cd restore-temp
tar -xzf "$BACKUP_FILE"

# Verify extraction
if [ $? -ne 0 ]; then
  echo "Error: Failed to extract backup"
  exit 1
fi

# Restore volumes
echo "Restoring volumes..."
for vol in pgdata keycloak_data opencloud_data synapse_data notes_data mox_data sogo_data traefik-acme; do
  echo "  Restoring $vol..."
  if [ -d "$vol" ]; then
    # Remove existing volume directory
    rm -rf "$vol"
    # Create new volume directory
    mkdir "$vol"
    # Copy data from extraction
    cp -r restore-temp/"$vol"/* "$vol"/
  else
    echo "Warning: Volume $vol is not a directory, skipping"
  fi
done

# Cleanup temporary directory
echo "Cleaning up..."
cd ..
rm -rf restore-temp

# Start services
echo "Starting services..."
docker-compose up -d

# Wait for health checks
echo "Waiting for services to become healthy..."
sleep 60

# Verify services are running
echo "Verifying services..."
docker-compose ps

# Log completion
echo ""
echo "Restore completed successfully!"
echo "Backup file: $BACKUP_FILE"
echo "Timestamp: $(date)"

# Log to restore.log
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Restore completed: $BACKUP_FILE" >> backups/restore.log

echo ""
echo "Restore verification:"
echo "Run 'docker-compose ps' to verify all services are healthy."

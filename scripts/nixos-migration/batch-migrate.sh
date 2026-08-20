#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Batch Migration Script for NixOS Containers
Migrates multiple services at once

Usage:
    ./batch-migrate.sh [service1] [service2] ...
    ./batch-migrate.sh --all       # Migrate all services with Dockerfiles
    ./batch-migrate.sh --pending   # Migrate services not yet converted
"""

set -euo pipefail

# Configuration
DOCKER_SERVICES_DIR="opendesk-nix/docker/services"
NIXOS_MIGRATION_LOG="nixos-migration-log.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if we have any services with Dockerfiles but no NixOS configs
get_pending_services() {
    find "$DOCKER_SERVICES_DIR" -mindepth 2 -name "Dockerfile" -type f | while read dockerfile; do
        service_dir=$(dirname "$dockerfile")
        service_name=$(basename "$service_dir")
        if [ ! -d "$service_dir/nixos" ]; then
            echo "$service_name"
        fi
    done | sort | uniq
}

# Check if we have any services at all
get_all_services() {
    find "$DOCKER_SERVICES_DIR" -mindepth 1 -maxdepth 1 -type d | xargs -I {} basename {} | sort
}

# Log function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    case "$level" in
        "error") echo -e "${RED}[${timestamp}] ERROR: ${message}${NC}" | tee -a "$NIXOS_MIGRATION_LOG" ;;
        "warn")  echo -e "${YELLOW}[${timestamp}] WARN:  ${message}${NC}" | tee -a "$NIXOS_MIGRATION_LOG" ;;
        "info")  echo -e "${BLUE}[${timestamp}] INFO:  ${message}${NC}" | tee -a "$NIXOS_MIGRATION_LOG" ;;
        "success") echo -e "${GREEN}[${timestamp}] OK:    ${message}${NC}" | tee -a "$NIXOS_MIGRATION_LOG" ;;
        *) echo -e "[${timestamp}] ${message}" | tee -a "$NIXOS_MIGRATION_LOG" ;;
    esac
}

# Initialize
init() {
    echo "========================================" > "$NIXOS_MIGRATION_LOG"
    echo "NixOS Container Migration Log" >> "$NIXOS_MIGRATION_LOG"
    echo "Started: $(date)" >> "$NIXOS_MIGRATION_LOG"
    echo "========================================" >> "$NIXOS_MIGRATION_LOG"
    echo ""
}

# Finalize
finalize() {
    local start_time="$1"
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo "========================================" >> "$NIXOS_MIGRATION_LOG"
    echo "Migration Summary" >> "$NIXOS_MIGRATION_LOG"
    echo "========================================" >> "$NIXOS_MIGRATION_LOG"
    echo "Started: $(date -d @$start_time)" >> "$NIXOS_MIGRATION_LOG"
    echo "Ended:   $(date)" >> "$NIXOS_MIGRATION_LOG"
    echo "Duration: ${duration} seconds" >> "$NIXOS_MIGRATION_LOG"
    echo "========================================" >> "$NIXOS_MIGRATION_LOG"
    
    cat "$NIXOS_MIGRATION_LOG"
}

# Migrate a single service
migrate_service() {
    local service_name="$1"
    local version="${2:-}"
    
    log "info" "Starting migration for: $service_name"
    
    # Check if service directory exists
    local service_dir="$DOCKER_SERVICES_DIR/$service_name"
    if [ ! -d "$service_dir" ]; then
        log "warn" "Service directory not found, skipping: $service_dir"
        return 1
    fi
    
    # Check if Dockerfile exists
    local dockerfile="$service_dir/Dockerfile"
    if [ ! -f "$dockerfile" ]; then
        log "warn" "Dockerfile not found, skipping: $dockerfile"
        return 1
    fi
    
    # Check if already migrated
    if [ -d "$service_dir/nixos" ]; then
        log "warn" "Already migrated, skipping: $service_name"
        return 0
    fi
    
    # Determine version from Dockerfile
    if [ -z "$version" ]; then
        version=$(grep -iE '^(FROM|ARG.*VERSION|ENV.*VERSION)' "$dockerfile" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "latest")
        if [ -z "$version" ]; then
            version="latest"
        fi
    fi
    
    # Run migration script
    log "info" "Migrating $service_name (version: $version)"
    
    if ./scripts/nixos-migration/migrate-service.sh "$service_name" "$version" "$dockerfile"; then
        log "success" "Successfully migrated: $service_name"
        return 0
    else
        log "error" "Failed to migrate: $service_name"
        return 1
    fi
}

# Main function
main() {
    local start_time=$(date +%s)
    init
    
    local services_to_migrate=()
    
    # Parse arguments
    if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "Usage: $0 [service1] [service2] ..."
        echo "       $0 --all"
        echo "       $0 --pending"
        exit 0
    fi
    
    if [ "$1" = "--all" ]; then
        log "info" "Migrating ALL services with Dockerfiles..."
        services_to_migrate=($(get_all_services))
    elif [ "$1" = "--pending" ]; then
        log "info" "Migrating PENDING services (with Dockerfile but no NixOS config)..."
        services_to_migrate=($(get_pending_services))
        if [ ${#services_to_migrate[@]} -eq 0 ]; then
            log "info" "No pending services to migrate!"
            exit 0
        fi
    else
        # Specific services provided
        services_to_migrate=("$@")
    fi
    
    log "info" "Services to migrate: ${#services_to_migrate[@]} (${services_to_migrate[*]})"
    
    local success_count=0
    local fail_count=0
    local skip_count=0
    
    for service in "${services_to_migrate[@]}"; do
        if migrate_service "$service"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done
    
    # Summary
    echo ""
    log "info" "Migration Statistics:"
    log "info" "  Successful: $success_count"
    log "info" "  Failed:     $fail_count"
    log "info" "  Skipped:    $skip_count"
    log "info" "  Total:      $((success_count + fail_count + skip_count))"
    
    # Final report
    if [ $fail_count -gt 0 ]; then
        log "warn" "Some migrations failed. Check the log for details."
    else
        log "success" "All migrations completed successfully!"
    fi
    
    finalize "$start_time"
}

# Run main
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

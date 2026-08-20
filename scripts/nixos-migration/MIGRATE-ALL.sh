#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Complete Migration Script
Migrates ALL services to NixOS containers in one operation.

This script:
1. Scans for all services with Dockerfiles
2. Migrates each service to NixOS
3. Finalizes all migrations
4. Tests all migrated services
5. Generates a comprehensive report

Usage:
    ./MIGRATE-ALL.sh [--dry-run] [--skip-tests]
    
Options:
    --dry-run    Show what would be done without making changes
    --skip-tests Skip the test phase (faster, but less verification)
    --help       Show this help message
"""

set -euo pipefail

SERVICES_DIR="opendesk-nix/docker/services"
DOCKER_DIR="opendesk-nix/docker"
REPORT_FILE="migration-report-$(date +%Y%m%d-%H%M%S).txt"
LOG_DIR="migration-logs-$(date +%Y%m%d-%H%M%S)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
SKIP_TESTS=false

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--dry-run] [--skip-tests]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be done without making changes"
            echo "  --skip-tests Skip the test phase (faster)"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Initialize
echo "=========================================================================="
echo "Complete NixOS Container Migration"
echo "=========================================================================="
echo ""
echo "Options:"
echo "  Dry run: $DRY_RUN"
echo "  Skip tests: $SKIP_TESTS"
echo ""

# Create log directory
if [ "$DRY_RUN" = false ]; then
    mkdir -p "$LOG_DIR"
    echo "Log directory: $LOG_DIR"
    echo ""
fi

# Initialize counters
TOTAL_SERVICES=0
MIGRATED=0
FAILED=0
SKIPPED=0
TESTED=0
PASSED=0
FAILED_TESTS=0

# Start timing
START_TIME=$(date +%s)

# Function to log
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    case "$level" in
        "ERROR") echo -e "${RED}[$timestamp] ERROR: $message${NC}" ;;
        "WARN")  echo -e "${YELLOW}[$timestamp] WARN:  $message${NC}" ;;
        "OK")    echo -e "${GREEN}[$timestamp] OK:    $message${NC}" ;;
        "INFO")  echo -e "${BLUE}[$timestamp] INFO:  $message${NC}" ;;
        "SECTION") echo -e "${BLUE}[$timestamp] ==== $message ====${NC}" ;;
        *) echo -e "[$timestamp] $message" ;;
    esac
    
    if [ "$DRY_RUN" = false ] && [ -n "$LOG_DIR" ]; then
        echo "[$timestamp] $level: $message" >> "$LOG_DIR/migration.log"
    fi
}

# Function to run command (with dry-run support)
run_cmd() {
    local description="$1"
    shift
    local cmd="$@"
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] $description"
        echo "  Command: $cmd"
        return 0
    fi
    
    echo "  [RUN] $description"
    if eval "$cmd" 2>&1; then
        return 0
    else
        return 1
    fi
}

# Phase 1: Scan and Identify
log "SECTION" "PHASE 1: Scanning for services to migrate"

All_SERVICES=()

# Find services in services/ directory with Dockerfile
while IFS= read -r -d '' dockerfile; do
    service_name=$(basename $(dirname "$dockerfile"))
    All_SERVICES+=("$service_name")
done < <(find "$SERVICES_DIR" -name "Dockerfile" -type f -print0)

# Find services in root docker/ directory with Dockerfile
while IFS= read -r -d '' dockerfile; do
    dir=$(dirname "$dockerfile")
    service_name=$(basename "$dir")
    # Check if this service already exists in services/ directory
    if [ ! -d "$SERVICES_DIR/$service_name" ]; then
        All_SERVICES+=("$service_name")
    fi
done < <(find "$DOCKER_DIR" -maxdepth 2 -name "Dockerfile" -type f -print0)

# Remove duplicates
IFS=$'\n' All_SERVICES=($(sort -u <<<"${All_SERVICES[*]}"))
unset IFS

TOTAL_SERVICES=${#All_SERVICES[@]}

log "INFO" "Found $TOTAL_SERVICES services with Dockerfiles"

# Separate already migrated vs pending
ALREADY_MIGRATED=()
PENDING=()

for service in "${All_SERVICES[@]}"; do
    if [ -d "$SERVICES_DIR/$service/nixos" ]; then
        ALREADY_MIGRATED+=("$service")
    else
        PENDING+=("$service")
    fi
done

# Also check root docker directory
for service in "${All_SERVICES[@]}"; do
    if [ -d "$DOCKER_DIR/$service/nixos" ] && [ ! "${ALREADY_MIGRATED[@]}" =~ "$service" ]; then
        ALREADY_MIGRATED+=("$service")
    fi
done

log "INFO" "Already migrated: ${#ALREADY_MIGRATED[@]} services"
log "INFO" "Pending: ${#PENDING[@]} services"

if [ ${#PENDING[@]} -eq 0 ]; then
    log "INFO" "No services to migrate! All services are already migrated."
    exit 0
fi

echo ""

# Phase 2: Migration
log "SECTION" "PHASE 2: Migrating services to NixOS"

for service in "${PENDING[@]}"; do
    log "INFO" "Migrating: $service"
    
    # Determine Dockerfile path
    DOCKERFILE_PATH=""
    if [ -f "$SERVICES_DIR/$service/Dockerfile" ]; then
        DOCKERFILE_PATH="$SERVICES_DIR/$service/Dockerfile"
    elif [ -f "$DOCKER_DIR/$service/Dockerfile" ]; then
        DOCKERFILE_PATH="$DOCKER_DIR/$service/Dockerfile"
    else
        log "ERROR" "Could not find Dockerfile for $service"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    # Copy Dockerfile to services/ if needed
    if [ "$DOCKERFILE_PATH" != "$SERVICES_DIR/$service/Dockerfile" ]; then
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$SERVICES_DIR/$service"
            cp "$DOCKERFILE_PATH" "$SERVICES_DIR/$service/Dockerfile"
            log "INFO" "  Copied Dockerfile to $SERVICES_DIR/$service/"
        else
            log "INFO" "  Would copy Dockerfile to $SERVICES_DIR/$service/"
        fi
        DOCKERFILE_PATH="$SERVICES_DIR/$service/Dockerfile"
    fi
    
    # Determine version
    VERSION="latest"
    if [ -f "$DOCKERFILE_PATH" ]; then
        version_line=$(grep -iE '(ARG|ENV|LABEL.*VERSION)' "$DOCKERFILE_PATH" | head -1 || true)
        if [[ "$version_line" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
            VERSION=$(echo "$version_line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        fi
    fi
    
    # Run migration
    if run_cmd "Running migration script" ./migrate-service.sh "$service" "$VERSION" "$DOCKERFILE_PATH"; then
        MIGRATED=$((MIGRATED + 1))
        log "OK" "$service migrated successfully"
    else
        FAILED=$((FAILED + 1))
        log "ERROR" "$service migration failed"
    fi
    
    echo ""
done

# Phase 3: Finalization
log "SECTION" "PHASE 3: Finalizing migrations"

if [ "$DRY_RUN" = false ]; then
    SERVICES_TO_FINALIZE=($PENDING)
    if [ ${#SERVICES_TO_FINALIZE[@]} -gt 0 ]; then
        if run_cmd "Finalizing migrations" ./finalize-migration.sh --all; then
            log "OK" "All migrations finalized"
        else
            log "WARN" "Some finalizations had issues"
        fi
    fi
else
    log "INFO" "Would run: ./finalize-migration.sh --all"
fi

echo ""

# Phase 4: Testing (if not skipped)
if [ "$SKIP_TESTS" = false ]; then
    log "SECTION" "PHASE 4: Testing migrated services"
    
    SERVICES_TO_TEST=()
    
    # Test newly migrated services
    for service in "${PENDING[@]}"; do
        if [ -d "$SERVICES_DIR/$service/nixos" ]; then
            SERVICES_TO_TEST+=("$service")
        fi
    done
    
    # Also test already migrated services if --all
    if [ ${#SERVICES_TO_TEST[@]} -eq 0 ]; then
        SERVICES_TO_TEST=("${All_SERVICES[@]}")
    fi
    
    if [ ${#SERVICES_TO_TEST[@]} -gt 0 ]; then
        log "INFO" "Testing ${#SERVICES_TO_TEST[@]} services"
        
        for service in "${SERVICES_TO_TEST[@]}"; do
            TESTED=$((TESTED + 1))
            log "INFO" "Testing: $service"
            
            if run_cmd "Testing $service" ./test-migration.sh "$service"; then
                PASSED=$((PASSED + 1))
                log "OK" "$service passed all tests"
            else
                FAILED_TESTS=$((FAILED_TESTS + 1))
                log "ERROR" "$service tests failed"
            fi
            
            echo ""
        done
    fi
else
    log "INFO" "Skipping tests (--skip-tests option)"
fi

# Phase 5: Report
log "SECTION" "PHASE 5: Generating migration report"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
DURATION_MINUTES=$((DURATION / 60))
DURATION_SECONDS=$((DURATION % 60))

{
    echo "=========================================================================="
    echo "NixOS Container Migration Report"
    echo "=========================================================================="
    echo ""
    echo "Generated: $(date)"
    echo "Duration: ${DURATION_MINUTES}m ${DURATION_SECONDS}s"
    echo ""
    echo "--------------------------------------------------------------------------"
    echo "SUMMARY"
    echo "--------------------------------------------------------------------------"
    echo "Total services found:        $TOTAL_SERVICES"
    echo "Already migrated:            ${#ALREADY_MIGRATED[@]}"
    echo "Newly migrated:              $MIGRATED"
    echo "Migration failures:          $FAILED"
    echo "Services tested:             $TESTED"
    echo "Tests passed:                $PASSED"
    echo "Tests failed:                $FAILED_TESTS"
    echo ""
    echo "--------------------------------------------------------------------------"
    echo "ALREADY MIGRATED SERVICES"
    echo "--------------------------------------------------------------------------"
    for service in "${ALREADY_MIGRATED[@]}"; do
        echo "  ✅ $service"
    done
    echo ""
    echo "--------------------------------------------------------------------------"
    echo "NEWLY MIGRATED SERVICES"
    echo "--------------------------------------------------------------------------"
    for service in "${PENDING[@]}"; do
        if [ -d "$SERVICES_DIR/$service/nixos" ]; then
            echo "  ✅ $service"
        else
            echo "  ❌ $service (failed)"
        fi
    done
    echo ""
    echo "--------------------------------------------------------------------------"
    echo "MIGRATION FAILURES"
    echo "--------------------------------------------------------------------------"
    if [ $FAILED -gt 0 ]; then
        # Would need to track which services failed during migration
        echo "  $FAILED services failed during migration (check logs above)"
    else
        echo "  None"
    fi
    echo ""
    echo "--------------------------------------------------------------------------"
    echo "TEST FAILURES"
    echo "--------------------------------------------------------------------------"
    if [ $FAILED_TESTS -gt 0 ]; then
        # Would need to track which services failed tests
        echo "  $FAILED_TESTS services failed tests (check logs above)"
    else
        echo "  None"
    fi
    echo ""
    echo "--------------------------------------------------------------------------"
    echo "NEXT STEPS"
    echo "--------------------------------------------------------------------------"
    if [ $FAILED -gt 0 ]; then
        echo "  1. Fix migration failures for $FAILED services"
        echo "  2. Re-run migration for failed services"
    fi
    if [ $FAILED_TESTS -gt 0 ]; then
        echo "  1. Fix test failures for $FAILED_TESTS services"
        echo "  2. Debug and retry tests"
    fi
    if [ $FAILED -eq 0 ] && [ $FAILED_TESTS -eq 0 ]; then
        echo "  1. Commit changes to git"
        echo "  2. Push to remote repository"
        echo "  3. Update migration tracker"
        echo "  4. Begin deployment planning"
    fi
    echo ""
    echo "=========================================================================="
} | tee "$REPORT_FILE"

if [ "$DRY_RUN" = false ]; then
    cp "$REPORT_FILE" "$LOG_DIR/report.txt"
fi

# Final statistics
log "SECTION" "MIGRATION COMPLETE"
log "INFO" "Total services: $TOTAL_SERVICES"
log "INFO" "Migrated: $MIGRATED"
log "INFO" "Failed: $FAILED"
log "INFO" "Tested: $TESTED"
log "INFO" "Passed: $PASSED"
log "INFO" "Failed tests: $FAILED_TESTS"
log "INFO" "Duration: ${DURATION_MINUTES}m ${DURATION_SECONDS}s"

if [ "$DRY_RUN" = false ]; then
    log "INFO" "Report saved to: $REPORT_FILE"
    if [ -n "$LOG_DIR" ]; then
        log "INFO" "Logs saved to: $LOG_DIR/"
    fi
fi

echo ""

# Exit with error if there were failures
if [ $FAILED -gt 0 ] || [ $FAILED_TESTS -gt 0 ]; then
    log "ERROR" "Migration completed with errors"
    exit 1
else
    log "OK" "Migration completed successfully!"
    exit 0
fi

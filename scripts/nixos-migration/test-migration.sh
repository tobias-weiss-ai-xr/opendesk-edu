#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Test NixOS Container Migration
Tests migrated services to ensure they build and work correctly.

Usage:
    ./test-migration.sh <service> [version]
    ./test-migration.sh --all
    ./test-migration.sh --pending
"""

set -euo pipefail

SERVICES_DIR="opendesk-nix/docker/services"
TEST_LOG="migration-test-log-$(date +%Y%m%d-%H%M%S).txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "NixOS Container Migration Test Suite"
echo "=========================================="
echo "Log: $TEST_LOG"
echo ""

# Initialize log
echo "NixOS Container Migration Test Suite" > "$TEST_LOG"
echo "Started: $(date)" >> "$TEST_LOG"
echo "==========================================" >> "$TEST_LOG"
echo "" >> "$TEST_LOG"

TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0

# Function to log
test_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    case "$level" in
        "PASS") 
            echo -e "${GREEN}[PASS]${NC} [$timestamp] $message" | tee -a "$TEST_LOG"
            ;;
        "FAIL") 
            echo -e "${RED}[FAIL]${NC} [$timestamp] $message" | tee -a "$TEST_LOG"
            ;;
        "SKIP") 
            echo -e "${YELLOW}[SKIP]${NC} [$timestamp] $message" | tee -a "$TEST_LOG"
            ;;
        "INFO") 
            echo -e "${BLUE}[INFO]${NC} [$timestamp] $message" | tee -a "$TEST_LOG"
            ;;
        *) 
            echo -e "[$timestamp] $message" | tee -a "$TEST_LOG"
            ;;
    esac
}

# Function to test a service
test_service() {
    local service="$1"
    local version="${2:-}"
    
    TOTAL=$((TOTAL + 1))
    test_log "INFO" "Testing service: $service"
    
    local service_dir="$SERVICES_DIR/$service"
    local nixos_dir="$service_dir/nixos"
    
    # Check if NixOS directory exists
    if [ ! -d "$nixos_dir" ]; then
        test_log "SKIP" "$service: No NixOS directory found"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi
    
    # Check for required files
    if [ ! -f "$nixos_dir/configuration.nix" ] || [ ! -f "$nixos_dir/default.nix" ]; then
        test_log "FAIL" "$service: Missing required files"
        FAILED=$((FAILED + 1))
        return 1
    fi
    
    # Test 1: Syntax check
    test_log "INFO" "$service: Checking Nix syntax..."
    if nix-instantiate --parse-only "$nixos_dir/configuration.nix" 2>/dev/null && \
       nix-instantiate --parse-only "$nixos_dir/default.nix" 2>/dev/null; then
        test_log "PASS" "$service: Nix syntax valid"
    else
        test_log "FAIL" "$service: Nix syntax errors"
        FAILED=$((FAILED + 1))
        return 1
    fi
    
    # Test 2: Build
    test_log "INFO" "$service: Building container..."
    local build_cmd="nix build .#${service}-nixos"
    if $build_cmd 2>&1 | tee -a "$TEST_LOG" | tail -5; then
        test_log "PASS" "$service: Build successful"
    else
        test_log "FAIL" "$service: Build failed"
        FAILED=$((FAILED + 1))
        return 1
    fi
    
    # Test 3: Docker load
    test_log "INFO" "$service: Loading into Docker..."
    if docker load < result 2>&1 | tee -a "$TEST_LOG" | tail -3; then
        test_log "PASS" "$service: Docker load successful"
    else
        test_log "FAIL" "$service: Docker load failed"
        FAILED=$((FAILED + 1))
        return 1
    fi
    
    # Test 4: Docker run and health check
    local image_name="${service}-opendesk"
    local container_name="test-${service}-$(date +%s)"
    
    test_log "INFO" "$service: Starting container..."
    
    # Get the port from default.nix
    local port=$(grep -E '"[0-9]+/tcp"' "$nixos_dir/default.nix" | head -1 | grep -oE '[0-9]+' || echo "8080")
    
    # Run container in background
    if docker run -d --name "$container_name" -p "$port:$port" "$image_name" 2>&1 | tee -a "$TEST_LOG"; then
        test_log "PASS" "$service: Container started"
    else
        test_log "FAIL" "$service: Container failed to start"
        FAILED=$((FAILED + 1))
        return 1
    fi
    
    # Wait for health check
    test_log "INFO" "$service: Waiting for health check..."
    local max_attempts=30
    local attempt=1
    local healthy=false
    
    while [ $attempt -le $max_attempts ]; do
        sleep 2
        local health_status=$(docker inspect --format='{{json .State.Health.Status}}' "$container_name" 2>/dev/null || echo "null")
        
        if [ "$health_status" = '"healthy"' ]; then
            healthy=true
            break
        elif [ "$health_status" = '"starting"' ]; then
            echo "  Attempt $attempt/$max_attempts: Container starting..."
        else
            echo "  Attempt $attempt/$max_attempts: Health status: $health_status"
        fi
        
        attempt=$((attempt + 1))
    done
    
    if [ "$healthy" = true ]; then
        test_log "PASS" "$service: Health check passed"
    else
        test_log "FAIL" "$service: Health check failed after $max_attempts attempts"
        FAILED=$((FAILED + 1))
    fi
    
    # Cleanup
    test_log "INFO" "$service: Cleaning up..."
    docker stop "$container_name" 2>/dev/null || true
    docker rm "$container_name" 2>/dev/null || true
    docker rmi "$image_name" 2>/dev/null || true
    
    # Only count as passed if all tests passed
    if [ "$healthy" = true ]; then
        PASSED=$((PASSED + 1))
    fi
}

# Get services to test
if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 <service> [version]"
    echo "       $0 --all"
    echo "       $0 --pending"
    exit 0
fi

if [ "$1" = "--all" ]; then
    echo "[INFO] Testing ALL migrated services..."
    SERVICES=$(find "$SERVICES_DIR" -type d -name "nixos" | while read dir; do
        basename $(dirname "$dir")
    done)
elif [ "$1" = "--pending" ]; then
    echo "[INFO] Testing services that need verification..."
    # Find services with NixOS dir but no test results
    SERVICES=$(find "$SERVICES_DIR" -type d -name "nixos" | while read dir; do
        basename $(dirname "$dir")
    done)
else
    SERVICES="$@"
fi

echo "[INFO] Services to test: ${#SERVICES[@]} (${SERVICES[*]})"
echo ""

# Run tests
for service in $SERVICES; do
    test_service "$service"
    echo ""
done

# Final summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total: $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Skipped: $SKIPPED"
echo ""

echo "==========================================" >> "$TEST_LOG"
echo "Test Summary" >> "$TEST_LOG"
echo "==========================================" >> "$TEST_LOG"
echo "Total: $TOTAL" >> "$TEST_LOG"
echo "Passed: $PASSED" >> "$TEST_LOG"
echo "Failed: $FAILED" >> "$TEST_LOG"
echo "Skipped: $SKIPPED" >> "$TEST_LOG"
echo "Ended: $(date)" >> "$TEST_LOG"
echo "==========================================" >> "$TEST_LOG"

if [ $FAILED -gt 0 ]; then
    test_log "FAIL" "Some tests failed. See $TEST_LOG for details."
    exit 1
else
    test_log "PASS" "All tests passed!"
    exit 0
fi

#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Integration test script for semester-provisioning package.
# Runs unit tests, linting, and import checks.
#
# Usage: ./tests/run_integration.sh [--venv /path/to/venv]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROVISIONING_DIR="$(dirname "$SCRIPT_DIR")"  # scripts/semester-provisioning/
PROJECT_DIR="$(dirname "$(dirname "$PROVISIONING_DIR")")"  # repo root

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
PASS=0
FAIL=0

pass() {
    PASS=$((PASS+1))
    echo -e "${GREEN}[PASS]${NC} $1"
}

fail() {
    FAIL=$((FAIL+1))
    echo -e "${RED}[FAIL]${NC} $1"
}

# Parse arguments
VENV_DIR=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --venv) VENV_DIR="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Locate or create virtual environment
if [[ -z "$VENV_DIR" ]]; then
    if [[ -d "$PROVISIONING_DIR/.venv" ]]; then
        VENV_DIR="$PROVISIONING_DIR/.venv"
    elif [[ -d "$PROJECT_DIR/.venv" ]]; then
        VENV_DIR="$PROJECT_DIR/.venv"
    else
        echo "No virtual environment found. Creating one..."
        python3 -m venv "$PROVISIONING_DIR/.venv"
        VENV_DIR="$PROVISIONING_DIR/.venv"
    fi
fi

echo "Using virtual environment: $VENV_DIR"
source "$VENV_DIR/bin/activate"

# Ensure dependencies installed
echo "Installing dependencies..."
pip install -q httpx pytest pytest-httpx pytest-asyncio ldap3 flake8

echo ""
echo "========================================="
echo "  semester-provisioning Integration Tests"
echo "========================================="
echo ""

cd "$PROVISIONING_DIR"

# ---- Test 1: Import check ----
echo "--- Test: Import check ---"
if python -c "from sync.keycloak_client import KeycloakClient, KeycloakConfig" 2>/dev/null; then
    pass "keycloak_client imports"
else
    fail "keycloak_client imports"
fi

if python -c "from sync.semester_check import process_semester_check, get_enrolled_usernames_from_ldap" 2>/dev/null; then
    pass "semester_check imports"
else
    fail "semester_check imports"
fi

if python -c "from sync.guest_cleanup import process_guest_cleanup" 2>/dev/null; then
    pass "guest_cleanup imports"
else
    fail "guest_cleanup imports"
fi

# ---- Test 2: Unit tests ----
echo ""
echo "--- Test: Unit tests ---"
if python -m pytest tests/ -v --tb=short; then
    pass "All unit tests pass"
else
    fail "Some unit tests failed"
fi

# ---- Test 3: Linting (flake8 on sync/) ----
echo ""
echo "--- Test: Linting (flake8) ---"
if python -m flake8 sync/ --max-line-length=120; then
    pass "flake8 linting (sync/)"
else
    fail "flake8 linting violations"
fi

# ---- Summary ----
echo ""
echo "========================================="
echo "  Results: $PASS passed, $FAIL failed"
echo "========================================="

exit $FAIL

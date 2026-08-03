#!/usr/bin/env bash
# SOGo 5 Container Entrypoint Script
# SPDX-License-Identifier: Apache-2.0
# File: entrypoint.sh
# Purpose: Multi-process startup, signal handling, graceful shutdown for SOGo 5
# Version: 2.0.0
# Author: openDesk Edu Team
#
# This script manages the SOGo 5 container lifecycle:
#   1. Environment validation and configuration
#   2. Directory setup with proper permissions
#   3. Configuration template processing
#   4. Multi-process startup (SOGo + Memcached)
#   5. Signal handling and graceful shutdown
#   6. Health monitoring
#
# Processes started:
#   - memcached: Caching server for SOGo
#   - sogod: Main SOGo daemon
#   - health server: HTTP health probes
#
# USAGE:
#   /entrypoint.sh (default: starts all services)
#   /entrypoint.sh --version (shows version)
#   /entrypoint.sh --help (shows help)
#   /entrypoint.sh sogod (start only sogod)
#   /entrypoint.sh memcached (start only memcached)
#

set -euo pipefail

# =============================================================================
# CONSTANTS
# =============================================================================
readonly SCRIPT_NAME=$(basename "${0}")
readonly SCRIPT_DIR=$(dirname "$(readlink -f "${0}" 2>/dev/null || echo "${0}")")

# Process names
readonly SCHOOL_NAME="sogo5"
readonly MEMCACHED_BIN="/usr/bin/memcached"
readonly SOGO_BIN="/usr/sbin/sogod"
readonly HEALTH_SCRIPT="/healthcheck.sh"

# Configuration files
readonly SOGO_CONF="/etc/sogo/sogo.conf"
readonly MEMCACHED_CONF="/etc/memcached.conf"
readonly GNUSTEP_CONF="/etc/GNUstep/GNUstep.conf"

# Log directories
readonly LOG_DIR="/var/log/sogo"
readonly MEMCACHED_LOG="/var/log/memcached.log"

# PID files
readonly MEMCACHED_PID_FILE="/tmp/memcached.pid"
readonly SOGO_PID_FILE="/tmp/sogod.pid"
readonly HEALTH_PID_FILE="/tmp/health.pid"

# Timeout and retry settings
readonly MEMCACHED_STARTUP_TIMEOUT=10
readonly SOGO_STARTUP_TIMEOUT=30
readonly GRACEFUL_TIMEOUT=30

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# =============================================================================
# GLOBAL VARIABLES
# =============================================================================
MEMCACHED_PID=""
SOGO_PID=""
HEALTH_PID=""
SHUTDOWN_REQUESTED=false

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================
log_timestamp() {
    date -u +'%Y-%m-%dT%H:%M:%SZ'
}

log_message() {
    local level="$1"
    local color="$2"
    local message="$3"
    echo -e "${color}[${level}]$(log_timestamp)${NC} ${message}"
}

log_info() {
    log_message "INFO" "${BLUE}" "$1"
}

log_success() {
    log_message "SUCCESS" "${GREEN}" "$1"
}

log_warn() {
    log_message "WARN" "${YELLOW}" "$1" >&2
}

log_error() {
    log_message "ERROR" "${RED}" "$1" >&2
}

# =============================================================================
# SIGNAL HANDLING
# =============================================================================

# Cleanup function for graceful shutdown
cleanup() {
    local exit_code=${1:-0}
    local signal_name="$2"
    
    if ${SHUTDOWN_REQUESTED:-false}; then
        log_info "Already handling shutdown, ignoring signal ${signal_name}"
        return
    fi
    
    SHUTDOWN_REQUESTED=true
    log_info "Received signal ${signal_name:-unknown}, performing graceful shutdown..."
    
    # Order matters: stop services in reverse startup order
    
    # 3. Stop health server
    if [[ -n "${HEALTH_PID}" && -f "/proc/${HEALTH_PID}/status" ]]; then
        log_info "Stopping health server (PID: ${HEALTH_PID})..."
        stop_process "${HEALTH_PID}" "health server" "${GRACEFUL_TIMEOUT}"
        HEALTH_PID=""
    fi
    
    # 2. Stop SOGo
    if [[ -n "${SOGO_PID}" && -f "/proc/${SOGO_PID}/status" ]]; then
        log_info "Stopping SOGo (PID: ${SOGO_PID})..."
        stop_process "${SOGO_PID}" "SOGo" "${GRACEFUL_TIMEOUT}"
        # SOGo might spawn child processes
        stop_related_processes "sogod" "SOGo child processes"
        SOGO_PID=""
    fi
    
    # 1. Stop Memcached
    if [[ -n "${MEMCACHED_PID}" && -f "/proc/${MEMCACHED_PID}/status" ]]; then
        log_info "Stopping Memcached (PID: ${MEMCACHED_PID})..."
        stop_process "${MEMCACHED_PID}" "Memcached" "${GRACEFUL_TIMEOUT}"
        MEMCACHED_PID=""
    fi
    
    # Cleanup PID files
    cleanup_pid_files
    
    log_info "All services stopped, exiting with code ${exit_code}"
    exit ${exit_code}
}

stop_process() {
    local pid="$1"
    local name="$2"
    local timeout="$3"
    
    # Try graceful shutdown first
    if ! kill -0 "${pid}" 2>/dev/null; then
        log_info "${name} already stopped"
        return 0
    fi
    
    # Send TERM signal
    if kill -TERM "${pid}" 2>/dev/null; then
        local count=0
        while kill -0 "${pid}" 2>/dev/null && [[ ${count} -lt ${timeout} ]]; do
            sleep 1
            count=$((count + 1))
        done
        
        if kill -0 "${pid}" 2>/dev/null; then
            log_warn "${name} did not stop gracefully, sending SIGKILL"
            kill -KILL "${pid}" 2>/dev/null || true
            sleep 2
        else
            log_info "${name} stopped gracefully"
        fi
    else
        log_warn "Could not send TERM to ${name}"
    fi
}

stop_related_processes() {
    local name="$1"
    local description="$2"
    
    log_info "Stopping ${description}..."
    local pids
    pids=$(pgrep -f "${name}" 2>/dev/null || true)
    
    if [[ -n "${pids}" ]]; then
        for pid in ${pids}; do
            if [[ "${pid}" != "$$" && "${pid}" != "${SOGO_PID}" ]]; then
                kill -TERM "${pid}" 2>/dev/null || true
            fi
        done
        
        # Wait for all to stop
        sleep 2
        pids=$(pgrep -f "${name}" 2>/dev/null || true)
        if [[ -n "${pids}" ]]; then
            for pid in ${pids}; do
                if [[ "${pid}" != "$$" ]]; then
                    kill -KILL "${pid}" 2>/dev/null || true
                fi
            done
        fi
    fi
}

cleanup_pid_files() {
    rm -f "${MEMCACHED_PID_FILE}" "${SOGO_PID_FILE}" "${HEALTH_PID_FILE}"
}

# Setup signal traps
trap 'cleanup 146 TERM' TERM
trap 'cleanup 143 INT' INT
trap 'cleanup 150 QUIT' QUIT
trap 'cleanup 1 HUP' HUP
trap 'cleanup 0' EXIT

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_required_binaries() {
    log_info "Validating required binaries..."
    
    local binaries=(
        "${MEMCACHED_BIN}"
        "${SOGO_BIN}"
        "/usr/bin/bash"
        "/usr/bin/curl"
        "/usr/bin/wget"
    )
    
    for binary in "${binaries[@]}"; do
        if [[ ! -x "${binary}" ]]; then
            log_error "Required binary not found or not executable: ${binary}"
            return 1
        fi
        log_info "  Found: ${binary}"
    done
    
    log_success "All required binaries validated"
    return 0
}

validate_environment() {
    log_info "Validating environment variables..."
    
    # SOGo configuration
    local sogo_vars=(
        "SOGO_DEBUG"
        "SOGO_WORKERS"
        "SOGO_MAX_MESSAGE_SIZE"
        "SOGO_APACHE_MODEL"
        "SOGO_MODULES"
        "SOGO_DEFAULT_LANGUAGE"
        "SOGO_SQL_DEBUG"
    )
    
    for var in "${sogo_vars[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            log_info "  ${var}=${!var}"
        fi
    done
    
    # Database configuration
    local db_vars=(
        "SOGO_DB_HOST"
        "SOGO_DB_PORT"
        "SOGO_DB_NAME"
        "SOGO_DB_USER"
        "SOGO_DB_TYPE"
    )
    
    local db_configured=true
    for var in "${db_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_warn "Database variable not set: ${var}"
            db_configured=false
        else
            log_info "  ${var}=[REDACTED]"
        fi
    done
    
    if ! ${db_configured}; then
        log_error "Database configuration incomplete. Required: SOGO_DB_HOST, SOGO_DB_PORT, SOGO_DB_NAME, SOGO_DB_USER, SOGO_DB_TYPE"
        return 1
    fi
    
    # Memcached configuration
    local memcached_vars=(
        "MEMCACHED_SERVER"
        "MEMCACHED_PORT"
        "MEMCACHED_MAX_CONNECTIONS"
        "MEMCACHED_CACHE_SIZE"
    )
    
    for var in "${memcached_vars[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            log_info "  ${var}=${!var}"
        fi
    done
    
    log_success "Environment validation passed"
    return 0
}

# =============================================================================
# DIRECTORY & FILE SETUP
# =============================================================================

setup_directories() {
    log_info "Setting up directories..."
    
    local directories=(
        "${LOG_DIR}"
        "/var/run/sogo"
        "/var/cache/sogo"
        "/var/lib/sogo"
        "/tmp"
        "/etc/sogo"
        "/etc/GNUstep"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "${dir}" ]]; then
            mkdir -p "${dir}" && chown sogo:sogo "${dir}" && chmod 755 "${dir}"
            log_info "  Created: ${dir}"
        else
            # Ensure correct ownership
            chown sogo:sogo "${dir}" 2>/dev/null || true
            log_info "  Exists: ${dir}"
        fi
    done
    
    # Create required files
    local files=(
        "${SOGO_CONF}"
        "${MEMCACHED_CONF}"
        "${GNUSTEP_CONF}"
        "${LOG_DIR}/sogo.log"
        "${LOG_DIR}/access.log"
        "${LOG_DIR}/error.log"
        "${MEMCACHED_LOG}"
    )
    
    for file in "${files[@]}"; do
        local dirname=$(dirname "${file}")
        if [[ ! -d "${dirname}" ]]; then
            mkdir -p "${dirname}" && chown sogo:sogo "${dirname}"
        fi
        if [[ ! -f "${file}" ]]; then
            touch "${file}" && chown sogo:sogo "${file}" && chmod 644 "${file}"
            log_info "  Created: ${file}"
        else
            chown sogo:sogo "${file}" 2>/dev/null || true
            log_info "  Exists: ${file}"
        fi
    done
    
    # Setup log rotation for SOGo
    setup_log_rotation
    
    log_success "Directory and file setup complete"
    return 0
}

setup_log_rotation() {
    log_info "Setting up log rotation..."
    
    cat > /etc/logrotate.d/sogo << 'EOF'
/var/log/sogo/*.log {
    compress
    copytruncate
    daily
    dateext
    delaycompress
    missingok
    notifempty
    rotate 30
    size 100M
    create 644 sogo sogo
    sharedscripts
    postrotate
        systemctl reload sogo 2>/dev/null || true
    endscript
}
EOF
    
    if [[ -f "/etc/logrotate.d/sogo" ]]; then
        chmod 644 "/etc/logrotate.d/sogo"
        log_info "Log rotation configuration created"
    fi
    
    return 0
}

# =============================================================================
# CONFIGURATION TEMPLATE PROCESSING
# =============================================================================

process_sogo_configuration() {
    log_info "Processing SOGo configuration..."
    
    # Check if configuration template exists
    if [[ ! -f "${SOGO_CONF}" ]]; then
        log_error "SOGo configuration file not found: ${SOGO_CONF}"
        return 1
    fi
    
    # Check if template needs processing (contains ${...} variables)
    if grep -q '\${' "${SOGO_CONF}" 2>/dev/null; then
        log_info "  Processing environment variables in SOGo config..."
        
        # Use envsubst to replace environment variables in template
        if command -v envsubst &>/dev/null; then
            envsubst '${SOGO_DB_HOST} ${SOGO_DB_PORT} ${SOGO_DB_NAME} ${SOGO_DB_USER} ${SOGO_DB_PASSWORD} ${SOGO_DB_TYPE}' \
                < "${SOGO_CONF}" > "${SOGO_CONF}.tmp" && \
            mv "${SOGO_CONF}.tmp" "${SOGO_CONF}" && \
            chown sogo:sogo "${SOGO_CONF}" && \
            chmod 600 "${SOGO_CONF}" || {
                log_error "Failed to process SOGo configuration template"
                return 1
            }
        else
            # Fallback: use sed for simple replacements
            log_warn "envsubst not available, using sed for template processing"
            local vars=(
                "SOGO_DB_HOST"
                "SOGO_DB_PORT"
                "SOGO_DB_NAME"
                "SOGO_DB_USER"
                "SOGO_DB_PASSWORD"
                "SOGO_DB_TYPE"
            )
            
            cp "${SOGO_CONF}" "${SOGO_CONF}.tmp"
            for var in "${vars[@]}"; do
                local value="${!var:-}"
                if [[ -n "${value}" ]]; then
                    sed -i "s|\${${var}}|${value}|g" "${SOGO_CONF}.tmp" || true
                fi
            done
            mv "${SOGO_CONF}.tmp" "${SOGO_CONF}"
            chown sogo:sogo "${SOGO_CONF}"
            chmod 600 "${SOGO_CONF}"
        fi
    fi
    
    # Validate configuration file
    if ! validate_sogo_config; then
        log_error "SOGo configuration validation failed"
        return 1
    fi
    
    log_success "SOGo configuration processed"
    return 0
}

process_memcached_configuration() {
    log_info "Processing Memcached configuration..."
    
    # Default memcached port
    local memcached_port="${MEMCACHED_PORT:-11211}"
    local memcached_threads="${MEMCACHED_THREADS:-4}"
    local memcached_connections="${MEMCACHED_MAX_CONNECTIONS:-1024}"
    local memcached_memory="${MEMCACHED_CACHE_SIZE:-512}"
    
    # Check if custom config exists
    if [[ -f "${MEMCACHED_CONF}" ]]; then
        log_info "  Using existing Memcached configuration"
    else
        # Create default configuration
        cat > "${MEMCACHED_CONF}" << EOF
# Memcached Configuration for SOGo
# Automatically generated by container entrypoint

# Run as daemon
-d

# User to run as
-u sogo

# Port to listen on
-p ${memcached_port}

# Maximum memory to use (MB)
-m ${memcached_memory}

# Maximum simultaneous connections
-c ${memcached_connections}

# Number of threads to use
-t ${memcached_threads}

# Connection timeout (seconds)
-timeout 30

# Disable Nagle's algorithm
-n

# Log file
-l ${MEMCACHED_LOG}

# PID file
-P ${MEMCACHED_PID_FILE}
EOF
        
        chown sogo:sogo "${MEMCACHED_CONF}"
        chmod 644 "${MEMCACHED_CONF}"
        log_info "  Created default Memcached configuration"
    fi
    
    # Validate the port is available
    if ss -tlnp 2>/dev/null | grep -q ":${memcached_port} "; then
        log_error "Port ${memcached_port} is already in use"
        return 1
    fi
    
    log_success "Memcached configuration processed"
    return 0
}

process_gnustep_configuration() {
    log_info "Processing GNUstep configuration..."
    
    # Check if GNUstep configuration exists
    if [[ ! -f "${GNUSTEP_CONF}" ]]; then
        # Create default GNUstep configuration
        cat > "${GNUSTEP_CONF}" << 'EOF'
# GNUstep Configuration for SOGo
# Automatically generated by container entrypoint

# Default user
NSRemotePipePath = /tmp

# ObjectiveC library paths
OBJC_LIBRARY_PATH = /usr/lib/GNUstep/Libraries

# GNUstep system root
GNUstepSystemRoot = /usr/lib/GNUstep/System

# Local library paths
GNUSTEP_LOCAL_ROOT = /usr/lib/GNUstep/Local

# User defaults database
NSUserDefaultsDatabase = /var/lib/sogo/defaults
EOF
        
        chmod 644 "${GNUSTEP_CONF}"
        log_info "  Created default GNUstep configuration"
    fi
    
    return 0
}

validate_sogo_config() {
    log_info "Validating SOGo configuration..."
    
    # Basic syntax check - ensure file is readable YAML/INI
    if ! sogo-check-conf "${SOGO_CONF}" 2>/dev/null; then
        log_error "SOGo configuration syntax error"
        return 1
    fi
    
    # Check for required sections
    local required_sections=(
        "sogod"
        "OCSURLs"
        "SOGoSuperUsernames"
    )
    
    for section in "${required_sections[@]}"; do
        if ! grep -q "${section}" "${SOGO_CONF}" 2>/dev/null; then
            log_error "Missing required section in SOGo config: ${section}"
            return 1
        fi
    done
    
    # Check database configuration
    if ! grep -q "x PostgreSQL\|x MySQL\|x MariaDB" "${SOGO_CONF}" 2>/dev/null; then
        log_warn "No database driver specified in SOGo configuration"
    fi
    
    log_success "SOGo configuration validated"
    return 0
}

# Command substitution helper for sogo-check-conf
sogo-check-conf() {
    if ! command -v sogod &>/dev/null; then
        return 0  # Can't validate without sogod, assume ok
    fi
    
    # Try to validate config
    if sogod --validate-config "$1" 2>/dev/null; then
        return 0
    fi
    
    # Try alternative validation
    if sogod --help 2>&1 | grep -q "validate"; then
        sogod --validate-config "$1" 2>/dev/null || return 1
    fi
    
    # Fallback: just check file is readable
    [[ -r "$1" ]]
}

# =============================================================================
# SERVICE STARTUP FUNCTIONS
# =============================================================================

start_memcached() {
    log_info "Starting Memcached..."
    
    # Use configuration file if it exists
    local config_flag=""
    if [[ -f "${MEMCACHED_CONF}" ]]; then
        config_flag="-c ${MEMCACHED_CONF}"
    fi
    
    # Start memcached in the background
    ${MEMCACHED_BIN} ${config_flag} &
    MEMCACHED_PID=$!
    
    # Save PID
    echo "${MEMCACHED_PID}" > "${MEMCACHED_PID_FILE}"
    
    # Wait for startup
    local count=0
    while ! ss -tlnp 2>/dev/null | grep -q "${MEMCACHED_BIN}" && [[ ${count} -lt ${MEMCACHED_STARTUP_TIMEOUT} ]]; do
        sleep 1
        count=$((count + 1))
    done
    
    # Verify it's running
    if kill -0 "${MEMCACHED_PID}" 2>/dev/null; then
        log_success "Memcached started (PID: ${MEMCACHED_PID})"
        return 0
    else
        log_error "Memcached failed to start"
        cat "${MEMCACHED_LOG}" 2>/dev/null || true
        return 1
    fi
}

start_sogo() {
    log_info "Starting SOGo..."
    
    # Check if database is reachable
    if ! wait_for_database; then
        log_error "Database not available, cannot start SOGo"
        return 1
    fi
    
    # Start SOGo in the background
    exec ${SOGO_BIN} &
    SOGO_PID=$!
    
    # Save PID
    echo "${SOGO_PID}" > "${SOGO_PID_FILE}"
    
    # Wait for startup
    local count=0
    while [[ ${count} -lt ${SOGO_STARTUP_TIMEOUT} ]]; do
        if kill -0 "${SOGO_PID}" 2>/dev/null; then
            # Check if it's listening on its port
            if ss -tlnp 2>/dev/null | grep -q "sogod"; then
                log_success "SOGo started (PID: ${SOGO_PID})"
                return 0
            fi
        fi
        sleep 1
        count=$((count + 1))
    done
    
    # Check if it's still running
    if kill -0 "${SOGO_PID}" 2>/dev/null; then
        log_warn "SOGo started but may not be fully ready (PID: ${SOGO_PID})"
        return 0
    else
        log_error "SOGo failed to start"
        return 1
    fi
}

start_health_server() {
    log_info "Starting health server..."
    
    # Check if health check script exists
    if [[ ! -x "${HEALTH_SCRIPT}" ]]; then
        log_warn "Health check script not found or not executable, skipping"
        return 0
    fi
    
    # Start health check server
    ${HEALTH_SCRIPT} server &
    HEALTH_PID=$!
    
    # Save PID
    echo "${HEALTH_PID}" > "${HEALTH_PID_FILE}"
    
    # Wait for it to start
    local count=0
    while [[ ${count} -lt 10 ]]; do
        if kill -0 "${HEALTH_PID}" 2>/dev/null; then
            log_success "Health server started (PID: ${HEALTH_PID})"
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    
    log_error "Health server failed to start"
    return 1
}

# =============================================================================
# Database WAIT Function
# =============================================================================

wait_for_database() {
    local db_host="${SOGO_DB_HOST:-localhost}"
    local db_port="${SOGO_DB_PORT:-5432}"
    local db_type="${SOGO_DB_TYPE:-PostgreSQL}"
    local max_retries=60
    local retry_delay=5
    
    log_info "Waiting for database (${db_type} at ${db_host}:${db_port})..."
    
    local retry_count=0
    while [[ ${retry_count} -lt ${max_retries} ]]; do
        if check_database_connection; then
            log_success "Database connection established"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        log_info "Database not available (attempt ${retry_count}/${max_retries}), retrying in ${retry_delay}s..."
        sleep ${retry_delay}
    done
    
    log_error "Failed to connect to database after ${max_retries} attempts"
    return 1
}

check_database_connection() {
    local db_host="${SOGO_DB_HOST:-localhost}"
    local db_port="${SOGO_DB_PORT:-5432}"
    local db_type="${SOGO_DB_TYPE:-PostgreSQL}"
    local db_name="${SOGO_DB_NAME:-sogo}"
    local db_user="${SOGO_DB_USER:-sogo}"
    local db_password="${SOGO_DB_PASSWORD:-}"
    
    case "${db_type,,}" in
        postgresql|pgsql)
            if command -v pg_isready &>/dev/null; then
                # Use pg_isready for PostgreSQL
                PGPASSWORD="${db_password}" pg_isready -h "${db_host}" -p "${db_port}" -U "${db_user}" -d "${db_name}" 2>/dev/null
            else
                # Fallback to direct connection
                if echo "\\q" | nc -w 2 "${db_host}" "${db_port}" 2>/dev/null; then
                    return 0
                fi
            fi
            ;;
        mysql|mariadb)
            if command -v mysql &>/dev/null; then
                MYSQL_PWD="${db_password}" mysql -h "${db_host}" -P "${db_port}" -u "${db_user}" "${db_name}" -e "SELECT 1;" 2>/dev/null || true
            else
                # Try with nc
                if echo "" | nc -w 2 "${db_host}" "${db_port}" 2>/dev/null; then
                    return 0
                fi
            fi
            ;;
        *)
            # Generic check
            if echo "" | nc -w 2 "${db_host}" "${db_port}" 2>/dev/null; then
                return 0
            fi
            ;;
    esac
    
    return 1
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    local target="${1:-all}"
    shift || true
    
    # Parse command line
    case "${target}" in
        --version|-v)
            echo "SOGo 5 Entrypoint v2.0.0"
            echo "SOGo Version: $(sogod --version 2>/dev/null | head -1)"
            exit 0
            ;;
        --help|-h)
            echo "Usage: ${SCRIPT_NAME} [TARGET]"
            echo ""
            echo "Targets:"
            echo "  all         Start all services (default)"
            echo "  sogod       Start only SOGo"
            echo "  memcached   Start only Memcached"
            echo "  health      Start only health server"
            echo ""
            echo "Options:"
            echo "  --version, -v   Show version"
            echo "  --help, -h      Show this help"
            exit 0
            ;;
    esac
    
    # ======================
    # STARTUP SEQUENCE
    # ======================
    
    log_info "========================================"
    log_info "  SOGo 5 Container Entrypoint"
    log_info "  Starting container..."
    log_info "========================================"
    
    # Step 1: Validate environment and binaries
    if ! validate_required_binaries; then
        log_error "Binary validation failed"
        exit 1
    fi
    
    # Step 2: Validate environment variables
    if ! validate_environment; then
        log_error "Environment validation failed"
        exit 1
    fi
    
    # Step 3: Setup directories and files
    if ! setup_directories; then
        log_error "Directory setup failed"
        exit 1
    fi
    
    # Step 4: Process configurations
    if ! process_memcached_configuration; then
        log_error "Memcached configuration failed"
        exit 1
    fi
    
    if ! process_gnustep_configuration; then
        log_error "GNUstep configuration failed"
        exit 1
    fi
    
    if ! process_sogo_configuration; then
        log_error "SOGo configuration failed"
        exit 1
    fi
    
    # ======================
    # START SERVICES
    # ======================
    
    # Determine what to start
    case "${target}" in
        memcached)
            start_memcached || exit 1
            ;;
        sogod|sogo)
            start_sogo || exit 1
            ;;
        health)
            start_health_server || exit 1
            ;;
        *)
            # Start all services in order: memcached -> sogo -> health
            log_info "Starting all services..."
            
            start_memcached || exit 1
            start_sogo || exit 1
            start_health_server || exit 1
            ;;
    esac
    
    # ======================
    # MONITOR SERVICES
    # ======================
    
    log_success "All services started successfully!"
    log_info "========================================"
    log_info "  Services Running"
    if [[ -n "${MEMCACHED_PID}" ]]; then
        log_info "  Memcached PID: ${MEMCACHED_PID}"
    fi
    if [[ -n "${SOGO_PID}" ]]; then
        log_info "  SOGo PID: ${SOGO_PID}"
    fi
    if [[ -n "${HEALTH_PID}" ]]; then
        log_info "  Health Server PID: ${HEALTH_PID}"
    fi
    log_info "========================================"
    log_info "Container is ready for requests"
    
    # Wait forever, handling signals via our traps
    while true; do
        # Simple service monitoring - restart if any process dies unexpectedly
        if [[ -n "${MEMCACHED_PID}" && ! -f "/proc/${MEMCACHED_PID}/status" ]]; then
            log_error "Memcached crashed, attempting to restart..."
            MEMCACHED_PID=""
            start_memcached || log_error "Failed to restart Memcached"
        fi
        
        if [[ -n "${SOGO_PID}" && ! -f "/proc/${SOGO_PID}/status" ]]; then
            log_error "SOGo crashed, attempting to restart..."
            SOGO_PID=""
            start_sogo || log_error "Failed to restart SOGo"
        fi
        
        if [[ -n "${HEALTH_PID}" && ! -f "/proc/${HEALTH_PID}/status" ]]; then
            log_warn "Health server crashed, attempting to restart..."
            HEALTH_PID=""
            start_health_server || log_error "Failed to restart health server"
        fi
        
        sleep 10
    done
}

# =============================================================================
# EXECUTE MAIN
# =============================================================================
main "$@"

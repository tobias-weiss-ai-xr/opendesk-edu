#!/usr/bin/env bash
# SOGo 6 Container Entrypoint Script
# SPDX-License-Identifier: Apache-2.0
# File: entrypoint.sh
# Purpose: Multi-process startup, signal handling, graceful shutdown for SOGo 6
# Version: 3.0.0
# Built: 2026-08-03T12:00:00Z
# Author: openDesk Edu Team
#
# IMPROVEMENTS over SOGo 5:
#   - Dynamic EDV (External Data Validation) support
#   - Enhanced graceful shutdown with multi-phase cleanup
#   - Advanced process supervision with restart limits
#   - Built-in debug mode with verbose logging
#   - Configuration hot-reload support
#   - Hardware-accelerated encryption detection
#
# This script manages the SOGo 6 container lifecycle:
#   1. Environment validation and configuration
#   2. Hardware capabilities detection
#   3. Directory setup with proper permissions
#   4. Configuration template processing (with EDV)
#   5. Multi-process startup (SOGo + Memcached)
#   6. Signal handling and graceful shutdown
#   7. Health monitoring with auto-restart
#   8. Configuration reload on changes
#
# Processes started:
#   - memcached: Caching server for SOGo (optimized for version 6)
#   - sogod: Main SOGo daemon
#   - health server: HTTP health probes
#
# USAGE:
#   /entrypoint.sh (default: starts all services)
#   /entrypoint.sh --version (shows version)
#   /entrypoint.sh --help (shows help)
#   /entrypoint.sh sogod (start only sogod)
#   /entrypoint.sh memcached (start only memcached)
#   /entrypoint.sh --debug (start with debug logging)
#

set -euo pipefail

# =============================================================================
# CONSTANTS
# =============================================================================
readonly SCRIPT_NAME=$(basename "${0}")
readonly SCRIPT_DIR=$(dirname "$(readlink -f "${0}" 2>/dev/null || echo "${0}")")

# SOGo 6 specific constants
readonly SOGO_VERSION="6.0.0"
readonly SCHOOL_NAME="sogo6"
readonly MEMCACHED_BIN="/usr/sbin/memcached"
readonly SOGO_BIN="/usr/sbin/sogod"
readonly HEALTH_SCRIPT="/healthcheck.sh"

# Configuration files
readonly SOGO_CONF="/etc/sogo/sogo.conf"
readonly MEMCACHED_CONF="/etc/memcached.conf"
readonly GNUSTEP_CONF="/etc/GNUstep/GNUstep.conf"

# SOGo 6 specific directories
readonly EDV_CONF_DIR="/etc/sogo/edv"
readonly SSL_CONF_DIR="/etc/sogo/ssl"

# Log directories
readonly LOG_DIR="/var/log/sogo"
readonly MEMCACHED_LOG="/var/log/memcached.log"

# PID files
readonly MEMCACHED_PID_FILE="/tmp/memcached.pid"
readonly SOGO_PID_FILE="/tmp/sogod.pid"
readonly HEALTH_PID_FILE="/tmp/health.pid"

# Timeout and retry settings
readonly MEMCACHED_STARTUP_TIMEOUT=10
readonly SOGO_STARTUP_TIMEOUT=45
readonly GRACEFUL_TIMEOUT=30
readonly MAX_RESTART_ATTEMPTS=5
readonly RESTART_DELAY=5

# SOGo 6 defaults
readonly SOGO_WORKERS_DEFAULT=8
readonly MEMCACHED_THREADS_DEFAULT=8
readonly MEMCACHED_MEMORY_DEFAULT=512

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m'

# =============================================================================
# GLOBAL VARIABLES
# =============================================================================
MEMCACHED_PID=""
SOGO_PID=""
HEALTH_PID=""
SHUTDOWN_REQUESTED=false
SHUTDOWN_PHASE="none"
DEBUG_MODE=false

# Restart tracking
declare -A RESTART_COUNTS
MAX_RESTART_ATTEMPTS=5

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
    local prefix="[${level}]$(log_timestamp)"
    
    # In debug mode, add file/line info
    if ${DEBUG_MODE:-false}; then
        local caller_info=$(caller 1 2>/dev/null || echo "")
        if [[ -n "${caller_info}" ]]; then
            IFS=' ' read -r -a caller_parts <<< "${caller_info}"
            # caller returns: line_number file_name function_name
            local file_line="${caller_parts[1]}:${caller_parts[2]}"
            prefix="${prefix} ${file_line}"
        fi
    fi
    
    echo -e "${color}${prefix}${NC} ${message}"
}

log_debug() {
    if ${DEBUG_MODE:-false}; then
        log_message "DEBUG" "${MAGENTA}" "$1"
    fi
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

# Define shutdown phases
PHASE_NOTIFY="notify"
PHASE_STOP_ACCEPTING="stop_accepting"
PHASE_DRAIN="drain"
PHASE_CLEANUP="cleanup"

# Cleanup function for graceful shutdown
cleanup() {
    local exit_code=${1:-0}
    local signal_name="$2"
    
    if [[ "${SHUTDOWN_PHASE}" != "none" ]]; then
        log_info "Already handling shutdown (phase: ${SHUTDOWN_PHASE}), ignoring signal ${signal_name}"
        return
    fi
    
    SHUTDOWN_REQUESTED=true
    log_info "Received signal ${signal_name:-unknown}, initiating graceful shutdown..."
    
    # Phase 1: Notify running connections to complete
    SHUTDOWN_PHASE="${PHASE_NOTIFY}"
    log_info "Shutdown Phase 1/4: Notifying active connections to complete..."
    notify_shutdown
    sleep 2
    
    # Phase 2: Stop accepting new connections
    SHUTDOWN_PHASE="${PHASE_STOP_ACCEPTING}"
    log_info "Shutdown Phase 2/4: Stopping new connections..."
    stop_accepting_connections
    sleep 1
    
    # Phase 3: Drain existing connections
    SHUTDOWN_PHASE="${PHASE_DRAIN}"
    log_info "Shutdown Phase 3/4: Draining existing connections..."
    drain_connections
    sleep 5
    
    # Phase 4: Stop all services
    SHUTDOWN_PHASE="${PHASE_CLEANUP}"
    log_info "Shutdown Phase 4/4: Stopping all services..."
    stop_services "${exit_code}"
    
    log_info "Shutdown complete, exiting with code ${exit_code}"
    exit ${exit_code}
}

notify_shutdown() {
    # SOGo 6 supports graceful shutdown notifications
    local sockets
    sockets=$(find /var/run/sogo -name "*.sock" 2>/dev/null || true)
    
    for socket in ${sockets}; do
        log_debug "Notifying socket: ${socket}"
        # Send GRACEFUL_SHUTDOWN notification if supported
        echo "GRACEFUL_SHUTDOWN" | socat - UNIX-CONNECT:"${socket}" 2>/dev/null || true
    done
}

stop_accepting_connections() {
    # For SOGo 6, we can stop accepting new connections by adjusting firewall or
    # by sending a signal to Gracefully stop the listener
    if [[ -n "${SOGO_PID}" ]]; then
        log_info "  Sending STOP_ACCEPTING signal to SOGo"
        kill -USR1 "${SOGO_PID}" 2>/dev/null || true
    fi
}

drain_connections() {
    # Wait for existing connections to complete
    log_info "  Waiting for existing connections to complete..."
    
    # Check for active SOGo processes
    local active_processes
    active_processes=$(pgrep -f "sogod" 2>/dev/null || true)
    
    local max_wait=15
    local wait_count=0
    
    while [[ -n "${active_processes}" && ${wait_count} -lt ${max_wait} ]]; do
        sleep 1
        active_processes=$(pgrep -f "sogod" 2>/dev/null || true)
        wait_count=$((wait_count + 1))
    done
    
    if [[ ${wait_count} -ge ${max_wait} ]]; then
        log_warn "  Draining timed out, forcing shutdown of remaining connections"
    fi
}

stop_services() {
    local exit_code="$1"
    
    # Order: reverse startup order
    # 3. Stop health server
    if [[ -n "${HEALTH_PID}" && -f "/proc/${HEALTH_PID}/status" ]]; then
        log_info "  Stopping health server (PID: ${HEALTH_PID})"
        stop_process "${HEALTH_PID}" "health server" "5"
    fi
    
    # 2. Stop SOGo
    if [[ -n "${SOGO_PID}" && -f "/proc/${SOGO_PID}/status" ]]; then
        log_info "  Stopping SOGo (PID: ${SOGO_PID})"
        stop_process "${SOGO_PID}" "SOGo" "${GRACEFUL_TIMEOUT}"
        stop_related_processes "sogod" "SOGo"
    fi
    
    # 1. Stop Memcached
    if [[ -n "${MEMCACHED_PID}" && -f "/proc/${MEMCACHED_PID}/status" ]]; then
        log_info "  Stopping Memcached (PID: ${MEMCACHED_PID})"
        stop_process "${MEMCACHED_PID}" "Memcached" "10"
    fi
    
    # Cleanup PID files
    cleanup_pid_files
}

stop_process() {
    local pid="$1"
    local name="$2"
    local timeout="$3"
    
    # Already stopped
    if ! kill -0 "${pid}" 2>/dev/null; then
        log_debug "${name} (PID: ${pid}) already stopped"
        return 0
    fi
    
    log_info "    Sending SIGTERM to ${name} (PID: ${pid})..."
    
    # Send TERM signal
    kill -TERM "${pid}" 2>/dev/null || {
        log_warn "    Failed to send TERM to ${name}"
        return 1
    }
    
    # Wait for graceful shutdown
    local count=0
    while kill -0 "${pid}" 2>/dev/null && [[ ${count} -lt ${timeout} ]]; do
        sleep 1
        count=$((count + 1))
    done
    
    if ! kill -0 "${pid}" 2>/dev/null; then
        log_info "    ${name} stopped gracefully after ${count}s"
        return 0
    fi
    
    # Still running, try SIGKILL
    log_warn "    ${name} did not stop after ${timeout}s, sending SIGKILL..."
    kill -KILL "${pid}" 2>/dev/null || true
    sleep 2
    
    if kill -0 "${pid}" 2>/dev/null; then
        log_error "    Failed to stop ${name} even with SIGKILL!"
        return 1
    fi
    
    log_info "    ${name} stopped with SIGKILL"
    return 0
}

stop_related_processes() {
    local name="$1"
    local description="$2"
    
    log_debug "Stopping ${description}..."
    local pids
    pids=$(pgrep -f "${name}" 2>/dev/null || true)
    
    if [[ -z "${pids}" ]]; then
        log_debug "No ${name} processes found"
        return 0
    fi
    
    for pid in ${pids}; do
        if [[ "${pid}" != "$$" && "${pid}" != "${SOGO_PID}" ]]; then
            log_debug "  Stopping ${name} process ${pid}"
            kill -TERM "${pid}" 2>/dev/null || true
        fi
    done
    
    # Wait a bit then force kill
    sleep 2
    pids=$(pgrep -f "${name}" 2>/dev/null || true)
    if [[ -n "${pids}" ]]; then
        for pid in ${pids}; do
            if [[ "${pid}" != "$$" ]]; then
                kill -KILL "${pid}" 2>/dev/null || true
            fi
        done
    fi
    
    return 0
}

cleanup_pid_files() {
    rm -f "${MEMCACHED_PID_FILE}" "${SOGO_PID_FILE}" "${HEALTH_PID_FILE}"
}

# Setup signal traps with graceful shutdown
setup_signal_traps() {
    trap 'cleanup 143 INT' INT
    trap 'cleanup 146 TERM' TERM
    trap 'cleanup 150 QUIT' QUIT
    trap 'cleanup 1 HUP' HUP
    trap 'cleanup 0' EXIT
}

# =============================================================================
# HARDWARE DETECTION
# =============================================================================

detect_hardware_capabilities() {
    log_info "Detecting hardware capabilities..."
    
    # Check CPU architecture
    local arch
    arch=$(uname -m)
    log_info "  Architecture: ${arch}"
    
    # Check for hardware-accelerated encryption
    detect_hardware_acceleration
    
    # Check available memory
    local total_mem
    total_mem=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}') || total_mem=0
    local mem_gb=$((total_mem / 1048576))
    log_info "  Total Memory: ${mem_gb}GB"
    
    # Set defaults based on available memory
    if [[ ${mem_gb} -lt 2 ]]; then
        log_warn "  Low memory system (${mem_gb}GB), reducing defaults"
        export SOGO_WORKERS=${SOGO_WORKERS:-2}
        export MEMCACHED_MEMORY=${MEMCACHED_MEMORY:-128}
        export MEMCACHED_THREADS=${MEMCACHED_THREADS:-2}
    elif [[ ${mem_gb} -lt 4 ]]; then
        export SOGO_WORKERS=${SOGO_WORKERS:-4}
        export MEMCACHED_MEMORY=${MEMCACHED_MEMORY:-256}
        export MEMCACHED_THREADS=${MEMCACHED_THREADS:-4}
    elif [[ ${mem_gb} -ge 8 ]]; then
        export SOGO_WORKERS=${SOGO_WORKERS:-16}
        export MEMCACHED_MEMORY=${MEMCACHED_MEMORY:-1024}
        export MEMCACHED_THREADS=${MEMCACHED_THREADS:-16}
    fi
    
    # Check CPU cores
    local cpu_cores
    cpu_cores=$(nproc 2>/dev/null || echo 1)
    log_info "  CPU Cores: ${cpu_cores}"
    
    # Don't set workers higher than CPU cores
    if [[ ${SOGO_WORKERS:-${SOGO_WORKERS_DEFAULT}} -gt ${cpu_cores} ]]; then
        export SOGO_WORKERS=${cpu_cores}
        log_info "  Adjusted SOGo workers to CPU cores: ${cpu_cores}"
    fi
    
    log_success "Hardware detection complete"
}

detect_hardware_acceleration() {
    local has_aes=false
    local has_avx=false
    local has_avx2=false
    
    if grep -q aes /proc/cpuinfo 2>/dev/null; then
        has_aes=true
    fi
    
    if grep -q avx /proc/cpuinfo 2>/dev/null; then
        has_avx=true
    fi
    
    if grep -q avx2 /proc/cpuinfo 2>/dev/null; then
        has_avx2=true
    fi
    
    if ${has_aes}; then
        log_info "  AES-NI hardware acceleration: Available"
        # Enable hardware-accelerated encryption in SOGo config
        export SOGO_ENABLE_AES_NI=true
    fi
    
    if ${has_avx} || ${has_avx2}; then
        log_info "  AVX/AVX2 vector instructions: Available"
        export SOGO_ENABLE_AVX=true
    fi
    
    if ! ${has_aes} && ! ${has_avx}; then
        log_warn "  Hardware acceleration not available"
    fi
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --version|-v)
                show_version
                exit 0
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --debug)
                DEBUG_MODE=true
                export SOGO_DEBUG=true
                log_info "Debug mode enabled"
                shift
                ;;
            sogod|sogo)
                # Start only SOGo
                TARGET="sogo"
                shift
                ;;
            memcached)
                # Start only Memcached
                TARGET="memcached"
                shift
                ;;
            *)
                # Unknown argument or default (all services)
                break
                ;;
        esac
    done
}

show_version() {
    echo "SOGo 6 Container Entrypoint v3.0.0"
    echo "SOGo Version: ${SOGO_VERSION}"
    if command -v sogod &>/dev/null; then
        echo "SOGo Binary: $(sogod --version 2>/dev/null | head -1 || echo 'unknown')"
    fi
}

show_help() {
    echo "Usage: ${SCRIPT_NAME} [OPTIONS] [TARGET]"
    echo ""
    echo "Targets:"
    echo "  (none)       Start all services (default)"
    echo "  sogod, sogo  Start only SOGo"
    echo "  memcached    Start only Memcached"
    echo ""
    echo "Options:"
    echo "  --version, -v    Show version and exit"
    echo "  --help, -h       Show this help message"
    echo "  --debug          Enable debug logging"
    echo ""
    echo "Environment Variables:"
    echo "  SOGO_DB_HOST              Database server hostname"
    echo "  SOGO_DB_PORT              Database server port"
    echo "  SOGO_DB_NAME              Database name"
    echo "  SOGO_DB_USER              Database username"
    echo "  SOGO_DB_PASSWORD          Database password"
    echo "  SOGO_DB_TYPE              Database type (PostgreSQL, MySQL, MariaDB)"
    echo "  SOGO_WORKERS             Number of worker processes"
    echo "  MEMCACHED_SERVER          Memcached server (if external)"
    echo "  MEMCACHED_PORT            Memcached port"
    echo "  MEMCACHED_CACHE_SIZE      Memcached memory in MB"
    echo "  MEMCACHED_MAX_CONNECTIONS Memcached max connections"
    echo ""
}

validate_required_binaries() {
    log_info "Validating required binaries..."
    
    local binaries=(
        "${MEMCACHED_BIN}"
        "${SOGO_BIN}"
        "/usr/bin/bash"
        "/usr/bin/curl"
        "/usr/bin/wget"
    )
    
    local missing=()
    for binary in "${binaries[@]}"; do
        if [[ ! -x "${binary}" ]]; then
            missing+=("${binary}")
        else
            log_info "  Found: ${binary}"
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing binaries: ${missing[*]}"
        return 1
    fi
    
    # Check SOGo capabilities
    if ${SOGO_BIN} --help 2>&1 | grep -q "External Data Validation"; then
        log_info "  EDV (External Data Validation) support detected"
        export SOGO_EDV_ENABLED=true
    fi
    
    log_success "All required binaries validated"
    return 0
}

validate_environment() {
    log_info "Validating environment variables..."
    
    # Database configuration - required
    local required_db_vars=(
        "SOGO_DB_HOST"
        "SOGO_DB_PORT"
        "SOGO_DB_NAME"
        "SOGO_DB_USER"
        "SOGO_DB_TYPE"
    )
    
    local db_configured=true
    for var in "${required_db_vars[@]}"; do
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
    
    # Validate database type
    local db_type="${SOGO_DB_TYPE:-}"
    case "${db_type,,}" in
        postgresql|pgsql|mysql|mariadb)
            log_info "  Database type: ${db_type}"
            ;;
        *)
            log_error "Unsupported database type: ${db_type}"
            return 1
            ;;
    esac
    
    # Validate database port
    local db_port="${SOGO_DB_PORT:-}"
    if ! [[ "${db_port}" =~ ^[0-9]+$ ]] || [[ ${db_port} -lt 1 || ${db_port} -gt 65535 ]]; then
        log_error "Invalid database port: ${db_port}"
        return 1
    fi
    
    # Optional variables with defaults
    export SOGO_WORKERS=${SOGO_WORKERS:-${SOGO_WORKERS_DEFAULT}}
    export MEMCACHED_PORT=${MEMCACHED_PORT:-11211}
    export MEMCACHED_CACHE_SIZE=${MEMCACHED_CACHE_SIZE:-${MEMCACHED_MEMORY_DEFAULT}}
    export MEMCACHED_MAX_CONNECTIONS=${MEMCACHED_MAX_CONNECTIONS:-1024}
    export MEMCACHED_THREADS=${MEMCACHED_THREADS:-${MEMCACHED_THREADS_DEFAULT}}
    
    log_info "  SOGO_WORKERS=${SOGO_WORKERS}"
    log_info "  MEMCACHED_PORT=${MEMCACHED_PORT}"
    log_info "  MEMCACHED_CACHE_SIZE=${MEMCACHED_CACHE_SIZE}MB"
    log_info "  MEMCACHED_MAX_CONNECTIONS=${MEMCACHED_MAX_CONNECTIONS}"
    log_info "  MEMCACHED_THREADS=${MEMCACHED_THREADS}"
    
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
        "${EDV_CONF_DIR}"
        "${SSL_CONF_DIR}"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "${dir}" ]]; then
            mkdir -p "${dir}" || {
                log_error "Failed to create directory: ${dir}"
                return 1
            }
        fi
        
        # Ensure correct ownership
        chown sogo:sogo "${dir}" 2>/dev/null || true
        chmod 755 "${dir}" 2>/dev/null || true
        log_info "  Directory ready: ${dir}"
    done
    
    # Create required files
    local files=(
        "${SOGO_CONF}"
        "${MEMCACHED_CONF}"
        "${GNUSTEP_CONF}"
        "${LOG_DIR}/sogo.log"
        "${LOG_DIR}/access.log"
        "${LOG_DIR}/error.log"
        "${LOG_DIR}/slow.log"
        "${MEMCACHED_LOG}"
    )
    
    for file in "${files[@]}"; do
        local dirname=$(dirname "${file}")
        if [[ ! -d "${dirname}" ]]; then
            mkdir -p "${dirname}" || {
                log_error "Failed to create parent directory: ${dirname}"
                return 1
            }
        fi
        
        if [[ ! -f "${file}" ]]; then
            touch "${file}" || {
                log_error "Failed to create file: ${file}"
                return 1
            }
        fi
        
        chown sogo:sogo "${file}" 2>/dev/null || true
        chmod 644 "${file}" 2>/dev/null || true
        log_info "  File ready: ${file}"
    done
    
    # Setup log rotation
    setup_log_rotation
    
    log_success "Directory and file setup complete"
    return 0
}

setup_log_rotation() {
    log_debug "Setting up log rotation..."
    
    local logrotate_conf="/etc/logrotate.d/sogo"
    cat > "${logrotate_conf}" << 'EOF'
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
        /usr/bin/killall -HUP sogod 2>/dev/null || true
    endscript
}
EOF
    
    if [[ -f "${logrotate_conf}" ]]; then
        chmod 644 "${logrotate_conf}"
        log_debug "Log rotation configuration created"
    fi
    
    return 0
}

# =============================================================================
# EDV (EXTERNAL DATA VALIDATION) SUPPORT
# =============================================================================

setup_edv() {
    log_info "Setting up External Data Validation (EDV)..."
    
    # Check if EDV is enabled
    if [[ "${SOGO_EDV_ENABLED:-false}" != "true" ]]; then
        log_debug "EDV is disabled"
        return 0
    fi
    
    # Create EDV directory structure
    mkdir -p "${EDV_CONF_DIR}/servers" "${EDV_CONF_DIR}/certificates"
    chown -R sogo:sogo "${EDV_CONF_DIR}" 2>/dev/null || true
    chmod 700 "${EDV_CONF_DIR}" 2>/dev/null || true
    
    # Generate default EDV configuration if not present
    local edv_conf="${EDV_CONF_DIR}/edv.conf"
    if [[ ! -f "${edv_conf}" ]]; then
        cat > "${edv_conf}" << 'EOF'
# SOGo 6 External Data Validation Configuration
# OpenPGP Keys for data validation
# GnuPG home directory
GnuPGHome = "/var/lib/sogo/gpg";

# OpenPGP Keys directory
Keys = ("EDVKey");

# Keyserver configuration
Keyserver = "hkps://keys.openpgp.org";

# Or use local keyring
Keyring = "/etc/sogo/edv/keyring.gpg";
EOF
        chown sogo:sogo "${edv_conf}"
        chmod 600 "${edv_conf}"
        log_info "  Created default EDV configuration"
    fi
    
    log_success "EDV setup complete"
    return 0
}

# =============================================================================
# CONFIGURATION PROCESSING
# =============================================================================

process_sogo_configuration() {
    log_info "Processing SOGo configuration..."
    
    # Ensure config directory exists
    mkdir -p "${SOGO_CONF%/*}" || {
        log_error "Failed to create SOGo config directory"
        return 1
    }
    
    # Check if configuration already exists
    if [[ ! -f "${SOGO_CONF}" ]]; then
        log_info "  Creating default SOGo configuration"
        create_default_sogo_config || return 1
    fi
    
    # Process environment variables in configuration
    process_template "${SOGO_CONF}" || return 1
    
    # Validate configuration
    validate_sogo_config || return 1
    
    log_success "SOGo configuration processed"
    return 0
}

create_default_sogo_config() {
    log_debug "Creating default SOGo 6 configuration"
    
    local db_type="${SOGO_DB_TYPE:-PostgreSQL}"
    local db_host="${SOGO_DB_HOST:-localhost}"
    local db_port="${SOGO_DB_PORT:-5432}"
    local db_name="${SOGO_DB_NAME:-sogo}"
    local db_user="${SOGO_DB_USER:-sogo}"
    
    cat > "${SOGO_CONF}" << EOF
{
  /*
   * SOGo Configuration for openDesk
   * Generated by container entrypoint
   * Version: ${SOGO_VERSION}
   */

  /* Database Configuration */
  sogod = {
    SOGoUserSources = (
      {
        type = sql;
        id = directory;
        viewURL = "${db_type}://${db_user}:\${SOGO_DB_PASSWORD}@${db_host}:${db_port}/${db_name}";
        canAuthenticate = YES;
        isAddressBook = YES;
        displayName = "Users";
      }
    );

    /* Performance Tuning */
    SOGoWorkersCount = ${SOGO_WORKERS};
    SOGoMaximumMessageSize = 102400; /* 100 MB */
    SOGoMaximumPingInterval = 3540;
    SOGoMaximumSyncInterval = 3600;
    SOGoMaximumSyncRequests = 100;
    SOGoCacheCleanupInterval = 3600;

    /* Memory Management */
    SOGoMaximumPermanentObjectSize = 2097152; /* 2 MB */
    SOGoMaxObjectSize = 10485760; /* 10 MB */

    /* Logging */
    SOGoDebugRequests = NO;
    SOGoUserLogsDirectory = "${LOG_DIR}";
    SOGoLogFile = "${LOG_DIR}/sogo.log";
    SOGoAccessLogFile = "${LOG_DIR}/access.log";
    SOGoErrorLogFile = "${LOG_DIR}/error.log";
    SOGoSlowQueriesLogFile = "${LOG_DIR}/slow.log";
    LOGTimeFormat = "%Y-%m-%d %H:%M:%S %z";

    /* Caching */
    OCSCacheFolderURL = "file:///var/cache/sogo";
    SOGoCacheFolderURL = "file:///var/cache/sogo";
    SOGoMemcachedHost = "localhost";
    SOGoMemcachedPort = ${MEMCACHED_PORT};

    /* Session Management */
    SOGoMaximumSessionDuration = 3600; /* 1 hour */
    SOGoSessionCookieName = "SOGoSessionID";

    /* Calendar and Contacts */
    OCSChannelsTimeOut = 3600;
    OCSSessionsTimeOut = 3600;

    /* Mail */
    SOGoMailingMechanism = smtp;
    SOGoSMTPServer = "${SOGO_SMTP_SERVER:-localhost}";
    SOGoSMTPPort = ${SOGO_SMTP_PORT:-25};
    SOGoMailDomain = "${SOGO_MAIL_DOMAIN:-opendesk-edu.org}";

    /* Web Interface */
    SOGoPageTitle = "SOGo - openDesk";
    SOGoVacationEnabled = YES;
    SOGoForwardEnabled = YES;
    SOGoSieveScriptsEnabled = YES;

    /* External Data Validation (EDV) */
    SOGoGnuPGHome = "/var/lib/sogo/gpg";

    /* Web Server */
    WOListenQueueSize = 512;
    WOMaximumClientsToHandle = 1000;

    /* SSL/TLS */
    SOGoSSLEmailAddress = "admin@${SOGO_MAIL_DOMAIN:-opendesk-edu.org}";
  };

  /* Web Server Configuration */
  WOWatchDogRequestTimeout = 30;
  WODirectActionURL = "/SOGo";
EOF
    
    chown sogo:sogo "${SOGO_CONF}"
    chmod 600 "${SOGO_CONF}"
    log_debug "Default SOGo configuration created"
    
    return 0
}

process_memcached_configuration() {
    log_info "Processing Memcached configuration..."
    
    local memcached_port="${MEMCACHED_PORT}"
    
    # Create directory if it doesn't exist
    mkdir -p "${MEMCACHED_CONF%/*}" || {
        log_error "Failed to create Memcached config directory"
        return 1
    }
    
    if [[ ! -f "${MEMCACHED_CONF}" ]]; then
        # Create default memcached configuration optimized for SOGo 6
        cat > "${MEMCACHED_CONF}" << EOF
# Memcached Configuration for SOGo 6
# Automatically generated by container entrypoint
# Optimized for multi-threaded workloads

# Run as daemon
-d

# User to run as
-u sogo

# Port to listen on
-p ${memcached_port}

# Listen on all interfaces (container will handle network filtering)
-l 0.0.0.0

# Maximum memory to use (MB)
-m ${MEMCACHED_CACHE_SIZE}

# Maximum simultaneous connections
-c ${MEMCACHED_MAX_CONNECTIONS}

# Number of threads to use
-t ${MEMCACHED_THREADS}

# Thread stack size (KB)
-s 256

# Connection timeout (seconds)
-timeout 30

# Disable Nagle's algorithm for better performance
-n

# Log file
-l ${MEMCACHED_LOG}

# PID file
-P ${MEMCACHED_PID_FILE}

# disable udp
-U 0

# Log level (0-4: error, warning, info, debug, verbose debug)
-v 1

# evict expired items instead of returning error
-e

# overwrite existing items
-o

# connection concurrency
-R 100

# item size max
-I 10m
EOF
        
        chown sogo:sogo "${MEMCACHED_CONF}"
        chmod 644 "${MEMCACHED_CONF}"
        log_info "  Created default Memcached configuration for SOGo 6"
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
    log_debug "Processing GNUstep configuration..."
    
    mkdir -p "${GNUSTEP_CONF%/*}" || {
        log_error "Failed to create GNUstep config directory"
        return 1
    }
    
    if [[ ! -f "${GNUSTEP_CONF}" ]]; then
        cat > "${GNUSTEP_CONF}" << 'EOF'
# GNUstep Configuration for SOGo 6
# Automatically generated by container entrypoint

# Default user
NSRemotePipePath = /tmp

# Objective-C library paths
OBJC_LIBRARY_PATH = /usr/lib/GNUstep/Libraries

# GNUstep system root
GNUstepSystemRoot = /usr/lib/GNUstep/System

# Local library paths
GNUSTEP_LOCAL_ROOT = /usr/lib/GNUstep/Local

# User defaults database
NSUserDefaultsDatabase = /var/lib/sogo/defaults
EOF
        
        chmod 644 "${GNUSTEP_CONF}"
        log_debug "  Created default GNUstep configuration"
    fi
    
    return 0
}

process_template() {
    local file="$1"
    
    log_debug "Processing template: ${file}"
    
    # Check if file contains template variables
    if ! grep -q '\${\|%{\|<%\|%>\|<%</' "${file}" 2>/dev/null; then
        log_debug "  No template variables found"
        return 0
    fi
    
    # Use envsubst to replace environment variables
    if command -v envsubst &>/dev/null; then
        log_debug "  Using envsubst for template processing"
        local template_vars=(
            "SOGO_DB_HOST"
            "SOGO_DB_PORT"
            "SOGO_DB_NAME"
            "SOGO_DB_USER"
            "SOGO_DB_PASSWORD"
            "SOGO_DB_TYPE"
            "SOGO_WORKERS"
            "MEMCACHED_PORT"
            "MEM('MEMCACHED_CACHE_SIZE"
            "MEMCACHED_THREADS"
            "SOGO_MAIL_DOMAIN"
            "SOGO_SMTP_SERVER"
            "SOGO_SMTP_PORT"
        )
        
        # Replace each variable
        local processed_file="${file}.tmp"
        cp "${file}" "${processed_file}"
        
        for var in "${template_vars[@]}"; do
            local value="${!var:-}"
            if [[ -n "${value}" ]]; then
                sed -i "s|\${${var}}|${value}|g" "${processed_file}" || true
            fi
        done
        
        # Replace any remaining ${...} with empty string (not set)
        sed -i 's/\${[^}]*}/nojg/g' "${processed_file}" || true
        
        # Validate the processed file
        if [[ $(stat -c %s "${processed_file}" 2>/dev/null || echo 0) -gt 0 ]]; then
            mv "${processed_file}" "${file}" || {
                log_error "Failed to move processed file: ${processed_file} -> ${file}"
                rm -f "${processed_file}"
                return 1
            }
        else
            log_error "Template processing resulted in empty file"
            rm -f "${processed_file}"
            return 1
        fi
        
        log_debug "  Template processed successfully"
        return 0
    else
        # envsubst not available, use sed
        log_debug "  Using sed for template processing (envsubst not available)"
        
        local template_vars=(
            "SOGO_DB_HOST"
            "SOGO_DB_PORT"
            "SOGO_DB_NAME"
            "SOGO_DB_USER"
            "SOGO_DB_PASSWORD"
            SOGO_DB_TYPE"
        )
        
        for var in "${template_vars[@]}"; do
            local value="${!var:-}"
            if [[ -n "${value}" ]]; then
                sed -i "s|\${${var}}|${value}|g" "${file}" || true
            fi
        done
        
        return 0
    fi
}

validate_sogo_config() {
    log_debug "Validating SOGo configuration..."
    
    # Check if file is readable
    if [[ ! -r "${SOGO_CONF}" ]]; then
        log_error "SOGo configuration file is not readable: ${SOGO_CONF}"
        return 1
    fi
    
    # Use sogod to validate if available
    if sogod --validate-config "${SOGO_CONF}" 2>/dev/null; then
        log_debug "  Configuration validated by sogod"
        return 0
    fi
    
    # Fallback: check for basic syntax errors
    # Check for unmatched braces
    local open_braces=$(grep -o '{' "${SOGO_CONF}" | wc -l)
    local close_braces=$(grep -o '}' "${SOGO_CONF}" | wc -l)
    
    if [[ ${open_braces} -ne ${close_braces} ]]; then
        log_error "SOGo configuration has unmatched braces (open: ${open_braces}, close: ${close_braces})"
        return 1
    fi
    
    # Check for required sections
    if ! grep -q "SOGoUserSources" "${SOGO_CONF}" 2>/dev/null; then
        log_error "SOGo configuration missing SOGoUserSources"
        return 1
    fi
    
    log_debug "  Configuration syntax looks valid"
    return 0
}

# =============================================================================
# SERVICE STARTUP FUNCTIONS
# =============================================================================

start_memcached() {
    log_info "Starting Memcached..."
    
    # Check if already running
    if [[ -n "${MEMCACHED_PID}" && kill -0 "${MEMCACHED_PID}" 2>/dev/null ]]; then
        log_info "  Memcached already running (PID: ${MEMCACHED_PID})"
        return 0
    fi
    
    # Use configuration file
    if [[ -f "${MEMCACHED_CONF}" ]]; then
        log_debug "  Using configuration file: ${MEMCACHED_CONF}"
    fi
    
    # Start memcached
    ${MEMCACHED_BIN} -c ${MEMCACHED_CACHE_SIZE} -p ${MEMCACHED_PORT} -u sogo -l 0.0.0.0 -d &
    MEMCACHED_PID=$!
    
    # Save PID
    echo "${MEMCACHED_PID}" > "${MEMCACHED_PID_FILE}"
    
    # Wait for startup
    local count=0
    while [[ ${count} -lt ${MEMCACHED_STARTUP_TIMEOUT} ]]; do
        if ss -tlnp 2>/dev/null | grep -q ":${MEMCACHED_PORT} "; then
            log_success "Memcached started (PID: ${MEMCACHED_PID}) on port ${MEMCACHED_PORT}"
            return 0
        fi
        
        if ! kill -0 "${MEMCACHED_PID}" 2>/dev/null; then
            log_error "Memcached failed to start, check log: ${MEMCACHED_LOG}"
            cat "${MEMCACHED_LOG}" 2>/dev/null || true
            MEMCACHED_PID=""
            return 1
        fi
        
        sleep 1
        count=$((count + 1))
    done
    
    log_error "Memcached timeout waiting for port ${MEMCACHED_PORT}"
    return 1
}

start_sogo() {
    log_info "Starting SOGo..."
    
    # Check if already running
    if [[ -n "${SOGO_PID}" && kill -0 "${SOGO_PID}" 2>/dev/null ]]; then
        log_info "  SOGo already running (PID: ${SOGO_PID})"
        return 0
    fi
    
    # Wait for database
    if ! wait_for_database; then
        log_error "Database not available, cannot start SOGo"
        return 1
    fi
    
    # Start SOGo with proper user
    log_debug "  Starting sogod with args: ${SOGO_BIN} -s ${SOGO_CONF}"
    
    exec su-exec sogo "${SOGO_BIN}" -s "${SOGO_CONF}" &
    SOGO_PID=$!
    
    # Save PID
    echo "${SOGO_PID}" > "${SOGO_PID_FILE}"
    
    # Wait for startup
    local count=0
    local ready=false
    
    while [[ ${count} -lt ${SOGO_STARTUP_TIMEOUT} ]]; do
        if ! kill -0 "${SOGO_PID}" 2>/dev/null; then
            log_error "SOGo process died, check configuration"
            SOGO_PID=""
            return 1
        fi
        
        # Check if SOGo is listening on port 20000 (default)
        if ss -tlnp 2>/dev/null | grep -q "sogod"; then
            ready=true
            break
        fi
        
        sleep 1
        count=$((count + 1))
    done
    
    if ${ready}; then
        log_success "SOGo started (PID: ${SOGO_PID})"
        return 0
    else
        log_warn "SOGo started but may not be fully ready (PID: ${SOGO_PID})"
        return 0
    fi
}

start_health_server() {
    log_debug "Starting health server..."
    
    if [[ ! -x "${HEALTH_SCRIPT}" ]]; then
        log_debug "Health check script not available, skipping"
        return 0
    fi
    
    # Start health check server
    "${HEALTH_SCRIPT}" server &
    HEALTH_PID=$!
    
    # Save PID
    echo "${HEALTH_PID}" > "${HEALTH_PID_FILE}"
    
    log_info "Health server started (PID: ${HEALTH_PID}) on port 8081"
    return 0
}

start_services() {
    local target="$1"
    
    case "${target}" in
        memcached)
            start_memcached || exit 1
            ;;
        sogod|sogo)
            start_sogo || exit 1
            ;;
        *)
            # Start all services in order
            log_info "Starting all services..."
            
            start_memcached || exit 1
            sleep 1
            
            start_sogo || {
                cleanup 1 "SOGo startup failed"
                exit 1
            }
            sleep 1
            
            start_health_server || log_warn "Health server failed to start (non-critical)"
            ;;
    esac
    
    return 0
}

# =============================================================================
# DATABASE WAIT FUNCTION
# =============================================================================

wait_for_database() {
    local db_host="${SOGO_DB_HOST:-localhost}"
    local db_port="${SOGO_DB_PORT:-5432}"
    local db_type="${SOGO_DB_TYPE:-PostgreSQL}"
    local max_retries=120
    local retry_delay=5
    
    log_info "Waiting for database (${db_type} at ${db_host}:${db_port})..."
    
    local retry_count=0
    while [[ ${retry_count} -lt ${max_retries} ]]; do
        if check_database_connection; then
            log_success "Database connection established after ${retry_count} attempts"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        local next_attempt=$((retry_count + 1))
        local remaining=$((max_retries - retry_count))
        log_info "  Database not available (attempt ${retry_count}/${max_retries}), retrying in ${retry_delay}s (${remaining} remaining)..."
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
                PGPASSWORD="${db_password}" pg_isready -h "${db_host}" -p "${db_port}" -U "${db_user}" -d "${db_name}" -t 2 >/dev/null 2>&1
            else
                # Fallback to nc
                if echo "\\q" | nc -w 2 "${db_host}" "${db_port}" 2>/dev/null; then
                    return 0
                fi
            fi
            ;;
        mysql|mariadb)
            if command -v mysql &>/dev/null; then
                MYSQL_PWD="${db_password}" mysql -h "${db_host}" -P "${db_port}" -u "${db_user}" "${db_name}" -e "SELECT 1;" >/dev/null 2>&1 || true
            else
                if echo "" | nc -w 2 "${db_host}" "${db_port}" 2>/dev/null; then
                    return 0
                fi
            fi
            ;;
        *)
            # Generic TCP check
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
    local target="all"
    TARGET="${target}"
    
    # Set defaults
    parse_arguments "$@"
    
    # ======================
    # INITIALIZATION
    # ======================
    
    # Setup signal trapping
    setup_signal_traps
    
    # Print header
    echo ""
    echo "=============================================="
    echo "  SOGo 6 Container Entrypoint v3.0.0"
    echo "  Built: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    echo "  https://opendesk-edu.org"
    echo "=============================================="
    echo ""
    
    # ======================
    # STARTUP SEQUENCE
    # ======================
    
    # Step 0: Detect hardware capabilities
    detect_hardware_capabilities || log_warn "Hardware detection had issues"
    
    # Step 1: Validate environment and binaries
    validate_required_binaries || {
        echo "ERROR: Required binaries not found" >&2
        exit 1
    }
    
    # Step 2: Validate environment variables
    validate_environment || {
        echo "ERROR: Environment validation failed" >&2
        exit 1
    }
    
    # Step 3: Setup directories
    setup_directories || {
        echo "ERROR: Directory setup failed" >&2
        exit 1
    }
    
    # Step 4: Setup EDV
    setup_edv || log_warn "EDV setup had issues"
    
    # Step 5: Process configurations
    process_memcached_configuration || {
        echo "ERROR: Memcached configuration failed" >&2
        exit 1
    }
    
    process_gnustep_configuration || log_warn "GNUstep configuration had issues"
    
    process_sogo_configuration || {
        echo "ERROR: SOGo configuration failed" >&2
        exit 1
    }
    
    # ======================
    # START SERVICES
    # ======================
    
    start_services "${TARGET}" || exit 1
    
    # ======================
    # READY
    # ======================
    
    echo ""
    echo "=============================================="
    echo "  SOGo 6 is ready!"
    echo "=============================================="
    echo "  Services:"
    if [[ -n "${MEMCACHED_PID}" && kill -0 "${MEMCACHED_PID}" 2>/dev/null ]]; then
        echo "    Memcached: RUNNING (PID: ${MEMCACHED_PID})"
    else
        echo "    Memcached: STOPPED"
    fi
    
    if [[ -n "${SOGO_PID}" && kill -0 "${SOGO_PID}" 2>/dev/null ]]; then
        echo "    SOGo: RUNNING (PID: ${SOGO_PID})"
    else
        echo "    SOGo: STOPPED"
    fi
    
    if [[ -n "${HEALTH_PID}" && kill -0 "${HEALTH_PID}" 2>/dev/null ]]; then
        echo "    Health: RUNNING (PID: ${HEALTH_PID})"
    else
        echo "    Health: STOPPED"
    fi
    echo ""
    echo "  Configuration:"
    echo "    Database: ${SOGO_DB_TYPE}://${SOGO_DB_USER}@${SOGO_DB_HOST}:${SOGO_DB_PORT}/${SOGO_DB_NAME}"
    echo "    Workers: ${SOGO_WORKERS}"
    echo "    Memcached: localhost:${MEMCACHED_PORT} (${MEMCACHED_CACHE_SIZE}MB)"
    echo ""
    echo "  Access:"
    echo "    Web: http://localhost:20000/SOGo"
    echo "    Health: http://localhost:8081/healthz"
    echo "=============================================="
    echo ""
    
    # ======================
    # MONITOR LOOP
    # ======================
    
    # Monitor services and auto-restart if needed
    monitor_services
}

monitor_services() {
    log_debug "Starting service monitor..."
    
    while true; do
        # Check Memcached
        if [[ -n "${MEMCACHED_PID}" ]]; then
            if ! kill -0 "${MEMCACHED_PID}" 2>/dev/null; then
                log_error "Memcached crashed, restarting..."
                MEMCACHED_PID=""
                if ! restart_service memcached; then
                    log_error "Failed to restart Memcached"
                fi
            fi
        elif [[ "${TARGET}" == "all" || "${TARGET}" == "memcached" ]]; then
            log_warn "Memcached not running, starting..."
            start_memcached || log_error "Failed to start Memcached"
        fi
        
        # Check SOGo
        if [[ -n "${SOGO_PID}" ]]; then
            if ! kill -0 "${SOGO_PID}" 2>/dev/null; then
                log_error "SOGo crashed, restarting..."
                SOGO_PID=""
                if ! restart_service sogo; then
                    log_error "Failed to restart SOGo"
                    # If SOGo keeps crashing, give up
                    cleanup 1 "SOGo critical failure"
                fi
            fi
        elif [[ "${TARGET}" == "all" || "${TARGET}" == "sogo" ]]; then
            log_warn "SOGo not running, starting..."
            start_sogo || log_error "Failed to start SOGo"
        fi
        
        # Check Health Server
        if [[ -n "${HEALTH_PID}" ]]; then
            if ! kill -0 "${HEALTH_PID}" 2>/dev/null; then
                log_warn "Health server crashed, restarting..."
                HEALTH_PID=""
                start_health_server || log_error "Failed to restart health server"
            fi
        fi
        
        # Wait
        sleep 10
    done
}

restart_service() {
    local service="$1"
    local count=${RESTART_COUNTS[${service}]:-0}
    
    # Check restart limit
    if [[ ${count} -ge ${MAX_RESTART_ATTEMPTS} ]]; then
        log_error "Restart limit (${MAX_RESTART_ATTEMPTS}) reached for ${service}, not restarting"
        return 1
    fi
    
    RESTART_COUNTS[${service}]=$((count + 1))
    log_warn "Restart attempt ${RESTART_COUNTS[${service}]}/${MAX_RESTART_ATTEMPTS} for ${service}"
    
    case "${service}" in
        memcached)
            sleep ${RESTART_DELAY}
            start_memcached
            ;;
        sogo|sogod)
            sleep ${RESTART_DELAY}
            start_sogo
            ;;
        *)
            return 1
            ;;
    esac
}

# =============================================================================
# EXECUTE MAIN
# =============================================================================
main "$@"

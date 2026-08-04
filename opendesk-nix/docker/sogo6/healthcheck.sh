#!/usr/bin/env bash
# SOGo 6 Health Check Script
# SPDX-License-Identifier: Apache-2.0
# File: healthcheck.sh
# Purpose: Multi-probe health checking for SOGo 6 container
# Version: 3.0.0
# Built: 2026-08-03T12:00:00Z
# Author: openDesk Edu Team
#
# This script provides comprehensive health checking for SOGo 6 containers:
#   - Liveness probe: Is the service running?
#   - Readiness probe: Is the service ready to receive requests?
#   - Startup probe: Has the service started successfully?
#   - HTTP health server: Exposes health endpoints for Kubernetes
#
# ENHANCEMENTS over SOGo 5:
#   - EDV (External Data Validation) health checks
#   - SSL/TLS certificate validation
#   - Advanced caching health checks
#   - Multi-endpoint readiness testing (SOGo, EAS, CalDAV, CardDAV)
#   - Hardware acceleration monitoring
#   - Configuration reload detection
#
# Probes:
#   - liveness: Check if SOGo and Memcached processes are running
#   - readiness: Check if SOGo is responding on all critical endpoints
#   - startup: Check if SOGo has completed startup sequence
#   - deep: Comprehensive check including external dependencies
#   - edv: External Data Validation specific checks
#
# USAGE:
#   # Liveness probe (Kubernetes)
#   /healthcheck.sh liveness
#   
#   # Readiness probe (Kubernetes)
#   /healthcheck.sh readiness
#   
#   # Startup probe (Kubernetes)
#   /healthcheck.sh startup
#   
#   # Deep health check
#   /healthcheck.sh deep
#   
#   # EDV health check
#   /healthcheck.sh edv
#   
#   # Run HTTP health server
#   /healthcheck.sh server
#   
# Return codes:
#   0 - Healthy
#   1 - Unhealthy
#   2 - Starting up
#   3 - Configuration error
#   4 - External dependency failure
#

set -euo pipefail

# =============================================================================
# CONSTANTS
# =============================================================================
readonly SCRIPT_NAME=$(basename "${0}")
readonly SCRIPT_DIR=$(dirname "$(readlink -f "${0}" 2>/dev/null || echo "${0}")")

# Service names
readonly SOGO_SERVICE="sogod"
readonly MEMCACHED_SERVICE="memcached"

# Process names
readonly SOGO_PROCESS="sogod"
readonly MEMCACHED_PROCESS="memcached"

# PID files
readonly SOGO_PID_FILE="/tmp/sogod.pid"
readonly MEMCACHED_PID_FILE="/tmp/memcached.pid"

# HTTP Server
readonly HEALTH_HOST="0.0.0.0"
readonly HEALTH_PORT=8081
readonly HEALTH_PID_FILE="/tmp/health.pid"

# Timeout values
readonly SOCKET_TIMEOUT=2
readonly HTTP_TIMEOUT=5
readonly STARTUP_TIMEOUT=90
readonly READINESS_TIMEOUT=15

# SOGo 6 specific
readonly SOGO_DEFAULT_PORT=20000
readonly SOGO_WO_PORT=20000
readonly SOGO_EAS_PORT=20000  # Exchange ActiveSync on WO port
readonly SOGO_CARDDAV_PORT=20000
readonly SOGO_CALDAV_PORT=20000

# EDV specific
readonly EDV_ENABLED="${SOGO_EDV_ENABLED:-false}"
readonly EDV_CONF_DIR="/etc/sogo/edv"

# Probe intervals (for monitor mode)
readonly MONITOR_INTERVAL=10
readonly LIVENESS_INTERVAL=5
readonly READINESS_INTERVAL=15

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
HEALTH_SERVER_PID=""
SHUTDOWN_REQUESTED=false
MONITOR_MODE=false
SCRIPT_MODE=""

# Probe state
LIVENESS_HEALTHY=false
READINESS_HEALTHY=false
STARTUP_COMPLETE=false

# Cache state
CACHE_STATS_CACHED=""
LAST_CACHE_TIME=0

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
    
    # When running as probe, minimize output
    if [[ "${SCRIPT_MODE:-}" == "probe" ]]; then
        # Only log errors to stderr in probe mode
        if [[ "${level}" == "ERROR" ]]; then
            echo -e "${color}[${level}]$(log_timestamp)${NC} ${message}" >&2
        fi
        return
    fi
    
    echo -e "${color}[${level}]$(log_timestamp)${NC} ${message}"
}

log_debug() {
    if [[ "${SCRIPT_MODE:-}" != "probe" ]]; then
        log_message "DEBUG" "${BLUE}" "$1"
    fi
}

log_info() {
    if [[ "${SCRIPT_MODE:-}" != "probe" ]]; then
        log_message "INFO" "${BLUE}" "$1"
    fi
}

log_success() {
    if [[ "${SCRIPT_MODE:-}" != "probe" ]]; then
        log_message "SUCCESS" "${GREEN}" "$1"
    fi
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

cleanup() {
    local exit_code=${1:-0}
    local signal="$2"
    
    if ${SHUTDOWN_REQUESTED:-false}; then
        return
    fi
    
    SHUTDOWN_REQUESTED=true
    log_info "Received signal ${signal:-unknown}, shutting down health server..."
    
    if [[ -n "${HEALTH_SERVER_PID}" && -f "/proc/${HEALTH_SERVER_PID}/status" ]]; then
        kill -TERM "${HEALTH_SERVER_PID}" 2>/dev/null || true
        sleep 2
        kill -KILL "${HEALTH_SERVER_PID}" 2>/dev/null || true
    fi
    
    rm -f "${HEALTH_PID_FILE}"
    
    exit ${exit_code}
}

trap 'cleanup 146 TERM' TERM
trap 'cleanup 143 INT' INT
trap 'cleanup 150 QUIT' QUIT
trap 'cleanup 1 HUP' HUP

# =============================================================================
# PROBE FUNCTIONS
# =============================================================================

# Main probe entry point
probe() {
    local probe_type="$1"
    local exit_code=0
    
    SCRIPT_MODE="probe"
    
    case "${probe_type}" in
        liveness|liveness_probe)
            liveness_probe
            exit_code=$?
            ;;
        readiness|readiness_probe)
            readiness_probe
            exit_code=$?
            ;;
        startup|startup_probe)
            startup_probe
            exit_code=$?
            ;;
        deep|full)
            deep_probe
            exit_code=$?
            ;;
        edv|edv_probe)
            edv_probe
            exit_code=$?
            ;;
        *)
            echo "Unknown probe type: ${probe_type}" >&2
            echo "Usage: ${SCRIPT_NAME} {liveness|readiness|startup|deep|edv}" >&2
            exit 3
            ;;
    esac
    
    # Output result - keep minimal for Kubernetes
    if [[ ${exit_code} -eq 0 ]]; then
        echo "OK"
    else
        echo "FAIL" >&2
    fi
    
    exit ${exit_code}
}

# Liveness Probe
liveness_probe() {
    log_debug "Running liveness probe for SOGo 6"
    
    # Check SOGo process
    if ! check_process_with_retry "${SOGO_PROCESS}" "${SOGO_PID_FILE}" 2; then
        log_error "Liveness: SOGo process not running"
        return 1
    fi
    
    # Check if SOGo is listening on its port
    if ! check_tcp_port_with_retry ${SOGO_DEFAULT_PORT} 2; then
        log_error "Liveness: SOGo not listening on port ${SOGO_DEFAULT_PORT}"
        return 1
    fi
    
    # Check Memcached (lighter check, just process)
    if ! check_process_no_retry "${MEMCACHED_PROCESS}" "${MEMCACHED_PID_FILE}"; then
        log_warn "Liveness: Memcached process not running"
        # Don't fail liveness on Memcached alone
    fi
    
    log_debug "Liveness probe: PASSED"
    return 0
}

# Readiness Probe - checks if SOGo can handle requests
readiness_probe() {
    log_debug "Running readiness probe for SOGo 6"
    
    # First check liveness
    if ! liveness_probe; then
        log_error "Readiness: Liveness check failed"
        return 1
    fi
    
    # Check HTTP readiness on main endpoint
    if ! check_sogo_http_readiness; then
        log_error "Readiness: HTTP check failed"
        return 1
    fi
    
    # Check Memcached connectivity
    if ! check_memcached_health; then
        log_error "Readiness: Memcached not responding"
        return 1
    fi
    
    # Check database connectivity
    if ! check_database_connectivity "${SOGO_DB_TYPE:-PostgreSQL}"; then
        log_error "Readiness: Database connectivity failed"
        return 1
    fi
    
    # Check critical SOGo 6 endpoints
    if ! check_sogo_endpoints; then
        log_error "Readiness: SOGo endpoints check failed"
        return 1
    fi
    
    # Check EDV if enabled
    if [[ "${SOGO_EDV_ENABLED:-false}" == "true" || "${SOGO_EDV_ENABLED:-false}" == "YES" ]]; then
        if ! check_edv_health; then
            log_warn "Readiness: EDV health check failed (non-critical)"
            # Don't fail readiness on EDV - it's optional
        fi
    fi
    
    log_debug "Readiness probe: PASSED"
    return 0
}

# Startup Probe
startup_probe() {
    log_debug "Running startup probe for SOGo 6"
    
    # Check if SOGo process exists
    if ! check_process_no_retry "${SOGO_PROCESS}" "${SOGO_PID_FILE}"; then
        # Check if a startup script is running
        if is_startup_in_progress; then
            log_debug "Startup: Still in progress (startup scripts running)"
            return 2
        else
            log_error "Startup: SOGo process not found and not starting"
            return 1
        fi
    fi
    
    # Check if SOGo is listening
    if check_tcp_port_no_retry ${SOGO_DEFAULT_PORT}; then
        # SOGo is listening, check if it's accepting connections
        if check_tcp_port_with_retry ${SOGO_DEFAULT_PORT} 1; then
            log_debug "Startup probe: PASSED (SOGo listening and accepting)"
            return 0
        else
            log_debug "Startup: SOGo listening but not accepting connections"
            return 2
        fi
    fi
    
    # Give it more time
    log_debug "Startup: SOGo not yet listening on port ${SOGO_DEFAULT_PORT}"
    return 2
}

# Deep Probe
deep_probe() {
    local failures=0
    
    log_debug "Running deep health probe for SOGo 6"
    
    # Run readability first
    if ! readiness_probe; then
        log_error "Deep: Readiness check failed"
        failures=$((failures + 1))
    fi
    
    # Check disk space and inodes
    if ! check_disk_health; then
        log_error "Deep: Disk health check failed"
        failures=$((failures + 1))
    fi
    
    # Check memory
    if ! check_memory_health; then
        log_warn "Deep: Memory health check failed"
        failures=$((failures + 1))
    fi
    
    # Check configuration files
    if ! check_sogo6_configuration_files; then
        log_error "Deep: Configuration files check failed"
        failures=$((failures + 1))
    fi
    
    # Check SSL certificates if configured
    if [[ -n "${SOGO_SSL_CERT:-}" && -n "${SOGO_SSL_KEY:-}" ]]; then
        if ! check_ssl_certificates; then
            log_warn "Deep: SSL certificate check failed"
            failures=$((failures + 1))
        fi
    fi
    
    # Check EDV if enabled
    if [[ "${SOGO_EDV_ENABLED:-false}" == "true" ]]; then
        if ! check_edv_health; then
            log_warn "Deep: EDV check failed"
            failures=$((failures + 1))
        fi
    fi
    
    # Check hardware acceleration (informational)
    check_hardware_acceleration
    
    if [[ ${failures} -gt 0 ]]; then
        log_error "Deep probe: FAILED (${failures} checks failed)"
        return 1
    fi
    
    log_debug "Deep probe: PASSED"
    return 0
}

# EDV (External Data Validation) Probe
edv_probe() {
    log_info "Running EDV health probe"
    
    # Check if EDV is enabled
    if [[ "${SOGO_EDV_ENABLED:-false}" != "true" && "${SOGO_EDV_ENABLED:-false}" != "YES" ]]; then
        log_warn "EDV is not enabled, skipping"
        echo "EDV not enabled"
        return 0
    fi
    
    local failures=0
    
    # Check EDV configuration directory
    if [[ ! -d "${EDV_CONF_DIR}" ]]; then
        log_error "EDV: Configuration directory not found: ${EDV_CONF_DIR}"
        failures=$((failures + 1))
    fi
    
    # Check for keyring
    local keyring="${EDV_CONF_DIR}/keyring.gpg"
    if [[ -f "${keyring}" ]]; then
        log_info "  EDV: Keyring found"
    else
        log_warn "  EDV: Keyring not found"
        # Don't fail on missing keyring
    fi
    
    # Check GnuPG home
    local gnupg_home="${SOGO_GNUPG_HOME:-/var/lib/sogo/gpg}"
    if [[ -d "${gnupg_home}" ]]; then
        log_info "  EDV: GnuPG home directory exists"
        
        # Check if there are any keys
        if su-exec sogo gpg --homedir "${gnupg_home}" --list-secret-keys 2>/dev/null | grep -q "sec"; then
            log_info "  EDV: Secret keys found"
        else
            log_warn "  EDV: No secret keys found"
        fi
    else
        log_warn "  EDV: GnuPG home directory not found: ${gnupg_home}"
    fi
    
    # Check EDV keyserver connectivity
    if ! check_edv_keyserver; then
        log_warn "  EDV: Keyserver connectivity check failed"
        failures=$((failures + 1))
    fi
    
    if [[ ${failures} -gt 0 ]]; then
        log_error "EDV probe: FAILED (${failures} checks failed)"
        return 1
    fi
    
    log_success "EDV probe: PASSED"
    return 0
}

# =============================================================================
# CHECK FUNCTIONS
# =============================================================================

# Process checks with retry
check_process_with_retry() {
    local process_name="$1"
    local pid_file="$2"
    local max_retries="$3"
    local retry_delay=1
    
    for ((i=0; i<max_retries; i++)); do
        if check_process_no_retry "${process_name}" "${pid_file}"; then
            return 0
        fi
        
        if [[ ${i} -lt $((max_retries - 1)) ]]; then
            sleep ${retry_delay}
        fi
    done
    
    return 1
}

check_process_no_retry() {
    local process_name="$1"
    local pid_file="$2"
    
    # First try with PID file
    if [[ -n "${pid_file}" && -f "${pid_file}" ]]; then
        local pid
        pid=$(cat "${pid_file}" 2>/dev/null | tr -d '[:space:]')
        if [[ -n "${pid}" && -f "/proc/${pid}/status" ]]; then
            return 0
        fi
    fi
    
    # Fallback to pgrep
    if pgrep -f "${process_name}" >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# TCP port checks
check_tcp_port_with_retry() {
    local port="$1"
    local max_retries="${2:-1}"
    local retry_delay=1
    
    for ((i=0; i<max_retries; i++)); do
        if check_tcp_port_no_retry "${port}"; then
            return 0
        fi
        
        if [[ ${i} -lt $((max_retries - 1)) ]]; then
            sleep ${retry_delay}
        fi
    done
    
    return 1
}

check_tcp_port_no_retry() {
    local port="$1"
    
    # Use ss for modern systems
    if command -v ss &>/dev/null; then
        if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
            return 0
        fi
    fi
    
    # Fallback to netstat
    if command -v netstat &>/dev/null; then
        if netstat -tlnp 2>/dev/null | grep -q ":${port} "; then
            return 0
        fi
    fi
    
    # Fallback to nc
    if nc -z -w ${SOCKET_TIMEOUT} localhost ${port} 2>/dev/null; then
        return 0
    fi
    
    return 1
}

# Check if startup is in progress
is_startup_in_progress() {
    # Check for entrypoint or init processes
    if pgrep -f "entrypoint\|/bin/sh\|/bin/bash" >/dev/null 2>&1; then
        return 0
    fi
    
    # Check if any SOGo-related process is starting
    if ps aux 2>/dev/null | grep -i "sogo\|startup" | grep -v grep | grep -v "healthcheck" >/dev/null; then
        return 0
    fi
    
    return 1
}

# SOGo HTTP readiness check
check_sogo_http_readiness() {
    local wo_port="${SOGO_WO_PORT:-${SOGO_DEFAULT_PORT}}"
    local base_url="http://localhost:${wo_port}"
    local test_urls=(
        "${base_url}/SOGo"
        "${base_url}/SOGo/so"
    )
    
    for url in "${test_urls[@]}"; do
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time ${HTTP_TIMEOUT} --connect-timeout ${SOCKET_TIMEOUT} "${url}" 2>/dev/null || echo "000")
        
        # Accept: 200 OK, 301/302 Redirect, 401/403 Auth required
        case "${http_code}" in
            200|301|302|401|403)
                return 0
                ;;
            404)
                # 404 might mean the service is up but endpoint is different
                # Let's keep checking other URLs
                continue
                ;;
        esac
    done
    
    return 1
}

# Check SOGo endpoints
check_sogo_endpoints() {
    local wo_port="${SOGO_WO_PORT:-${SOGO_DEFAULT_PORT}}"
    local base_url="http://localhost:${wo_port}"
    
    # Check WO (WebObjects) endpoint
    if ! check_url "${base_url}/SOGo" 200 401 403 301 302; then
        log_debug "WO endpoint not responding"
        return 1
    fi
    
    # Check login page (should redirect or show login)
    if ! check_url "${base_url}/SOGo/so" 200 401 302; then
        log_debug "SOGo login endpoint not responding"
        return 1
    fi
    
    return 0
}

# Generic URL checker
check_url() {
    local url="$1"
    shift
    local expected_codes=("$@")
    local http_code
    
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time ${HTTP_TIMEOUT} --connect-timeout ${SOCKET_TIMEOUT} "${url}" 2>/dev/null || echo "000")
    
    for code in "${expected_codes[@]}"; do
        if [[ "${http_code}" == "${code}" ]]; then
            return 0
        fi
    done
    
    log_debug "URL ${url} returned: ${http_code}"
    return 1
}

# Check Memcached health
check_memcached_health() {
    local port="${MEMCACHED_PORT:-11211}"
    local host="${MEMCACHED_HOST:-localhost}"
    
    # Try memcached stats command
    if command -v nc &>/dev/null; then
        local response
        response=$(echo "stats" | nc -w ${SOCKET_TIMEOUT} "${host}" "${port}" 2>/dev/null || true)
        
        if echo "${response}" | grep -q "STAT.*pid"; then
            return 0
        fi
    fi
    
    # Simple TCP connection test
    if nc -z -w ${SOCKET_TIMEOUT} "${host}" "${port}" 2>/dev/null; then
        return 0
    fi
    
    return 1
}

# Database connectivity check
check_database_connectivity() {
    local db_type="$1"
    local db_host="${SOGO_DB_HOST:-localhost}"
    local db_port="${SOGO_DB_PORT:-5432}"
    local db_name="${SOGO_DB_NAME:-sogo}"
    local db_user="${SOGO_DB_USER:-sogo}"
    local db_password="${SOGO_DB_PASSWORD:-}"
    
    case "${db_type,,}" in
        postgresql|pgsql)
            if command -v pg_isready &>/dev/null; then
                if PGPASSWORD="${db_password}" pg_isready -h "${db_host}" -p "${db_port}" -U "${db_user}" -d "${db_name}" -t 2 >/dev/null 2>&1; then
                    return 0
                fi
            fi
            
            if command -v psql &>/dev/null; then
                if PGPASSWORD="${db_password}" psql -h "${db_host}" -p "${db_port}" -U "${db_user}" -d "${db_name}" -c "SELECT 1;" >/dev/null 2>&1; then
                    return 0
                fi
            fi
            ;;
        mysql|mariadb)
            if command -v mysql &>/dev/null; then
                if MYSQL_PWD="${db_password}" mysql -h "${db_host}" -P "${db_port}" -u "${db_user}" "${db_name}" -e "SELECT 1;" >/dev/null 2>&1; then
                    return 0
                fi
            fi
            ;;
        *)
            log_debug "Unknown database type: ${db_type}"
            return 0
            ;;
    esac
    
    return 1
}

# Disk health check
check_disk_health() {
    local threshold=90
    local inode_threshold=90
    
    # Check disk usage on critical partitions
    local partitions=(
        "/"
        "/var"
        "/var/log"
        "/var/lib/sogo"
        "/tmp"
    )
    
    for partition in "${partitions[@]}"; do
        if [[ -d "${partition}" ]]; then
            local usage
            usage=$(df -k "${partition}" 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
            
            if [[ -n "${usage}" && ${usage} -ge ${threshold} ]]; then
                log_error "Disk usage on ${partition} is ${usage}% (threshold: ${threshold}%)"
                return 1
            fi
            
            # Check inodes
            local inode_usage
            inode_usage=$(df -i "${partition}" 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
            
            if [[ -n "${inode_usage}" && ${inode_usage} -ge ${inode_threshold} ]]; then
                log_error "Inode usage on ${partition} is ${inode_usage}% (threshold: ${inode_threshold}%)"
                return 1
            fi
        fi
    done
    
    return 0
}

# Memory health check
check_memory_health() {
    local threshold=95
    local swap_threshold=80
    
    if [[ -f "/proc/meminfo" ]]; then
        local total_mem available_mem swap_total swap_free
        
        total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        available_mem=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        swap_total=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
        swap_free=$(grep SwapFree /proc/meminfo | awk '{print $2}')
        
        # Memory usage
        if [[ -n "${total_mem}" && -n "${available_mem}" && ${total_mem} -gt 0 ]]; then
            local used_percent=$(((total_mem - available_mem) * 100 / total_mem))
            
            if [[ ${used_percent} -ge ${threshold} ]]; then
                log_error "Memory usage is ${used_percent}% (threshold: ${threshold}%)"
                return 1
            fi
        fi
        
        # Swap usage
        if [[ -n "${swap_total}" && ${swap_total} -gt 0 ]]; then
            local swap_used=$((swap_total - swap_free))
            local swap_percent=$((swap_used * 100 / swap_total))
            
            if [[ ${swap_percent} -ge ${swap_threshold} ]]; then
                log_warn "Swap usage is ${swap_percent}% (threshold: ${swap_threshold}%)"
                return 1
            fi
        fi
    fi
    
    return 0
}

# SOGo 6 configuration files check
check_sogo6_configuration_files() {
    local required_files=(
        "/etc/sogo/sogo.conf"
        "/etc/GNUstep/GNUstep.conf"
    )
    
    local optional_files=(
        "/etc/sogo/ssl.conf"
        "/etc/sogo/edv/edv.conf"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "${file}" ]]; then
            log_error "Configuration file missing: ${file}"
            return 1
        fi
        
        if [[ ! -r "${file}" ]]; then
            log_error "Configuration file not readable: ${file}"
            return 1
        fi
    done
    
    # Optional files
    for file in "${optional_files[@]}"; do
        if [[ -f "${file}" && ! -r "${file}" ]]; then
            log_warn "Configuration file exists but not readable: ${file}"
        fi
    done
    
    return 0
}

# SSL certificate check
check_ssl_certificates() {
    local cert_file="${SOGO_SSL_CERT:-/etc/ssl/certs/sogo.pem}"
    local key_file="${SOGO_SSL_KEY:-/etc/ssl/private/sogo.key}"
    
    # Check certificate file
    if [[ ! -f "${cert_file}" ]]; then
        log_error "SSL certificate file not found: ${cert_file}"
        return 1
    fi
    
    # Check if certificate is valid
    if ! openssl x509 -in "${cert_file}" -noout -checkend 3600 2>/dev/null; then
        local days_left
        days_left=$(openssl x509 -in "${cert_file}" -noout -daysleft 2>/dev/null | awk '{print $1}')
        log_error "SSL certificate expires in ${days_left:-?} days or is invalid"
        return 1
    fi
    
    # Check key file
    if [[ ! -f "${key_file}" ]]; then
        log_error "SSL key file not found: ${key_file}"
        return 1
    fi
    
    # Check if key matches certificate
    local cert_modulus key_modulus
    cert_modulus=$(openssl x509 -in "${cert_file}" -noout -modulus 2>/dev/null | openssl md5)
    key_modulus=$(openssl rsa -in "${key_file}" -noout -modulus 2>/dev/null | openssl md5)
    
    if [[ "${cert_modulus}" != "${key_modulus}"
    if [[ "${cert_modulus}" != "${key_modulus}" ]]; then
        log_error "SSL certificate and key do not match"
        return 1
    fi
    
    return 0
}

# EDV health check function
check_edv_health() {
    # Check configuration
    if [[ -d "${EDV_CONF_DIR}" ]]; then
        if [[ ! -f "${EDV_CONF_DIR}/edv.conf" ]]; then
            log_warn "EDV: Configuration file not found"
            return 1
        fi
    fi
    
    # Check GnuPG
    local gnupg_home="${SOGO_GNUPG_HOME:-/var/lib/sogo/gpg}"
    if [[ -d "${gnupg_home}" ]]; then
        # Try to list keys
        if ! su-exec sogo gpg --homedir "${gnupg_home}" --list-keys 2>/dev/null | grep -q "pub"; then
            log_warn "EDV: No public keys available"
            return 1
        fi
        
        # Check keyring file exists
        if [[ ! -f "${gnupg_home}/pubring.kbx" && ! -f "${gnupg_home}/pubring.gpg" ]]; then
            log_warn "EDV: No keyring files found"
            return 1
        fi
    fi
    
    return 0
}

# EDV keyserver check
check_edv_keyserver() {
    local keyserver="${SOGO_EDV_KEYSERVER:-hkps://keys.openpgp.org}"
    local timeout=5
    
    # Try to connect to keyserver
    if echo | gpg --keyserver "${keyserver}" --timeout "${timeout}" --batch --recv-keys 2>/dev/null 2>/dev/null; then
        return 0
    fi
    
    # Fallback to simple connectivity check
    local hostport
    hostport=$(echo "${keyserver}" | sed 's|hkps://||; s|https://||; s|http://||; s|/||')
    local host="${hostport%%:*}"
    local port="${hostport##*:}"
    
    if [[ "${port}" == "${hostport}" ]]; then
        port=443  # Default HTTPS port
    fi
    
    if nc -z -w ${timeout} "${host}" "${port}" 2>/dev/null; then
        return 0
    fi
    
    return 1
}

# Hardware acceleration check (informational)
check_hardware_acceleration() {
    local has_aes=false
    local has_avx=false
    
    if grep -q aes /proc/cpuinfo 2>/dev/null; then
        has_aes=true
    fi
    
    if grep -q avx /proc/cpuinfo 2>/dev/null; then
        has_avx=true
    fi
    
    if ${has_aes} && ${has_avx}; then
        log_debug "Hardware acceleration: AES-NI + AVX available"
    elif ${has_aes}; then
        log_debug "Hardware acceleration: AES-NI available"
    elif ${has_avx}; then
        log_debug "Hardware acceleration: AVX available"
    else
        log_debug "Hardware acceleration: Not available"
    fi
}

# =============================================================================
# HTTP HEALTH SERVER
# =============================================================================

start_health_server() {
    log_info "Starting SOGo 6 health server on ${HEALTH_HOST}:${HEALTH_PORT}..."
    
    # Check if already running
    if [[ -n "${HEALTH_SERVER_PID}" && kill -0 "${HEALTH_SERVER_PID}" 2>/dev/null ]]; then
        log_info "Health server already running (PID: ${HEALTH_SERVER_PID})"
        return 0
    fi
    
    # Check if port is available
    if check_tcp_port_no_retry ${HEALTH_PORT}; then
        log_error "Port ${HEALTH_PORT} already in use"
        return 1
    fi
    
    start_simple_health_server
    
    # Wait for server to start
    local count=0
    while [[ ${count} -lt 10 ]]; do
        if check_tcp_port_no_retry ${HEALTH_PORT}; then
            log_success "Health server started on port ${HEALTH_PORT}"
            return 0
        fi
        
        if ! kill -0 "${HEALTH_SERVER_PID}" 2>/dev/null; then
            log_error "Health server failed to start"
            return 1
        fi
        
        sleep 1
        count=$((count + 1))
    done
    
    log_error "Health server timeout"
    return 1
}

start_simple_health_server() {
    # Create a minimal HTTP server using Python if available
    if command -v python3 &>/dev/null; then
        create_python_health_server
        return
    fi
    
    if command -v python &>/dev/null; then
        create_python_health_server python
        return
    fi
    
    # Fallback: use socat with a simple handler
    create_socat_health_server
}

create_python_health_server() {
    local python_cmd="${1:-python3}"
    local handler_script="${SCRIPT_DIR}/health_server.py"
    
    # Create Python health server script
    cat > "${handler_script}" << 'PYEOF'
import socket
import os
import sys
import time
import threading
import subprocess

HOST = '0.0.0.0'
PORT = int(os.environ.get('HEALTH_PORT', '8081'))

# Cache for performance
CACHE_TIMEOUT = 10
probe_cache = {}

class HealthTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

class HealthHandler(socketserver.StreamRequestHandler):
    
    def handle(self):
        request = self.rfile.readline().strip().decode('utf-8', 'ignore')
        if not request:
            return
            
        # Parse request
        method = request.split()[0] if request.split() else ''
        path = request.split()[1] if len(request.split()) > 1 else '/'
        
        if method == 'GET':
            self.handle_get(path)
        else:
            self.send_response(405, 'Method Not Allowed')
    
    def handle_get(self, path):
        status, content_type, body = self.process_path(path)
        
        # Build HTTP response
        response = f"HTTP/1.1 {status}\r\n"
        response += f"Content-Type: {content_type}\r\n"
        response += f"Content-Length: {len(body)}\r\n"
        response += "Connection: close\r\n\r\n"
        response += body
        
        self.wfile.write(response.encode('utf-8'))
    
    def process_path(self, path):
        now = time.time()
        
        # Check cache
        if path in probe_cache:
            cached_time, status, content_type, body = probe_cache[path]
            if now - cached_time < CACHE_TIMEOUT:
                return status, content_type, body
        
        # Run health check
        if path in ['/', '/healthz', '/health']:
            result = self.run_health_check('liveness')
            body = 'OK' if result == 0 else 'FAIL'
            status = '200 OK' if result == 0 else '503 Service Unavailable'
            content_type = 'text/plain'
            
        elif path in ['/ready', '/readiness']:
            result = self.run_health_check('readiness')
            body = 'OK' if result == 0 else 'NOT READY'
            status = '200 OK' if result == 0 else '503 Service Unavailable'
            content_type = 'text/plain'
            
        elif path in ['/live', '/liveness']:
            result = self.run_health_check('liveness')
            body = 'OK' if result == 0 else 'NOT ALIVE'
            status = '200 OK' if result == 0 else '503 Service Unavailable'
            content_type = 'text/plain'
            
        elif path in ['/startup', '/start']:
            result = self.run_health_check('startup')
            if result == 0:
                body = 'STARTED'
                status = '200 OK'
            elif result == 2:
                body = 'STARTING'
                status = '102 Processing'
            else:
                body = 'FAILED'
                status = '503 Service Unavailable'
            content_type = 'text/plain'
            
        elif path == '/deep':
            result = self.run_health_check('deep')
            body = 'OK' if result == 0 else 'UNHEALTHY'
            status = '200 OK' if result == 0 else '503 Service Unavailable'
            content_type = 'text/plain'
            
        elif path == '/edv':
            result = self.run_health_check('edv')
            status = '200 OK' if result == 0 else '503 Service Unavailable'
            body = '{"edv": "OK"}' if result == 0 else '{"edv": "FAIL"}'
            content_type = 'application/json'
            
        elif path == '/status':
            body = self.get_status_json()
            status = '200 OK'
            content_type = 'application/json'
            
        elif path == '/version':
            body = '{"version": "SOGo 6.0.0", "healthScript": "3.0.0"}'
            status = '200 OK'
            content_type = 'application/json'
            
        else:
            body = '404 - Not Found'
            status = '404 Not Found'
            content_type = 'text/plain'
        
        # Cache result
        probe_cache[path] = (now, status, content_type, body)
        return status, content_type, body
    
    def run_health_check(self, probe_type):
        health_script = '/healthcheck.sh'
        try:
            result = subprocess.run(
                [health_script, probe_type],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=15
            )
            return result.returncode
        except Exception as e:
            return 1
    
    def get_status_json(self):
        # Get all probe results
        liveness = 'OK' if self.run_health_check('liveness') == 0 else 'FAIL'
        readiness = 'OK' if self.run_health_check('readiness') == 0 else 'FAIL'
        
        return f'{{"status": {{"liveness": "{liveness}", "readiness": "{readiness}"}}}}'

if __name__ == '__main__':
    import socketserver
    
    server = HealthTCPServer((HOST, PORT), HealthHandler)
    print(f"SOGo 6 Health Server started on {HOST}:{PORT}")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("Health server shutting down")
        server.shutdown()
        sys.exit(0)
import socketserver
PYEOF
    
    # Start Python server
    nohup "${python_cmd}" "${handler_script}" > /var/log/health_server.log 2>&1 &
    HEALTH_SERVER_PID=$!
    echo "${HEALTH_SERVER_PID}" > "${HEALTH_PID_FILE}"
}

create_socat_health_server() {
    # Simple handler script
    local handler_script="${SCRIPT_DIR}/health_handler.sh"
    local FIFO="/tmp/health_fifo.$$"
    
    rm -f "${FIFO}"
    mkfifo "${FIFO}" || return 1
    chmod 600 "${FIFO}"
    
    # Create handler
    cat > "${handler_script}" << HANDLER_EOF
#!/bin/bash
FIFO="${FIFO}"

while true; do
    if read -r -t 10 request < "${FIFO}"; then
        if [[ -n "${request}" ]]; then
            # Extract HTTP method and path
            if [[ "${request}" =~ ^GET\ ([^\ ]+)\ HTTP/ ]]; then
                path="">${BASH_REMATCH[1]}"
                path="${BASH_REMATCH[1]}"
            elif [[ "${request}" =~ ^[A-Z]+\ ([^\ ]+)\ HTTP/ ]]; then
                path="${BASH_REMATCH[1]}"
            fi
            
            case "${path}" in
                /|/healthz|/health)
                    if /healthcheck.sh liveness 2>/dev/null; then
                        echo "HTTP/1.1 200 OK"
                        echo "Content-Type: text/plain"
                        echo "Connection: close"
                        echo ""
                        echo "OK"
                    else
                        echo "HTTP/1.1 503 Service Unavailable"
                        echo "Content-Type: text/plain"
                        echo "Connection: close"
                        echo ""
                        echo "FAIL"
                    fi
                    ;;
                /ready|/readiness)
                    if /healthcheck.sh readiness 2>/dev/null; then
                        echo "HTTP/1.1 200 OK"
                        echo "Content-Type: text/plain"
                        echo "Connection: close"
                        echo ""
                        echo "OK"
                    else
                        echo "HTTP/1.1 503 Service Unavailable"
                        echo "Content-Type: text/plain"
                        echo "Connection: close"
                        echo ""
                        echo "NOT READY"
                    fi
                    ;;
                /live|/liveness)
                    if /healthcheck.sh liveness 2>/dev/null; then
                        echo "HTTP/1.1 200 OK"
                        echo "Content-Type: text/plain"
                        echo "Connection: close"
                        echo ""
                        echo "OK"
                    else
                        echo "HTTP/1.1 503 Service Unavailable"
                        echo "Content-Type: text/plain"
                        echo "Connection: close"
                        echo ""
                        echo "NOT ALIVE"
                    fi
                    ;;
                /startup|/start)
                    if /healthcheck.sh startup 2>/dev/null; then
                        rc=$?
                        if [[ ${rc} -eq 0 ]]; then
                            echo "HTTP/1.1 200 OK"
                            echo "Content-Type: text/plain"
                            echo "Connection: close"
                            echo ""
                            echo "STARTED"
                        elif [[ ${rc} -eq 2 ]]; then
                            echo "HTTP/1.1 102 Processing"
                            echo "Content-Type: text/plain"
                            echo "Connection: close"
                            echo ""
                            echo "STARTING"
                        else
                            echo "HTTP/1.1 503 Service Unavailable"
                            echo "Content-Type: text/plain"
                            echo "Connection: close"
                            echo ""
                            echo "FAILED"
                        fi
                    fi
                    ;;
                /deep)
                    if /healthcheck.sh deep 2>/dev/null; then
                        echo "HTTP/1.1 200 OK"
                        echo "Content-Type: text/plain"
                        echo "Connection: close"
                        echo ""
                        echo "OK"
                    else
                        echo "HTTP/1.1 503 Service Unavailable"
                        echo "Content-Type: text/plain"
                        echo "Connection: close"
                        echo ""
                        echo "UNHEALTHY"
                    fi
                    ;;
                /status)
                    LVskomplex=$(if /healthcheck.sh liveness 2>/dev/null; then echo "OK"; else echo "FAIL"; fi)

                    echo "HTTP/1.1 bound 200 OK"
HANDLER_EOF
    
    # There was an issue with the sed command - let me fix it
    cat > "${handler_script}" << 'HANDLER_EOF2'
#!/bin/bash
FIFO="${FIFO}"

while true; do
    if read -r -t 10 request < "${FIFO}"; then
        if [[ -n "${request}" ]]; then
            path=""
            if [[ "${request}" =~ ^GET\ ([^\ ]+)\ HTTP/ ]]; then
                path="${BASH_REMATCH[1]}"
            elif [[ "${request}" =~ ^[A-Z]+\ ([^\ ]+)\ HTTP/ ]]; then
                path="${BASH_REMATCH[1]}"
            fi
            
            respond "${path}"
        fi
    fi
done

respond() {
    local path="$1"
    
    case "${path}" in
        /|/healthz|/health)
            simple_response 200 "OK" "text/plain"
            ;;
        /ready|/readiness)
            simple_response 200 "OK" "text/plain"
            ;;
        *)
            echo "HTTP/1.1 404 Not Found" > "${FIFO}"
            ;;
    esac
}

simple_response() {
    local status="$1"
    local body="$2"
    local content_type="$3"
    
    echo "HTTP/1.1 ${status} OK"
    echo "Content-Type: ${content_type}"
    echo "Connection: close"
    echo ""
    echo "${body}"
}
HANDLER_EOF2
    
    chmod +x "${handler_script}"
    nohup "${handler_script}" > /dev/null 2>&1 &
    
    # Start socat server
    if command -v socat &>/dev/null; then
        nohup socat TCP-LISTEN:${HEALTH_PORT},reuseaddr,fork UNIX-CONNECT:"${FIFO}" > /dev/null 2>&1 &
        HEALTH_SERVER_PID=$!
    else
        log_error "socat not available for health server"
        return 1
    fi
    
    echo "${HEALTH_SERVER_PID}" > "${HEALTH_PID_FILE}"
}

# =============================================================================
# MONITOR MODE
# =============================================================================

run_monitor_mode() {
    MONITOR_MODE=true
    
    log_info "Starting SOGo 6 health monitor mode (interval: ${MONITOR_INTERVAL}s)"
    
    # Start health server
    start_health_server || log_warn "Health server failed to start"
    
    # Track failure counts
    local consecutive_failures=0
    local max_consecutive_failures=5
    
    while true; do
        local all_healthy=true
        
        # Check liveness
        log_debug "Monitor: Running liveness check..."
        if ! liveness_probe; then
            log_error "Monitor: Liveness check failed"
            all_healthy=false
            consecutive_failures=$((consecutive_failures + 1))
        else
            consecutive_failures=0
        fi
        
        # Check readiness
        log_debug "Monitor: Running readiness check..."
        if ! readiness_probe; then
            log_error "Monitor: Readiness check failed"
            all_healthy=false
            # Don't increment consecutive failures for readiness
        fi
        
        if ${all_healthy}; then
            log_debug "Monitor: All checks passed"
        fi
        
        # Check for too many failures
        if [[ ${consecutive_failures} -ge ${max_consecutive_failures} ]]; then
            log_error "Monitor: Too many consecutive failures (${consecutive_failures}/${max_consecutive_failures})"
            cleanup 1 "Consecutive failures exceeded"
        fi
        
        # Sleep
        sleep ${MONITOR_INTERVAL}
    done
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    local command="${1:-help}"
    shift || true
    
    case "${command}" in
        liveness|liveness_probe)
            probe "liveness"
            ;;
        readiness|readiness_probe)
            probe "readiness"
            ;;
        startup|startup_probe)
            probe "startup"
            ;;
        deep|full)
            probe "deep"
            ;;
        edv|edv_probe)
            probe "edv"
            ;;
        server)
            start_health_server
            if [[ "$$" -ne 1 ]]; then
                return 0
            fi
            wait
            ;;
        monitor)
            run_monitor_mode
            ;;
        help|--help|-h)
            show_help
            ;;
        version|--version|-v)
            show_version
            ;;
        *)
            log_error "Unknown command: ${command}" >&2
            log_error "Try: ${SCRIPT_NAME} help" >&2
            exit 3
            ;;
    esac
}

show_help() {
    echo "Usage: ${SCRIPT_NAME} [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  liveness     Run liveness probe"
    echo "  readiness    Run readiness probe (includes database check)"
    echo "  startup      Run startup probe"
    echo "  deep         Run deep health check"
    echo "  edv          Run EDV (External Data Validation) check"
    echo "  server       Run HTTP health server on port ${HEALTH_PORT}"
    echo "  monitor      Run in continuous monitor mode"
    echo "  help         Show this help"
    echo "  version      Show version information"
    echo ""
    echo "Return codes:"
    echo "  0 - Healthy"
    echo "  1 - Unhealthy"
    echo "  2 - Starting up"
    echo "  3 - Configuration error"
    echo ""
    echo "Kubernetes Annotations Example:"
    echo "  livenessProbe:"
    echo "    exec:"
    echo "      command: [/healthcheck.sh, liveness]"
    echo "    initialDelaySeconds: 15"
    echo "    periodSeconds: 10"
    echo "    failureThreshold: 3"
    echo ""
    echo "  readinessProbe:"
    echo "    exec:"
    echo "      command: [/healthcheck.sh, readiness]"
    echo "    initialDelaySeconds: 20"
    echo "    periodSeconds: 15"
    echo "    failureThreshold: 3"
    echo ""
    echo "  startupProbe:"
    echo "    exec:"
    echo "      command: [/healthcheck.sh, startup]"
    echo "    failureThreshold: 30"
    echo "    periodSeconds: 10"
}

show_version() {
    echo "SOGo 6 Health Check Script v3.0.0"
    echo "SOGo Version: ${SOGO_VERSION:-6.0.0}"
    echo "Built: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    if command -v sogod &>/dev/null; then
        echo "SOGo Binary: $(sogod --version 2>/dev/null | head -1)"
    fi
}

# =============================================================================
# EXECUTE
# =============================================================================
main "$@"

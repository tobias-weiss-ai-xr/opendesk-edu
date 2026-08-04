#!/usr/bin/env bash
# SOGo 5 Health Check Script
# SPDX-License-Identifier: Apache-2.0
# File: healthcheck.sh
# Purpose: Multi-probe health checking for SOGo 5 container
# Version: 2.0.0
# Author: openDesk Edu Team
#
# This script provides comprehensive health checking for SOGo 5 containers:
#   - Liveness probe: Is the service running?
#   - Readiness probe: Is the service ready to receive requests?
#   - Startup probe: Has the service started successfully?
#   - HTTP health server: Exposes health endpoints for Kubernetes
#
# Probes:
#   - liveness: Check if SOGo and Memcached processes are running
#   - readiness: Check if SOGo is responding to HTTP requests
#   - startup: Check if SOGo has completed startup
#   - deep: Comprehensive check including database connectivity
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
#   # Run HTTP health server
#   /healthcheck.sh server
#   
#   # Run as PID 1 with signal handling
#   /healthcheck.sh monitor
#   
# Return codes:
#   0 - Healthy
#   1 - Unhealthy
#   2 - Starting up
#   3 - Configuration error
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
readonly STARTUP_TIMEOUT=60

# SOGo specific
readonly SOGO_DEFAULT_PORT=20000
readonly SOGO_WO_PORT=20000

# Probe intervals (for monitor mode)
readonly MONITOR_INTERVAL=10
readonly LIVENESS_INTERVAL=5
readonly READINESS_INTERVAL=10

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
HEALTH_SERVER_PID=""
SHUTDOWN_REQUESTED=false
MONITOR_MODE=false

# Probe state
LIVENESS_HEALTHY=false
READINESS_HEALTHY=false
STARTUP_COMPLETE=false

# Startup tracking
STARTUP_START_TIME=0

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
    
    # When running as probe, only log errors to avoid breaking health check output
    if [[ "${SCRIPT_MODE:-}" == "probe" ]]; then
        if [[ "${level}" == "ERROR" ]]; then
            echo -e "${color}[${level}]$(log_timestamp)${NC} ${message}" >&2
        fi
        return
    fi
    
    echo -e "${color}[${level}]$(log_timestamp)${NC} ${message}"
}

log_debug() {
    log_message "DEBUG" "${BLUE}" "$1"
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
        # Give it time to cleanup
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
        liveness)
            liveness_probe
            exit_code=$?
            ;;
        readiness)
            readiness_probe
            exit_code=$?
            ;;
        startup)
            startup_probe
            exit_code=$?
            ;;
        deep|full)
            deep_probe
            exit_code=$?
            ;;
        *)
            echo "Unknown probe type: ${probe_type}"
            echo "Usage: ${SCRIPT_NAME} {liveness|readiness|startup|deep}"
            exit 3
            ;;
    esac
    
    # Output result in Kubernetes-compatible format
    if [[ ${exit_code} -eq 0 ]]; then
        echo "OK"
    else
        echo "FAIL" >&2
    fi
    
    exit ${exit_code}
}

# Liveness Probe: Check if the service is running
# Should fail quickly if the service is in a broken state
liveness_probe() {
    local failures=0
    local max_failures=1
    
    log_debug "Running liveness probe"
    
    # Check SOGo process
    if ! check_process "${SOGO_PROCESS}" "${SOGO_PID_FILE}"; then
        log_error "Liveness: SOGo process not running"
        return 1
    fi
    
    # Check Memcached process (optional for liveness, but good to have)
    if ! check_process "${MEMCACHED_PROCESS}" "${MEMCACHED_PID_FILE}"; then
        log_warn "Liveness: Memcached process not running"
        # Don't fail liveness on Memcached alone
    fi
    
    # Check if SOGo is listening on its port
    if ! check_tcp_port ${SOGO_DEFAULT_PORT} "SOGo"; then
        log_error "Liveness: SOGo not listening on port ${SOGO_DEFAULT_PORT}"
        return 1
    fi
    
    log_debug "Liveness probe: PASSED"
    return 0
}

# Readiness Probe: Check if the service is ready to receive requests
# Should fail if the service is not ready to handle traffic
readiness_probe() {
    local failures=0
    local max_failures=1
    
    log_debug "Running readiness probe"
    
    # First check liveness
    if ! liveness_probe; then
        log_error "Readiness: Liveness check failed"
        return 1
    fi
    
    # Check if SOGo responds to HTTP requests
    if ! check_sogo_http; then
        log_error "Readiness: SOGo HTTP check failed"
        return 1
    fi
    
    # Check if Memcached is responding
    if ! check_memcached_health; then
        log_error "Readiness: Memcached not responding"
        return 1
    fi
    
    # Check database connectivity
    if ! check_database_connectivity "${SOGO_DB_TYPE:-PostgreSQL}"; then
        log_error "Readiness: Database connectivity check failed"
        return 1
    fi
    
    log_debug "Readiness probe: PASSED"
    return 0
}

# Startup Probe: Check if the service has started successfully
# Should succeed once the service has started, even if not ready
# Kubernetes will switch to liveness/readiness probes after initial delay
startup_probe() {
    log_debug "Running startup probe"
    
    # Check if SOGo process exists
    if ! check_process "${SOGO_PROCESS}" "${SOGO_PID_FILE}"; then
        # If SOGo is not running, check if it's still starting
        if is_service_starting "${SOGO_PROCESS}"; then
            log_debug "Startup: SOGo is still starting"
            return 2
        else
            log_error "Startup: SOGo process not found and not starting"
            return 1
        fi
    fi
    
    # Check if SOGo is listening
    if check_tcp_port ${SOGO_DEFAULT_PORT} "SOGo"; then
        log_debug "Startup probe: PASSED (SOGo listening)"
        return 0
    fi
    
    # Check if Memcached is listening
    if ! check_tcp_port ${MEMCACHED_PORT:-11211} "Memcached"; then
        log_warn "Startup: Memcached not yet listening"
    fi
    
    # Give it more time
    log_debug "Startup: SOGo not yet listening on port ${SOGO_DEFAULT_PORT}"
    return 2
}

# Deep Probe: Comprehensive health check
# Checks all components and dependencies
deep_probe() {
    local failures=0
    
    log_debug "Running deep health probe"
    
    # Run all other probes
    if ! liveness_probe; then
        log_error "Deep: Liveness check failed"
        failures=$((failures + 1))
    fi
    
    if ! readiness_probe; then
        log_error "Deep: Readiness check failed"
        failures=$((failures + 1))
    fi
    
    # Check disk space
    if ! check_disk_space; then
        log_error "Deep: Disk space check failed"
        failures=$((failures + 1))
    fi
    
    # Check memory usage
    if ! check_memory_usage; then
        log_warn "Deep: Memory usage check failed"
        failures=$((failures + 1))
    fi
    
    # Check configuration files
    if ! check_configuration_files; then
        log_error "Deep: Configuration files check failed"
        failures=$((failures + 1))
    fi
    
    if [[ ${failures} -gt 0 ]]; then
        log_error "Deep probe: FAILED (${failures} checks failed)"
        return 1
    fi
    
    log_debug "Deep probe: PASSED"
    return 0
}

# =============================================================================
# CHECK FUNCTIONS
# =============================================================================

# Check if a process is running
check_process() {
    local process_name="$1"
    local pid_file="$2"
    
    # First try with PID file
    if [[ -n "${pid_file}" && -f "${pid_file}" ]]; then
        local pid
        pid=$(cat "${pid_file}" 2>/dev/null | tr -d '[:space:]')
        if [[ -n "${pid}" && -f "/proc/${pid}/status" ]]; then
            local cmdline
            cmdline=$(cat "/proc/${pid}/cmdline" 2>/dev/null | tr '\0' ' ')
            if [[ "${cmdline}" == *"${process_name}"* ]]; then
                return 0
            fi
        fi
    fi
    
    # Fallback to pgrep
    if pgrep -f "${process_name}" >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# Check if a service is in the process of starting
is_service_starting() {
    local process_name="$1"
    
    # Check if there are any processes related to startup
    if pgrep -f "entrypoint\|sh\|bash" >/dev/null 2>&1; then
        return 0  # There are startup scripts running
    fi
    
    # Check if the process name appears in /proc with recent start time
    local pids
    pids=$(pgrep -f "${process_name}" 2>/dev/null || true)
    
    if [[ -n "${pids}" ]]; then
        for pid in ${pids}; do
            if [[ -f "/proc/${pid}/stat" ]]; then
                local stat_info
                stat_info=$(cat "/proc/${pid}/stat" 2>/dev/null)
                # Field 22 is the start time in clock ticks
                # We can't easily convert to seconds without /proc/uptime, but
                # if it exists, it's running
                return 0
            fi
        done
    fi
    
    return 1
}

# Check if a TCP port is listening
check_tcp_port() {
    local port="$1"
    local service_name="$2"
    
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

# Check SOGo HTTP endpoint
check_sogo_http() {
    local url="http://localhost:${SOGO_DEFAULT_PORT}/SOGo"
    local http_code
    
    # Use curl if available
    if command -v curl &>/dev/null; then
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time ${HTTP_TIMEOUT} --connect-timeout ${SOCKET_TIMEOUT} "${url}" 2>/dev/null || echo "000")
        
        # Accept: 200 OK, 301 Moved, 302 Found, 401 Unauthorized (all indicate server is responding)
        case "${http_code}" in
            200|301|302|401|403)
                return 0
                ;;
            *)
                log_debug "SOGo HTTP check returned status: ${http_code}"
                return 1
                ;;
        esac
    fi
    
    # Fallback to wget
    if command -v wget &>/dev/null; then
        local output
        output=$(wget -q -S --spider --timeout=${HTTP_TIMEOUT} --tries=1 "${url}" 2>&1 || true)
        
        if echo "${output}" | grep -q "HTTP/1.1 [23]0[0-9]\|HTTP/2 [23]0[0-9]"; then
            return 0
        fi
    fi
    
    # Fallback to raw TCP connection
    if echo "GET /SOGo HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc -w ${HTTP_TIMEOUT} localhost ${SOGO_DEFAULT_PORT} 2>/dev/null | grep -q "HTTP/1.1"; then
        return 0
    fi
    
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
        
        if echo "${response}" | grep -q "STAT"; then
            return 0
        fi
    fi
    
    # Try telnet
    if command -v telnet &>/dev/null; then
        local response
        response=$(echo "stats\nquit" | telnet "${host}" "${port}" 2>/dev/null || true)
        
        if echo "${response}" | grep -q "STAT"; then
            return 0
        fi
    fi
    
    # Simple TCP connection test
    if nc -z -w ${SOCKET_TIMEOUT} "${host}" "${port}" 2>/dev/null; then
        return 0
    fi
    
    return 1
}

# Check database connectivity
check_database_connectivity() {
    local db_type="$1"
    local db_host="${SOGO_DB_HOST:-localhost}"
    local db_port="${SOGO_DB_PORT:-5432}"
    local db_name="${SOGO_DB_NAME:-sogo}"
    local db_user="${SOGO_DB_USER:-sogo}"
    local db_password="${SOGO_DB_PASSWORD:-}"
    
    case "${db_type,,}" in
        postgresql|pgsql)
            # Use pg_isready if available
            if command -v pg_isready &>/dev/null; then
                if PGPASSWORD="${db_password}" pg_isready -h "${db_host}" -p "${db_port}" -U "${db_user}" -d "${db_name}" -t 2 >/dev/null 2>&1; then
                    return 0
                fi
            fi
            
            # Fallback to psql
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
            log_debug "Unknown database type: ${db_type}, skipping connectivity check"
            return 0  # Don't fail on unknown types
            ;;
    esac
    
    return 1
}

# Check disk space
check_disk_space() {
    local threshold=90  # 90% full is unhealthy
    
    local usage
    usage=$(df -k / 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
    
    if [[ -z "${usage}" ]]; then
        log_warn "Could not determine disk usage"
        return 1
    fi
    
    if [[ ${usage} -ge ${threshold} ]]; then
        log_error "Disk usage is ${usage}% (threshold: ${threshold}%)"
        return 1
    fi
    
    return 0
}

# Check memory usage
check_memory_usage() {
    local threshold=95  # 95% memory usage is unhealthy
    
    local total_mem
    local used_mem
    
    if [[ -f "/proc/meminfo" ]]; then
        total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        available_mem=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        
        if [[ -n "${total_mem}" && -n "${available_mem}" && ${total_mem} -gt 0 ]]; then
            local used_percent=$(((total_mem - available_mem) * 100 / total_mem))
            
            if [[ ${used_percent} -ge ${threshold} ]]; then
                log_error "Memory usage is ${used_percent}% (threshold: ${threshold}%)"
                return 1
            fi
        fi
    fi
    
    return 0
}

# Check configuration files
check_configuration_files() {
    local required_files=(
        "/etc/sogo/sogo.conf"
        "/etc/GNUstep/GNUstep.conf"
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
    
    return 0
}

# =============================================================================
# HTTP HEALTH SERVER
# =============================================================================

# Start HTTP health server
start_health_server() {
    log_info "Starting health server on ${HEALTH_HOST}:${HEALTH_PORT}..."
    
    # Check if already running
    if [[ -n "${HEALTH_SERVER_PID}" && kill -0 "${HEALTH_SERVER_PID}" 2>/dev/null ]]; then
        log_info "Health server already running (PID: ${HEALTH_SERVER_PID})"
        return 0
    fi
    
    # Check if port is available
    if check_tcp_port ${HEALTH_PORT} "Health Server"; then
        log_error "Port ${HEALTH_PORT} already in use"
        return 1
    fi
    
    # Create a simple HTTP server using a FIFO pipe and socat
    # Since we can't rely on Python or Node, we use a simple approach
    
    # Create named pipe for communication
    local FIFO="/tmp/health_fifo"
    rm -f "${FIFO}"
    mkfifo "${FIFO}" || {
        log_error "Failed to create FIFO pipe"
        return 1
    }
    chmod 600 "${FIFO}"
    
    # Start netcat/socat server (prefer socat for better control)
    local server_cmd=""
    if command -v socat &>/dev/null; then
        server_cmd="socat TCP-LISTEN:${HEALTH_PORT},reuseaddr,fork UNIX-CONNECT:\"${FIFO}\""
    elif command -v nc &>/dev/null; then
        # nc doesn't support persistent listening easily, use a loop
        server_cmd="while true; do nc -l -p ${HEALTH_PORT} < \"${FIFO}\" > \"${FIFO}\"; done"
    fi
    
    if [[ -z "${server_cmd}" ]]; then
        log_error "No suitable command for health server (need socat or nc)"
        rm -f "${FIFO}"
        return 1
    fi
    
    # Start the server
    nohup bash -c "${server_cmd}" > /dev/null 2>&1 &
    HEALTH_SERVER_PID=$!
    
    # Save PID
    echo "${HEALTH_SERVER_PID}" > "${HEALTH_PID_FILE}"
    
    # Create a script to read from FIFO and return appropriate responses
    local handler_script="${SCRIPT_DIR}/health_handler.sh"
    cat > "${handler_script}" << 'HANDLER_EOF'
#!/bin/bash
FIFO="${FIFO}"
while true; do
    if read -r request < "${FIFO}"; then
        if [[ "${request}" == GET* ]]; then
            path=$(echo "${request}" | awk '{print $2}')
            case "${path}" in
                /healthz|/health)
                    echo "HTTP/1.1 200 OK"
                    echo "Content-Type: text/plain"
                    echo ""
                    echo "OK"
                    ;;
                /ready|/readiness)
                    if /healthcheck.sh readiness >/dev/null 2>&1; then
                        echo "HTTP/1.1 200 OK"
                        echo "Content-Type: text/plain"
                        echo ""
                        echo "OK"
                    else
                        echo "HTTP/1.1 503 Service Unavailable"
                        echo "Content-Type: text/plain"
                        echo ""
                        echo "NOT READY"
                    fi
                    ;;
                /live|/liveness)
                    if /healthcheck.sh liveness >/dev/null 2>&1; then
                        echo "HTTP/1.1 200 OK"
                        echo "Content-Type: text/plain"
                        echo ""
                        echo "OK"
                    else
                        echo "HTTP/1.1 503 Service Unavailable"
                        echo "Content-Type: text/plain"
                        echo ""
                        echo "NOT ALIVE"
                    fi
                    ;;
                /startup|/start)
                    if /healthcheck.sh startup >/dev/null 2>&1; then
                        local exit_code=$?
                        if [[ ${exit_code} -eq 0 ]]; then
                            echo "HTTP/1.1 200 OK"
                            echo "Content-Type: text/plain"
                            echo ""
                            echo "STARTED"
                        elif [[ ${exit_code} -eq 2 ]]; then
                            echo "HTTP/1.1 102 Processing"
                            echo "Content-Type: text/plain"
                            echo ""
                            echo "STARTING"
                        else
                            echo "HTTP/1.1 503 Service Unavailable"
                            echo "Content-Type: text/plain"
                            echo ""
                            echo "FAILED"
                        fi
                    fi
                    ;;
                /deep)
                    if /healthcheck.sh deep >/dev/null 2>&1; then
                        echo "HTTP/1.1 200 OK"
                        echo "Content-Type: text/plain"
                        echo ""
                        echo "OK"
                    else
                        echo "HTTP/1.1 503 Service Unavailable"
                        echo "Content-Type: text/plain"
                        echo ""
                        echo "UNHEALTHY"
                    fi
                    ;;
                /status)
                    echo "HTTP/1.1 200 OK"
                    echo "Content-Type: application/json"
                    echo ""
                    echo '{"status": {"liveness": "unknown", "readiness": "unknown"}}'
                    ;;
                *)
                    echo "HTTP/1.1 404 Not Found"
                    echo "Content-Type: text/plain"
                    echo ""
                    echo "404 - Not Found"
                    ;;
            esac
        fi
    fi
done
HANDLER_EOF
    
    chmod +x "${handler_script}"
    nohup "${handler_script}" > /dev/null 2>&1 &
    
    # Wait for server to start
    local count=0
    while [[ ${count} -lt 10 ]]; do
        if check_tcp_port ${HEALTH_PORT} "Health Server"; then
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

# =============================================================================
# MONITOR MODE
# =============================================================================

# Run in monitor mode (performs regular health checks)
run_monitor_mode() {
    MONITOR_MODE=true
    
    log_info "Starting health monitor mode (interval: ${MONITOR_INTERVAL}s)"
    
    # Start health server
    start_health_server || log_warn "Health server failed to start"
    
    # Track state
    local consecutive_liveness_failures=0
    local consecutive_readiness_failures=0
    local healthy=true
    
    while true; do
        # Check liveness
        if ! liveness_probe; then
            consecutive_liveness_failures=$((consecutive_liveness_failures + 1))
            log_error "Liveness check failed (${consecutive_liveness_failures} consecutive failures)"
            
            if [[ ${consecutive_liveness_failures} -ge 3 ]]; then
                log_error "Too many liveness failures, exiting..."
                cleanup 1 "Liveness check failed"
            fi
        else
            consecutive_liveness_failures=0
        fi
        
        # Check readiness
        if ! readiness_probe; then
            consecutive_readiness_failures=$((consecutive_readiness_failures + 1))
            log_warn "Readiness check failed (${consecutive_readiness_failures} consecutive failures)"
        else
            consecutive_readiness_failures=0
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
        liveness|readiness|startup|deep|full)
            probe "${command}"
            ;;
        server)
            start_health_server
            # If we're not running as PID 1, return
            if [[ "$$" -ne 1 ]]; then
                return 0
            fi
            # Otherwise, wait forever
            wait
            ;;
        monitor)
            run_monitor_mode
            ;;
        help|--help|-h)
            echo "Usage: ${SCRIPT_NAME} [COMMAND]"
            echo ""
            echo "Commands:"
            echo "  liveness     Run liveness probe"
            echo "  readiness    Run readiness probe"
            echo "  startup      Run startup probe"
            echo "  deep, full   Run deep health check"
            echo "  server       Run HTTP health server"
            echo "  monitor      Run in monitor mode"
            echo "  help         Show this help"
            echo ""
            echo "Kubernetes Annotations Example:"
            echo "  livenessProbe:"
            echo "    exec:"
            echo "      command: [/healthcheck.sh, liveness]"
            echo "    initialDelaySeconds: 10"
            echo "    periodSeconds: 10"
            echo ""
            echo "  readinessProbe:"
            echo "    exec:"
            echo "      command: [/healthcheck.sh, readiness]"
            echo "    initialDelaySeconds: 15"
            echo "    periodSeconds: 15"
            echo ""
            echo "  startupProbe:"
            echo "    exec:"
            echo "      command: [/healthcheck.sh, startup]"
            echo "    failureThreshold: 30"
            echo "    periodSeconds: 10"
            ;;
        *)
            log_error "Unknown command: ${command}"
            log_error "Try: ${SCRIPT_NAME} help"
            exit 3
            ;;
    esac
}

# =============================================================================
# EXECUTE
# =============================================================================
main "$@"

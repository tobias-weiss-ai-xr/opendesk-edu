#!/usr/bin/env bash
# Dev Agent Operator Health Check Script
# SPDX-License-Identifier: Apache-2.0
# File: healthcheck.sh
# Purpose: Multi-probe health checking for Dev Agent Operator container
# Version: 3.0.0
# Built: 2026-08-03T12:00:00Z
# Author: openDesk Edu Team
#
# This script provides comprehensive health checking for the Dev Agent Operator:
#   - Liveness probe: Is the operator running?
#   - Readiness probe: Is the operator ready to process repairs?
#   - Startup probe: Has the operator started successfully?
#   - HTTP health server: Exposes health endpoints for Kubernetes
#   - Cluster health: Check connectivity to Kubernetes API
#   - Repair capability: Verify operator can access required resources
#
# FEATURES:
#   - Kubernetes API connectivity check
#   - CRD availability check (HealthPolicy, RepairStrategy)
#   - Operator metrics endpoint check
#   - RBAC permissions verification
#   - Repair controller readiness check
#   - Health controller readiness check
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
# Return codes:
#   0 - Healthy
#   1 - Unhealthy
#   2 - Starting up
#   3 - Configuration error
#   4 - Kubernetes connection failed
#

set -euo pipefail

# =============================================================================
# CONSTANTS
# =============================================================================
readonly SCRIPT_NAME=$(basename "${0}")
readonly SCRIPT_DIR=$(dirname "$(readlink -f "${0}" 2>/dev/null || echo "${0}")")

# Operator binary
readonly OPERATOR_BIN="/usr/local/bin/manager"
readonly OPERATOR_PROCESS="manager"
readonly OPERATOR_PID_FILE="/tmp/operator.pid"

# Health server
readonly HEALTH_HOST="0.0.0.0"
readonly HEALTH_PORT=8081
readonly HEALTH_PID_FILE="/tmp/health.pid"

# Kubernetes
readonly KUBECONFIG="/home/opendesk/.kube/config"
readonly KUBECTL="/usr/local/bin/kubectl"
readonly DEFAULT_NAMESPACES=("opendesk" "opendesk-edu" "default")

# Operator metrics
readonly OPERATOR_METRICS_PORT=8080
readonly OPERATOR_METRICS_PATH="/metrics"

# CRDs
readonly HEALTH_POLICY_CRD="healthpolicies.opendesk-dev-agent.tobias-weiss-ai-xr.github.com"
readonly REPAIR_STRATEGY_CRD="repairstrategies.opendesk-dev-agent.tobias-weiss-ai-xr.github.com"

# Timeout values
readonly SOCKET_TIMEOUT=2
readonly HTTP_TIMEOUT=5
readonly KUBE_API_TIMEOUT=10
readonly STARTUP_TIMEOUT=60

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
SCRIPT_MODE=""

# Cache for probe results
CACHE_TIMEOUT=10
LAST_CACHE_TIME=0
declare -A PROBE_CACHE

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
    
    # Minimal output in probe mode
    if [[ "${SCRIPT_MODE:-}" == "probe" ]]; then
        [[ "${level}" == "ERROR" ]] && echo -e "${color}[${level}]$(log_timestamp)${NC} ${message}" >&2
        return
    fi
    
    echo -e "${color}[${level}]$(log_timestamp)${NC} ${message}"
}

log_debug() {
    [[ "${SCRIPT_MODE:-}" != "probe" ]] && log_message "DEBUG" "${BLUE}" "$1"
}

log_info() {
    [[ "${SCRIPT_MODE:-}" != "probe" ]] && log_message "INFO" "${BLUE}" "$1"
}

log_success() {
    [[ "${SCRIPT_MODE:-}" != "probe" ]] && log_message "SUCCESS" "${GREEN}" "$1"
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
    
    [[ -n "${HEALTH_SERVER_PID}" && -d "/proc/${HEALTH_SERVER_PID}" ]] && kill -TERM "${HEALTH_SERVER_PID}" 2>/dev/null || true
    sleep 2
    [[ -n "${HEALTH_SERVER_PID}" && -d "/proc/${HEALTH_SERVER_PID}" ]] && kill -KILL "${HEALTH_SERVER_PID}" 2>/dev/null || true
    
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
        k8s|kubernetes)
            kubernetes_probe
            exit_code=$?
            ;;
        *)
            echo "Unknown probe type: ${probe_type}" >&2
            exit 3
            ;;
    esac
    
    # Kubernetes-compatible output
    if [[ ${exit_code} -eq 0 ]]; then
        echo "OK"
    else
        echo "FAIL" >&2
    fi
    
    exit ${exit_code}
}

# Liveness Probe: Check if operator process is running
liveness_probe() {
    log_debug "Running liveness probe"
    
    # Check operator process
    if ! check_process "${OPERATOR_PROCESS}" "${OPERATOR_PID_FILE}"; then
        log_error "Liveness: Operator process not running"
        return 1
    fi
    
    # Check if operator is listening on metrics port
    if ! check_tcp_port ${OPERATOR_METRICS_PORT} "Operator metrics"; then
        log_error "Liveness: Operator not listening on metrics port ${OPERATOR_METRICS_PORT}"
        return 1
    fi
    
    log_debug "Liveness probe: PASSED"
    return 0
}

# Readiness Probe: Check if operator is ready to process
readiness_probe() {
    log_debug "Running readiness probe"
    
    # First check liveness
    if ! liveness_probe; then
        log_error "Readiness: Liveness check failed"
        return 1
    fi
    
    # Check Kubernetes API connectivity
    if ! check_kubernetes_api; then
        log_error "Readiness: Kubernetes API not reachable"
        return 4
    fi
    
    # Check required CRDs exist
    if ! check_required_crds; then
        log_error "Readiness: Required CRDs not found"
        return 3
    fi
    
    # Check operator can access its namespace
    if ! check_operator_namespace; then
        log_error "Readiness: Operator cannot access its namespace"
        return 3
    fi
    
    # Check repair controller readiness (if running as leader)
    if ! check_repair_controller; then
        log_warn "Readiness: Repair controller not ready"
        # Don't fail on this - might not be leader
    fi
    
    # Check health controller readiness
    if ! check_health_controller; then
        log_warn "Readiness: Health controller not ready"
        # Don't fail on this - might not be leader
    fi
    
    log_debug "Readiness probe: PASSED"
    return 0
}

# Startup Probe: Check if operator has started successfully
startup_probe() {
    log_debug "Running startup probe"
    
    # Check if operator process exists
    if ! check_process "${OPERATOR_PROCESS}" "${OPERATOR_PID_FILE}"; then
        if is_service_starting "${OPERATOR_PROCESS}"; then
            log_debug "Startup: Operator is still starting"
            return 2
        else
            log_error "Startup: Operator process not found and not starting"
            return 1
        fi
    fi
    
    # Check if operator is listening on metrics port
    if ! check_tcp_port_no_retry ${OPERATOR_METRICS_PORT}; then
        log_debug "Startup: Operator not yet listening on metrics port"
        return 2
    fi
    
    # Check if operator has completed its startup sequence
    # This is indicated by the metrics endpoint being available
    if ! check_metrics_endpoint_no_retry; then
        log_debug "Startup: Metrics endpoint not yet available"
        return 2
    fi
    
    log_debug "Startup probe: PASSED (Operator fully started)"
    return 0
}

# Deep Probe: Comprehensive health check
deep_probe() {
    local failures=0
    
    log_debug "Running deep health probe"
    
    # Run liveness and readiness
    if ! liveness_probe; then
        log_error "Deep: Liveness check failed"
        failures=$((failures + 1))
    fi
    
    if ! readiness_probe; then
        log_error "Deep: Readiness check failed"
        failures=$((failures + 1))
    fi
    
    # Check Kubernetes connection in more detail
    if ! kubernetes_probe; then
        log_error "Deep: Kubernetes probe failed"
        failures=$((failures + 1))
    fi
    
    # Check RBAC permissions
    if ! check_rbac_permissions; then
        log_warn "Deep: RBAC permission check failed"
        failures=$((failures + 1))
    fi
    
    # Check disk and memory
    if ! check_system_health; then
        log_warn "Deep: System health check failed"
        failures=$((failures + 1))
    fi
    
    # Check operator metrics
    if ! check_operator_metrics; then
        log_warn "Deep: Metrics check failed"
        failures=$((failures + 1))
    fi
    
    if [[ ${failures} -gt 0 ]]; then
        log_error "Deep probe: FAILED (${failures} checks failed)"
        return 1
    fi
    
    log_debug "Deep probe: PASSED"
    return 0
}

# Kubernetes-specific probe
kubernetes_probe() {
    log_debug "Running Kubernetes probe"
    
    # Check API server connectivity
    if ! check_kubernetes_api; then
        log_error "Kubernetes: API server not reachable"
        return 4
    fi
    
    # Check node status
    if ! check_node_health; then
        log_warn "Kubernetes: Node health check failed"
        return 1
    fi
    
    # Check if we can list pods
    if ! check_pod_listing; then
        log_error "Kubernetes: Cannot list pods"
        return 1
    fi
    
    # Check if we can list CRDs
    if ! check_crd_listing; then
        log_error "Kubernetes: Cannot list CRDs"
        return 1
    fi
    
    log_debug "Kubernetes probe: PASSED"
    return 0
}

# =============================================================================
# CHECK FUNCTIONS
# =============================================================================

# Process check
check_process() {
    local process_name="$1"
    local pid_file="$2"
    
    # Try with PID file first
    if [[ -n "${pid_file}" && -f "${pid_file}" ]]; then
        local pid
        pid=$(cat "${pid_file}" 2>/dev/null | tr -d '[:space:]')
        if [[ -n "${pid}" && -d "/proc/${pid}" ]]; then
            return 0
        fi
    fi
    
    # Fallback to pgrep
    if pgrep -f "${process_name}" >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# Non-cached process check
check_process_no_retry() {
    check_process "$1" "$2"
    return $?
}

# TCP port check with retry
check_tcp_port() {
    local port="$1"
    local service="$2"
    local max_retries=3
    
    for ((i=0; i<max_retries; i++)); do
        if check_tcp_port_no_retry ${port}; then
            return 0
        fi
        sleep 1
    done
    
    log_debug "Port ${port} not listening (${service})"
    return 1
}

# TCP port check without retry
check_tcp_port_no_retry() {
    local port="$1"
    
    # Use ss first
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

# Check if service is starting
is_service_starting() {
    local process_name="$1"
    
    # Check for entrypoint or init processes
    if pgrep -f "entrypoint" >/dev/null 2>&1; then
        return 0
    fi
    
    # Check for shell processes that might be starting the operator
    if ps aux 2>/dev/null | grep -i "${SCRIPT_DIR}/entrypoint\|manager" | grep -v grep | grep -v healthcheck >/dev/null; then
        # Count how many processes we found
        local count
        count=$(ps aux 2>/dev/null | grep -i "${SCRIPT_DIR}/entrypoint\|manager" | grep -v grep | grep -v healthcheck | wc -l)
        if [[ ${count} -gt 0 ]]; then
            return 0
        fi
    fi
    
    return 1
}

# Kubernetes API connectivity check
check_kubernetes_api() {
    local now
    now=$(date +%s)
    
    # Check cache
    if [[ -n "${PROBE_CACHE[k8s_api]:-}" ]]; then
        local cached_time="${PROBE_CACHE[k8s_api]%%:*}"
        local cached_result="${PROBE_CACHE[k8s_api]##*:}"
        
        if [[ $((now - cached_time)) -lt ${CACHE_TIMEOUT} ]]; then
            [[ "${cached_result}" == "OK" ]] && return 0 || return 1
        fi
    fi
    
    # Try kubectl
    if [[ -x "${KUBECTL}" ]]; then
        if KUBECONFIG="${KUBECONFIG}" "${KUBECTL}" get --raw /healthz >/dev/null 2>&1; then
            PROBE_CACHE[k8s_api]="${now}:OK"
            return 0
        fi
    fi
    
    # Try in-cluster service account
    local service_account_dir="/var/run/secrets/kubernetes.io/serviceaccount"
    if [[ -d "${service_account_dir}" ]]; then
        local ca_crt="${service_account_dir}/ca.crt"
        local token="${service_account_dir}/token"
        local namespace="${service_account_dir}/namespace"
        
        if [[ -f "${ca_crt}" && -f "${token}" ]]; then
            local api_server="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}"
            
            if curl --cacert "${ca_crt}" --header "Authorization: Bearer $(cat ${token})" \
                -s -o /dev/null -w "%{http_code}" --max-time ${KUBE_API_TIMEOUT} "${api_server}/healthz" 2>/dev/null | grep -q "200"; then
                PROBE_CACHE[k8s_api]="${now}:OK"
                return 0
            fi
        fi
    fi
    
    # Try with kubectl from default location
    if command -v kubectl &>/dev/null; then
        if kubectl get --raw /healthz >/dev/null 2>&1; then
            PROBE_CACHE[k8s_api]="${now}:OK"
            return 0
        fi
    fi
    
    log_debug "Kubernetes API not reachable"
    PROBE_CACHE[k8s_api]="${now}:FAIL"
    return 1
}

# Check required CRDs exist
check_required_crds() {
    local now
    now=$(date +%s)
    
    # Cache key
    local cache_key="crds_$(echo "${OPERATOR_WATCH_NAMESPACES:-default}" | md5sum | cut -c1-8)"
    
    if [[ -n "${PROBE_CACHE[${cache_key}]:-}" ]]; then
        local cached_time="${PROBE_CACHE[${cache_key}]%%:*}"
        local cached_result="${PROBE_CACHE[${cache_key}]##*:}"
        
        if [[ $((now - cached_time)) -lt ${CACHE_TIMEOUT} ]]; then
            [[ "${cached_result}" == "OK" ]] && return 0 || return 1
        fi
    fi
    
    # Check if kubectl is available
    local kubectl_cmd=""
    if [[ -x "${KUBECTL}" ]]; then
        kubectl_cmd="KUBECONFIG=${KUBECONFIG} ${KUBECTL}"
    elif command -v kubectl &>/dev/null; then
        kubectl_cmd="kubectl"
    fi
    
    if [[ -z "${kubectl_cmd}" ]]; then
        log_debug "kubectl not available, cannot check CRDs"
        PROBE_CACHE[${cache_key}]="${now}:FAIL"
        return 1
    fi
    
    # Check each required CRD
    local crds=("${HEALTH_POLICY_CRD}" "${REPAIR_STRATEGY_CRD}")
    
    for crd in "${crds[@]}"; do
        if ! ${kubectl_cmd} get crd "${crd}" >/dev/null 2>&1; then
            log_debug "CRD not found: ${crd}"
            PROBE_CACHE[${cache_key}]="${now}:FAIL"
            return 1
        fi
    done
    
    PROBE_CACHE[${cache_key}]="${now}:OK"
    return 0
}

# Check operator namespace
check_operator_namespace() {
    local namespace="${OPERATOR_NAMESPACE:-default}"
    local now
    now=$(date +%s)
    
    # Cache check
    if [[ -n "${PROBE_CACHE[ns_${namespace}]:-}" ]]; then
        local cached_time="${PROBE_CACHE[ns_${namespace}]%%:*}"
        local cached_result="${PROBE_CACHE[ns_${namespace}]##*:}"
        
        if [[ $((now - cached_time)) -lt ${CACHE_TIMEOUT} ]]; then
            [[ "${cached_result}" == "OK" ]] && return 0 || return 1
        fi
    fi
    
    # Try to get namespace
    local kubectl_cmd=""
    if [[ -x "${KUBECTL}" ]]; then
        kubectl_cmd="KUBECONFIG=${KUBECONFIG} ${KUBECTL}"
    elif command -v kubectl &>/dev/null; then
        kubectl_cmd="kubectl"
    fi
    
    if [[ -z "${kubectl_cmd}" ]]; then
        log_debug "kubectl not available for namespace check"
        return 1
    fi
    
    if ${kubectl_cmd} get namespace "${namespace}" >/dev/null 2>&1; then
        PROBE_CACHE[ns_${namespace}]="${now}:OK"
        return 0
    fi
    
    log_debug "Namespace not accessible: ${namespace}"
    PROBE_CACHE[ns_${namespace}]="${now}:FAIL"
    return 1
}

# Check repair controller readiness
check_repair_controller() {
    # Check if there are any repair-related pods or logs
    local kubectl_cmd=""
    if [[ -x "${KUBECTL}" ]]; then
        kubectl_cmd="KUBECONFIG=${KUBECONFIG} ${KUBECTL}"
    elif command -v kubectl &>/dev/null; then
        kubectl_cmd="kubectl"
    fi
    
    # If kubectl is not available, assume controller is ready (can't check)
    if [[ -z "${kubectl_cmd}" ]]; then
        return 0
    fi
    
    # Check if we can list RepairStrategy resources
    local namespace="${OPERATOR_NAMESPACE:-default}"
    if ${kubectl_cmd} -n "${namespace}" get repairstrategies >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# Check health controller readiness
check_health_controller() {
    local kubectl_cmd=""
    if [[ -x "${KUBECTL}" ]]; then
        kubectl_cmd="KUBECONFIG=${KUBECONFIG} ${KUBECTL}"
    elif command -v kubectl &>/dev/null; then
        kubectl_cmd="kubectl"
    fi
    
    if [[ -z "${kubectl_cmd}" ]]; then
        return 0
    fi
    
    local namespace="${OPERATOR_NAMESPACE:-default}"
    if ${kubectl_cmd} -n "${namespace}" get healthpolicies >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# Check node health
check_node_health() {
    local kubectl_cmd=""
    if [[ -x "${KUBECTL}" ]]; then
        kubectl_cmd="KUBECONFIG=${KUBECONFIG} ${KUBECTL}"
    elif command -v kubectl &>/dev/null; then
        kubectl_cmd="kubectl"
    fi
    
    if [[ -z "${kubectl_cmd}" ]]; then
        return 0  # Can't check, assume OK
    fi
    
    # Check current node
    local node_name
    node_name=$(cat /etc/hostname 2>/dev/null || echo "")
    
    if [[ -n "${node_name}" ]]; then
        if ${kubectl_cmd} describe node "${node_name}" >/dev/null 2>&1; then
            return 0
        fi
    fi
    
    return 1
}

# Check if we can list pods
check_pod_listing() {
    local kubectl_cmd=""
    if [[ -x "${KUBECTL}" ]]; then
        kubectl_cmd="KUBECONFIG=${KUBECONFIG} ${KUBECTL}"
    elif command -v kubectl &>/dev/null; then
        kubectl_cmd="kubectl"
    fi
    
    if [[ -z "${kubectl_cmd}" ]]; then
        return 0  # Can't check, assume OK
    fi
    
    # Try to list pods in operator namespace
    local namespace="${OPERATOR_NAMESPACE:-default}"
    if ${kubectl_cmd} -n "${namespace}" get pods --no-headers --field-selector=status.phase=Running >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# Check if we can list CRDs
check_crd_listing() {
    local kubectl_cmd=""
    if [[ -x "${KUBECTL}" ]]; then
        kubectl_cmd="KUBECONFIG=${KUBECONFIG} ${KUBECTL}"
    elif command -v kubectl &>/dev/null; then
        kubectl_cmd="kubectl"
    fi
    
    if [[ -z "${kubectl_cmd}" ]]; then
        return 0  # Can't check, assume OK
    fi
    
    if ${kubectl_cmd} get crd >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# Check RBAC permissions
check_rbac_permissions() {
    local kubectl_cmd=""
    if [[ -x "${KUBECTL}" ]]; then
        kubectl_cmd="KUBECONFIG=${KUBECONFIG} ${KUBECTL}"
    elif command -v kubectl &>/dev/null; then
        kubectl_cmd="kubectl"
    fi
    
    if [[ -z "${kubectl_cmd}" ]]; then
        return 0  # Can't check, assume OK
    fi
    
    local namespace="${OPERATOR_NAMESPACE:-default}"
    local sa_name="${OPERATOR_SERVICE_ACCOUNT:-opendesk-dev-agent}"
    
    # Try to check the service account's permissions
    if ${kubectl_cmd} -n "${namespace}" auth can-i get pods --as=system:serviceaccount:${namespace}:${sa_name} >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# Check system health (disk, memory)
check_system_health() {
    local threshold=90
    
    # Disk usage
    local usage
    usage=$(df -k / 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
    if [[ -n "${usage}" && ${usage} -ge ${threshold} ]]; then
        log_warn "Disk usage is ${usage}% (threshold: ${threshold}%)"
        return 1
    fi
    
    # Memory usage
    if [[ -f /proc/meminfo ]]; then
        local total_mem available_mem
        total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        available_mem=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        
        if [[ -n "${total_mem}" && -n "${available_mem}" && ${total_mem} -gt 0 ]]; then
            local used_percent=$(((total_mem - available_mem) * 100 / total_mem))
            if [[ ${used_percent} -ge ${threshold} ]]; then
                log_warn "Memory usage is ${used_percent}%"
                return 1
            fi
        fi
    fi
    
    return 0
}

# Check operator metrics endpoint
check_operator_metrics() {
    local port="${OPERATOR_METRICS_PORT}"
    local path="${OPERATOR_METRICS_PATH}"
    local url="http://localhost:${port}${path}"
    
    # Use curl if available
    if command -v curl &>/dev/null; then
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time ${HTTP_TIMEOUT} --connect-timeout ${SOCKET_TIMEOUT} "${url}" 2>/dev/null || echo "000")
        
        if [[ "${http_code}" == "200" ]]; then
            return 0
        fi
    fi
    
    return 1
}

# Check operator metrics endpoint (no retry)
check_metrics_endpoint_no_retry() {
    check_operator_metrics
    return $?
}

# =============================================================================
# HTTP HEALTH SERVER
# =============================================================================

start_health_server() {
    log_info "Starting health server on ${HEALTH_HOST}:${HEALTH_PORT}..."
    
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
    
    # Try to start using Python first (best option)
    if command -v python3 &>/dev/null; then
        start_python_health_server python3
        return $?
    fi
    
    if command -v python &>/dev/null; then
        start_python_health_server python
        return $?
    fi
    
    # Fallback to simple HTTP server
    start_simple_health_server
    return $?
}

start_python_health_server() {
    local python_cmd="$1"
    local handler_script="${SCRIPT_DIR}/health_server_dev_agent.py"
    
    # Create Python health server script
    cat > "${handler_script}" << 'PYEOF'
#!/usr/bin/env python3
import socket
import os
import sys
import time
import subprocess
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn

HOST = '0.0.0.0'
PORT = int(os.environ.get('HEALTH_PORT', '8081'))

# Cache for performance
CACHE_TIMEOUT = 10
probe_cache = {}

class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    allow_reuse_address = True
    daemon_threads = True

class HealthHandler(BaseHTTPRequestHandler):
    
    def log_message(self, format, *args):
        # Suppress default logging to avoid cluttering stdout
        sys.stderr.write("%s - - [%s] %s\n" % (self.address_string(), 
                                              self.log_date_time_string(),
                                              format % args))
    
    def do_GET(self):
        try:
            self.process_get()
        except Exception as e:
            self.send_error(500, str(e))
    
    def process_get(self):
        status, content_type, body = self.process_path(self.path)
        
        # Send response
        self.send_response(status)
        self.send_header('Content-Type', content_type)
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body.encode('utf-8'))
    
    def process_path(self, path):
        now = time.time()
        
        # Normalize path
        path = path.rstrip('/')
        
        # Health endpoints
        if path in ['', '/', '/healthz', '/health']:
            result = self.run_probe('liveness')
            body = 'OK' if result == 0 else 'FAIL'
            status = 200 if result == 0 else 503
            return status, 'text/plain', body
        
        elif path in ['/ready', '/readiness']:
            result = self.run_probe('readiness')
            body = 'OK' if result == 0 else 'NOT READY'
            status = 200 if result == 0 else 503
            return status, 'text/plain', body
        
        elif path in ['/live', '/liveness']:
            result = self.run_probe('liveness')
            body = 'OK' if result == 0 else 'NOT ALIVE'
            status = 200 if result == 0 else 503
            return status, 'text/plain', body
        
        elif path in ['/startup', '/start']:
            result = self.run_probe('startup')
            if result == 0:
                body = 'STARTED'
                status = 200
            elif result == 2:
                body = 'STARTING'
                status = 102
            else:
                body = 'FAILED'
                status = 503
            return status, 'text/plain', body
        
        elif path == '/deep':
            result = self.run_probe('deep')
            body = 'OK' if result == 0 else 'UNHEALTHY'
            status = 200 if result == 0 else 503
            return status, 'text/plain', body
        
        elif path == '/k8s':
            result = self.run_probe('k8s')
            body = 'OK' if result == 0 else 'FAIL'
            status = 200 if result == 0 else 503
            return status, 'text/plain', body
        
        elif path == '/status':
            body = self.get_status_json()
            return 200, 'application/json', body
        
        elif path == '/version':
            body = json.dumps({
                'operator': 'Dev Agent Operator',
                'version': os.environ.get('OPERATOR_VERSION', '1.2.0'),
                'healthScript': '3.0.0'
            })
            return 200, 'application/json', body
        
        elif path == '/metrics':
            # Proxy to operator metrics
            result = self.fetch_from_operator(8080, '/metrics')
            if result:
                return 200, 'text/plain', result
            else:
                return 503, 'text/plain', 'Metrics unavailable'
        
        else:
            return 404, 'text/plain', '404 - Not Found'
    
    def run_probe(self, probe_type):
        health_script = '/healthcheck.sh'
        try:
            result = subprocess.run(
                [health_script, probe_type],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=15
            )
            return result.returncode
        except Exception:
            return 1
    
    def get_status_json(self):
        liveness = 'OK' if self.run_probe('liveness') == 0 else 'FAIL'
        readiness = 'OK' if self.run_probe('readiness') == 0 else 'FAIL'
        startup = 'OK' if self.run_probe('startup') == 0 else 'FAIL'
        
        return json.dumps({
            'status': {
                'liveness': liveness,
                'readiness': readiness,
                'startup': startup,
                'timestamp': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
            },
            'operator': {
                'name': os.environ.get('OPERATOR_NAME', 'opendesk-dev-agent'),
                'namespace': os.environ.get('OPERATOR_NAMESPACE', 'default')
            }
        })
    
    def fetch_from_operator(self, port, path):
        import urllib.request
        import urllib.error
        try:
            url = f'http://localhost:{port}{path}'
            req = urllib.request.Request(url)
            with urllib.request.urlopen(req, timeout=5) as response:
                return response.read().decode('utf-8')
        except Exception:
            return None

if __name__ == '__main__':
    server = ThreadedHTTPServer((HOST, PORT), HealthHandler)
    print(f"Dev Agent Health Server started on {HOST}:{PORT}")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("Health server shutting down")
        server.shutdown()
        sys.exit(0)
PYEOF
    
    # Start Python server
    nohup "${python_cmd}" "${handler_script}" > /var/log/health_server.log 2>&1 &
    HEALTH_SERVER_PID=$!
    echo "${HEALTH_SERVER_PID}" > "${HEALTH_PID_FILE}"
    
    # Wait for server to start
    local count=0
    while [[ ${count} -lt 10 ]]; do
        if kill -0 "${HEALTH_SERVER_PID}" 2>/dev/null; then
            if check_tcp_port_no_retry ${HEALTH_PORT}; then
                log_success "Python health server started on port ${HEALTH_PORT}"
                return 0
            fi
        else
            log_error "Python health server failed to start"
            return 1
        fi
        sleep 1
        count=$((count + 1))
    done
    
    log_error "Python health server timeout"
    return 1
}

start_simple_health_server() {
    # Use socat if available
    if command -v socat &>/dev/null; then
        local FIFO="/tmp/health_fifo.$$"
        rm -f "${FIFO}"
        mkfifo "${FIFO}" || return 1
        chmod 600 "${FIFO}"
        
        # Create handler script
        local handler_script="${SCRIPT_DIR}/simple_health_handler.sh"
        cat > "${handler_script}" << 'SOCAT_HANDLER'
#!/bin/bash
FIFO="${FIFO}"

handle_request() {
    local method path protocol
    read -r method path protocol
    
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
        *)
            echo "HTTP/1.1 404 Not Found"
            echo "Content-Type: text/plain"
            echo "Connection: close"
            echo ""
            echo "404 - Not Found"
            ;;
    esac
    exit 0
}

# Main loop
while true; do
    if read -r request < "${FIFO}"; then
        handle_request <<< "${request}" 2>/dev/null || true
    fi
done
SOCAT_HANDLER
        
        chmod +x "${handler_script}"
        nohup "${handler_script}" > /dev/null 2>&1 &
        
        nohup socat TCP-LISTEN:${HEALTH_PORT},reuseaddr,fork UNIX-CONNECT:"${FIFO}" > /dev/null 2>&1 &
        HEALTH_SERVER_PID=$!
        echo "${HEALTH_SERVER_PID}" > "${HEALTH_PID_FILE}"
        
        log_success "Simple health server started on port ${HEALTH_PORT}"
        return 0
    else
        log_error "socat not available for health server"
        return 1
    fi
}

# =============================================================================
# MONITOR MODE
# =============================================================================

run_monitor_mode() {
    log_info "Starting health monitor mode..."
    
    # Start health server
    start_health_server || log_warn "Health server failed to start"
    
    local consecutive_failures=0
    local max_consecutive_failures=10
    
    while true; do
        log_debug "Monitor: Running health checks..."
        
        if ! liveness_probe; then
            log_error "Monitor: Liveness check failed"
            consecutive_failures=$((consecutive_failures + 1))
        else
            consecutive_failures=0
        fi
        
        # Every 3rd iteration, run readiness check
        local iteration=$(( (RANDOM % 3) + 1 ))
        if [[ ${iteration} -eq 1 ]]; then
            if ! readiness_probe; then
                log_warn "Monitor: Readiness check failed"
            fi
        fi
        
        if [[ ${consecutive_failures} -ge ${max_consecutive_failures} ]]; then
            log_error "Monitor: Too many consecutive failures (${consecutive_failures}/${max_consecutive_failures})"
            cleanup 1 "Consecutive failures exceeded"
        fi
        
        sleep 10
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
        k8s|kubernetes)
            probe "k8s"
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
    echo "  readiness    Run readiness probe (checks K8s API and CRDs)"
    echo "  startup      Run startup probe"
    echo "  deep         Run deep health check"
    echo "  k8s          Run Kubernetes connectivity check"
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
    echo "  4 - Kubernetes connection failed"
    echo ""
    echo "Kubernetes Annotations Example:"
    echo "  livenessProbe:"
    echo "    exec:"
    echo "      command: [/healthcheck.sh, liveness]"
    echo "    initialDelaySeconds: 30"
    echo "    periodSeconds: 10"
    echo "    failureThreshold: 3"
    echo ""
    echo "  readinessProbe:"
    echo "    exec:"
    echo "      command: [/healthcheck.sh, readiness]"
    echo "    initialDelaySeconds: 45"
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
    echo "Dev Agent Operator Health Check Script v3.0.0"
    echo "Operator Version: ${OPERATOR_VERSION:-1.2.0}"
    echo "Built: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    
    if [[ -x "${OPERATOR_BIN}" ]]; then
        if "${OPERATOR_BIN}" --version >/dev/null 2>&1; then
            echo "Operator Binary: արդյունք ($("${OPERATOR_BIN}" --version 2>&1 | head -1))"
        fi
    fi
}

# =============================================================================
# EXECUTE
# =============================================================================
main "$@"

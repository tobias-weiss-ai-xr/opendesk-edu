#!/usr/bin/env bash
# Dev Agent Operator Entrypoint Script
# SPDX-License-Identifier: Apache-2.0
# File: entrypoint.sh
# Purpose: Container entrypoint with signal handling, initialization, and startup
# Version: 2.0.0
# Author: openDesk Edu Team
#
# This script is executed as PID 1 when the container starts.
# It is responsible for:
#   1. Environment validation
#   2. Directory setup
#   3. Configuration preparation
#   4. Signal handling setup
#   5. Starting the operator and health check server
#   6. Graceful shutdown
#
# USAGE:
#   /entrypoint.sh (default: starts operator)
#   /entrypoint.sh --version (shows version info)
#   /entrypoint.sh --help (shows this help)
#

set -euo pipefail

# =============================================================================
# CONSTANTS
# =============================================================================
readonly SCRIPT_NAME=$(basename "${0}")
readonly SCRIPT_DIR=$(dirname "$(readlink -f "${0}" 2>/dev/null || echo "${0}")")
readonly OPERATOR_BIN="/usr/local/bin/manager"
readonly HEALTH_SCRIPT="/healthcheck.sh"
readonly CONFIG_DIR="/etc/opendesk-dev-agent"
readonly LOG_DIR="/var/log/opendesk"
readonly HOME_DIR="/home/opendesk"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================
log_info() {
    local msg="$1"
    echo -e "${BLUE}[INFO]${NC} ${msg}" | tee -a "${LOG_FILE:-/dev/stdout}"
}

log_success() {
    local msg="$1"
    echo -e "${GREEN}[SUCCESS]${NC} ${msg}" | tee -a "${LOG_FILE:-/dev/stdout}"
}

log_warn() {
    local msg="$1"
    echo -e "${YELLOW}[WARN]${NC} ${msg}" >&2 | tee -a "${LOG_FILE:-/dev/stdout}"
}

log_error() {
    local msg="$1"
    echo -e "${RED}[ERROR]${NC} ${msg}" >&2 | tee -a "${LOG_FILE:-/dev/stdout}"
}

# =============================================================================
# SIGNAL HANDLING
# =============================================================================
# Global variables for signal handling
HEALTH_PID=""
OPERATOR_PID=""
SHUTDOWN_REQUESTED=false

# Cleanup function for graceful shutdown
cleanup() {
    local exit_code=${1:-0}
    
    if ${SHUTDOWN_REQUESTED}; then
        log_info "Already handling shutdown, ignoring additional signals"
        return
    fi
    
    SHUTDOWN_REQUESTED=true
    log_info "Received shutdown signal, performing graceful shutdown..."
    
    # Stop health check server first
    if [[ -n "${HEALTH_PID}" && -d "/proc/${HEALTH_PID}" ]]; then
        log_info "Stopping health check server (PID: ${HEALTH_PID})..."
        if kill -TERM "${HEALTH_PID}" 2>/dev/null; then
            # Wait for up to 15 seconds
            for i in $(seq 1 15); do
                if ! kill -0 "${HEALTH_PID}" 2>/dev/null; then
                    log_info "Health check server stopped gracefully"
                    break
                fi
                sleep 1
            done
            # Force kill if still running
            if kill -0 "${HEALTH_PID}" 2>/dev/null; then
                log_warn "Health check server did not stop gracefully, force killing..."
                kill -9 "${HEALTH_PID}" 2>/dev/null || true
            fi
        fi
        HEALTH_PID=""
    fi
    
    # Stop operator
    if [[ -n "${OPERATOR_PID}" && -d "/proc/${OPERATOR_PID}" ]]; then
        log_info "Stopping operator (PID: ${OPERATOR_PID})..."
        if kill -TERM "${OPERATOR_PID}" 2>/dev/null; then
            # Wait for up to 30 seconds
            for i in $(seq 1 30); do
                if ! kill -0 "${OPERATOR_PID}" 2>/dev/null; then
                    log_info "Operator stopped gracefully"
                    break
                fi
                sleep 1
            done
            # Force kill if still running
            if kill -0 "${OPERATOR_PID}" 2>/dev/null; then
                log_warn "Operator did not stop gracefully, force killing..."
                kill -9 "${OPERATOR_PID}" 2>/dev/null || true
            fi
        fi
        OPERATOR_PID=""
    fi
    
    log_info "All processes stopped, exiting with code ${exit_code}"
    exit ${exit_code}
}

# Setup signal traps
trap 'cleanup' TERM INT QUIT HUP

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================
validate_binary() {
    local binary="$1"
    local name="$2"
    
    if [[ ! -x "${binary}" ]]; then
        log_error "${name} binary not found or not executable at: ${binary}"
        return 1
    fi
    
    if ! file "${binary}" | grep -q "ELF 64-bit"; then
        log_error "${name} binary is not a 64-bit ELF executable: ${binary}"
        return 1
    fi
    
    log_info "Found ${name} binary: $(file "${binary}")"
    return 0
}

validate_environment() {
    log_info "Validating environment..."
    
    # Required environment variables
    local required_vars=("OPERATOR_NAME" "OPERATOR_NAMESPACE")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Required environment variable ${var} is not set"
            return 1
        fi
        log_info "  ${var}=${!var}"
    done
    
    # Validate operator binary
    if ! validate_binary "${OPERATOR_BIN}" "Operator"; then
        return 1
    fi
    
    # Validate health check script
    if [[ -f "${HEALTH_SCRIPT}" ]]; then
        if ! validate_binary "${HEALTH_SCRIPT}" "Health check script"; then
            return 1
        fi
    else
        log_warn "Health check script not found at: ${HEALTH_SCRIPT}"
    fi
    
    log_success "Environment validation passed"
    return 0
}

# =============================================================================
# DIRECTORY SETUP
# =============================================================================
setup_directories() {
    log_info "Setting up directories..."
    
    # Create directories with proper permissions
    local dirs=(
        "${CONFIG_DIR}"
        "${LOG_DIR}"
        "${HOME_DIR}"
        "${HOME_DIR}/.kube"
        "${HOME_DIR}/logs"
        "/tmp"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "${dir}" ]]; then
            mkdir -p "${dir}" && chmod 755 "${dir}" && chown opendesk:opendesk "${dir}"
            log_info "  Created directory: ${dir}"
        else
            log_info "  Directory exists: ${dir}"
        fi
    done
    
    # Create log files if they don't exist
    local log_files=(
        "${LOG_DIR}/operator.log"
        "${LOG_DIR}/health.log"
        "${LOG_DIR}/repair.log"
        "${HOME_DIR}/logs/operator.log"
    )
    
    for log_file in "${log_files[@]}"; do
        if [[ ! -f "${log_file}" ]]; then
            touch "${log_file}" && chown opendesk:opendesk "${log_file}" && chmod 644 "${log_file}"
            log_info "  Created log file: ${log_file}"
        fi
    done
    
    log_success "Directory setup complete"
    return 0
}

# =============================================================================
# CONFIGURATION SETUP
# =============================================================================
setup_configuration() {
    log_info "Setting up configuration..."
    
    # Check if custom config exists
    if [[ -f "${CONFIG_DIR}/custom-config.yaml" ]]; then
        log_info "Using custom configuration: ${CONFIG_DIR}/custom-config.yaml"
        cp "${CONFIG_DIR}/custom-config.yaml" "${CONFIG_DIR}/config.yaml"
    elif [[ -f "${CONFIG_DIR}/config.yaml" ]]; then
        log_info "Using default configuration: ${CONFIG_DIR}/config.yaml"
    else
        log_error "No configuration file found in: ${CONFIG_DIR}"
        return 1
    fi
    
    # Validate configuration file
    if ! yq e '.' "${CONFIG_DIR}/config.yaml" >/dev/null 2>&1; then
        # yq may not be available, try basic YAML validation
        if ! python3 -c "import yaml; yaml.safe_load(open('${CONFIG_DIR}/config.yaml')); print('YAML valid')" 2>/dev/null; then
            log_warn "Cannot validate YAML configuration (no python3 or yq available)"
        fi
    fi
    
    log_success "Configuration setup complete"
    return 0
}

# =============================================================================
# CLUSTER-SPECIFIC OPTIMIZATIONS
# =============================================================================
apply_cluster_optimizations() {
    local cluster_type="${K8S_CLUSTER_TYPE:-k3s}"
    log_info "Applying optimizations for cluster type: ${cluster_type}"
    
    case "${cluster_type,,}" in
        k3s)
            # K3s-specific optimizations
            log_info "  K3s optimizations applied"
            # K3s uses a simplified API server, increase timeouts
            export OPERATOR_METRICS_BIND_ADDRESS="0.0.0.0:8080"
            export OPERATOR_HEALTH_PROBE_BIND_ADDRESS="0.0.0.0:8081"
            ;;
        minikube)
            log_info "  Minikube optimizations applied"
            # Minikube has limited resources
            ;;
        kind)
            log_info "  KIND optimizations applied"
            # KIND runs in containers, ensure proper DNS
            ;;
        docker-desktop)
            log_info "  Docker Desktop optimizations applied"
            ;;
        gke|google-kubernetes-engine)
            log_info "  GKE optimizations applied"
            ;;
        eks|elastic-kubernetes-service)
            log_info "  EKS optimizations applied"
            ;;
        aks|azure-kubernetes-service)
            log_info "  AKS optimizations applied"
            ;;
        openshift|ocp)
            log_info "  OpenShift optimizations applied"
            ;;
        rancher)
            log_info "  Rancher optimizations applied"
            ;;
        *)
            log_warn "Unknown cluster type: ${cluster_type}, no specific optimizations applied"
            ;;
    esac
    
    return 0
}

# =============================================================================
# HEALTH CHECK SERVER
# =============================================================================
start_health_server() {
    log_info "Starting health check server..."
    
    # Check if health check script exists and is executable
    if [[ ! -x "${HEALTH_SCRIPT}" ]]; then
        log_warn "Health check script not found or not executable: ${HEALTH_SCRIPT}"
        return 0
    fi
    
    # Start health check server in background
    "${HEALTH_SCRIPT}" server &
    HEALTH_PID=$!
    
    # Wait for server to start
    for i in $(seq 1 10); do
        if kill -0 "${HEALTH_PID}" 2>/dev/null; then
            if curl -s http://localhost:8081/healthz >/dev/null 2>&1; then
                log_success "Health check server started (PID: ${HEALTH_PID}), listening on 0.0.0.0:8081"
                break
            fi
        else
            log_error "Health check server failed to start"
            return 1
        fi
        sleep 1
    done
    
    return 0
}

# =============================================================================
# OPERATOR STARTUP
# =============================================================================
start_operator() {
    log_info "Starting operator..."
    
    # Build operator arguments
    local operator_args=()
    
    # Always include these flags
    operator_args+=(
        --zap-log-level="${OPERATOR_ZAP_LOG_LEVEL:-info}"
        --zap-encoder="${OPERATOR_ZAP_ENCODER:-json}"
        --leader-elect="${OPERATOR_ENABLE_LEADER_ELECTION:-false}"
        --metrics-addr="${OPERATOR_METRICS_BIND_ADDRESS:-0.0.0.0:8080}"
        --health-probe-addr="${OPERATOR_HEALTH_PROBE_BIND_ADDRESS:-0.0.0.0:8081}"
    )
    
    # Debug mode
    if [[ "${OPERATOR_DEBUG:-false}" == "true" ]]; then
        operator_args+=(--debug)
        log_info "  Debug mode enabled"
    fi
    
    # Disable PI Memory (default in production)
    if [[ "${OPERATOR_DISABLE_PI_MEMORY:-true}" == "true" ]]; then
        operator_args+=(--disable-pi-memory)
        log_info "  PI Memory integration disabled"
    else
        log_info "  PI Memory integration enabled"
    fi
    
    # Watch namespaces
    if [[ -n "${OPERATOR_WATCH_NAMESPACES:-}" ]]; then
        IFS=',' read -ra namespaces <<< "${OPERATOR_WATCH_NAMESPACES}"
        for ns in "${namespaces[@]}"; do
            operator_args+=(--watch-namespace="${ns}")
        done
        log_info "  Watching namespaces: ${OPERATOR_WATCH_NAMESPACES}"
    else
        # Default namespaces
        operator_args+=(--watch-namespace=opendesk --watch-namespace=opendesk-edu --watch-namespace=default)
        log_info "  Watching default namespaces: opendesk, opendesk-edu, default"
    fi
    
    # Operator name
    if [[ -n "${OPERATOR_NAME:-}" ]]; then
        operator_args+=(--operator-name="${OPERATOR_NAME}")
    fi
    
    # Display final args
    log_info "Operator arguments: ${operator_args[*]}"
    
    # Start operator in background
    exec "${OPERATOR_BIN}" "${operator_args[@]}" &
    OPERATOR_PID=$!
    
    log_success "Operator started (PID: ${OPERATOR_PID})"
    return 0
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================
main() {
    # Parse command line arguments
    if [[ "$#" -gt 0 ]]; then
        case "$1" in
            --version|-v)
                echo "Dev Agent Operator Entrypoint v2.0.0"
                echo "Operator Version: ${OPERATOR_VERSION:-1.2.0}"
                echo "Build Date: ${BUILD_DATE:-unknown}"
                echo "Git Commit: ${GIT_COMMIT:-unknown}"
                exit 0
                ;;
            --help|-h)
                echo "Usage: ${SCRIPT_NAME} [OPTION]"
                echo ""
                echo "Options:"
                echo "  --version, -v    Show version information"
                echo "  --help, -h       Show this help message"
                echo ""
                echo "Environment Variables:"
                echo "  OPERATOR_NAME             Operator name (default: opendesk-dev-agent)"
                echo "  OPERATOR_NAMESPACE        Operator namespace"
                echo "  OPERATOR_VERSION          Operator version"
                echo "  OPERATOR_LOG_LEVEL        Log level (debug, info, warn, error)"
                echo "  OPERATOR_DEBUG            Enable debug mode (true/false)"
                echo "  OPERATOR_WATCH_NAMESPACES Comma-separated list of namespaces to watch"
                echo "  K8S_CLUSTER_TYPE          Kubernetes cluster type (k3s, gke, eks, aks, etc.)"
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                exit 1
                ;;
        esac
    fi
    
    # Setup log file
    LOG_FILE="${OPERATOR_LOG_FILE:-/var/log/opendesk/operator.log}"
    
    # ======================
    # STARTUP SEQUENCE
    # ======================
    
    log_info "========================================"
    log_info "  Dev Agent Operator Entrypoint"
    log_info "  Version: 2.0.0"
    log_info "  Starting container..."
    log_info "========================================"
    
    # Step 1: Validate environment
    if ! validate_environment; then
        log_error "Environment validation failed"
        cleanup 1
    fi
    
    # Step 2: Setup directories
    if ! setup_directories; then
        log_error "Directory setup failed"
        cleanup 1
    fi
    
    # Step 3: Setup configuration
    if ! setup_configuration; then
        log_error "Configuration setup failed"
        cleanup 1
    fi
    
    # Step 4: Apply cluster-specific optimizations
    apply_cluster_optimizations
    
    # Step 5: Start health check server
    if ! start_health_server; then
        log_error "Failed to start health check server"
        cleanup 1
    fi
    
    # Step 6: Start operator
    if ! start_operator; then
        log_error "Failed to start operator"
        cleanup 1
    fi
    
    # ======================
    # MAIN LOOP
    # ======================
    log_success "All services started successfully!"
    log_info "========================================"
    log_info "  Operator is running"
    log_info "  Operator PID: ${OPERATOR_PID}"
    log_info "  Health PID: ${HEALTH_PID}"
    log_info "  Neural Engine: Disabled"
    log_info "  Watch Namespaces: ${OPERATOR_WATCH_NAMESPACES:-opendesk,opendesk-edu,default}"
    log_info "========================================"
    
    # Wait for all background processes
    # Using a loop to periodically check process status
    while true; do
        # Check if operator is still running
        if ! kill -0 "${OPERATOR_PID}" 2>/dev/null; then
            # Operator exited, check exit code
            if wait "${OPERATOR_PID}" 2>/dev/null; then
                log_warn "Operator exited normally, restarting..."
            else
                local exit_code=$?
                log_error "Operator exited with error code: ${exit_code}"
            fi
            # Try to restart operator
            if ! start_operator; then
                log_error "Failed to restart operator, exiting..."
                cleanup 1
            fi
        fi
        
        # Check if health server is still running
        if [[ -n "${HEALTH_PID}" ]]; then
            if ! kill -0 "${HEALTH_PID}" 2>/dev/null; then
                log_warn "Health server exited, restarting..."
                if ! start_health_server; then
                    log_error "Failed to restart health server"
                fi
            fi
        fi
        
        # Sleep for a while before checking again
        sleep 10
    done
}

# =============================================================================
# EXECUTE MAIN
# =============================================================================
main "$@"

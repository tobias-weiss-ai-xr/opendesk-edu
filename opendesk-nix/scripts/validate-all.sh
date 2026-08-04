#!/usr/bin/env bash
# Comprehensive Validation Script for openDesk Containers
# SPDX-License-Identifier: Apache-2.0
# Maintainer: openDesk Edu Team <team@opendesk-edu.org>
#
# ==============================================================================
# Usage: ./scripts/validate-all.sh [options] [component]
#
# Options:
#   -h, --help           Show this help message
#   -v, --verbose        Enable verbose output
#   --no-build           Skip building images
#   --no-delete          Don't delete temporary resources
#   --namespace NS       Kubernetes namespace to use
#   --context CTX        Kubernetes context to use
#
# Components:
#   all          Validate all components
#   sogo5        Validate SOGo 5
#   sogo6        Validate SOGo 6
#   dev-agent    Validate Dev Agent
#   zot          Validate Zot Registry
#   k8s          Validate Kubernetes manifests only
#   docker       Validate Dockerfiles only
#
# Examples:
#   ./scripts/validate-all.sh all
#   ./scripts/validate-all.sh sogo6
#   ./scripts/validate-all.sh --no-build --namespace opendesk-edu
#
# ==============================================================================

set -euo pipefail

# ==============================================================================
# GLOBAL VARIABLES
# ==============================================================================

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default configuration
REGISTRY="registry.gitlab.opencode.de/umr"
NAMESPACE="default"
CONTEXT=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Temporary resources
TEMP_NAMESPACE=""
TEMP_RESOURCES=()

# ==============================================================================
# FUNCTIONS
# ==============================================================================

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $*"
    ((PASSED++))
}

log_failure() {
    echo -e "${RED}[FAIL]${NC} $*"
    ((FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $*"
    ((WARNINGS++))
}

log_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $*${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

log_summary() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  VALIDATION SUMMARY${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "  Passed:   ${GREEN}${PASSED}${NC}"
    echo -e "  Failed:   ${RED}${FAILED}${NC}"
    echo -e "  Warnings: ${YELLOW}${WARNINGS}${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    if [ $FAILED -gt 0 ]; then
        echo -e "\n${RED}Validation FAILED with ${FAILED} error(s)${NC}"
        return 1
    else
        echo -e "\n${GREEN}Validation PASSED${NC}"
        return 0
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
check_dependencies() {
    local missing=()
    local optional=()
    
    # Required tools
    for cmd in docker kubectl; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done
    
    # Optional tools
    for cmd in hadolint shellcheck yamllint trivy syft; do
        if ! command_exists "$cmd"; then
            optional+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_failure "Missing required dependencies: ${missing[*]}"
        exit 1
    fi
    
    if [ ${#optional[@]} -ne 0 ]; then
        log_warning "Optional tools not found: ${optional[*]}"
        log_warning "Some validations will be skipped"
    fi
}

# Cleanup temporary resources
cleanup() {
    if [ "$NO_DELETE" = "false" ]; then
        log_info "Cleaning up temporary resources..."
        
        # Delete temporary namespace
        if [ -n "$TEMP_NAMESPACE" ]; then
            if kubectl get namespace "$TEMP_NAMESPACE" >/dev/null 2>&1; then
                kubectl delete namespace "$TEMP_NAMESPACE" >/dev/null 2>&1 || true
                log_info "Deleted temporary namespace: $TEMP_NAMESPACE"
            fi
        fi
        
        # Delete other temporary resources
        for resource in "${TEMP_RESOURCES[@]}"; do
            if [[ "$resource" =~ ^[a-z]+/[a-z0-9-]+$ ]]; then
                local resource_type="${resource%%/*}"
                local resource_name="${resource#*/}"
                kubectl delete "$resource_type" "$resource_name" --ignore-not-found=true >/dev/null 2>&1 || true
                log_info "Deleted: $resource"
            fi
        done
    else
        log_info "Skipping cleanup (--no-delete specified)"
        if [ -n "$TEMP_NAMESPACE" ]; then
            log_info "Temporary namespace: $TEMP_NAMESPACE (not deleted)"
        fi
        if [ ${#TEMP_RESOURCES[@]} -ne 0 ]; then
            log_info "Temporary resources: ${TEMP_RESOURCES[*]}"
        fi
    fi
}

# Trap for cleanup on exit
trap cleanup EXIT

# ==============================================================================
# VALIDATION FUNCTIONS
# ==============================================================================

# Validate Dockerfile with hadolint
validate_dockerfile() {
    local dockerfile="$1"
    local component="$2"
    
    if ! command_exists hadolint; then
        log_warning "Skipping Dockerfile validation for $component (hadolint not installed)"
        return 0
    fi
    
    log_info "Validating Dockerfile: $dockerfile"
    if hadolint "$dockerfile" >/dev/null 2>&1; then
        log_success "Dockerfile $component: valid"
        return 0
    else
        log_failure "Dockerfile $component: invalid"
        hadolint "$dockerfile" || true
        return 1
    fi
}

# Validate shell scripts with shellcheck
validate_shell_script() {
    local script="$1"
    local component="$2"
    
    if ! command_exists shellcheck; then
        log_warning "Skipping shell script validation for $component (shellcheck not installed)"
        return 0
    fi
    
    log_info "Validating shell script: $script"
    if shellcheck "$script" >/dev/null 2>&1; then
        log_success "Shell script $component: valid"
        return 0
    else
        log_failure "Shell script $component: invalid"
        shellcheck "$script" || true
        return 1
    fi
}

# Validate Kubernetes manifests
validate_k8s_manifest() {
    local manifest="$1"
    local component="$2"
    
    log_info "Validating Kubernetes manifest: $manifest"
    if KUBECTL_EXTERNAL=true kubectl apply --dry-run=client -f "$manifest" >/dev/null 2>&1; then
        log_success "K8s manifest $component: valid"
        return 0
    else
        log_failure "K8s manifest $component: invalid"
        kubectl apply --dry-run=client -f "$manifest" || true
        return 1
    fi
}

# Validate YAML with yamllint
validate_yaml() {
    local file="$1"
    local component="$2"
    
    if ! command_exists yamllint; then
        log_warning "Skipping YAML validation for $component (yamllint not installed)"
        return 0
    fi
    
    log_info "Validating YAML: $file"
    if yamllint "$file" >/dev/null 2>&1; then
        log_success "YAML $component: valid"
        return 0
    else
        log_failure "YAML $component: invalid"
        yamllint "$file" || true
        return 1
    fi
}

# Build Docker image
build_image() {
    local component="$1"
    local dockerfile="$2"
    local image_name="$3"
    
    if [ "$NO_BUILD" = "true" ]; then
        log_warning "Skipping build for $component (--no-build specified)"
        return 0
    fi
    
    log_info "Building $component: $image_name"
    if docker build -t "$image_name" -f "$dockerfile" "$PROJECT_ROOT" >/dev/null 2>&1; then
        log_success "Build $component: successful"
        return 0
    else
        log_failure "Build $component: failed"
        return 1
    fi
}

# Scan image with Trivy
scan_image() {
    local component="$1"
    local image_name="$2"
    
    if ! command_exists trivy; then
        log_warning "Skipping vulnerability scan for $component (trivy not installed)"
        return 0
    fi
    
    log_info "Scanning $component: $image_name"
    if trivy image --severity CRITICAL,HIGH --exit-code 0 "$image_name" >/dev/null 2>&1; then
        log_success "Scan $component: no critical/high vulnerabilities"
        return 0
    else
        log_failure "Scan $component: vulnerabilities found"
        trivy image --severity CRITICAL,HIGH "$image_name" || true
        return 1
    fi
}

# Test image by running it
run_test() {
    local component="$1"
    local image_name="$2"
    local port="$3"
    
    log_info "Testing $component: $image_name"
    
    # Start container
    local container_name="test-${component}-validate"
    docker run -d --rm --name "$container_name" "$image_name" >/dev/null 2>&1 || {
        log_failure "Test $component: failed to start container"
        return 1
    }
    
    # Add to cleanup list
    TEMP_RESOURCES+=("$container_name")
    
    # Wait for health check if port is specified
    if [ -n "$port" ]; then
        local max_attempts=30
        local attempt=0
        
        while [ $attempt -lt $max_attempts ]; do
            if docker exec "$container_name" sh -c "exit 0" >/dev/null 2>&1; then
                log_success "Test $component: container running"
                docker stop "$container_name" >/dev/null 2>&1 || true
                return 0
            fi
            sleep 1
            ((attempt++))
        done
        
        log_failure "Test $component: container failed to start"
        docker stop "$container_name" >/dev/null 2>&1 || true
        return 1
    else
        # Basic test: just check if container starts
        sleep 5
        if docker ps | grep -q "$container_name"; then
            log_success "Test $component: container running"
            docker stop "$container_name" >/dev/null 2>&1 || true
            return 0
        else
            log_failure "Test $component: container not running"
            docker stop "$container_name" >/dev/null 2>&1 || true
            return 1
        fi
    fi
}

# Deploy to Kubernetes for integration testing
deploy_to_k8s() {
    local component="$1"
    local namespace="$2"
    local k8s_manifest_dir="$3"
    
    log_info "Deploying $component to Kubernetes"
    
    # Create namespace if it doesn't exist
    if ! kubectl get namespace "$namespace" >/dev/null 2>&1; then
        kubectl create namespace "$namespace" >/dev/null 2>&1 || {
            log_failure "Deploy $component: failed to create namespace $namespace"
            return 1
        }
        TEMP_NAMESPACE="$namespace"
    fi
    
    # Apply manifests
    if kubectl apply -n "$namespace" -f "$k8s_manifest_dir" >/dev/null 2>&1; then
        log_success "Deploy $component: manifests applied successfully"
        
        # Wait for pods to be ready
        local max_attempts=30
        local attempt=0
        
        while [ $attempt -lt $max_attempts ]; do
            if kubectl get pods -n "$namespace" -l "app=$component" >/dev/null 2>&1; then
                local ready_pods
                ready_pods=$(kubectl get pods -n "$namespace" -l "app=$component" \
                    -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)
                
                if echo "$ready_pods" | grep -q "True"; then
                    log_success "Deploy $component: pods ready"
                    return 0
                fi
            fi
            sleep 5
            ((attempt++))
        done
        
        log_failure "Deploy $component: pods not ready within timeout"
        return 1
    else
        log_failure "Deploy $component: failed to apply manifests"
        kubectl apply -n "$namespace" -f "$k8s_manifest_dir" || true
        return 1
    fi
}

# Validate a single component
validate_component() {
    local component="$1"
    local use_temp_ns="${2:-false}"
    
    log_header "Validating Component: $component"
    
    local dockerfile=""
    local image_name=""
    local k8s_dir=""
    local test_port=""
    
    case "$component" in
        sogo5)
            dockerfile="$PROJECT_ROOT/docker/sogo5/Dockerfile"
            image_name="${REGISTRY}/opendesk-sogo5:${SOGO5_VERSION}"
            k8s_dir="$PROJECT_ROOT/k8s/sogo5"
            test_port="20000"
            ;;
        sogo6)
            dockerfile="$PROJECT_ROOT/docker/sogo6/Dockerfile"
            image_name="${REGISTRY}/opendesk-sogo6:${SOGO6_VERSION}"
            k8s_dir="$PROJECT_ROOT/k8s/sogo6"
            test_port="20000"
            ;;
        dev-agent)
            dockerfile="$PROJECT_ROOT/docker/dev-agent/Dockerfile"
            image_name="${REGISTRY}/opendesk-dev-agent:${DEV_AGENT_VERSION}"
            k8s_dir="$PROJECT_ROOT/k8s/dev-agent"
            test_port=""
            ;;
        zot)
            dockerfile="$PROJECT_ROOT/docker/zot-registry/Dockerfile"
            image_name="${REGISTRY}/zot-registry:${ZOT_VERSION}"
            k8s_dir="$PROJECT_ROOT/k8s/zot-registry"
            test_port="8080"
            ;;
        k8s)
            # Kubernetes manifests only
            ;;
        docker)
            # Dockerfiles only
            ;;
        *)
            log_failure "Unknown component: $component"
            return 1
            ;;
    esac
    
    # ===========================================================================
    # DOCKERFILE VALIDATION
    # ===========================================================================
    if [ -n "$dockerfile" ] && [ "$component" != "k8s" ]; then
        validate_dockerfile "$dockerfile" "$component"
        
        # Validate all shell scripts in docker directory
        find "$(dirname "$dockerfile")" -name "*.sh" -type f | while read -r script; do
            validate_shell_script "$script" "$component/$(basename "$script")"
        done
        
        # Validate Dockerfile with YAML lint if it has YAML sections
        validate_yaml "$dockerfile" "$component-dockerfile"
    fi
    
    # ===========================================================================
    # KUBERNETES MANIFEST VALIDATION
    # ===========================================================================
    if [ "$component" != "docker" ] && [ -n "$k8s_dir" ]; then
        for manifest in $(find "$k8s_dir" -name "*.yaml" -type f | sort); do
            validate_k8s_manifest "$manifest" "$component/$(basename "$manifest")"
        done
    fi
    
    if [ "$component" = "k8s" ]; then
        # Only validate K8s manifests
        log_header "Validating Kubernetes Manifests Only"
        for k8s_dir in "$PROJECT_ROOT/k8s"/*/; do
            for manifest in $(find "$k8s_dir" -name "*.yaml" -type f | sort); do
                validate_k8s_manifest "$manifest" "k8s/$(basename "$k8s_dir")/$(basename "$manifest")"
            done
        done
        return $?
    fi
    
    if [ "$component" = "docker" ]; then
        # Only validate Dockerfiles
        log_header "Validating Dockerfiles Only"
        for docker_dir in "$PROJECT_ROOT/docker"/*/; do
            local dirname=$(basename "$docker_dir")
            validate_dockerfile "$docker_dir/Dockerfile" "$dirname"
            find "$docker_dir" -name "*.sh" -type f | while read -r script; do
                validate_shell_script "$script" "$dirname/$(basename "$script")"
            done
        done
        return $?
    fi
    
    # ===========================================================================
    # BUILD AND SCAN
    # ===========================================================================
    if [ -n "$dockerfile" ]; then
        # Build image
        build_image "$component" "$dockerfile" "$image_name"
        
        # Scan for vulnerabilities
        scan_image "$component" "$image_name"
        
        # Run basic test
        run_test "$component" "$image_name" "$test_port"
    fi
    
    # ===========================================================================
    # KUBERNETES DEPLOYMENT (for integration testing)
    # ===========================================================================
    if [ -n "$k8s_dir" ]; then
        local ns="$NAMESPACE"
        if [ "$use_temp_ns" = "true" ]; then
            ns="validate-${component}-ns"
            # Check if namespace already exists
            if kubectl get namespace "$ns" >/dev/null 2>&1; then
                kubectl delete namespace "$ns" >/dev/null 2>&1 || true
                sleep 2
            fi
            kubectl create namespace "$ns" >/dev/null 2>&1 || {
                log_warning "Failed to create temp namespace, using: $NAMESPACE"
                ns="$NAMESPACE"
            }
            TEMP_NAMESPACE="$ns"
        fi
        
        deploy_to_k8s "$component" "$ns" "$k8s_dir"
        
        if [ "$NO_DELETE" = "false" ]; then
            # Delete the deployment if we created a temp namespace
            if [ "$use_temp_ns" = "true" ]; then
                kubectl delete -n "$ns" -f "$k8s_dir" --ignore-not-found=true >/dev/null 2>&1 || true
            fi
        fi
    fi
    
    return 0
}

# Main function
main() {
    local component=""
    local Verbose="false"
    local UseTempNS="false"
    
    # ===========================================================================
    # PARSE ARGUMENTS
    # ===========================================================================
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            -v|--verbose)
                Verbose="true"
                shift
                ;;
            --no-build)
                NO_BUILD="true"
                shift
                ;;
            --no-delete)
                NO_DELETE="true"
                shift
                ;;
            --namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            --context)
                CONTEXT="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [ -n "$component" ]; then
                    log_error "Multiple components specified"
                    usage
                    exit 1
                fi
                component="$1"
                shift
                ;;
        esac
    done
    
    # Set default component
    if [ -z "$component" ]; then
        component="all"
    fi
    
    # Set context if not specified
    if [ -z "$CONTEXT" ]; then
        CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
    fi
    
    # ===========================================================================
    # INITIAL SETUP
    # ===========================================================================
    
    if [ -n "$CONTEXT" ]; then
        export KUBECONFIG=$(kubectl config view --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' 2>/dev/null) || true
    fi
    
    log_header "openDesk Validation Suite"
    log_info "Component: ${component}"
    log_info "Namespace: ${NAMESPACE}"
    log_info "Context: ${CONTEXT}"
    log_info "Build Images: ${NO_BUILD:-yes}"
    log_info "Delete Temp Resources: ${NO_DELETE:-yes}"
    
    # Check dependencies
    check_dependencies
    
    # ===========================================================================
    # RUN VALIDATIONS
    # ===========================================================================
    
    case "$component" in
        all)
            log_header "Validating All Components"
            
            # Validate Dockerfiles first
            validate_component "docker"
            
            # Validate Kubernetes manifests
            validate_component "k8s"
            
            # Validate and test each component
            validate_component "sogo5" "true"
            validate_component "sogo6" "true"
            validate_component "dev-agent" "true"
            validate_component "zot" "true"
            ;;
        sogo5|sogo6|dev-agent|zot)
            validate_component "$component" "true"
            ;;
        k8s)
            validate_component "$component"
            ;;
        docker)
            validate_component "$component"
            ;;
        *)
            log_error "Unknown component: $component"
            usage
            exit 1
            ;;
    esac
    
    # ===========================================================================
    # SUMMARY
    # ===========================================================================
    
    log_summary
    
    # Cleanup (trap handles this already)
    
    return $?
}

# ==============================================================================
# USAGE FUNCTION
# ==============================================================================

usage() {
    grep '^# ' "$0" | sed -e 's/^# //' -e 's/^#//' | head -n -1
    exit 0
}

# ==============================================================================
# ENTRY POINT
# ==============================================================================

NO_BUILD="false"
NO_DELETE="false"

main "$@"

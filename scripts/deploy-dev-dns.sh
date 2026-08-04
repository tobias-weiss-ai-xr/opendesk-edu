#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2024 OpenDesk Edu Team
# SPDX-License-Identifier: Apache-2.0
#
# deploy-dev-dns.sh - Deploy dev DNS configuration to k3s CoreDNS
#
# This script deploys the dev DNS chart which:
# 1. Adds static host entries to k3s CoreDNS for internal services
# 2. Exposes CoreDNS externally via NodePort for team machines
#
# Usage:
#   ./deploy-dev-dns.sh                    # Deploy with default values
#   ./deploy-dev-dns.sh --values myvals.yaml  # Deploy with custom values
#   ./deploy-dev-dns.sh --destroy          # Remove dev DNS configuration
#   ./deploy-dev-dns.sh --verify           # Test DNS resolution
#
# Requirements:
#   - kubectl configured with access to the cluster
#   - helm available (or helm template with kubectl)
#   - k3s cluster (uses k3s-specific coredns-custom ConfigMap)
#
# Idempotent: Safe to run multiple times. Will update existing resources.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="${SCRIPT_DIR}/../helmfile/charts/dev-dns"
NAMESPACE="kube-system"
COREDNS_SVC_CLUSTER_IP="172.17.128.10"  # default k3s CoreDNS cluster IP

# ---------------------------------------------------------------------------
# Color output helpers
# ---------------------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
step()  { echo -e "${CYAN}[STEP]${NC}  $*"; }

# ---------------------------------------------------------------------------
# Deploy the chart
# ---------------------------------------------------------------------------
deploy() {
    local values_arg=""
    if [[ -n "${CUSTOM_VALUES:-}" ]]; then
        values_arg="-f ${CUSTOM_VALUES}"
    fi

    step "Generating Kubernetes manifests from Helm chart..."
    helm template dev-dns "${CHART_DIR}" \
        --namespace "${NAMESPACE}" \
        ${values_arg} \
        --output-dir /tmp/dev-dns-manifests 2>/dev/null || \
    helm template dev-dns "${CHART_DIR}" \
        --namespace "${NAMESPACE}" \
        ${values_arg} \
        > /tmp/dev-dns-manifests.yaml

    step "Applying manifests to namespace '${NAMESPACE}'..."
    if [[ -d /tmp/dev-dns-manifests ]]; then
        kubectl apply -f /tmp/dev-dns-manifests --namespace "${NAMESPACE}"
    elif [[ -f /tmp/dev-dns-manifests.yaml ]]; then
        kubectl apply -f /tmp/dev-dns-manifests.yaml
    fi
    info "Done. Manifests applied."

    step "Waiting for CoreDNS to reload configuration..."
    # k3s CoreDNS reloads automatically when the coredns-custom ConfigMap changes
    # but we wait a few seconds to ensure the configuration is picked up
    sleep 5

    # Restart CoreDNS pods to pick up the new ConfigMap immediately
    info "Restarting CoreDNS pods..."
    kubectl -n "${NAMESPACE}" rollout restart deployment coredns 2>/dev/null || \
    kubectl -n "${NAMESPACE}" rollout restart deployment.apps/coredns 2>/dev/null || \
    warn "Could not restart CoreDNS deployment - may need manual restart"

    # Wait for CoreDNS to be ready
    info "Waiting for CoreDNS to be ready..."
    kubectl -n "${NAMESPACE}" rollout status deployment coredns --timeout=60s 2>/dev/null || \
    warn "Timeout waiting for CoreDNS rollout - check with 'kubectl -n kube-system get pods'"

    echo ""
    verify
}

# ---------------------------------------------------------------------------
# Verify DNS resolution
# ---------------------------------------------------------------------------
verify() {
    step "Verifying DNS resolution..."

    # Get a test pod
    local test_pod
    test_pod=$(kubectl -n "${NAMESPACE}" get pod -l app.kubernetes.io/name=dev-dns -o name 2>/dev/null | head -1)

    if [[ -z "${test_pod}" ]]; then
        warn "No dev-dns test pod found. Running inline verification..."

        # Test 1: Resolve dev hostname via CoreDNS cluster IP
        info "Test 1: Resolve r.opendesk.hrz.uni-marburg.de via CoreDNS..."
        if kubectl run dns-test-$$ --image=busybox:1.36 --restart=Never \
            --rm -it -- sh -c "nslookup r.opendesk.hrz.uni-marburg.de ${COREDNS_SVC_CLUSTER_IP} 2>&1" 2>/dev/null; then
            info "✅ Dev hostname resolution: PASS"
        else
            warn "⚠️  Dev hostname resolution: FAIL - check ConfigMap"
        fi

        # Test 2: Resolve upstream (google.com) - tests fallthrough
        info "Test 2: Resolve google.com via CoreDNS (fallthrough)..."
        if kubectl run dns-test-upstream-$$ --image=busybox:1.36 --restart=Never \
            --rm -it -- sh -c "nslookup google.com ${COREDNS_SVC_CLUSTER_IP} 2>&1" 2>/dev/null; then
            info "✅ Upstream resolution (fallthrough): PASS"
        else
            warn "⚠️  Upstream resolution: FAIL - check CoreDNS forward plugin"
        fi
    fi

    # Test 3: Check NodePort service
    info "Test 3: Check NodePort service..."
    if kubectl -n "${NAMESPACE}" get svc dev-dns-external &>/dev/null; then
        local node_port
        node_port=$(kubectl -n "${NAMESPACE}" get svc dev-dns-external -o jsonpath='{.spec.ports[?(@.name=="dns-udp")].nodePort}')
        info "✅ Dev DNS NodePort service available at UDP/${node_port}"
    else
        warn "⚠️  dev-dns-external service not found"
    fi

    echo ""
    info "Verification complete."
}

# ---------------------------------------------------------------------------
# Destroy / clean up
# ---------------------------------------------------------------------------
destroy() {
    step "Removing dev DNS configuration..."

    # Remove the coredns-custom ConfigMap entry
    if kubectl -n "${NAMESPACE}" get configmap coredns-custom &>/dev/null; then
        info "Removing coredns-custom ConfigMap..."
        kubectl -n "${NAMESPACE}" delete configmap coredns-custom --ignore-not-found
    else
        info "No coredns-custom ConfigMap found."
    fi

    # Remove the NodePort service
    if kubectl -n "${NAMESPACE}" get svc dev-dns-external &>/dev/null; then
        info "Removing dev-dns-external NodePort service..."
        kubectl -n "${NAMESPACE}" delete svc dev-dns-external --ignore-not-found
    else
        info "No dev-dns-external service found."
    fi

    # Restart CoreDNS to clear custom config
    info "Restarting CoreDNS to clear custom configuration..."
    kubectl -n "${NAMESPACE}" rollout restart deployment coredns 2>/dev/null || true
    kubectl -n "${NAMESPACE}" rollout status deployment coredns --timeout=60s 2>/dev/null || true

    info "Dev DNS configuration removed."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    local action="deploy"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --destroy|--remove|--cleanup)
                action="destroy"
                shift
                ;;
            --verify|--test)
                action="verify"
                shift
                ;;
            --values|-f)
                CUSTOM_VALUES="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [--values file.yaml] [--destroy] [--verify]"
                echo ""
                echo "  --values <file>   Custom values file for helm template"
                echo "  --destroy         Remove dev DNS configuration"
                echo "  --verify          Test DNS resolution"
                echo "  --help            Show this help"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    case "${action}" in
        deploy)
            deploy
            ;;
        destroy)
            destroy
            ;;
        verify)
            verify
            ;;
    esac
}

main "$@"

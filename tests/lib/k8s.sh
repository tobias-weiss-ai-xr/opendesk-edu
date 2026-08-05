# Kubernetes helper functions for test framework

KUBE_CONFIG="${KUBECONFIG:-$HOME/.kube/config}"
NAMESPACE="${NAMESPACE:-opendesk}"

# Check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "ERROR: kubectl not found"
        return 1
    fi
    return 0
}

# Check cluster connectivity
check_cluster() {
    kubectl --kubeconfig="$KUBE_CONFIG" cluster-info &> /dev/null
    return $?
}

# Get all pods in namespace
get_pods() {
    kubectl --kubeconfig="$KUBE_CONFIG" -n "$NAMESPACE" get pods -o json
}

# Check pod readiness
check_pod_ready() {
    local pod_name="$1"
    local output
    output=$(kubectl --kubeconfig="$KUBE_CONFIG" -n "$NAMESPACE" get pod "$pod_name" -o jsonpath='{.status.readyReplicas}/{.spec.replicas}{"\n"}{.status.phase}')
    echo "$output"
}

# Get all PVCs
get_pvcs() {
    kubectl --kubeconfig="$KUBE_CONFIG" -n "$NAMESPACE" get pvc -o json
}

# Get all ingresses
get_ingresses() {
    kubectl --kubeconfig="$KUBE_CONFIG" -n "$NAMESPACE" get ingress -o json
}

# Get k8up schedules
get_k8up_schedules() {
    kubectl --kubeconfig="$KUBE_CONFIG" -n "$NAMESPACE" get schedule.k8up.io -o json
}

# Get nodes
get_nodes() {
    kubectl --kubeconfig="$KUBE_CONFIG" get nodes -o json
}

# Get deployment by label
get_deployment_by_label() {
    local label="$1"
    kubectl --kubeconfig="$KUBE_CONFIG" -n "$NAMESPACE" get deployment -l "$label" -o json
}

# Get pod logs
get_pod_logs() {
    local pod_name="$1"
    local container="${2:-}"
    local tail="${3:-50}"
    
    if [ -z "$container" ]; then
        kubectl --kubeconfig="$KUBE_CONFIG" -n "$NAMESPACE" logs "$pod_name" --tail="$tail"
    else
        kubectl --kubeconfig="$KUBE_CONFIG" -n "$NAMESPACE" logs "$pod_name" -c "$container" --tail="$tail"
    fi
}

# Execute command in pod
exec_in_pod() {
    local pod_name="$1"
    shift
    kubectl --kubeconfig="$KUBE_CONFIG" -n "$NAMESPACE" exec "$pod_name" -- "$@"
}

# Get service endpoint
get_service_endpoint() {
    local service_name="$1"
    kubectl --kubeconfig="$KUBE_CONFIG" -n "$NAMESPACE" get svc "$service_name" -o jsonpath='{.spec.clusterIP}:{.spec.ports[0].port}{"\n"}'
}
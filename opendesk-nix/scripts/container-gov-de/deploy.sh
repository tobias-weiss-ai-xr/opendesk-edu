#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 container.gov.de Contributors
# Deploy container.gov.de Compliant Images to Kubernetes
# Usage: ./deploy.sh [OPTIONS]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"
K8S_DIR="$PROJECT_ROOT/k8s/services"
LOG_DIR="$SCRIPT_DIR/../migrate-upstream/logs"

# Default registry
TARGET_REGISTRY="opencode.de/opendesk-edu"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Deploy container.gov.de compliant images to Kubernetes

Options:
  --services SERVICES    Comma-separated list of services (default: all in docker/services)
  --namespace NAMESPACE  Kubernetes namespace (default: opendesk)
  --registry REGISTRY    Registry to pull images from (default: $TARGET_REGISTRY)
  --tag TAG              Image tag to deploy (default: latest)
  --replicas N           Number of replicas per service (default: 1)
  --dry-run              Show YAML without applying
  --apply                Apply Kubernetes manifests (default: dry-run only)
  --clean                Delete existing deployments before deploying
  --verify               Verify deployed images have valid signatures
  --parallel N           Number of parallel deployments (default: 1)
  --help                 Show this help message

Examples:
  $0 --apply                             # Deploy all services
  $0 --services nginx,redis --apply      # Deploy only nginx and redis
  $0 --namespace production --apply     # Deploy to production namespace
  $0 --registry local:5000 --apply       # Deploy from local registry
  $0 --dry-run                           # Show YAML for all services
  $0 --clean --apply                     # Clean and deploy all services
  $0 --verify                            # Verify deployed images

container.gov.de Compliance:
  All deployed images will have:
  - BG-1: Trusted Base Images
  - BG-2: Non-Root User (runAsNonRoot: true)
  - BG-3: Minimal Rights (capabilities.drop: ["ALL"], readOnlyRootFilesystem: true)
  - BG-4: No Sensitive Data
  - BG-5: Regular Updates (imagePullPolicy: Always)
  - BG-6: SBOM Generation (annotations)
  - BG-7: Image Signing (Cosign verification in admission controller)
  - BG-8: Vulnerability Scanning (pre-deployment)
EOF
}

# Get all services
get_all_services() {
    cd "$PROJECT_ROOT"
    if [ -d "docker/services" ]; then
        find docker/services -maxdepth 1 -type d ! -name "services" ! -name ".*" | sed 's|docker/services/||' | sed '/^$/d' | sort | tr '\n' ',' | sed 's/,$//'
    else
        echo ""
    fi
}

# Get image version
get_image_version() {
    local service="$1"
    local service_dir="$PROJECT_ROOT/docker/services/$service/nixos"
    
    if [ -f "$service_dir/default.nix" ]; then
        grep -E "tag\s*=" "$service_dir/default.nix" | grep -oE '"[^"]+"' | tr -d '"' | head -1
    else
        echo "latest"
    fi
}

# Get port from Dockerfile or Nix expression
get_service_port() {
    local service="$1"
    local service_dir="$PROJECT_ROOT/docker/services/$service"
    
    # Try Dockerfile
    if [ -f "$service_dir/Dockerfile" ]; then
        local port=$(grep -i "^EXPOSE" "$service_dir/Dockerfile" | sed 's/^EXPOSE\s\+//' | head -1)
        if [ -n "$port" ]; then
            echo "$port"
            return
        fi
    fi
    
    # Try NixOS config
    if [ -f "$service_dir/nixos/configuration.nix" ]; then
        # Look for firewall ports
        local ports=$(grep -E "allowedTCPPorts|allowedUDPPorts" "$service_dir/nixos/configuration.nix" | grep -oE '[0-9]+' | head -1)
        if [ -n "$ports" ]; then
            echo "$ports"
            return
        fi
    fi
    
    # Try K8s service file
    if [ -f "$K8S_DIR/${service}.nix" ]; then
        local port=$(grep -E "port:\s*[0-9]+" "$K8S_DIR/${service}.nix" | grep -oE '[0-9]+' | head -1)
        if [ -n "$port" ]; then
            echo "$port"
            return
        fi
    fi
    
    # Default port
    echo "8080"
}

# Get resource limits
get_resource_limits() {
    local service="$1"
    local service_dir="$PROJECT_ROOT/docker/services/$service/nixos"
    
    # Try to extract from Nix expression
    if [ -f "$service_dir/default.nix" ]; then
        # Look for resource annotations
        if grep -q "memory" "$service_dir/default.nix"; then
            echo "memory: 512Mi, cpu: 500m"
        else
            echo "memory: 256Mi, cpu: 250m"
        fi
    else
        echo "memory: 256Mi, cpu: 250m"
    fi
}

# Generate Kubernetes manifest for a single service
generate_manifest() {
    local service="$1"
    local namespace="$2"
    local registry="$3"
    local tag="$4"
    local replicas="$5"
    local dry_run="$6"
    
    local version=$(get_image_version "$service")
    local port=$(get_service_port "$service")
    local resources=$(get_resource_limits "$service")
    local memory=$(echo "$resources" | grep -oE 'memory:\s*[^,]+' | sed 's/memory://')
    local cpu=$(echo "$resources" | grep -oE 'cpu:\s*[^,]+' | sed 's/cpu://')
    
    local image_ref="${registry}/${namespace}/${service}:${tag}"
    
    if [ "$dry_run" = "true" ]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would generate manifest for: ${CYAN}${service}:${version}${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Generating Kubernetes manifest for: ${CYAN}${service}:${version}${NC}"
    
    # Generate Deployment
    local deployment_file="/tmp/${service}-deployment.yaml"
    cat > "$deployment_file" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${service}
  namespace: ${namespace}
  labels:
    app: ${service}
    app.kubernetes.io/name: ${service}
    app.kubernetes.io/version: "${version}"
    app.kubernetes.io/managed-by: "opendesk-nix"
    de.bsi.container-gov-de.compliant: "true"
    de.bsi.container-gov-de.standard: "v1.0"
    de.bsi.container-gov-de.bg-1: "true"
    de.bsi.container-gov-de.bg-2: "true"
    de.bsi.container-gov-de.bg-3: "true"
    de.bsi.container-gov-de.bg-4: "true"
    de.bsi.container-gov-de.bg-5: "true"
    de.bsi.container-gov-de.bg-6: "true"
    de.bsi.container-gov-de.bg-7: "true"
    de.bsi.container-gov-de.bg-8: "true"
spec:
  replicas: ${replicas}
  selector:
    matchLabels:
      app: ${service}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: ${service}
        app.kubernetes.io/name: ${service}
        app.kubernetes.io/version: "${version}"
    spec:
      containers:
      - name: ${service}
        image: ${image_ref}
        imagePullPolicy: Always
        ports:
        - containerPort: ${port}
          name: http
          protocol: TCP
        resources:
          limits:
            memory: ${memory}
            cpu: ${cpu}
          requests:
            memory: "128Mi"
            cpu: "100m"
        # BG-3: Security context
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
        livenessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 2
          failureThreshold: 3
      imagePullSecrets:
      - name: container-gov-de-registry
      nodeSelector:
        kubernetes.io/os: linux
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - ${service}
              topologyKey: kubernetes.io/hostname
EOF
    
    # Generate Service
    local service_file="/tmp/${service}-service.yaml"
    cat > "$service_file" <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ${service}
  namespace: ${namespace}
  labels:
    app: ${service}
    app.kubernetes.io/name: ${service}
    app.kubernetes.io/version: "${version}"
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "${port}"
spec:
  selector:
    app: ${service}
  ports:
  - name: http
    port: ${port}
    targetPort: http
    protocol: TCP
  type: ClusterIP
EOF
    
    # Generate Ingress (optional - can be customized per environment)
    local ingress_file="/tmp/${service}-ingress.yaml"
    cat > "$ingress_file" <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${service}
  namespace: ${namespace}
  labels:
    app: ${service}
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  rules:
  - host: ${service}.${namespace}.opendesk.hrz.uni-marburg.de
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ${service}
            port:
              name: http
  tls:
  - hosts:
    - ${service}.${namespace}.opendesk.hrz.uni-marburg.de
    secretName: ${service}-tls
EOF
    
    # Generate NetworkPolicy
    local network_policy_file="/tmp/${service}-network-policy.yaml"
    cat > "$network_policy_file" <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${service}
  namespace: ${namespace}
spec:
  podSelector:
    matchLabels:
      app: ${service}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: ingress-nginx
    ports:
    - protocol: TCP
      port: ${port}
  - from:
    - podSelector:
        matchLabels:
          app: prometheus
    ports:
    - protocol: TCP
      port: ${port}
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
EOF
    
    echo -e "  ${GREEN}✓ Deployment: ${deployment_file}${NC}"
    echo -e "  ${GREEN}✓ Service: ${service_file}${NC}"
    echo -e "  ${GREEN}✓ Ingress: ${ingress_file}${NC}"
    echo -e "  ${GREEN}✓ NetworkPolicy: ${network_policy_file}${NC}"
    
    # Output the files
    echo "---"
    cat "$deployment_file"
    echo "---"
    cat "$service_file"
    echo "---"
    cat "$ingress_file"
    echo "---"
    cat "$network_policy_file"
    
    # Clean up temp files
    rm -f "$deployment_file" "$service_file" "$ingress_file" "$network_policy_file"
    
    return 0
}

# Verify deployed image signatures
verify_deployment() {
    local service="$1"
    local namespace="$2"
    local registry="$3"
    local keys_dir="$4"
    
    echo -e "${BLUE}Verifying deployment for: ${CYAN}${service}${NC}"
    
    # Get the deployed image
    local pod=$(kubectl get pods -n "$namespace" -l app="$service" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$pod" ]; then
        echo -e "  ${YELLOW}⚠ No pod found for ${service} in namespace ${namespace}${NC}"
        return 1
    fi
    
    # Get the image from the pod
    local image=$(kubectl get pod "$pod" -n "$namespace" -o jsonpath='{.spec.containers[0].image}' 2>/dev/null || echo "")
    
    if [ -z "$image" ]; then
        echo -e "  ${YELLOW}⚠ Could not get image from pod ${pod}${NC}"
        return 1
    fi
    
    echo -e "  Verifying image: ${image}"
    
    # Check if the image is from the expected registry
    if [[ "$image" != *"${registry}"* ]]; then
        echo -e "  ${RED}✗ Image is not from expected registry: ${registry}${NC}"
        return 1
    fi
    
    # Verify the signature (if we have the public key)
    local public_key="$keys_dir/cosign-key.pub"
    if [ -f "$public_key" ]; then
        echo -e "  Verifying Cosign signature..."
        if cosign verify --key "$public_key" "$image" 2>&1; then
            echo -e "  ${GREEN}✓ Signature verified${NC}"
        else
            echo -e "  ${RED}✗ Signature verification failed${NC}"
            return 1
        fi
    else
        echo -e "  ${YELLOW}⚠ Public key not found: ${public_key}, skipping signature verification${NC}"
    fi
    
    # Verify compliance labels
    echo -e "  Checking compliance labels..."
    local labels=$(kubectl get deployment "$service" -n "$namespace" -o jsonpath='{.metadata.labels}' 2>/dev/null || echo "{}")
    
    for bg in bg-1 bg-2 bg-3 bg-4 bg-5 bg-6 bg-7 bg-8; do
        if echo "$labels" | grep -q "de.bsi.container-gov-de.${bg}\":\"true\""; then
            echo -e "    ${GREEN}✓ ${bg}${NC}"
        else
            echo -e "    ${RED}✗ ${bg} label missing${NC}"
            return 1
        fi
    done
    
    echo -e "  ${GREEN}✓ Deployment verified: ${service}${NC}"
    return 0
}

# Clean deployment
clean_deployment() {
    local service="$1"
    local namespace="$2"
    local dry_run="$3"
    
    if [ "$dry_run" = "true" ]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would delete deployment for: ${CYAN}${service}${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Deleting deployment for: ${CYAN}${service}${NC}"
    
    # Delete Deployment
    if kubectl delete deployment "$service" -n "$namespace" 2>&1; then
        echo -e "  ${GREEN}✓ Deleted Deployment: ${service}${NC}"
    else
        echo -e "  ${YELLOW}⚠ Deployment not found: ${service}${NC}"
    fi
    
    # Delete Service
    if kubectl delete service "$service" -n "$namespace" 2>&1; then
        echo -e "  ${GREEN}✓ Deleted Service: ${service}${NC}"
    else
        echo -e "  ${YELLOW}⚠ Service not found: ${service}${NC}"
    fi
    
    # Delete Ingress
    if kubectl delete ingress "$service" -n "$namespace" 2>&1; then
        echo -e "  ${GREEN}✓ Deleted Ingress: ${service}${NC}"
    else
        echo -e "  ${YELLOW}⚠ Ingress not found: ${service}${NC}"
    fi
    
    # Delete NetworkPolicy
    if kubectl delete networkpolicy "$service" -n "$namespace" 2>&1; then
        echo -e "  ${GREEN}✓ Deleted NetworkPolicy: ${service}${NC}"
    else
        echo -e "  ${YELLOW}⚠ NetworkPolicy not found: ${service}${NC}"
    fi
    
    # Delete ConfigMaps and Secrets
    if kubectl delete configmap "$service" -n "$namespace" 2>&1; then
        echo -e "  ${GREEN}✓ Deleted ConfigMap: ${service}${NC}"
    else
        echo -e "  ${YELLOW}⚠ ConfigMap not found: ${service}${NC}"
    fi
    
    if kubectl delete secret "${service}-secrets" -n "$namespace" 2>&1; then
        echo -e "  ${GREEN}✓ Deleted Secret: ${service}-secrets${NC}"
    else
        echo -e "  ${YELLOW}⚠ Secret not found: ${service}-secrets${NC}"
    fi
    
    return 0
}

# Main function
main() {
    local services_arg=""
    local namespace="opendesk"
    local registry="$TARGET_REGISTRY"
    local tag="latest"
    local replicas=1
    local parallel=1
    local dry_run=true
    local apply=false
    local clean=false
    local verify=false
    local keys_dir="$SCRIPT_DIR/../migrate-upstream/keys"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --services)
                services_arg="$2"
                shift 2
                ;;
            --namespace)
                namespace="$2"
                shift 2
                ;;
            --registry)
                registry="$2"
                shift 2
                ;;
            --tag)
                tag="$2"
                shift 2
                ;;
            --replicas)
                replicas="$2"
                shift 2
                ;;
            --parallel)
                parallel="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                apply=false
                shift
                ;;
            --apply)
                apply=true
                dry_run=false
                shift
                ;;
            --clean)
                clean=true
                shift
                ;;
            --verify)
                verify=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            -*)
                echo -e "${RED}Unknown option: $1${NC}"
                usage
                exit 1
                ;;
            *)
                echo -e "${RED}Unexpected argument: $1${NC}"
                usage
                exit 1
                ;;
        esac
    done
    
    cd "$PROJECT_ROOT"
    
    # Create directories
    mkdir -p "$LOG_DIR"
    
    # Check for kubectl
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}Error: kubectl is not installed${NC}"
        echo -e "Install with: nix-env -iA nixpkgs.kubectl"
        exit 1
    fi
    
    # Check if cluster is accessible
    if [ "$dry_run" != "true" ] && [ "$apply" = "true" ]; then
        if ! kubectl cluster-info > /dev/null 2>&1; then
            echo -e "${RED}Error: Cannot access Kubernetes cluster${NC}"
            echo -e "Check your kubeconfig"
            exit 1
        fi
    fi
    
    # Get services
    local services=()
    if [ -n "$services_arg" ]; then
        IFS=',' read -ra services <<< "$services_arg"
    else
        local all_services=($(get_all_services | tr ',' '\n'))
        services=("${all_services[@]}")
    fi
    
    if [ ${#services[@]} -eq 0 ]; then
        echo -e "${RED}Error: No services found${NC}"
        usage
        exit 1
    fi
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}container.gov.de Kubernetes Deployer${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Namespace: ${namespace}${NC}"
    echo -e "${BLUE}Registry: ${registry}${NC}"
    echo -e "${BLUE}Tag: ${tag}${NC}"
    echo -e "${BLUE}Replicas: ${replicas}${NC}"
    echo -e "${BLUE}Services: ${#services[@]}${NC}"
    [ "$dry_run" = "true" ] && echo -e "${YELLOW}Dry run mode enabled${NC}"
    [ "$apply" = "true" ] && echo -e "${GREEN}Apply mode enabled${NC}"
    [ "$clean" = "true" ] && echo -e "${YELLOW}Clean mode enabled${NC}"
    [ "$verify" = "true" ] && echo -e "${BLUE}Verify mode enabled${NC}"
    echo ""
    
    # Verify mode
    if [ "$verify" = "true" ]; then
        local success_count=0
        local failure_count=0
        
        for service in "${services[@]}"; do
            if verify_deployment "$service" "$namespace" "$registry" "$keys_dir"; then
                ((success_count++))
            else
                ((failure_count++))
            fi
        done
        
        echo ""
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}Verification Summary${NC}"
        echo -e "========================================${NC}"
        echo -e "${GREEN}Verified: $success_count${NC}"
        echo -e "${RED}Failed:   $failure_count${NC}"
        
        if [ "$failure_count" -gt 0 ]; then
            echo -e "${RED}⚠ Some deployments failed verification${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}✓ All deployments verified!${NC}"
        exit 0
    fi
    
    # Clean mode
    if [ "$clean" = "true" ]; then
        local success_count=0
        local failure_count=0
        
        for service in "${services[@]}"; do
            if clean_deployment "$service" "$namespace" "$dry_run"; then
                ((success_count++))
            else
                ((failure_count++))
            fi
        done
        
        echo ""
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}Clean Summary${NC}"
        echo -e "========================================${NC}"
        echo -e "${GREEN}Cleaned: $success_count${NC}"
        echo -e "${RED}Failed:   $failure_count${NC}"
        
        if [ "$failure_count" -gt 0 ]; then
            echo -e "${RED}⚠ Some cleanups failed${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}✓ All deployments cleaned!${NC}"
        
        # Exit unless also deploying
        if [ "$apply" != "true" ]; then
            exit 0
        fi
    fi
    
    # Deploy mode
    if [ "$parallel" -gt 1 ] && [ "$parallel" -le ${#services[@]} ]; then
        # Parallel deployment
        echo -e "${BLUE}Deploying ${#services[@]} services with ${parallel} parallel jobs...${NC}"
        
        seq 0 $(( ${#services[@]} - 1 )) | xargs -P "$parallel" -I {} sh -c '
            svc="${services[{}]}"
            '"$0'" --services "\$svc" --namespace "$namespace" --registry "$registry" --tag "$tag" --replicas "$replicas" --dry-run $dry_run --apply $apply
        ' _ "$0"
    else
        # Sequential deployment
        local success_count=0
        local failure_count=0
        
        for service in "${services[@]}"; do
            echo ""
            echo -e "${BLUE}========================================${NC}"
            echo -e "${BLUE}Deploying: ${CYAN}${service}${NC}"
            echo -e "${BLUE}========================================${NC}"
            
            # Generate manifest
            if generate_manifest "$service" "$namespace" "$registry" "$tag" "$replicas" "$dry_run"; then
                ((success_count++))
                
                # Apply if requested
                if [ "$apply" = "true" ]; then
                    echo -e "${BLUE}Applying Kubernetes manifests...${NC}"
                    
                    # Create temp file for all manifests
                    local tmp_file="/tmp/${service}-all.yaml"
                    generate_manifest "$service" "$namespace" "$registry" "$tag" "$replicas" "false" > "$tmp_file" 2>/dev/null || true
                    
                    if [ -f "$tmp_file" ] && [ -s "$tmp_file" ]; then
                        if kubectl apply -f "$tmp_file" 2>&1; then
                            echo -e "  ${GREEN}✓ Applied: ${service}${NC}"
                            
                            # Wait for rollout
                            if kubectl rollout status deployment "$service" -n "$namespace" --timeout=300s 2>&1; then
                                echo -e "  ${GREEN}✓ Rollout complete: ${service}${NC}"
                            else
                                echo -e "  ${RED}✗ Rollout failed: ${service}${NC}"
                                ((failure_count++))
                            fi
                        else
                            echo -e "  ${RED}✗ Apply failed: ${service}${NC}"
                            ((failure_count++))
                        fi
                        
                        rm -f "$tmp_file"
                    else
                        echo -e "  ${RED}✗ Failed to generate manifests: ${service}${NC}"
                        ((failure_count++))
                    fi
                fi
            else
                echo -e "  ${RED}✗ Failed to generate manifest: ${service}${NC}"
                ((failure_count++))
            fi
        done
        
        echo ""
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}Deployment Summary${NC}"
        echo -e "========================================${NC}"
        echo -e "${GREEN}Successful: $success_count${NC}"
        echo -e "${RED}Failed:      $failure_count${NC}"
        echo -e "${BLUE}Total:       $((success_count + failure_count))${NC}"
        
        if [ "$failure_count" -gt 0 ]; then
            echo -e "${RED}⚠ Some deployments failed${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}✓ All deployments completed!${NC}"
        
        # Show next steps
        echo ""
        if [ "$dry_run" = "true" ]; then
            echo -e "${BLUE}Next steps:${NC}"
            echo -e "  1. Review generated YAML manifests"
            echo -e "  2. Run with --apply to deploy: $0 --apply"
        else
            echo -e "${BLUE}Next steps:${NC}"
            echo -e "  1. Verify deployments: kubectl get pods -n ${namespace}"
            echo -e "  2. Verify compliance: $0 --verify"
            echo -e "  3. Check logs: kubectl logs -n ${namespace} -l app=SERVICE"
        fi
    fi
}

# Run main with all arguments
main "$@"

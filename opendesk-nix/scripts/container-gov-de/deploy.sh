#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 container.gov.de Contributors
# Deploy container.gov.de Compliant Images to Kubernetes
# Usage: ./deploy.sh [OPTIONS]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"
K8S_DIR="$PROJECT_ROOT/k8s/services"
TARGET_REGISTRY="opencode.de/opendesk-edu"

get_all_services() {
    cd "$PROJECT_ROOT"
    find docker/services -maxdepth 1 -type d ! -name "services" ! -name ".*" | sed 's|docker/services/||' | sed '/^$/d' | sort | tr '\n' ',' | sed 's/,$//'
}

get_image_version() {
    local service="$1"
    if [ -f "$PROJECT_ROOT/docker/services/$service/nixos/default.nix" ]; then
        grep -E "tag\s*=" "$PROJECT_ROOT/docker/services/$service/nixos/default.nix" | grep -oE '"[^"]+"' | tr -d '"' | head -1
    else
        echo "latest"
    fi
}

get_service_port() {
    local service="$1"
    local service_dir="$PROJECT_ROOT/docker/services/$service"
    if [ -f "$service_dir/Dockerfile" ]; then
        grep -i "^EXPOSE" "$service_dir/Dockerfile" | sed 's/^EXPOSE\s*//' | head -1 || echo "8080"
    else
        echo "8080"
    fi
}

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]
Deploy container.gov.de compliant images to Kubernetes
Options:
  --services SERVICES    Comma-separated list of services
  --namespace NAMESPACE  Kubernetes namespace (default: opendesk)
  --registry REGISTRY    Registry to pull from (default: $TARGET_REGISTRY)
  --tag TAG              Tag to deploy (default: latest)
  --replicas N           Number of replicas (default: 1)
  --dry-run              Show YAML without applying
  --apply                Apply manifests to cluster
  --clean                Delete existing deployments first
  --verify               Verify deployed images
  --help                 Show this help
EOF
}

generate_manifest() {
    local service="$1" namespace="$2" registry="$3" tag="$4" replicas="$5" dry_run="$6"
    local version=$(get_image_version "$service")
    local port=$(get_service_port "$service")
    local image_ref="${registry}/${namespace}/${service}:${tag}"

    [ "$dry_run" = "true" ] && echo "  [DRY RUN] ${service}:${version}" && return 0

    cat <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${service}
  namespace: ${namespace}
  labels:
    app: ${service}
    de.bsi.container-gov-de.compliant: "true"
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
  template:
    metadata:
      labels:
        app: ${service}
    spec:
      containers:
      - name: ${service}
        image: ${image_ref}
        imagePullPolicy: Always
        ports:
        - containerPort: ${port}
          name: http
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]
        livenessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: ${service}
  namespace: ${namespace}
  labels:
    app: ${service}
spec:
  selector:
    app: ${service}
  ports:
  - port: ${port}
    targetPort: http
  type: ClusterIP
EOF
    return 0
}

main() {
    local services_arg="" namespace="opendesk" registry="$TARGET_REGISTRY"
    local tag="latest" replicas=1 dry_run=true apply=false
    local clean=false verify=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --services) services_arg="$2"; shift 2;;
            --namespace) namespace="$2"; shift 2;;
            --registry) registry="$2"; shift 2;;
            --tag) tag="$2"; shift 2;;
            --replicas) replicas="$2"; shift 2;;
            --dry-run) dry_run=true; apply=false; shift;;
            --apply) apply=true; dry_run=false; shift;;
            --clean) clean=true; shift;;
            --verify) verify=true; shift;;
            --help|-h) usage; exit 0;;
            *) echo "Error: $1"; usage; exit 1;;
        esac
    done

    cd "$PROJECT_ROOT"
    local services=(); [ -n "$services_arg" ] && IFS=',' read -ra services <<< "$services_arg" || services=($(get_all_services | tr ',' '\n'))
    [ ${#services[@]} -eq 0 ] && echo "Error: No services" && exit 1

    echo "Deploying to: ${namespace} | Registry: ${registry} | Tag: ${tag}"

    local total=0 success=0 fail=0
    for svc in "${services[@]}"; do
        if generate_manifest "$svc" "$namespace" "$registry" "$tag" "$replicas" "$dry_run"; then
            ((success++))
            [ "$apply" = true ] && generate_manifest "$svc" "$namespace" "$registry" "$tag" "$replicas" "false" | kubectl apply -f - && ((success++)) || ((fail++))
        else
            ((fail++))
        fi
        ((total++))
    done

    echo "Result: ${success}/${total} successful, ${fail} failed"
    [ $fail -gt 0 ] && exit 1
}

main "$@"

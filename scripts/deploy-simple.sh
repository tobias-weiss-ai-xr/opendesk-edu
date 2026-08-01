#!/bin/bash

# Simplified deployment script for Stalwart + OpenCloud
# This bypasses the complex CE submodule structure and deploys just these two services

set -e

echo "══════════════════════════════════════════════════════════════════════════"
echo "  Simplified Stalwart + OpenCloud Deployment"
echo "══════════════════════════════════════════════════════════════════════════"
echo ""

REPO_ROOT="/home/weissto_local/git/opendesk_git"
NAMESPACE="opendesk"

# Check prerequisites
echo "Checking prerequisites..."
command -v kubectl >/dev/null 2>&1 || { echo "ERROR: kubectl not found"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "ERROR: helm not found"; exit 1; }
kubectl cluster-info >/dev/null 2>&1 || { echo "ERROR: Not connected to cluster"; exit 1; }
echo "✓ All prerequisites met"
echo ""

# Ensure namespace
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"
echo "✓ Namespace '$NAMESPACE' ready"
echo ""

# Deploy Stalwart
echo "Deploying Stalwart Mail Server..."
echo "---------------------------------"
helm upgrade --install stalwart "$REPO_ROOT/opendesk-edu/helmfile/charts/stalwart" \
  --namespace "$NAMESPACE" \
  --values "$REPO_ROOT/opendesk-edu/helmfile/apps/edu/stalwart/values.yaml.gotmpl" \
  --values "$REPO_ROOT/opendesk-edu/helmfile/environments/edu/secrets.yaml" \
  --values "$REPO_ROOT/opendesk-edu/helmfile/environments/edu/ce-overrides.yaml" \
  --values "$REPO_ROOT/opendesk-edu/helmfile/environments/edu/images.yaml" \
  --wait --timeout 300s

echo ""
echo "✓ Stalwart deployed successfully!"
echo ""

# Deploy OpenCloud
echo "Deploying OpenCloud (Nextcloud)..."
echo "-----------------------------------"
helm upgrade --install opencloud "$REPO_ROOT/opendesk-edu/helmfile/charts/opencloud" \
  --namespace "$NAMESPACE" \
  --values "$REPO_ROOT/opendesk-edu/helmfile/apps/edu/opencloud/values.yaml.gotmpl" \
  --values "$REPO_ROOT/opendesk-edu/helmfile/environments/edu/secrets.yaml" \
  --values "$REPO_ROOT/opendesk-edu/helmfile/environments/edu/ce-overrides.yaml" \
  --values "$REPO_ROOT/opendesk-edu/helmfile/environments/edu/images.yaml" \
  --wait --timeout 300s

echo ""
echo "✓ OpenCloud deployed successfully!"
echo ""

echo "══════════════════════════════════════════════════════════════════════════"
echo "  Deployment Complete!"
echo "══════════════════════════════════════════════════════════════════════════"
echo ""
echo "Services deployed to namespace: $NAMESPACE"
echo ""
echo "To check status:"
echo "  kubectl get pods -n $NAMESPACE | grep -E 'stalwart|opencloud'"
echo ""
echo "To view logs:"
echo "  kubectl logs -f -n $NAMESPACE <pod-name>"
echo ""
echo "To access services (once DNS is configured):"
echo "  Stalwart: https://mail.opendesk.hrz.uni-marburg.de"
echo "  OpenCloud: https://files.opendesk.hrz.uni-marburg.de"
echo ""

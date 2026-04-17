#!/bin/bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0

# SOGo Apache Proxy Deployment Script
# This script completes the SOGo deployment by enabling Apache proxy
# Execute on server: root@178.63.182.104

set -e

echo "======================================"
echo "SOGo Apache Proxy Deployment Script"
echo "======================================"

cd /root/opendesk-edu

# Step 1: Fetch and checkout the feature branch
echo ""
echo "Step 1: Fetching feature/sogo-fix branch from Codeberg..."
git fetch codeberg feature/sogo-fix:feature/sogo-fix || {
    echo "ERROR: Failed to fetch feature/sogo-fix branch"
    exit 1
}

echo "Step 2: Checking out feature/sogo-fix branch..."
git checkout feature/sogo-fix || {
    echo "ERROR: Failed to checkout feature/sogo-fix branch"
    exit 1
}

# Step 2: Verify the Apache configuration is present
echo ""
echo "Step 3: Verifying Apache configuration in entrypoint-configmap.yaml..."
if grep -q "^\[program:apache\]" helmfile/charts/sogo/templates/entrypoint-configmap.yaml; then
    echo "✓ Apache program configuration found"
else
    echo "ERROR: Apache program configuration not found in entrypoint-configmap.yaml"
    exit 1
fi

if grep -q "/usr/sbin/apache2.*-D FOREGROUND" helmfile/charts/sogo/templates/entrypoint-configmap.yaml; then
    echo "✓ Apache foreground command found"
else
    echo "ERROR: Apache foreground command not found"
    exit 1
fi

# Step 3: Deploy using Helm
echo ""
echo "Step 4: Deploying SOGo with Apache proxy..."
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm upgrade --install sogo helmfile/charts/sogo \
    --namespace opendesk-edu \
    --values sogo-direct-values.yaml \
    --timeout 10m || {
    echo "ERROR: Helm upgrade failed"
    exit 1
}

# Step 4: Wait for the new pod to be ready
echo ""
echo "Step 5: Waiting for SOGo pod to be ready..."
kubectl -n opendesk-edu wait \
    --for=condition=ready pod \
    -l app.kubernetes.io/instance=sogo \
    --timeout=5m || {
    echo "ERROR: Pod did not become ready within 5 minutes"
    exit 1
}

# Step 5: Get the new pod name
echo ""
echo "Step 6: Getting SOGo pod name..."
POD_NAME=$(kubectl -n opendesk-edu get pods \
    -l app.kubernetes.io/instance=sogo \
    -o jsonpath='{.items[0].metadata.name}')
echo "SOGo pod: $POD_NAME"

# Step 6: Verify Apache is running
echo ""
echo "Step 7: Verifying Apache is running..."
if kubectl -n opendesk-edu exec "$POD_NAME" -- supervisorctl status apache | grep -q RUNNING; then
    echo "✓ Apache is RUNNING"
else
    echo "ERROR: Apache is not running"
    echo "Supervisord status:"
    kubectl -n opendesk-edu exec "$POD_NAME" -- supervisorctl status
    exit 1
fi

# Step 7: Verify port 80 is listening
echo ""
echo "Step 8: Verifying port 80 is listening..."
POD_IP=$(kubectl -n opendesk-edu get pod "$POD_NAME" -o jsonpath='{.status.podIP}')
if kubectl -n opendesk-edu exec "$POD_NAME" -- netstat -tlnp | grep -q ":80.*LISTEN"; then
    echo "✓ Port 80 is listening on $POD_IP"
else
    echo "ERROR: Port 80 is not listening"
    echo "Listening ports:"
    kubectl -n opendesk-edu exec "$POD_NAME" -- netstat -tlnp
    exit 1
fi

# Step 8: Test SOGo web interface
echo ""
echo "Step 9: Testing SOGo web interface..."
if curl -s -o /dev/null -w "%{http_code}" "http://$POD_IP:80/" | grep -q "200\|302"; then
    echo "✓ SOGo web interface is accessible (HTTP 200/302)"
else
    echo "WARNING: SOGo web interface test returned non-200 status"
    echo "Status code: $(curl -s -o /dev/null -w "%{http_code}" "http://$POD_IP:80/")"
fi

# Step 9: Verify ConfigMap has supervisord.conf
echo ""
echo "Step 10: Verifying ConfigMap has supervisord.conf..."
CM_DATA_KEYS=$(kubectl -n opendesk-edu get configmap sogo-sogo-entrypoint \
    -o jsonpath='{.data}' | jq -r 'keys | .[]')
if echo "$CM_DATA_KEYS" | grep -q "supervisord.conf"; then
    echo "✓ ConfigMap has supervisord.conf key"
else
    echo "ERROR: ConfigMap missing supervisord.conf key"
    echo "ConfigMap keys: $CM_DATA_KEYS"
    exit 1
fi

# Step 10: Display SOGo logs for verification
echo ""
echo "Step 11: Displaying SOGo logs (last 20 lines)..."
kubectl -n opendesk-edu logs "$POD_NAME" --tail=20

# Final summary
echo ""
echo "======================================"
echo "Deployment Complete!"
echo "======================================"
echo ""
echo "SOGo Pod: $POD_NAME"
echo "Pod IP: $POD_IP"
echo "Status: Running"
echo "Apache: RUNNING"
echo "Port 80: LISTENING"
echo ""
echo "Next steps:"
echo "1. Access SOGo web interface: https://sogo.opendesk-edu.org"
echo "2. Test OIDC authentication with Keycloak"
echo "3. Verify email functionality works"
echo "4. Test calendar and contacts integration"
echo ""
echo "To view logs:"
echo "  kubectl -n opendesk-edu logs -f $POD_NAME"
echo ""
echo "To check supervisord status:"
echo "  kubectl -n opendesk-edu exec $POD_NAME -- supervisorctl status"
echo ""
echo "====================================================="
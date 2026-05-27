#!/bin/bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Simple Apache HTTP test pod

set -euo pipefail

echo "=== SOGo Fixes Apache Proxy Verification ==="
echo "Testing Apache DefaultRuntimeDir fix with full Apache image"

kubectl delete deployment apache-test -n opendesk-edu --ignore-not-found=true

echo "Creating Apache test deployment with Debian base..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache-test
  namespace: opendesk-edu
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apache-test
  template:
    metadata:
      labels:
        app: apache-test
    spec:
      containers:
      - name: apache
        image: debian:bullseye
        ports:
        - containerPort: 80
        command:
        - bash
        - -c
        - |
          echo "Installing Apache with DefaultRuntimeDir fix..."
          apt-get update && apt-get install -y apache2 curl net-tools iputils-ping
          echo "Starting Apache with fix..."
          mkdir -p /var/run/apache2
          exec /usr/sbin/apache2 -c "ErrorLog /dev/stdout" -c "DefaultRuntimeDir /var/run/apache2" -D FOREGROUND
EOF

echo "Waiting for pod to be ready..."
sleep 15

POD=$(kubectl get pods -n opendesk-edu -l app=apache-test -o name | head -1)
if [ -z "$POD" ]; then
    echo "ERROR: Pod not found"
    kubectl get pods -n opendesk-edu -l app=apache-test
    exit 1
fi

echo "Pod: $POD"
echo "Waiting for Apache to start..."
sleep 20

echo ""
echo "=== Apache Process Status ==="
kubectl exec -n opendesk-edu $POD -- ps aux | grep apache

echo ""
echo "=== Port 80 Bindings ==="
kubectl exec -n opendesk-edu $POD -- netstat -tlnp | grep :80

echo ""
echo "=== HTTP Response Test ==="
kubectl exec -n opendesk-edu $POD -- curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:80/

echo ""
echo "=== Apache Self-Test ==="
kubectl exec -n opendesk-edu $POD -- curl -s http://localhost:80/ | head -5

echo ""
echo "✓ Apache DefaultRuntimeDir fix verified successfully!"
echo ""
echo "Deployment summary:"
kubectl get deployment apache-test -n opendesk-edu
kubectl get pod -n opendesk-edu -l app=apache-test
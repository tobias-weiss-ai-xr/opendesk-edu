#!/bin/bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Quick deployment script for SOGo fixes verification in opendesk-edu namespace

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="${NAMESPACE:-opendesk-edu}"
DRY_RUN="${DRY_RUN:-false}"

echo -e "${GREEN}=== SOGo Fixes Deployment Verification ===${NC}"
echo "Namespace: ${NAMESPACE}"
echo "Dry Run: ${DRY_RUN}"
echo ""

# Check prerequisites
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}ERROR: kubectl not found${NC}"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo -e "${RED}ERROR: helm not found${NC}"
    exit 1
fi

# Create namespace if it doesn't exist
echo -e "${YELLOW}Step 1: Creating namespace ${NAMESPACE}...${NC}"
if kubectl get namespace "${NAMESPACE}" &> /dev/null; then
    echo "Namespace ${NAMESPACE} already exists"
else
    if [ "$DRY_RUN" = "false" ]; then
        kubectl create namespace "${NAMESPACE}"
        echo -e "${GREEN}✓ Namespace created${NC}"
    else
        echo "[DRY RUN] Would create namespace ${NAMESPACE}"
    fi
fi

echo ""

# Deploy with helmfile (SOGo only)
echo -e "${YELLOW}Step 2: Deploying SOGo with fixes...${NC}"
echo "Environment: prod"
echo "Namespace: ${NAMESPACE}"

if [ "$DRY_RUN" = "false" ]; then
    # Deploy SOGo using helmfile
    helmfile -f helmfile/apps/sogo/helmfile-child.yaml.gotmpl \
        --environment prod \
        --namespace "${NAMESPACE}" \
        apply

    echo -e "${GREEN}✓ Deployment initiated${NC}"
else
    echo "[DRY RUN] Would deploy SOGo to ${NAMESPACE}"
fi

echo ""

# Wait for deployment
if [ "$DRY_RUN" = "false" ]; then
    echo -e "${YELLOW}Step 3: Waiting for SOGo pod to be ready...${NC}"
    # Wait for deployment to complete
    kubectl wait --for=condition=available \
        deployment -l app.kubernetes.io/name=sogo \
        -n "${NAMESPACE}" \
        --timeout=300s

    echo -e "${GREEN}✓ Deployment complete${NC}"
fi

echo ""

# Get pod name
if [ "$DRY_RUN" = "false" ]; then
    POD=$(kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name=sogo -o name | head -1)
    if [ -z "$POD" ]; then
        echo -e "${RED}ERROR: SOGo pod not found${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Step 4: Running verification checks...${NC}"
    echo "Pod: ${POD}"
    echo ""

    # Check Apache status
    echo "Checking Apache status..."
    APACHE_STATUS=$(kubectl -n "${NAMESPACE}" exec ${POD} -- supervisorctl status apache || echo "")
    if echo "$APACHE_STATUS" | grep -q "RUNNING"; then
        echo -e "${GREEN}✓ Apache is running${NC}"
        echo "$APACHE_STATUS"
    else
        echo -e "${RED}✗ Apache is not running${NC}"
        echo "$APACHE_STATUS"
    fi
    echo ""

    # Check SOGo status
    echo "Checking SOGo status..."
    SOGO_STATUS=$(kubectl -n "${NAMESPACE}" exec ${POD} -- supervisorctl status sogo || echo "")
    if echo "$SOGO_STATUS" | grep -q "RUNNING"; then
        echo -e "${GREEN}✓ SOGo is running${NC}"
        echo "$SOGO_STATUS"
    else
        echo -e "${RED}✗ SOGo is not running${NC}"
        echo "$SOGO_STATUS"
    fi
    echo ""

    # Check port 80 bindings
    echo "Checking port 80 bindings..."
    PORT80=$(kubectl -n "${NAMESPACE}" exec ${POD} -- netstat -tlnp | grep :80 || echo "")
    if echo "$PORT80" | grep -q "LISTEN"; then
        echo -e "${GREEN}✓ Port 80 is accessible${NC}"
        echo "$PORT80"
    else
        echo -e "${RED}✗ Port 80 is not bound${NC}"
        echo "$PORT80"
    fi
    echo ""

    # Check SOGo internal port
    echo "Checking SOGo internal port 20000..."
    PORT20000=$(kubectl -n "${NAMESPACE}" exec ${POD} -- netstat -tlnp | grep 20000 || echo "")
    if echo "$PORT20000" | grep -q "LISTEN"; then
        echo -e "${GREEN}✓ SOGo internal port 20000 is accessible${NC}"
        echo "$PORT20000"
    else
        echo -e "${RED}✗ SOGo internal port 20000 is not bound${NC}"
        echo "$PORT20000"
    fi
fi

echo ""
echo -e "${GREEN}=== Deployment Summary ===${NC}"
echo "Namespace: ${NAMESPACE}"
if [ "$DRY_RUN" = "false" ]; then
    echo "SOGo Pod: ${POD}"
    echo ""
    echo "Next steps:"
    echo "1. Check pod logs: kubectl -n ${NAMESPACE} logs -f ${POD}"
    echo "2. Test access: kubectl -n ${NAMESPACE} port-forward ${POD} 8080:80"
    echo "3. Then: curl http://localhost:8080/"
else
    echo "Status: DRY RUN (no changes made)"
fi
echo ""
echo "For detailed troubleshooting, see SOGO_FIXES_VERIFICATION_GUIDE.md"
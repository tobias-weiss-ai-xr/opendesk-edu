#!/bin/bash
# Apply OX-Independent LDAP Category
# This script creates the cn=applications category to make the deployment OX-independent
#
# Usage: ./apply-ox-independent-ldap-category.sh

set -euo pipefail

# Configuration
NAMESPACE="${NAMESPACE:-opendesk-edu}"
LDAP_POD="${LDAP_POD:-ums-ldap-server-primary-0}"
LDAP_BASE_DN="${LDAP_BASE_DN:-dc=swp-ldap,dc=internal}"
LDAP_ADMIN_DN="${LDAP_ADMIN_DN:-cn=admin,$LDAP_BASE_DN}"

# Get LDAP pod name if not specified
if [[ -z "$LDAP_POD" ]]; then
    LDAP_POD=$(kubectl get pod -n "$NAMESPACE" -l app.kubernetes.io/component=server -o jsonpath='{.items[0].metadata.name}')
fi

echo "Using LDAP pod: $LDAP_POD"

# Verify pod is running
POD_STATUS=$(kubectl get pod -n "$NAMESPACE" "$LDAP_POD" -o jsonpath='{.status.phase}')
echo "Pod status: $POD_STATUS"

if [[ "$POD_STATUS" != "Running" ]]; then
    echo "ERROR: LDAP pod is not running"
    exit 1
fi

# Get LDAP password
echo "Retrieving LDAP credentials..."
LDAP_PASSWORD=$(kubectl get secret -n "$NAMESPACE" ums-ldap-server-credentials -o jsonpath='{.data.ldapSecret}' | base64 -d)

if [[ -z "$LDAP_PASSWORD" ]]; then
    echo "ERROR: Could not retrieve LDAP password"
    exit 1
fi

# Check if category already exists
echo "Checking if cn=applications already exists..."
EXISTS=$(kubectl exec -n "$NAMESPACE" "$LDAP_POD" -c main -- ldapsearch -x -LLL \
    -D "$LDAP_ADMIN_DN" -w "$LDAP_PASSWORD" \
    -b "cn=applications,cn=category,cn=portals,cn=univention,$LDAP_BASE_DN" \
    dn 2>/dev/null | grep -c "^dn:" || echo "0")

if [[ "$EXISTS" -gt 0 ]]; then
    echo "✓ cn=applications already exists in LDAP"
    exit 0
fi

# Locate LDIF file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LDIF_FILE="${SCRIPT_DIR}/files/applications-ox-independent.ldif"

if [[ ! -f "$LDIF_FILE" ]]; then
    echo "ERROR: LDIF file not found at $LDIF_FILE"
    exit 1
fi

echo "Using LDIF file: $LDIF_FILE"

# Apply LDIF
echo "Creating OX-independent LDAP category..."
kubectl cp "$LDIF_FILE" "$NAMESPACE/$LDAP_POD:/tmp/applications-ox-independent.ldif" -c main

kubectl exec -n "$NAMESPACE" "$LDAP_POD" -c main -- ldapadd -x \
    -D "$LDAP_ADMIN_DN" -w "$LDAP_PASSWORD" \
    -f /tmp/applications-ox-independent.ldif

# Verify creation
echo "Verifying creation..."
VERIFY_EXISTS=$(kubectl exec -n "$NAMESPACE" "$LDAP_POD" -c main -- ldapsearch -x -LLL \
    -D "$LDAP_ADMIN_DN" -w "$LDAP_PASSWORD" \
    -b "cn=applications,cn=category,cn=portals,cn=univention,$LDAP_BASE_DN" \
    dn 2>/dev/null | grep -c "^dn:" || echo "0")

if [[ "$VERIFY_EXISTS" -gt 0 ]]; then
    echo "✓ Successfully created cn=applications"
else
    echo "✗ Failed to verify creation"
    exit 1
fi

echo ""
echo "OX-independent LDAP category created successfully!"
echo "This category can be referenced as cn=applications (without the od. prefix)"
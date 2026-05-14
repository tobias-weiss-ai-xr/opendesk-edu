#!/bin/bash
set -e

KEYCLOAK_URL="https://id.opendesk-edu.org"
REALM="opendesk"
ADMIN_USERNAME="kcadmin"
ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-}"

if [ -z "$ADMIN_PASSWORD" ]; then
    echo "Error: KEYCLOAK_ADMIN_PASSWORD environment variable not set"
    echo "Get the admin password from: kubectl get secret ums-keycloak-admin-password -n opendesk-edu -o jsonpath='{.data.password}' | base64 -d"
    exit 1
fi

echo "Getting Keycloak admin token..."
TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$ADMIN_USERNAME" \
    -d "password=$ADMIN_PASSWORD" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" | jq -r '.access_token')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "Error: Failed to get admin token"
    exit 1
fi

echo "Checking if portal client already exists..."
EXISTING_CLIENT=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/clients?clientId=opendesk-portal" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id // empty')

if [ -n "$EXISTING_CLIENT" ]; then
    echo "Deleting existing portal client: $EXISTING_CLIENT"
    curl -s -X DELETE "$KEYCLOAK_URL/admin/realms/$REALM/clients/$EXISTING_CLIENT" \
        -H "Authorization: Bearer $TOKEN"
    echo "Existing client deleted"
fi

echo "Retrieving portal client secret from Kubernetes..."
SECRET=$(kubectl get secret ums-keycloak-config -n opendesk-edu -o jsonpath='{.data.portal_client_secret}' 2>/dev/null || echo "")
if [ -z "$SECRET" ]; then
    echo "Warning: Could not find portal client secret in ums-keycloak-config secret"
    echo "Attempting to find in configmap..."
    SECRET=$(kubectl get configmap ums-keycloak-config -n opendesk-edu -o jsonpath='{.data.portal_client_secret}' 2>/dev/null || echo "")
fi

if [ -z "$SECRET" ]; then
    echo "Error: Could not find portal client secret. Please ensure it exists in ums-keycloak-config."
    exit 1
fi

SECRET=$(echo "$SECRET" | base64 -d)
echo "Using portal client secret"

echo "Creating portal OIDC client with multi-domain support..."
sed "s/{{PORTAL_CLIENT_SECRET}}/$SECRET/g" /tmp/create-portal-client.json > /tmp/portal-client-final.json

curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM/clients" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d @/tmp/portal-client-final.json > /dev/null

echo "Portal OIDC client created successfully"
echo ""
echo "Client configuration:"
echo "  Client ID: opendesk-portal"
echo "  Redirect URIs:"
echo "    - https://portal.demo.opendesk-edu.org/*"
echo "    - https://portal.demo.opendesk-sme.org/*"
echo ""
echo "Test the login on https://portal.demo.opendesk-sme.org/ to verify OIDC authentication works"
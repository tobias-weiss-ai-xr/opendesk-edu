#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 openDesk Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Add a custom audience string to a Keycloak client's access token.
# Useful when a relying party (e.g., pam_oauthbearer.so) validates the `aud` claim
# against a URI that is not a registered Keycloak client.
#
# Usage:
#   ./add-keycloak-custom-audience.sh <client-id> <custom-audience> [realm] [keycloak-pod]
#
# Examples:
#   ./add-keycloak-custom-audience.sh 87ae71f6... "ldaps://opendesk.hrz.uni-marburg.de/"
#   ./add-keycloak-custom-audience.sh my-client "https://api.example.com" myrealm my-keycloak-0
#
# Dependencies:
#   - kubectl with access to the cluster
#   - jq (preferred but optional)

set -euo pipefail

CLIENT_ID="${1:-}"
CUSTOM_AUDIENCE="${2:-}"
REALM="${3:-opendesk}"
KEYCLOAK_POD="${4:-ums-keycloak-0}"
NAMESPACE="${NAMESPACE:-opendesk}"
KCADM_CONFIG="/tmp/.keycloak/kcadm.config"

if [ -z "$CLIENT_ID" ] || [ -z "$CUSTOM_AUDIENCE" ]; then
    echo "Usage: $0 <client-id> <custom-audience> [realm] [keycloak-pod]"
    echo ""
    echo "Examples:"
    echo "  $0 87ae71f6... 'ldaps://opendesk.hrz.uni-marburg.de/'"
    echo "  $0 my-client 'https://api.example.com' myrealm my-keycloak-0"
    exit 1
fi

MAPPER_NAME="custom-audience-$(echo "$CUSTOM_AUDIENCE" | tr -c 'a-zA-Z0-9' '-')"

echo "=== Adding custom audience mapper ==="
echo "  Client ID:       $CLIENT_ID"
echo "  Custom audience: $CUSTOM_AUDIENCE"
echo "  Realm:           $REALM"
echo "  Pod:             $KEYCLOAK_POD"
echo "  Mapper name:     $MAPPER_NAME"
echo ""

MAPPER_JSON=$(cat <<ENDJSON
{
  "name": "$MAPPER_NAME",
  "protocol": "openid-connect",
  "protocolMapper": "oidc-audience-mapper",
  "config": {
    "included.custom.audience": "$CUSTOM_AUDIENCE",
    "access.token.claim": "true",
    "id.token.claim": "false",
    "userinfo.token.claim": "false"
  }
}
ENDJSON
)

echo "$MAPPER_JSON" | kubectl exec -n "$NAMESPACE" "$KEYCLOAK_POD" -i -- bash -c "
set -euo pipefail

# Authenticate with Keycloak admin CLI
/opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user kcadmin \
  --password \"\$(cat /opt/keycloak/kcadm-admin-password 2>/dev/null || echo 'admin')\" \
  --config $KCADM_CONFIG 2>&1

# Check if mapper already exists
EXISTING=\$(/opt/keycloak/bin/kcadm.sh get clients/$CLIENT_ID/protocol-mappers/models \
  -r $REALM \
  --config $KCADM_CONFIG 2>/dev/null | grep -c \"$MAPPER_NAME\" || true)

if [ \"\$EXISTING\" -gt 0 ]; then
  echo 'Mapper already exists — skipping.'
  exit 0
fi

# Write mapper JSON from stdin
cat > /tmp/audience-mapper.json

# Add the mapper
/opt/keycloak/bin/kcadm.sh create clients/$CLIENT_ID/protocol-mappers/models \
  -r $REALM \
  --config $KCADM_CONFIG \
  -f /tmp/audience-mapper.json 2>&1

echo 'Mapper created successfully.'
" 2>&1

echo ""
echo "=== Done ==="
echo "Verify: kubectl exec -n $NAMESPACE $KEYCLOAK_POD -- \
  /opt/keycloak/bin/kcadm.sh get clients/$CLIENT_ID/protocol-mappers/models \
  -r $REALM --config $KCADM_CONFIG 2>/dev/null | grep -A5 '$MAPPER_NAME'"

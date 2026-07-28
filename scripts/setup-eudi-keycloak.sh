#!/bin/bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Setup bundID + EUDI Wallet integration in Keycloak
# Phase 1: bundID SAML Identity Provider
# Phase 2: EUDI Wallet SIOP/OIDC4VP
#
# Usage: ./scripts/setup-eudi-keycloak.sh [phase]
#   phase: 1 (bundID), 2 (EUDI SIOP), all (default)

set -euo pipefail

NAMESPACE="${NAMESPACE:-opendesk}"
KEYCLOAK_POD="ums-keycloak-0"
KEYCLOAK_REALM="${KEYCLOAK_REALM:-opendesk}"
KEYCLOAK_ADMIN_USER="${KEYCLOAK_ADMIN_USER:-kcadmin}"
KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-}"
KCADM="/opt/keycloak/bin/kcadm.sh"

PHASE="${1:-all}"

# Get admin password from K8s secret if not provided
if [ -z "$KEYCLOAK_ADMIN_PASSWORD" ]; then
  KEYCLOAK_ADMIN_PASSWORD=$(kubectl get secret -n "$NAMESPACE" keycloak-admin-password \
    -o jsonpath='{.data.adminPassword}' | base64 -d)
fi

kc_exec() {
  kubectl exec -n "$NAMESPACE" "$KEYCLOAK_POD" -- "$@"
}

kcadm() {
  kc_exec "$KCADM" "$@"
}

echo "=== Keycloak bundID/EUDI Setup ==="
echo "Realm: $KEYCLOAK_REALM"
echo ""

# Authenticate to Keycloak
echo "--- Authenticating to Keycloak ---"
kcadm config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user "$KEYCLOAK_ADMIN_USER" \
  --password "$KEYCLOAK_ADMIN_PASSWORD"

# ============================================
# PHASE 1: bundID SAML Identity Provider
# ============================================
setup_bundid() {
  echo ""
  echo "=== Phase 1: bundID SAML Identity Provider ==="

  # Check if already exists
  EXISTING=$(kcadm get identity-provider/instances -r "$KEYCLOAK_REALM" -q alias=bundid 2>/dev/null)
  if echo "$EXISTING" | grep -q "bundid"; then
    echo "bundID IdP already exists, updating..."
    kcadm update identity-provider/instances/bundid -r "$KEYCLOAK_REALM" -f - <<ENDJSON
{
  "alias": "bundid",
  "displayName": "bundID (Federal ID)",
  "providerId": "saml",
  "enabled": true,
  "config": {
    "entityId": "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk",
    "singleSignOnServiceUrl": "https://id.bund.de/SAML2/POST",
    "singleLogoutServiceUrl": "https://id.bund.de/SAML2/SLO",
    "nameIDPolicyFormat": "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
    "principalType": "NameID",
    "storeToken": "true",
    "addReadTokenRoleOnCreate": "true",
    "authnContextClassRefs": "[\"https://www.bundid.de/loa/high\"]",
    "syncMode": "IMPORT",
    "updateProfileFirstLogin": "true",
    "trustEmail": "false",
    "addReadTokenRoleOnCreate": "true"
  }
}
ENDJSON
  else
    echo "Creating bundID IdP..."
    kcadm create identity-provider/instances -r "$KEYCLOAK_REALM" -f - <<ENDJSON
{
  "alias": "bundid",
  "displayName": "bundID (Federal ID)",
  "providerId": "saml",
  "enabled": true,
  "config": {
    "entityId": "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk",
    "singleSignOnServiceUrl": "https://id.bund.de/SAML2/POST",
    "singleLogoutServiceUrl": "https://id.bund.de/SAML2/SLO",
    "nameIDPolicyFormat": "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
    "principalType": "NameID",
    "storeToken": "true",
    "addReadTokenRoleOnCreate": "true",
    "authnContextClassRefs": "[\"https://www.bundid.de/loa/high\"]",
    "syncMode": "IMPORT",
    "updateProfileFirstLogin": "true",
    "trustEmail": "false",
    "addReadTokenRoleOnCreate": "true"
  }
}
ENDJSON
  fi

  # Export SP metadata for bundID registration
  echo ""
  echo "--- Exporting SP metadata for bundID registration ---"
  kc_exec curl -s "http://localhost:8080/realms/${KEYCLOAK_REALM}/broker/bundid/endpoint/descriptor" \
    > /tmp/bundid-sp-metadata.xml 2>/dev/null
  echo "SP metadata saved to /tmp/bundid-sp-metadata.xml"
  echo "This file must be uploaded to FITKO/BSI for bundID registration."
}

# ============================================
# PHASE 2: EUDI Wallet SIOP / OIDC4VP
# ============================================
setup_eudi() {
  echo ""
  echo "=== Phase 2: EUDI Wallet SIOP/OIDC4VP ==="

  # Check if OID4VC is enabled
  VCI_ENABLED=$(kcadm get serverinfo -r "$KEYCLOAK_REALM" 2>/dev/null | \
    python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('features',{}).get('oid4vc-vci','false'))" 2>/dev/null || echo "unknown")

  if [ "$VCI_ENABLED" != "true" ]; then
    echo ""
    echo "WARNING: OID4VC features are NOT enabled in Keycloak."
    echo "To enable, add these environment variables to the Keycloak deployment:"
    echo "  KC_SPI_OID4VC_VCI_ENABLED=true"
    echo "  KC_SPI_OID4VC_SIOP_ENABLED=true"
    echo ""
    echo "Run: kubectl set env deployment/ums-keycloak -n $NAMESPACE \\"
    echo "  KC_SPI_OID4VC_VCI_ENABLED=true \\"
    echo "  KC_SPI_OID4VC_SIOP_ENABLED=true"
    echo ""
    echo "Then restart: kubectl rollout restart deployment/ums-keycloak -n $NAMESPACE"
    echo "And re-run this script."
    return 1
  fi

  # Create SIOP client for EUDI Wallet
  echo "--- Creating EUDI Wallet client (SIOP) ---"
  kcadm create clients -r "$KEYCLOAK_REALM" -f - <<ENDJSON
{
  "clientId": "eudi-wallet",
  "name": "EUDI Wallet",
  "enabled": true,
  "protocol": "openid-connect",
  "publicClient": true,
  "standardFlowEnabled": true,
  "redirectUris": ["openid4vp://callback"],
  "attributes": {
    "oid4vc.siop.enabled": "true",
    "oid4vc.siop.presentationDefinition": "{\"id\":\"student-id-request\",\"input_descriptors\":[{\"id\":\"student-id\",\"name\":\"Student ID Credential\",\"purpose\":\"Verify student identity\",\"constraints\":{\"fields\":[{\"path\":[\"$.vc.credentialSubject.studentId\"]}]}}]}"
  }
}
ENDJSON
  echo "EUDI Wallet client created."

  # Create authentication flow for SIOP
  echo "--- Creating SIOP authentication flow ---"
  kcadm create authentication/flows -r "$KEYCLOAK_REALM" -f - <<ENDJSON
{
  "alias": "eudi-siop-browser",
  "providerId": "basic-flow",
  "topLevel": true,
  "builtIn": false,
  "authenticationExecutions": [
    {
      "authenticator": "auth-username-password-form",
      "requirement": "REQUIRED",
      "priority": 10
    },
    {
      "authenticator": "idp-create-or-link-user",
      "requirement": "ALTERNATIVE",
      "priority": 20
    }
  ]
}
ENDJSON
  echo "SIOP flow created."
}

# ============================================
# Execute phases
# ============================================
case "$PHASE" in
  1) setup_bundid ;;
  2) setup_eudi ;;
  all)
    setup_bundid
    setup_eudi
    ;;
  *)
    echo "Usage: $0 [1|2|all]"
    exit 1
    ;;
esac

echo ""
echo "=== Done ==="
echo "Phase $PHASE completed."
echo ""
echo "Next steps:"
echo "  Phase 1: Upload /tmp/bundid-sp-metadata.xml to FITKO/BSI"
echo "  Phase 2: Enable OID4VC features, then re-run with: $0 2"
echo "  Phase 3: Deploy EUDI Issuer service (helmfile)"

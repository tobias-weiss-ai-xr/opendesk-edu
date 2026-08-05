#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BACKCHANNEL_NEXTCLOUD_URL:-https://nc.example.org}"
TOKEN_CANDIDATE="${LOGOUT_TOKEN:-}"
INVALID_TOKEN="${INVALID_LOGOUT_TOKEN:-"invalid-token"}"

echo "[Task-5] Testing Nextcloud OIDC backchannel logout at ${BASE_URL}"

if [[ -z "${TOKEN_CANDIDATE}" ]]; then
  echo "WARN: LOGOUT_TOKEN not set. Skipping valid-token test."
else
  echo "Running valid-token test..."
  HTTP_CODE=$(curl -sS -k -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/apps/user_oidc/backchannel_logout" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "logout_token=${TOKEN_CANDIDATE}")
  echo "Valid-token HTTP status: ${HTTP_CODE}"
fi

echo "Running invalid-token test..."
  HTTP_CODE_INVALID=$(curl -sS -k -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/apps/user_oidc/backchannel_logout" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "logout_token=${INVALID_TOKEN}")
  echo "Invalid-token HTTP status: ${HTTP_CODE_INVALID}"

echo "Done."

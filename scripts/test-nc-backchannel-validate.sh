#!/usr/bin/env bash
set -euo pipefail

# Validate Nextcloud OIDC backchannel logout with a real logout_token
BASE_URL="${1:-${BACKCHANNEL_NEXTCLOUD_URL:-https://nc.example.org}}"
TOKEN="${2:-${LOGOUT_TOKEN:-}}"

if [[ -z "$TOKEN" ]]; then
  echo "ERROR: Provide a logout_token as the second argument or set LOGOUT_TOKEN env variable."
  exit 2
fi

echo "[Task-5] Validating Nextcloud backchannel logout with token on $BASE_URL"
HTTP_CODE=$(curl -sS -k -o /dev/null -w "%{http_code}" \
  "$BASE_URL/apps/user_oidc/backchannel_logout" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "logout_token=${TOKEN}")
echo "HTTP code: ${HTTP_CODE}"
exit 0

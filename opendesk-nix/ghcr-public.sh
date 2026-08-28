#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
# =============================================================================
# Mark ghcr.io/opendesk-edu/* packages as PUBLIC via the GitHub API.
#
# Public = anonymous pulls (no token needed) – required for the public mirror
# of the ghcr.io/tobias-weiss-ai-xr/umr/opendesk-edu/containers images.
#
# Prerequisites (one of):
#   - gh CLI authenticated with a token that has  `packages: read+write`
#     on the opendesk-edu org (classic PAT `write:packages` + `read:org`,
#     or fine-grained PAT with Packages write on the org) – recommended:
#       gh auth login --scopes read:org,write:packages,read:packages
#   - GH_TOKEN env var set to such a token
#
# NOTE: The most robust one-time setup is the ORGANIZATION default:
#   GitHub -> opendesk-edu org -> Settings -> Packages
#   -> "Default repository visibility" / container packages default = PUBLIC
# Then every new package is public automatically and this script is only
# needed for already-private packages.
#
# Usage:
#   ./ghcr-public.sh                # sogo sogo6 stalwart opencloud
#   ./ghcr-public.sh sogo opencloud # explicit list
#   GHCR_ORG=opendesk-edu ./ghcr-public.sh
# =============================================================================

set -euo pipefail

ORG="${GHCR_ORG:-opendesk-edu}"
PKGS=("${@:-sogo sogo6 stalwart opencloud}")

for p in "${PKGS[@]}"; do
  echo "== set PUBLIC: ghcr.io/${ORG}/${p}"
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh api -X POST "/orgs/${ORG}/packages/container/${p}/visibility" \
      -f visibility=public \
      --jq '{visibility: .visibility, package_type: .package_type, name: .name}' 2>&1 \
      || echo "   (⚠️  gh fehlt packages-Scope oder Paket existiert nicht – siehe Hilfe oben)"
  elif [ -n "${GH_TOKEN:-}" ]; then
    curl -s -X POST \
      -H "Authorization: Bearer ${GH_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/orgs/${ORG}/packages/container/${p}/visibility" \
      -d '{"visibility":"public"}'
    echo
  else
    echo "   ✗ kein Auth: gh einloggen (packages-Scope) oder GH_TOKEN setzen"
    exit 1
  fi
done

echo
echo "Done. Verify anonymously:"
echo "  curl -s https://ghcr.io/v2/$ORG/<image>/tags/list  (braucht Token-Dance)"
echo "  skopeo inspect docker://ghcr.io/$ORG/<image>:latest"

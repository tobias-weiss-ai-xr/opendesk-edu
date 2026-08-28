#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
# =============================================================================
# Push Nix-built openDesk Edu images to BOTH registries:
#   - ghcr.io/tobias-weiss-ai-xr/umr/opendesk-edu/containers    (primary, sovereign)   [needs OPENCODE_TOKEN]
#   - ghcr.io/opendesk-edu        (public mirror)        [needs GHCR token]
#
# Public availability strategy:
#   registry.opencode.de is the EU-sovereign source of truth; ghcr.io mirrors
#   the exact same tags so clusters / users without opencode.access can pull
#   anonymously. Keep both registries in sync via this script or the
#   .github/workflows/nix-images.yml pipeline (GITHUB_TOKEN handles GHCR).
#
# Usage:
#   ./push-images.sh [--dry-run] [image...]
#
# Examples:
#   ./push-images.sh                     # all four repos, version + latest
#   ./push-images.sh --dry-run          # show what would be pushed
#   ./push-images.sh opencloud          # only opencloud
#
# Prerequisites:
#   docker login registry.opencode.de -u <user>     (PAT with write_registry)
#   docker login ghcr.io -u <user>                  (PAT / GITHUB_TOKEN)
# =============================================================================

set -euo pipefail

OPENCODE_REG="${OPENCODE_REGISTRY:-ghcr.io/tobias-weiss-ai-xr/umr/opendesk-edu/containers}"
GHCR_REG="${GHCR_REGISTRY:-ghcr.io/opendesk-edu}"

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then DRY_RUN=1; shift; fi

# local-image|version|repo  (repo on BOTH registries)
DEFAULTS=(
  "sogo6|5.12.10|sogo"
  "sogo6|5.12.10|sogo6"
  "stalwart|0.16.17|stalwart"
  "opencloud|7.2.2|opencloud"
)

ENTRIES=()
if [ "$#" -gt 0 ]; then
  for sel in "$@"; do
    for e in "${DEFAULTS[@]}"; do
      IFS='|' read -r _ _ repo <<< "$e"
      [ "$repo" = "$sel" ] && ENTRIES+=("$e")
    done
  done
else
  ENTRIES=("${DEFAULTS[@]}")
fi

if [ "$DRY_RUN" = "1" ]; then
  echo "== DRY RUN =="
fi

for entry in "${ENTRIES[@]}"; do
  IFS='|' read -r localimg tag repo <<< "$entry"
  for reg in "$OPENCODE_REG" "$GHCR_REG"; do
    for t in "$tag" latest; do
      echo "==> $reg/$repo:$t  (from $localimg:$tag)"
      if [ "$DRY_RUN" = "1" ]; then continue; fi
      docker tag "$localimg:$tag" "$reg/$repo:$t"
      docker push "$reg/$repo:$t"
    done
  done
done

echo
echo "Done. Registries in sync:"
echo "  $OPENCODE_REG/{sogo,sogo6,stalwart,opencloud}:{version,latest}"
echo "  $GHCR_REG/{sogo,sogo6,stalwart,opencloud}:{version,latest}"

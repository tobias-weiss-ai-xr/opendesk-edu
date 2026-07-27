#!/bin/bash
# deploy-opencloud.sh — Deploy OpenCloud (Nextcloud with OIDC)
# Part of openDesk Edu deployment
#
# Usage: ./deploy-opencloud.sh [--diff] [--verbose] [--help]
#
# This script deploys OpenCloud via the edu helmfile.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELMFILE_DIR="$SCRIPT_DIR/../helmfile"

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --diff       Dry-run: show changes without applying"
  echo "  --verbose    Enable verbose output"
  echo "  --help       Show this help"
  echo ""
  echo "Environment variables:"
  echo "  ENVIRONMENT  Deployment environment (default: edu)"
  echo ""
  echo "Examples:"
  echo "  $0                         # Deploy OpenCloud"
  echo "  $0 --diff                  # Preview changes"
  echo "  ENVIRONMENT=edu-test $0    # Deploy to edu-test"
  exit 0
}

# --- Parse arguments ---
DIFF=false
VERBOSE=false
ENVIRONMENT="${ENVIRONMENT:-edu}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --diff)     DIFF=true; shift ;;
    --verbose)  VERBOSE=true; shift ;;
    --help)     usage ;;
    *)          echo "Error: Unknown option $1" >&2; usage ;;
  esac
done

# --- Validate environment ---
if [[ ! -d "$HELMFILE_DIR/environments/$ENVIRONMENT" ]]; then
  echo "Error: Environment '$ENVIRONMENT' not found at $HELMFILE_DIR/environments/$ENVIRONMENT" >&2
  exit 1
fi

# --- Build helmfile command ---
HELMFILE_OPTS=()
[[ "$VERBOSE" == true ]] && HELMFILE_OPTS+=(--log-level debug)
ACTION="sync"
[[ "$DIFF" == true ]] && ACTION="diff"

# Determine domain from ce-overrides
DOMAIN=$(grep 'domain:' "$HELMFILE_DIR/environments/$ENVIRONMENT/ce-overrides.yaml" 2>/dev/null | head -1 | awk '{print $2}' || echo "opendesk.hrz.uni-marburg.de")

echo "========================================="
echo " OpenCloud — Deploy ($ENVIRONMENT)"
echo " Domain: $DOMAIN"
echo " Action: $ACTION"
echo "========================================="

# Deploy via edu helmfile (component filter)
cd "$HELMFILE_DIR"
helmfile ${HELMFILE_OPTS[*]} -f edu-helmfile.yaml.gotmpl \
  -e "$ENVIRONMENT" \
  -l "component=opencloud" \
  $ACTION

# === Summary ===
if [[ "$DIFF" == true ]]; then
  echo ""
  echo "========================================="
  echo " OpenCloud — diff complete (no changes applied)"
  echo "========================================="
else
  echo ""
  echo "========================================="
  echo " ✅ OpenCloud deployment complete!"
  echo ""
  echo " Access OpenCloud at:"
  echo "   Web UI:  https://files.$DOMAIN"
  echo ""
  echo " OIDC Configuration:"
  echo "   Issuer:    https://id.$DOMAIN/realms/opendesk"
  echo "   Client ID: opendesk-opencloud"
  echo ""
  echo " Verify with:"
  echo "   kubectl get pods -n opendesk -l app.kubernetes.io/name=opencloud"
  echo "   kubectl logs -n opendesk -l app.kubernetes.io/name=opencloud"
  echo "   curl -sk https://files.$DOMAIN/status.php"
  echo "========================================="
fi

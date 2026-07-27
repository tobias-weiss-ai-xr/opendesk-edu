#!/bin/bash
# deploy-stalwart-opencloud.sh — Deploy Stalwart and/or OpenCloud
# Part of openDesk Edu deployment
#
# Usage: ./deploy-stalwart-opencloud.sh [--diff] [--stalwart] [--opencloud] [--verbose]
#
# Deploy both Stalwart Mail Server and OpenCloud, or individual services.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELMFILE_DIR="$SCRIPT_DIR/../helmfile"

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --diff       Dry-run: show changes without applying"
  echo "  --verbose    Enable verbose output"
  echo "  --stalwart   Deploy only Stalwart"
  echo "  --opencloud  Deploy only OpenCloud"
  echo "  --help       Show this help"
  echo ""
  echo "If neither --stalwart nor --opencloud is given, both are deployed."
  echo ""
  echo "Environment variables:"
  echo "  ENVIRONMENT  Deployment environment (default: edu)"
  exit 0
}

# --- Parse arguments ---
DIFF=false
VERBOSE=false
DEPLOY_STALWART=false
DEPLOY_OPENCLOUD=false
ENVIRONMENT="${ENVIRONMENT:-edu}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --diff)      DIFF=true; shift ;;
    --verbose)   VERBOSE=true; shift ;;
    --stalwart)  DEPLOY_STALWART=true; shift ;;
    --opencloud) DEPLOY_OPENCLOUD=true; shift ;;
    --help)      usage ;;
    *)           echo "Error: Unknown option $1" >&2; usage ;;
  esac
done

# If no specific service selected, deploy both
if [[ "$DEPLOY_STALWART" == false && "$DEPLOY_OPENCLOUD" == false ]]; then
  DEPLOY_STALWART=true
  DEPLOY_OPENCLOUD=true
fi

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

DOMAIN=$(grep 'domain:' "$HELMFILE_DIR/environments/$ENVIRONMENT/ce-overrides.yaml" 2>/dev/null | head -1 | awk '{print $2}' || echo "opendesk.hrz.uni-marburg.de")

echo "========================================="
echo " openDesk Edu — Deploy Services ($ENVIRONMENT)"
echo " Domain: $DOMAIN"
echo " Action: $ACTION"
echo "========================================="

cd "$HELMFILE_DIR"

# --- Deploy Stalwart ---
if [[ "$DEPLOY_STALWART" == true ]]; then
  echo ""
  echo "--- Deploying Stalwart Mail Server ---"
  helmfile ${HELMFILE_OPTS[*]} -f edu-helmfile.yaml.gotmpl \
    -e "$ENVIRONMENT" \
    -l "component=stalwart" \
    $ACTION
fi

# --- Deploy OpenCloud ---
if [[ "$DEPLOY_OPENCLOUD" == true ]]; then
  echo ""
  echo "--- Deploying OpenCloud ---"
  helmfile ${HELMFILE_OPTS[*]} -f edu-helmfile.yaml.gotmpl \
    -e "$ENVIRONMENT" \
    -l "component=opencloud" \
    $ACTION
fi

# === Summary ===
echo ""
echo "========================================="
if [[ "$DIFF" == true ]]; then
  echo " ✅ Diff complete (no changes applied)"
else
  echo " ✅ Deployment complete!"
fi
echo ""

if [[ "$DEPLOY_STALWART" == true ]]; then
  echo " Stalwart Mail Server:"
  echo "   Admin:  https://mail.$DOMAIN"
  echo "   IMAP:   mail.$DOMAIN:993"
  echo "   SMTP:   mail.$DOMAIN:465"
  echo "   Pods:   kubectl get pods -n opendesk -l app.kubernetes.io/name=stalwart"
fi

if [[ "$DEPLOY_OPENCLOUD" == true ]]; then
  echo ""
  echo " OpenCloud:"
  echo "   Web UI: https://files.$DOMAIN"
  echo "   Status: curl -sk https://files.$DOMAIN/status.php"
  echo "   OIDC:   https://id.$DOMAIN/realms/opendesk"
  echo "   Pods:   kubectl get pods -n opendesk -l app.kubernetes.io/name=opencloud"
fi

echo ""
echo " Logs: kubectl logs -n opendesk -l app.kubernetes.io/name=<service>"
echo "========================================="

#!/bin/bash
# deploy-opencloud.sh — Deploy OpenCloud (Nextcloud with OIDC)
# Part of openDesk Edu deployment

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
  exit 0
}

# Parse arguments
DIFF=false
VERBOSE=false
ENVIRONMENT="edu"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --diff)
      DIFF=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --help)
      usage
      ;;
    *)
      echo "Error: Unknown option $1" >&2
      usage
      ;;
  esac
done

# Validate environment
if [[ ! -d "$HELMFILE_DIR/environments/$ENVIRONMENT" ]]; then
  echo "Error: Environment '$ENVIRONMENT' not found" >&2
  exit 1
fi

# Build helmfile command
HELMFILE_OPTIONS=()
if [[ "$VERBOSE" == true ]]; then
  HELMFILE_OPTIONS+=(--log-level debug)
fi

if [[ "$DIFF" == true ]]; then
  ACTION="diff"
else
  ACTION="sync"
fi

cd "$HELMFILE_DIR"

echo "========================================="
echo "Deploying OpenCloud ($ENVIRONMENT)"
echo "========================================="

# Deploy OpenCloud via edu-helmfile
# The edu-helmfile includes the opencloud helmfile-child
echo ""
echo "--- Deploying OpenCloud ---"

# First, ensure CE base is deployed
cd "$HELMFILE_DIR/ce"
echo "Deploying CE base..."
helmfile ${HELMFILE_OPTIONS[*]} -f helmfile.yaml.gotmpl \
  --values "../environments/$ENVIRONMENT/ce-overrides.yaml" \
  --values "../environments/$ENVIRONMENT/secrets.yaml" \
  --values "../environments/$ENVIRONMENT/images.yaml" \
  $ACTION

# Then deploy edu overlay with OpenCloud
cd "$HELMFILE_DIR"
echo "Deploying edu overlay with OpenCloud..."
helmfile ${HELMFILE_OPTIONS[*]} -f edu-helmfile.yaml.gotmpl \
  -e "$ENVIRONMENT" \
  -l "component=opencloud" \
  $ACTION

if [[ "$DIFF" == true ]]; then
  echo ""
  echo "========================================="
  echo "OpenCloud deployment diff complete"
  echo "(no changes applied)"
  echo "========================================="
else
  echo ""
  echo "========================================="
  echo "OpenCloud deployment complete!"
  echo ""
  DOMAIN=$(grep domain ../helmfile/environments/$ENVIRONMENT/ce-overrides.yaml | head -1 | cut -d' ' -f2)
  echo "Access OpenCloud at:"
  echo "  Web: https://files.$DOMAIN"
  echo ""
  echo "OIDC Configuration:"
  echo "  Issuer: https://portal.$DOMAIN/realms/opendesk"
  echo "  Client ID: opendesk-opencloud"
  echo ""
  echo "Check status:"
  echo "  kubectl get pods -l component=opencloud"
  echo "  kubectl logs -f deployment/opendesk-opencloud"
  echo ""
  echo "Verify OIDC login:"
  echo "  Visit https://files.$DOMAIN"
  echo "  You should be redirected to Keycloak for authentication"
  echo "========================================="
fi

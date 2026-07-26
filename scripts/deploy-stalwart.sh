#!/bin/bash
# deploy-stalwart.sh — Deploy Stalwart Mail Server
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
echo "Deploying Stalwart Mail Server ($ENVIRONMENT)"
echo "========================================="

# Deploy Stalwart via edu-helmfile
# The edu-helmfile includes the stalwart helmfile-child
echo ""
echo "--- Deploying Stalwart ---"

# First, ensure CE base is deployed
cd "$HELMFILE_DIR/ce"
echo "Deploying CE base..."
helmfile ${HELMFILE_OPTIONS[*]} -f helmfile.yaml.gotmpl \
  --values "../environments/$ENVIRONMENT/ce-overrides.yaml" \
  --values "../environments/$ENVIRONMENT/secrets.yaml" \
  --values "../environments/$ENVIRONMENT/images.yaml" \
  $ACTION

# Then deploy edu overlay with Stalwart
cd "$HELMFILE_DIR"
echo "Deploying edu overlay with Stalwart..."
helmfile ${HELMFILE_OPTIONS[*]} -f edu-helmfile.yaml.gotmpl \
  -e "$ENVIRONMENT" \
  -l "component=stalwart" \
  $ACTION

if [[ "$DIFF" == true ]]; then
  echo ""
  echo "========================================="
  echo "Stalwart deployment diff complete"
  echo "(no changes applied)"
  echo "========================================="
else
  echo ""
  echo "========================================="
  echo "Stalwart deployment complete!"
  echo ""
  echo "Accessantilwart at:"
  echo "  Admin Console: https://mail.$(grep domain ../helmfile/environments/$ENVIRONMENT/ce-overrides.yaml | head -1 | cut -d' ' -f2)"
  echo "  IMAP:      mail.$(grep domain ../helmfile/environments/$ENVIRONMENT/ce-overrides.yaml | head -1 | cut -d' ' -f2):993"
  echo "  SMTP:      mail.$(grep domain ../helmfile/environments/$ENVIRONMENT/ce-overrides.yaml | head -1 | cut -d' ' -f2):465"
  echo ""
  echo "Check status:"
  echo "  kubectl get pods -l component=stalwart"
  echo "  kubectl logs -f deployment/stalwart"
  echo "========================================="
fi

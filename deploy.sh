#!/bin/bash
# deploy.sh — Deploy openDesk CE + edu overlay
# Usage:
#   ./deploy.sh [environment]        — Deploy environment (default: edu)
#   ./deploy.sh --diff [environment]  — Dry-run, show changes (no apply)
#   ./deploy.sh --diff edu           — Show changes for edu environment
#   ./deploy.sh --verbose [env]       — Enable helmfile debug output
#   ./deploy.sh --help                — Show this help
#
# Environments:
#   edu       — Production (default)
#   edu-test  — Test/staging

set -euo pipefail

# --- Parse arguments ---
DIFF=false
VERBOSE=false
ENVIRONMENT=""

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
      echo "Usage: ./deploy.sh [options] [environment]"
      echo ""
      echo "Options:"
      echo "  --diff       Dry-run: show changes without applying"
      echo "  --verbose    Enable helmfile debug output"
      echo "  --help       Show this help"
      echo ""
      echo "Environments:"
      echo "  edu          Production environment (default)"
      echo "  edu-test     Test/staging environment"
      echo ""
      echo "Examples:"
      echo "  ./deploy.sh                    Deploy edu"
      echo "  ./deploy.sh edu-test           Deploy edu-test"
      echo "  ./deploy.sh --diff             Show diff for edu"
      echo "  ./deploy.sh --diff edu-test    Show diff for edu-test"
      exit 0
      ;;
    *)
      if [[ -n "$ENVIRONMENT" ]]; then
        echo "Error: Multiple environments specified: $ENVIRONMENT and $1" >&2
        echo "Usage: ./deploy.sh [options] [environment]" >&2
        exit 1
      fi
      ENVIRONMENT="$1"
      shift
      ;;
  esac
done

ENVIRONMENT="${ENVIRONMENT:-edu}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Validate environment ---
if [[ ! -d "$SCRIPT_DIR/helmfile/environments/$ENVIRONMENT" ]]; then
  echo "Error: Environment '$ENVIRONMENT' not found at helmfile/environments/$ENVIRONMENT/" >&2
  echo "Available environments:" >&2
  for d in "$SCRIPT_DIR"/helmfile/environments/*/; do
    echo "  - $(basename "$d")" >&2
  done
  exit 1
fi

# --- Helmfile flags ---
HELMFILE_OPTS=()
if $VERBOSE; then
  HELMFILE_OPTS+=(--log-level debug)
fi

HELMFILE_CMD="helmfile ${HELMFILE_OPTS[*]}"
if $DIFF; then
  HELMFILE_CMD="$HELMFILE_CMD diff"
else
  HELMFILE_CMD="$HELMFILE_CMD sync"
fi

echo "=== Step 1: Deploy CE ($ENVIRONMENT overrides) ==="
cd "$SCRIPT_DIR/helmfile/ce"

$HELMFILE_CMD -f helmfile.yaml.gotmpl \
  --values "../environments/$ENVIRONMENT/ce-overrides.yaml" \
  --values "../environments/$ENVIRONMENT/secrets.yaml" \
  --values "../environments/$ENVIRONMENT/images.yaml"

echo "=== Step 2: Deploy edu apps ($ENVIRONMENT) ==="
cd "$SCRIPT_DIR"

$HELMFILE_CMD -f helmfile/edu-helmfile.yaml.gotmpl \
  -e "$ENVIRONMENT"

if $DIFF; then
  echo "=== Diff complete (no changes applied) ==="
else
  echo "=== Deploy complete ==="
fi

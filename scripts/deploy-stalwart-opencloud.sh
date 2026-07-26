#!/bin/bash
# deploy-stalwart-opencloud.sh — Deploy both Stalwart and OpenCloud together
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
  echo "  --stalwart   Deploy only Stalwart"
  echo "  --opencloud  Deploy only OpenCloud"
  echo "  --help       Show this help"
  echo ""
  echo "Environment variables:"
  echo "  ENVIRONMENT  Deployment environment (default: edu)"
  exit 0
}

# Parse arguments
DIFF=false
VERBOSE=false
DEPLOY_STALWART=true
DEPLOY_OPENCLOUD=true
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
    --stalwart)
      DEPLOY_OPENCLOUD=false
      shift
      ;;
    --opencloud)
      DEPLOY_STALWART=false
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

# Build helmfile options
HELMFILE_OPTIONS=()
if [[ "$VERBOSE" == true ]]; then
  HELMFILE_OPTIONS+=(--log-level debug)
fi

ACTION="sync"
if [[ "$DIFF" == true ]]; then
  ACTION="diff"
fi

cd "$HELMFILE_DIR"

echo "========================================="
echo "Deploying Services ($ENVIRONMENT)"
echo "========================================="

# Deploy CE base first
cd "$HELMFILE_DIR/ce"
echo ""
echo "--- Step 1: Deploying CE base ---"
helmfile ${HELMFILE_OPTIONS[*]} -f helmfile.yaml.gotmpl \
  --values "../environments/$ENVIRONMENT/ce-overrides.yaml" \
  --values "../environments/$ENVIRONMENT/secrets.yaml" \
  --values "../environments/$ENVIRONMENT/images.yaml" \
  $ACTION

# Deploy edu overlay with selected services
cd "$HELMFILE_DIR"

if [[ "$DEPLOY_STALWART" == true ]]; then
  echo ""
  echo "--- Step 2: Deploying Stalwart Mail Server ---"
  helmfile ${HELMFILE_OPTIONS[*]} -f edu-helmfile.yaml.gotmpl \
    -e "$ENVIRONMENT" \
    -l "component=stalwart" \
    $ACTION
fi

if [[ "$DEPLOY_OPENCLOUD" == true ]]; then
  echo ""
  echo "--- Step 3: Deploying OpenCloud ---"
  helmfile ${HELMFILE_OPTIONS[*]} -f edu-helmfile.yaml.gotmpl \
    -e "$ENVIRONMENT" \
    -l "component=opencloud" \
    $ACTION
fi

# Summary
if [[ "$DIFF" == true ]]; then
  echo ""
  echo "========================================="
  if [[ "$DEPLOY_STALWART" == true && "$DEPLOY_OPENCLOUD" == true ]]; then
    echo "Stalwart + OpenCloud deployment diff complete"
  elif [[ "$DEPLOY_STALWART" == true ]]; then
    echo "Stalwart deployment diff complete"
  else
    echo "OpenCloud deployment diff complete"
  fi
  echo "(no changes applied)"
  echo "========================================="
else
  echo ""
  echo "========================================="
  if [[ "$DEPLOY_STALWART" == true && "$DEPLOY_OPENCLOUD" == true ]]; then
    echo "Stalwart + OpenCloud deployment complete!"
  elif [[ "$DEPLOY_STALWART" == true ]]; then
    echo "Stalwart deployment complete!"
  else
    echo "OpenCloud deployment complete!"
  fi
  echo ""
  
  DOMAIN=$(grep domain ../helmfile/environments/$ENVIRONMENT/ce-overrides.yaml | head -1 | cut -d' ' -f2)
  
  if [[ "$DEPLOY_STALWART" == true ]]; then
    echo "Stalwart Mail Server:"
    echo "  Admin Console: https://mail.$DOMAIN"
    echo "  IMAP:         mail.$DOMAIN:993"
    echo "  SMTP:         mail.$DOMAIN:465"
    echo ""
    echo "Stalwart status:"
    echo "  kubectl get pods -l component=stalwart"
    echo "  kubectl logs -f deployment/stalwart"
  fi
  
  if [[ "$DEPLOY_OPENCLOUD" == true ]]; then
    echo "OpenCloud:"
    echo "  Web: https://files.$DOMAIN"
    echo ""
    echo "OpenCloud status:"
    echo "  kubectl get pods -l component=opencloud"
    echo "  kubectl logs -f deployment/opendesk-opencloud"
  fi
  
  echo ""
  echo "Verify services:"
  if [[ "$DEPLOY_STALWART" == true ]]; then
    echo "  curl -k https://mail.$DOMAIN/api/health"
  fi
  if [[ "$DEPLOY_OPENCLOUD" == true ]]; then
    echo "  curl -k https://files.$DOMAIN/status.php"
  fi
  echo "========================================="
fi

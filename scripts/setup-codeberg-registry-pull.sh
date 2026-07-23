#!/bin/bash
# openDesk Edu — Create K8s pull secret for Codeberg Container Registry
# Usage: ./setup-codeberg-registry-pull.sh [namespace]
# Requires: kubectl, logged-in cluster context
set -euo pipefail

NAMESPACE="${1:-opendesk}"
SECRET_NAME="codeberg-registry-pull"

echo "=== Codeberg Container Registry Pull Secret ==="
echo "Namespace: ${NAMESPACE}"
echo ""

# Determine token source
if [ -n "${CI_REGISTRY_TOKEN:-}" ]; then
  TOKEN="${CI_REGISTRY_TOKEN}"
  echo "Using CI_REGISTRY_TOKEN from environment"
elif [ -n "${CODEPAT:-}" ]; then
  TOKEN="${CODEPAT}"
  echo "Using CODEPAT from environment"
else
  echo "No token found in environment."
  echo ""
  echo "Provide a Codeberg access token with 'write:packages' scope:"
  read -r -s -p "Codeberg token: " TOKEN
  echo ""
fi

if [ -z "${TOKEN:-}" ]; then
  echo "ERROR: No token provided." >&2
  exit 1
fi

# Registry auth secret
kubectl create secret docker-registry "${SECRET_NAME}" \
  --namespace "${NAMESPACE}" \
  --docker-server="codeberg.org" \
  --docker-username="${CI_REPO_OWNER:-opendesk-edu}" \
  --docker-password="${TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "Secret '${SECRET_NAME}' created in namespace '${NAMESPACE}'."

# Show usage instructions
echo ""
echo "To use this secret in a deployment, add to the pod spec:"
echo ""
echo "  imagePullSecrets:"
echo "    - name: ${SECRET_NAME}"
echo ""
echo "Or patch the default service account:"
echo ""
echo "  kubectl patch serviceaccount default \\"
echo "    -n ${NAMESPACE} -p '{\"imagePullSecrets\": [{\"name\": \"${SECRET_NAME}\"}]}'"

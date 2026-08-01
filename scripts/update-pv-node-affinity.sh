#!/bin/bash
set -e

NAMESPACE="${NAMESPACE:-opendesk}"

# PVC:node mappings - Update this array with actual PVC:node mappings
declare -A pvc_nodes=(
  ["openproject-web-96cd98989-225f2-app-tmp"]="vhrz2337"
  ["openproject-web-96cd98989-225f2-tmp"]="vhrz2337"
  ["openproject-worker-default-69876b87-8qbnv-app-tmp"]="vhrz2336"
  ["openproject-worker-default-69876b87-8qbnv-tmp"]="vhrz2336"
)

echo "Adding node affinity to PVs in namespace: $NAMESPACE"
echo "---------------------------------------------------"

for pvc in "${!pvc_nodes[@]}"; do
  node="${pvc_nodes[$pvc]}"

  pv=$(kubectl get pvc "$pvc" -n "$NAMESPACE" -o jsonpath='{.spec.volumeName}' 2>/dev/null || true)
  
  if [ -z "$pv" ]; then
    echo "⚠️  Skipping $pvc - PVC not found in namespace $NAMESPACE"
    continue
  fi
  
  echo "→ PVC: $pvc"
  echo "  PV: $pv"
  echo "  Target Node: $node"

  kubectl patch pv "$pv" -p "{
    \"spec\": {
      \"nodeAffinity\": {
        \"required\": {
          \"nodeSelectorTerms\": [
            {
              \"matchExpressions\": [
                {
                  \"key\": \"kubernetes.io/hostname\",
                  \"operator\": \"In\",
                  \"values\": [\"$node\"]
                }
              ]
            }
          ]
        }
      }
    }
  }" --type=merge
  
  if [ $? -eq 0 ]; then
    echo "  ✅ Node affinity added successfully"
  else
    echo "  ❌ Failed to add node affinity"
    exit 1
  fi
  echo ""
done

echo "---------------------------------------------------"
echo "✅ All PV node affinity updates completed"
echo ""
echo "To verify:"
echo "  kubectl get pv -o jsonpath='{range .items[*]}{.metadata.name}: {.spec.nodeAffinity}{\"\\n\"}{end}'"
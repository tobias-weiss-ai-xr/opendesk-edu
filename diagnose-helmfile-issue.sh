#!/bin/bash
# Helmfile Diagnostic Script
# This script helps diagnose and isolate the helmfile recursion/template issue
# Usage: ./diagnose-helmfile-issue.sh

set -euo pipefail

echo "========================================"
echo "Helmfile Diagnostic Script"
echo "========================================"
echo ""

# Configuration
HELMFILE_DIR="${HELMFILE_DIR:-/root/opendesk-edu}"
NAMESPACE="${NAMESPACE:-opendesk-edu}"
ENV="${ENV:-prod}"

echo "Configuration:"
echo "  Helmfile Dir: $HELMFILE_DIR"
echo "  Namespace: $NAMESPACE"
echo "  Environment: $ENV"
echo ""

# Check prerequisites
echo "=== Step 1: Prerequisites Check ==="

# Check helmfile version
echo "Helmfile version:"
helmfile version || { echo "❌ helmfile not found"; exit 1; }
echo ""

# Check k3s
echo "K3s status:"
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl cluster-info || { echo "❌ k3s not accessible"; exit 1; }
echo ""

# Check directory exists
if [[ ! -d "$HELMFILE_DIR" ]]; then
  echo "❌ Directory not found: $HELMFILE_DIR"
  exit 1
fi

cd "$HELMFILE_DIR"
echo "✅ Working directory: $(pwd)"
echo ""

# Step 2: Check helmfile files exist
echo "=== Step 2: Helmfile Files Check ==="

FILES=(
  "helmfile.yaml.gotmpl"
  "helmfile_generic.yaml.gotmpl"
)

for file in "${FILES[@]}"; do
  if [[ -f "$file" ]]; then
    echo "✅ $file exists"
  else
    echo "❌ $file not found"
  fi
done
echo ""

# Step 3: Try helmfile template (not apply) to see if it's a template issue
echo "=== Step 3: Helmfile Template Test ==="
echo "Running: helmfile -e prod -n $NAMESPACE template"
echo ""

TEMPLATE_OUTPUT=$(DOMAIN=desk.opendesk-edu.org MAIL_DOMAIN=opendesk-edu.org MATRIX_DOMAIN=desk.opendesk-edu.org \
  helmfile -e $ENV -n $NAMESPACE template 2>&1 || true)

if echo "$TEMPLATE_OUTPUT" | grep -q "Error:"; then
  echo "❌ Helmfile template failed"
  echo ""
  echo "=== ERROR DETAILS ==="
  echo "$TEMPLATE_OUTPUT"
  echo ""
else
  echo "✅ Helmfile template succeeded"
  echo ""
fi

# Step 4: Check for circular references
echo "=== Step 4: Check for Circular References ==="
echo "Searching for helmfile includes..."

echo ""
echo "=== Main helmfile includes ==="
grep -n "path.*helmfile" helmfile.yaml.gotmpl || echo "No includes in root helmfile"

echo ""
echo "=== helmfile_generic includes (first 30) ==="
grep -n "path.*helmfile" helmfile_generic.yaml.gotmpl | head -30 || echo "No includes found"

echo ""

# Step 5: Check template syntax
echo "=== Step 5: Check Template Syntax ==="
echo "Checking for unmatched template brackets..."

# Check main helmfile
echo "helmfile.yaml.gotmpl:"
OPEN_MAIN=$(grep -o '{{' helmfile.yaml.gotmpl | wc -l)
CLOSE_MAIN=$(grep -o '}}' helmfile.yaml.gotmpl | wc -l)
echo "  {{ count: $OPEN_MAIN, }} count: $CLOSE_MAIN"
if [[ $OPEN_MAIN -ne $CLOSE_MAIN ]]; then
  echo "  ⚠️ UNMATCHED BRACKETS in helmfile.yaml.gotmpl"
else
  echo "  ✅ All brackets matched"
fi

# Check helmfile_generic
echo "helmfile_generic.yaml.gotmpl:"
OPEN_GEN=$(grep -o '{{' helmfile_generic.yaml.gotmpl | wc -l)
CLOSE_GEN=$(grep -o '}}' helmfile_generic.yaml.gotmpl | wc -l)
echo "  {{ count: $OPEN_GEN, }} count: $CLOSE_GEN"
if [[ $OPEN_GEN -ne $CLOSE_GEN ]]; then
  echo "  ⚠️ UNMATCHED BRACKETS in helmfile_generic.yaml.gotmpl"
else
  echo "  ✅ All brackets matched"
fi
echo ""

# Step 6: Test values rendering
echo "=== Step 6: Test Values Rendering ==="
echo "Testing if template values render correctly..."

# Test single template expansion
echo "Testing template on a simple file..."
cat > /tmp/test-template.yaml << 'EOF'
---
test:
  value: "{{ .Env.TEST_VAR | default \"default\" }}"
EOF

if DOMAIN=desk.opendesk-edu.org envsubst < /tmp/test-template.yaml > /dev/null 2>&1; then
  echo "✅ Template expansion works"
else
  echo "❌ Template expansion failed"
fi
echo ""

# Step 7: Check environment files
echo "=== Step 7: Check Environment Files ==="

if [[ -d "helmfile/environments/$ENV" ]]; then
  echo "✅ Environment directory exists: helmfile/environments/$ENV"
  echo ""
  echo "Files in environment:"
  ls -la helmfile/environments/$ENV/*.yaml.gotmpl 2>/dev/null || echo "No value files found"
else
  echo "❌ Environment directory not found: helmfile/environments/$ENV"
fi
echo ""

# Step 8: Create minimal diagnostic helmfile
echo "=== Step 8: Create Minimal Helmfile Test ==="

cat > /tmp/minimal-diagnostic.yaml << EOF
---
environments:
  $ENV:
    values:
      - "helmfile/environments/$ENV/*.yaml.gotmpl"
---
helmfiles:
  - path: "helmfile/apps/nubus/helmfile-child.yaml.gotmpl"
    values:
      - "helmfile/environments/default/*.yaml.gotmpl"
EOF

echo "Testing minimal helmfile (single app: nubus)..."
echo ""

MINIMAL_OUTPUT=$(DOMAIN=desk.opendesk-edu.org MAIL_DOMAIN=opendesk-edu.org MATRIX_DOMAIN=desk.opendesk-edu.org \
  helmfile -f /tmp/minimal-diagnostic.yaml -e $ENV -n $NAMESPACE template 2>&1 || true)

if echo "$MINIMAL_OUTPUT" | grep -q "Error:"; then
  echo "❌ Minimal helmfile failed too"
  echo ""
  echo "=== MINIMAL HELMFILE ERROR ==="
  echo "$MINIMAL_OUTPUT" | tail -30
  echo ""
  echo "CONCLUSION: Issue is NOT related to app count or circular reference"
else
  echo "✅ Minimal helmfile succeeded"
  echo ""
  echo "CONCLUSION: Issue IS related to app count, circular reference, or complex includes"
fi

# Step 9: Summary and Recommendations
echo ""
echo "========================================"
echo "DIAGNOSTIC SUMMARY"
echo "========================================"
echo ""

if echo "$TEMPLATE_OUTPUT" | grep -q "Recursion.*too deep"; then
  echo "❌ ISSUE TYPE: Circular Reference or Deep Recursion"
  echo ""
  echo "RECOMMENDATIONS:"
  echo "  1. Review all helmfile-child includes for self-references"
  echo "  2. Try binary search: test with half the apps, then narrow down"
  echo "  3. Check if any app's helmfile-child includes helmfile_generic.yaml.gotmpl"
elif echo "$TEMPLATE_OUTPUT" | grep -q "did not find expected.*indicator"; then
  echo "❌ ISSUE TYPE: Template Rendering - Invalid YAML Generated"
  echo ""
  echo "RECOMMENDATIONS:"
  echo "  1. Check Go template syntax in .gotmpl files"
  echo "  2. Verify {{ toYaml .Values | nindent 8 }} output is valid YAML"
  echo "  3. Look for template-generated list markers that are malformed"
  echo "  4. Test helmfile with debug output: helmfile --debug template"
elif echo "$TEMPLATE_OUTPUT" | grep -q "Error:"; then
  echo "❌ ISSUE TYPE: Other Error"
  echo ""
  echo "RECOMMENDATIONS:"
  echo "  1. Review the error output above"
  echo "  2. Test with debug flag: helmfile --debug template"
else
  echo "✅ No helmfile errors detected during template phase"
  echo ""
  echo "If deployment still fails, the issue may be:"
  echo "  - During helm upgrade (not template phase)"
  echo "  - Kubernetes-level issues"
  echo "  - OCI registry authentication"
fi

echo ""
echo "========================================"
echo "NEXT STEPS FOR DEBUGGING"
echo "========================================"
echo ""
echo "1. Run with debug flag:"
echo "   helmfile -e prod -n $NAMESPACE --debug template > debug-output.log 2>&1"
echo ""
echo "2. Search for circular references in included helmfiles:"
echo "   grep -r 'path.*helmfile_generic' helmfile/apps/*/helmfile-child.yaml.gotmpl"
echo ""
echo "3. Try testing individual apps:"
echo "   for app in nubus sogo open-xchange; do"
echo "     echo \"Testing \$app...\""
echo "   done"
echo ""
echo "4. Check helmfile known issues:"
echo "   https://github.com/roboll/helmfile/issues"
echo ""
echo "========================================"
echo "END OF DIAGNOSTIC"
echo "========================================"
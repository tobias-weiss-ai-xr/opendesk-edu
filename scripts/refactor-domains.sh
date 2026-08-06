#!/bin/bash

# OpenDesk Edu Domain Refactoring Script
# Replaces: home.opendesk-edu.org, home.opendesk-edu.org, opendesk-edu.org
# With: home.opendesk-edu.org

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$REPO_ROOT"

echo "=== OpenDesk Edu Domain Refactoring ==="
echo "Replacing domain references with home.opendesk-edu.org"
echo ""

# Directories to refactor (priority order)
DIRS=(
  "helmfile/environments"
  "helmfile/apps"
  "helmfile/charts"
  "deploy-configs"
  "tests"
  "docs/mail"
  "docs/dns-setup"
)

# File extensions to process
EXTENSIONS=(
  "*.yaml"
  "*.yml"
  "*.yaml.gotmpl"
  "*.yml.gotmpl"
  "*.md"
  "*.txt"
  "*.sh"
  "*.json"
)

# Generate find command for all target files
FIND_CMD=""
for dir in "${DIRS[@]}"; do
  FIND_CMD+=" $dir"
done

# Get all matching files
FILES=$(find $FIND_CMD -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.yaml.gotmpl" -o -name "*.yml.gotmpl" -o -name "*.md" -o -name "*.txt" -o -name "*.sh" -o -name "*.json" \) 2>/dev/null)

if [ -z "$FILES" ]; then
  echo "No files found to refactor."
  exit 0
fi

echo "Found $(echo "$FILES" | wc -l) files to check."
echo ""

# Count files with replacements needed
NEEDS_REPLACE=0
for file in $FILES; do
  if grep -q -E "opendesk\.hrz\.uni-marburg\.de|hrz\.uni-marburg\.de|uni-marburg\.de|dc=opendesk-edu,dc=org|mx\.uni-marburg\.de|ldap\.uni-marburg\.de|HRZ|Marburg" "$file" 2>/dev/null; then
    NEEDS_REPLACE=$((NEEDS_REPLACE + 1))
  fi
done

echo "Files needing refactoring: $NEEDS_REPLACE"
echo ""

# Perform replacements
REPLACEMENTS=(
  "s/opendesk\.hrz\.uni-marburg\.de/home.opendesk-edu.org/g"
  "s/hrz\.uni-marburg\.de/home.opendesk-edu.org/g"
  "s/uni-marburg\.de/opendesk-edu.org/g"
  "s/dc=opendesk-edu,dc=org/dc=opendesk-edu,dc=org/g"
  "s/mx\.uni-marburg\.de/mx.home.opendesk-edu.org/g"
  "s/ldap\.uni-marburg\.de/ldap.home.opendesk-edu.org/g"
  "s/ums-ldap\.opendesk\.hrz\.uni-marburg\.de/ums-ldap.home.opendesk-edu.org/g"
  "s/HRZ/Kubernetes/g"
  "s/Marburg/OpenDesk/g"
)

MODIFIED=0
for file in $FILES; do
  BACKUP="${file}.backup"
  
  # Check if file needs modification
  needs_change=false
  for pattern in "home.opendesk-edu.org" "home.opendesk-edu.org" "opendesk-edu.org" "dc=opendesk-edu,dc=org"; do
    if grep -q "$pattern" "$file" 2>/dev/null; then
      needs_change=true
      break
    fi
  done
  
  if [ "$needs_change" = true ]; then
    echo "Processing: $file"
    cp "$file" "$BACKUP"
    
    # Apply all replacements
    for replacement in "${REPLACEMENTS[@]}"; do
      sed -i "$replacement" "$file" 2>/dev/null
    done
    
    # Check if file was modified
    if ! diff -q "$file" "$BACKUP" >/dev/null 2>&1; then
      echo "  ✓ Modified"
      MODIFIED=$((MODIFIED + 1))
      rm "$BACKUP"
    else
      echo "  - No changes"
      rm "$BACKUP"
    fi
  fi
done

echo ""
echo "=== Refactoring Complete ==="
echo "Files checked: $(echo "$FILES" | wc -l)"
echo "Files modified: $MODIFIED"
echo ""
echo "Remember to:"
echo "1. Review changes with: git diff"
echo "2. Test configuration before deploying"
echo "3. Update any hardcoded values in deployment scripts"
echo "4. Check DNS and TLS configurations"

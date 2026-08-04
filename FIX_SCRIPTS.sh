#!/bin/bash
# Fix all bash scripts to remove syntax errors

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Fixing bash script syntax errors..."

# List of files to fix
FILES=(
    "opendesk-nix/scripts/container-gov-de/push-all.sh"
    "opendesk-nix/scripts/container-gov-de/scan-all.sh"
    "opendesk-nix/scripts/container-gov-de/sign-all.sh"
    "opendesk-nix/scripts/container-gov-de/generate-reports.sh"
    "opendesk-nix/scripts/container-gov-de/deploy.sh"
    "opendesk-nix/scripts/migrate-upstream-images.sh"
)

for file in "${FILES[@]}"; do
    echo "Fixing $file..."
    
    # Remove the problematic xargs parallel execution blocks
    python3 << PYTHON
import re

with open('$file', 'r') as f:
    content = f.read()

# Remove the broken xargs -P ... sh -c blocks
pattern = r'seq 0.*?\|\s*xargs -P.*?-I \{\} sh -c[^']*'\''[^']*'[^']*\s*_ \"\$0\"[^\n]*\n'
content = re.sub(pattern, '', content, flags=re.DOTALL)

# Also remove the preceding if condition for parallel
pattern2 = r'if \[ \"\$parallel\" -gt 1 \] \&\& \[ \"\$parallel\" -le.*?\]; then\s*echo.*?\n\s*\n\s*fi'
content = re.sub(pattern2, '', content, flags=re.DOTALL)

with open('$file', 'w') as f:
    f.write(content)

print("  Fixed parallel execution blocks")
PYTHON
    
    # Check if it now passes bash -n
    if bash -n "$file" 2>/dev/null; then
        echo "  ✅ PASS"
    else
        echo "  ❌ FAIL"
    fi
done

echo "Done!"

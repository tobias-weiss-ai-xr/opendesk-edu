#!/usr/bin/env python3
"""Fix all library files from original source."""

import re
import subprocess
import sys
import os


def fix_file_content(content):
    """Apply all fixes to content."""
    # Fix 1: // comments -> # comments
    content = re.sub(r'^(//.*)$', lambda m: '#' + m.group(1)[2:], content, flags=re.MULTILINE)
    
    # Fix 2: Triple-quoted blocks -> comments
    lines = content.split('\n')
    new_lines = []
    in_triple = False
    for line in lines:
        stripped = line.strip()
        if not in_triple and stripped.startswith('"""'):
            in_triple = True
            new_lines.append('#' + line.lstrip())
        elif in_triple and stripped.endswith('"""'):
            in_triple = False
            new_lines.append('#' + line.lstrip())
        elif in_triple:
            new_lines.append('# ' + line)
        else:
            new_lines.append(line)
    content = '\n'.join(new_lines)
    
    # Fix 3: AllowPrivilegeEscalation -> allowPrivilegeEscalation
    content = re.sub(r'\bAllowPrivilegeEscalation\b', 'allowPrivilegeEscalation', content)
    
    # Fix 4: tostring -> toString
    content = re.sub(r'\btostring\b', 'toString', content)
    
    # Fix 5: case...of -> if...then...else
    # Pattern for getProfile-like functions
    # Match: variable
    #   case var of
    #     "pat1" | "pat2" -> expr1;
    #     ...
    #     _ -> default;
    
    # This is complex, skip for now - will handle manually
    
    return content


def fix_case_of_simple(content):
    """Fix simple case...of patterns (one-line each)."""
    # Find all case...of blocks
    # This is a simplified version
    
    # Pattern: case VAR of\n  PAT -> EXPR1;\n  PAT2 -> EXPR2;\n  _ -> DEFAULT;
    # This needs more complex parsing
    
    # For now, skip - we'll do this manually per file
    return content


def test_parse(filepath):
    """Test if file parses."""
    result = subprocess.run(
        ['nix-instantiate', '--parse-only', filepath],
        capture_output=True,
        text=True,
        cwd='/home/weissto_local/git/opendesk_git'
    )
    return result.returncode == 0, result.stderr


def main():
    files = {
        'lib/cicd.nix': 'edd7765',
        'lib/cosign.nix': 'edd7765',
        'lib/registry.nix': 'edd7765',
        'lib/sbom.nix': 'edd7765',
        'lib/security-scanning.nix': 'edd7765',
        'lib/nixos/containers.nix': '2f0302e',
        'lib/nixos/security.nix': '2f0302e',
    }
    
    for filepath, commit in files.items():
        # Get original
        result = subprocess.run(
            ['git', 'show', f'{commit}:opendesk-nix/{filepath}'],
            capture_output=True,
            text=True,
            cwd='/home/weissto_local/git/opendesk_git'
        )
        
        if result.returncode != 0:
            print(f"✗ {filepath}: not found")
            continue
        
        content = result.stdout
        
        # Apply fixes
        content = fix_file_content(content)
        
        # Write temp file
        tmp_file = f'/tmp/{os.path.basename(filepath).replace(".nix", "_fixed.nix")}'
        with open(tmp_file, 'w') as f:
            f.write(content)
        
        # Test parse
        ok, error = test_parse(tmp_file)
        if ok:
            print(f"✓ {filepath}: parses OK ({len(content.splitlines())} lines)")
            # Copy to destination
            dest = f'/home/weissto_local/git/opendesk_git/opendesk-nix/{filepath}'
            with open(dest, 'w') as f:
                f.write(content)
        else:
            print(f"✗ {filepath}: parse error")
            print(f"  {error[:200]}")


if __name__ == '__main__':
    main()

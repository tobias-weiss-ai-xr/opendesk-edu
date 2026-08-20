#!/usr/bin/env python3
"""Port a full library file from original with all fixes applied."""

import re
import sys
import subprocess


def fix_file(filepath, output_path):
    """Fix all known issues in a library file."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    lines = content.split('\n')
    new_lines = []
    in_triple = False
    in_case = False
    case_indent = ""
    case_var = None
    case_patterns = []
    
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        
        # Handle triple-quoted strings
        if not in_triple and stripped.startswith('"""'):
            in_triple = True
            i += 1
            continue
        elif in_triple and stripped.endswith('"""'):
            in_triple = False
            i += 1
            continue
        elif in_triple:
            new_lines.append('# ' + line)
            i += 1
            continue
        
        # Handle C++ comments
        if re.match(r'^\s*//', line):
            new_lines.append('#' + line.lstrip()[2:])
            i += 1
            continue
        
        # Handle case...of blocks
        if not in_case and stripped.startswith('case') and stripped.endswith('of'):
            # Start of case block - parse it
            in_case = True
            case_var = stripped.split()[1]
            i += 1
            continue
        elif in_case and '->' in line:
            # Case pattern line
            case_patterns.append(line)
            i += 1
            continue
        elif in_case and (not stripped or stripped == ';'):
            # End of case block
            # Convert all patterns to if-then-else chain
            indent = '  '
            if case_patterns:
                # Build if-then-else chain
                first = True
                for pattern_line in reversed(case_patterns):
                    pattern_part, result_part = pattern_line.split('->', 1)
                    pattern = pattern_part.strip().strip('"')
                    result = result_part.strip().rstrip(';')
                    
                    if first:
                        chain = f'{indent}if {case_var} == "{pattern}" then {result}'
                        first = False
                    else:
                        chain = f'{indent}if {case_var} == "{pattern}" then {result} else {chain}'
                
                new_lines.append(chain + ';')
            
            in_case = False
            case_var = None
            case_patterns = []
            i += 1
            continue
        
        # Add line as-is
        new_lines.append(line)
        i += 1
    
    content = '\n'.join(new_lines)
    
    # Additional fixes
    # Fix AllowPrivilegeEscalation -> allowPrivilegeEscalation
    content = re.sub(r'\bAllowPrivilegeEscalation\b', 'allowPrivilegeEscalation', content)
    
    # Fix tostring -> toString  
    content = re.sub(r'\btostring\b', 'toString', content)
    
    # Ensure SPDX header
    if not content.strip().startswith('# SPDX'):
        lines = content.split('\n')
        for i, line in enumerate(lines):
            stripped = line.strip()
            if stripped.startswith('{') or stripped.startswith('{ lib'):
                lines.insert(i, '')
                lines.insert(i, '# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors')
                lines.insert(i, '# SPDX-License-Identifier: Apache-2.0')
                break
        content = '\n'.join(lines)
    
    with open(output_path, 'w') as f:
        f.write(content)
    
    return output_path


def test_parse(filepath):
    """Test if a file parses."""
    result = subprocess.run(
        ['nix-instantiate', '--parse-only', filepath],
        capture_output=True,
        text=True
    )
    return result.returncode == 0


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 port_full_lib.py <commit> <file> [file2 ...]")
        sys.exit(1)
    
    commit = sys.argv[1]
    files = sys.argv[2:]
    
    for file in files:
        input_path = f'/tmp/{file.replace("/", "_")}_orig.nix'
        output_path = f'/tmp/{file.replace("/", "_")}_fixed.nix'
        
        # Get file from commit
        result = subprocess.run(
            ['git', 'show', f'{commit}:opendesk-nix/{file}'],
            capture_output=True,
            text=True,
            cwd='/home/weissto_local/git/opendesk_git'
        )
        
        if result.returncode != 0:
            print(f"✗ {file}: not found at {commit}")
            continue
        
        with open(input_path, 'w') as f:
            f.write(result.stdout)
        
        # Fix the file
        try:
            fix_file(input_path, output_path)
            
            # Test parsing
            if test_parse(output_path):
                print(f"✓ {file}: parsed successfully")
            else:
                print(f"✗ {file}: parse errors")
                result2 = subprocess.run(
                    ['nix-instantiate', '--parse-only', output_path],
                    capture_output=True,
                    text=True
                )
                print(f"  Error: {result2.stderr[:200]}")
        except Exception as e:
            print(f"✗ {file}: exception: {e}")


if __name__ == '__main__':
    main()

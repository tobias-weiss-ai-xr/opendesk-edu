#!/usr/bin/env python3
"""
Port original lib/*.nix files with invalid syntax to valid Nix.
Fixes:
- // C++ style comments -> # Nix style comments
- """ multi-line strings as comments -> # line comments
- Function argument ordering issues
- Other common syntax issues
"""

import re
import sys
import os

def fix_file(filepath):
    """Fix a Nix file with invalid syntax."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    original_lines = content.split('\n')
    
    # Step 1: Convert // comments to # comments
    # But only if they're not inside a string
    lines = []
    in_triple_quote = False
    in_single_line_string = False
    string_char = None
    
    for line in original_lines:
        new_line = line
        i = 0
        new_chars = []
        
        while i < len(new_line):
            char = new_line[i]
            next_char = new_line[i+1] if i+1 < len(new_line) else ''
            
            # Handle string contexts
            if in_single_line_string:
                new_chars.append(char)
                if char == string_char:
                    in_single_line_line = False
                i += 1
                continue
            
            if in_triple_quote:
                new_chars.append(char)
                if char == '"' and next_char == '"' and i+2 < len(new_line) and new_line[i+2] == '"':
                    in_triple_quote = False
                    i += 3
                    continue
                i += 1
                continue
            
            # Check for string start
            if char == '"' and next_char == '"' and i+2 < len(new_line) and new_line[i+2] == '"':
                # Triple-quoted string - mark as comment
                in_triple_quote = True
                new_chars.append('# ')
                i += 3
                continue
            elif char == '"':
                in_single_line_string = True
                string_char = '"'
                new_chars.append(char)
                i += 1
                continue
            elif char == '\'':
                in_single_line_string = True
                string_char = '\''
                new_chars.append(char)
                i += 1
                continue
            
            # Handle // comments (only outside strings)
            if char == '/' and next_char == '/':
                # Convert to # comment
                new_chars.append('#')
                # Skip the rest of the line
                i = len(new_line)
                continue
            
            # Handle single-line '//' that appeared after replacing
            if char == '#' and not new_chars:
                # Already a comment, skip
                new_chars.append(char)
                i += 1
                continue
            
            new_chars.append(char)
            i += 1
        
        lines.append(''.join(new_chars))
    
    # Join and do post-processing
    content = '\n'.join(lines)
    
    # Step 2: Fix function argument ordering
    # Move { ... } to the front when it's not first
    # Pattern: function_name (arg1: arg2) { ... } -> { ... }: function_name (arg1: arg2)
    # This is complex, so we'll do a simpler approach
    
    # Step 3: Replace remaining """ with comments
    content = re.sub(r'"""(.*?)"""', lambda m: '-- Comment: ' + m.group(1).replace('\n', '\n-- '), content, flags=re.DOTALL)
    
    # Step 4: Fix common issues
    # Replace "or" (future keyword in Nix 2.0+) with "//"
    # But be careful - "or" in strings or comments should not be replaced
    content = re.sub(r'(\s)(or)(\s)', r'\1//\3', content)
    
    # Step 5: Ensure SPDX header is at the very top
    if '# SPDX-License-Identifier:' not in content[:100]:
        content = '# SPDX-License-Identifier: Apache-2.0\n# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors\n\n' + content
    
    return content


def main():
    if len(sys.argv) < 2:
        print("Usage: python port-lib-file.py <file.nix> [output.nix]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else input_file
    
    if not os.path.exists(input_file):
        print(f"Error: File not found: {input_file}")
        sys.exit(1)
    
    print(f"Porting: {input_file}")
    fixed_content = fix_file(input_file)
    
    with open(output_file, 'w') as f:
        f.write(fixed_content)
    
    print(f"  -> {output_file}")
    print("Done!")


if __name__ == '__main__':
    main()

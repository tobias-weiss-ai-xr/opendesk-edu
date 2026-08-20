#!/usr/bin/env python3
"""Convert invalid Nix syntax to valid syntax."""

import re
import sys
import os


def fix_file_content(content):
    """Fix all known syntax issues in Nix file content."""
    
    # Step 1: Replace // comments with # comments
    content = re.sub(r'^(\s*)//', r'\1#', content, flags=re.MULTILINE)
    content = re.sub(r'(\s)//', r'\1#', content, flags=re.MULTILINE)
    
    # Step 2: Remove triple-quoted strings by converting to comments
    def replace_triple_quote(match):
        text = match.group(1)
        lines = text.split('\n')
        # Convert each line to a comment, preserving indentation
        commented = []
        for line in lines:
            if line.strip():
                # Preserve leading whitespace but add #
                indent = len(line) - len(line.lstrip())
                commented.append(' ' * indent + '# ' + line.strip())
            else:
                commented.append('')
        return '\n'.join(commented)
    
    content = re.sub(r'"""(.*?)"""', replace_triple_quote, content, flags=re.DOTALL)
    
    # Step 3: Remove standalone // lines (now they're # lines, but we wanted to remove them)
    # Actually we converted them to #, which is fine
    
    # Step 4: Move { ... }: to the first non-comment, non-empty line
    lines = content.split('\n')
    header_lines = []
    code_lines = []
    found_code = False
    
    for line in lines:
        stripped = line.strip()
        if not found_code and (stripped.startswith('#') or not stripped):
            header_lines.append(line)
        else:
            found_code = True
            code_lines.append(line)
    
    # Find the function argument line ({ lib, ... }: or { pkgs, lib, ... }:)
    func_line_idx = None
    for i, line in enumerate(code_lines):
        stripped = line.strip()
        if '{' in stripped and '}:' in stripped:
            func_line_idx = i
            break
    
    if func_line_idx is not None:
        func_line = code_lines[func_line_idx]
        before = code_lines[:func_line_idx]
        after = code_lines[func_line_idx+1:]
        code_lines = [func_line] + before + after
    
    content = '\n'.join(header_lines + [''] + code_lines)
    
    # Step 5: Clean up multiple consecutive empty lines
    content = re.sub(r'\n{3,}', '\n\n', content)
    
    # Step 6: Remove empty lines at start
    content = content.lstrip('\n')
    
    return content


def fix_file(filepath):
    """Fix a single Nix file."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    fixed = fix_file_content(content)
    
    with open(filepath, 'w') as f:
        f.write(fixed)
    
    return filepath


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 fix_nix_syntax.py <file> [file2 ...]")
        sys.exit(1)
    
    for filepath in sys.argv[1:]:
        if os.path.exists(filepath):
            fix_file(filepath)
            print(f"Fixed: {filepath}")
        else:
            print(f"Not found: {filepath}", file=sys.stderr)
            sys.exit(1)


if __name__ == '__main__':
    main()

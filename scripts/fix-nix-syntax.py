#!/usr/bin/env bash
# Convert invalid Nix syntax to valid syntax
# Usage: ./fix-nix-syntax.py <file>

python3 << 'PYEOF'
import re
import sys

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Step 1: Replace // comments with # comments
    content = re.sub(r'^(\s*)//', r'\1#', content, flags=re.MULTILINE)
    content = re.sub(r'(\s)//', r'\1#', content, flags=re.MULTILINE)
    
    # Step 2: Remove triple-quoted strings
    def remove_triple_quotes(match):
        lines = match.group(1).split('\n')
        return '\n'.join(f'# {line}' if line.strip() else '' for line in lines)
    
    content = re.sub(r'"""(.*?)"""', remove_triple_quotes, content, flags=re.DOTALL)
    
    # Step 3: Remove standalone // lines
    content = re.sub(r'^\s*//\s*$', '', content, flags=re.MULTILINE)
    
    # Step 4: Move { ... }: to first non-comment line
    lines = content.split('\n')
    header = []
    code = []
    found_code = False
    
    for line in lines:
        stripped = line.strip()
        if not found_code and (stripped.startswith('#') or not stripped):
            header.append(line)
        else:
            found_code = True
            code.append(line)
    
    # Find the { lib, ... }: line in code
    func_line_idx = None
    for i, line in enumerate(code):
        if '{' in line and '}:' in line and ('lib' in line or 'pkgs' in line):
            func_line_idx = i
            break
    
    if func_line_idx is not None:
        # Move it to the front of code
        func_line = code[func_line_idx]
        code = [func_line] + code[:func_line_idx] + code[func_line_idx+1:]
    
    content = '\n'.join(header + [''] + code)
    
    # Step 5: Clean up
    content = re.sub(r'\n\n\n+', '\n\n', content)
    
    return content

if __name__ == '__main__':
    filepath = sys.argv[1]
    new_content = fix_file(filepath)
    print(new_content)
PYEOF

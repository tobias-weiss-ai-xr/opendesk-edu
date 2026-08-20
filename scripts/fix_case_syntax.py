#!/usr/bin/env python3
"""Convert Haskell-style case...of to Nix if...then...else."""

import re
import sys


def convert_case(content):
    """Convert case...of blocks to if...then...else."""
    
    # Pattern: case VAR of\n  PAT1 -> EXPR1;\n  PAT2 -> EXPR2;\n  ...\n
    def replace_case(match):
        var = match.group(1).strip()
        patterns_exprs = match.group(2).strip()
        
        # Split patterns and expressions
        lines = patterns_exprs.split('\n')
        if_values = []
        else_expr = None
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
            # Check for "->" separator
            if '->' in line:
                pattern_part, expr_part = line.split('->', 1)
                pattern = pattern_part.strip()
                expr = expr_part.strip().rstrip(';')
                # Pattern might be multiple values: "a" | "b" | "c"
                pattern_values = [p.strip().strip('"') for p in pattern.split('|')]
                if_values.append((pattern_values, expr))
            else:
                # This shouldn't happen in a well-formed case
                pass
        
        # Build the if-then-else chain
        # Start from the end and work backwards
        result = if_values[-1][1] if if_values else "null"
        for i in range(len(if_values) - 2, -1, -1):
            pattern_values, expr = if_values[i]
            # Check if any of the patterns match
            # In Nix: if builtins.elem var [p1 p2 p3] then expr else ...
            # But we need to handle | patterns
            # For a single value: if var == "value" then expr else ...
            # For multiple: if builtins.elem var ["v1" "v2" "v3"] then expr else ...
            
            if len(pattern_values) == 1:
                condition = f'{var} == "{pattern_values[0]}"'
            else:
                # Use builtins.elem
                patterns_str = ' '.join(f'"{p}"' for p in pattern_values)
                condition = f'builtins.elem {var} [{patterns_str}]'
            
            result = f'(if {condition} then {expr} else {result})'
        
        return f'  if {var} then {result}'
    
    # Match case...of blocks
    # case variable of
    #   "pat1" -> expr1;
    #   "pat2" -> expr2;
    pattern = r'(case\s+(\w+)\s+of\s*\n)(\s+(?:[^;]+\s+->\s+[^;]+;\s*\n)+)'
    content = re.sub(pattern, replace_case, content)
    
    return content


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 fix_case_syntax.py <input.nix> [output.nix]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else input_file + '.fixed'
    
    with open(input_file, 'r') as f:
        content = f.read()
    
    fixed_content = convert_case(content)
    
    with open(output_file, 'w') as f:
        f.write(fixed_content)
    
    print(f"Fixed: {input_file} -> {output_file}")


if __name__ == '__main__':
    main()

#!/usr/bin/env python3

import re
import sys


def fix_content(content):
    lines = content.split('\n')
    new_lines = []
    in_triple = False

    for line in lines:
        if not in_triple and line.strip() == '"""':
            in_triple = True
            continue
        elif in_triple and line.strip() == '"""':
            in_triple = False
            continue
        elif in_triple:
            new_lines.append('# ' + line)
            continue

        if re.match(r'^\s*//', line):
            new_lines.append('#' + line.lstrip()[2:])
            continue

        new_lines.append(line)

    return '\n'.join(new_lines)


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 fix_lib_syntax.py <input.nix> [output.nix]")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else input_file + '.fixed'

    with open(input_file, 'r') as f:
        content = f.read()

    # Remove existing SPDX headers (both // and # styles)
    # Match lines that start with optional whitespace, then SPDX (case insensitive)
    content = re.sub(r'^(\s*(//|# )?\s*)?SPDX-.*(\n|$)', '', content, flags=re.MULTILINE | re.IGNORECASE)
    
    # Remove empty lines left behind
    content = re.sub(r'^\s*$\n', '', content, flags=re.MULTILINE)
    content = content.lstrip()
    
    if not content.startswith('# SPDX'):
        # Add SPDX header at the top
        content = '# SPDX-License-Identifier: Apache-2.0\n# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors\n\n' + content

    fixed_content = fix_content(content)

    # Remove duplicate blank lines
    fixed_content = re.sub(r'\n\n\n+', '\n\n', fixed_content)

    with open(output_file, 'w') as f:
        f.write(fixed_content)

    print(f"Fixed: {input_file} -> {output_file}")


if __name__ == '__main__':
    main()

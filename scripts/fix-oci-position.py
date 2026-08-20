#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Script to fix OCI labels position in service files.
Moves ociLabels definition after name, tag, etc. are defined.
"""

import os
import re

SERVICES_DIR = '/home/weissto_local/git/opendesk_git/opendesk-nix/k8s/services'

def fix_service_file(filepath):
    """Fix OCI labels position in a service file."""
    filename = os.path.basename(filepath)
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Check if needs fixing: ociLabels defined before name
    if 'ociLabels = lib.mkOCILabels' in content:
        # Find the ociLabels definition
        oci_pattern = r'(\n\s*# OCI Labels[^}]+\:\s*lib\.mkOCILabels\s*\{[^}]+\}\s*;)'
        oci_match = re.search(oci_pattern, content)
        
        if oci_match:
            oci_block = oci_match.group(1)
            
            # Remove the current ociLabels block
            content = content.replace(oci_block, '')
            
            # Find where to insert it (after name=, tag=, description= lines)
            # Look for the pattern: name = "..."; tag = "...";
            # or: name = "..."; image = "..."; tag = "...";
            
            # Find the let block end or first semicolon after variable defs
            # Insert after the first 2-3 variable definitions
            
            # Find all lines starting with space followed by word = 
            var_lines = list(re.finditer(r'(\n\s+\w+\s*=\s*(?:["\'].*?["\']|\w+|\{))', content))
            
            if len(var_lines) >= 2:
                # Insert after the second variable definition
                insert_pos = var_lines[1].end()
                
                # Build a better ociLabels block
                # Extract name value from first var line
                name_match = re.search(r'name\s*=\s*["\']([^"\']+)["\']', content)
                tag_match = re.search(r'tag\s*=\s*["\']([^"\']+)["\']', content)
                desc_match = re.search(r'description\s*=\s*["\']([^"\']+)["\']', content)
                
                name_val = name_match.group(1) if name_match else 'name'
                tag_val = tag_match.group(1) if tag_match else 'tag'
                desc_val = desc_match.group(1) if desc_match else f'{name_val} service'
                
                # Create new OCI block with proper references
                new_oci_block = f'''

  # OCI Labels (OpenSpec Compliance - FR-IMAGE-007)
  ociLabels = lib.mkOCILabels {{
    name = name;
    version = tag;
    description = "{desc_val}";
    serviceType = "web";
    component = "backend";
  }};'''
                
                # Insert the block
                content = content[:insert_pos] + new_oci_block + content[insert_pos:]
                
                with open(filepath, 'w') as f:
                    f.write(content)
                
                return True
    
    return False

def main():
    """Fix all service files."""
    services_dir = SERVICES_DIR
    service_files = [os.path.join(services_dir, f) for f in sorted(os.listdir(services_dir)) 
                     if f.endswith('.nix') and os.path.isfile(os.path.join(services_dir, f))]
    
    fixed = 0
    skipped = 0
    
    for filepath in service_files:
        try:
            if fix_service_file(filepath):
                fixed += 1
            else:
                skipped += 1
        except Exception as e:
            print(f"✗ {os.path.basename(filepath)}: Error - {e}")
            skipped += 1
    
    print(f"\n{'='*60}")
    print(f"Summary:")
    print(f"  Fixed:   {fixed}")
    print(f"  Skipped: {skipped}")
    print(f"  Total:   {len(service_files)}")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()

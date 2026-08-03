#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Script to update all service files in opendesk-nix/k8s/services/ to add OCI labels.
This adds env parameter and OCI label generation to all service files.
"""

import os
import re
import sys

SERVICES_DIR = '/home/weissto_local/git/opendesk_git/opendesk-nix/k8s/services'

# The env parameter to add
env_param_line = "  env ? import ../environments/hrz/default.nix { lib = lib; },"

# OCI labels code
def get_oci_code(name_var, description):
    return f'''
  # OCI Labels (OpenSpec Compliance - FR-IMAGE-007)
  ociLabels = lib.mkOCILabels {{
    name = {name_var};
    version = tag;
    description = "{description}";
    serviceType = "web";
    component = "backend";
  }};'''

def update_service_file(filepath):
    """Update a single service file to add OCI labels support."""
    filename = os.path.basename(filepath)
    
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    content = ''.join(lines)
    
    # Check if already has OCI labels
    if 'mkOCILabels' in content or 'ociLabels' in content:
        print(f"✓ {filename}: Already has OCI labels")
        return False
    
    # Check if already has env parameter
    if 'env ? import' in content:
        print(f"✓ {filename}: Already has env parameter")
        return False
    
    # Find the parameters closing brace
    # Pattern: pkgs ? import <nixpkgs> { }\n}:
    # or:     pkgs ? import <nixpkgs> { }\n\}:
    
    # Find the line with pkgs and the next line with }:
    for i, line in enumerate(lines):
        if 'pkgs ? import' in line and '<nixpkgs>' in line:
            # Check if next line is }: or }:
            if i + 1 < len(lines) and lines[i+1].strip() in ['}:', '}:', '} :']:
                # Insert env param before the closing brace
                lines.insert(i + 1, env_param_line + '\n')
                print(f"✓ {filename}: Added env parameter after pkgs")
                break
    else:
        # Try to find any line with }:
        for i, line in enumerate(lines):
            if line.strip() == '}:' or line.strip() == '}:':
                # Insert before this line
                lines.insert(i, env_param_line + '\n')
                print(f"✓ {filename}: Added env parameter before }}:")
                break
        else:
            print(f"⚠ {filename}: Could not find ): or }}: to insert env")
            return False
    
    content = ''.join(lines)
    
    # Now add OCI labels in the let block
    # Find the let line and first variable definition
    let_found = False
    let_line_idx = -1
    first_var_idx = -1
    name_value = "name"
    description_value = ""
    
    for i, line in enumerate(lines):
        if not let_found and 'let' in line and i < len(lines) - 1:
            let_found = True
            let_line_idx = i
        elif let_found and first_var_idx == -1 and '=' in line and not line.strip().startswith('#'):
            # Found first variable definition
            first_var_idx = i
            # Extract name and tag if possible
            if 'name =' in line or "name =" in line:
                name_match = re.search(r'name\s*=\s*["\']([^"\']+)["\']', line)
                if name_match:
                    name_value = name_match.group(1)
            
            # Look ahead for tag
            for j in range(i, min(i + 5, len(lines))):
                if 'tag =' in lines[j] or "tag =" in lines[j]:
                    tag_match = re.search(r'tag\s*=\s*["\']([^"\']+)["\']', lines[j])
                    if tag_match:
                        version_value = tag_match.group(1)
            
            # Look for description
            for j in range(i, min(i + 5, len(lines))):
                if 'description' in lines[j].lower():
                    desc_match = re.search(r'description\s*=\s*["\']([^"\']+)["\']', lines[j])
                    if desc_match:
                        description_value = desc_match.group(1)
            
            break
    
    if let_found and first_var_idx > 0:
        # Insert OCI labels after let line or before first variable
        if let_line_idx + 1 == first_var_idx:
            # let is immediately followed by first variable, insert between them
            lines.insert(first_var_idx, get_oci_code(name_value, description_value or f"{name_value} service"))
        else:
            # Insert after let line
            lines.insert(let_line_idx + 1, get_oci_code(name_value, description_value or f"{name_value} service"))
        
        # Write the updated file
        with open(filepath, 'w') as f:
            f.writelines(lines)
        
        print(f"✓ {filename}: Added OCI labels")
        return True
    else:
        print(f"⚠ {filename}: Could not find let block or variable definitions")
        return False

def main():
    """Update all service files with OCI labels."""
    services_dir = SERVICES_DIR
    service_files = [os.path.join(services_dir, f) for f in sorted(os.listdir(services_dir)) 
                     if f.endswith('.nix') and os.path.isfile(os.path.join(services_dir, f))]
    
    updated = 0
    skipped = 0
    errors = 0
    
    for filepath in service_files:
        try:
            if update_service_file(filepath):
                updated += 1
            else:
                skipped += 1
        except Exception as e:
            print(f"✗ {os.path.basename(filepath)}: Error - {e}")
            import traceback
            traceback.print_exc()
            errors += 1
    
    print(f"\n{'='*60}")
    print(f"Summary:")
    print(f"  Updated: {updated}")
    print(f"  Skipped: {skipped}")
    print(f"  Errors:  {errors}")
    print(f"  Total:   {len(service_files)}")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()

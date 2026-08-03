#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Script to add OCI labels to service files in a way that works with the compact format.
"""

import os
import re

SERVICES_DIR = '/home/weissto_local/git/opendesk_git/opendesk-nix/k8s/services'

def process_service_file(filepath):
    """Process a single service file."""
    filename = os.path.basename(filepath)
    
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    # Skip if already has OCI
    content = ''.join(lines)
    if 'mkOCILabels' in content or 'ociLabels' in content:
        return False
    
    # Find the pkgs line and add env after it
    new_lines = []
    pkgs_pattern = re.compile(r'pkgs\s*\?\s*import\s*<nixpkgs>\s*\{')
    env_added = False
    
    for i, line in enumerate(lines):
        new_lines.append(line)
        
        # Add env parameter after pkgs line
        if not env_added and pkgs_pattern.search(line):
            # Check if the import has a closing brace on same line or next
            if '}' in line:
                # Closing brace on same line, add env on next line
                pass
            else:
                # Check next line
                if i + 1 < len(lines) and '}' in lines[i+1]:
                    # Closing brace on next line, add env after it
                    continue
            
            # Add env parameter
            new_lines.append('  env ? import ../environments/hrz/default.nix { lib = lib; },\n')
            env_added = True
    
    # If we didn't find a pkgs line, find the closing }: and add env before it
    if not env_added:
        new_lines = []
        for i, line in enumerate(lines):
            if line.strip() == '}:' or line.strip() == '}:':
                new_lines.append('  env ? import ../environments/hrz/default.nix { lib = lib; },\n')
            new_lines.append(line)
    
    # Now add OCI labels in the let block after name and tag are defined
    # The compact format has everything on one line after let
    # e.g.: let\n name = "argocd"; image = ""; tag = "v2.10.0"; ...
    
    final_lines = []
    let_found = False
    let_line_idx = -1
    
    for i, line in enumerate(new_lines):
        if 'let' in line and not line.strip().startswith('#'):
            let_found = True
            let_line_idx = i
            final_lines.append(line)
        elif let_found and len(final_lines) == let_line_idx + 1:
            # This is the first line after let
            # Insert OCI labels before it
            final_lines.append('\n')
            final_lines.append('  # OCI Labels (OpenSpec Compliance - FR-IMAGE-007)\n')
            final_lines.append('  ociLabels = lib.mkOCILabels {\n')
            final_lines.append('    name = name;\n')
            final_lines.append('    version = tag;\n')
            
            # Extract service name from filename
            service_name = filename.replace('.nix', '')
            final_lines.append(f'    description = "{service_name} service for openDesk";\n')
            final_lines.append('    serviceType = "web";\n')
            final_lines.append('    component = "backend";\n')
            final_lines.append('  };\n')
            final_lines.append(line)
            let_found = False  # Only add once
        else:
            final_lines.append(line)
    
    # If let was never followed by anything, insert OCI labels after let
    if let_found:
        # Already handled above
        pass
    
    # Write the file
    with open(filepath, 'w') as f:
        f.writelines(final_lines)
    
    return True

def main():
    """Process all service files."""
    services_dir = SERVICES_DIR
    service_files = [os.path.join(services_dir, f) for f in sorted(os.listdir(services_dir)) 
                     if f.endswith('.nix') and os.path.isfile(os.path.join(services_dir, f))]
    
    updated = 0
    skipped = 0
    
    for filepath in service_files:
        try:
            if process_service_file(filepath):
                updated += 1
                print(f"✓ {os.path.basename(filepath)}")
            else:
                skipped += 1
        except Exception as e:
            print(f"✗ {os.path.basename(filepath)}: {e}")
            import traceback
            traceback.print_exc()
            skipped += 1
    
    print(f"\n{'='*60}")
    print(f"Summary:")
    print(f"  Updated: {updated}")
    print(f"  Skipped: {skipped}")
    print(f"  Total:   {len(service_files)}")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()

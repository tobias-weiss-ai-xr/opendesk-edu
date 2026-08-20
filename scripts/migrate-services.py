#!/usr/bin/env python3

"""
Automated Migration Script for Phase 2 Consolidation

This script updates all service definition files in opendesk-nix/k8s/services/
to use the new library features from opendesk-nix/lib/

Features added:
- Import new libraries (security, registry, types, sbom)
- Add security contexts (container + pod)
- Add probe configurations
- Standardize image references using registry helpers
- Add resource requests/limits where missing
- Add PSA labels

Usage:
  ./migrate-services.py              # Dry run (shows what would change)
  ./migrate-services.py --apply       # Actually make changes
  ./migrate-services.py --backup      # Create backups before changes
  ./migrate-services.py --all         # Backup + apply
"""

import os
import sys
import re
import shutil
import argparse
from datetime import datetime
from pathlib import Path

# Configuration
SERVICES_DIR = Path("/home/weissto_local/git/opendesk_git/opendesk-nix/k8s/services")

# ANSI Colors
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color

# Service categorization for security profiles
SERVICE_PROFILES = {
    # Databases
    "mariadb": "database",
    "postgresql": "database",
    "timescale": "database",
    
    # Caches
    "redis": "cache",
    "memcached": "cache",
    
    # Storage
    "minio": "storage",
    "seaweedfs": "storage",
    "clamav": "storage",
    
    # LMS & Education
    "ilias": "lms",
    "ilias-full": "lms",
    "moodle": "lms",
    "xwiki": "lms",
    "jupyterhub": "lms",
    "bookstack": "lms",
    "openproject": "lms",
    "collab-dashboard": "lms",
    
    # Collaboration
    "collabora": "collaboration",
    "drawio": "collaboration",
    "excalidraw": "collaboration",
    "etherpad": "collaboration",
    "opencloud": "collaboration",
    
    # Communication
    "element": "web",
    "jitsi": "web",
    "stalwart": "web",
    "bigbluebutton": "collaboration",
    
    # Development
    "coderd": "web",
    "code-server": "web",
    "rstudio": "web",
    "ttyd": "web",
    "dask": "web",
    
    # AI
    "ollama": "web",
    "open-webui": "web",
    "n8n": "web",
    
    # Monitoring
    "kube-prometheus-stack": "monitoring",
    "monitoring": "monitoring",
    "elasticsearch": "monitoring",
    "kibana": "monitoring",
    "filebeat": "monitoring",
    "loki": "monitoring",
    "promtail": "monitoring",
    
    # Authentication
    "sogo": "web",
    "self-service-password": "web",
    "portal-entries": "web",
    "semester-provisioning": "web",
    "eudi-issuer": "web",
    
    # Project Management
    "planka": "web",
    "argocd": "web",
    "zammad": "web",
    
    # Other
    "f13": "web",
    "grommunio": "web",
    "intercom": "web",
    "intercom-service": "web",
    "snipr": "web",
    "slidev": "web",
    "limesurvey": "web",
    "overleaf": "web",
    "typo3": "web",
}

DEFAULT_PROFILE = "web"

# Counters
class Stats:
    def __init__(self):
        self.total_files = 0
        self.processed_files = 0
        self.failed_files = 0
        self.processed_list = []
        self.failed_list = []

stats = Stats()

# Helper functions
class Logger:
    @staticmethod
    def success(msg):
        print(f"{Colors.GREEN}✓{Colors.NC} {msg}")
    
    @staticmethod
    def warning(msg):
        print(f"{Colors.YELLOW}⚠{Colors.NC} {msg}")
    
    @staticmethod
    def error(msg):
        print(f"{Colors.RED}✗{Colors.NC} {msg}")
    
    @staticmethod
    def info(msg):
        print(f"{Colors.BLUE}ℹ{Colors.NC} {msg}")

def has_security(filepath):
    """Check if file already has security configurations."""
    with open(filepath, 'r') as f:
        content = f.read()
    return bool(re.search(r'security|SecurityContext|runAsNonRoot|readOnlyRootFilesystem', content))

def has_probes(filepath):
    """Check if file already has probe configurations."""
    with open(filepath, 'r') as f:
        content = f.read()
    return bool(re.search(r'livenessProbe|readinessProbe|startupProbe', content))

def has_resources(filepath):
    """Check if file already has resource configurations."""
    with open(filepath, 'r') as f:
        content = f.read()
    return bool(re.search(r'resources|requests|limits', content))

def extract_port(filepath):
    """Extract port number from file."""
    with open(filepath, 'r') as f:
        content = f.read()
    match = re.search(r'port\s*=\s*(\d+)', content)
    return match.group(1) if match else "80"

def extract_name_from_filename(filename):
    """Extract service name from filename."""
    return Path(filename).stem

def get_security_profile(filename):
    """Get security profile for a service."""
    name = extract_name_from_filename(filename)
    return SERVICE_PROFILES.get(name, DEFAULT_PROFILE)

def do_create_backup(services_dir):
    """Create backup of all service files."""
    backup_dir = services_dir / f".backup-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    backup_dir.mkdir(parents=True, exist_ok=True)
    
    Logger.info(f"Creating backup in: {backup_dir}")
    
    count = 0
    for filepath in services_dir.glob("*.nix"):
        if filepath.name not in ["README.md", "MIGRATION-TRACKER.md", "mariadb-enhanced.nix"]:
            shutil.copy2(filepath, backup_dir)
            count += 1
    
    Logger.success(f"Created backup of {count} files")
    return backup_dir

def update_service_file(filepath, dry_run=False):
    """Update a single service file with new library features."""
    filename = filepath.name
    name = extract_name_from_filename(filename)
    
    # Skip non-service files
    if filename in ["README.md", "MIGRATION-TRACKER.md", "mariadb-enhanced.nix"]:
        return True
    
    profile = get_security_profile(filename)
    
    # Read original content
    with open(filepath, 'r') as f:
        original_content = f.read()
    
    # Check if already updated
    if re.search(r'security\s*\?\s*import', original_content):
        Logger.info(f"Skipping {filename} - already has new imports")
        stats.processed_list.append(f"{filename} (skipped - already updated)")
        return True
    
    try:
        # Extract port
        port = extract_port(filepath)
        
        # Build new content
        new_content = """// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

{ 
  lib,
  security ? import ../../lib/security.nix { },
  registry ? import ../../lib/registry.nix { },
  types ? import ../../lib/types.nix { },
  sbom ? import ../../lib/sbom.nix { },
  pkgs ? import <nixpkgs> { }
}:

"""
        
        # Check if file has a let block
        let_match = re.search(r'\blet\b(.*?)\bin\b', original_content, re.DOTALL)
        
        if let_match:
            # File has let block, extract its content
            let_content = let_match.group(1)
            
            # Add security context if missing
            if not has_security(filepath):
                let_content += f"""
  # Security configuration
  containerSecurity = security.mkContainerSecurityContext {{ profile = "{profile}"; }};
  podSecurity = security.mkPodSecurityContext {{ user = 1000; group = 1000; fsGroup = 1000; }};

"""
            
            # Add probes if missing
            if not has_probes(filepath):
                let_content += f"""  # Probe configuration
  livenessProbe = lib.mkProbe {{
    type = "tcp";
    port = {port};
    initialDelaySeconds = 30;
    periodSeconds = 10;
    timeoutSeconds = 5;
  }};
  readinessProbe = lib.mkProbe {{
    type = "tcp";
    port = {port};
    initialDelaySeconds = 5;
    periodSeconds = 5;
    timeoutSeconds = 3;
  }};

"""
            
            # Add resources if missing
            if not has_resources(filepath):
                let_content += """  # Resource configuration
  resources = {
    requests = { cpu = "100m"; memory = "256Mi"; };
    limits = { cpu = "500m"; memory = "512Mi"; };
  };

"""
            
            # Reconstruct the file
            new_content += "let\n" + let_content + "\nin\n"
            
            # Add the rest of the file (after 'in')
            in_match = re.search(r'\bin\b(.*?)$', original_content, re.DOTALL)
            if in_match:
                new_content += in_match.group(1)
        else:
            # File doesn't have a let block, add basic structure
            new_content += "let\n"
            new_content += "  # Service name\n"
            new_content += f"  name = \"{name}\";\n\n"
            new_content += "  # Security configuration\n"
            new_content += f"  containerSecurity = security.mkContainerSecurityContext {{ profile = \"{profile}\"; }};\n"
            new_content += "  podSecurity = security.mkPodSecurityContext { user = 1000; group = 1000; fsGroup = 1000; };\n\n"
            new_content += "  # Probe configuration\n"
            new_content += f"  livenessProbe = lib.mkProbe {{ type = \"tcp\"; port = {port}; initialDelaySeconds = 30; periodSeconds = 10; timeoutSeconds = 5; }};\n"
            new_content += f"  readinessProbe = lib.mkProbe {{ type = \"tcp\"; port = {port}; initialDelaySeconds = 5; periodSeconds = 5; timeoutSeconds = 3; }};\n\n"
            new_content += "  # Resource configuration\n"
            new_content += "  resources = { requests = { cpu = \"100m\"; memory = \"256Mi\"; }; limits = { cpu = \"500m\"; memory = \"512Mi\"; }; };\n"
            new_content += "in\n"
            new_content += original_content
        
        # Show diff if dry run
        if dry_run:
            print(f"{Colors.BLUE}========================================{Colors.NC}")
            print(f"{Colors.BLUE}BEGIN: {filename}{Colors.NC}")
            print(f"{Colors.BLUE}========================================{Colors.NC}")
            print("\nOriginal:")
            print("---")
            print(original_content[:200] + "..." if len(original_content) > 200 else original_content)
            print("\nNew:")
            print("---")
            print(new_content[:200] + "..." if len(new_content) > 200 else new_content)
            print()
        
        # Apply changes if requested
        if not dry_run:
            with open(filepath, 'w') as f:
                f.write(new_content)
            Logger.success(f"Updated {filename} with profile: {profile}")
        else:
            Logger.info(f"Would update {filename} with profile: {profile}")
        
        stats.processed_list.append(f"{filename} ({profile})")
        stats.processed_files += 1
        return True
        
    except Exception as e:
        Logger.error(f"Failed to update {filename}: {e}")
        stats.failed_list.append(filename)
        stats.failed_files += 1
        return False

def main():
    parser = argparse.ArgumentParser(
        description='Automated migration script for openDesk service definitions.'
    )
    parser.add_argument('--apply', '-a', action='store_true', help='Apply changes to files')
    parser.add_argument('--backup', '-b', action='store_true', help='Create backups before changes')
    parser.add_argument('--all', action='store_true', help='Create backups AND apply changes')
    parser.add_argument('--dry-run', '-n', action='store_true', help='Show what would change (default)')
    
    args = parser.parse_args()
    
    dry_run = args.dry_run
    create_backup_flag = args.backup or args.all
    apply_changes = args.apply or args.all
    
    if not (dry_run or apply_changes or create_backup):
        dry_run = True
        Logger.info("Running in DRY RUN mode (no changes will be made)")
        Logger.info("Use --apply or --all to make changes")
    
    Logger.info("Starting service migration...")
    print()
    
    # Verify services directory exists
    if not SERVICES_DIR.exists():
        Logger.error(f"Services directory not found: {SERVICES_DIR}")
        sys.exit(1)
    
    # Create backup if requested
    if create_backup_flag:
        do_create_backup(SERVICES_DIR)
        print()
    
    # Count total files
    service_files = [
        f for f in SERVICES_DIR.glob("*.nix") 
        if f.name not in ["README.md", "MIGRATION-TRACKER.md", "mariadb-enhanced.nix"]
    ]
    stats.total_files = len(service_files)
    
    Logger.info(f"Found {stats.total_files} service files to process")
    print()
    
    # Process each file
    for filepath in sorted(service_files):
        success = update_service_file(filepath, dry_run=dry_run)
        if not success:
            pass  # Error already logged
    
    # Print summary
    print()
    print()
    Logger.info("=" * 40)
    Logger.info("           MIGRATION SUMMARY")
    Logger.info("=" * 40)
    print()
    print(f"Total service files:    {stats.total_files}")
    print(f"Processed:              {stats.processed_files}")
    print(f"Failed:                 {stats.failed_files}")
    print()
    
    if stats.processed_list:
        print(f"{Colors.GREEN}Processed files:{Colors.NC}")
        for item in stats.processed_list:
            print(f"  - {item}")
        print()
    
    if stats.failed_list:
        print(f"{Colors.RED}Failed files:{Colors.NC}")
        for item in stats.failed_list:
            print(f"  - {item}")
        print()
    
    if dry_run:
        Logger.warning("DRY RUN - No changes were actually made to files")
        Logger.info("Use --apply or --all to apply changes")
    
    if apply_changes:
        Logger.success(f"Changes applied to {stats.processed_files} files")

if __name__ == "__main__":
    main()

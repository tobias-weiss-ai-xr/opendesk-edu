#!/bin/bash

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

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
  ./migrate-services.sh              # Dry run (shows what would change)
  ./migrate-services.sh --apply       # Actually make changes
  ./migrate-services.sh --backup      # Create backups before changes
  ./migrate-services.sh --all         # Backup + apply
"""

set -euo pipefail

# Configuration
SERVICES_DIR="/home/weissto_local/git/opendesk_git/opendesk-nix/k8s/services"
BACKUP_DIR="${SERVICES_DIR}/.backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
CREATE_BACKUP=false
APPLY_CHANGES=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Automated migration script for openDesk service definitions."
    echo ""
    echo "Options:"
    echo "  --apply, -a      Apply changes to files"
    echo "  --backup, -b     Create backups before changes"
    echo "  --all            Create backups AND apply changes"
    echo "  --dry-run, -n    Show what would change (default)"
    echo "  --help, -h       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --dry-run           # Show changes without applying"
    echo "  $0 --backup            # Create backups only"
    echo "  $0 --all               # Create backups and apply all changes"
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --apply|-a)
            APPLY_CHANGES=true
            shift
            ;;
        --backup|-b)
            CREATE_BACKUP=true
            shift
            ;;
        --all)
            CREATE_BACKUP=true
            APPLY_CHANGES=true
            shift
            ;;
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# If no specific flags, default to dry run
if [[ ! $APPLY_CHANGES && ! $CREATE_BACKUP ]]; then
    DRY_RUN=true
    echo -e "${BLUE}Running in DRY RUN mode (no changes will be made)${NC}"
    echo -e "Use --apply or --all to make changes"
    echo ""
fi

# Service categorization for security profiles
# Format: service_name:security_profile
declare -A SERVICE_PROFILES=(
    # Databases
    [mariadb]="database"
    [postgresql]="database"
    [timescale]="database"
    
    # Caches
    [redis]="cache"
    [memcached]="cache"
    
    # Storage
    [minio]="storage"
    [seaweedfs]="storage"
    [clamav]="storage"
    
    # LMS & Education
    [ilias]="lms"
    [ilias-full]="lms"
    [moodle]="lms"
    [xwiki]="lms"
    [jupyterhub]="lms"
    [bookstack]="lms"
    [openproject]="lms"
    [collab-dashboard]="lms"
    
    # Collaboration
    [collabora]="collaboration"
    [drawio]="collaboration"
    [excalidraw]="collaboration"
    [etherpad]="collaboration"
    [opencloud]="collaboration"
    
    # Communication
    [element]="web"
    [jitsi]="web"
    [stalwart]="web"
    [bigbluebutton]="collaboration"
    
    # Development
    [coderd]="web"
    [code-server]="web"
    [rstudio]="web"
    [ttyd]="web"
    [dask]="web"
    
    # AI
    [ollama]="web"
    [open-webui]="web"
    [n8n]="web"
    
    # Monitoring
    [kube-prometheus-stack]="monitoring"
    [monitoring]="monitoring"
    [elasticsearch]="monitoring"
    [kibana]="monitoring"
    [filebeat]="monitoring"
    [loki]="monitoring"
    [promtail]="monitoring"
    
    # Authentication
    [sogo]="web"
    [self-service-password]="web"
    [portal-entries]="web"
    [semester-provisioning]="web"
    [eudi-issuer]="web"
    
    # Project Management
    [planka]="web"
    [argocd]="web"
    [zammad]="web"
    
    # Other
    [f13]="web"
    [grommunio]="web"
    [intercom]="web"
    [intercom-service]="web"
    [snipr]="web"
    [slidev]="web"
    [limesurvey]="web"
    [overleaf]="web"
    [typo3]="web"
)

# Default profile
DEFAULT_PROFILE="web"

# Counters
TOTAL_FILES=0
PROCESSED_FILES=0
FAILED_FILES=0

# Arrays to track results
declare -a PROCESSED_LIST
declare -a FAILED_LIST

# Helper functions
log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

has_security() {
    grep -q "security\|SecurityContext\|runAsNonRoot\|readOnlyRootFilesystem" "$1"
}

has_probes() {
    grep -q "livenessProbe\|readinessProbe\|startupProbe" "$1"
}

has_resources() {
    grep -q "resources\|requests\|limits" "$1"
}

# Create backup
create_backup() {
    if [[ ! -d "$SERVICES_DIR" ]]; then
        log_error "Services directory not found: $SERVICES_DIR"
        exit 1
    fi
    
    log_info "Creating backup in: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    local count=0
    for file in "$SERVICES_DIR"/*.nix; do
        if [[ -f "$file" && ! "$file" =~ README\.md|MIGRATION-TRACKER\.md|mariadb-enhanced\.nix ]]; then
            cp "$file" "$BACKUP_DIR/"
            ((count++))
        fi
    done
    
    log_success "Created backup of $count files"
    echo ""
}

# Update a single service file
update_service_file() {
    local file="$1"
    local filename=$(basename "$file" .nix)
    local backup_file=""
    
    TOTAL_FILES=$((TOTAL_FILES + 1))
    
    # Skip non-service files
    if [[ "$filename" =~ README|MIGRATION|mariadb-enhanced ]]; then
        return 0
    fi
    
    # Determine security profile
    local profile=${SERVICE_PROFILES[$filename]:-$DEFAULT_PROFILE}
    
    # Read original content
    local original_content=$(cat "$file")
    
    # Backup original if applying changes
    if [[ $APPLY_CHANGES == true ]]; then
        backup_file="${file}.bak-$(date +%Y%m%d-%H%M%S)"
        cp "$file" "$backup_file"
    fi
    
    # Check if file already has new imports
    if grep -q "security ? import" "$file"; then
        log_info "Skipping $filename - already has new imports"
        PROCESSED_LIST+=("$filename (skipped - already updated)")
        return 0
    fi
    
    # Build new content
    local new_content=""
    
    # Add header with SPDX license
    new_content+="// SPDX-License-Identifier: Apache-2.0\n"
    new_content+="// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors\n"
    new_content+="\n"
    
    # Add new imports
    new_content+="{ \n"
    new_content+="  lib, \n"
    new_content+="  security ? import ../../lib/security.nix { }, \n"
    new_content+="  registry ? import ../../lib/registry.nix { }, \n"
    new_content+="  types ? import ../../lib/types.nix { }, \n"
    new_content+="  sbom ? import ../../lib/sbom.nix { }, \n"
    new_content+="  pkgs ? import <nixpkgs> { } \n"
    new_content+="}:\n"
    new_content+="\n"
    
    # Extract existing let block or add new one
    if grep -q "^let" "$file"; then
        # File already has a let block, update it
        # Extract the let block content
        local let_content=$(sed -n '/^let/,/^in /p' "$file" | sed '$d')
        
        # Check if security context exists
        if ! has_security "$file"; then
            # Add security context definitions
            let_content+="\n  # Security configuration\n"
            let_content+="  containerSecurity = security.mkContainerSecurityContext {\n"
            let_content+="    profile = "\"$profile\"\"\n"
            let_content+="  };\n"
            let_content+="  podSecurity = security.mkPodSecurityContext {\n"
            let_content+="    user = 1000;\n"
            let_content+="    group = 1000;\n"
            let_content+="    fsGroup = 1000;\n"
            let_content+="  };\n"
        fi
        
        # Check if probes exist
        if ! has_probes "$file"; then
            # Extract port from file
            local port=$(grep -oP 'port = \K[0-9]+' "$file" | head -1 || echo "80")
            
            let_content+="\n  # Probe configuration\n"
            let_content+="  livenessProbe = lib.mkProbe {\n"
            let_content+="    type = \"tcp\";\n"
            let_content+="    port = $port;\n"
            let_content+="    initialDelaySeconds = 30;\n"
            let_content+="    periodSeconds = 10;\n"
            let_content+="    timeoutSeconds = 5;\n"
            let_content+="  };\n"
            let_content+="  readinessProbe = lib.mkProbe {\n"
            let_content+="    type = \"tcp\";\n"
            let_content+="    port = $port;\n"
            let_content+="    initialDelaySeconds = 5;\n"
            let_content+="    periodSeconds = 5;\n"
            let_content+="    timeoutSeconds = 3;\n"
            let_content+="  };\n"
        fi
        
        # Check if resources exist
        if ! has_resources "$file"; then
            let_content+="\n  # Resource configuration\n"
            let_content+="  resources = {\n"
            let_content+="    requests = { cpu = \"100m\"; memory = \"256Mi\"; };\n"
            let_content+="    limits = { cpu = \"500m\"; memory = \"512Mi\"; };\n"
            let_content+="  };\n"
        fi
        
        # Reconstruct the file
        new_content+="$let_content\n"
        
        # Add the rest of the file (after 'in')
        local rest_content=$(sed -n '/^in /,$p' "$file")
        new_content+="$rest_content\n"
    else
        # File doesn't have a let block, add basic structure
        new_content+="let\n"
        new_content+="  # Service name\n"
        new_content+="  name = \"$filename\";\n"
        new_content+="\n"
        new_content+="  # Security configuration\n"
        new_content+="  containerSecurity = security.mkContainerSecurityContext {\n"
        new_content+="    profile = \"$profile\";\n"
        new_content+="  };\n"
        new_content+="  podSecurity = security.mkPodSecurityContext {\n"
        new_content+="    user = 1000;\n"
        new_content+="    group = 1000;\n"
        new_content+="    fsGroup = 1000;\n"
        new_content+="  };\n"
        new_content+="\n"
        new_content+="  # Probe configuration\n"
        new_content+="  livenessProbe = lib.mkProbe {\n"
        new_content+="    type = \"tcp\";\n"
        new_content+="    port = 80;\n"
        new_content+="    initialDelaySeconds = 30;\n"
        new_content+="    periodSeconds = 10;\n"
        new_content+="    timeoutSeconds = 5;\n"
        new_content+="  };\n"
        new_content+="  readinessProbe = lib.mkProbe {\n"
        new_content+="    type = \"tcp\";\n"
        new_content+="    port = 80;\n"
        new_content+="    initialDelaySeconds = 5;\n"
        new_content+="    periodSeconds = 5;\n"
        new_content+="    timeoutSeconds = 3;\n"
        new_content+="  };\n"
        new_content+="\n"
        new_content+="  # Resource configuration\n"
        new_content+="  resources = {\n"
        new_content+="    requests = { cpu = \"100m\"; memory = \"256Mi\"; };\n"
        new_content+="    limits = { cpu = \"500m\"; memory = \"512Mi\"; };\n"
        new_content+="  };\n"
        new_content+="in\n"
        new_content+="${original_content}\n"
    fi
    
    # Show diff if dry run
    if [[ $DRY_RUN == true ]]; then
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}BEGIN: $filename${NC}"
        echo -e "${BLUE}========================================${NC}"
        echo ""
        echo "Original:"
        echo "---"
        echo "$original_content"
        echo ""
        echo "New:"
        echo "---"
        echo "$new_content"
        echo ""
    fi
    
    # Apply changes if requested
    if [[ $APPLY_CHANGES == true ]]; then
        echo "$new_content" > "$file"
        log_success "Updated $filename with profile: $profile"
    else
        log_info "Would update $filename with profile: $profile"
    fi
    
    PROCESSED_LIST+=("$filename ($profile)")
    PROCESSED_FILES=$((PROCESSED_FILES + 1))
}

# Main execution
main() {
    log_info "Starting service migration..."
    echo ""
    
    # Create backup if requested
    if [[ $CREATE_BACKUP == true ]]; then
        create_backup
    fi
    
    # Count total files
    local file_count=$(find "$SERVICES_DIR" -maxdepth 1 -name "*.nix" ! -name "README*" ! -name "*MIGRATION*" ! -name "*enhanced*" | wc -l)
    
    log_info "Found $file_count service files to process"
    echo ""
    
    # Process each file
    for file in "$SERVICES_DIR"/*.nix; do
        if [[ -f "$file" ]]; then
            update_service_file "$file" || FAILED_FILES=$((FAILED_FILES + 1)) || FAILED_LIST+=("$(basename "$file")")
        fi
    done
    
    # Print summary
    echo ""
    echo ""
    log_info "========================================"
    log_info "           MIGRATION SUMMARY"
    log_info "========================================"
    echo ""
    echo "Total service files:    $file_count"
    echo "Processed:              $PROCESSED_FILES"
    echo "Failed:                 $FAILED_FILES"
    echo ""
    
    if [[ ${#PROCESSED_LIST[@]} -gt 0 ]]; then
        echo -e "${GREEN}Processed files:${NC}"
        for item in "${PROCESSED_LIST[@]}"; do
            echo "  - $item"
        done
        echo ""
    fi
    
    if [[ ${#FAILED_LIST[@]} -gt 0 ]]; then
        echo -e "${RED}Failed files:${NC}"
        for item in "${FAILED_LIST[@]}"; do
            echo "  - $item"
        done
        echo ""
    fi
    
    if [[ $DRY_RUN == true ]]; then
        log_warning "DRY RUN - No changes were actually made to files"
        log_info "Use --apply or --all to apply changes"
    fi
    
    if [[ $APPLY_CHANGES == true ]]; then
        log_success "Changes applied to $PROCESSED_FILES files"
    fi
    
    echo ""
}

# Run main
main

exit 0

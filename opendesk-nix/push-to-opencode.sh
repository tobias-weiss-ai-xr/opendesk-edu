#!/bin/bash
# =============================================================================
# Push All Images to opencode.de Container Registry
#
# Pulls images from GHCR (ghcr.io/opendesk-edu/*, ghcr.io/tobias-weiss-ai-xr/*)
# and pushes them to registry.opencode.de/umr/
#
# Usage:
#   OPENCODE_TOKEN="your-pat" ./push-to-opencode.sh [OPTIONS]
#
# Options:
#   --all          Push all images (default: core only)
#   --core         Push only core images (OpenCloud, Stalwart, SOGo, PostgreSQL, Memcached, Keycloak)
#   --list         List images that would be pushed
#   --dry-run      Show what would be pushed without pushing
#   --registry     Override target registry (default: registry.opencode.de/umr)
#   --source       Override source registry (default: ghcr.io)
#   --help         Show this help
#
# Environment variables:
#   OPENCODE_TOKEN   GitLab Personal Access Token (required for push)
#   OPENCODE_USER    GitLab username (default: weiss)
#   OPENCODE_REGISTRY  Target registry (default: registry.opencode.de/umr)
#
# Examples:
#   OPENCODE_TOKEN="glpat-xxx" ./push-to-opencode.sh --core
#   OPENCODE_TOKEN="glpat-xxx" ./push-to-opencode.sh --all
#   OPENCODE_TOKEN="glpat-xxx" ./push-to-opencode.sh --list
#   OPENCODE_TOKEN="glpat-xxx" ./push-to-opencode.sh --dry-run --all
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

TARGET_REGISTRY="${OPENCODE_REGISTRY:-registry.opencode.de/umr}"
SOURCE_REGISTRY="${SOURCE_REGISTRY:-ghcr.io}"
GITLAB_USER="${OPENCODE_USER:-weiss}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# =============================================================================
# Core Images (required for OpenDesk EDU minimal deployment)
# =============================================================================

declare -a CORE_IMAGES=(
    "ghcr.io/opendesk-edu/postgresql:latest"
    "ghcr.io/opendesk-edu/memcached:latest"
    "ghcr.io/opendesk-edu/sogo:latest"
    "ghcr.io/opendesk-edu/stalwart:latest"
    "ghcr.io/opendesk-edu/opencloud:4.0.3"
    "ghcr.io/opendesk-edu/supplier/univention/keycloak:26.7.0"
    "ghcr.io/project-zot/zot:v2.1.0"
)

# =============================================================================
# Additional EDU Images
# =============================================================================

declare -a EDU_IMAGES=(
    "ghcr.io/opendesk-edu/mariadb:latest"
    "ghcr.io/opendesk-edu/bookstack:latest"
    "ghcr.io/opendesk-edu/drawio:latest"
    "ghcr.io/opendesk-edu/excalidraw:latest"
    "ghcr.io/opendesk-edu/planka:latest"
    "ghcr.io/opendesk-edu/self-service-password:latest"
    "ghcr.io/opendesk-edu/user-import:latest"
    "ghcr.io/opendesk-edu/opendesk-dev-agent-operator:latest"
    "ghcr.io/opendesk-edu/moodle-shib:latest"
    "ghcr.io/opendesk-edu/ilias-shibboleth:latest"
    "ghcr.io/opendesk-edu/ilias:latest"
    "ghcr.io/opendesk-edu/moodle:latest"
    "ghcr.io/opendesk-edu/collabora:latest"
    "ghcr.io/opendesk-edu/clamav:latest"
    "ghcr.io/opendesk-edu/etherpad:1.9.9"
    "ghcr.io/opendesk-edu/element:latest"
    "ghcr.io/opendesk-edu/jitsi-jicofo:latest"
    "ghcr.io/opendesk-edu/jitsi-web:latest"
    "ghcr.io/opendesk-edu/greenlight-saml:v1.3.0"
    "ghcr.io/opendesk-edu/coderd:latest"
    "ghcr.io/opendesk-edu/code-server:latest"
    "ghcr.io/opendesk-edu/collab-dashboard:latest"
    "ghcr.io/opendesk-edu/eudi-issuer:v0.1.0"
    "ghcr.io/opendesk-edu/f13:latest"
    "ghcr.io/opendesk-edu/grommunio:latest"
    "ghcr.io/opendesk-edu/intercom:latest"
    "ghcr.io/opendesk-edu/intercom-service:latest"
    "ghcr.io/opendesk-edu/jupyterhub:latest"
    "ghcr.io/opendesk-edu/limesurvey:latest"
    "ghcr.io/opendesk-edu/ollama:latest"
    "ghcr.io/opendesk-edu/openproject:latest"
    "ghcr.io/opendesk-edu/portal-entries:latest"
    "ghcr.io/opendesk-edu/redis:latest"
    "ghcr.io/opendesk-edu/rstudio:latest"
    "ghcr.io/opendesk-edu/semester-provisioning:latest"
    "ghcr.io/opendesk-edu/slidev:latest"
    "ghcr.io/opendesk-edu/snipr:v1.0.0"
    "ghcr.io/opendesk-edu/seaweedfs:latest"
    "ghcr.io/opendesk-edu/timescale:latest"
    "ghcr.io/opendesk-edu/ttyd:latest"
    "ghcr.io/opendesk-edu/typo3:13.4.0"
    "ghcr.io/opendesk-edu/xwiki:latest"
    "ghcr.io/opendesk-edu/zammad:latest"
    "ghcr.io/tobias-weiss-ai-xr/snipr:latest"
)

# =============================================================================
# Utility Functions
# =============================================================================

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_push()    { echo -e "${MAGENTA}[PUSH]${NC} $1"; }

check_docker() {
    if ! command -v docker &>/dev/null; then
        log_error "Docker is not installed."
        exit 1
    fi
    if ! docker info &>/dev/null; then
        log_error "Docker is not running."
        exit 1
    fi
    log_info "Docker: $(docker --version)"
}

check_network() {
    log_info "Checking network connectivity to ${SOURCE_REGISTRY}..."
    if nslookup "${SOURCE_REGISTRY}" &>/dev/null 2>&1; then
        log_info "DNS OK (${SOURCE_REGISTRY} resolvable)"
    else
        log_warn "DNS lookup for ${SOURCE_REGISTRY} failed"
    fi
}

login_registry() {
    if [ -z "${OPENCODE_TOKEN:-}" ]; then
        log_error "OPENCODE_TOKEN is not set."
        log_error "Get a token from: https://gitlab.opencode.de/-/profile/personal_access_tokens"
        log_error "Required scopes: read_registry, write_registry, api"
        log_error ""
        log_error "Usage: OPENCODE_TOKEN=\"glpat-xxx\" $0"
        exit 1
    fi

    log_info "Logging in to ${TARGET_REGISTRY}..."
    if echo "$OPENCODE_TOKEN" | docker login registry.opencode.de -u "$GITLAB_USER" --password-stdin 2>&1; then
        log_success "Login successful (user: ${GITLAB_USER})"
    else
        log_error "Login failed! Check your OPENCODE_TOKEN."
        exit 1
    fi
}

# Convert a source image reference to a target image reference
# e.g. ghcr.io/opendesk-edu/sogo:latest → registry.opencode.de/umr/sogo:latest
# e.g. ghcr.io/opendesk-edu/supplier/univention/keycloak:26.7.0 → registry.opencode.de/umr/supplier/univention/keycloak:26.7.0
# e.g. ghcr.io/tobias-weiss-ai-xr/snipr:latest → registry.opencode.de/umr/snipr:latest
convert_image() {
    local source_image="$1"
    # Strip the registry prefix
    local without_registry
    without_registry="${source_image#${SOURCE_REGISTRY}/}"
    
    # Strip known sub-paths but preserve meaningful ones
    # opendesk-edu/ and tobias-weiss-ai-xr/ are registry org names, not part of image path
    # project-zot/ is also a registry org name
    local image_path
    case "$without_registry" in
        opendesk-edu/*)
            image_path="${without_registry#opendesk-edu/}"
            ;;
        tobias-weiss-ai-xr/*)
            image_path="${without_registry#tobias-weiss-ai-xr/}"
            ;;
        project-zot/*)
            image_path="${without_registry#project-zot/}"
            ;;
        *)
            image_path="$without_registry"
            ;;
    esac
    
    echo "${TARGET_REGISTRY}/${image_path}"
}

push_single_image() {
    local source_image="$1"
    local target_image
    target_image=$(convert_image "$source_image")

    log_info "  Source: ${source_image}"
    log_info "  Target: ${target_image}"

    # Pull from source
    log_info "  Pulling..."
    if ! docker pull "$source_image" 2>&1 | tail -1 | grep -qE "Downloaded newer image|Image is up to date"; then
        log_warn "  Pull may have failed for ${source_image}"
        if ! docker image inspect "$source_image" &>/dev/null; then
            log_error "  Image not available locally: ${source_image}"
            return 1
        fi
        log_info "  Using locally cached image"
    fi

    # Tag for target
    log_info "  Tagging..."
    if ! docker tag "$source_image" "$target_image"; then
        log_error "  Failed to tag ${source_image} → ${target_image}"
        return 1
    fi

    # Push to target
    log_push "  Pushing to ${target_image}..."
    if docker push "$target_image" 2>&1 | tail -1 | grep -qE "digest:|Pushed"; then
        log_success "  Pushed: ${target_image}"
        return 0
    else
        # Check if already exists
        if docker manifest inspect "$target_image" &>/dev/null 2>&1; then
            log_success "  Already exists: ${target_image}"
            return 0
        fi
        log_error "  Failed to push ${target_image}"
        return 1
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    local mode="core"
    local dry_run=false
    local list_only=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)     mode="all"; shift;;
            --core)    mode="core"; shift;;
            --list)    list_only=true; shift;;
            --dry-run) dry_run=true; shift;;
            --registry) TARGET_REGISTRY="$2"; shift 2;;
            --source)  SOURCE_REGISTRY="$2"; shift 2;;
            --help|-h)
                echo "Usage: OPENCODE_TOKEN=\"glpat-xxx\" $0 [OPTIONS]"
                echo ""
                echo "Push images from ${SOURCE_REGISTRY} to ${TARGET_REGISTRY}"
                echo ""
                echo "Options:"
                echo "  --all          Push all images (core + edu)"
                echo "  --core         Push only core images (default)"
                echo "  --list         List images that would be pushed"
                echo "  --dry-run      Show what would be pushed without pushing"
                echo "  --registry     Override target registry"
                echo "  --source       Override source registry"
                echo "  --help         Show this help"
                echo ""
                echo "Environment:"
                echo "  OPENCODE_TOKEN    GitLab PAT (required)"
                echo "  OPENCODE_USER     GitLab username (default: weiss)"
                echo "  OPENCODE_REGISTRY Target registry (default: registry.opencode.de/umr)"
                echo ""
                echo "Core images:"
                for img in "${CORE_IMAGES[@]}"; do
                    echo "  ${img}"
                done
                echo ""
                echo "EDU images (--all):"
                for img in "${EDU_IMAGES[@]}"; do
                    echo "  ${img}"
                done
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Build image list
    declare -a IMAGES=()
    if [ "$mode" = "all" ]; then
        IMAGES=("${CORE_IMAGES[@]}" "${EDU_IMAGES[@]}")
    else
        IMAGES=("${CORE_IMAGES[@]}")
    fi

    # List mode
    if [ "$list_only" = true ]; then
        echo -e "${CYAN}Images to push (${mode}):${NC}"
        echo ""
        for img in "${IMAGES[@]}"; do
            local target
            target=$(convert_image "$img")
            printf "  %-70s → %s\n" "$img" "$target"
        done
        echo ""
        echo "Total: ${#IMAGES[@]} images"
        echo "Target registry: ${TARGET_REGISTRY}"
        exit 0
    fi

    # Dry-run mode
    if [ "$dry_run" = true ]; then
        echo -e "${CYAN}Dry-run mode — no images will be pushed${NC}"
        echo ""
        log_info "Source registry: ${SOURCE_REGISTRY}"
        log_info "Target registry: ${TARGET_REGISTRY}"
        log_info "Mode: ${mode}"
        log_info "Images: ${#IMAGES[@]}"
        echo ""
        for img in "${IMAGES[@]}"; do
            local target
            target=$(convert_image "$img")
            printf "  %-70s → %s\n" "$img" "$target"
        done
        exit 0
    fi

    # Real mode
    check_docker
    check_network
    login_registry

    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}  Push Images to opencode.de Container Registry${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "  Source:  ${SOURCE_REGISTRY}"
    echo -e "  Target:  ${TARGET_REGISTRY}"
    echo -e "  Mode:    ${mode}"
    echo -e "  Images:  ${#IMAGES[@]}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    local success=0
    local failed=0
    local failed_images=()

    for img in "${IMAGES[@]}"; do
        echo -e "${CYAN}─── $((success + failed + 1))/${#IMAGES[@]} ───${NC}"
        if push_single_image "$img"; then
            success=$((success + 1))
        else
            failed=$((failed + 1))
            failed_images+=("$img")
        fi
        echo ""
    done

    # Summary
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}  PUSH SUMMARY${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "  ${GREEN}Pushed${NC}:  ${success}"
    echo -e "  ${RED}Failed${NC}:  ${failed}"
    echo -e "  Total:   ${#IMAGES[@]}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"

    if [ ${failed} -gt 0 ]; then
        echo ""
        echo -e "${RED}Failed images:${NC}"
        for img in "${failed_images[@]}"; do
            echo "  - ${img}"
        done
        exit 1
    fi

    echo ""
    log_success "All images pushed to ${TARGET_REGISTRY}"
    echo ""
    echo "Next steps:"
    echo "  1. Verify: docker manifest inspect ${TARGET_REGISTRY}/sogo:latest"
    echo "  2. Deploy: kubectl apply -f image-source-opencode.yaml"
    echo "  3. Toggle: Use image-source-toggle.yaml to switch between GHCR and opencode.de"
}

main "$@"

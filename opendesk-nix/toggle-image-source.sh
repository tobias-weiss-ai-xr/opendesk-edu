#!/bin/bash
# =============================================================================
# Toggle Image Source for OpenDesk EDU
#
# Switches all image references between:
#   ghcr     → ghcr.io/opendesk-edu/* (GitHub Container Registry)
#   opencode → registry.gitlab.opencode.de/umr/* (GitLab Container Registry)
#   zot      → zot-registry.opendesk.svc:5000/* (local Zot cache)
#
# Usage:
#   ./toggle-image-source.sh ghcr       # Use GHCR (default)
#   ./toggle-image-source.sh opencode   # Use opencode.de CR
#   ./toggle-image-source.sh zot        # Use local Zot cache
#   ./toggle-image-source.sh status     # Show current configuration
#
# This script updates:
#   - helmfile/environments/edu/images.yaml
#   - helmfile/charts/{sogo,stalwart,opencloud}/values.yaml
#   - argocd-opendesk/minimal-deployment/*.yaml
#   - nix/k8s/*.nix
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# =============================================================================
# Image registry mappings
# =============================================================================

# GHCR (default)
GHCR_REGISTRY="ghcr.io"
GHCR_PREFIX="opendesk-edu"

# opencode.de GitLab CR
OPENCODE_REGISTRY="registry.gitlab.opencode.de"
OPENCODE_PREFIX="umr"

# Zot local cache
ZOT_REGISTRY="zot-registry.opendesk.svc:5000"
ZOT_PREFIX="opendesk-edu"

# =============================================================================
# Image mappings (source name → target name)
# =============================================================================

declare -A IMAGE_MAP=(
    ["postgresql"]="postgresql"
    ["memcached"]="memcached"
    ["sogo"]="sogo"
    ["stalwart"]="stalwart"
    ["opencloud"]="opencloud"
    ["keycloak"]="supplier/univention/keycloak"
    ["bookstack"]="bookstack"
    ["drawio"]="drawio"
    ["excalidraw"]="excalidraw"
    ["planka"]="planka"
    ["self-service-password"]="self-service-password"
    ["user-import"]="user-import"
    ["opendesk-dev-agent-operator"]="opendesk-dev-agent-operator"
    ["moodle-shib"]="moodle-shib"
    ["ilias-shibboleth"]="ilias-shibboleth"
    ["ilias"]="ilias"
    ["moodle"]="moodle"
    ["collabora"]="collabora"
    ["clamav"]="clamav"
    ["etherpad"]="etherpad"
    ["element"]="element"
    ["mariadb"]="mariadb"
    ["redis"]="redis"
    ["snipr"]="snipr"
)

# Special: snipr is under tobias-weiss-ai-xr on GHCR, but umr on opencode
declare -A GHCR_SPECIAL_PREFIX=(
    ["snipr"]="tobias-weiss-ai-xr"
)

# Image tags
declare -A IMAGE_TAGS=(
    ["postgresql"]="latest"
    ["memcached"]="latest"
    ["sogo"]="latest"
    ["stalwart"]="latest"
    ["opencloud"]="4.0.3"
    ["keycloak"]="26.7.0"
    ["bookstack"]="latest"
    ["drawio"]="latest"
    ["excalidraw"]="latest"
    ["planka"]="latest"
    ["self-service-password"]="latest"
    ["user-import"]="latest"
    ["opendesk-dev-agent-operator"]="latest"
    ["moodle-shib"]="latest"
    ["ilias-shibboleth"]="latest"
    ["ilias"]="latest"
    ["moodle"]="latest"
    ["collabora"]="latest"
    ["clamav"]="latest"
    ["etherpad"]="1.9.9"
    ["element"]="latest"
    ["mariadb"]="latest"
    ["redis"]="latest"
    ["snipr"]="latest"
)

# =============================================================================
# Functions
# =============================================================================

show_status() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  OpenDesk EDU Image Source Status${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Check helmfile images.yaml
    local images_file="${REPO_ROOT}/opendesk-edu/helmfile/environments/edu/images.yaml"
    if [ -f "$images_file" ]; then
        local current_reg
        current_reg=$(grep -m1 "repository:" "$images_file" | sed 's/.*repository: *//' | sed 's/\/.*//')
        echo "  helmfile images.yaml registry: ${current_reg}"
    fi

    # Check chart defaults
    for chart in sogo stalwart opencloud; do
        local values_file="${REPO_ROOT}/opendesk-edu/helmfile/charts/${chart}/values.yaml"
        if [ -f "$values_file" ]; then
            local reg
            reg=$(grep -A1 "image:" "$values_file" | grep "registry:" | head -1 | sed 's/.*registry: *//')
            echo "  chart ${chart}: ${reg}"
        fi
    done

    # Check ArgoCD manifests
    for f in "${REPO_ROOT}"/argocd-opendesk/minimal-deployment/opendesk-*-internal.yaml; do
        if [ -f "$f" ]; then
            local name
            name=$(basename "$f" .yaml)
            local reg
            reg=$(grep -m1 "registry:" "$f" | sed 's/.*registry: *//')
            echo "  ArgoCD ${name}: ${reg}"
        fi
    done

    # Check nix
    for nix in "${REPO_ROOT}"/opendesk-edu/nix/k8s/{sogo,stalwart,opencloud}.nix; do
        if [ -f "$nix" ]; then
            local name
            name=$(basename "$nix" .nix)
            local img
            img=$(grep "image = " "$nix" | head -1 | sed 's/.*image = "//; s/".*//')
            echo "  nix ${name}: ${img}"
        fi
    done

    echo ""
    echo "  Available sources:"
    echo "    ghcr     → ${GHCR_REGISTRY}/${GHCR_PREFIX}/*"
    echo "    opencode → ${OPENCODE_REGISTRY}/${OPENCODE_PREFIX}/*"
    echo "    zot      → ${ZOT_REGISTRY}/${ZOT_PREFIX}/*"
    echo ""
}

update_helmfile_images() {
    local source="$1"
    local images_file="${REPO_ROOT}/opendesk-edu/helmfile/environments/edu/images.yaml"

    log_info "Updating ${images_file}"

    case "$source" in
        ghcr)
            cat > "$images_file" << 'EOF'
images:
  stalwart:
    repository: ghcr.io/opendesk-edu/stalwart
    tag: latest
  opencloud:
    repository: ghcr.io/opendesk-edu/opencloud
    tag: 4.0.3
  typo3:
    repository: ghcr.io/opendesk/typo3
    tag: 13.4.0
  mayan:
    repository: docker.io/mayanedms/mayanedms
    tag: 4.5.0
    pullPolicy: IfNotPresent
  paperless:
    repository: ghcr.io/paperless-ngx/paperless-ngx
    tag: 2.12.0
    pullPolicy: IfNotPresent
EOF
            ;;
        opencode)
            cat > "$images_file" << 'EOF'
images:
  stalwart:
    repository: registry.gitlab.opencode.de/umr/stalwart
    tag: latest
  opencloud:
    repository: registry.gitlab.opencode.de/umr/opencloud
    tag: 4.0.3
  typo3:
    repository: registry.gitlab.opencode.de/umr/typo3
    tag: 13.4.0
  mayan:
    repository: registry.gitlab.opencode.de/umr/mayanedms
    tag: 4.5.0
    pullPolicy: IfNotPresent
  paperless:
    repository: registry.gitlab.opencode.de/umr/paperless-ngx
    tag: 2.12.0
    pullPolicy: IfNotPresent
EOF
            ;;
        zot)
            cat > "$images_file" << 'EOF'
images:
  stalwart:
    repository: zot-registry.opendesk.svc:5000/opendesk-edu/stalwart
    tag: latest
  opencloud:
    repository: zot-registry.opendesk.svc:5000/opendesk-edu/opencloud
    tag: 4.0.3
  typo3:
    repository: zot-registry.opendesk.svc:5000/opendesk/typo3
    tag: 13.4.0
  mayan:
    repository: zot-registry.opendesk.svc:5000/mayanedms/mayanedms
    tag: 4.5.0
    pullPolicy: IfNotPresent
  paperless:
    repository: zot-registry.opendesk.svc:5000/paperless-ngx/paperless-ngx
    tag: 2.12.0
    pullPolicy: IfNotPresent
EOF
            ;;
    esac
    log_success "Updated helmfile images.yaml → ${source}"
}

update_chart_values() {
    local source="$1"
    local registry prefix

    case "$source" in
        ghcr)     registry="$GHCR_REGISTRY"; prefix="$GHCR_PREFIX";;
        opencode) registry="$OPENCODE_REGISTRY"; prefix="$OPENCODE_PREFIX";;
        zot)      registry="$ZOT_REGISTRY"; prefix="$ZOT_PREFIX";;
    esac

    # SOGo
    local sogo_file="${REPO_ROOT}/opendesk-edu/helmfile/charts/sogo/values.yaml"
    if [ -f "$sogo_file" ]; then
        log_info "Updating ${sogo_file}"
        sed -i "s|registry:.*|registry: ${registry}|" "$sogo_file"
        sed -i "s|repository:.*|repository: ${prefix}/sogo|" "$sogo_file"
        log_success "  sogo → ${registry}/${prefix}/sogo"
    fi

    # Stalwart
    local stalwart_file="${REPO_ROOT}/opendesk-edu/helmfile/charts/stalwart/values.yaml"
    if [ -f "$stalwart_file" ]; then
        log_info "Updating ${stalwart_file}"
        sed -i "s|registry:.*|registry: ${registry}|" "$stalwart_file"
        sed -i "s|repository:.*|repository: ${prefix}/stalwart|" "$stalwart_file"
        log_success "  stalwart → ${registry}/${prefix}/stalwart"
    fi

    # OpenCloud
    local opencloud_file="${REPO_ROOT}/opendesk-edu/helmfile/charts/opencloud/values.yaml"
    if [ -f "$opencloud_file" ]; then
        log_info "Updating ${opencloud_file}"
        sed -i "s|registry:.*|registry: ${registry}|" "$opencloud_file"
        sed -i "s|repository:.*|repository: ${prefix}/opencloud|" "$opencloud_file"
        log_success "  opencloud → ${registry}/${prefix}/opencloud"
    fi
}

update_argocd_manifests() {
    local source="$1"
    local registry prefix

    case "$source" in
        ghcr)     registry="$GHCR_REGISTRY"; prefix="$GHCR_PREFIX";;
        opencode) registry="$OPENCODE_REGISTRY"; prefix="$OPENCODE_PREFIX";;
        zot)      registry="$ZOT_REGISTRY"; prefix="$ZOT_PREFIX";;
    esac

    for f in "${REPO_ROOT}"/argocd-opendesk/minimal-deployment/opendesk-*.yaml; do
        if [ ! -f "$f" ]; then continue; fi
        local name
        name=$(basename "$f" .yaml)
        log_info "Updating ${name}"

        # Replace registry and repository in image blocks
        sed -i "s|registry: ghcr.io|registry: ${registry}|g" "$f"
        sed -i "s|registry: registry.gitlab.opencode.de|registry: ${registry}|g" "$f"
        sed -i "s|registry: zot-registry.opendesk.svc:5000|registry: ${registry}|g" "$f"
        sed -i "s|registry: docker.io|registry: ${registry}|g" "$f"

        # Replace repository prefixes
        sed -i "s|repository: opendesk-edu/|repository: ${prefix}/|g" "$f"
        sed -i "s|repository: opencloudeu/|repository: ${prefix}/|g" "$f"
        sed -i "s|repository: stalwartlabs/|repository: ${prefix}/|g" "$f"
        sed -i "s|repository: weissto/|repository: ${prefix}/|g" "$f"
        sed -i "s|repository: umr/|repository: ${prefix}/|g" "$f"

        log_success "  ${name} → ${registry}/${prefix}"
    done

    # Also update values-minimal.yaml
    local values_file="${REPO_ROOT}/argocd-opendesk/minimal-deployment/values-minimal.yaml"
    if [ -f "$values_file" ]; then
        log_info "Updating values-minimal.yaml"
        sed -i "s|registry: ghcr.io|registry: ${registry}|g" "$values_file"
        sed -i "s|registry: registry.gitlab.opencode.de|registry: ${registry}|g" "$values_file"
        sed -i "s|registry: zot-registry.opendesk.svc:5000|registry: ${registry}|g" "$values_file"
        sed -i "s|registry: docker.io|registry: ${registry}|g" "$values_file"
        sed -i "s|repository: opendesk-edu/|repository: ${prefix}/|g" "$values_file"
        sed -i "s|repository: opencloudeu/|repository: ${prefix}/|g" "$values_file"
        sed -i "s|repository: stalwartlabs/|repository: ${prefix}/|g" "$values_file"
        sed -i "s|repository: weissto/|repository: ${prefix}/|g" "$values_file"
        sed -i "s|repository: umr/|repository: ${prefix}/|g" "$values_file"
        log_success "  values-minimal.yaml updated"
    fi
}

update_nix() {
    local source="$1"
    local registry prefix

    case "$source" in
        ghcr)     registry="$GHCR_REGISTRY"; prefix="$GHCR_PREFIX";;
        opencode) registry="$OPENCODE_REGISTRY"; prefix="$OPENCODE_PREFIX";;
        zot)      registry="$ZOT_REGISTRY"; prefix="$ZOT_PREFIX";;
    esac

    for nix in "${REPO_ROOT}"/opendesk-edu/nix/k8s/{sogo,stalwart,opencloud,postgresql,memcached,mariadb,redis}.nix; do
        if [ ! -f "$nix" ]; then continue; fi
        local name
        name=$(basename "$nix" .nix)
        log_info "Updating nix/${name}.nix"

        # Replace image = "..." patterns
        sed -i "s|image = \"ghcr.io/opendesk-edu/|image = \"${registry}/${prefix}/|g" "$nix"
        sed -i "s|image = \"registry.gitlab.opencode.de/umr/|image = \"${registry}/${prefix}/|g" "$nix"
        sed -i "s|image = \"zot-registry.opendesk.svc:5000/opendesk-edu/|image = \"${registry}/${prefix}/|g" "$nix"
        sed -i "s|image = \"docker.io/opencloudeu/|image = \"${registry}/${prefix}/|g" "$nix"
        sed -i "s|image = \"docker.io/stalwartlabs/|image = \"${registry}/${prefix}/|g" "$nix"
        sed -i "s|image = \"weissto/|image = \"${registry}/${prefix}/|g" "$nix"

        log_success "  nix/${name}.nix updated"
    done
}

# =============================================================================
# Main
# =============================================================================

main() {
    local source="${1:-status}"

    case "$source" in
        ghcr|opencode|zot)
            echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${CYAN}  Switching image source to: ${source}${NC}"
            echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
            echo ""

            update_helmfile_images "$source"
            update_chart_values "$source"
            update_argocd_manifests "$source"
            update_nix "$source"

            echo ""
            log_success "All image sources switched to: ${source}"
            echo ""
            show_status
            ;;
        status)
            show_status
            ;;
        *)
            echo "Usage: $0 {ghcr|opencode|zot|status}"
            echo ""
            echo "  ghcr     → ghcr.io/opendesk-edu/* (GitHub Container Registry)"
            echo "  opencode → registry.gitlab.opencode.de/umr/* (GitLab CR)"
            echo "  zot      → zot-registry.opendesk.svc:5000/* (local Zot cache)"
            echo "  status   → Show current image source configuration"
            exit 1
            ;;
    esac
}

main "$@"

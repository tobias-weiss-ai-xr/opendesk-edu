#!/bin/bash
# Push Docker Images to GitLab Container Registry (opencode.de)
# Usage: OPENCODE_TOKEN="your-pat" ./push-to-gitlab.sh
# Target: registry.gitlab.opencode.de/umr/

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REGISTRY="registry.gitlab.opencode.de/umr"

# Check for token
if [ -z "$OPENCODE_TOKEN" ]; then
    echo -e "${YELLOW}Please enter your GitLab opencode.de Personal Access Token:${NC}"
    echo "Get it from: https://gitlab.opencode.de/-/profile/personal_access_tokens"
    echo "Required scopes: read_registry, write_registry, api"
    read -rs OPENCODE_TOKEN
    echo ""
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Docker
if ! command_exists docker; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
    exit 1
fi

# Check kubectl
if ! command_exists kubectl; then
    echo -e "${YELLOW}Warning: kubectl not found. Kubernetes integration will be skipped.${NC}"
    KUBECTL_AVAILABLE=false
else
    KUBECTL_AVAILABLE=true
fi

# Login
echo -e "${GREEN}=== Step 1/4: Logging in to $REGISTRY ===${NC}"
if ! echo "$OPENCODE_TOKEN" | docker login registry.gitlab.opencode.de -u weiss --password-stdin 2>&1; then
    echo -e "${RED}Login failed! Please check your token.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Login successful${NC}"
echo ""

# Create pull secret for Kubernetes
echo -e "${GREEN}=== Step 2/4: Creating Kubernetes pull secret ===${NC}"
if [ "$KUBECTL_AVAILABLE" = true ]; then
    kubectl create secret docker-registry gitlab-registry-opencode \
      --docker-server=registry.gitlab.opencode.de \
      --docker-username=weiss \
      --docker-password=$OPENCODE_TOKEN \
      --docker-email=tobias.weiss@hrz.uni-marburg.de \
      --dry-run=client -o yaml > /tmp/gitlab-registry-secret.yaml 2>/dev/null
    
    if [ -f /tmp/gitlab-registry-secret.yaml ]; then
        echo -e "${GREEN}✓ Pull secret YAML created at /tmp/gitlab-registry-secret.yaml${NC}"
        echo "  Apply with: kubectl apply -f /tmp/gitlab-registry-secret.yaml"
    else
        echo -e "${YELLOW}Warning: Could not create pull secret YAML${NC}"
    fi
else
    echo -e "${YELLOW}Skipping pull secret creation (kubectl not available)${NC}"
fi
echo ""

# Push Images
echo -e "${GREEN}=== Step 3/4: Pushing Docker images ===${NC}"

# Function to push an image
push_image() {
    local image_name=$1
    local build_cmd=$2
    local dockerfile=$3
    local context=$4
    
    echo -e "${BLUE}--- Pushing $image_name ---${NC}"
    
    if [ -n "$build_cmd" ]; then
        echo -e "  Building with custom command..."
        if ! eval "$build_cmd"; then
            echo -e "  ${YELLOW}Build failed for $image_name, skipping...${NC}"
            return 1
        fi
    else
        echo -e "  Building $image_name..."
        cd "$context"
        if [ -n "$dockerfile" ]; then
            if ! docker build -t $REGISTRY/$image_name:latest -f "$dockerfile" .; then
                echo -e "  ${YELLOW}Build failed for $image_name, skipping...${NC}"
                return 1
            fi
        else
            if ! docker build -t $REGISTRY/$image_name:latest .; then
                echo -e "  ${YELLOW}Build failed for $image_name, skipping...${NC}"
                return 1
            fi
        fi
        cd - >/dev/null
    fi
    
    echo -e "  Pushing $REGISTRY/$image_name:latest..."
    if docker push $REGISTRY/$image_name:latest; then
        echo -e "  ${GREEN}✓ $image_name pushed successfully${NC}"
        return 0
    else
        echo -e "  ${RED}✗ Failed to push $image_name${NC}"
        return 1
    fi
}

# Push all images
SUCCESS_COUNT=0
TOTAL_COUNT=0

# 1. Website
TOTAL_COUNT=$((TOTAL_COUNT + 1))
if push_image "opendesk-edu-website" "" "" "../opendesk-edu-website"; then
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
fi

# 2. Dev Agent (from operator repo)
TOTAL_COUNT=$((TOTAL_COUNT + 1))
if push_image "dev-agent" "make docker-build" "" "../opendesk-dev-agent-operator"; then
    docker tag opendesk-dev-agent-operator:latest $REGISTRY/dev-agent:latest 2>/dev/null || true
    docker push $REGISTRY/dev-agent:latest 2>/dev/null && SUCCESS_COUNT=$((SUCCESS_COUNT + 1)) || true
fi

# 3. SBOM Generator
TOTAL_COUNT=$((TOTAL_COUNT + 1))
if push_image "sbom-generator" "" "docker/sbom-generator/Dockerfile" "../opendesk-edu-website"; then
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
fi

echo ""
echo -e "${GREEN}=== Step 4/4: Summary ===${NC}"
echo -e "Pushed $SUCCESS_COUNT/$TOTAL_COUNT images"
echo ""

if [ $SUCCESS_COUNT -eq $TOTAL_COUNT ]; then
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}✓ ALL IMAGES PUSHED TO GITLAB REGISTRY${NC}"
    echo -e "${GREEN}=====================================${NC}"
else
    echo -e "${YELLOW}Some images failed to push. See errors above.${NC}"
fi

echo ""
echo "Images available at:"
echo "  $REGISTRY/opendesk-edu-website:latest"
echo "  $REGISTRY/dev-agent:latest"
echo "  $REGISTRY/sbom-generator:latest"
echo ""

if [ -f /tmp/gitlab-registry-secret.yaml ]; then
    echo "Kubernetes pull secret:"
    echo "  kubectl apply -f /tmp/gitlab-registry-secret.yaml"
fi

echo ""
echo "Next steps:"
echo "  1. Deploy to Kubernetes: make -C opendesk-nix deploy"
echo "  2. Or use Kustomize: kubectl apply -k opendesk-nix/k8s/"

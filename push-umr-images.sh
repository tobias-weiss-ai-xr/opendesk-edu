#!/bin/bash
# Push Docker Images to opencode.de/umr/
# Usage: OPENCODE_TOKEN="your-pat" ./push-umr-images.sh
# Or: ./push-umr-images.sh (will prompt for token)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

REGISTRY="registry.opencode.de/umr"

# Check if token is provided
if [ -z "$OPENCODE_TOKEN" ]; then
    echo -e "${YELLOW}Please enter your opencode.de Personal Access Token:${NC}"
    echo "Get it from: https://gitlab.opencode.de/-/profile/personal_access_tokens"
    echo "Required scopes: read_registry, write_registry, api"
    read -rs OPENCODE_TOKEN
    echo ""
fi

# Login to registry
echo -e "${GREEN}=== Logging in to registry.opencode.de ===${NC}"
if ! echo "$OPENCODE_TOKEN" | docker login registry.opencode.de -u weiss --password-stdin 2>&1; then
    echo -e "${RED}Login failed. Please verify your token:${NC}"
    echo "1. Go to: https://gitlab.opencode.de/-/profile/personal_access_tokens"
    echo "2. Create new token with scopes: read_registry, write_registry, api"
    echo "3. Try again"
    exit 1
fi
echo -e "${GREEN}✓ Login successful${NC}"

# Function to build and push an image
push_image() {
    local name="$1"
    local context="$2"
    local dockerfile="$3"
    local tag="${4:-latest}"
    
    echo ""
    echo -e "${GREEN}=== Building $name ===${NC}"
    
    cd "$context"
    
    if [ -n "$dockerfile" ]; then
        echo "Building with Dockerfile: $dockerfile"
        docker build -t "$REGISTRY/$name:$tag" -f "$dockerfile" .
    else
        echo "Building with default Dockerfile"
        docker build -t "$REGISTRY/$name:$tag" .
    fi
    
    echo -e "${GREEN}=== Pushing $name:$tag ===${NC}"
    docker push "$REGISTRY/$name:$tag"
    echo -e "${GREEN}✓ $name:$tag pushed successfully${NC}"
}

echo ""
echo -e "${YELLOW}Starting image build and push process...${NC}"
echo "Registry: $REGISTRY"
echo ""

# Build and push each image
# Order: Fastest wins first

# 1. Website (Next.js) - Fastest
echo -e "${YELLOW}--- 1/5: Website ---${NC}"
push_image "opendesk-edu-website" \
    "/home/weissto_local/git/opendesk_git/opendesk-edu-website" \
    "Dockerfile"

# 2. SBOM Generator
echo -e "${YELLOW}--- 2/5: SBOM Generator ---${NC}"
push_image "sbom-generator" \
    "/home/weissto_local/git/opendesk_git/opendesk-edu-website" \
    "docker/sbom-generator/Dockerfile"

# 3. Dev Agent
echo -e "${YELLOW}--- 3/5: Dev Agent ---${NC}"
push_image "dev-agent" \
    "/home/weissto_local/git/opendesk_git/opendesk-dev-agent-operator" \
    "Dockerfile"

# 4. SOGo 5 (if Dockerfile exists)
echo -e "${YELLOW}--- 4/5: SOGo 5 ---${NC}"
SOGO5_DIR="/path/to/sogo5/dockerfile"
if [ -f "$SOGO5_DIR/Dockerfile" ] || [ -f "$SOGO5_DIR/Dockerfile.sogo5" ]; then
    push_image "sogo5" "$SOGO5_DIR" "Dockerfile.sogo5"
else
    echo -e "${YELLOW}⚠SOGo 5: Dockerfile not found at $SOGO5_DIR${NC}"
    echo "  Please provide Dockerfile path and re-run"
fi

# 5. SOGo 6 (if Dockerfile exists)
echo -e "${YELLOW}--- 5/5: SOGo 6 ---${NC}"
SOGO6_DIR="/path/to/sogo6/dockerfile"
if [ -f "$SOGO6_DIR/Dockerfile" ] || [ -f "$SOGO6_DIR/Dockerfile.sogo6" ]; then
    push_image "sogo6" "$SOGO6_DIR" "Dockerfile.sogo6"
else
    echo -e "${YELLOW}⚠SOGo 6: Dockerfile not found at $SOGO6_DIR${NC}"
    echo "  Please provide Dockerfile path and re-run"
fi

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}✓ ALL DONE!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo "Images pushed to: $REGISTRY/"
echo ""
echo "Available images:"
echo "  • $REGISTRY/opendesk-edu-website:latest"
echo "  • $REGISTRY/sbom-generator:latest"
echo "  • $REGISTRY/dev-agent:latest"
echo ""
if [ -f "$SOGO5_DIR/Dockerfile" ] || [ -f "$SOGO5_DIR/Dockerfile.sogo5" ]; then
    echo "  • $REGISTRY/sogo5:latest"
fi
if [ -f "$SOGO6_DIR/Dockerfile" ] || [ -f "$SOGO6_DIR/Dockerfile.sogo6" ]; then
    echo "  • $REGISTRY/sogo6:latest"
fi
echo ""
echo "Verify with:"
echo "  curl -u weiss:\$OPENCODE_TOKEN https://registry.opencode.de/v2/umr/tags/list | jq ."
echo ""
echo "Next steps:"
echo "  1. Update Kubernetes manifests with new image URLs"
echo "  2. Create pull secret: kubectl create secret docker-registry opencode-de-registry --docker-server=registry.opencode.de --docker-username=weiss --docker-password=\$OPENCODE_TOKEN --docker-email=your@email.de"
echo "  3. Deploy with: kubectl apply -f your-deployment.yaml"

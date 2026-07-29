#!/bin/bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Build and push custom openDesk Edu images to registries.
# Usage: ./scripts/build-and-push.sh [image-name]
#   If image-name is omitted, builds and pushes all images.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
IMAGES_DIR="$PROJECT_DIR/images"

# Registry configuration
ZOT_REGISTRY="${ZOT_REGISTRY:-172.17.209.143:5000}"
GITLAB_REGISTRY="${GITLAB_REGISTRY:-registry.gitlab.com/tbsweiss/opendesk-edu}"
GHCR_REGISTRY="${GHCR_REGISTRY:-ghcr.io/opendesk-edu}"

# Image definitions: name:dockerfile_dir:tag
# Custom-built images (have Dockerfiles in images/)
IMAGES=(
  "mariadb:mariadb:11.4.4"
  "ilias-shibboleth:ilias-shibboleth:9-php8.2-apache"
  "moodle-shib:moodle-shib:v1.4.0"
)

# Mirrored images (pulled from upstream, pushed to our registries)
MIRRORS=(
  "drawio:jgraph/drawio:latest"
  "excalidraw:excalidraw/excalidraw:latest"
  "self-service-password:ltbproject/self-service-password:latest"
  "planka:ghcr.io/plankanban/planka:latest"
  "bookstack:linuxserver/bookstack:latest"
)

build_and_push() {
  local img_name="$1"
  local img_dir="$2"
  local img_tag="$3"

  echo "=== Building $img_name:$img_tag ==="
  docker build -t "opendesk-$img_name:$img_tag" "$IMAGES_DIR/$img_dir"

  # Push to Zot (local)
  echo "--- Pushing to Zot ($ZOT_REGISTRY) ---"
  kubectl port-forward -n registry svc/zot 5000:5000 &>/dev/null &
  PF_PID=$!
  sleep 2
  docker tag "opendesk-$img_name:$img_tag" "localhost:5000/opendesk-edu/$img_name:$img_tag"
  docker push "localhost:5000/opendesk-edu/$img_name:$img_tag"
  kill "$PF_PID" 2>/dev/null || true

  # Push to GitLab
  echo "--- Pushing to GitLab ($GITLAB_REGISTRY) ---"
  docker tag "opendesk-$img_name:$img_tag" "$GITLAB_REGISTRY/$img_name:$img_tag"
  docker push "$GITLAB_REGISTRY/$img_name:$img_tag"

  # Push to GHCR (requires write:packages token)
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    echo "--- Pushing to GHCR ($GHCR_REGISTRY) ---"
    echo "$GITHUB_TOKEN" | docker login ghcr.io -u "${GITHUB_USER:-tobias-weiss-ai-xr}" --password-stdin &>/dev/null
    docker tag "opendesk-$img_name:$img_tag" "$GHCR_REGISTRY/$img_name:$img_tag"
    docker push "$GHCR_REGISTRY/$img_name:$img_tag" 2>&1 || echo "GHCR push failed (token may lack write:packages scope)"
  else
    echo "--- Skipping GHCR (GITHUB_TOKEN not set) ---"
  fi

  echo "=== Done: $img_name:$img_tag ==="
  echo ""
}



# Mirror images (pull + retag + push without building)
mirror_and_push() {
  local img_name="$1"
  local upstream="$2"
  local img_tag="$3"

  echo "=== Mirroring $img_name from $upstream:$img_tag ==="
  docker pull "$upstream:$img_tag" || { echo "Pull failed for $upstream:$img_tag"; return 1; }

  # Push to Zot
  echo "--- Pushing to Zot ---"
  kubectl port-forward -n registry svc/zot 5000:5000 &>/dev/null &
  PF_PID=$!
  sleep 2
  docker tag "$upstream:$img_tag" "localhost:5000/opendesk-edu/$img_name:$img_tag"
  docker push "localhost:5000/opendesk-edu/$img_name:$img_tag" 2>/dev/null
  kill "$PF_PID" 2>/dev/null || true

  # Push to GHCR
  echo "--- Pushing to GHCR ---"
  docker tag "$upstream:$img_tag" "$GHCR_REGISTRY/$img_name:$img_tag"
  docker push "$GHCR_REGISTRY/$img_name:$img_tag" 2>&1 || echo "GHCR push failed"

  echo "=== Mirrored: $img_name:$img_tag ==="
  echo ""
}

# Build custom images
for img_def in "${IMAGES[@]}"; do
  name="${img_def%%:*}"
  rest="${img_def#*:}"
  dir="${rest%%:*}"
  tag="${rest#*:}"
  build_and_push "$name" "$dir" "$tag"
done

# Mirror upstream images
for img_def in "${MIRRORS[@]}"; do
  name="${img_def%%:*}"
  rest="${img_def#*:}"
  upstream="${rest%%:*}"
  tag="${rest#*:}"
  mirror_and_push "$name" "$upstream" "$tag"
done

echo "=== All images built and pushed ==="

# Supplier mirrors (key third-party images we depend on)
mirror_supplier() {
  local category="$1"
  local name="$2"
  local tag="$3"
  local source="$4"
  
  echo "=== Mirroring $category/$name:$tag ==="
  docker pull "$source:$tag" 2>/dev/null | tail -1 || return 1
  
  for registry in "$GHCR_REGISTRY/supplier" "$GITLAB_REGISTRY/supplier"; do
    docker tag "$source:$tag" "$registry/$category/$name:$tag"
    docker push "$registry/$category/$name:$tag" 2>/dev/null | tail -2
  done
  echo "✅ $category/$name mirrored"
}

# Uncomment to run:
# mirror_supplier univention intercom-service 2.24.0 "$OPENDESK_REGISTRY/supplier/univention/images-mirror/intercom-service"
# mirror_supplier collabora online 25.04.11.3.1 "$OPENDESK_REGISTRY/supplier/collabora/images/collabora-online-for-opendesk"

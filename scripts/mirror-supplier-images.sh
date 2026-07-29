#!/bin/bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Mirror critical supplier images to our registries.
# Usage: ./scripts/mirror-supplier-images.sh [category]
#   category: univention | collabora | element | nordeck | community | all

set -euo pipefail

GHCR="ghcr.io/opendesk-edu/supplier"
GITLAB="registry.gitlab.com/tbsweiss/opendesk-edu/supplier"
OPENDESK_REGISTRY="registry.opencode.de/bmi/opendesk/components"

mirror_image() {
  local source="$1"
  local target_name="$2"
  
  echo "--- $target_name ---"
  
  # Pull from opencode.de
  docker pull "$source" 2>/dev/null | tail -1
  
  # Push to GHCR
  docker tag "$source" "$GHCR/$target_name:latest"
  docker push "$GHCR/$target_name:latest" 2>/dev/null | tail -2
  
  # Push to GitLab
  docker tag "$source" "$GITLAB/$target_name:latest"
  docker push "$GITLAB/$target_name:latest" 2>/dev/null | tail -2
  
  echo "✅ $target_name mirrored"
}

mirror_univention() {
  echo "=== Univention (Nubus stack) ==="
  mirror_image "$OPENDESK_REGISTRY/supplier/univention/images-mirror/keycloak:26.7.0" "univention/keycloak"
  mirror_image "$OPENDESK_REGISTRY/supplier/univention/images-mirror/ldap-server:0.48.2" "univention/ldap-server"
  mirror_image "$OPENDESK_REGISTRY/supplier/univention/images-mirror/portal-server:0.94.16" "univention/portal-server"
  mirror_image "$OPENDESK_REGISTRY/supplier/univention/images-mirror/portal-frontend:0.94.16" "univention/portal-frontend"
  mirror_image "$OPENDESK_REGISTRY/supplier/univention/images-mirror/provisioning-api:0.70.22" "univention/provisioning-api"
  mirror_image "$OPENDESK_REGISTRY/supplier/univention/images-mirror/udm-rest-api:0.44.2" "univention/udm-rest-api"
  mirror_image "$OPENDESK_REGISTRY/supplier/univention/images-mirror/intercom-service:2.24.0" "univention/intercom-service"
}

mirror_collabora() {
  echo "=== Collabora ==="
  mirror_image "$OPENDESK_REGISTRY/supplier/collabora/images/collabora-online-for-opendesk:25.04.11.3.1" "collabora/online"
}

mirror_element() {
  echo "=== Element ==="
  mirror_image "$OPENDESK_REGISTRY/supplier/element/images/opendesk-element-web:v1.12.6" "element/web"
}

mirror_nordeck() {
  echo "=== Nordeck (Jitsi) ==="
  mirror_image "$OPENDESK_REGISTRY/supplier/nordeck/images-mirror/web:stable-11031" "nordeck/jitsi-web"
  mirror_image "$OPENDESK_REGISTRY/supplier/nordeck/images-mirror/jicofo:stable-11031" "nordeck/jitsi-jicofo"
  mirror_image "$OPENDESK_REGISTRY/supplier/nordeck/images-mirror/jvb:stable-11031" "nordeck/jitsi-jvb"
  mirror_image "$OPENDESK_REGISTRY/supplier/nordeck/images-mirror/prosody:stable-11031" "nordeck/jitsi-prosody"
  mirror_image "$OPENDESK_REGISTRY/supplier/nordeck/images-mirror/jitsi-keycloak-adapter:v20260623" "nordeck/jitsi-keycloak-adapter"
}

mirror_community() {
  echo "=== Community images ==="
  mirror_image "$OPENDESK_REGISTRY/community/images-mirror/redis:7.4.3-debian-12-r0" "community/redis"
  mirror_image "$OPENDESK_REGISTRY/community/images-mirror/memcached:1.6.38-debian-12-r3" "community/memcached"
  mirror_image "$OPENDESK_REGISTRY/community/images-mirror/seaweedfs:4.17" "community/seaweedfs"
}

# Main
case "${1:-all}" in
  univention)  mirror_univention ;;
  collabora)   mirror_collabora ;;
  element)     mirror_element ;;
  nordeck)     mirror_nordeck ;;
  community)   mirror_community ;;
  all)
    mirror_univention
    mirror_collabora
    mirror_element
    mirror_nordeck
    mirror_community
    ;;
  *)
    echo "Usage: $0 [univention|collabora|element|nordeck|community|all]"
    exit 1
    ;;
esac

echo ""
echo "=== All supplier images mirrored ==="

# Supplier Image Mirrors

Images we've mirrored from upstream vendors to our own registries.

## Registry: ghcr.io/opendesk-edu/supplier/

| Image | Source | Status |
|-------|--------|--------|
| univention/keycloak:26.7.0 | registry.opencode.de/.../univention/images-mirror/keycloak | ✅ Mirrored |
| univention/ldap-server:0.48.2 | registry.opencode.de/.../univention/images-mirror/ldap-server | ✅ Mirrored |
| univention/intercom-service:2.24.0 | registry.opencode.de/.../univention/images-mirror/intercom-service | ✅ Mirrored |

## Mirror Script

```bash
./scripts/mirror-supplier-images.sh [category]
```

Categories: univention, collabora, element, nordeck, community, all

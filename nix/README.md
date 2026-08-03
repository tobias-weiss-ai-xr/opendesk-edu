# opendesk-edu/nix - DEPRECATED

**⚠️ DEPRECATION NOTICE: This directory is being migrated to `opendesk-nix/`**

## What's Happening?

As part of the Nix Integration (see [opendesk-edu-spec/changes/nix-integration-proposal](../../opendesk-edu-spec/changes/nix-integration-proposal/)), 
we are consolidating all Nix code into the `opendesk-nix/` repository to avoid duplication and maintain a single source of truth.

## Current Status

| Component | Location | Status | Notes |
|-----------|----------|--------|-------|
| `lib/k8s.nix` | Both locations | ⚠️ Transitioning | Use `opendesk-nix/lib/k8s.nix` for new code |
| `k8s/*.nix` | Both locations | ⚠️ To be migrated | Will be moved to `opendesk-nix/k8s/` |
| `flake.nix` | This directory | ⚠️ Updated | Now references `opendesk-nix` as input |

## Migration Phases

### Phase 1: Integration (Current)
- ✅ Added `opendesk-nix` as flake input
- ✅ Updated `flake.nix` to expose `opendesk-nix.lib`
- ✅ Maintain backward compatibility with existing `lib/k8s.nix`

### Phase 2: Consolidation (Next)
- 🔄 Move `opendesk-edu/nix/lib/k8s.nix` → `opendesk-nix/lib/k8s.nix` (merged with best features)
- 🔄 Move `opendesk-edu/nix/k8s/*.nix` → `opendesk-nix/k8s/`
- 🔄 Update all imports in `opendesk-edu/nix/` to use `opendesk-nix`

### Phase 3: Deprecation (Final)
- 🟡 Mark `opendesk-edu/nix/` as deprecated
- 🟡 Update documentation to point to `opendesk-nix/`
- 🟡 Eventually remove `opendesk-edu/nix/` completely

## How to Use During Transition

### For New Development
**Use `opendesk-nix/` directly:**

```nix
# In your nix code
inputs = {
  opendesk-nix.path = "../opendesk-nix";
};

outputs = { opendesk-nix, ... }:
  let
    lib = opendesk-nix.lib.${system};
    k8s = lib.k8s;
    security = lib.security;
    sbom = lib.sbom;
    registry = lib.registry;
    types = lib.types;
  in {
    # Your code using the consolidated libraries
  }
```

### For Existing Code
**Continue using current imports (backward compatible):**

```nix
# This still works during transition
lib = import ./lib/k8s.nix { inherit pkgs; };
```

But you can also access the new libraries:

```nix
# Access via opendesk-nix input
k8s-lib = opendesk-nix.lib.${system}.k8s;
```

## Benefits of Consolidation

1. **Single Source of Truth** - No more duplication between repos
2. **Easier Maintenance** - Updates to libraries affect all consumers
3. **Better Discoverability** - All Nix code in one place
4. **Consistent Standards** - Unified security, SBOM, registry handling
5. **Improved Collaboration** - Clearer ownership and contribution path

## Accessing Libraries

After the consolidation is complete, all libraries will be available at:

```
opendesk-nix/lib/
├── k8s.nix        # Kubernetes resource builders
├── security.nix   # Security hardening presets
├── sbom.nix       # SBOM generation utilities
├── registry.nix   # Multi-registry support
└── types.nix      # Type definitions
```

## Timeline

| Phase | During | After |
|-------|--------|-------|
| Current | This READMEnote | Will redirect to opendesk-nix |
| Phase 2 | `opendesk-nix` input available | All code moved to `opendesk-nix/` |
| Phase 3 | Backward compatible | Full deprecation |

## See Also

- [Nix Integration OpenSpec](../../opendesk-edu-spec/changes/nix-integration-proposal/)
- [opendesk-nix Repository](../../opendesk-nix/)
- [OpenSpec Methodology](../../opendesk-edu-spec/METHODOLOGY.md)

---

**Last Updated:** 2026-08-28  
**Target Completion:** 2026-09-15 (End of Phase 2)

# ADR-001: Nix-based Kubernetes Deployment

## Status
Accepted (2026-07-29)

## Context
Helmfile + Go templates produce non-deterministic YAML. Errors are hard to debug
("failed to render values file"). Templating is imperative with side effects.

## Decision
Replace Helmfile with pure Nix expressions for generating Kubernetes manifests.
Nix is purely functional, deterministic, and cached.

## Consequences
Positive:
- Pure evaluation → deterministic YAML
- Caching → unchanged services rebuild instantly
- Composable → services are pure functions
- flake.lock pins all dependencies

Negative:
- Nix learning curve for new contributors
- No Helm ecosystem (no `helm search`, no Bitnami charts)
- No Helm tests (but we have kubectl dry-run)

## Migration Path
1. Generate Nix modules alongside existing Helmfile
2. Compare outputs (Nix vs Helmfile) for identicality
3. Switch when Nix output matches Helmfile

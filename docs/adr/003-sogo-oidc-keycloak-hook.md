# ADR-003: Keycloak Pre-install Hook for SOGo OIDC Secret

**Date:** 2026-07  
**Status:** Accepted  

## Context

SOGo authenticates users via OpenID Connect (OIDC) against Keycloak. This requires
a shared client secret between SOGo and Keycloak. The challenge: Helm and Keycloak
do not share a state — Helm cannot know the Keycloak client secret at template time.

Options considered:
- **Random fallback + post-install sync job** (original approach):
  Helm generates a random `oidc-client-secret` via `randAlphaNum 32`.
  A post-install Job patches the K8s Secret with the real Keycloak value.
  **Problem:** Race — the deployment starts with the random secret and never picks
  up the patch. Works only if the deployment restarts after the patch.
- **Pre-provisioned secret**: Operator creates `sogo-oidc` Secret manually before
  `helm install`. **Problem:** Not automated; error-prone.
- **Pre-install hook** (chosen): A Helm pre-install hook Job contacts the Keycloak
  Admin API, creates/updates the client with a generated secret, and writes the
  secret to a K8s Secret before the deployment starts.
- **Init container**: A container checks Keycloak and blocks until the secret
  matches. **Problem:** Circular dependency — SOGo deployment waits for Keycloak,
  but Keycloak may be in the same deploy.

## Decision

**Use a Helm pre-install hook Job to create the Keycloak OIDC client and secret.**

- The hook runs before any regular resource (weight: -10 for RBAC, 0 for Job)
- Creates the Keycloak client if absent, updates if present
- Generates a cryptographically random secret via `openssl rand -hex 32`
- Stores the result in a `sogo-oidc` K8s Secret
- The SOGo deployment reads the hook-created secret

## Consequences

- **Positive:** No race condition — secret exists before the deployment starts.
- **Positive:** Fully automated — no manual secret provisioning.
- **Negative:** Keycloak must be deployed in the same namespace before SOGo.
- **Negative:** The hook requires Keycloak admin credentials (password from K8s Secret).
- **Negative:** If the hook fails, the entire `helm install` fails, and the operator
  must resolve the Keycloak issue before retrying.

# Sprint: SSO Rollout

## Goal
Wire up SSO for all remaining opendesk-edu services using the Keycloak OIDC/SAML clients already registered.

## Services & Approach

### Native OIDC support (chart-level env vars)
| Service | Client ID | Approach |
|---------|-----------|----------|
| **Bookstack** | `opendesk-bookstack` | Native OIDC (BOOKSTACK_OIDC_* env vars) |
| **Planka** | `opendesk-planka` | Native OIDC (OIDC_* env vars) |
| **Draw.io** | `opendesk-drawio` | Native OIDC config |
| **Etherpad** | `opendesk-etherpad` | OIDC plugin via env vars |
| **TYPO3** | `opendesk-typo3` | Native OIDC extension config |
| **n8n** | `opendesk-n8n` | ✅ Already done |

### oauth2-proxy sidecar (no native OIDC)
| Service | Client ID | Approach |
|---------|-----------|----------|
| **LimeSurvey** | `opendesk-limesurvey` | oauth2-proxy sidecar like SSP |
| **Excalidraw** | `opendesk-excalidraw` | oauth2-proxy sidecar like SSP |
| **SSP** | `opendesk-ssp` | ✅ Already done |

### SAML / Admin UI config
| Service | Client ID | Approach |
|---------|-----------|----------|
| **Moodle** | `moodle SAML` | Re-add Shibboleth SP config to chart |
| **ILIAS** | `ilias-saml` | Configure ILIAS SAML authentication |
| **Zammad** | `opendesk-zammad` | OIDC via admin UI (documented) |

### Keycloak client updates
- Set redirect URIs to match actual service endpoints
- Generate/verify client secrets for confidential clients

## Task breakdown
1. Bookstack OIDC — add env vars to chart
2. Planka OIDC — add env vars to chart
3. Draw.io OIDC — add env vars to chart
4. Etherpad OIDC — add OIDC plugin env vars
5. TYPO3 OIDC — add OIDC extension config
6. LimeSurvey oauth2-proxy — add sidecar to chart
7. Excalidraw oauth2-proxy — add sidecar to chart
8. Moodle Shibboleth — re-add SAML SP config to chart
9. ILIAS SAML — configure SAML auth values
10. Zammad OIDC — document admin UI steps, verify client
11. Keycloak — update redirect URIs, verify all 10+ clients
12. Verify — test each service's SSO login flow
13. Docs — update sso-configuration.md with actual configs

## Order
Native OIDC first (fastest), then oauth2-proxy sidecars (reuse SSP pattern), then SAML (most complex).

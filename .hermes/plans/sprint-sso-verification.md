# Sprint: SSO Verification

## Goal
Test SSO login for all 10 edu services, fix any issues found, complete
Zammad OIDC admin UI setup.

## Tasks

### 1. OIDC services (native + oauth2-proxy) — 9 services
For each service:
- Open the URL in a browser (via curl)
- Verify redirect to Keycloak login page
- Verify Keycloak shows the correct realm (`opendesk`)
- Verify redirect URI is correct after login

Services to test:
- n8n (`n8n.home.opendesk-edu.org`)
- Bookstack (`bookstack.home.opendesk-edu.org`)
- Planka (`planka.home.opendesk-edu.org`)
- Draw.io (`draw.home.opendesk-edu.org`)
- Etherpad (`etherpad.home.opendesk-edu.org`)
- TYPO3 (`typo3.home.opendesk-edu.org`)
- LimeSurvey (`limesurvey.home.opendesk-edu.org`)
- Excalidraw (`excalidraw.home.opendesk-edu.org`)
- SSP (`ssp.home.opendesk-edu.org`)

### 2. SAML services — 2 services
- Moodle (`moodle.home.opendesk-edu.org`) — Shibboleth SP
- ILIAS (`lms.home.opendesk-edu.org`) — SimpleSAMLphp

### 3. Zammad OIDC admin UI
- Document and execute the manual admin UI setup steps
- Client: `opendesk-zammad` (confidential, secret known)

### 4. Fix issues found
- Missing redirect URIs in Keycloak
- Wrong chart values
- Oauth2-proxy config errors
- SAML metadata mismatches

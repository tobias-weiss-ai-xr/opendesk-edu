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
- n8n (`n8n.opendesk.hrz.uni-marburg.de`)
- Bookstack (`bookstack.opendesk.hrz.uni-marburg.de`)
- Planka (`planka.opendesk.hrz.uni-marburg.de`)
- Draw.io (`draw.opendesk.hrz.uni-marburg.de`)
- Etherpad (`etherpad.opendesk.hrz.uni-marburg.de`)
- TYPO3 (`typo3.opendesk.hrz.uni-marburg.de`)
- LimeSurvey (`limesurvey.opendesk.hrz.uni-marburg.de`)
- Excalidraw (`excalidraw.opendesk.hrz.uni-marburg.de`)
- SSP (`ssp.opendesk.hrz.uni-marburg.de`)

### 2. SAML services — 2 services
- Moodle (`moodle.opendesk.hrz.uni-marburg.de`) — Shibboleth SP
- ILIAS (`lms.opendesk.hrz.uni-marburg.de`) — SimpleSAMLphp

### 3. Zammad OIDC admin UI
- Document and execute the manual admin UI setup steps
- Client: `opendesk-zammad` (confidential, secret known)

### 4. Fix issues found
- Missing redirect URIs in Keycloak
- Wrong chart values
- Oauth2-proxy config errors
- SAML metadata mismatches

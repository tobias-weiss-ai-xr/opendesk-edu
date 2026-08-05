# Multi-Domain Ingress Configuration - Manual Fix Details

## Date
2026-05-14

## Issue
User reported:
1. Login button → ERR_NAME_NOT_RESOLVED
2. demo.opendesk-sme.org → 404

## Root Cause
The deployment was using single-domain configuration (`opendesk-edu.org`) but serving requests from multiple domains. Keycloak and Portal ingresses were only configured for the primary domain.

## Solution
### 1. Keycloak Ingress - Multi-Domain Support
Fixed the Keycloak ingress to serve both domains:
- `id.demo.opendesk-edu.org` (original)
- `id.demo.opendesk-sme.org` (new - for SME domain login)

### 2. Portal Server Ingress - Multi-Domain Support
Added second host rule for the portal server ingress:
- `portal.demo.opendesk-edu.org` (original)
- `portal.demo.opendesk-sme.org` (new)

### 3. Home Ingress - SME Domain Support
Created new ingress for SME home page:
- `demo.opendesk-sme.org` → redirects to `https://portal.demo.opendesk-sme.org`
- Uses wildcard TLS certificate (`opendesk-certificates-tls`)

## Ingress Summary
| Ingress | Hosts | Status |
|----------|-------|--------|
| ums-keycloak-extensions-proxy | id.demo.opendesk-edu.org, id.demo.opendesk-sme.org | ✅ Fixed |
| ums-portal-server | portal.demo.opendesk-edu.org, portal.demo.opendesk-sme.org | ✅ Fixed |
| opendesk-home-basedomain | demo.opendesk-edu.org | ✅ Original |
| opendesk-home-basedomain-sme | demo.opendesk-sme.org | ✅ New |

## Service Status
All required pods running:
- ums-keycloak-extensions-proxy: Running
- ums-portal-server: Running
- ums-portal-frontend-static: Running
- ums-portal-consumer: Running
- All other application pods: Running

## Verification Commands
```bash
# Test Keycloak from EDU domain
curl -k https://id.demo.opendesk-edu.org/realms/

# Test Keycloak from SME domain
curl -k https://id.demo.opendesk-sme.org/realms/

# Test Portal from EDU domain
curl -k https://portal.demo.opendesk-edu.org/univention/portal/portal.json

# Test Portal from SME domain
curl -k https://portal.demo.opendesk-sme.org/univention/portal/portal.json

# Test Home redirect from SME domain
curl -k -I https://demo.opendesk-sme.org/ 2>&1 | grep -i location
```
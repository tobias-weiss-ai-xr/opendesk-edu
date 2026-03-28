<!--
SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# Backchannel Logout

This document provides comprehensive documentation for the backchannel logout feature
 openDesk Edu, Backchannel logout enables centralized session termination across
 all connected services when a user logs out from the portal.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Configuration](#configuration)
- [Setup Guide](#setup-guide)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

---

## Overview

### What is Backchannel Logout?

Backchannel logout is a server-to-server communication mechanism that ensures that when a user
logs out from one application (the portal), their sessions are terminated
across **all** connected services without requiring the user's browser to visit each service.

### Why It Matters

| Benefit | Description |
|:--------|:------------|
| **Security** | Prevent orphaned sessions that could be accessed after logout |
| **GDPR Compliance** | Supports "Right to be Forgotten" by ensuring complete data removal |
| **Session Management** | Single logout action terminates sessions across all services |
| **User Experience** | Users don't need to manually log out from each service |

### SAML vs OIDC Backchannel Logout

| Protocol | Services | Mechanism |
|:-------- |:---------|:-----------|
| **SAML 2.0** | Moodle, BigBlueButton | SOAP/HTTP-POST binding for backchannel logout requests |
| **OIDC** | OpenCloud, Nextcloud | POST logout token to backchannel endpoint |

---

## Architecture

### System Overview

```
                                    ┌─────────────────┐
                                    │                 │
                                    │    Keycloak     │
                                    │    (IdP)        │
                                    │                 │
         ┌────────────────────────┼────────────────────────────┐
         │                                │                                │
         │                                │                                │
    ┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
    │                  │      │                  │      │                  │
    │     Portal       │      │      Moodle       │      │      BBB         │
    │  (Frontend)     │      │    (Frontend)     │      │    (Frontend)     │
    │                │      │                  │      │                  │
    │   Logout        │      │   Logout         │      │   Logout         │
    │                │      │                  │      │                  │
    └──────────────────┘      └──────────────────┘      └──────────────────┘
         │                                                                                                
         │    Backchannel Logout Requests (Server-to-Server)                                       
         │                                                                                                
    ┌──────────────────────────────────────────────────────────────────────────────┐
    │                                                                             │
    │    ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐    ┌──────────────┐    │
    │    │              │    │              │    │                  │    │              │    │
    │    │    Moodle    │    │     BBB      │    │   OpenCloud      │    │  Nextcloud    │    │
    │    │              │    │              │    │                  │    │              │    │
    │    │  SAML SOAP  │    │  SAML SOAP  │    │  OIDC POST      │    │  OIDC POST    │    │
    │    │    /SOAP    │    │   /SOAP     │    │   /backchannel      │    │ /backchannel    │    │
    │    │  Logout   │    │   Logout     │    │   _logout          │    │   _logout        │    │
    │    │              │    │              │    │                  │    │              │    │
    └────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Logout Flow

1. **User clicks "Logout" in portal**
2. Portal initiates logout via Keycloak
3. Keycloak sends backchannel logout requests to all registered services:
   - SAML: SOAP/HTTP-POST to `/Shibboleth.sso/Logout` (Moodle) or `/saml/logout` (BBB)
   - OIDC: POST to `/backchannel_logout` (OpenCloud, Nextcloud)
4. Each service receives request and validates:
5. Each service terminates the user's session
6. Each service returns success response to Keycloak
7. Portal shows logout confirmation to user

### Components

| Component | File | Purpose |
|:----------|:-----|:---------|
| **Configuration** | `helmfile/environments/default/backchannel-logout.yaml.gotmpl` | Feature toggles and environment variables |
| **Moodle Handler** | `helmfile/apps/moodle/files/backchannel-handler.php` | SAML backchannel logout endpoint |
| **Moodle Apache Config** | `helmfile/apps/moodle/templates/apache-backchannel-configmap.yaml` | Apache routing for backchannel endpoint |
| **BBB Controller** | `helmfile/apps/bigbluebutton/controllers/saml_backchannel_controller.rb` | SAML backchannel logout endpoint |
| **Test Scripts** | `scripts/test-backchannel-propagation.sh` | E2E timing tests |
| **E2E Tests** | `tests/playwright/backchannel-e2e.spec.js` | End-to-end logout verification |

---

## Configuration

### Environment Variables

#### Global Settings

| Variable | Default | Description |
|:--------|:---------|:-------------|
| `BACKCHANNEL_LOGOUT_ENABLED` | `false` | Master toggle for backchannel logout |
| `BACKCHANNEL_LOGOUT_CENTRAL_URL` | `https://portal.{domain}/logout` | Portal logout URL |
| `BACKCHANNEL_LOGOUT_PROPAGATION_TIMEOUT` | `60` | Max time for logout propagation (seconds) |
| `BACKCHANNEL_LOGOUT_LOGGING_ENABLED` | `true` | Enable structured logging |
| `BACKCHANNEL_LOGOUT_LOGGING_LEVEL` | `info` | Log level: debug, info, warn, error |
| `BACKCHANNEL_LOGOUT_LOGGING_FORMAT` | `json` | Log format: json, text |

| `BACKCHANNEL_LOGOUT_RETRY_ENABLED` | `true` | Enable retry for failed logout |
| `BACKCHANNEL_LOGOUT_RETRY_MAX_ATTEMPTS` | `3` | Maximum retry attempts |
| `BACKCHANNEL_LOGOUT_RETRY_DELAY` | `5` | Delay between retries (seconds) |

#### SAML Services (Moodle, BBB)

| Variable | Default | Description |
|:--------|:---------|:-------------|
| `BACKCHANNEL_LOGOUT_MOODLE_ENABLED` | `false` | Enable Moodle backchannel logout |
| `BACKCHANNEL_LOGOUT_MOODLE_URL` | `https://moodle.{domain}/Shibboleth.sso/Logout` | Moodle logout endpoint |
| `BACKCHANNEL_LOGOUT_MOODLE_TIMEOUT` | `30` | Session termination timeout |
| `BACKCHANNEL_LOGOUT_MOODLE_VERBOSE` | `false` | Enable verbose logging |
| `BACKCHANNEL_LOGOUT_MOODLE_REQUIRE_SIGNED_REQUESTS` | `true` | Require signed logout requests |
| `BACKCHANNEL_LOGOUT_BBB_ENABLED` | `false` | Enable BBB backchannel logout |
| `BACKCHANNEL_LOGOUT_BBB_URL` | `https://bbb.{domain}/saml/logout` | BBB logout endpoint |

#### OIDC Services (OpenCloud, Nextcloud)
| Variable | Default | Description |
|:--------|:---------|:-------------|
| `BACKCHANNEL_LOGOUT_OPENCLOUD_ENABLED` | `false` | Enable OpenCloud backchannel logout |
| `BACKCHANNEL_LOGOUT_OPENCLOUD_URL` | `https://files.{domain}/backchannel_logout` | OpenCloud logout endpoint |
| `BACKCHANNEL_LOGOUT_OPENCLOUD_REQUIRE_PKCE` | `true` | Require PKCE for logout tokens |
| `BACKCHANNEL_LOGOUT_OPENCLOUD_MAX_TOKEN_AGE` | `300` | Maximum logout token age (seconds) |
| `BACKCHANNEL_LOGOUT_NEXTCLOUD_ENABLED` | `false` | Enable Nextcloud backchannel logout |
| `BACKCHANNEL_LOGOUT_NEXTCLOUD_URL` | `https://nc.{domain}/apps/user_oidc/backchannel_logout` | Nextcloud logout endpoint |

### Configuration Example

```yaml
# In helmfile/environments/default/global.yaml.gotmpl or backchannel-logout.yaml.gotmpl

global:
  domain: "example.org"

backchannelLogout:
  enabled: "true"
  
  saml:
    moodle:
      enabled: "true"
      bindings:
        soap: "true"
        httpPost: "true"
      signature:
        requireSignedRequests: "true"
        signResponses: "true"
  
    bigbluebutton:
      enabled: "true"
      bindings:
        soap: "true"
  
  oidc:
    opencloud:
      enabled: "true"
      requirePkce: "true"
      maxTokenAge: "300"
    
    nextcloud:
      enabled: "true"
  
  global:
    propagationTimeout: "60"
    retry:
      enabled: "true"
      maxAttempts: "3"
      delay: "5"
```

---

## Setup Guide

### Prerequisites

- Kubernetes 1.28+
- Helm 3.x
- helmfile 0.x
- Keycloak configured as SSO provider
- Services deployed and accessible

- Shibboleth SP for SAML services (Moodle, BBB)
- OIDC plugin for Nextcloud (`user_oidc`)

- OpenCloud deployed with OIDC support

### Step 1: Enable Backchannel Logout

Edit `helmfile/environments/default/backchannel-logout.yaml.gotmpl`:

```yaml
backchannelLogout:
  enabled: "true"  # Set to "true" to enable
```

### Step 2: Enable Individual Services

For each service you want to enable:

```yaml
backchannelLogout:
  saml:
    moodle:
      enabled: "true"
    bigbluebutton:
      enabled: "true"
  oidc:
    opencloud:
      enabled: "true"
    nextcloud:
      enabled: "true"
```

### Step 3: Configure Keycloak

In Keycloak admin console:

1. Navigate to your realm
2. Go to Clients
3. For each service client:
   - Add backchannel logout URL
   - Configure SAML/OIDC settings as needed
4. Save changes

### Step 4: Deploy Configuration
```bash
# Apply the helmfile configuration
helmfile -e default apply
```
### Step 5: Verify Configuration
```bash
# Check backchannel endpoints are accessible
curl -k -I -X POST https://moodle.example.org/Shibboleth.sso/Logout
curl -k -I -X POST https://bbb.example.org/saml/logout
curl -k -I -X POST https://files.example.org/backchannel_logout
curl -k -I -X POST https://nc.example.org/apps/user_oidc/backchannel_logout
```

---

## Testing

### Manual Testing

1. Login to the portal
2. Open each service in separate tabs
3. Verify you is authenticated in each service
4. Click logout in the portal
5. Verify all services show logged out state

### Automated Testing
Run the E2E test suite:
```bash
# Run backchannel logout E2E tests
npx playwright test tests/playwright/backchannel-e2e.spec.js
```
### Timing Test
Measure propagation timing:
```bash
# Run propagation timing test
./scripts/test-backchannel-propagation.sh <logout_token>
```
Expected Results:
- All services should terminate within 60 seconds
- Moodle and BBB typically respond within 5-10 seconds
- OpenCloud and Nextcloud typically respond within 2-5 seconds

### Test Evidence
Test results are saved in:
.sisyphus/evidence/
├── task-6-propagation-times.json
├── task-6-termination-results.json
└── task-6-*.png (screenshots)
```
---
## Troubleshooting

### Common Issues

#### 1. Sessions Not Terminating
**Symptoms**: User still logged in after portal logout

**Solutions**:
- Check backchannel logout is enabled in configuration
- Verify Keycloak client configurations
- Check service logs for errors
- Verify network connectivity between Keycloak and services

```bash
# Check Moodle logs
kubectl logs -l moodle | grep -i backchannel

# Check BBB logs
kubectl logs -l bbb | grep -i backchannel
```
#### 2. Signature Verification Failed
**Symptoms**: HTTP 403 errors in logs

**Solutions**:
- Verify IdP certificate is correctly mounted
- Check certificate expiration
- Ensure correct certificate path in configuration

```bash
# Check IdP certificate
kubectl exec -it moodle -- cat /etc/shibboleth/idp-cert.pem
```
#### 3. Timeout Errors
**Symptoms**: Logout requests timing out

**Solutions**:
- Increase `sessionTerminationTimeout` value
- Check for slow database queries
- Verify adequate resources (CPU/memory)

#### 4. Network Connectivity Issues
**Symptoms**: Connection refused or timeout errors

**Solutions**:
- Verify network policies allow traffic
- Check DNS resolution
- Verify services are running and accessible

```bash
# Test connectivity from Keycloak to services
kubectl exec -it keycloak -- curl -v https://moodle.example.org/Shibboleth.sso/Logout
```
### Debug Mode
Enable verbose logging for debugging:
```yaml
backchannelLogout:
  saml:
    moodle:
      verbose: "true"
    bigbluebutton:
      verbose: "true"
  oidc:
    opencloud:
      verbose: "true"
    nextcloud:
      verbose: "true"
```
Check logs:
```bash
# View detailed backchannel logs
kubectl logs -l moodle | grep backchannel
kubectl logs -l bbb | grep backchannel
```
---
## Security Considerations

### Request Validation
All backchannel logout requests must validated:
- **SAML**: XML signature verification using IdP certificate
- **OIDC**: JWT token validation with shared secret

### Certificate Management
- IdP certificates should be rotated before expiration
- Store certificates in Kubernetes secrets
- Use certificate monitoring tools

### Network Security
- Backchannel endpoints should not be publicly accessible
- Use Kubernetes network policies to restrict access
- Only Keycloak should be able to call backchannel endpoints

### Audit Logging
All logout events are logged:
```json
{
  "timestamp": "2026-03-28T10:30:00Z",
  "level": "INFO",
  "event": "backchannel_logout_completed",
  "service": "moodle",
  "user_id": "user123",
  "session_index": "abc...",
  "duration_ms": 45.2
}
```
### Rate Limiting
Implement rate limiting for backchannel endpoints to prevent:
DoS attacks.

- Limit to 10 requests per second per user
- Return HTTP 429 when rate limit exceeded

---

## Related Documentation

- [Getting Started](./getting-started.md) - Initial setup
- [Architecture](./architecture.md) - System architecture
- [Security](./security.md) - General security measures
- [Testing](./testing.md) - Testing guide

# Collab Services Deployment Guide

## Overview

Collab Services adds interactive computing tools (JupyterHub, RStudio, code-server, Open WebUI, etc.) to openDesk Edu. All services integrate with Keycloak SSO and appear as tiles in the portal navigation.

## Prerequisites

- Running openDesk Edu deployment with Nubus IAM / Keycloak
- Helmfile access to the `opendesk-edu` namespace
- LDAP admin credentials (for portal tiles)

## Quick Start

Deploy all collab-services via helmfile:

```bash
helmfile -e prod apply --selector name=collab-dashboard
helmfile -e prod apply --selector name=rstudio
helmfile -e prod apply --selector name=ttyd
helmfile -e prod apply --selector name=slidev
helmfile -e prod apply --selector name=code-server
helmfile -e prod apply --selector name=jupyterhub
helmfile -e prod apply --selector name=open-webui
helmfile -e prod apply --selector name=ollama
helmfile -e prod apply --selector name=dask
```

Or deploy individually with Helm:

## Individual Service Deployment

### 1. RStudio (with OAuth2)

```bash
helm upgrade --install rstudio ./helmfile/charts/rstudio \
  --namespace opendesk-edu \
  --set ingress.hosts[0].host=r.${DOMAIN} \
  --set ingress.hosts[0].paths[0].path=/ \
  --set oauth2.enabled=true \
  --set oauth2.clientSecret=${RSTUDIO_CLIENT_SECRET} \
  --set oauth2.cookieSecret=$(openssl rand -hex 16) \
  --set oauth2.oidcIssuerUrl=https://id.${DOMAIN}/realms/opendesk
```

### 2. ttyd (Web Terminal)

```bash
helm upgrade --install ttyd ./helmfile/charts/ttyd \
  --namespace opendesk-edu \
  --set ingress.hosts[0].host=term.${DOMAIN} \
  --set ingress.hosts[0].paths[0].path=/ \
  --set oauth2.enabled=true \
  --set oauth2.clientSecret=${TTYD_CLIENT_SECRET} \
  --set oauth2.cookieSecret=$(openssl rand -hex 16) \
  --set oauth2.oidcIssuerUrl=https://id.${DOMAIN}/realms/opendesk
```

### 3. Slidev (Presentations)

```bash
helm upgrade --install slidev ./helmfile/charts/slidev \
  --namespace opendesk-edu \
  --set ingress.hosts[0].host=slides.${DOMAIN} \
  --set ingress.hosts[0].paths[0].path=/ \
  --set persistence.enabled=false
```

### 4. code-server (VS Code IDE)

```bash
helm upgrade --install code-server ./helmfile/charts/code-server \
  --namespace opendesk-edu \
  --set ingress.hosts[0].host=code.${DOMAIN} \
  --set ingress.hosts[0].paths[0].path=/
```

### 5. Collab Dashboard

```bash
helm upgrade --install collab-dashboard ./helmfile/charts/collab-dashboard \
  --namespace opendesk-edu \
  --set ingress.hosts[0].host=collab.${DOMAIN} \
  --set ingress.hosts[0].paths[0].path=/
```

### 6. JupyterHub (with OIDC)

```bash
helm upgrade --install jupyterhub jupyterhub/jupyterhub \
  --namespace opendesk-edu \
  --set ingress.enabled=true \
  --set ingress.hosts[0]=jupyter.${DOMAIN} \
  --set hub.config.GenericOAuthenticator.client_id=opendesk-jupyterhub \
  --set hub.config.GenericOAuthenticator.client_secret=${JH_CLIENT_SECRET} \
  --set hub.config.GenericOAuthenticator.oauth_callback_url=https://jupyter.${DOMAIN}/hub/oauth_callback \
  --set hub.config.GenericOAuthenticator.authorize_url=https://id.${DOMAIN}/realms/opendesk/protocol/openid-connect/auth \
  --set hub.config.GenericOAuthenticator.token_url=https://id.${DOMAIN}/realms/opendesk/protocol/openid-connect/token \
  --set hub.config.GenericOAuthenticator.userdata_url=https://id.${DOMAIN}/realms/opendesk/protocol/openid-connect/userinfo \
  --set hub.config.JupyterHub.authenticator_class=oauthenticator.generic.GenericOAuthenticator
```

### 7. Open WebUI

```bash
helm upgrade --install open-webui open-webui/open-webui \
  --namespace opendesk-edu \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=ai.${DOMAIN}
```

### 8. Ollama (LLM Backend)

```bash
helm upgrade --install ollama otwld/ollama \
  --namespace opendesk-edu \
  --set persistentVolume.enabled=true \
  --set persistentVolume.size=50Gi
```

## Portal Tile Setup

After deploying services, provision portal tiles:

```bash
# Create LDAP entries
for f in helmfile/apps/portal-entries/entries/*.ldif; do
  kubectl exec -i ums-ldap-server-primary-0 -- ldapadd -x \
    -H ldap://localhost \
    -D "cn=admin,dc=swp-ldap,dc=internal" -w ${LDAP_PW} \
    < "$f"
done

# Link to central navigation
kubectl exec -i ums-ldap-server-primary-0 -- ldapmodify -x \
  -H ldap://localhost \
  -D "cn=admin,dc=swp-ldap,dc=internal" -w ${LDAP_PW} \
  < helmfile/apps/portal-entries/entries/portal-central-navigation.ldif
```

## Verification

Run the smoke test:

```bash
./scripts/smoke-test.sh ${DOMAIN} ${INGRESS_IP}
```

Expected output:
```
RStudio → HTTP 302 (redirect to Keycloak)
ttyd → HTTP 302
Collab Dashboard → HTTP 302
Slidev → HTTP 200 (landing page)
Open WebUI → HTTP 200
JupyterHub → HTTP 302
code-server → HTTP 302
ILIAS → HTTP 200
Moodle → HTTP 200
```

## SSO Architecture

| Service | Auth Method | Provider |
|---------|------------|----------|
| RStudio, ttyd, slidev | oauth2-proxy sidecar | Keycloak OIDC |
| code-server | Built-in password | — |
| collab-dashboard | oauth2-proxy sidecar | Keycloak OIDC |
| JupyterHub | OAuthenticator | Keycloak OIDC |
| Open WebUI | Built-in OIDC | Keycloak |
| ILIAS | SAML via Shibboleth SP | Keycloak SAML |
| Moodle | SAML via Shibboleth SP | Keycloak SAML |

## Keycloak Client Setup

Each service needs an OIDC client in Keycloak:

```bash
# Create client
CLIENT_ID="opendesk-${SERVICE}"
HOST="${SERVICE}.${DOMAIN}"

curl -X POST "https://id.${DOMAIN}/admin/realms/opendesk/clients" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"clientId\":\"${CLIENT_ID}\",\"protocol\":\"openid-connect\",\"enabled\":true,\"redirectUris\":[\"https://${HOST}/*\",\"https://${HOST}/oauth2/callback\"]}"

# Generate secret
curl -X POST "https://id.${DOMAIN}/admin/realms/opendesk/clients/${CLIENT_UUID}/client-secret" \
  -H "Authorization: Bearer ${TOKEN}"
```

## Ingress Configuration

Services use HAProxy ingress with:

```yaml
ingressClassName: haproxy
annotations:
  cert-manager.io/cluster-issuer: letsencrypt-prod
  haproxy-ingress.github.io/backend-protocol: http
tls:
  - hosts: ["*.${DOMAIN}"]
    secretName: opendesk-certificates-tls
```

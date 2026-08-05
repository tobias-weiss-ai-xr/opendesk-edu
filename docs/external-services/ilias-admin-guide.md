# ILIAS SAML/Shibboleth Administration Guide

## Architecture

```
User Browser
    |
    v
openDesk Portal  -->  ILIAS (/shib_login.php)
    |                      |
    v                      v
Keycloak (SAML IdP)  <-- Shibboleth SP (Apache mod_shib)
```

- **Keycloak**: SAML 2.0 Identity Provider (realm: `opendesk`)
- **Shibboleth SP**: Service Provider running as Apache module (`mod_shib`)
- **ILIAS**: Built-in Shibboleth authentication (v9.18)

## Keycloak Configuration

| Setting | Value |
|---------|-------|
| Client ID | `ilias-saml` |
| Protocol | SAML 2.0 |
| Realm | `opendesk` |
| Redirect URI | `https://lms.opendesk.example.com/*` |
| Name ID Format | Persistent |

### Protocol Mappers

| Name | Attribute | SAML Attribute |
|------|-----------|----------------|
| username | uid | username |
| email | email | email |
| firstname | firstName | firstname |
| lastname | lastName | lastname |
| role-list | - | Role |

## Shibboleth SP Configuration

### Files

| File | Location | Purpose |
|------|----------|---------|
| shibboleth2.xml | ConfigMap: `ilias-shibboleth-config` | Main SP config |
| attribute-map.xml | ConfigMap: `ilias-shibboleth-config` | SAML attribute mapping |
| attribute-policy.xml | ConfigMap: `ilias-shibboleth-config` | Attribute filter |
| sp-key.pem | Secret: `ilias-shibboleth-certs` | SP signing key |
| sp-cert.pem | Secret: `ilias-shibboleth-certs` | SP signing certificate |
| shibboleth.conf | ConfigMap: `ilias-apache-shibboleth-config` | Apache module config |

### Metadata

- **SP Metadata**: `https://lms.opendesk.example.com/Shibboleth.sso/Metadata`
- **IdP Metadata**: `https://id.opendesk.example.com/realms/opendesk/protocol/saml/descriptor`

### Certificate Management

Generate new SP certificates:

```bash
openssl req -new -x509 -nodes -days 3650 \
  -keyout sp-key.pem -out sp-cert.pem \
  -subj "/CN=lms.opendesk.example.com"
```

Update the K8s secret:

```bash
kubectl create secret generic ilias-shibboleth-certs \
  --from-file=sp-key.pem=sp-key.pem \
  --from-file=sp-cert.pem=sp-cert.pem \
  -n opendesk --dry-run=client -o yaml | kubectl apply -f -
```

## ILIAS Shibboleth Settings

Configure in ILIAS admin UI at `https://lms.opendesk.example.com`:

1. Navigate to: **Administration > Authentication & Registration > Shibboleth**
2. Enable Shibboleth authentication
3. Configure attribute mapping:

| ILIAS Field | Shibboleth Attribute |
|-------------|---------------------|
| Username | username |
| First Name | firstname |
| Last Name | lastname |
| Email | email |
| External ID | username |

4. Default role: `il_user_role_std` (Standard user)
5. Enable: Update existing users on each login

## Portal Integration

- **Tile group**: `managed-by-attribute-Learnmanagement`
- **Tile URL**: `https://lms.opendesk.example.com`
- **Icon**: `helmfile/files/theme/learn/favicon.svg`

Users must be in the `cn=managed-by-attribute-Learnmanagement,cn=groups,<baseDn>` LDAP group to see the tile.

## Troubleshooting

### SAML login fails

1. Check Shibboleth logs: `kubectl logs <ilias-pod> -c shibd`
2. Verify Keycloak SAML metadata is accessible: `curl https://id.opendesk.example.com/realms/opendesk/protocol/saml/descriptor`
3. Check certificate expiration: `kubectl get secret ilias-shibboleth-certs -o jsonpath='{.data.sp-cert\.pem}' | base64 -d | openssl x509 -noout -dates`
4. Verify attribute mapping matches between Keycloak mappers and Shibboleth attribute-map.xml

### User not created in ILIAS

1. Check attribute mapping in Keycloak client (`ilias-saml`)
2. Verify Shibboleth attribute-map.xml has correct `id` attributes
3. Check ILIAS Shibboleth settings in admin UI
4. Verify Shibboleth headers are reaching ILIAS: check Apache error logs

### SP Metadata not accessible

1. Check Apache mod_shib is loaded: `kubectl exec <ilias-pod> -- apache2ctl -M | grep shib`
2. Verify Shibboleth config is mounted: `kubectl exec <ilias-pod> -- ls /etc/shibboleth/`
3. Check SP certificate is valid and readable

### mod_shib not installed

The `srsolutions/ilias:9-php8.2-apache` image does not include `libapache2-mod-shib2` by default. To add it:

1. Build a custom Docker image:

```dockerfile
FROM srsolutions/ilias:9-php8.2-apache
RUN apt-get update && apt-get install -y libapache2-mod-shib2 && a2enmod shib && apt-get clean
```

2. Update the ILIAS Helm values to use the custom image.

## Deployment

Apply all configuration:

```bash
# Apply Shibboleth ConfigMaps
kubectl apply -f helmfile/apps/ilias/templates/shibboleth-config.yaml
kubectl apply -f helmfile/apps/ilias/templates/apache-shibboleth-config.yaml

# Apply certificate secret (generate certs first)
kubectl apply -f helmfile/apps/ilias/templates/shibboleth-certs.yaml.gotmpl

# Restart ILIAS pods
kubectl rollout restart deployment/ilias-ilias -n opendesk
kubectl rollout status deployment/ilias-ilias -n opendesk --timeout=300s
```

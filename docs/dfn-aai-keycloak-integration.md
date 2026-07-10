# SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0

# DFN-AAI Integration with Keycloak

This guide explains how to configure Keycloak as a SAML Service Provider proxy for DFN-AAI federation, mapping eduGAIN attributes to OIDC claims for openDesk services.

## Architecture

```
┌──────────────┐      SAML 2.0      ┌──────────────┐      OIDC       ┌──────────────┐
│  DFN-AAI IdP │◄──────────────────►│   Keycloak   │◄───────────────►│ openDesk     │
│ (Shibboleth) │     (eduGAIN)      │  (SAML SP)   │    (Claims)     │ Services     │
└──────────────┘                    └──────────────┘                 └──────────────┘
```

Keycloak acts as a SAML SP to DFN-AAI and an OIDC IdP for openDesk services, translating SAML attributes to OIDC claims.

## Prerequisites

1. **DFN-AAI Membership**: Institution must be a DFN-AAI member
2. **Shibboleth IdP**: Your institution's Shibboleth IdP must be registered with DFN-AAI
3. **Keycloak**: Running Keycloak instance with SAML support enabled
4. **Metadata**: DFN-AAI IdP metadata URL

## Step 1: Configure Keycloak SAML Identity Provider

### 1.1 Import DFN-AAI IdP Metadata

In Keycloak Admin Console:
1. Navigate to **Identity Providers** → **Add Provider** → **SAML**
2. Enter provider alias: `dfn-aai`
3. Click **Import from URL** and enter your institution's IdP metadata URL
   - Example: `https://idp.university.de/idp/shibboleth`
4. Click **Import**

### 1.2 Configure SAML Settings

| Setting | Value | Description |
|---------|-------|-------------|
| **Enabled** | ON | Enable the IdP |
| **Hide on Login** | OFF | Show as login option |
| **Link Only** | OFF | Allow first-time login |
| **Trust Email** | ON | Trust IdP email verification |
| **Store Token** | ON | Store SAML token |
| **Gui Order** | 1 | Display order |

### 1.3 Configure SAML Endpoint

| Endpoint | Value |
|----------|-------|
| **Single Sign-On Service URL** | `https://idp.university.de/idp/profile/SAML2/Redirect/SSO` |
| **Single Logout Service URL** | `https://idp.university.de/idp/profile/SAML2/POST/SLO` |
| **NameID Policy Format** | `urn:oasis:names:tc:SAML:2.0:nameid-format:persistent` |

## Step 2: Configure eduGAIN Attribute Mappers

DFN-AAI provides standard eduGAIN attributes. Map these to Keycloak user attributes:

### 2.1 Required Attributes (5 mandatory for DFN-AAI)

```yaml
# Add to Keycloak Identity Provider → dfn-aai → Mappers

# 1. eduPersonPrincipalName (ePPN) - Unique user identifier
- name: "eppn"
  syncMode: "INHERIT"
  identityProviderMapper: "saml-user-attribute-mapper"
  config:
    attribute.name: "eduPersonPrincipalName"
    attribute.nameformat: "urn:oasis:names:tc:SAML:2.0:attrname-format:uri"
    user.attribute: "eppn"

# 2. mail - User email address
- name: "email"
  syncMode: "INHERIT"
  identityProviderMapper: "saml-user-attribute-mapper"
  config:
    attribute.name: "mail"
    attribute.nameformat: "urn:oasis:names:tc:SAML:2.0:attrname-format:basic"
    user.attribute: "email"

# 3. displayName - User's full display name
- name: "displayName"
  syncMode: "INHERIT"
  identityProviderMapper: "saml-user-attribute-mapper"
  config:
    attribute.name: "displayName"
    attribute.nameformat: "urn:oasis:names:tc:SAML:2.0:attrname-format:basic"
    user.attribute: "displayName"

# 4. eduPersonAffiliation - User's role (student, staff, faculty, etc.)
- name: "affiliation"
  syncMode: "INHERIT"
  identityProviderMapper: "saml-user-attribute-mapper"
  config:
    attribute.name: "eduPersonAffiliation"
    attribute.nameformat: "urn:oasis:names:tc:SAML:2.0:attrname-format:uri"
    user.attribute: "eduPersonAffiliation"

# 5. eduPersonTargetedID - Persistent anonymous identifier
- name: "epuid"
  syncMode: "INHERIT"
  identityProviderMapper: "saml-user-attribute-mapper"
  config:
    attribute.name: "eduPersonTargetedID"
    attribute.nameformat: "urn:oasis:names:tc:SAML:2.0:attrname-format:uri"
    user.attribute: "epuid"
```

### 2.2 Recommended Additional Attributes

```yaml
# 6. givenName - First name
- name: "firstName"
  syncMode: "INHERIT"
  identityProviderMapper: "saml-user-attribute-mapper"
  config:
    attribute.name: "givenName"
    attribute.nameformat: "urn:oasis:names:tc:SAML:2.0:attrname-format:basic"
    user.attribute: "firstName"

# 7. sn (surname) - Last name
- name: "lastName"
  syncMode: "INHERIT"
  identityProviderMapper: "saml-user-attribute-mapper"
  config:
    attribute.name: "sn"
    attribute.nameformat: "urn:oasis:names:tc:SAML:2.0:attrname-format:basic"
    user.attribute: "lastName"

# 8. eduPersonScopedAffiliation - Role with institutional scope
- name: "scopedAffiliation"
  syncMode: "INHERIT"
  identityProviderMapper: "saml-user-attribute-mapper"
  config:
    attribute.name: "eduPersonScopedAffiliation"
    attribute.nameformat: "urn:oasis:names:tc:SAML:2.0:attrname-format:uri"
    user.attribute: "eduPersonScopedAffiliation"

# 9. schacHomeOrganization - Home institution identifier
- name: "homeOrg"
  syncMode: "INHERIT"
  identityProviderMapper: "saml-user-attribute-mapper"
  config:
    attribute.name: "schacHomeOrganization"
    attribute.nameformat: "urn:oid:1.3.6.1.4.1.25178.1.2.9"
    user.attribute: "schacHomeOrganization"

# 10. o (organization) - Organization name
- name: "organization"
  syncMode: "INHERIT"
  identityProviderMapper: "saml-user-attribute-mapper"
  config:
    attribute.name: "o"
    attribute.nameformat: "urn:oasis:names:tc:SAML:2.0:attrname-format:basic"
    user.attribute: "organization"
```

## Step 3: Configure OIDC Protocol Mappers

Map Keycloak user attributes to OIDC claims for openDesk services:

```yaml
# In Keycloak Client → Protocol Mappers

# Email claim
- name: "email"
  protocol: "openid-connect"
  protocolMapper: "oidc-usermodel-attribute-mapper"
  consentRequired: false
  config:
    user.attribute: "email"
    claim.name: "email"
    jsonType.label: "String"

# Name claim (full name)
- name: "name"
  protocol: "openid-connect"
  protocolMapper: "oidc-full-name-mapper"
  consentRequired: false
  config:
    id.token.claim: "true"
    access.token.claim: "true"

# Given name
- name: "given_name"
  protocol: "openid-connect"
  protocolMapper: "oidc-usermodel-attribute-mapper"
  consentRequired: false
  config:
    user.attribute: "firstName"
    claim.name: "given_name"
    jsonType.label: "String"

# Family name
- name: "family_name"
  protocol: "openid-connect"
  protocolMapper: "oidc-usermodel-attribute-mapper"
  consentRequired: false
  config:
    user.attribute: "lastName"
    claim.name: "family_name"
    jsonType.label: "String"

# eduPersonPrincipalName (custom claim)
- name: "eppn"
  protocol: "openid-connect"
  protocolMapper: "oidc-usermodel-attribute-mapper"
  consentRequired: false
  config:
    user.attribute: "eppn"
    claim.name: "eppn"
    jsonType.label: "String"

# eduPersonAffiliation (custom claim)
- name: "affiliation"
  protocol: "openid-connect"
  protocolMapper: "oidc-usermodel-attribute-mapper"
  consentRequired: false
  config:
    user.attribute: "eduPersonAffiliation"
    claim.name: "affiliation"
    jsonType.label: "String"
```

## Step 4: Generate SP Metadata for DFN-AAI

Use the provided metadata generator script:

```bash
cd scripts/saml-metadata-generator

# Configure for your environment
cp saml-metadata-generator-config.yaml.example saml-metadata-generator-config.yaml

# Edit configuration
vim saml-metadata-generator-config.yaml
# Set: entity_id, acs_url, slo_url, certificate paths

# Generate metadata
python saml-metadata-generator.py \
  --config saml-metadata-generator-config.yaml \
  --env production \
  --output sp-metadata.xml

# Validate metadata
./validate-metadata.sh sp-metadata.xml
```

## Step 5: Register with DFN-AAI

### 5.1 Test Federation

1. Submit `sp-metadata.xml` to: https://test.aai.dfn.de/metadata/
2. Wait for approval (typically 1-2 business days)
3. Test authentication flow with test IdPs

### 5.2 Production Federation

1. Submit `sp-metadata.xml` to: https://www.aai.dfn.de/en/service/metadata/
2. Complete DFN-AAI registration form
3. Sign DFN-AAI participation agreement
4. Wait for approval (typically 1-2 weeks)

## Step 6: Test Integration

### 6.1 Test Authentication Flow

```bash
# Test SAML flow
curl -L -v "https://portal.example.com/realms/opendesk/broker/dfn-aai/endpoint"

# Verify attribute mapping
curl -H "Authorization: Bearer <token>" \
  "https://id.example.com/realms/opendesk/protocol/openid-connect/userinfo"
```

### 6.2 Verify Attributes

Expected OIDC claims from DFN-AAI authentication:

```json
{
  "sub": "abc123",
  "email": "user@university.de",
  "email_verified": true,
  "name": "Max Mustermann",
  "given_name": "Max",
  "family_name": "Mustermann",
  "eppn": "user@university.de",
  "affiliation": "member@university.de",
  "homeOrg": "https://university.de"
}
```

## Troubleshooting

### Issue: Attributes Not Received

**Symptoms:** User authenticates but OIDC claims are empty.

**Resolution:**
1. Check IdP mapper configuration in Keycloak
2. Verify attribute names match exactly (case-sensitive)
3. Check DFN-AAI IdP releases the attributes
4. Enable Keycloak debug logging for SAML

### Issue: eduPersonPrincipalName Missing

**Symptoms:** ePPN attribute not in token.

**Resolution:**
1. Verify IdP releases eduPersonPrincipalName
2. Check attribute name format (should be URI format)
3. Ensure mapper syncMode is "INHERIT"

### Issue: Metadata Validation Failed

**Symptoms:** DFN-AAI rejects SP metadata.

**Resolution:**
1. Validate XML schema: `xmllint --noout --schema dfn-aai-metadata.xsd sp-metadata.xml`
2. Ensure all required elements present (EntityDescriptor, SPSSODescriptor, etc.)
3. Verify certificate format (PEM, no headers in metadata)

## Security Considerations

- **Signing**: Enable SAML assertion signing
- **Encryption**: Enable SAML encryption for sensitive attributes
- **Certificate Rotation**: Rotate certificates annually
- **Attribute Filtering**: Only request required attributes
- **Logout**: Configure single logout for session termination

## References

- [DFN-AAI Documentation](https://www.aai.dfn.de/)
- [eduGAIN Attribute Naming](https://technical.edugain.org/2021/07/edugain-attribute-naming.html)
- [SAML V2.0 Metadata Specification](https://docs.oasis-open.org/security/saml/v2.0/saml-metadata-2.0-os.pdf)
- [Keycloak SAML Identity Providers](https://www.keycloak.org/docs/latest/server_admin/#_identity_broker)

---

**Version:** 1.0  
**Last Updated:** 2026-07-09  
**Owner:** openDesk Operations Team

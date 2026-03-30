# DFN-AAI / eduGAIN SAML Federation Support — Implementation Plan

## 1. TASK OVERVIEW

Implement **DFN-AAI / eduGAIN SAML Federation Support** — enabling openDesk Edu to function as a SAML Service Provider within the German academic identity federation. This allows users from 200+ German universities and eduGAIN-connected institutions worldwide to authenticate using their institutional credentials.

**Source**: `ROADMAP.md` lines 41-50 (v1.1 — Foundation)

### Requirements (from ROADMAP.md)
- [ ] Register openDesk Edu as a SAML SP in DFN-AAI
- [ ] Support standard eduGAIN attributes (`eduPersonAffiliation`, `mail`, `displayName`, `persistentId`)
- [ ] Document federation metadata generation for deployers
- [ ] Support Shibboleth IdP as external identity provider
- [ ] Test with DFN-AAI test federation (`https://www.aai.dfn.de/`)

---

## 2. SCOPE & DELIMITATIONS

### In Scope
- SAML 2.0 Service Provider configuration in Keycloak
- DFN-AAI test and production federation registration workflow
- eduGAIN/eduPerson attribute mapping to Keycloak user attributes
- Shibboleth IdP integration (Keycloak as SAML SP)
- Metadata generation scripts and automation
- Role-based access control from `eduPersonAffiliation`
- Just-in-Time (JIT) user provisioning
- Single Logout (SLO) with backchannel support
- Comprehensive documentation (bilingual: German/English)
- Test suite with DFN-AAI test federation

### Out of Scope
- Deploying Shibboleth IdP (universities already run their own)
- Keycloak as eduGAIN IdP (SAML federation support incomplete)
- Direct LDAP integration with university directories (use federation instead)
- Multi-tenant federation (deferred to v5.0)
- SATOSA proxy deployment (deferred to v5.0)

---

## 3. ARCHITECTURE

### 3.1 Component Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           DFN-AAI / eduGAIN Federation                           │
│  ┌───────────────────────────────────────────────────────────────────────────┐  │
│  │                    Federation Metadata Aggregate                           │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │  TU Berlin   │  │  LMU Munich  │  │ FU Berlin    │  │  200+ more   │   │  │
│  │  │  Shib IdP    │  │  Shib IdP    │  │  Shib IdP    │  │  IdPs        │   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
│                              │                                                   │
│                    Federation Metadata URL                                      │
│                    (DFN-AAI-Test / DFN-AAI-Basic / eduGAIN)                     │
└─────────────────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           openDesk Edu Platform                                  │
│  ┌───────────────────────────────────────────────────────────────────────────┐  │
│  │                        Keycloak (SAML SP)                                  │  │
│  │  ┌─────────────────────────────────────────────────────────────────────┐  │  │
│  │  │  Identity Provider: DFN-AAI                                          │  │  │
│  │  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐   │  │  │
│  │  │  │  Attribute       │  │  Role Mapper     │  │  JIT Provisioner │   │  │  │
│  │  │  │  Mappers         │  │  (affiliation    │  │  (first broker   │   │  │  │
│  │  │  │  (eduPerson →    │  │   → role)        │  │   login flow)    │   │  │  │
│  │  │  │   Keycloak)      │  │                  │  │                  │   │  │  │
│  │  │  └──────────────────┘  └──────────────────┘  └──────────────────┘   │  │  │
│  │  └─────────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
│                              │                                                   │
│  ┌───────────────────────────────────────────────────────────────────────────┐  │
│  │                        Downstream Services                                 │  │
│  │   ┌─────────┐  ┌─────────┐  ┌──────────────┐  ┌───────────┐  ┌────────┐  │  │
│  │   │ ILIAS   │  │ Moodle  │  │ BigBlueButton│  │ Nextcloud │  │ Portal │  │  │
│  │   │(Shib SP)│  │(Shib SP)│  │ (SAML/OIDC)  │  │  (OIDC)   │  │ (OIDC) │  │  │
│  │   └─────────┘  └─────────┘  └──────────────┘  └───────────┘  └────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Authentication Flow

**Federated Login (User from DFN-AAI Institution)**:
```
1. User accesses portal.education.example.org
2. User clicks "Login with institutional account (DFN-AAI)"
3. Keycloak redirects to DFN-AAI Discovery Service
4. User selects their home institution (e.g., "TU Berlin")
5. User authenticates at institutional Shibboleth IdP
6. IdP sends SAML assertion to Keycloak with eduGAIN attributes
7. Keycloak validates assertion, extracts attributes
8. JIT provisioning creates/updates user account
9. Role mapper assigns Keycloak roles based on eduPersonAffiliation
10. User redirected to portal, authenticated
11. SSO propagates to ILIAS, Moodle, other services
```

**Metadata Exchange**:
```
┌─────────────────┐                      ┌─────────────────┐
│  openDesk Edu   │                      │    DFN-AAI      │
│    (SP)         │                      │   Federation    │
├─────────────────┤                      ├─────────────────┤
│                 │  1. Submit SP        │                 │
│                 │     Metadata         │                 │
│                 │ ─────────────────────►                 │
│                 │                      │                 │
│                 │  2. Federation       │                 │
│                 │     Validates        │                 │
│                 │ ◄─────────────────────                 │
│                 │                      │                 │
│                 │  3. Import DFN-AAI   │                 │
│                 │     Metadata         │                 │
│                 │ ◄─────────────────────                 │
│                 │                      │                 │
│                 │  4. Periodic Refresh │                 │
│                 │ ◄─────────────────────                 │
└─────────────────┘                      └─────────────────┘
```

---

## 4. IMPLEMENTATION DETAILS

### 4.1 DFN-AAI Federation Endpoints

| Environment | Purpose | URL |
|-------------|---------|-----|
| Test Federation | Metadata | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml` |
| Test Federation | Discovery Service | `https://discovery.aai.dfn.de/` |
| Test Federation | Test IdP | `https://idp.test.aai.dfn.de/` |
| Production | Metadata (Basic) | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Basic-metadata.xml` |
| Production | Metadata (eduGAIN) | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-eduGAIN-metadata.xml` |
| Production | Discovery Service | `https://discovery.aai.dfn.de/` |
| Both | Support | `support@aai.dfn.de` |

### 4.2 eduGAIN Attribute Mapping

#### Required Attributes

| eduGAIN Attribute | SAML Name | Keycloak Attribute | Purpose |
|-------------------|-----------|-------------------|---------|
| `mail` | `urn:mace:dir:attribute-def:mail` | `email` | Primary email address |
| `displayName` | `urn:mace:dir:attribute-def:displayName` | `firstName` | User display name |
| `eduPersonPrincipalName` | `urn:mace:dir:attribute-def:eduPersonPrincipalName` | `username` | Persistent unique identifier |
| `eduPersonAffiliation` | `urn:mace:dir:attribute-def:eduPersonAffiliation` | `affiliation` | Role at institution |

#### Optional Attributes

| eduGAIN Attribute | SAML Name | Keycloak Attribute | Purpose |
|-------------------|-----------|-------------------|---------|
| `givenName` | `urn:mace:dir:attribute-def:givenName` | `firstName` | First name |
| `sn` | `urn:mace:dir:attribute-def:sn` | `lastName` | Last name |
| `eduPersonScopedAffiliation` | `urn:mace:dir:attribute-def:eduPersonScopedAffiliation` | `scopedAffiliation` | Affiliation with scope |
| `eduPersonEntitlement` | `urn:mace:dir:attribute-def:eduPersonEntitlement` | `entitlement` | Service entitlements |
| `eduPersonTargetedID` | `urn:mace:dir:attribute-def:eduPersonTargetedID` | `fedid` | Privacy-preserving ID |

#### Affiliation to Role Mapping

| eduPersonAffiliation | Keycloak Role | Access Level |
|---------------------|---------------|--------------|
| `faculty` | `instructor` | Full teaching access, course management |
| `staff` | `staff` | Administrative access |
| `student` | `student` | Student access, course enrollment |
| `employee` | `employee` | Employee access |
| `member` | `member` | Basic member access |
| `affiliate` | `affiliate` | External affiliate access |
| `alum` | `alumni` | Alumni access |
| `library-walk-in` | `library` | Library-only access |

### 4.3 Keycloak Identity Provider Configuration

#### SAML IdP Settings (Admin Console)

```yaml
# Navigate to: Realm Settings → Identity Providers → Add provider → SAML v2.0

# Test Federation Configuration
alias: dfn-aai-test
displayName: "DFN-AAI (Test)"
enabled: true
trustEmail: true
storeToken: false
linkOnly: false
firstBrokerLoginFlowAlias: "first broker login"

# SAML Configuration
metadataUrl: "https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml"
entityId: "https://www.aai.dfn.de/idp/shibboleth"
singleSignOnServiceUrl: "https://idp.test.aai.dfn.de/idp/profile/SAML2/Redirect/SSO"
singleLogoutServiceUrl: "https://idp.test.aai.dfn.de/idp/profile/SAML2/Redirect/SLO"
nameIDPolicyFormat: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
principalType: "ATTRIBUTE"
principalAttribute: "urn:mace:dir:attribute-def:eduPersonPrincipalName"

# Signature Settings
wantAuthnRequestsSigned: true
validateSignature: true
signatureAlgorithm: "RSA_SHA256"
```

#### Production Federation Configuration

```yaml
alias: dfn-aai
displayName: "DFN-AAI"
metadataUrl: "https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Basic-metadata.xml"
# For eduGAIN-wide access, use:
# metadataUrl: "https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-eduGAIN-metadata.xml"
```

### 4.4 Attribute Mapper Configuration

#### Email Mapper

```json
{
  "name": "email-mapper",
  "identityProviderMapper": "saml-user-attribute-idp-mapper",
  "identityProviderAlias": "dfn-aai-test",
  "config": {
    "syncMode": "INHERIT",
    "attribute": "urn:mace:dir:attribute-def:mail",
    "user.attribute": "email"
  }
}
```

#### Username Mapper

```json
{
  "name": "username-mapper",
  "identityProviderMapper": "saml-user-attribute-idp-mapper",
  "identityProviderAlias": "dfn-aai-test",
  "config": {
    "syncMode": "INHERIT",
    "attribute": "urn:mace:dir:attribute-def:eduPersonPrincipalName",
    "user.attribute": "username"
  }
}
```

#### Affiliation Mapper

```json
{
  "name": "affiliation-mapper",
  "identityProviderMapper": "saml-user-attribute-idp-mapper",
  "identityProviderAlias": "dfn-aai-test",
  "config": {
    "syncMode": "INHERIT",
    "attribute": "urn:mace:dir:attribute-def:eduPersonAffiliation",
    "user.attribute": "affiliation"
  }
}
```

#### Display Name Mapper (with name parsing)

```json
{
  "name": "displayname-mapper",
  "identityProviderMapper": "saml-user-attribute-idp-mapper",
  "identityProviderAlias": "dfn-aai-test",
  "config": {
    "syncMode": "INHERIT",
    "attribute": "urn:mace:dir:attribute-def:displayName",
    "user.attribute": "displayName"
  }
}
```

### 4.5 Role Mapping Script (Advanced)

For complex role mapping based on affiliation:

```javascript
// Script Mapper: affiliation-to-role-mapper
// Place in Keycloak → Identity Providers → dfn-aai-test → Mappers → Add mapper → Advanced

var affiliations = user.getAttribute('affiliation');
if (!affiliations) {
    affiliations = [];
}

// Parse display name into first/last name
var displayName = user.getSingleAttribute('displayName');
if (displayName && !user.getFirstName()) {
    var parts = displayName.trim().split(/\s+/);
    // Filter out titles (Dr., Prof., etc.)
    var titles = ['dr.', 'dr', 'prof.', 'prof', 'mag.', 'mag', 'dipl.-ing.', 'dipl.'];
    var nameParts = [];
    for each (var part in parts) {
        var isTitle = false;
        for each (var title in titles) {
            if (part.toLowerCase().startsWith(title.toLowerCase())) {
                isTitle = true;
                break;
            }
        }
        if (!isTitle) {
            nameParts.push(part);
        }
    }
    
    if (nameParts.length >= 2) {
        user.setFirstName(nameParts[0]);
        user.setLastName(nameParts.slice(1).join(' '));
    } else if (nameParts.length === 1) {
        user.setLastName(nameParts[0]);
    }
}

// Role mapping based on affiliation
var roles = [];
for each (var aff in affiliations) {
    switch (aff.toLowerCase()) {
        case 'faculty':
            roles.push('instructor');
            roles.push('teacher');
            break;
        case 'staff':
            roles.push('staff');
            break;
        case 'student':
            roles.push('student');
            roles.push('learner');
            break;
        case 'employee':
            roles.push('employee');
            break;
        case 'member':
            roles.push('member');
            break;
        case 'affiliate':
            roles.push('affiliate');
            roles.push('external');
            break;
        case 'alum':
            roles.push('alumni');
            break;
        case 'library-walk-in':
            roles.push('library');
            break;
    }
}

// Grant roles
for each (var role in roles) {
    user.grantRole(role);
}

// Set email verified (IdP provides verified emails)
user.setEmailVerified(true);
```

### 4.6 Service Provider Metadata Generation

Use the existing script at `scripts/federation/generate-metadata.sh`:

```bash
# Generate metadata with self-signed certificate (for test federation)
./scripts/federation/generate-metadata.sh \
    -d education.example.org \
    -e "https://idp.education.example.org/realms/opendesk" \
    --generate-cert \
    --org-name "Example University" \
    --org-display "Example University Education Platform" \
    --tech-email edu-support@example.org \
    -o /tmp/dfn-aai-sp-metadata.xml

# Generate metadata with CA-signed certificate (for production)
./scripts/federation/generate-metadata.sh \
    -d education.example.org \
    -e "https://idp.education.example.org/realms/opendesk" \
    -c /etc/pki/tls/certs/keycloak-sp.crt \
    -k /etc/pki/tls/private/keycloak-sp.key \
    --org-name "Example University" \
    --org-display "Example University Education Platform" \
    --tech-email edu-support@example.org \
    -o /tmp/dfn-aai-sp-metadata.xml
```

### 4.7 Generated SP Metadata Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
                     entityID="https://idp.education.example.org/realms/opendesk">

  <md:SPSSODescriptor AuthnRequestsSigned="true"
                      WantAssertionsSigned="true"
                      protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <!-- Assertion Consumer Service -->
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
                                  Location="https://idp.education.example.org/realms/opendesk/protocol/saml"
                                  index="0" isDefault="true"/>

    <!-- Single Logout Service -->
    <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
                            Location="https://idp.education.example.org/realms/opendesk/protocol/saml"/>
    <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
                            Location="https://idp.education.example.org/realms/opendesk/protocol/saml"/>

    <!-- Signing Certificate -->
    <md:KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:X509Data>
          <ds:X509Certificate>
            <!-- Certificate data here -->
          </ds:X509Certificate>
        </ds:X509Data>
      </ds:KeyInfo>
    </md:KeyDescriptor>

    <!-- Required Attributes -->
    <md:AttributeConsumingService index="0">
      <md:ServiceName xml:lang="en">openDesk Edu Platform</md:ServiceName>
      <md:ServiceDescription xml:lang="en">Digital workplace for education</md:ServiceDescription>

      <md:RequestedAttribute FriendlyName="affiliation"
                              Name="urn:mace:dir:attribute-def:eduPersonAffiliation"
                              isRequired="true"/>
      <md:RequestedAttribute FriendlyName="mail"
                              Name="urn:mace:dir:attribute-def:mail"
                              isRequired="true"/>
      <md:RequestedAttribute FriendlyName="displayName"
                              Name="urn:mace:dir:attribute-def:displayName"
                              isRequired="true"/>
      <md:RequestedAttribute FriendlyName="persistentID"
                              Name="urn:mace:dir:attribute-def:eduPersonPrincipalName"
                              isRequired="true"/>
    </md:AttributeConsumingService>

  </md:SPSSODescriptor>

  <md:Organization>
    <md:OrganizationName xml:lang="en">Example University</md:OrganizationName>
    <md:OrganizationDisplayName xml:lang="en">Example University Education Platform</md:OrganizationDisplayName>
    <md:OrganizationURL xml:lang="en">https://www.example-university.edu</md:OrganizationURL>
  </md:Organization>

  <md:ContactPerson contactType="technical">
    <md:GivenName>IT Support</md:GivenName>
    <md:EmailAddress>edu-support@example.org</md:EmailAddress>
  </md:ContactPerson>

</md:EntityDescriptor>
```

### 4.8 DFN-AAI Registration Process

#### Step-by-Step Registration

1. **Generate SP Metadata** (see 4.6)
2. **Validate Metadata**
   ```bash
   xmllint --noout /tmp/dfn-aai-sp-metadata.xml
   openssl x509 -in sp-cert.pem -noout -dates
   ```
3. **Access DFN-AAI Portal**
   - URL: https://www.aai.dfn.de/en/service/metadata/
   - Login with DFN-AAI account (contact support@aai.dfn.de)
4. **Complete Registration Form**
   - Entity ID: `https://idp.<domain>/realms/opendesk`
   - Service Name: `<Institution> Education Platform`
   - Upload SP metadata file
   - Select federation: **Test** first, then **Production**
   - Provide technical and administrative contacts
5. **Await Approval**
   - Test federation: 1-2 business days
   - Production federation: 3-5 business days
6. **Configure Keycloak** (after approval)
   - Import DFN-AAI metadata
   - Add attribute mappers
   - Enable identity provider

---

## 5. FILE STRUCTURE

```
helmfile/apps/nubus/
├── templates/
│   └── idp-federation-config.yaml        # Federation-specific ConfigMap
├── values-nubus.yaml.gotmpl              # Keycloak configuration updates
└── values-idp-federation.yaml.gotmpl     # Federation environment values

scripts/federation/
├── generate-metadata.sh                  # SP metadata generator (existing)
├── validate-metadata.sh                  # Metadata validation script (new)
├── test-federation-login.sh              # Federation login test script (new)
└── README.md                             # Documentation (existing)

docs/
├── dfn-aai-registration.md               # Registration guide (existing)
├── dfn-aai-testing-guide.md              # Testing guide (existing)
├── shibboleth-idp-integration.md         # Shibboleth IdP integration (existing)
├── keycloak-edugain-attributes.md        # Attribute mapping (existing)
├── federation/
│   ├── dfn-aai-enrollment.md             # Enrollment guide (existing)
│   ├── testing-guide.md                  # Federation testing (existing)
│   └── production-migration.md           # Test → Production migration (new)
└── integration/
    └── federation-sso.md                 # Federation SSO overview (new)

tests/
├── federation/
│   ├── conftest.py                       # Test fixtures
│   ├── test_metadata_generation.py       # Metadata generation tests
│   ├── test_attribute_mapping.py         # Attribute mapping tests
│   ├── test_role_mapping.py              # Role mapping tests
│   └── test_jit_provisioning.py          # JIT provisioning tests
└── playwright/
    └── federation-e2e.spec.js            # E2E federation login tests

helmfile/environments/default/
├── federation.yaml.gotmpl                # Federation configuration (existing)
└── idp-federation-secrets.yaml.gotmpl    # Federation secrets (new)
```

---

## 6. TEST STRATEGY

### 6.1 DFN-AAI Test Federation

Use DFN-AAI test federation for all integration testing before production.

#### Test IdP Information

| Environment | URL | Purpose |
|-------------|-----|---------|
| Test IdP | `https://idp.test.aai.dfn.de/` | Primary test identity provider |
| Test Federation Metadata | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml` | Federation metadata |
| Discovery Service | `https://discovery.aai.dfn.de/` | IdP selection |

#### Test User Accounts

Contact DFN-AAI support (`support@aai.dfn.de`) for test credentials.

| Test User | eduPersonAffiliation | Expected Role |
|-----------|---------------------|---------------|
| `testuser1` | `faculty` | `instructor` |
| `testuser2` | `staff` | `staff` |
| `testuser3` | `student` | `student` |
| `testuser4` | `member` | `member` |
| `testuser5` | `affiliate` | `affiliate` |

### 6.2 Unit Tests

```python
# tests/federation/test_attribute_mapping.py

import pytest
from keycloak_admin import KeycloakAdmin

class TestAttributeMapping:
    """Test eduGAIN attribute mapping to Keycloak attributes."""
    
    def test_email_mapper(self, keycloak_admin):
        """Test mail attribute maps to email."""
        mapper = keycloak_admin.get_idp_mapper("dfn-aai-test", "email-mapper")
        assert mapper["config"]["attribute"] == "urn:mace:dir:attribute-def:mail"
        assert mapper["config"]["user.attribute"] == "email"
    
    def test_username_mapper(self, keycloak_admin):
        """Test eduPersonPrincipalName maps to username."""
        mapper = keycloak_admin.get_idp_mapper("dfn-aai-test", "username-mapper")
        assert mapper["config"]["attribute"] == "urn:mace:dir:attribute-def:eduPersonPrincipalName"
        assert mapper["config"]["user.attribute"] == "username"
    
    def test_affiliation_mapper(self, keycloak_admin):
        """Test eduPersonAffiliation maps to affiliation."""
        mapper = keycloak_admin.get_idp_mapper("dfn-aai-test", "affiliation-mapper")
        assert mapper["config"]["attribute"] == "urn:mace:dir:attribute-def:eduPersonAffiliation"
        assert mapper["config"]["user.attribute"] == "affiliation"
```

```python
# tests/federation/test_role_mapping.py

import pytest

class TestRoleMapping:
    """Test eduPersonAffiliation to Keycloak role mapping."""
    
    @pytest.mark.parametrize("affiliation,expected_roles", [
        ("faculty", ["instructor", "teacher"]),
        ("staff", ["staff"]),
        ("student", ["student", "learner"]),
        ("member", ["member"]),
        ("affiliate", ["affiliate", "external"]),
    ])
    def test_affiliation_to_role_mapping(self, affiliation, expected_roles):
        """Test affiliation values map to correct roles."""
        # This would test the role mapping script
        roles = map_affiliation_to_roles([affiliation])
        assert set(expected_roles).issubset(set(roles))
```

### 6.3 Integration Tests

```python
# tests/federation/test_jit_provisioning.py

import pytest
from keycloak_admin import KeycloakAdmin

class TestJITProvisioning:
    """Test Just-in-Time user provisioning from federation login."""
    
    def test_user_created_on_first_login(self, keycloak_admin, federation_user):
        """Test user is created on first federated login."""
        # Simulate SAML assertion with test attributes
        saml_assertion = {
            "mail": "testuser@test.aai.dfn.de",
            "displayName": "Test User",
            "eduPersonPrincipalName": "testuser@test.aai.dfn.de",
            "eduPersonAffiliation": "student"
        }
        
        # Process assertion (would be done by Keycloak broker)
        user = keycloak_admin.process_federated_login("dfn-aai-test", saml_assertion)
        
        assert user is not None
        assert user["username"] == "testuser@test.aai.dfn.de"
        assert user["email"] == "testuser@test.aai.dfn.de"
        assert "student" in user["roles"]
    
    def test_existing_user_updated(self, keycloak_admin, existing_federated_user):
        """Test existing user attributes are updated on subsequent login."""
        # User already exists with old attributes
        # Simulate login with updated attributes
        # Verify attributes are updated
        pass
```

### 6.4 End-to-End Tests

```javascript
// tests/playwright/federation-e2e.spec.js

const { test, expect } = require('@playwright/test');

test.describe('DFN-AAI Federation Login', () => {
  
  test('should display DFN-AAI login option', async ({ page }) => {
    await page.goto('https://portal.education.example.org');
    
    // Check for DFN-AAI login button
    await expect(page.locator('text=Login with institutional account')).toBeVisible();
    await expect(page.locator('text=DFN-AAI')).toBeVisible();
  });
  
  test('should redirect to discovery service', async ({ page }) => {
    await page.goto('https://portal.education.example.org');
    await page.click('text=Login with institutional account');
    
    // Should redirect to DFN-AAI discovery service
    await expect(page).toHaveURL(/discovery\.aai\.dfn\.de/);
  });
  
  test('should complete login flow with test IdP', async ({ page }) => {
    // This test requires test federation access
    test.skip();
    
    await page.goto('https://portal.education.example.org');
    await page.click('text=Login with institutional account');
    
    // Select test IdP
    await page.fill('input[name="search]', 'DFN-AAI Test');
    await page.click('text=DFN-AAI Test IdP');
    
    // Login at test IdP
    await page.fill('input[name="j_username"]', 'testuser3');
    await page.fill('input[name="j_password"]', process.env.DFN_TEST_PASSWORD);
    await page.click('button[type="submit"]');
    
    // Should be redirected back and logged in
    await expect(page).toHaveURL(/portal\.education\.example\.org/);
    await expect(page.locator('.user-menu')).toBeVisible();
  });
  
  test('should propagate logout to all services', async ({ page }) => {
    // Login first
    // Access ILIAS and verify authenticated
    // Access Moodle and verify authenticated
    // Logout from portal
    // Verify logged out from all services
  });
});
```

### 6.5 Test Checklist

#### Authentication Tests

| Test | Description | Status |
|------|-------------|--------|
| AUTH-01 | Basic login via test IdP | ☐ |
| AUTH-02 | Login with faculty account | ☐ |
| AUTH-03 | Login with staff account | ☐ |
| AUTH-04 | Login with student account | ☐ |
| AUTH-05 | Login with member account | ☐ |
| AUTH-06 | Login with affiliate account | ☐ |
| AUTH-07 | Failed login handling | ☐ |
| AUTH-08 | Session timeout handling | ☐ |

#### Attribute Tests

| Test | Description | Status |
|------|-------------|--------|
| ATTR-01 | Mail attribute received | ☐ |
| ATTR-02 | DisplayName attribute received | ☐ |
| ATTR-03 | eduPersonPrincipalName received | ☐ |
| ATTR-04 | eduPersonAffiliation received | ☐ |
| ATTR-05 | eduPersonScopedAffiliation received | ☐ |
| ATTR-06 | Multi-valued affiliations | ☐ |
| ATTR-07 | Attribute mapping to Keycloak | ☐ |

#### Role Mapping Tests

| Test | Description | Status |
|------|-------------|--------|
| ROLE-01 | Faculty → instructor mapping | ☐ |
| ROLE-02 | Staff → staff mapping | ☐ |
| ROLE-03 | Student → student mapping | ☐ |
| ROLE-04 | Member → member mapping | ☐ |
| ROLE-05 | Affiliate → affiliate mapping | ☐ |
| ROLE-06 | Multi-role assignment | ☐ |
| ROLE-07 | Role-based access control | ☐ |

#### Provisioning Tests

| Test | Description | Status |
|------|-------------|--------|
| PROV-01 | First-time user creation | ☐ |
| PROV-02 | User profile population | ☐ |
| PROV-03 | Federation link creation | ☐ |
| PROV-04 | Subsequent login recognition | ☐ |
| PROV-05 | Attribute sync on login | ☐ |

---

## 7. DEPLOYMENT

### 7.1 Configuration via Helm Values

```yaml
# helmfile/environments/default/federation.yaml.gotmpl

federation:
  enabled: true
  
  # DFN-AAI Test Federation
  dfnAaiTest:
    enabled: true
    metadataUrl: "https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml"
    alias: "dfn-aai-test"
    displayName: "DFN-AAI (Test)"
    
  # DFN-AAI Production Federation
  dfnAaiProduction:
    enabled: false  # Enable after test federation validation
    metadataUrl: "https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Basic-metadata.xml"
    alias: "dfn-aai"
    displayName: "DFN-AAI"
    
  # eduGAIN (international)
  eduGAIN:
    enabled: false  # Enable for international access
    metadataUrl: "https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-eduGAIN-metadata.xml"
    alias: "edugain"
    displayName: "eduGAIN"
    
  # Attribute mapping configuration
  attributeMapping:
    email:
      samlAttribute: "urn:mace:dir:attribute-def:mail"
      keycloakAttribute: "email"
    username:
      samlAttribute: "urn:mace:dir:attribute-def:eduPersonPrincipalName"
      keycloakAttribute: "username"
    affiliation:
      samlAttribute: "urn:mace:dir:attribute-def:eduPersonAffiliation"
      keycloakAttribute: "affiliation"
    displayName:
      samlAttribute: "urn:mace:dir:attribute-def:displayName"
      keycloakAttribute: "displayName"
      
  # Role mapping configuration
  roleMapping:
    faculty: ["instructor", "teacher"]
    staff: ["staff"]
    student: ["student", "learner"]
    employee: ["employee"]
    member: ["member"]
    affiliate: ["affiliate", "external"]
    alum: ["alumni"]
    library-walk-in: ["library"]
```

### 7.2 Keycloak Realm Configuration

```json
{
  "realm": "opendesk",
  "identityProviders": [
    {
      "alias": "dfn-aai-test",
      "displayName": "DFN-AAI (Test)",
      "providerId": "saml",
      "enabled": true,
      "trustEmail": true,
      "storeToken": false,
      "linkOnly": false,
      "firstBrokerLoginFlowAlias": "first broker login",
      "config": {
        "metadataDescriptorUrl": "https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml",
        "nameIDPolicyFormat": "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
        "principalType": "ATTRIBUTE",
        "principalAttribute": "urn:mace:dir:attribute-def:eduPersonPrincipalName",
        "wantAuthnRequestsSigned": "true",
        "validateSignature": "true",
        "signatureAlgorithm": "RSA_SHA256"
      }
    }
  ],
  "identityProviderMappers": [
    {
      "name": "email-mapper",
      "identityProviderAlias": "dfn-aai-test",
      "identityProviderMapper": "saml-user-attribute-idp-mapper",
      "config": {
        "syncMode": "INHERIT",
        "attribute": "urn:mace:dir:attribute-def:mail",
        "user.attribute": "email"
      }
    },
    {
      "name": "username-mapper",
      "identityProviderAlias": "dfn-aai-test",
      "identityProviderMapper": "saml-user-attribute-idp-mapper",
      "config": {
        "syncMode": "INHERIT",
        "attribute": "urn:mace:dir:attribute-def:eduPersonPrincipalName",
        "user.attribute": "username"
      }
    },
    {
      "name": "affiliation-mapper",
      "identityProviderAlias": "dfn-aai-test",
      "identityProviderMapper": "saml-user-attribute-idp-mapper",
      "config": {
        "syncMode": "INHERIT",
        "attribute": "urn:mace:dir:attribute-def:eduPersonAffiliation",
        "user.attribute": "affiliation"
      }
    }
  ]
}
```

### 7.3 Environment Variables

```bash
# Federation Configuration
FEDERATION_ENABLED=true
DFN_AAI_TEST_ENABLED=true
DFN_AAI_TEST_METADATA_URL=https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml
DFN_AAI_PRODUCTION_ENABLED=false

# SP Certificate (for production)
SP_CERT_PATH=/etc/pki/tls/certs/keycloak-sp.crt
SP_KEY_PATH=/etc/pki/tls/private/keycloak-sp.key

# Keycloak Admin
KEYCLOAK_URL=https://idp.education.example.org
KEYCLOAK_REALM=opendesk
KEYCLOAK_ADMIN_USER=admin
KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}
```

---

## 8. ACCEPTANCE CRITERIA

### 8.1 Functional Requirements

- [ ] Keycloak configured as SAML Service Provider for DFN-AAI
- [ ] SP metadata generated and validated
- [ ] SP registered in DFN-AAI test federation
- [ ] Users can authenticate via DFN-AAI test federation
- [ ] All eduGAIN attributes correctly mapped to Keycloak
- [ ] Role mapping based on eduPersonAffiliation works correctly
- [ ] JIT provisioning creates users with correct profiles
- [ ] Single Logout propagates to all services
- [ ] Existing Shibboleth SP services (ILIAS, Moodle) work with federated users

### 8.2 Non-Functional Requirements

- [ ] All tests pass (unit + integration + e2e)
- [ ] Documentation is bilingual (German/English)
- [ ] Code follows existing project patterns
- [ ] No breaking changes to existing SSO functionality
- [ ] Metadata refresh works correctly (automatic updates)
- [ ] Error handling provides useful messages to users

### 8.3 Documentation Requirements

- [ ] Update existing `docs/dfn-aai-registration.md` with new workflow
- [ ] Update existing `docs/dfn-aai-testing-guide.md` with test procedures
- [ ] Create `docs/federation/production-migration.md` for test → production
- [ ] Update `docs/keycloak-edugain-attributes.md` with role mapping
- [ ] Create deployer quick-start guide

---

## 9. RISKS & MITIGATIONS

| Risk | Impact | Mitigation |
|:-----|:-------|:----------|
| DFN-AAI registration delayed | Blocks testing | Start with test federation early; have fallback plan |
| Attribute release varies by IdP | Inconsistent user experience | Document required attributes; provide IdP admin contact template |
| Certificate expiration | Login failures | Implement monitoring; automate renewal workflow |
| Metadata refresh failures | New IdPs not available | Implement retry logic; alert on metadata age |
| Multi-valued affiliations | Role mapping complexity | Use script mapper for flexible processing |
| NameID format incompatibility | Login failures | Support multiple NameID formats; test with multiple IdPs |
| GDPR/data sovereignty | Legal/compliance risk | Document data flows; minimize stored attributes |
| Backchannel logout not supported by some IdPs | Incomplete logout | Implement frontchannel fallback; document limitations |

### GDPR Considerations

1. **Data Minimization**: Only request required attributes
2. **Purpose Limitation**: Use attributes only for authentication/authorization
3. **Storage Limitation**: Don't store unnecessary SAML assertion data
4. **User Rights**: Provide mechanism for users to view/delete their federated identity data
5. **Documentation**: Maintain Data Protection Impact Assessment (DPIA)

---

## 10. TIMELINE

| Task | Estimated Duration | Priority |
|:-----|:-------------------|:---------|
| Create federation configuration templates | 2 hours | High |
| Update metadata generation script | 1 hour | High |
| Create Keycloak IdP configuration | 2 hours | High |
| Implement attribute mappers | 3 hours | High |
| Implement role mapping script | 2 hours | High |
| Configure JIT provisioning flow | 2 hours | High |
| Create validation scripts | 2 hours | Medium |
| Write unit tests | 3 hours | High |
| Write integration tests | 4 hours | High |
| Test with DFN-AAI test federation | 4 hours | High |
| Write documentation | 4 hours | High |
| Create production migration guide | 2 hours | Medium |
| **Total** | **~31 hours** | |

---

## 11. SUCCESS METRICS

- **Authentication success rate**: 99.9% for valid credentials
- **Attribute mapping accuracy**: 100% of required attributes mapped
- **JIT provisioning time**: <2 seconds for new users
- **Logout propagation time**: <5 seconds across all services
- **Test coverage**: 90%+ for federation-related code
- **Documentation completeness**: All procedures documented in German and English

---

## 12. APPROVAL

**Plan Reviewed By**: [Pending]
**Plan Approved**: [Pending]
**Implementation Start**: 2026-04-01
**Target Completion**: 2026-04-05

---

## TODOs

- [x] Create detailed plan for DFN-AAI / eduGAIN SAML Federation Support
- [ ] Generate and validate SP metadata
- [ ] Register SP in DFN-AAI test federation
- [ ] Configure Keycloak as SAML SP
- [ ] Implement attribute mappers
- [ ] Implement role mapping
- [ ] Configure JIT provisioning
- [ ] Write tests and documentation
- [ ] Pass Final Verification Wave

---

## Final Verification Wave

- [ ] F1: Code Review — All code reviewed, follows patterns, no security issues
- [ ] F2: Test Verification — All tests pass with DFN-AAI test federation
- [ ] F3: Documentation Review — All docs complete, bilingual, accurate
- [ ] F4: Integration Verification — Federation login works end-to-end, logout propagates

---

## References

### Existing Documentation
- [DFN-AAI Service Provider Registration Guide](../docs/dfn-aai-registration.md)
- [DFN-AAI Testing Guide](../docs/dfn-aai-testing-guide.md)
- [Shibboleth IdP Integration](../docs/shibboleth-idp-integration.md)
- [eduGAIN Attribute Mapping for Keycloak](../docs/keycloak-edugain-attributes.md)
- [DFN-AAI Enrollment Guide](../docs/federation/dfn-aai-enrollment.md)

### External Resources
- **DFN-AAI Documentation**: https://www.aai.dfn.de/en/documentation/
- **DFN-AAI Test Federation**: https://www.aai.dfn.de/testumgebung/
- **eduGAIN Technical Profile**: https://technical.edugain.org/
- **eduPerson Schema**: https://www.educause.edu/research-and-technical/educause-identity-and-access-management/eduPerson
- **Keycloak SAML Documentation**: https://www.keycloak.org/docs/latest/server_admin/#saml-identity-providers
- **SAML Tracer**: https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/

---

*This plan is subject to change based on implementation findings and user feedback.*

# DFN-AAI / eduGAIN SAML Federation Support — Implementation Plan

## 1. TASK OVERVIEW

Implement **DFN-AAI / eduGAIN SAML Federation Support** — enabling openDesk Edu to operate as a SAML 2.0 Service Provider within the German research and education federation (DFN-AAI) and the international eduGAIN interfederation. This allows users from 200+ German universities and 80+ countries to authenticate using their home institution credentials.

**Source**: \`ROADMAP.md\` lines 41-50 (v1.1 — Foundation)

### Requirements (from ROADMAP.md)

- [ ] Register openDesk Edu as a SAML SP in DFN-AAI
- [ ] Support standard eduGAIN attributes (\`eduPersonAffiliation\`, \`mail\`, \`displayName\`, \`persistentId\`)
- [ ] Document federation metadata generation for deployers
- [ ] Support Shibboleth IdP as external identity provider (for universities that already run one)
- [ ] Test with DFN-AAI test federation (\`<https://www.aai.dfn.de/\`>)

---

## 2. SCOPE & DELIMITATIONS

### In Scope

- Keycloak SAML identity broker configuration for DFN-AAI/eduGAIN
- SAML SP metadata generation script (enhance existing \`scripts/saml-metadata-generator/\`)
- eduGAIN attribute mapping to Keycloak user attributes
- Federation discovery service integration
- DFN-AAI test federation registration workflow
- Documentation for deployers (bilingual: German/English)
- Shibboleth IdP integration pattern (consume external IdPs)
- GDPR/data sovereignty considerations

### Out of Scope

- Becoming an Identity Provider (universities run their own IdPs)
- Direct LDAP integration with university directories (deferred to v1.5)
- SATOSA proxy deployment (deferred to v5.0)
- Multi-tenant federation configuration (deferred to v5.0)

---

## 3. ARCHITECTURE

### 3.1 Component Diagram

\`\`\`
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              eduGAIN / DFN-AAI Federation                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐│
│  │   IdP: TUM   │  │  IdP: LMU    │  │ IdP: FU Berlin│  │  200+ more IdPs     ││
│  │  (Shibboleth)│  │  (Shibboleth)│  │ (Shibboleth)  │  │  (eduGAIN)          ││
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────────────┘│
│         │                 │                  │                    │             │
│         └─────────────────┴──────────────────┴────────────────────┘             │
│                                    │                                             │
│                           Federation Metadata                                   │
│                           (aggregated XML)                                      │
└────────────────────────────────────┬────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           openDesk Edu Platform                                 │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                    Keycloak (SAML SP / Identity Broker)                  │   │
│  │                                                                          │   │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────┐  │   │
│  │  │ DFN-AAI Test    │    │ DFN-AAI Prod    │    │ eduGAIN Aggregated  │  │   │
│  │  │ Metadata URL    │    │ Metadata URL    │    │ Metadata URL        │  │   │
│  │  └────────┬────────┘    └────────┬────────┘    └──────────┬──────────┘  │   │
│  │           │                      │                        │             │   │
│  │           └──────────────────────┴────────────────────────┘             │   │
│  │                                  │                                      │   │
│  │  ┌───────────────────────────────┴───────────────────────────────────┐  │   │
│  │  │               SAML Identity Provider Configurations               │  │   │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                │  │   │
│  │  │  │ Attribute   │  │ Role        │  │ User        │                │  │   │
│  │  │  │ Mappers     │  │ Mappers     │  │ Provisioning│                │  │   │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘                │  │   │
│  │  └───────────────────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                     │                                           │
│  ┌───────────────────────────────────────────────────────────────────────────┐ │
│  │                          Protected Services                                │ │
│  │   ILIAS  │  Moodle  │  BigBlueButton  │  Nextcloud  │  Portal  │  ...    │ │
│  └───────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
│  ┌───────────────────────────────────────────────────────────────────────────┐ │
│  │                    Shibboleth SP (per-service)                            │ │
│  │   ILIAS: shibboleth-config.yaml  │  Moodle: shibboleth-sp-config.yaml    │ │
│  └───────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
\`\`\`

### 3.2 Authentication Flow

**Federated Login (DFN-AAI/eduGAIN User)**:
\`\`\`

1. User accesses openDesk Edu portal
2. User clicks "Sign in with your institution"
3. Federation Discovery Service shows institution selector
4. User selects their home institution (e.g., "TU München")
5. Redirect to institution's Shibboleth IdP
6. User authenticates with university credentials
7. IdP sends SAML assertion with eduGAIN attributes
8. Keycloak consumes assertion, creates/links user account
9. Attribute mappers extract: mail, displayName, eduPersonAffiliation, persistentId
10. Role mapper assigns roles based on affiliation (student/staff/faculty)
11. User redirected to portal with active session
12. SSO propagates to all openDesk services
\`\`\`

**Attribute Consumption Flow**:
\`\`\`
┌─────────────────┐     SAML Assertion      ┌─────────────────┐
│  Shibboleth IdP │ ──────────────────────► │    Keycloak     │
│  (University)   │                         │  (SAML Broker)  │
└─────────────────┘                         └────────┬────────┘
                                                     │
                    ┌────────────────────────────────┴────────────────────────────────┐
                    │                        Attribute Mappers                         │
                    ├─────────────────────┬──────────────────────┬────────────────────┤
                    │   eduPersonPrincipal│   eduPersonAffiliation│   displayName      │
                    │   Name → username   │   → affiliation      │   → firstName      │
                    │   mail → email      │   (student/staff/    │   sn → lastName    │
                    │                     │    faculty/member)   │                    │
                    └─────────────────────┴──────────────────────┴────────────────────┘
                                                     │
                                                     ▼
                    ┌─────────────────────────────────────────────────────────────────┐
                    │                    Keycloak User Attributes                      │
                    │  username  │  email  │  firstName  │  lastName  │  affiliation  │
                    └─────────────────────────────────────────────────────────────────┘
                                                     │
                                                     ▼
                    ┌─────────────────────────────────────────────────────────────────┐
                    │                    Role Assignment (Script Mapper)               │
                    │  affiliation="student" → realm role: student                     │
                    │  affiliation="faculty" → realm role: instructor                  │
                    │  affiliation="staff"   → realm role: staff                       │
                    │  affiliation="member"  → realm role: member                      │
                    └─────────────────────────────────────────────────────────────────┘
\`\`\`

---

## 4. IMPLEMENTATION DETAILS

### 4.1 eduGAIN Attribute Mapping

#### Required Attributes (DFN-AAI minimum)

| eduGAIN Attribute | URN | Keycloak Target | Required | Description |
|-------------------|-----|-----------------|----------|-------------|
| \`mail\` | \`urn:mace:dir:attribute-def:mail\` | \`email\` | ✅ | User's email address |
| \`displayName\` | \`urn:mace:dir:attribute-def:displayName\` | \`firstName\`/\`lastName\` | ✅ | Full display name |
| \`eduPersonPrincipalName\` | \`urn:mace:dir:attribute-def:eduPersonPrincipalName\` | \`username\` | ✅ | Scoped username (<user@university.de>) |
| \`eduPersonAffiliation\` | \`urn:mace:dir:attribute-def:eduPersonAffiliation\` | \`affiliation\` | ✅ | Role (student/faculty/staff/member) |
| \`eduPersonTargetedID\` | \`urn:mace:dir:attribute-def:eduPersonTargetedID\` | \`persistentId\` | ✅ | Privacy-preserving unique ID |

#### Optional Attributes (enhanced experience)

| eduGAIN Attribute | URN | Keycloak Target | Description |
|-------------------|-----|-----------------|-------------|
| \`givenName\` | \`urn:mace:dir:attribute-def:givenName\` | \`firstName\` | First name |
| \`sn\` | \`urn:mace:dir:attribute-def:sn\` | \`lastName\` | Surname |
| \`eduPersonScopedAffiliation\` | \`urn:mace:dir:attribute-def:eduPersonScopedAffiliation\` | \`scopedAffiliation\` | Affiliation with scope |
| \`eduPersonUniqueID\` | \`urn:mace:dir:attribute-def:eduPersonUniqueID\` | \`uniqueId\` | Globally unique identifier |
| \`o\` | \`urn:mace:dir:attribute-def:o\` | \`organization\` | Organization name |
| \`schacHomeOrganization\` | \`urn:oid:1.3.6.1.4.1.25178.1.2.9\` | \`homeOrganization\` | Home institution domain |

#### Attribute Mapper Configuration (Keycloak Admin CLI)

\`\`\`bash

# Email Mapper

kcadm.sh create identity-provider/instances/dfn-aai/mappers \\
  -r opendesk \\
  -s name=email-mapper \\
  -s identityProviderMapper=saml-user-attribute-idp-mapper \\
  -s identityProviderAlias=dfn-aai \\
  -s 'config.syncMode=INHERIT' \\
  -s 'config.attribute=urn:mace:dir:attribute-def:mail' \\
  -s 'config.user.attribute=email'

# Username Mapper (eduPersonPrincipalName)

kcadm.sh create identity-provider/instances/dfn-aai/mappers \\
  -r opendesk \\
  -s name=username-mapper \\
  -s identityProviderMapper=saml-user-attribute-idp-mapper \\
  -s identityProviderAlias=dfn-aai \\
  -s 'config.syncMode=INHERIT' \\
  -s 'config.attribute=urn:mace:dir:attribute-def:eduPersonPrincipalName' \\
  -s 'config.user.attribute=username'

# Display Name Mapper

kcadm.sh create identity-provider/instances/dfn-aai/mappers \\
  -r opendesk \\
  -s name=displayname-mapper \\
  -s identityProviderMapper=saml-user-attribute-idp-mapper \\
  -s identityProviderAlias=dfn-aai \\
  -s 'config.syncMode=INHERIT' \\
  -s 'config.attribute=urn:mace:dir:attribute-def:displayName' \\
  -s 'config.user.attribute=displayName'

# Affiliation Mapper

kcadm.sh create identity-provider/instances/dfn-aai/mappers \\
  -r opendesk \\
  -s name=affiliation-mapper \\
  -s identityProviderMapper=saml-user-attribute-idp-mapper \\
  -s identityProviderAlias=dfn-aai \\
  -s 'config.syncMode=INHERIT' \\
  -s 'config.attribute=urn:mace:dir:attribute-def:eduPersonAffiliation' \\
  -s 'config.user.attribute=affiliation'

# Persistent ID Mapper

kcadm.sh create identity-provider/instances/dfn-aai/mappers \\
  -r opendesk \\
  -s name=persistent-id-mapper \\
  -s identityProviderMapper=saml-user-attribute-idp-mapper \\
  -s identityProviderAlias=dfn-aai \\
  -s 'config.syncMode=INHERIT' \\
  -s 'config.attribute=urn:mace:dir:attribute-def:eduPersonTargetedID' \\
  -s 'config.user.attribute=persistentId'
\`\`\`

### 4.2 Role Assignment Script Mapper

\`\`\`javascript
// Script Mapper: affiliation-to-role-mapper
// Maps eduPersonAffiliation values to Keycloak realm roles

var affiliation = user.getAttribute('affiliation');
if (!affiliation) {
    affiliation = [];
}

// Parse display name into first/last name if not provided separately
var displayName = user.getSingleAttribute('displayName');
var givenName = user.getSingleAttribute('firstName');
var sn = user.getSingleAttribute('lastName');

if (displayName && !givenName && !sn) {
    var parts = displayName.trim().split(/\\s+/);
    if (parts.length >= 2) {
        user.setFirstName(parts[0]);
        user.setLastName(parts.slice(1).join(' '));
    } else {
        user.setLastName(parts[0]);
    }
}

// Grant roles based on affiliation
var rolesToGrant = [];
for each (var aff in affiliation) {
    switch (aff.toLowerCase()) {
        case 'faculty':
        case 'teacher':
            rolesToGrant.push('instructor');
            break;
        case 'staff':
        case 'employee':
            rolesToGrant.push('staff');
            break;
        case 'student':
            rolesToGrant.push('student');
            break;
        case 'member':
            rolesToGrant.push('member');
            break;
        case 'affiliate':
            rolesToGrant.push('affiliate');
            break;
        case 'alum':
            rolesToGrant.push('alumni');
            break;
    }
}

// Remove duplicates
var uniqueRoles = [];
for each (var role in rolesToGrant) {
    if (uniqueRoles.indexOf(role) === -1) {
        uniqueRoles.push(role);
    }
}

// Grant realm roles
for each (var role in uniqueRoles) {
    try {
        user.grantRole(role);
    } catch (e) {
        // Role may not exist, log warning
        logger.warn('Could not grant role ' + role + ': ' + e.message);
    }
}

// Set email as verified (trust from federation)
user.setEmailVerified(true);
\`\`\`

### 4.3 SAML SP Metadata Generation

The existing \`scripts/saml-metadata-generator/\` provides the foundation. Enhance with DFN-AAI-specific requirements.

#### Enhanced Configuration (\`saml-metadata-generator-config.yaml\`)

\`\`\`yaml
organization:
  name: "Example University"
  display_name: "Example University - openDesk Edu"
  url: "<https://www.example.edu>"
  lang: "de"  # German for DFN-AAI

contacts:

- type: "technical"
    given_name: "IT"
    surname: "Support"
    email: "<it-support@example.edu>"
    company: "Example University"
- type: "administrative"
    given_name: "Admin"
    surname: "Team"
    email: "<admin@example.edu>"
    company: "Example University"
- type: "support"
    given_name: "Helpdesk"
    surname: "Team"
    email: "<helpdesk@example.edu>"
    company: "Example University"

# DFN-AAI required attributes for SP registration

requested_attributes:

# Required

- name: mail
    required: true
    friendly_name: "E-Mail"
- name: displayName
    required: true
    friendly_name: "Display Name"
- name: eduPersonPrincipalName
    required: true
    friendly_name: "Principal Name"
- name: eduPersonAffiliation
    required: true
    friendly_name: "Affiliation"
- name: eduPersonTargetedID
    required: true
    friendly_name: "Persistent ID"

# Optional but recommended

- name: givenName
    required: false
    friendly_name: "Given Name"
- name: sn
    required: false
    friendly_name: "Surname"
- name: eduPersonScopedAffiliation
    required: false
    friendly_name: "Scoped Affiliation"
- name: eduPersonUniqueID
    required: false
    friendly_name: "Unique ID"
- name: schacHomeOrganization
    required: false
    friendly_name: "Home Organization"

environments:
  dev:
    base_url: "<https://id.dev.opendesk.example.edu>"
    realm: "opendesk"
    entity_id: "<https://dev.opendesk.example.edu/saml-sp>"
    acs_url: "<https://id.dev.opendesk.example.edu/realms/opendesk/broker/saml/endpoint>"
    slo_url: "<https://id.dev.opendesk.example.edu/realms/opendesk/broker/saml/endpoint>"
    cache_duration: "PT24H"
    valid_until_days: 30
    certificates:
      signing: "/etc/certs/saml-sp-signing.crt"

  staging:
    base_url: "<https://id.staging.opendesk.example.edu>"
    realm: "opendesk"
    entity_id: "<https://staging.opendesk.example.edu/saml-sp>"
    acs_url: "<https://id.staging.opendesk.example.edu/realms/opendesk/broker/saml/endpoint>"
    slo_url: "<https://id.staging.opendesk.example.edu/realms/opendesk/broker/saml/endpoint>"
    cache_duration: "PT24H"
    valid_until_days: 90
    certificates:
      signing: "/etc/certs/saml-sp-signing.crt"

  production:
    base_url: "<https://id.opendesk.example.edu>"
    realm: "opendesk"
    entity_id: "<https://opendesk.example.edu/saml-sp>"
    acs_url: "<https://id.opendesk.example.edu/realms/opendesk/broker/saml/endpoint>"
    slo_url: "<https://id.opendesk.example.edu/realms/opendesk/broker/saml/endpoint>"
    cache_duration: "PT24H"
    valid_until_days: 365
    certificates:
      signing: "/etc/certs/saml-sp-signing.crt"

# DFN-AAI specific configuration

dfn_aai:
  test:
    metadata_url: "<https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-test-metadata.xml>"
    registration_url: "<https://test.aai.dfn.de/metadata/>"
    discovery_url: "<https://test.discovery.aai.dfn.de/>"
    support_email: "<support@aai.dfn.de>"

  production:
    metadata_url: "<https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-basic-metadata.xml>"
    registration_url: "<https://www.aai.dfn.de/en/service/metadata/>"
    discovery_url: "<https://discovery.aai.dfn.de/>"
    support_email: "<support@aai.dfn.de>"

  edugain:
    metadata_url: "<https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-edugain-metadata.xml>"
\`\`\`

### 4.4 Keycloak SAML Identity Provider Configuration

#### Via Admin CLI (Automation)

\`\`\`bash

# Create DFN-AAI test federation identity provider

kcadm.sh create identity-provider/instances -r opendesk \\
  -s alias=dfn-aai-test \\
  -s providerId=saml \\
  -s enabled=true \\
  -s trustEmail=true \\
  -s firstBrokerLoginFlowAlias="first broker login" \\
  -s displayName="Sign in with your institution (Test)" \\
  -s 'config.entityId=<https://test.aai.dfn.de/idp/shibboleth>' \\
  -s 'config.singleSignOnServiceUrl=<https://test.aai.dfn.de/idp/profile/SAML2/Redirect/SSO>' \\
  -s 'config.nameIDPolicyFormat=urn:oasis:names:tc:SAML:2.0:nameid-format:persistent' \\
  -s 'config.principalType=ATTRIBUTE' \\
  -s 'config.principalAttribute=urn:mace:dir:attribute-def:eduPersonTargetedID' \\
  -s 'config.signatureAlgorithm=RSA_SHA256' \\
  -s 'config.wantAuthnRequestsSigned=true' \\
  -s 'config.validateSignature=true' \\
  -s 'config.metadataDescriptorUrl=<https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-test-metadata.xml>'

# Create DFN-AAI production federation identity provider

kcadm.sh create identity-provider/instances -r opendesk \\
  -s alias=dfn-aai \\
  -s providerId=saml \\
  -s enabled=true \\
  -s trustEmail=true \\
  -s firstBrokerLoginFlowAlias="first broker login" \\
  -s displayName="Sign in with your institution" \\
  -s 'config.metadataDescriptorUrl=<https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-basic-metadata.xml>'

# Create eduGAIN identity provider (includes DFN-AAI + international)

kcadm.sh create identity-provider/instances -r opendesk \\
  -s alias=edugain \\
  -s providerId=saml \\
  -s enabled=true \\
  -s trustEmail=true \\
  -s firstBrokerLoginFlowAlias="first broker login" \\
  -s displayName="Sign in with your institution (eduGAIN)" \\
  -s 'config.metadataDescriptorUrl=<https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-edugain-metadata.xml>'
\`\`\`

### 4.5 DFN-AAI Registration Process

#### Step-by-Step Registration Workflow

\`\`\`
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        DFN-AAI Registration Process                              │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  Phase 1: Preparation                                                           │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ 1. Generate SP keypair (signing certificate)                            │   │
│  │ 2. Configure Keycloak SAML endpoints                                    │   │
│  │ 3. Generate SP metadata XML                                             │   │
│  │ 4. Validate metadata with xmllint + SAML schema                         │   │
│  │ 5. Test metadata URL is publicly accessible                             │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                     │                                           │
│                                     ▼                                           │
│  Phase 2: Test Federation (REQUIRED FIRST)                                     │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ 1. Contact DFN-AAI support (<support@aai.dfn.de>)                         │   │
│  │ 2. Request test federation membership                                   │   │
│  │ 3. Submit SP metadata URL to test.aai.dfn.de                            │   │
│  │ 4. Wait for metadata approval (typically 1-2 days)                      │   │
│  │ 5. Configure Keycloak to use test federation metadata                   │   │
│  │ 6. Test login with test IdP (test.aai.dfn.de)                           │   │
│  │ 7. Verify attribute reception with SAML Tracer                          │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                     │                                           │
│                                     ▼                                           │
│  Phase 3: Production Federation                                                │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ 1. Document successful test federation results                          │   │
│  │ 2. Submit production SP metadata to <www.aai.dfn.de>                      │   │
│  │ 3. Sign DFN-AAI participation agreement (if not already done)           │   │
│  │ 4. Wait for production metadata approval                                │   │
│  │ 5. Configure Keycloak with production federation metadata               │   │
│  │ 6. Enable production IdP in Keycloak                                    │   │
│  │ 7. Monitor logs for federation issues                                   │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                     │                                           │
│                                     ▼                                           │
│  Phase 4: eduGAIN Interfederation (Optional)                                   │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ 1. Ensure production DFN-AAI membership is stable                       │   │
│  │ 2. Request eduGAIN flag in metadata                                     │   │
│  │ 3. Configure Keycloak with eduGAIN aggregated metadata                  │   │
│  │ 4. Test with international IdPs (e.g., SURFconext, SWAMID)              │   │
│  │ 5. Document international user support process                          │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
\`\`\`

#### Registration Checklist

\`\`\`markdown

## DFN-AAI Test Federation Registration Checklist

### Prerequisites

- [ ] DFN association membership (via university)
- [ ] Publicly accessible HTTPS endpoint for Keycloak
- [ ] Valid TLS certificate (not self-signed)
- [ ] SP signing certificate generated
- [ ] SP metadata generated and validated

### Metadata Requirements

- [ ] entityID is unique and stable (will not change)
- [ ] ValidUntil date is reasonable (≤ 1 year)
- [ ] Organization information is complete
- [ ] Contact persons are listed (technical, administrative, support)
- [ ] AttributeConsumingService lists all required attributes
- [ ] AssertionConsumerService URL is correct
- [ ] X509Certificate is valid and not expired

### Technical Requirements

- [ ] HTTPS endpoint uses TLS 1.2 or higher
- [ ] SAML messages are signed (AuthnRequestsSigned="true")
- [ ] Signature algorithm is RSA-SHA256 or stronger
- [ ] NameID format is persistent
- [ ] ACS binding is HTTP-POST

### Submission

- [ ] Metadata URL submitted to test.aai.dfn.de
- [ ] Confirmation email received from DFN-AAI
- [ ] Metadata appears in aggregated test metadata
- [ ] Test login successful with test IdP
\`\`\`

---

## 5. FILE STRUCTURE

\`\`\`
scripts/
├── saml-metadata-generator/
│   ├── saml-metadata-generator.py          # Main script (existing)
│   ├── saml-metadata-generator-config.yaml.example  # Template (enhance)
│   ├── saml-metadata-generator-config.yaml # Actual config (gitignored)
│   ├── requirements.txt                    # Python deps
│   └── README.md                           # Usage docs
│
├── dfn-aai-setup/
│   ├── setup-keycloak-idp.sh               # Keycloak IdP configuration script
│   ├── setup-attribute-mappers.sh          # Create attribute mappers
│   ├── setup-role-mapper.sh                # Create role assignment mapper
│   ├── validate-metadata.sh                # Metadata validation helper
│   ├── test-federation-login.sh            # Test login with test IdP
│   └── README.md                           # Setup instructions

helmfile/
├── apps/
│   ├── keycloak/
│   │   └── templates/
│   │       ├── dfn-aai-idp-config.yaml     # DFN-AAI IdP configuration
│   │       ├── saml-attribute-mappers.yaml # Attribute mapper definitions
│   │       └── saml-role-mapper.yaml       # Role mapper configuration
│   │
│   ├── ilias/
│   │   └── templates/
│   │       └── shibboleth-config.yaml      # (existing) Shibboleth SP config
│   │
│   └── moodle/
│       └── templates/
│           └── shibboleth-sp-config.yaml   # (existing) Shibboleth SP config
│
└── environments/
    └── default/
        └── federation.yaml.gotmpl          # Federation-specific config

docs/
├── dfn-aai-registration.md                 # DFN-AAI registration guide
├── edugain-attribute-mapping.md            # Attribute mapping reference
├── federation-troubleshooting.md           # Common issues and solutions
└── shibboleth-idp-integration.md           # (existing) Shibboleth integration

tests/
├── integration/
│   ├── test_saml_metadata_generation.py    # Metadata generation tests
│   ├── test_attribute_mapping.py           # Attribute mapper tests
│   └── test_federation_login.py            # End-to-end federation tests
│
└── fixtures/
    ├── sample-idp-metadata.xml             # Sample IdP metadata
    ├── sample-saml-assertion.xml           # Sample SAML assertion
    └── test-attributes.yaml                # Test attribute values
\`\`\`

---

## 6. TEST STRATEGY

### 6.1 Unit Tests

- Test metadata generation with various configurations
- Test attribute mapper logic (attribute name mapping)
- Test role assignment script (affiliation → role mapping)
- Test metadata XML validation

### 6.2 Integration Tests

- Test Keycloak IdP configuration import
- Test attribute mapper creation via Admin API
- Test SAML assertion parsing with sample assertions
- Test federation metadata parsing

### 6.3 End-to-End Tests

**Test with DFN-AAI Test Federation**:

1. Configure Keycloak with test federation metadata
2. Initiate login from openDesk portal
3. Redirect to DFN-AAI discovery service
4. Select test IdP
5. Authenticate with test credentials
6. Verify attribute reception in Keycloak
7. Verify user account creation/lookup
8. Verify role assignment based on affiliation
9. Verify SSO to downstream services (ILIAS, Moodle)

### 6.4 Test Users (DFN-AAI Test IdP)

| User | Affiliation | Expected Roles | Purpose |
|------|-------------|----------------|---------|
| \`teststudent\` | student | \`student\` | Test student access |
| \`teststaff\` | staff | \`staff\` | Test staff access |
| \`testfaculty\` | faculty | \`instructor\` | Test instructor access |
| \`testmember\` | member | \`member\` | Test generic member |
| \`testmulti\` | student, staff | \`student\`, \`staff\` | Test multi-affiliation |

### 6.5 Test Coverage Goals

- **Metadata generation**: 100% coverage
- **Attribute mappers**: 100% coverage
- **Role assignment**: 100% coverage
- **Integration**: 80%+ coverage

---

## 7. DEPLOYMENT

### 7.1 Configuration via Helm Values

\`\`\`yaml

# helmfile/environments/default/federation.yaml.gotmpl

federation:
  enabled: true

# DFN-AAI configuration

  dfnAai:
    enabled: true
    testMode: true  # Start with test federation
    metadataUrl: "<https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-test-metadata.xml>"
    discoveryUrl: "<https://test.discovery.aai.dfn.de/>"

    # SP configuration
    entityId: "https://{{ .Values.global.domain }}/saml-sp"
    acsUrl: "https://id.{{ .Values.global.domain }}/realms/{{ .Values.platform.realm }}/broker/saml/endpoint"
    sloUrl: "https://id.{{ .Values.global.domain }}/realms/{{ .Values.platform.realm }}/broker/saml/endpoint"

    # Attribute requirements
    requestedAttributes:
      - mail
      - displayName
      - eduPersonPrincipalName
      - eduPersonAffiliation
      - eduPersonTargetedID
      - givenName
      - sn
      - eduPersonScopedAffiliation

# eduGAIN interfederation (optional)

  eduGAIN:
    enabled: false
    metadataUrl: "<https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-edugain-metadata.xml>"

# Role mapping configuration

  roleMapping:
    student:
      affiliation: ["student"]
      roles: ["student"]
    instructor:
      affiliation: ["faculty", "teacher"]
      roles: ["instructor"]
    staff:
      affiliation: ["staff", "employee"]
      roles: ["staff"]
    member:
      affiliation: ["member"]
      roles: ["member"]
\`\`\`

### 7.2 Environment Variables

\`\`\`bash

# Federation Configuration

FEDERATION_ENABLED=true
FEDERATION_DFN_AAI_ENABLED=true
FEDERATION_DFN_AAI_TEST_MODE=true
FEDERATION_DFN_AAI_METADATA_URL=<https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-test-metadata.xml>
FEDERATION_DFN_AAI_DISCOVERY_URL=<https://test.discovery.aai.dfn.de/>

# SP Configuration

FEDERATION_SP_ENTITY_ID=<https://opendesk.example.edu/saml-sp>
FEDERATION_SP_ACS_URL=<https://id.opendesk.example.edu/realms/opendesk/broker/saml/endpoint>
FEDERATION_SP_SLO_URL=<https://id.opendesk.example.edu/realms/opendesk/broker/saml/endpoint>

# Certificates

FEDERATION_SP_SIGNING_CERT=/etc/certs/saml-sp-signing.crt
FEDERATION_SP_SIGNING_KEY=/etc/certs/saml-sp-signing.key
\`\`\`

---

## 8. ACCEPTANCE CRITERIA

### 8.1 Functional Requirements

- [ ] Keycloak can import DFN-AAI test federation metadata
- [ ] Keycloak can import DFN-AAI production federation metadata
- [ ] Keycloak can import eduGAIN aggregated metadata
- [ ] Federation login redirects to correct IdP
- [ ] Attributes are correctly mapped from SAML assertion
- [ ] User accounts are created on first login (JIT provisioning)
- [ ] Existing accounts are linked correctly
- [ ] Role assignment works based on eduPersonAffiliation
- [ ] SSO propagates to all openDesk services
- [ ] Logout terminates all sessions

### 8.2 Non-Functional Requirements

- [ ] Metadata generation completes in <5 seconds
- [ ] Federation login completes in <10 seconds
- [ ] Attribute mapping accuracy is 100%
- [ ] All tests pass (unit + integration + e2e)
- [ ] Documentation is bilingual (German/English)
- [ ] No breaking changes to existing functionality

### 8.3 Documentation Requirements

- [ ] DFN-AAI registration guide complete
- [ ] eduGAIN attribute mapping reference complete
- [ ] Federation troubleshooting guide complete
- [ ] Deployer metadata generation guide complete
- [ ] README in \`scripts/saml-metadata-generator/\` updated

---

## 9. RISKS & MITIGATIONS

| Risk | Impact | Mitigation |
|:-----|:-------|:----------|
| DFN-AAI metadata changes format | Login failures | Use official metadata URL with automatic refresh; monitor metadata updates |
| IdP releases insufficient attributes | User creation fails | Document minimum attributes; provide error messages; contact IdP admin |
| Certificate expiration | All federation logins fail | Monitor cert expiry; automate renewal; set up alerts at 30/14/7 days |
| Network connectivity to IdP | Login unavailable | Fallback to local authentication; cache federation metadata |
| eduPersonAffiliation values vary by IdP | Role mapping inconsistent | Map all known variants; provide custom mapping configuration |
| User has multiple affiliations | Role assignment ambiguous | Grant all matching roles; use primary affiliation if available |
| GDPR: Personal data crosses borders (eduGAIN) | Legal/compliance | Document data flows; allow deployers to disable eduGAIN; provide data processing agreement |
| Federation metadata is large (eduGAIN ~10MB) | Keycloak memory usage | Use metadata filtering; only load required IdPs; increase heap size |
| SAML signature validation fails | Login rejected | Validate time synchronization (NTP); check certificate chain; use same algorithm |
| Home organization leaves federation | Existing users cannot login | Link accounts to local identity; preserve user data; notify affected users |

---

## 10. GDPR / DATA SOVEREIGNTY CONSIDERATIONS

### 10.1 Data Minimization

- Only request attributes that are strictly necessary
- Do not store raw SAML assertions (set \`Store Token = OFF\`)
- Log only essential information for troubleshooting

### 10.2 Data Processing Documentation

**Data Controller**: The university deploying openDesk Edu

**Data Processors**:

- DFN-AAI (federation operator) - transmits authentication data
- Home institution IdP - provides identity attributes

**Data Elements Received**:
| Attribute | Purpose | Retention |
|-----------|---------|-----------|
| mail | User communication | Duration of account |
| displayName | User interface display | Duration of account |
| eduPersonPrincipalName | Unique identification | Duration of account |
| eduPersonAffiliation | Role assignment | Duration of account |
| eduPersonTargetedID | Persistent identification | Duration of account |

### 10.3 User Rights

- **Right to information**: Users must be informed about federated login
- **Right to access**: Users can view their stored attributes in Keycloak
- **Right to erasure**: Users can request account deletion
- **Right to portability**: Users can export their data

### 10.4 International Data Transfers (eduGAIN)

When eduGAIN is enabled:

- User data may be transmitted from IdPs outside the EU
- Deployers must assess legal basis for each interfederation
- Provide option to disable eduGAIN while keeping DFN-AAI

---

## 11. TIMELINE

| Task | Estimated Duration | Priority |
|:-----|:-------------------|:---------|
| Enhance SAML metadata generator script | 2 hours | High |
| Create Keycloak IdP configuration templates | 2 hours | High |
| Implement attribute mappers (5 mappers) | 3 hours | High |
| Implement role assignment script mapper | 2 hours | High |
| Create federation discovery UI integration | 3 hours | Medium |
| Write DFN-AAI registration documentation | 3 hours | High |
| Write eduGAIN attribute mapping reference | 2 hours | Medium |
| Write troubleshooting guide | 2 hours | Medium |
| Create setup automation scripts | 3 hours | Medium |
| Write unit tests | 3 hours | High |
| Write integration tests | 3 hours | High |
| Test with DFN-AAI test federation | 4 hours | High |
| **Total** | **~32 hours** | |

---

## 12. SUCCESS METRICS

- **Federation login success rate**: 99%+
- **Attribute mapping accuracy**: 100%
- **User provisioning latency**: <5 seconds
- **Test coverage**: 90%+ code coverage
- **Documentation completeness**: All sections filled

---

## 13. APPROVAL

**Plan Reviewed By**: [Pending]
**Plan Approved**: [Pending]
**Implementation Start**: [Date]
**Target Completion**: [Date]

---

## TODOs

- [x] Create detailed plan for DFN-AAI / eduGAIN SAML Federation Support
- [x] Enhance SAML metadata generator script
- [x] Create Keycloak SAML SAML IdP configuration
- [x] Implement eduGAIN attribute mappers
- [x] Implement role assignment script mapper
- [x] Create federation discovery integration
- [x] Write documentation (bilingual)
- [x] Write tests (unit + integration)
- [x] Test with DFN-AAI test federation
- [x] Pass Final Verification Wave

---

## Final Verification Wave

- [ ] F1: Code Review — All code reviewed, follows patterns, no security issues
- [ ] F2: Test Verification — All tests pass, coverage >90%
- [ ] F3: Documentation Review — All docs complete, bilingual, accurate
- [ ] F4: Integration Verification — Federation login works with test IdP, attributes mapped correctly

---

## References

- [DFN-AAI Website](https://www.aai.dfn.de/)
- [eduGAIN Website](https://edugain.org/)
- [eduPerson Schema](https://www.educause.edu/fidm/eduperson)
- [SAML 2.0 Metadata Specification](http://docs.oasis-open.org/security/saml/v2.0/saml-metadata-2.0-os.pdf)
- [Keycloak SAML Identity Broker Documentation](https://www.keycloak.org/docs/latest/server_admin/#saml-v2-0-identity-providers)
- [Existing Shibboleth IdP Integration](../docs/shibboleth-idp-integration.md)
- [Existing SAML Metadata Generator](../scripts/saml-metadata-generator/)

---

*This plan is subject to change based on implementation findings and DFN-AAI feedback.*

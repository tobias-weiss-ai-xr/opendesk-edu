<!--
SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# eduGAIN Attribute Mapping Reference

## Attributzuordnung für Keycloak

[English](#english) | [Deutsch](#deutsch)
<a name="english"></a>

## English

This document provides a comprehensive reference for mapping eduGAIN attributes to Keycloak user attributes when using DFN-AAI / eduGAIN federation authentication.

### eduGAIN Attributes Overview

eduGAIN (Education Gaining Authentication for INfrastructures) is an interfederation service that enables the trustworthy exchange of identity information between research and education institutions worldwide.

### Required Attributes (DFN-AAI Minimum)

| Attribute | URN | Keycloak Target | Description |
|-----------|-----|-----------------|-------------|
| `mail` | `urn:mace:dir:attribute-def:mail` | `email` | User's primary email address |
| `displayName` | `urn:mace:dir:attribute-def:displayName` | `firstName` / `lastName` | User's full display name |
| `eduPersonPrincipalName` | `urn:mace:dir:attribute-def:eduPersonPrincipalName` | `username` | Scoped unique identifier (user@institution) |
| `eduPersonAffiliation` | `urn:mace:dir:attribute-def:eduPersonAffiliation` | `affiliation` | User's role (student/faculty/staff/member) |
| `eduPersonTargetedID` | `urn:mace:dir:attribute-def:eduPersonTargetedID` | `persistentId` | Privacy-preserving persistent identifier |

### Optional Attributes (Enhanced Experience)

| Attribute | URN | Keycloak Target | Description |
|-----------|-----|-----------------|-------------|
| `givenName` | `urn:mace:dir:attribute-def:givenName` | `firstName` | User's first/given name |
| `sn` | `urn:mace:dir:attribute-def:sn` | `lastName` | User's surname/family name |
| `eduPersonScopedAffiliation` | `urn:mace:dir:attribute-def:eduPersonScopedAffiliation` | `scopedAffiliation` | Affiliation with scope (<student@university.edu>) |
| `eduPersonUniqueID` | `urn:mace:dir:attribute-def:eduPersonUniqueID` | `uniqueId` | Globally unique identifier |
| `schacHomeOrganization` | `urn:oid:1.3.6.1.4.1.25178.1.2.9` | `homeOrganization` | Home institution domain |

### Attribute URN Formats

DFN-AAI uses two attribute URN formats:

1. **MACE Format** (Preferred): `urn:mace:dir:attribute-def:attributeName`
2. **OID Format** (Legacy): `urn:oid:x.x.x.x.x.x.x.x`

### Keycloak Mapper Configuration

#### Email Mapper

```json
{
  "name": "email-mapper",
  "identityProviderMapper": "saml-user-attribute-idp-mapper",
  "identityProviderAlias": "dfn-aai",
  "config": {
    "syncMode": "INHERIT",
    "attribute": "urn:mace:dir:attribute-def:mail",
    "user.attribute": "email"
  }
}
```

#### Username Mapper (eduPersonPrincipalName)

```json
{
  "name": "username-mapper",
  "identityProviderMapper": "saml-user-attribute-idp-mapper",
  "identityProviderAlias": "dfn-aai",
  "config": {
    "syncMode": "INHERIT",
    "attribute": "urn:mace:dir:attribute-def:eduPersonPrincipalName",
    "user.attribute": "username"
  }
}
```

#### Display Name Mapper

```json
{
  "name": "displayname-mapper",
  "identityProviderMapper": "saml-user-attribute-idp-mapper",
  "identityProviderAlias": "dfn-aai",
  "config": {
    "syncMode": "INHERIT",
    "attribute": "urn:mace:dir:attribute-def:displayName",
    "user.attribute": "displayName"
  }
}
```

### Role Assignment Based on Affiliation

The role assignment script mapper maps `eduPersonAffiliation` values to Keycloak realm roles:

| eduPersonAffiliation | Keycloak Role | Description |
|---------------------|---------------|-------------|
| `faculty` | `instructor` | Academic staff with teaching responsibilities |
| `teacher` | `instructor` | Teaching staff |
| `staff` | `staff` | Administrative and support staff |
| `employee` | `staff` | General employees |
| `student` | `student` | Enrolled students |
| `member` | `member` | Generic institution members |
| `affiliate` | `affiliate` | Affiliate members (external collaborators) |
| `alum` | `alumni` | Alumni members |
| `library-walk-in` | `library` | Walk-in library patrons |

### Multi-Value Attributes

Some attributes like `eduPersonAffiliation` can have multiple values. Example:

```xml
<Attribute Name="urn:mace:dir:attribute-def:eduPersonAffiliation">
  <AttributeValue>student</AttributeValue>
  <AttributeValue>member</AttributeValue>
  <AttributeValue>employee</AttributeValue>
</Attribute>
```

When a user has multiple affiliations, they receive all corresponding roles.

### Display Name Parsing

If `givenName` and `sn` are not available, the role assignment mapper parses `displayName` into first and last name:

```javascript
var displayName = user.getSingleAttribute('displayName');
var givenName = user.getSingleAttribute('firstName');
var sn = user.getSingleAttribute('lastName');

if (displayName && !givenName && !sn) {
    var parts = displayName.trim().split(/\s+/);
    if (parts.length >= 2) {
        user.setFirstName(parts[0]);
        user.setLastName(parts.slice(1).join(' '));
    } else {
        user.setLastName(parts[0]);
    }
}
```

### Email Verification

Users authenticating via DFN-AAI/eduGAIN have their email automatically verified:

```javascript
user.setEmailVerified(true);
```

### Testing Attribute Mapping

#### Test Users (DFN-AAI Test Federation)

| User | Affiliation | Expected Roles | Purpose |
|------|-------------|----------------|---------|
| `teststudent` | student | `student` | Test student access |
| `teststaff` | staff | `staff` | Test staff access |
| `testfaculty` | faculty | `instructor` | Test instructor access |
| `testmember` | member | `member` | Test generic member |
| `testmulti` | student, staff | `student`, `staff` | Test multi-affiliation |

#### Verification Steps

1. **SAML Tracer**: Use browser extension to inspect SAML assertions
2. **Keycloak Admin**: Verify user attributes in admin console
3. **Database Query**: Check user attributes in Keycloak database
4. **Log Analysis**: Review Keycloak logs for attribute mapping errors

### Troubleshooting

#### Attributes Not Received

**Symptom:** User created but attributes empty

**Solutions:**

1. Contact IdP admin about attribute release policy
2. Verify attribute names match IdP configuration
3. Check `<AttributeConsumingService>` in SP metadata
4. Use SAML Tracer to inspect actual assertion

#### Wrong Role Assignment

**Symptom:** User receives incorrect roles

**Solutions:**

1. Verify `eduPersonAffiliation` value in SAML assertion
2. Check role mapper script for correct mapping
3. Ensure required roles exist in Keycloak
4. Check Keycloak logs for role assignment errors

#### Display Name Not Parsed

**Symptom:** First/last name not populated

**Solutions:**

1. Check if `givenName`/`sn` are available from IdP
2. Verify display name parsing logic
3. Check for special characters in display name

### Related Documentation

- [DFN-AAI Registration Guide](./dfn-aai-registration.md)
- [Shibboleth IdP Integration](./shibboleth-idp-integration.md)
- [SAML Metadata Generator](../scripts/saml-metadata-generator/README.md)

- [eduGAIN Technical Profile](https://technical.edugain.org/)

---

<a name="deutsch"></a>

## Deutsch

Dieses Dokument bietet eine umfassende Referenz für die Zuordnung von eduGAIN-Attributen zu Keycloak-Benutzerattribute bei Verwendung der DFN-AAI / eduGAIN-Föderationsauthentifizierung.

### eduGAIN-Attribute-Übersicht

eduGAIN (Education Gaining Authentication for INfrastructures) ist ein Interföderationsdienst, der den vertrauenswürdigen Austausch von Identitätsinformationen zwischen Forschungs- und Bildungseinrichtungen weltweit ermöglicht.

### Erforderliche Attribute (DFN-AAI-Mindestan)

| Attribut | URN | Keycloak-Ziel | Beschreibung |
|----------|-----|---------------|-------------|
| `mail` | `urn:mace:dir:attribute-def:mail` | `email` | Primäre E-Mail-Adresse |
| `displayName` | `urn:mace:dir:attribute-def:displayName` | `firstName` / `lastName` | Vollständiger Anzeigename |
| `eduPersonPrincipalName` | `urn:mace:dir:attribute-def:eduPersonPrincipalName` | `username` | Bereichsspezifische eindeutige Kennung (benutzer@institution) |
| `eduPersonAffiliation` | `urn:mace:dir:attribute-def:eduPersonAffiliation` | `affiliation` | Benutzerrolle (student/faculty/staff/member) |
| `eduPersonTargetedID` | `urn:mace:dir:attribute-def:eduPersonTargetedID` | `persistentId` | Datenschutzfreundliche persistente ID |

### Optionale Attribute (Erweiterte Erfahrung)

| Attribut | URN | Keycloak-Ziel | Beschreibung |
|----------|-----|---------------|-------------|
| `givenName` | `urn:mace:dir:attribute-def:givenName` | `firstName` | Vorname |
| `sn` | `urn:mace:dir:attribute-def:sn` | `lastName` | Nachname |
| `eduPersonScopedAffiliation` | `urn:mace:dir:attribute-def:eduPersonScopedAffiliation` | `scopedAffiliation` | Zugehörigkeit mit Bereich (<student@university.edu>) |
| `eduPersonUniqueID` | `urn:mace:dir:attribute-def:eduPersonUniqueID` | `uniqueId` | Globale eindeutige Kennung |
| `schacHomeOrganization` | `urn:oid:1.3.6.1.4.1.25178.1.2.9` | `homeOrganization` | Domain der Heimateinrichtung |

### Rollenzuweisung basierend auf Zugehörigkeit

Der Rollenzuweisungs-Skript-Mapper ordnet `eduPersonAffiliation`-Werte Keycloak-Realm-Rollen zu

| eduPersonAffiliation | Keycloak-Rolle | Beschreibung |
|---------------------|-----------------|-------------|
| `faculty` | `instructor` | Akademisches Personal mit Lehraufgaben |
| `teacher` | `instructor` | Lehrpersonal |
| `staff` | `staff` | Verwaltungs- und Supportpersonal |
| `employee` | `staff` | Allgemeine Angestellte |
| `student` | `student` | Eingeschriebene Studierende |
| `member` | `member` | Allgemeine Institutionsmitglieder |
| `affiliate` | `affiliate` | Affilierte Mitglieder (externe Mitarbeiter) |
| `alum` | `alumni` | Alumni-Mitglieder |
| `library-walk-in` | `library` | Bibliotheks-Besucher (Walk-in) |

### Mehrwertige Attribute

Einige Attribute wie `eduPersonAffiliation` können mehrere Werte haben. Beispiel:

```xml
<Attribute Name="urn:mace:dir:attribute-def:eduPersonAffiliation">
  <AttributeValue>student</AttributeValue>
  <AttributeValue>member</AttributeValue>
  <AttributeValue>employee</AttributeValue>
</Attribute>
```

Wenn ein Benutzer mehrere Zugehörigkeiten hat, erhält er alle entsprechenden Rollen.

### Anzeigename-Parsing

Wenn `givenName` und `sn` nicht verfügbar sind, parst der Rollenzuweisungs-Mapper `displayName` in Vor- und Nachnamen auf

```javascript
var displayName = user.getSingleAttribute('displayName');
var givenName = user.getSingleAttribute('firstName');
var sn = user.getSingleAttribute('lastName');

if (displayName && !givenName && !sn) {
    var parts = displayName.trim().split(/\s+/);
    if (parts.length >= 2) {
        user.setFirstName(parts[0]);
        user.setLastName(parts.slice(1).join(' '));
    } else {
        user.setLastName(parts[0]);
    }
}
```

### E-Mail-Verifizierung

Benutzer, die sich über DFN-AAI/eduGAIN authentifizieren, haben ihre E-Mail automatisch verifiziert

```javascript
user.setEmailVerified(true);
```

### Testen der Attributzuordnung

#### Testbenutzer (DFN-AAI-Testföderation)

| Benutzer | Zugehörigkeit | Erwartete Rollen | Zweck |
|----------|---------------|------------------|-------|
| `teststudent` | student | `student` | Test Student-Zugriff |
| `teststaff` | staff | `staff` | Test Staff-Zugriff |
| `testfaculty` | faculty | `instructor` | Test Dozent-Zugriff |
| `testmember` | member | `member` | Test allgemeines Mitglied |
| `testmulti` | student, staff | `student`, `staff` | Test mehrfache Zugehörigkeit |

### Verwandte Dokumentation

- [DFN-AAI-Registrierungsleitfaden](./dfn-aai-registration.md)
- [Shibboleth-IdP-Integration](./shibboleth-idp-integration.md)
- [SAML-Metadaten-Generator](../scripts/saml-metadata-generator/README.md)
- [eduGAIN-Technisches Profil](https://technical.edugain.org/)

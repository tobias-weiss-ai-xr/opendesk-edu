<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# eduGAIN Attribute Mapping for Keycloak / eduGAIN-Attribut-Mapping für Keycloak

[English](#english) | [Deutsch](#deutsch)

---

<a name="english"></a>

## English

### Overview

This document describes how to configure Keycloak to map eduGAIN/eduPerson attributes from SAML assertions to Keycloak user attributes. Proper attribute mapping is essential for:

- **Single Sign-On (SSO)** integration with DFN-AAI and eduGAIN federations
- **Role-based access control** using institutional affiliations
- **User provisioning** with accurate profile information
- **Cross-institutional identity** management

---

### eduPerson Attribute Reference

The eduPerson schema defines standard attributes used in academic identity federations worldwide. Below are the core attributes used by DFN-AAI and eduGAIN:

#### Core Identity Attributes

| Attribute | OID | Friendly Name | Description |
|-----------|-----|---------------|-------------|
| `eduPersonPrincipalName` | 1.3.6.1.4.1.5923.1.1.1.6 | ePPN | Scoped unique identifier (user@scope) |
| `eduPersonTargetedID` | 1.3.6.1.4.1.5923.1.1.1.10 | TID | Persistent, privacy-preserving identifier |
| `eduPersonUniqueId` | 1.3.6.1.4.1.5923.1.1.1.13 | Unique ID | Persistent unique identifier within federation |
| `mail` | 0.9.2342.19200300.100.1.3 | Email | User's email address |
| `displayName` | 2.16.840.1.113730.3.2.1 | Display Name | Full display name |
| `givenName` | 2.5.4.42 | First Name | Given/first name |
| `sn` | 2.5.4.4 | Surname | Family/last name |

#### Affiliation Attributes

| Attribute | OID | Friendly Name | Allowed Values |
|-----------|-----|---------------|----------------|
| `eduPersonAffiliation` | 1.3.6.1.4.1.5923.1.1.1.1 | Affiliation | faculty, student, staff, alum, member, affiliate, employee, library-walk-in |
| `eduPersonScopedAffiliation` | 1.3.6.1.4.1.5923.1.1.1.9 | Scoped Affiliation | affiliation@scope (e.g., <student@university.edu>) |
| `eduPersonPrimaryAffiliation` | 1.3.6.1.4.1.5923.1.1.1.5 | Primary Affiliation | Single primary affiliation value |

#### Extended Attributes

| Attribute | OID | Friendly Name | Purpose |
|-----------|-----|---------------|---------|
| `eduPersonEntitlement` | 1.3.6.1.4.1.5923.1.1.1.7 | Entitlement | URI-based resource access rights |
| `eduPersonOrgDN` | 1.3.6.1.4.1.5923.1.1.1.3 | Org DN | Distinguished name of organization |
| `eduPersonOrgUnitDN` | 1.3.6.1.4.1.5923.1.1.1.4 | Org Unit DN | Distinguished name of organizational unit |
| `eduPersonAssurance` | 1.3.6.1.4.1.5923.1.1.1.11 | Assurance | Identity assurance level URIs |

---

### Attribute Mapping Configuration

#### SAML Attribute Names

DFN-AAI and eduGAIN use the `urn:mace:dir:attribute-def` namespace for attribute names:

| Attribute | SAML Name |
|-----------|-----------|
| `mail` | `urn:mace:dir:attribute-def:mail` |
| `displayName` | `urn:mace:dir:attribute-def:displayName` |
| `givenName` | `urn:mace:dir:attribute-def:givenName` |
| `sn` | `urn:mace:dir:attribute-def:sn` |
| `eduPersonPrincipalName` | `urn:mace:dir:attribute-def:eduPersonPrincipalName` |
| `eduPersonTargetedID` | `urn:mace:dir:attribute-def:eduPersonTargetedID` |
| `eduPersonAffiliation` | `urn:mace:dir:attribute-def:eduPersonAffiliation` |
| `eduPersonScopedAffiliation` | `urn:mace:dir:attribute-def:eduPersonScopedAffiliation` |
| `eduPersonEntitlement` | `urn:mace:dir:attribute-def:eduPersonEntitlement` |

Alternative OID-based format (also supported):

| Attribute | SAML Name (OID) |
|-----------|-----------------|
| `mail` | `urn:oid:0.9.2342.19200300.100.1.3` |
| `eduPersonPrincipalName` | `urn:oid:1.3.6.1.4.1.5923.1.1.1.6` |
| `eduPersonAffiliation` | `urn:oid:1.3.6.1.4.1.5923.1.1.1.1` |

---

### Keycloak Attribute Mapper Configuration

#### Step 1: Access Identity Provider Configuration

1. Navigate to **Realm Settings** → **Identity Providers**
2. Select your SAML provider (e.g., `dfn-aai` or `dfn-aai-test`)
3. Click **Mappers** tab
4. Click **Add mapper**

#### Step 2: Create Attribute Mappers

##### Email Mapper

| Field | Value |
|-------|-------|
| Name | `email-mapper` |
| Mapper Type | `Attribute Importer` |
| Attribute Name | `urn:mace:dir:attribute-def:mail` |
| Friendly Name | (leave empty or use `mail`) |
| User Attribute | `email` |
| Email Verified | `On` (if IdP provides verified emails) |

##### Display Name Mapper

| Field | Value |
|-------|-------|
| Name | `displayname-mapper` |
| Mapper Type | `Attribute Importer` |
| Attribute Name | `urn:mace:dir:attribute-def:displayName` |
| User Attribute | `firstName` |
| First Name Attribute | `firstName` |

> **Note:** For displayName, you may need a custom script mapper to split into firstName/lastName.

##### Username Mapper (eduPersonPrincipalName)

| Field | Value |
|-------|-------|
| Name | `username-mapper` |
| Mapper Type | `Attribute Importer` |
| Attribute Name | `urn:mace:dir:attribute-def:eduPersonPrincipalName` |
| User Attribute | `username` |

> **Important:** The `@scope` suffix will be included. Consider a script mapper to normalize if needed.

##### Persistent ID Mapper (eduPersonTargetedID)

| Field | Value |
|-------|-------|
| Name | `persistent-id-mapper` |
| Mapper Type | `Attribute Importer` |
| Attribute Name | `urn:mace:dir:attribute-def:eduPersonTargetedID` |
| User Attribute | `fedid` |

##### Affiliation Mapper

| Field | Value |
|-------|-------|
| Name | `affiliation-mapper` |
| Mapper Type | `Attribute Importer` |
| Attribute Name | `urn:mace:dir:attribute-def:eduPersonAffiliation` |
| User Attribute | `affiliation` |

---

### Role Mapping Configuration

Convert `eduPersonAffiliation` values to Keycloak roles for access control.

#### Affiliation to Role Mapping

| eduPersonAffiliation | Keycloak Role | Access Level |
|---------------------|---------------|--------------|
| `faculty` | `instructor` | Full teaching access |
| `staff` | `staff` | Administrative access |
| `student` | `student` | Student access |
| `employee` | `employee` | Employee access |
| `member` | `member` | Basic member access |
| `affiliate` | `affiliate` | Limited external access |
| `alum` | `alumni` | Alumni access |
| `library-walk-in` | `library` | Library-only access |

#### Implementing Role Mapping

##### Option 1: Using Role Import Mapper

1. Add mapper of type `Role Import`
2. Configure attribute name: `urn:mace:dir:attribute-def:eduPersonAffiliation`
3. Map values using role mapping rules

##### Option 2: Using Script Mapper (Recommended for Complex Logic)

Create a JavaScript mapper for flexible role assignment:

```javascript
// Script Mapper: affiliation-to-role-mapper
// Maps eduPersonAffiliation values to Keycloak roles

var affiliations = user.getAttribute('affiliation');
if (!affiliations) {
    affiliations = [];
}

// Get all affiliation values (may be multi-valued)
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

// Grant roles to user
for each (var role in roles) {
    user.grantRole(role);
}

// Set primary role based on primary affiliation
var primaryAff = user.getSingleAttribute('primaryAffiliation');
if (primaryAff) {
    user.setSingleAttribute('primaryRole', mapPrimaryRole(primaryAff));
}

function mapPrimaryRole(affiliation) {
    switch (affiliation.toLowerCase()) {
        case 'faculty': return 'instructor';
        case 'staff': return 'staff';
        case 'student': return 'student';
        default: return 'member';
    }
}
```

---

### Institution-Specific Role Mapping

Different institutions may require custom role mappings. Configure per-institution rules:

#### Example Configuration Structure

```json
{
  "institutionRoleMappings": {
    "tu-berlin.de": {
      "faculty": ["instructor", "researcher"],
      "staff": ["staff", "admin"],
      "student": ["student", "learner"]
    },
    "fu-berlin.de": {
      "faculty": ["professor", "instructor"],
      "staff": ["mitarbeiter"],
      "student": ["studierende"]
    },
    "default": {
      "faculty": ["instructor"],
      "staff": ["staff"],
      "student": ["student"]
    }
  }
}
```

#### Script Mapper for Institution-Specific Roles

```javascript
// Script Mapper: institution-role-mapper
// Applies institution-specific role mappings based on scope

var eppn = user.getAttribute('eduPersonPrincipalName');
var affiliation = user.getAttribute('affiliation');

if (!eppn || !affiliation) {
    return;
}

// Extract institution scope from eduPersonPrincipalName
var scope = eppn[0].split('@')[1];

// Institution-specific mappings
var mappings = {
    'tu-berlin.de': {
        'faculty': ['instructor', 'researcher', 'tu-faculty'],
        'staff': ['staff', 'tu-staff'],
        'student': ['student', 'tu-student']
    },
    'fu-berlin.de': {
        'faculty': ['instructor', 'fu-faculty'],
        'staff': ['staff', 'fu-staff'],
        'student': ['student', 'fu-student']
    }
};

var institutionMapping = mappings[scope] || mappings['default'];

for each (var aff in affiliation) {
    var roles = institutionMapping[aff.toLowerCase()];
    if (roles) {
        for each (var role in roles) {
            user.grantRole(role);
        }
    }
}

// Store institution for later reference
user.setSingleAttribute('institution', scope);
```

---

### Name Parsing (displayName → firstName/lastName)

For IdPs that only provide `displayName`, use a script mapper:

```javascript
// Script Mapper: name-parser-mapper
// Parses displayName into firstName and lastName

var displayName = user.getSingleAttribute('displayName');

if (!displayName) {
    return;
}

// Common name formats:
// "Dr. Max Mustermann" -> firstName: Max, lastName: Mustermann
// "Max Mustermann" -> firstName: Max, lastName: Mustermann
// "Mustermann, Max" -> firstName: Max, lastName: Mustermann

var parts;
var firstName = '';
var lastName = '';

if (displayName.includes(',')) {
    // Format: "Last, First"
    parts = displayName.split(',');
    lastName = parts[0].trim();
    firstName = parts.length > 1 ? parts[1].trim() : '';
} else {
    // Format: "First Last" or "Title First Last"
    parts = displayName.trim().split(/\s+/);

    // Filter out common titles
    var titles = ['dr.', 'dr', 'prof.', 'prof', 'prof.', 'mag.', 'mag', ' Dipl.-Ing.', 'Dipl.-Ing.'];

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
        firstName = nameParts[0];
        lastName = nameParts.slice(1).join(' ');
    } else if (nameParts.length === 1) {
        lastName = nameParts[0];
    }
}

user.setFirstName(firstName);
user.setLastName(lastName);
```

---

### Advanced: Username Normalization

For consistent usernames from `eduPersonPrincipalName`:

```javascript
// Script Mapper: username-normalizer
// Normalizes eduPersonPrincipalName to a clean username

var eppn = user.getSingleAttribute('eduPersonPrincipalName');

if (!eppn) {
    return;
}

// Extract local part (before @)
var localPart = eppn.split('@')[0];

// Normalize: lowercase, remove special characters
var username = localPart
    .toLowerCase()
    .replace(/[^a-z0-9._-]/g, '')
    .substring(0, 64); // Limit length

user.setUsername(username);

// Store original ePPN for reference
user.setSingleAttribute('originalEPPN', eppn);
```

---

### Testing Attribute Mapping

#### Using SAML Tracer

1. Install [SAML Tracer](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/) browser extension
2. Authenticate via DFN-AAI
3. Inspect SAML assertion to verify attributes received

#### Checking Keycloak User Attributes

After first login, verify in Keycloak Admin Console:

1. Navigate to **Users** → select user
2. Check **Attributes** tab for mapped values
3. Check **Role Mappings** tab for assigned roles

#### Debug Logging

Enable debug logging in Keycloak:

```properties
# In keycloak.conf or environment
log-level=org.keycloak.broker.saml:debug
log-level=org.keycloak.authentication:debug
```

---

### Troubleshooting

#### Attributes Not Received

**Symptom:** User created but attributes are empty

**Checklist:**

- [ ] Verify attribute names match IdP metadata (mace vs OID format)
- [ ] Check `<AttributeConsumingService>` in SP metadata
- [ ] Contact IdP admin about attribute release policy
- [ ] Use SAML tracer to inspect actual assertion

#### Role Mapping Fails

**Symptom:** Attributes received but roles not assigned

**Checklist:**

- [ ] Verify roles exist in Keycloak realm
- [ ] Check script mapper syntax (JavaScript)
- [ ] Enable debug logging for broker
- [ ] Verify mapper execution order

#### Username Conflicts

**Symptom:** "User already exists" errors

**Solutions:**

1. Use `eduPersonTargetedID` or `eduPersonUniqueId` for unique identification
2. Configure `First Login Flow` to handle conflicts
3. Implement username federation ID linking

#### Duplicate Users Created

**Symptom:** Same person gets multiple accounts

**Solutions:**

1. Set `Link Only` mode for existing users
2. Configure `Principal Type` to use persistent attribute
3. Use `eduPersonTargetedID` for user linking

---

### Reference Configuration Files

- [Attribute Mapping JSON](../.sisyphus/evidence/task-3-attribute-mapping.json) - Complete mapping configuration
- [Keycloak Client JSON](../.sisyphus/evidence/task-3-keycloak-client.json) - SAML client example
- [Role Mapping Log](../.sisyphus/evidence/task-3-role-mapping.log) - Test results

---

<a name="deutsch"></a>

## Deutsch

### Übersicht

Dieses Dokument beschreibt die Konfiguration von Keycloak zur Abbildung von eduGAIN/eduPerson-Attributen aus SAML-Assertions auf Keycloak-Benutzerattribute. Die korrekte Attributzuordnung ist erforderlich für:

- **Single Sign-On (SSO)**-Integration mit DFN-AAI und eduGAIN-Föderationen
- **Rollenbasierte Zugriffskontrolle** anhand institutioneller Zugehörigkeiten
- **Benutzerbereitstellung** mit korrekten Profilinformationen
- **Einrichtungsübergreifendes Identitätsmanagement**

---

### eduPerson-Attributreferenz

Das eduPerson-Schema definiert Standardattribute, die in akademischen Identitätsföderationen weltweit verwendet werden. Im Folgenden sind die Kernattribute aufgeführt, die von DFN-AAI und eduGAIN verwendet werden:

#### Kernidentitätsattribute

| Attribut | OID | Friendly Name | Beschreibung |
|-----------|-----|---------------|-------------|
| `eduPersonPrincipalName` | 1.3.6.1.4.1.5923.1.1.1.6 | ePPN | Bereichsspezifische eindeutige Kennung (benutzer@bereich) |
| `eduPersonTargetedID` | 1.3.6.1.4.1.5923.1.1.1.10 | TID | Persistente, datenschutzfreundliche Kennung |
| `eduPersonUniqueId` | 1.3.6.1.4.1.5923.1.1.1.13 | Unique ID | Persistente eindeutige Kennung innerhalb der Föderation |
| `mail` | 0.9.2342.19200300.100.1.3 | Email | E-Mail-Adresse des Benutzers |
| `displayName` | 2.16.840.1.113730.3.2.1 | Display Name | Vollständiger Anzeigename |
| `givenName` | 2.5.4.42 | First Name | Vorname |
| `sn` | 2.5.4.4 | Surname | Nachname |

#### Zugehörigkeitsattribute

| Attribut | OID | Friendly Name | Zulässige Werte |
|-----------|-----|---------------|----------------|
| `eduPersonAffiliation` | 1.3.6.1.4.1.5923.1.1.1.1 | Affiliation | faculty, student, staff, alum, member, affiliate, employee, library-walk-in |
| `eduPersonScopedAffiliation` | 1.3.6.1.4.1.5923.1.1.1.9 | Scoped Affiliation | affiliation@bereich (z.B. <student@university.edu>) |
| `eduPersonPrimaryAffiliation` | 1.3.6.1.4.1.5923.1.1.1.5 | Primary Affiliation | Einzelner primärer Zugehörigkeitswert |

#### Erweiterte Attribute

| Attribut | OID | Friendly Name | Zweck |
|-----------|-----|---------------|---------|
| `eduPersonEntitlement` | 1.3.6.1.4.1.5923.1.1.1.7 | Entitlement | URI-basierte Ressourcenzugriffsrechte |
| `eduPersonOrgDN` | 1.3.6.1.4.1.5923.1.1.1.3 | Org DN | Distinguished Name der Organisation |
| `eduPersonOrgUnitDN` | 1.3.6.1.4.1.5923.1.1.1.4 | Org Unit DN | Distinguished Name der Organisationseinheit |
| `eduPersonAssurance` | 1.3.6.1.4.1.5923.1.1.1.11 | Assurance | Identitätssicherheitsstufen-URIs |

---

### Attributzuordnungskonfiguration

#### SAML-Attributnamen

DFN-AAI und eduGAIN verwenden den `urn:mace:dir:attribute-def`-Namespace für Attributnamen:

| Attribut | SAML-Name |
|-----------|-----------|
| `mail` | `urn:mace:dir:attribute-def:mail` |
| `displayName` | `urn:mace:dir:attribute-def:displayName` |
| `givenName` | `urn:mace:dir:attribute-def:givenName` |
| `sn` | `urn:mace:dir:attribute-def:sn` |
| `eduPersonPrincipalName` | `urn:mace:dir:attribute-def:eduPersonPrincipalName` |
| `eduPersonTargetedID` | `urn:mace:dir:attribute-def:eduPersonTargetedID` |
| `eduPersonAffiliation` | `urn:mace:dir:attribute-def:eduPersonAffiliation` |
| `eduPersonScopedAffiliation` | `urn:mace:dir:attribute-def:eduPersonScopedAffiliation` |
| `eduPersonEntitlement` | `urn:mace:dir:attribute-def:eduPersonEntitlement` |

Alternative OID-basierte Format (ebenfalls unterstützt):

| Attribut | SAML-Name (OID) |
|-----------|-----------------|
| `mail` | `urn:oid:0.9.2342.19200300.100.1.3` |
| `eduPersonPrincipalName` | `urn:oid:1.3.6.1.4.1.5923.1.1.1.6` |
| `eduPersonAffiliation` | `urn:oid:1.3.6.1.4.1.5923.1.1.1.1` |

---

### Keycloak-Attribut-Mapper-Konfiguration

#### Schritt 1: Identitätsanbieterkonfiguration aufrufen

1. Navigieren Sie zu **Realm-Einstellungen** → **Identitätsanbieter**
2. Wählen Sie Ihren SAML-Anbieter (z.B. `dfn-aai` oder `dfn-aai-test`)
3. Klicken Sie auf den Reiter **Mapper**
4. Klicken Sie auf **Mapper hinzufügen**

#### Schritt 2: Attribut-Mapper erstellen

##### E-Mail-Mapper

| Feld | Wert |
|-------|-------|
| Name | `email-mapper` |
| Mapper-Typ | `Attribute Importer` |
| Attributname | `urn:mace:dir:attribute-def:mail` |
| Friendly Name | (leer lassen oder `mail` verwenden) |
| Benutzerattribut | `email` |
| E-Mail verifiziert | `Ein` (falls IdP verifizierte E-Mails bereitstellt) |

##### Anzeigename-Mapper

| Feld | Wert |
|-------|-------|
| Name | `displayname-mapper` |
| Mapper-Typ | `Attribute Importer` |
| Attributname | `urn:mace:dir:attribute-def:displayName` |
| Benutzerattribut | `firstName` |

> **Hinweis:** Für displayName benötigen Sie möglicherweise einen benutzerdefinierten Script-Mapper, um in firstName/lastName aufzuteilen.

##### Benutzername-Mapper (eduPersonPrincipalName)

| Feld | Wert |
|-------|-------|
| Name | `username-mapper` |
| Mapper-Typ | `Attribute Importer` |
| Attributname | `urn:mace:dir:attribute-def:eduPersonPrincipalName` |
| Benutzerattribut | `username` |

> **Wichtig:** Das `@bereich`-Suffix wird enthalten sein. Erwägen Sie einen Script-Mapper zur Normalisierung bei Bedarf.

##### Persistente ID-Mapper (eduPersonTargetedID)

| Feld | Wert |
|-------|-------|
| Name | `persistent-id-mapper` |
| Mapper-Typ | `Attribute Importer` |
| Attributname | `urn:mace:dir:attribute-def:eduPersonTargetedID` |
| Benutzerattribut | `fedid` |

##### Zugehörigkeits-Mapper

| Feld | Wert |
|-------|-------|
| Name | `affiliation-mapper` |
| Mapper-Typ | `Attribute Importer` |
| Attributname | `urn:mace:dir:attribute-def:eduPersonAffiliation` |
| Benutzerattribut | `affiliation` |

---

### Rollenzuordnungskonfiguration

Konvertieren Sie `eduPersonAffiliation`-Werte in Keycloak-Rollen für Zugriffskontrolle.

#### Zugehörigkeit-zu-Rolle-Mapping

| eduPersonAffiliation | Keycloak-Rolle | Zugriffsebene |
|---------------------|---------------|--------------|
| `faculty` | `instructor` | Voller Lehrzugriff |
| `staff` | `staff` | Verwaltungszugriff |
| `student` | `student` | Studentenzugriff |
| `employee` | `employee` | Mitarbeiterzugriff |
| `member` | `member` | Basis-Mitgliedszugriff |
| `affiliate` | `affiliate` | Eingeschränkter externer Zugriff |
| `alum` | `alumni` | Alumni-Zugriff |
| `library-walk-in` | `library` | Nur Bibliothekszugriff |

---

### Testen der Attributzuordnung

#### Mit SAML Tracer

1. Installieren Sie die [SAML Tracer](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/) Browser-Erweiterung
2. Authentifizieren Sie sich über DFN-AAI
3. Inspizieren Sie die SAML-Assertion, um empfangene Attribute zu verifizieren

#### Keycloak-Benutzerattribute prüfen

Nach der ersten Anmeldung in der Keycloak-Admin-Konsole prüfen:

1. Navigieren Sie zu **Benutzer** → Benutzer auswählen
2. Prüfen Sie den Reiter **Attribute** auf zugeordnete Werte
3. Prüfen Sie den Reiter **Rollen-Mappings** auf zugewiesene Rollen

---

### Fehlerbehebung

#### Attribute nicht empfangen

**Symptom:** Benutzer erstellt, aber Attribute sind leer

**Checkliste:**

- [ ] Prüfen, dass Attributnamen mit IdP-Metadaten übereinstimmen (mace vs OID-Format)
- [ ] `<AttributeConsumingService>` in SP-Metadaten prüfen
- [ ] IdP-Admin bezüglich Attributfreigaberichtlinie kontaktieren
- [ ] SAML-Tracer zur Inspektion der tatsächlichen Assertion verwenden

#### Rollenzuordnung fehlgeschlagen

**Symptom:** Attribute empfangen, aber Rollen nicht zugewiesen

**Checkliste:**

- [ ] Prüfen, dass Rollen im Keycloak-Realm existieren
- [ ] Script-Mapper-Syntax prüfen (JavaScript)
- [ ] Debug-Logging für Broker aktivieren
- [ ] Mapper-Ausführungsreihenfolge verifizieren

#### Benutzername-Konflikte

**Symptom:** "Benutzer existiert bereits"-Fehler

**Lösungen:**

1. `eduPersonTargetedID` oder `eduPersonUniqueId` zur eindeutigen Identifikation verwenden
2. `First Login Flow` zur Konfliktbehandlung konfigurieren
3. Benutzernamen-Föderations-ID-Verknüpfung implementieren

---

### Referenzkonfigurationsdateien

- [Attributzuordnungs-JSON](../.sisyphus/evidence/task-3-attribute-mapping.json) - Vollständige Zuordnungskonfiguration
- [Keycloak-Client-JSON](../.sisyphus/evidence/task-3-keycloak-client.json) - SAML-Client-Beispiel
- [Rollen-Mapping-Log](../.sisyphus/evidence/task-3-role-mapping.log) - Testergebnisse

---

**Verwandte Dokumentation:**

- [DFN-AAI Service Provider Registration Guide](./dfn-aai-registration.md)
- [Federation Testing Guide](./federation/testing-guide.md)
- [IdP Federation Configuration](./enhanced-configuration/idp-federation.md)

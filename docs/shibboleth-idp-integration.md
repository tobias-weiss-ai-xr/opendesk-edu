<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Shibboleth IdP Integration for Keycloak / Shibboleth-IdP-Integration für Keycloak

[English](#english) | [Deutsch](#deutsch)

---

<a name="english"></a>

## English

### Overview

This document describes how to configure Keycloak to act as a SAML Service Provider (SP) for external Shibboleth Identity Providers (IdPs). This integration enables:

- **Multi-IdP support** for multiple universities and institutions
- **Just-in-time (JIT) provisioning** of user accounts
- **Attribute consumption** from external IdPs
- **Fallback to local authentication** when external IdPs are unavailable

---

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           openDesk Edu Platform                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      Keycloak (SAML SP)                          │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │   │
│  │  │   IdP: TUM   │  │  IdP: LMU    │  │ IdP: FU Berlin│  ...      │   │
│  │  │   (Shib)     │  │  (Shib)      │  │  (Shib)      │           │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘           │   │
│  │           │                │                 │                   │   │
│  │           └────────────────┴─────────────────┘                   │   │
│  │                            │                                     │   │
│  │                    Federation Discovery                          │   │
│  │                    (DFN-AAI / eduGAIN)                           │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                              │                                          │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                        Services                                    │ │
│  │   ILIAS  │  Moodle  │  BigBlueButton  │  Nextcloud  │  ...       │ │
│  └───────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

---

### Prerequisites

| Requirement | Description |
|-------------|-------------|
| Keycloak 22+ | With SAML 2.0 identity broker support |
| IdP Metadata | Shibboleth IdP metadata XML from each institution |
| Network Access | HTTPS connectivity to IdP endpoints |
| Federation Membership | DFN-AAI test or production federation registration |
| Attribute Policy | Agreed attribute release with each IdP |

---

### Step 1: Obtain Shibboleth IdP Metadata

Each Shibboleth IdP provides metadata at a well-known URL:

```
https://idp.example.edu/idp/shibboleth
```

#### DFN-AAI Federation Metadata

For DFN-AAI federation members, use the aggregated metadata:

| Environment | Metadata URL |
|-------------|--------------|
| Test Federation | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml` |
| Production Federation | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Basic-metadata.xml` |
| eduGAIN | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-edugain-metadata.xml` |

#### Individual Institution Metadata Examples

| Institution | Metadata URL |
|-------------|--------------|
| TU Berlin | `https://sso.tu-berlin.de/idp/shibboleth` |
| FU Berlin | `https://identity.fu-berlin.de/idp/shibboleth` |
| LMU München | `https://sso.lmu.de/idp/shibboleth` |
| Universität Hamburg | `https://idp.uni-hamburg.de/idp/shibboleth` |

---

### Step 2: Configure Keycloak as SAML Service Provider

#### 2.1 Add Identity Provider via Admin Console

1. Navigate to **Realm Settings** → **Identity Providers**
2. Click **Add provider** → Select **SAML v2.0**
3. Configure the following settings:

##### Basic Configuration

| Field | Value | Description |
|-------|-------|-------------|
| Alias | `shib-<institution>` | Unique identifier (e.g., `shib-tum`, `shib-lmu`) |
| Display Name | Institution Name | User-facing name in login UI |
| Enabled | ON | Enable the provider |
| Store Token | OFF | Don't store SAML tokens |
| Stored Tokens Readable | OFF | Security best practice |
| Trust Email | ON | Trust email from IdP |
| Link Only | OFF | Allow new user creation |
| First Login Flow | `first broker login` | JIT provisioning flow |

##### SAML Configuration

| Field | Value | Description |
|-------|-------|-------------|
| Entity ID | (from IdP metadata) | IdP's SAML entity ID |
| Single Sign-On Service URL | (from IdP metadata) | SSO endpoint |
| Single Logout Service URL | (from IdP metadata) | SLO endpoint (optional) |
| Name ID Policy Format | `urn:oasis:names:tc:SAML:2.0:nameid-format:persistent` | Persistent identifier |
| Principal Type | `Attribute` | Use attribute for user identification |
| Principal Attribute | `urn:mace:dir:attribute-def:eduPersonTargetedID` | Persistent user ID |

#### 2.2 Import Metadata from URL

Keycloak can automatically import IdP configuration:

1. In **Add provider** dialog, click **Import from URL**
2. Enter the IdP metadata URL
3. Keycloak will populate all configuration fields automatically

#### 2.3 Using the Admin CLI (Alternative)

```bash
# Create SAML identity provider for TU Berlin
kcadm.sh create identity-provider/instances -r opendesk \
  -s alias=shib-tum \
  -s providerId=saml \
  -s enabled=true \
  -s trustEmail=true \
  -s firstBrokerLoginFlowAlias="first broker login" \
  -s 'config.entityId=https://sso.tu-berlin.de/idp/shibboleth' \
  -s 'config.singleSignOnServiceUrl=https://sso.tu-berlin.de/idp/profile/SAML2/Redirect/SSO' \
  -s 'config.singleLogoutServiceUrl=https://sso.tu-berlin.de/idp/profile/SAML2/Redirect/SLO' \
  -s 'config.nameIDPolicyFormat=urn:oasis:names:tc:SAML:2.0:nameid-format:persistent' \
  -s 'config.principalType=ATTRIBUTE' \
  -s 'config.principalAttribute=urn:mace:dir:attribute-def:eduPersonTargetedID' \
  -s 'config.signatureAlgorithm=RSA_SHA256' \
  -s 'config.wantAuthnRequestsSigned=true' \
  -s 'config.validateSignature=true'
```

---

### Step 3: Configure Attribute Mappers

Attribute mappers transform incoming SAML attributes to Keycloak user attributes.

#### Required Attribute Mappers

##### Email Mapper

| Field | Value |
|-------|-------|
| Name | `email-mapper` |
| Mapper Type | `Attribute Importer` |
| Attribute Name | `urn:mace:dir:attribute-def:mail` |
| User Attribute | `email` |

##### Username Mapper

| Field | Value |
|-------|-------|
| Name | `username-mapper` |
| Mapper Type | `Attribute Importer` |
| Attribute Name | `urn:mace:dir:attribute-def:eduPersonPrincipalName` |
| User Attribute | `username` |

##### Display Name Mapper

| Field | Value |
|-------|-------|
| Name | `displayname-mapper` |
| Mapper Type | `Attribute Importer` |
| Attribute Name | `urn:mace:dir:attribute-def:displayName` |
| User Attribute | `firstName` |

##### Affiliation Mapper

| Field | Value |
|-------|-------|
| Name | `affiliation-mapper` |
| Mapper Type | `Attribute Importer` |
| Attribute Name | `urn:mace:dir:attribute-def:eduPersonAffiliation` |
| User Attribute | `affiliation` |

#### Using the Admin CLI

```bash
# Add email mapper
kcadm.sh create identity-provider/instances/shib-tum/mappers \
  -r opendesk \
  -s name=email-mapper \
  -s identityProviderMapper=saml-user-attribute-idp-mapper \
  -s identityProviderAlias=shib-tum \
  -s 'config.syncMode=INHERIT' \
  -s 'config.attribute=urn:mace:dir:attribute-def:mail' \
  -s 'config.user.attribute=email'

# Add affiliation mapper
kcadm.sh create identity-provider/instances/shib-tum/mappers \
  -r opendesk \
  -s name=affiliation-mapper \
  -s identityProviderMapper=saml-user-attribute-idp-mapper \
  -s identityProviderAlias=shib-tum \
  -s 'config.syncMode=INHERIT' \
  -s 'config.attribute=urn:mace:dir:attribute-def:eduPersonAffiliation' \
  -s 'config.user.attribute=affiliation'
```

---

### Step 4: Just-in-Time (JIT) Provisioning

JIT provisioning automatically creates user accounts on first login.

#### 4.1 Configure First Broker Login Flow

The `first broker login` flow handles JIT provisioning:

1. Navigate to **Authentication** → **Flows**
2. Select **First Broker Login** flow
3. Review the default configuration:

| Execution | Requirement | Purpose |
|-----------|-------------|---------|
| Review Profile | ALTERNATIVE | User can edit profile data |
| Create User If Unique | ALTERNATIVE | Create new user if no conflict |
| Handle Existing Account | REQUIRED | Link existing account if found |

#### 4.2 Automatic Role Assignment (Script Mapper)

Create a script mapper to automatically assign roles based on affiliation:

```javascript
// Script Mapper: affiliation-role-mapper
// Maps eduPersonAffiliation to Keycloak roles

var affiliation = user.getAttribute('affiliation');
if (!affiliation) {
    affiliation = [];
}

// Parse display name into first/last name if not provided separately
var displayName = user.getSingleAttribute('displayName');
if (displayName && !user.getFirstName()) {
    var parts = displayName.split(' ');
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
            rolesToGrant.push('instructor');
            break;
        case 'staff':
            rolesToGrant.push('staff');
            break;
        case 'student':
            rolesToGrant.push('student');
            break;
        case 'employee':
            rolesToGrant.push('employee');
            break;
        case 'member':
            rolesToGrant.push('member');
            break;
    }
}

// Grant realm roles
for each (var role in rolesToGrant) {
    user.grantRole(role);
}
```

---

### Step 5: Multi-IdP Configuration

Configure multiple Shibboleth IdPs for different universities.

#### 5.1 Federation Discovery Service

Enable the discovery service to let users select their institution:

1. Navigate to **Realm Settings** → **Themes**
2. Configure login theme with IdP discovery
3. Or use DFN-AAI discovery service: `https://discovery.aai.dfn.de/`

#### 5.2 Per-Institution Configuration

Create separate IdP configurations for each institution:

| Alias | Institution | Entity ID |
|-------|-------------|-----------|
| `shib-tum` | TU München | `https://sso.tum.de/idp/shibboleth` |
| `shib-lmu` | LMU München | `https://sso.lmu.de/idp/shibboleth` |
| `shib-fu-berlin` | FU Berlin | `https://identity.fu-berlin.de/idp/shibboleth` |
| `shib-tu-berlin` | TU Berlin | `https://sso.tu-berlin.de/idp/shibboleth` |
| `shib-uni-hamburg` | Universität Hamburg | `https://idp.uni-hamburg.de/idp/shibboleth` |

#### 5.3 Institution-Specific Role Mapping

Different institutions may have custom role requirements:

```javascript
// Script Mapper: institution-role-mapper
// Institution-specific role mapping

var scope = user.getSingleAttribute('institution');
var affiliation = user.getAttribute('affiliation');

// Institution-specific role mappings
var mappings = {
    'tum.de': {
        'faculty': ['instructor', 'tum-faculty'],
        'staff': ['staff', 'tum-staff'],
        'student': ['student', 'tum-student']
    },
    'lmu.de': {
        'faculty': ['instructor', 'lmu-dozent'],
        'staff': ['staff', 'lmu-mitarbeiter'],
        'student': ['student', 'lmu-studierende']
    },
    'fu-berlin.de': {
        'faculty': ['instructor', 'fu-prof'],
        'staff': ['staff', 'fu-ma'],
        'student': ['student', 'fu-stud']
    }
};

var institutionMapping = mappings[scope];
if (institutionMapping) {
    for each (var aff in affiliation) {
        var roles = institutionMapping[aff.toLowerCase()];
        if (roles) {
            for each (var role in roles) {
                user.grantRole(role);
            }
        }
    }
}
```

---

### Step 6: Fallback to Local Authentication

Maintain local authentication as a fallback option.

#### 6.1 Configure Local Authentication

1. Ensure **Username/Password** authentication is enabled
2. Create a dedicated admin user for emergencies
3. Configure password policies for local accounts

#### 6.2 Login Flow with Fallback

Users can choose between federated and local authentication:

1. User accesses login page
2. Login page displays:
   - **"Sign in with your institution"** (federated options)
   - **"Sign in with local account"** (fallback)
3. If external IdPs are unavailable, local authentication remains functional

#### 6.3 Emergency Access Configuration

```bash
# Create emergency admin user
kcadm.sh create users -r opendesk \
  -s username=emergency-admin \
  -s enabled=true \
  -s email=emergency@opendesk.edu

# Set password
kcadm.sh set-password -r opendesk \
  --username emergency-admin \
  --new-password <secure-password>

# Grant admin role
kcadm.sh add-roles -r opendesk \
  --uusername emergency-admin \
  --rolename admin
```

---

### Sample IdP Metadata XML

See [task-4-idp-config.xml](../.sisyphus/evidence/task-4-idp-config.xml) for sample Shibboleth IdP metadata.

---

### Testing

#### Test with DFN-AAI Test Federation

1. Configure Keycloak to use DFN-AAI test federation
2. Use test credentials from `test.aai.dfn.de`
3. Verify attribute reception with SAML Tracer

#### Test Users

| User | Affiliation | Purpose |
|------|-------------|---------|
| `testuser1` | student | Test student role mapping |
| `testuser2` | staff | Test staff role mapping |
| `testuser3` | faculty | Test instructor role mapping |

#### Verification Commands

```bash
# List configured identity providers
kcadm.sh get identity-provider/instances -r opendesk

# Test SAML metadata export
curl -s https://idp.example.edu/realms/opendesk/broker/<alias>/endpoint/descriptor

# View user attributes after login
kcadm.sh get users/<user-id> -r opendesk
```

---

### Troubleshooting

#### IdP Metadata Import Fails

**Symptom:** Error importing metadata from URL

**Solutions:**

1. Verify network connectivity to IdP
2. Check certificate validity (use `--insecure` for test)
3. Download metadata file and import manually
4. Validate XML with `xmllint`

#### Attributes Not Received

**Symptom:** User created but attributes empty

**Solutions:**

1. Contact IdP admin about attribute release policy
2. Verify attribute names match IdP configuration
3. Use SAML Tracer to inspect actual assertion
4. Check `<AttributeConsumingService>` in SP metadata

#### User Not Created (JIT Fails)

**Symptom:** Authentication succeeds but no user created

**Solutions:**

1. Check `First Login Flow` configuration
2. Verify mappers are configured correctly
3. Enable debug logging: `org.keycloak.broker.saml:debug`
4. Check for existing user conflicts

#### Signature Validation Errors

**Symptom:** "Invalid signature" errors

**Solutions:**

1. Import IdP signing certificate correctly
2. Verify signature algorithm matches (RSA_SHA256)
3. Check time synchronization (NTP)
4. Validate certificate chain

---

### Related Documentation

- [eduGAIN Attribute Mapping](./keycloak-edugain-attributes.md)
- [DFN-AAI Registration Guide](./dfn-aai-registration.md)
- [Federation Testing Guide](./federation/testing-guide.md)

---

<a name="deutsch"></a>

## Deutsch

### Übersicht

Dieses Dokument beschreibt die Konfiguration von Keycloak als SAML Service Provider (SP) für externe Shibboleth-Identity-Provider (IdPs). Diese Integration ermöglicht:

- **Multi-IdP-Unterstützung** für mehrere Universitäten und Einrichtungen
- **Just-in-Time (JIT)-Bereitstellung** von Benutzerkonten
- **Attributübernahme** von externen IdPs
- **Fallback auf lokale Authentifizierung** wenn externe IdPs nicht verfügbar sind

---

### Voraussetzungen

| Anforderung | Beschreibung |
|-------------|--------------|
| Keycloak 22+ | Mit SAML 2.0 Identity-Broker-Unterstützung |
| IdP-Metadaten | Shibboleth-IdP-Metadaten-XML von jeder Einrichtung |
| Netzwerkzugriff | HTTPS-Konnektivität zu IdP-Endpunkten |
| Föderationsmitgliedschaft | DFN-AAI-Test- oder Produktivföderations-Registrierung |
| Attributrichtlinie | Vereinbarte Attributfreigabe mit jedem IdP |

---

### Schritt 1: Shibboleth-IdP-Metadaten abrufen

Jeder Shibboleth-IdP stellt Metadaten unter einer bekannten URL bereit:

```
https://idp.beispiel-universitaet.de/idp/shibboleth
```

#### DFN-AAI-Föderationsmetadaten

Für DFN-AAI-Föderationsmitglieder verwenden Sie die aggregierten Metadaten:

| Umgebung | Metadaten-URL |
|----------|---------------|
| Testföderation | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml` |
| Produktivföderation | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Basic-metadata.xml` |
| eduGAIN | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-edugain-metadata.xml` |

---

### Schritt 2: Keycloak als SAML-Service-Provider konfigurieren

#### 2.1 Identitätsanbieter über Admin-Konsole hinzufügen

1. Navigieren Sie zu **Realm-Einstellungen** → **Identitätsanbieter**
2. Klicken Sie auf **Anbieter hinzufügen** → Wählen Sie **SAML v2.0**
3. Konfigurieren Sie die folgenden Einstellungen:

##### Grundkonfiguration

| Feld | Wert | Beschreibung |
|------|------|--------------|
| Alias | `shib-<einrichtung>` | Eindeutige Kennung (z.B. `shib-tum`, `shib-lmu`) |
| Anzeigename | Institutionsname | Benutzerfreundlicher Name in der Anmelde-UI |
| Aktiviert | AN | Provider aktivieren |
| E-Mail vertrauen | AN | E-Mail vom IdP vertrauen |
| Erster-Broker-Login-Flow | `first broker login` | JIT-Bereitstellungsflow |

##### SAML-Konfiguration

| Feld | Wert | Beschreibung |
|------|------|--------------|
| Entity ID | (aus IdP-Metadaten) | SAML-Entity-ID des IdP |
| Single Sign-On Service URL | (aus IdP-Metadaten) | SSO-Endpunkt |
| Name ID Policy Format | `urn:oasis:names:tc:SAML:2.0:nameid-format:persistent` | Persistente Kennung |
| Principal Type | `Attribute` | Attribut zur Benutzeridentifikation |
| Principal Attribute | `urn:mace:dir:attribute-def:eduPersonTargetedID` | Persistente Benutzer-ID |

---

### Schritt 3: Attribut-Mapper konfigurieren

Attribut-Mapper transformieren eingehende SAML-Attribute in Keycloak-Benutzerattribute.

#### Erforderliche Attribut-Mapper

##### E-Mail-Mapper

| Feld | Wert |
|------|------|
| Name | `email-mapper` |
| Mapper-Typ | `Attribute Importer` |
| Attributname | `urn:mace:dir:attribute-def:mail` |
| Benutzerattribut | `email` |

##### Benutzername-Mapper

| Feld | Wert |
|------|------|
| Name | `username-mapper` |
| Mapper-Typ | `Attribute Importer` |
| Attributname | `urn:mace:dir:attribute-def:eduPersonPrincipalName` |
| Benutzerattribut | `username` |

##### Zugehörigkeits-Mapper

| Feld | Wert |
|------|------|
| Name | `affiliation-mapper` |
| Mapper-Typ | `Attribute Importer` |
| Attributname | `urn:mace:dir:attribute-def:eduPersonAffiliation` |
| Benutzerattribut | `affiliation` |

---

### Schritt 4: Just-in-Time (JIT)-Bereitstellung

Die JIT-Bereitstellung erstellt automatisch Benutzerkonten bei der ersten Anmeldung.

#### 4.1 First-Broker-Login-Flow konfigurieren

Der `first broker login`-Flow behandelt die JIT-Bereitstellung:

1. Navigieren Sie zu **Authentifizierung** → **Flows**
2. Wählen Sie **First Broker Login**-Flow
3. Überprüfen Sie die Standardkonfiguration:

| Ausführung | Anforderung | Zweck |
|------------|-------------|-------|
| Profil überprüfen | ALTERNATIVE | Benutzer kann Profildaten bearbeiten |
| Benutzer erstellen wenn eindeutig | ALTERNATIVE | Neuen Benutzer erstellen wenn kein Konflikt |
| Vorhandenes Konto verarbeiten | ERFORDERLICH | Vorhandenes Konto verknüpfen wenn gefunden |

---

### Schritt 5: Multi-IdP-Konfiguration

Konfigurieren Sie mehrere Shibboleth-IdPs für verschiedene Universitäten.

#### 5.1 Föderations-Discovery-Service

Aktivieren Sie den Discovery-Service, damit Benutzer ihre Einrichtung auswählen können:

1. Navigieren Sie zu **Realm-Einstellungen** → **Themes**
2. Konfigurieren Sie das Login-Theme mit IdP-Discovery
3. Oder verwenden Sie den DFN-AAI-Discovery-Service: `https://discovery.aai.dfn.de/`

#### 5.2 Pro-Einrichtung-Konfiguration

Erstellen Sie separate IdP-Konfigurationen für jede Einrichtung:

| Alias | Einrichtung | Entity ID |
|-------|-------------|-----------|
| `shib-tum` | TU München | `https://sso.tum.de/idp/shibboleth` |
| `shib-lmu` | LMU München | `https://sso.lmu.de/idp/shibboleth` |
| `shib-fu-berlin` | FU Berlin | `https://identity.fu-berlin.de/idp/shibboleth` |
| `shib-tu-berlin` | TU Berlin | `https://sso.tu-berlin.de/idp/shibboleth` |

---

### Schritt 6: Fallback auf lokale Authentifizierung

Behalten Sie die lokale Authentifizierung als Fallback-Option bei.

#### 6.1 Lokale Authentifizierung konfigurieren

1. Stellen Sie sicher, dass **Benutzername/Passwort**-Authentifizierung aktiviert ist
2. Erstellen Sie einen dedizierten Admin-Benutzer für Notfälle
3. Konfigurieren Sie Passwortrichtlinien für lokale Konten

#### 6.2 Anmeldeflow mit Fallback

Benutzer können zwischen föderierter und lokaler Authentifizierung wählen:

1. Benutzer öffnet Anmeldeseite
2. Anmeldeseite zeigt:
   - **"Mit Ihrer Einrichtung anmelden"** (föderierte Optionen)
   - **"Mit lokalem Konto anmelden"** (Fallback)
3. Wenn externe IdPs nicht verfügbar sind, bleibt lokale Authentifizierung funktional

---

### Beispiel-IdP-Metadaten-XML

Siehe [task-4-idp-config.xml](../.sisyphus/evidence/task-4-idp-config.xml) für Beispiel-Shibboleth-IdP-Metadaten.

---

### Testen

#### Mit DFN-AAI-Testföderation testen

1. Konfigurieren Sie Keycloak für die DFN-AAI-Testföderation
2. Verwenden Sie Test-Zugangsdaten von `test.aai.dfn.de`
3. Überprüfen Sie den Attributempfang mit SAML Tracer

#### Testbenutzer

| Benutzer | Zugehörigkeit | Zweck |
|----------|---------------|-------|
| `testuser1` | student | Test Student-Rollenmapping |
| `testuser2` | staff | Test Staff-Rollenmapping |
| `testuser3` | faculty | Test Dozent-Rollenmapping |

---

### Fehlerbehebung

#### IdP-Metadaten-Import schlägt fehl

**Symptom:** Fehler beim Importieren von Metadaten von URL

**Lösungen:**

1. Netzwerkkonnektivität zum IdP überprüfen
2. Zertifikatsgültigkeit prüfen (`--insecure` für Test verwenden)
3. Metadaten-Datei herunterladen und manuell importieren
4. XML mit `xmllint` validieren

#### Attribute nicht empfangen

**Symptom:** Benutzer erstellt, aber Attribute leer

**Lösungen:**

1. IdP-Admin bezüglich Attributfreigaberichtlinie kontaktieren
2. Prüfen, dass Attributnamen mit IdP-Konfiguration übereinstimmen
3. SAML Tracer verwenden, um tatsächliche Assertion zu inspizieren
4. `<AttributeConsumingService>` in SP-Metadaten prüfen

#### Benutzer nicht erstellt (JIT schlägt fehl)

**Symptom:** Authentifizierung erfolgreich, aber kein Benutzer erstellt

**Lösungen:**

1. `First Login Flow`-Konfiguration prüfen
2. Überprüfen, dass Mapper korrekt konfiguriert sind
3. Debug-Logging aktivieren: `org.keycloak.broker.saml:debug`
4. Auf bestehende Benutzerkonflikte prüfen

---

### Verwandte Dokumentation

- [eduGAIN-Attribut-Mapping](./keycloak-edugain-attributes.md)
- [DFN-AAI-Registrierungsleitfaden](./dfn-aai-registration.md)
- [Föderationstestleitfaden](./federation/testing-guide.md)

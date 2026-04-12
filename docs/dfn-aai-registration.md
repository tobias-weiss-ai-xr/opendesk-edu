<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# DFN-AAI Service Provider Registration Guide / DFN-AAI Service Provider Registrierungshandbuch

[English](#english) | [Deutsch](#deutsch)

---

<a name="english"></a>

## English

### What is DFN-AAI?

[DFN-AAI](https://www.aai.dfn.de/) (Deutsches Forschungsnetz - Authentication and Authorization Infrastructure) is the German academic identity federation that enables single sign-on (SSO) for research and education institutions across Germany and internationally through eduGAIN.

#### Why DFN-AAI Matters for German Universities

- **200+ German universities** already participate in DFN-AAI
- **Single sign-on** for students, faculty, and staff using institutional credentials
- **eduGAIN integration** enables access from 70+ national federations worldwide
- **No local account management** needed for external collaborators
- **Standardized attributes** (eduPerson schema) for role-based access control
- **Compliance** with German higher education IT standards

By registering openDesk Edu as a Service Provider (SP) in DFN-AAI, users from any participating institution can authenticate using their existing university credentials.

---

### Prerequisites for Registration

Before starting the registration process, ensure you have the following:

#### Administrative Requirements

| Requirement | Description |
|-------------|-------------|
| DFN-AAI Account | Contact your institution's IT department or DFN-AAI support at [support@aai.dfn.de](mailto:support@aai.dfn.de) |
| Institutional Authorization | Your institution must be a DFN-AAI participant or have a subscription |
| Technical Contact | Email address for federation administrators |
| Administrative Contact | Email address for organizational matters |

#### Technical Requirements

| Requirement | Description |
|-------------|-------------|
| Deployed openDesk Edu | Working installation with Keycloak |
| Public DNS | Your domain must be publicly resolvable |
| TLS Certificates | Valid HTTPS certificates for all endpoints |
| SAML Metadata | Generated metadata for your Service Provider |

#### Network Requirements

- All SAML endpoints accessible via HTTPS (port 443)
- Outbound HTTPS access to DFN-AAI services
- Firewall rules allowing traffic to/from DFN-AAI endpoints

---

### Required Information for Registration

Prepare the following information before starting the registration:

#### Service Provider Information

| Field | Example Value | Your Value |
|-------|---------------|------------|
| Entity ID | `https://idp.education.example.org/realms/opendesk` | |
| Service Name | `openDesk Edu - Example University` | |
| Service Description | `Digital workplace platform for education` | |
| Service URL | `https://portal.education.example.org` | |

#### Organization Information

| Field | Example Value | Your Value |
|-------|---------------|------------|
| Organization Name | `Example University` | |
| Organization Display Name | `Example University Education Platform` | |
| Organization URL | `https://www.example-university.edu` | |
| Technical Contact Email | `edu-tech@example-university.edu` | |
| Administrative Contact Email | `edu-admin@example-university.edu` | |

#### Technical Endpoints

| Endpoint | URL Pattern |
|----------|-------------|
| Assertion Consumer Service (POST) | `https://idp.<domain>/realms/opendesk/protocol/saml` |
| Single Logout Service | `https://idp.<domain>/realms/opendesk/protocol/saml` |
| Metadata Descriptor | `https://idp.<domain>/realms/opendesk/protocol/saml/descriptor` |

#### Required Attributes

DFN-AAI requires you to specify which attributes your service needs:

| Attribute | SAML Name | Purpose |
|-----------|-----------|---------|
| `mail` | `urn:mace:dir:attribute-def:mail` | User email address |
| `displayName` | `urn:mace:dir:attribute-def:displayName` | User display name |
| `eduPersonAffiliation` | `urn:mace:dir:attribute-def:eduPersonAffiliation` | User role (student/faculty/staff) |
| `eduPersonPrincipalName` | `urn:mace:dir:attribute-def:eduPersonPrincipalName` | Persistent unique identifier |

---

### Step-by-Step Registration Process

#### Step 1: Generate SAML Metadata

Generate your Service Provider metadata using the provided script:

```bash
cd /opt/git/opendesk-edu

# For test federation (self-signed certificate)
./scripts/federation/generate-metadata.sh \
    -d education.example.org \
    -e "https://idp.education.example.org/realms/opendesk" \
    --generate-cert \
    --org-name "Example University" \
    --org-display "Example University Education Platform" \
    --tech-email edu-support@example.org \
    -o /tmp/dfn-aai-metadata.xml
```

For production federation, use CA-signed certificates:

```bash
./scripts/federation/generate-metadata.sh \
    -d education.example.org \
    -e "https://idp.education.example.org/realms/opendesk" \
    -c /etc/pki/tls/certs/keycloak-sp.crt \
    -k /etc/pki/tls/private/keycloak-sp.key \
    --org-name "Example University" \
    --org-display "Example University Education Platform" \
    --tech-email edu-support@example.org \
    -o /tmp/dfn-aai-metadata.xml
```

#### Step 2: Validate Metadata

Before submission, validate your metadata:

```bash
# Check XML syntax
xmllint --noout /tmp/dfn-aai-metadata.xml && echo "✓ XML is valid"

# Verify certificate
openssl x509 -in sp-cert.pem -noout -dates

# Review metadata contents
cat /tmp/dfn-aai-metadata.xml
```

Verify in the output:

- `entityID` matches your intended identifier
- Organization information is correct
- All endpoints use HTTPS
- Certificate is properly embedded
- Required attributes are listed

#### Step 3: Submit Registration Request

1. **Access DFN-AAI Portal**
   - Navigate to: <https://www.aai.dfn.de/en/service/metadata/>
   - Log in with your DFN-AAI account

2. **Complete Registration Form**
   - **Service Information Tab**
     - Enter Entity ID (from metadata)
     - Provide service name and description
     - Specify service URL

   - **Metadata Upload Tab**
     - Upload the generated `dfn-aai-metadata.xml` file
     - Select target federation: **Test** or **Production**

   - **Attribute Requirements Tab**
     - Confirm required attributes:
       - ☑ `mail`
       - ☑ `displayName`
       - ☑ `eduPersonAffiliation`
       - ☑ `eduPersonPrincipalName`

   - **Contact Information Tab**
     - Technical contact email
     - Administrative contact email
     - Support URL (optional)

3. **Submit for Approval**
   - Review all information
   - Click **Submit Registration**
   - Note your registration reference number

#### Step 4: Await Approval

DFN-AAI will validate your submission:

- Metadata format validation
- Endpoint accessibility check
- Certificate validity verification
- Organizational verification

**Timeline:**

- Test federation: 1-2 business days
- Production federation: 3-5 business days

You will receive an email notification upon approval or if corrections are needed.

#### Step 5: Configure Keycloak

After approval, configure Keycloak to use DFN-AAI:

1. **Access Keycloak Admin Console**

   ```
   https://idp.education.example.org/admin/master/console/
   ```

2. **Add DFN-AAI as Identity Provider**
   - Navigate to **Realm Settings** > **Identity Providers**
   - Click **Add provider** > **SAML v2.0**

3. **Configure IdP Settings**

   | Field | Test Federation | Production Federation |
   |-------|-----------------|----------------------|
   | Alias | `dfn-aai-test` | `dfn-aai` |
   | Display Name | `DFN-AAI (Test)` | `DFN-AAI` |
   | Metadata URL | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml` | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Basic-metadata.xml` |

4. **Configure Attribute Mappers**

   Create mappers for each required attribute:

   | SAML Attribute | Keycloak Attribute |
   |----------------|-------------------|
   | `urn:mace:dir:attribute-def:mail` | `email` |
   | `urn:mace:dir:attribute-def:displayName` | `firstName` |
   | `urn:mace:dir:attribute-def:eduPersonAffiliation` | `affiliation` |
   | `urn:mace:dir:attribute-def:eduPersonPrincipalName` | `username` |

5. **Enable the Identity Provider**
   - Set **First Login Flow** to `first broker login`
   - Toggle **Enabled** to `On`
   - Click **Save**

---

### Testing with DFN-AAI Test Federation

Always test with the test federation before production registration.

#### Access Test Federation

1. **Navigate to Discovery Service**

   ```
   https://discovery.aai.dfn.de/
   ```

2. **Configure Return URL**

   ```
   https://idp.education.example.org/realms/opendesk/protocol/saml
   ```

3. **Select Test IdP**
   - Choose "DFN-AAI Test IdP" or any test institution
   - Login with test credentials

4. **Verify Authentication**
   - Check Keycloak user was created
   - Verify attributes were mapped correctly
   - Test application access (ILIAS, Moodle)

#### Test User Credentials

For DFN-AAI Test IdP:

- Username: `testuser1`, `testuser2`, `testuser3`
- Password: Check test IdP documentation

---

### Troubleshooting Common Issues

#### Metadata Validation Fails

**Symptom:** DFN-AAI rejects metadata with validation errors

**Solutions:**

1. Verify XML syntax: `xmllint --noout metadata.xml`
2. Check certificate format: `openssl x509 -in cert.pem -noout -text`
3. Ensure Entity ID is a valid HTTPS URL
4. Confirm all required attributes are listed

#### Registration Pending/Rejected

**Symptom:** No response or rejection after submission

**Checklist:**

- [ ] Verify email contacts are correct
- [ ] Check spam folder for DFN-AAI communications
- [ ] Confirm institution has valid DFN-AAI subscription
- [ ] Contact DFN-AAI support: [support@aai.dfn.de](mailto:support@aai.dfn.de)

#### "Invalid Signature" on Login

**Symptom:** Authentication fails with signature validation error

**Solutions:**

1. Verify SP certificate matches registration
2. Re-import DFN-AAI metadata in Keycloak
3. Check system time synchronization: `timedatectl status`

#### Attributes Not Received

**Symptom:** User authenticates but attributes are missing

**Solutions:**

1. Contact institutional IdP administrator about attribute release
2. Verify attribute mappers in Keycloak
3. Use SAML tracer browser extension to inspect assertions
4. Check `<AttributeConsumingService>` in your SP metadata

#### Certificate Expired

**Symptom:** Federation login fails due to expired certificate

**Recovery:**

1. Generate new certificate
2. Update Keycloak configuration
3. Re-submit metadata to DFN-AAI (30-day notice required for production)

---

### DFN-AAI Federation Endpoints

| Environment | Purpose | URL |
|-------------|---------|-----|
| Test Federation | Metadata | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml` |
| Test Federation | IdP SSO | `https://idp.test.aai.dfn.de/idp/profile/SAML2/Redirect/SSO` |
| Test Federation | Discovery | `https://discovery.aai.dfn.de/` |
| Production | Metadata | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Basic-metadata.xml` |
| Production | IdP SSO | `https://idp.aai.dfn.de/idp/profile/SAML2/Redirect/SSO` |
| Production | Discovery | `https://discovery.aai.dfn.de/` |

---

### Migration from Test to Production

Complete this checklist before moving to production:

- [ ] All tests pass with test federation
- [ ] CA-signed certificates obtained
- [ ] SP metadata regenerated with production certificates
- [ ] Production registration approved by DFN-AAI
- [ ] Keycloak IdP updated to production endpoints
- [ ] Pilot testing with small user group completed
- [ ] User support documentation created
- [ ] Helpdesk staff trained on federation authentication

---

### Additional Resources

- **DFN-AAI Documentation:** <https://www.aai.dfn.de/en/documentation/>
- **DFN-AAI Test Federation:** <https://www.aai.dfn.de/testumgebung/>
- **eduGAIN Technical Profile:** <https://technical.edugain.org/>
- **eduPerson Schema:** <https://www.educause.edu/research-and-technical/educause-identity-and-access-management/eduPerson>
- **Keycloak SAML Docs:** <https://www.keycloak.org/docs/latest/server_admin/#saml-identity-providers>
- **DFN-AAI Support:** [support@aai.dfn.de](mailto:support@aai.dfn.de)

---

<a name="deutsch"></a>

## Deutsch

### Was ist DFN-AAI?

[DFN-AAI](https://www.aai.dfn.de/) (Deutsches Forschungsnetz - Authentication and Authorization Infrastructure) ist die deutsche akademische Identitätsföderation, die Single Sign-On (SSO) für Forschungs- und Bildungseinrichtungen in Deutschland und international über eduGAIN ermöglicht.

#### Warum DFN-AAI für deutsche Universitäten wichtig ist

- **Über 200 deutsche Universitäten** nehmen bereits an DFN-AAI teil
- **Single Sign-On** für Studierende, Lehrende und Mitarbeitende mit institutionellen Zugangsdaten
- **eduGAIN-Integration** ermöglicht Zugriff aus über 70 nationalen Föderationen weltweit
- **Keine lokale Benutzerverwaltung** für externe Kollaborateure erforderlich
- **Standardisierte Attribute** (eduPerson-Schema) für rollenbasierte Zugriffskontrolle
- **Konformität** mit IT-Standards im deutschen Hochschulwesen

Durch die Registrierung von openDesk Edu als Service Provider (SP) in DFN-AAI können sich Benutzer beliebiger teilnehmender Einrichtungen mit ihren bestehenden Universitäts-Zugangsdaten authentifizieren.

---

### Voraussetzungen für die Registrierung

Stellen Sie vor Beginn des Registrierungsprozesses Folgendes sicher:

#### Administrative Voraussetzungen

| Anforderung | Beschreibung |
|-------------|--------------|
| DFN-AAI-Konto | Kontaktieren Sie Ihre IT-Abteilung oder den DFN-AAI-Support unter [support@aai.dfn.de](mailto:support@aai.dfn.de) |
| Institutionelle Autorisierung | Ihre Einrichtung muss DFN-AAI-Teilnehmer sein oder ein Abonnement haben |
| Technischer Kontakt | E-Mail-Adresse für Föderationsadministratoren |
| Administrativer Kontakt | E-Mail-Adresse für organisatorische Angelegenheiten |

#### Technische Voraussetzungen

| Anforderung | Beschreibung |
|-------------|--------------|
| Deployed openDesk Edu | Funktionierende Installation mit Keycloak |
| Öffentliches DNS | Ihre Domain muss öffentlich auflösbar sein |
| TLS-Zertifikate | Gültige HTTPS-Zertifikate für alle Endpunkte |
| SAML-Metadaten | Generierte Metadaten für Ihren Service Provider |

#### Netzwerkanforderungen

- Alle SAML-Endpunkte über HTTPS (Port 443) erreichbar
- Ausgehender HTTPS-Zugriff zu DFN-AAI-Diensten
- Firewall-Regeln für Verkehr zu/von DFN-AAI-Endpunkten

---

### Erforderliche Informationen für die Registrierung

Bereiten Sie folgende Informationen vor der Registrierung vor:

#### Service Provider-Informationen

| Feld | Beispielwert | Ihr Wert |
|------|--------------|----------|
| Entity ID | `https://idp.education.example.org/realms/opendesk` | |
| Dienstname | `openDesk Edu - Beispiel-Universität` | |
| Dienstbeschreibung | `Digitale Arbeitsplatzplattform für Bildung` | |
| Dienst-URL | `https://portal.education.example.org` | |

#### Organisationsinformationen

| Feld | Beispielwert | Ihr Wert |
|------|--------------|----------|
| Organisationsname | `Beispiel-Universität` | |
| Anzeigename | `Beispiel-Universität Bildungsplattform` | |
| Organisations-URL | `https://www.beispiel-universitaet.de` | |
| Technische Kontakt-E-Mail | `edu-tech@beispiel-universitaet.de` | |
| Administrative Kontakt-E-Mail | `edu-admin@beispiel-universitaet.de` | |

#### Technische Endpunkte

| Endpunkt | URL-Muster |
|----------|------------|
| Assertion Consumer Service (POST) | `https://idp.<domain>/realms/opendesk/protocol/saml` |
| Single Logout Service | `https://idp.<domain>/realms/opendesk/protocol/saml` |
| Metadaten-Deskriptor | `https://idp.<domain>/realms/opendesk/protocol/saml/descriptor` |

#### Erforderliche Attribute

DFN-AAI verlangt die Angabe, welche Attribute Ihr Dienst benötigt:

| Attribut | SAML-Name | Zweck |
|----------|-----------|-------|
| `mail` | `urn:mace:dir:attribute-def:mail` | E-Mail-Adresse des Benutzers |
| `displayName` | `urn:mace:dir:attribute-def:displayName` | Anzeigename des Benutzers |
| `eduPersonAffiliation` | `urn:mace:dir:attribute-def:eduPersonAffiliation` | Benutzerrolle (student/faculty/staff) |
| `eduPersonPrincipalName` | `urn:mace:dir:attribute-def:eduPersonPrincipalName` | Persistente eindeutige Kennung |

---

### Schritt-für-Schritt Registrierungsprozess

#### Schritt 1: SAML-Metadaten generieren

Generieren Sie Ihre Service Provider-Metadaten mit dem bereitgestellten Skript:

```bash
cd /opt/git/opendesk-edu

# Für Test-Föderation (selbstsigniertes Zertifikat)
./scripts/federation/generate-metadata.sh \
    -d education.example.org \
    -e "https://idp.education.example.org/realms/opendesk" \
    --generate-cert \
    --org-name "Beispiel-Universität" \
    --org-display "Beispiel-Universität Bildungsplattform" \
    --tech-email edu-support@example.org \
    -o /tmp/dfn-aai-metadata.xml
```

Für Produktions-Föderation verwenden Sie CA-signierte Zertifikate:

```bash
./scripts/federation/generate-metadata.sh \
    -d education.example.org \
    -e "https://idp.education.example.org/realms/opendesk" \
    -c /etc/pki/tls/certs/keycloak-sp.crt \
    -k /etc/pki/tls/private/keycloak-sp.key \
    --org-name "Beispiel-Universität" \
    --org-display "Beispiel-Universität Bildungsplattform" \
    --tech-email edu-support@example.org \
    -o /tmp/dfn-aai-metadata.xml
```

#### Schritt 2: Metadaten validieren

Validieren Sie vor der Einreichung Ihre Metadaten:

```bash
# XML-Syntax prüfen
xmllint --noout /tmp/dfn-aai-metadata.xml && echo "✓ XML ist gültig"

# Zertifikat verifizieren
openssl x509 -in sp-cert.pem -noout -dates

# Metadateninhalt prüfen
cat /tmp/dfn-aai-metadata.xml
```

Überprüfen Sie in der Ausgabe:

- `entityID` entspricht Ihrer beabsichtigten Kennung
- Organisationsinformationen sind korrekt
- Alle Endpunkte verwenden HTTPS
- Zertifikat ist korrekt eingebettet
- Erforderliche Attribute sind aufgelistet

#### Schritt 3: Registrierungsantrag einreichen

1. **DFN-AAI-Portal aufrufen**
   - Navigieren Sie zu: <https://www.aai.dfn.de/en/service/metadata/>
   - Melden Sie sich mit Ihrem DFN-AAI-Konto an

2. **Registrierungsformular ausfüllen**
   - **Registerkarte Dienstinformationen**
     - Entity ID eingeben (aus Metadaten)
     - Dienstname und -beschreibung angeben
     - Dienst-URL angeben

   - **Registerkarte Metadaten-Upload**
     - Generierte `dfn-aai-metadata.xml` hochladen
     - Zielföderation auswählen: **Test** oder **Produktion**

   - **Registerkarte Attributanforderungen**
     - Erforderliche Attribute bestätigen:
       - ☑ `mail`
       - ☑ `displayName`
       - ☑ `eduPersonAffiliation`
       - ☑ `eduPersonPrincipalName`

   - **Registerkarte Kontaktinformationen**
     - Technische Kontakt-E-Mail
     - Administrative Kontakt-E-Mail
     - Support-URL (optional)

3. **Zur Genehmigung einreichen**
   - Alle Informationen überprüfen
   - Auf **Registrierung einreichen** klicken
   - Registrierungsreferenznummer notieren

#### Schritt 4: Genehmigung abwarten

DFN-AAI validiert Ihre Einreichung:

- Metadatenformat-Validierung
- Endpunkt-Erreichbarkeitsprüfung
- Zertifikatsgültigkeitsprüfung
- Organisationale Verifizierung

**Zeitrahmen:**

- Test-Föderation: 1-2 Werktage
- Produktions-Föderation: 3-5 Werktage

Sie erhalten eine E-Mail-Benachrichtigung bei Genehmigung oder wenn Korrekturen erforderlich sind.

#### Schritt 5: Keycloak konfigurieren

Konfigurieren Sie nach der Genehmigung Keycloak für DFN-AAI:

1. **Keycloak-Admin-Konsole aufrufen**

   ```
   https://idp.education.example.org/admin/master/console/
   ```

2. **DFN-AAI als Identitätsanbieter hinzufügen**
   - Navigieren Sie zu **Realm-Einstellungen** > **Identitätsanbieter**
   - Klicken Sie **Anbieter hinzufügen** > **SAML v2.0**

3. **IdP-Einstellungen konfigurieren**

   | Feld | Test-Föderation | Produktions-Föderation |
   |------|-----------------|------------------------|
   | Alias | `dfn-aai-test` | `dfn-aai` |
   | Anzeigename | `DFN-AAI (Test)` | `DFN-AAI` |
   | Metadaten-URL | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml` | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Basic-metadata.xml` |

4. **Attribut-Mapper konfigurieren**

   Erstellen Sie Mapper für jedes erforderliche Attribut:

   | SAML-Attribut | Keycloak-Attribut |
   |---------------|-------------------|
   | `urn:mace:dir:attribute-def:mail` | `email` |
   | `urn:mace:dir:attribute-def:displayName` | `firstName` |
   | `urn:mace:dir:attribute-def:eduPersonAffiliation` | `affiliation` |
   | `urn:mace:dir:attribute-def:eduPersonPrincipalName` | `username` |

5. **Identitätsanbieter aktivieren**
   - **Erster Anmeldefluss** auf `first broker login` setzen
   - **Aktiviert** auf `Ein` schalten
   - **Speichern** klicken

---

### Test mit der DFN-AAI Test-Föderation

Testen Sie immer mit der Test-Föderation vor der Produktionsregistrierung.

#### Test-Föderation aufrufen

1. **Discovery-Service aufrufen**

   ```
   https://discovery.aai.dfn.de/
   ```

2. **Return-URL konfigurieren**

   ```
   https://idp.education.example.org/realms/opendesk/protocol/saml
   ```

3. **Test-IdP auswählen**
   - "DFN-AAI Test IdP" oder eine Test-Institution wählen
   - Mit Test-Zugangsdaten anmelden

4. **Authentifizierung verifizieren**
   - Prüfen, ob Keycloak-Benutzer erstellt wurde
   - Attribute korrekt gemappt wurden
   - Anwendungszugriff (ILIAS, Moodle) testen

#### Test-Benutzerzugangsdaten

Für DFN-AAI Test IdP:

- Benutzername: `testuser1`, `testuser2`, `testuser3`
- Passwort: Test-IdP-Dokumentation prüfen

---

### Fehlerbehebung häufiger Probleme

#### Metadaten-Validierung fehlgeschlagen

**Symptom:** DFN-AAI lehnt Metadaten mit Validierungsfehlern ab

**Lösungen:**

1. XML-Syntax prüfen: `xmllint --noout metadata.xml`
2. Zertifikatsformat prüfen: `openssl x509 -in cert.pem -noout -text`
3. Sicherstellen, dass Entity ID eine gültige HTTPS-URL ist
4. Bestätigen, dass alle erforderlichen Attribute aufgelistet sind

#### Registrierung ausstehend/abgelehnt

**Symptom:** Keine Antwort oder Ablehnung nach Einreichung

**Checkliste:**

- [ ] E-Mail-Kontakte auf Richtigkeit prüfen
- [ ] Spam-Ordner auf DFN-AAI-Kommunikation prüfen
- [ ] Bestätigen, dass die Einrichtung ein gültiges DFN-AAI-Abonnement hat
- [ ] DFN-AAI-Support kontaktieren: [support@aai.dfn.de](mailto:support@aai.dfn.de)

#### "Ungültige Signatur" bei Anmeldung

**Symptom:** Authentifizierung fehlgeschlagen mit Signaturvalidierungsfehler

**Lösungen:**

1. SP-Zertifikat mit Registrierung abgleichen
2. DFN-AAI-Metadaten in Keycloak neu importieren
3. Systemzeitsynchronisation prüfen: `timedatectl status`

#### Attribute nicht empfangen

**Symptom:** Benutzer authentifiziert sich, aber Attribute fehlen

**Lösungen:**

1. Institutionellen IdP-Administrator bezüglich Attributfreigabe kontaktieren
2. Attribut-Mapper in Keycloak prüfen
3. SAML-Tracer-Browsererweiterung zur Assertion-Inspektion verwenden
4. `<AttributeConsumingService>` in SP-Metadaten prüfen

#### Zertifikat abgelaufen

**Symptom:** Föderationsanmeldung fehlgeschlagen aufgrund abgelaufenem Zertifikat

**Wiederherstellung:**

1. Neues Zertifikat generieren
2. Keycloak-Konfiguration aktualisieren
3. Metadaten erneut bei DFN-AAI einreichen (30-Tage-Frist für Produktion)

---

### DFN-AAI Föderations-Endpunkte

| Umgebung | Zweck | URL |
|-----------|------|-----|
| Test-Föderation | Metadaten | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml` |
| Test-Föderation | IdP SSO | `https://idp.test.aai.dfn.de/idp/profile/SAML2/Redirect/SSO` |
| Test-Föderation | Discovery | `https://discovery.aai.dfn.de/` |
| Produktion | Metadaten | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Basic-metadata.xml` |
| Produktion | IdP SSO | `https://idp.aai.dfn.de/idp/profile/SAML2/Redirect/SSO` |
| Produktion | Discovery | `https://discovery.aai.dfn.de/` |

---

### Migration von Test zu Produktion

Absolvieren Sie diese Checkliste vor dem Wechsel zur Produktion:

- [ ] Alle Tests mit Test-Föderation erfolgreich
- [ ] CA-signierte Zertifikate erhalten
- [ ] SP-Metadaten mit Produktionszertifikaten neu generiert
- [ ] Produktionsregistrierung von DFN-AAI genehmigt
- [ ] Keycloak-IdP auf Produktions-Endpunkte aktualisiert
- [ ] Pilot-Testung mit kleiner Benutzergruppe abgeschlossen
- [ ] Benutzer-Support-Dokumentation erstellt
- [ ] Helpdesk-Mitarbeiter in Föderationsauthentifizierung geschult

---

### Zusätzliche Ressourcen

- **DFN-AAI-Dokumentation:** <https://www.aai.dfn.de/dokumentation/>
- **DFN-AAI Test-Föderation:** <https://www.aai.dfn.de/testumgebung/>
- **eduGAIN Technisches Profil:** <https://technical.edugain.org/>
- **eduPerson-Schema:** <https://www.educause.edu/research-and-technical/educause-identity-and-access-management/eduPerson>
- **Keycloak SAML-Dokumentation:** <https://www.keycloak.org/docs/latest/server_admin/#saml-identity-providers>
- **DFN-AAI-Support:** [support@aai.dfn.de](mailto:support@aai.dfn.de)

---

**Verwandte Dokumentation:**

- [DFN-AAI Enrollment Guide](./federation/dfn-aai-enrollment.md) - Technische Integrationsdetails
- [Federation Testing Guide](./federation/testing-guide.md) - Umfassende Testverfahren
- [IdP Federation Configuration](./enhanced-configuration/idp-federation.md) - Allgemeine IdP-Föderation

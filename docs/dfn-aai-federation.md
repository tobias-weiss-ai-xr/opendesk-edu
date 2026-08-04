<!--
SPDX-FileCopyrightText: 2025 openDesk Edu Contributors
SPDX-License-Identifier: AGPL-3.0-only
-->

# DFN-AAI Federation Guide / DFN-AAI Föderationsleitfaden

[English](#english) | [Deutsch](#deutsch)

---

<a name="english"></a>

## English

### Overview

DFN-AAI (Deutsche Forschungsnetz Authentication and Authorization Infrastructure) is the German Shibboleth federation that enables federated authentication for universities and research institutions. This guide explains how to integrate openDesk Edu with DFN-AAI.

### Architecture

```
┌─────────────┐                ┌──────────────┐              ┌──────────────┐
│    User     │                │  DFN-AAI IdP │              │  openDesk    │
│  (Browser)  │                │  (Shibboleth)│              │   Edu SP     │
└──────┬──────┘                └──────┬───────┘              └──────┬───────┘
       │                              │                              │
       │  1. Access Service           │                              │
       ├─────────────────────────────►│                              │
       │                              │                              │
       │  2. Redirect to DFN-AAI IdP                                │
       │◄─────────────────────────────┼──────────────────────────────┤
       │                              │                              │
       │  3. Login at DFN-AAI IdP     │                              │
       ├─────────────────────────────►│                              │
       │                              │                              │
       │  4. SAML Assertion           │                              │
       │◄─────────────────────────────┼──────────────────────────────┤
       │                              │                              │
       │  5. Access to Service                                        │
       ├─────────────────────────────────────────────────────────────►│
       │                                                              │
       │  6. Token from Keycloak                                     │
       │◄─────────────────────────────────────────────────────────────┤
```

### Prerequisites

1. **DFN-AAI Membership**: Your institution must be a member of DFN-AAI
2. **Shibboleth IdP**: Running a Shibboleth Identity Provider
3. **Domain**: A registered domain for your openDesk Edu deployment
4. **Certificates**: Valid SSL/TLS certificates for your domain

### Configuration Steps

#### 1. Register with DFN-AAI

Contact your institution's DFN-AAI administrator to register openDesk Edu as a Service Provider.

**Required Information:**

- Metadata URL: `https://yourdomain.de/saml/sp/metadata`
- Entity ID: `urn:auth:opendesk:edu:yourdomain`
- SSO URL: `https://yourdomain.de/saml/sp/sso`
- SLO URL: `https://yourdomain.de/saml/sp/slo`
- Certificates: Your SAML signing certificate

#### 2. Configure Keycloak SAML SP

Edit `helmfile/charts/keycloak/values.yaml`:

```yaml
# Enable SAML SP
keycloak:
  enabled: true
  auth:
    saml:
      enabled: true
      idp:
        name: "DFN-AAI"
        ssoUrl: "https://idp.yourinstitution.de/idp/profile/SAML2/Redirect/SSO"
        sloUrl: "https://idp.yourinstitution.de/idp/profile/SAML2/POST/SLO"
        metadataUrl: "https://idp.yourinstitution.de/idp/shibboleth"
        nameIdFormat: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
      sp:
        entityId: "urn:auth:opendesk:edu:yourdomain"
        nameIdFormat: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
        assertionConsumerServiceUrl: "https://yourdomain.de/saml/sp/sso"
        singleLogoutServiceUrl: "https://yourdomain.de/saml/sp/slo"
```

#### 3. Configure Attribute Mapping

DFN-AAI provides standard eduPerson attributes. Map these to Keycloak claims in `helmfile/charts/keycloak/values.yaml`:

```yaml
keycloak:
  auth:
    saml:
      attributeMapper:
        - name: "eduPersonPrincipalName"
          friendlyName: "eduPersonPrincipalName"
          samlAttributeName: "eduPersonPrincipalName"
          userAttributeName: "username"
        - name: "mail"
          friendlyName: "mail"
          samlAttributeName: "mail"
          userAttributeName: "email"
        - name: "displayName"
          friendlyName: "displayName"
          samlAttributeName: "displayName"
          userAttributeName: "firstName"
        - name: "sn"
          friendlyName: "sn"
          samlAttributeName: "sn"
          userAttributeName: "lastName"
        - name: "eduPersonAffiliation"
          friendlyName: "eduPersonAffiliation"
          samlAttributeName: "eduPersonAffiliation"
          userAttributeName: "affiliation"
        - name: "eduPersonEntitlement"
          friendlyName: "eduPersonEntitlement"
          samlAttributeName: "eduPersonEntitlement"
          userAttributeName: "entitlement"
```

#### 4. Role Mapping Based on Affiliation

Create Keycloak groups and map DFN-AAI affiliations to these groups:

```yaml
keycloak:
  realm:
    roles:
      - name: student
        description: "Student access"
        federationId: "student"
      - name: employee
        description: "Employee access"
        federationId: "employee"
      - name: faculty
        description: "Faculty access"
        federationId: "faculty"
      - name: staff
        description: "Staff access"
        federationId: "staff"

    roleMappings:
      - affiliation: "student"
        role: "student"
      - affiliation: "employee"
        role: "employee"
      - affiliation: "faculty"
        role: "faculty"
      - affiliation: "staff"
        role: "staff"
```

#### 5. Configure Backchannel Logout

Ensure backchannel logout is configured for DFN-AAI:

```yaml
keycloak:
  auth:
    saml:
      backchannel:
        enabled: true
        logoutUrl: "https://idp.yourinstitution.de/idp/profile/SAML2/SLO/SOAP"
```

### Testing DFN-AAI Integration

#### 1. Metadata Verification

Test your SAML SP metadata:

```bash
curl -X GET https://yourdomain.de/saml/sp/metadata
```

Verify:

- Entity ID matches what you registered with DFN-AAI
- SSO and SLO URLs are correct
- Certificates are valid

#### 2. Test Federation Login

1. Navigate to your openDesk Edu portal
2. Click "Login with DFN-AAI"
3. Select your institution's IdP from the Discovery Service
4. Login with your institutional credentials
5. Verify you're logged in and have correct roles

#### 3. Test Attribute Release

Check that DFN-AAI IdP is releasing required attributes:

```bash
kubectl logs -n keycloak deployment/keycloak -f
```

Look for:

- `eduPersonPrincipalName` — Your institutional username
- `mail` — Your institutional email
- `displayName` — Your display name
- `sn` — Your surname
- `eduPersonAffiliation` — Your affiliation (student/employee/faculty/staff)

### Troubleshooting

#### Common Issues

##### 1. Invalid Metadata URL

**Problem**: DFN-AAI cannot retrieve your metadata

**Solution**:

- Check metadata URL is publicly accessible
- Verify SSL certificate is valid
- Ensure firewall allows access to your metadata URL

##### 2. Attribute Release Refused

**Problem**: User cannot login — attributes not released

**Solution**:

- Contact your DFN-AAI administrator
- Request attribute release for required attributes
- Verify attribute mapping in the IdP configuration

##### 3. Role Mismatch

**Problem**: User has wrong roles/permissions

**Solution**:

- Check `eduPersonAffiliation` value returned by IdP
- Verify role mapping configuration in Keycloak
- Ensure user has correct affiliation in your institutional directory

##### 4. Logout Not Propagating

**Problem**: Logging out of openDesk Edu doesn't logout from IdP

**Solution**:

- Verify backchannel logout is enabled
- Check SLO URL is correct
- Test with DFN-AAI test federation

#### Debug Logging

Enable verbose logging for Keycloak SAML:

```yaml
keycloak:
  logging:
    level:
      root: DEBUG
      org.keycloak.saml: DEBUG
      org.keycloak.saml.processing: TRACE
```

### Production Deployment Checklist

- [ ] Registered with DFN-AAI and received Entity ID
- [ ] Valid SSL/TLS certificate installed
- [ ] Keycloak SAML SP configured with DFN-AAI IdP
- [ ] Attribute mapping configured and tested
- [ ] Role mapping configured and tested
- [ ] Backchannel logout enabled and tested
- [ ] Test with DFN-AAI test federation
- [ ] Test with production DFN-AAI federation
- [ ] Document your Entity ID and metadata URL
- [ ] Train support team on DFN-AAI login flow

### References

- [DFN-AAI Documentation](https://www.aai.dfn.de/)
- [DFN-AAI Metadata](https://www.aai.dfn.de/metadata/)
- [Shibboleth Documentation](https://wiki.shibboleth.net/)
- [eduPerson Specification](https://internet2.edu/performance/eduPerson/)
- [eduGAIN](https://edugain.org/)

### Support

For DFN-AAI-specific issues, contact your institution's DFN-AAI administrator or the DFN-AAI support team.

For openDesk Edu configuration issues, open an issue on GitHub.

---

<a name="deutsch"></a>

## Deutsch

### Übersicht

DFN-AAI (Deutsches Forschungsnetz — Authentication and Authorization Infrastructure) ist die deutsche Shibboleth-Föderation, die föderierte Authentifizierung für Universitäten und Forschungseinrichtungen ermöglicht. Dieser Leitfaden erklärt die Integration von openDesk Edu mit DFN-AAI.

### Architektur

```
┌─────────────┐                ┌──────────────┐              ┌──────────────┐
│   Benutzer  │                │  DFN-AAI IdP │              │  openDesk    │
│  (Browser)  │                │  (Shibboleth)│              │   Edu SP     │
└──────┬──────┘                └──────┬───────┘              └──────┬───────┘
       │                              │                              │
       │  1. Dienst aufrufen          │                              │
       ├─────────────────────────────►│                              │
       │                              │                              │
       │  2. Weiterleitung zum DFN-AAI-IdP                           │
       │◄─────────────────────────────┼──────────────────────────────┤
       │                              │                              │
       │  3. Anmeldung am DFN-AAI-IdP │                              │
       ├─────────────────────────────►│                              │
       │                              │                              │
       │  4. SAML-Assertion           │                              │
       │◄─────────────────────────────┼──────────────────────────────┤
       │                              │                              │
       │  5. Dienstzugriff                                             │
       ├─────────────────────────────────────────────────────────────►│
       │                                                              │
       │  6. Token von Keycloak                                       │
       │◄─────────────────────────────────────────────────────────────┤
```

### Voraussetzungen

1. **DFN-AAI-Mitgliedschaft**: Ihre Einrichtung muss DFN-AAI-Mitglied sein
2. **Shibboleth-IdP**: Ein laufender Shibboleth-Identity-Provider
3. **Domain**: Eine registrierte Domain für Ihre openDesk-Edu-Deployment
4. **Zertifikate**: Gültige SSL/TLS-Zertifikate für Ihre Domain

### Konfigurationsschritte

#### 1. Bei DFN-AAI registrieren

Kontaktieren Sie den DFN-AAI-Administrator Ihrer Einrichtung, um openDesk Edu als Service Provider zu registrieren.

**Erforderliche Informationen:**

- Metadaten-URL: `https://ihredomain.de/saml/sp/metadata`
- Entity ID: `urn:auth:opendesk:edu:ihredomain`
- SSO-URL: `https://ihredomain.de/saml/sp/sso`
- SLO-URL: `https://ihredomain.de/saml/sp/slo`
- Zertifikate: Ihr SAML-Signaturzertifikat

#### 2. Keycloak SAML SP konfigurieren

Bearbeiten Sie `helmfile/charts/keycloak/values.yaml`:

```yaml
# SAML SP aktivieren
keycloak:
  enabled: true
  auth:
    saml:
      enabled: true
      idp:
        name: "DFN-AAI"
        ssoUrl: "https://idp.ihreinrichtung.de/idp/profile/SAML2/Redirect/SSO"
        sloUrl: "https://idp.ihreinrichtung.de/idp/profile/SAML2/POST/SLO"
        metadataUrl: "https://idp.ihreinrichtung.de/idp/shibboleth"
        nameIdFormat: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
      sp:
        entityId: "urn:auth:opendesk:edu:ihredomain"
        nameIdFormat: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
        assertionConsumerServiceUrl: "https://ihredomain.de/saml/sp/sso"
        singleLogoutServiceUrl: "https://ihredomain.de/saml/sp/slo"
```

#### 3. Attribut-Mapping konfigurieren

DFN-AAI stellt standardisierte eduPerson-Attribute bereit. Ordnen Sie diese Keycloak-Claims in `helmfile/charts/keycloak/values.yaml` zu:

```yaml
keycloak:
  auth:
    saml:
      attributeMapper:
        - name: "eduPersonPrincipalName"
          friendlyName: "eduPersonPrincipalName"
          samlAttributeName: "eduPersonPrincipalName"
          userAttributeName: "username"
        - name: "mail"
          friendlyName: "mail"
          samlAttributeName: "mail"
          userAttributeName: "email"
        - name: "displayName"
          friendlyName: "displayName"
          samlAttributeName: "displayName"
          userAttributeName: "firstName"
        - name: "sn"
          friendlyName: "sn"
          samlAttributeName: "sn"
          userAttributeName: "lastName"
        - name: "eduPersonAffiliation"
          friendlyName: "eduPersonAffiliation"
          samlAttributeName: "eduPersonAffiliation"
          userAttributeName: "affiliation"
        - name: "eduPersonEntitlement"
          friendlyName: "eduPersonEntitlement"
          samlAttributeName: "eduPersonEntitlement"
          userAttributeName: "entitlement"
```

#### 4. Rollenzuordnung basierend auf Zugehörigkeit

Erstellen Sie Keycloak-Gruppen und ordnen Sie DFN-AAI-Zugehörigkeiten diesen Gruppen zu:

```yaml
keycloak:
  realm:
    roles:
      - name: student
        description: "Studentenzugriff"
        federationId: "student"
      - name: employee
        description: "Mitarbeiterzugriff"
        federationId: "employee"
      - name: faculty
        description: "Dozentenzugriff"
        federationId: "faculty"
      - name: staff
        description: "Personalzugriff"
        federationId: "staff"

    roleMappings:
      - affiliation: "student"
        role: "student"
      - affiliation: "employee"
        role: "employee"
      - affiliation: "faculty"
        role: "faculty"
      - affiliation: "staff"
        role: "staff"
```

#### 5. Backchannel-Abmeldung konfigurieren

Stellen Sie sicher, dass die Backchannel-Abmeldung für DFN-AAI konfiguriert ist:

```yaml
keycloak:
  auth:
    saml:
      backchannel:
        enabled: true
        logoutUrl: "https://idp.ihreinrichtung.de/idp/profile/SAML2/SLO/SOAP"
```

### DFN-AAI-Integration testen

#### 1. Metadatenüberprüfung

Testen Sie Ihre SAML-SP-Metadaten:

```bash
curl -X GET https://ihredomain.de/saml/sp/metadata
```

Überprüfen Sie:

- Entity ID stimmt mit der bei DFN-AAI registrierten überein
- SSO- und SLO-URLs sind korrekt
- Zertifikate sind gültig

#### 2. Föderationsanmeldung testen

1. Navigieren Sie zu Ihrem openDesk-Edu-Portal
2. Klicken Sie auf „Mit DFN-AAI anmelden"
3. Wählen Sie den IdP Ihrer Einrichtung im Discovery-Service
4. Melden Sie sich mit Ihren institutionellen Zugangsdaten an
5. Überprüfen Sie, ob Sie angemeldet sind und die korrekten Rollen haben

#### 3. Attributfreigabe testen

Prüfen Sie, ob der DFN-AAI-IdP die erforderlichen Attribute freigibt:

```bash
kubectl logs -n keycloak deployment/keycloak -f
```

Suchen Sie nach:

- `eduPersonPrincipalName` — Ihr institutioneller Benutzername
- `mail` — Ihre institutionelle E-Mail
- `displayName` — Ihr Anzeigename
- `sn` — Ihr Nachname
- `eduPersonAffiliation` — Ihre Zugehörigkeit (student/employee/faculty/staff)

### Fehlerbehebung

#### Häufige Probleme

##### 1. Ungültige Metadaten-URL

**Problem**: DFN-AAI kann Ihre Metadaten nicht abrufen

**Lösung**:

- Prüfen Sie, ob die Metadaten-URL öffentlich zugänglich ist
- Überprüfen Sie, ob das SSL-Zertifikat gültig ist
- Stellen Sie sicher, dass die Firewall den Zugriff auf Ihre Metadaten-URL erlaubt

##### 2. Attributfreigabe verweigert

**Problem**: Benutzer kann sich nicht anmelden — Attribute werden nicht freigegeben

**Lösung**:

- Kontaktieren Sie Ihren DFN-AAI-Administrator
- Fordern Sie die Attributfreigabe für die erforderlichen Attribute an
- Überprüfen Sie das Attribut-Mapping in der IdP-Konfiguration

##### 3. Rollendiskrepanz

**Problem**: Benutzer hat falsche Rollen/Berechtigungen

**Lösung**:

- Prüfen Sie den vom IdP zurückgegebenen `eduPersonAffiliation`-Wert
- Überprüfen Sie die Rollenzuordnungskonfiguration in Keycloak
- Stellen Sie sicher, dass der Benutzer die korrekte Zugehörigkeit in Ihrem institutionellen Verzeichnis hat

##### 4. Abmeldung wird nicht weitergegeben

**Problem**: Die Abmeldung von openDesk Edu meldet den Benutzer nicht beim IdP ab

**Lösung**:

- Überprüfen Sie, ob die Backchannel-Abmeldung aktiviert ist
- Prüfen Sie, ob die SLO-URL korrekt ist
- Testen Sie mit der DFN-AAI-Testföderation

#### Debug-Logging

Aktivieren Sie ausführliche Protokollierung für Keycloak SAML:

```yaml
keycloak:
  logging:
    level:
      root: DEBUG
      org.keycloak.saml: DEBUG
      org.keycloak.saml.processing: TRACE
```

### Produktionsbereitstellungs-Checkliste

- [ ] Bei DFN-AAI registriert und Entity ID erhalten
- [ ] Gültiges SSL/TLS-Zertifikat installiert
- [ ] Keycloak SAML SP mit DFN-AAI-IdP konfiguriert
- [ ] Attribut-Mapping konfiguriert und getestet
- [ ] Rollenzuordnung konfiguriert und getestet
- [ ] Backchannel-Abmeldung aktiviert und getestet
- [ ] Test mit DFN-AAI-Testföderation durchgeführt
- [ ] Test mit produktiver DFN-AAI-Föderation durchgeführt
- [ ] Entity ID und Metadaten-URL dokumentiert
- [ ] Support-Team im DFN-AAI-Anmeldeflow geschult

### Referenzen

- [DFN-AAI-Dokumentation](https://www.aai.dfn.de/)
- [DFN-AAI-Metadaten](https://www.aai.dfn.de/metadata/)
- [Shibboleth-Dokumentation](https://wiki.shibboleth.net/)
- [eduPerson-Spezifikation](https://internet2.edu/performance/eduPerson/)
- [eduGAIN](https://edugain.org/)

### Support

Bei DFN-AAI-spezifischen Problemen kontaktieren Sie den DFN-AAI-Administrator Ihrer Einrichtung oder das DFN-AAI-Support-Team.

Bei openDesk Edu-Konfigurationsproblemen erstellen Sie ein Issue auf GitHub.

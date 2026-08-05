<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# DFN-AAI Test Federation Testing Guide / DFN-AAI Test-Föderation Testhandbuch

[English](#english) | [Deutsch](#deutsch)

---

<a name="english"></a>

## English

### Overview

This guide provides comprehensive procedures for testing openDesk Edu integration with the DFN-AAI test federation environment. Testing with the test federation is mandatory before production deployment to ensure:

- **Authentication flows** work correctly with SAML 2.0
- **eduGAIN attributes** are received and mapped properly
- **Role-based access** is assigned based on eduPersonAffiliation
- **Just-in-time provisioning** creates users with correct profiles
- **Single Logout** propagates correctly across all services

---

### Test Federation Information

#### DFN-AAI Test Federation Endpoints

| Environment | Purpose | URL |
|-------------|---------|-----|
| Test Federation | Metadata | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml` |
| Test Federation | Discovery Service | `https://discovery.aai.dfn.de/` |
| Test Federation | Test IdP | `https://idp.test.aai.dfn.de/` |
| Test Federation | Support | `support@aai.dfn.de` |

#### Test Federation Characteristics

| Feature | Test Federation | Production |
|---------|-----------------|------------|
| Certificates | Self-signed allowed | CA-signed required |
| Metadata Refresh | Manual | Automatic |
| User Accounts | Test accounts available | Real institution accounts |
| Attribute Release | Predictable test values | Institution-dependent |
| Registration Time | 1-2 business days | 3-5 business days |

---

### Prerequisites for Testing

#### System Requirements

| Requirement | Status | Notes |
|-------------|--------|-------|
| Keycloak deployed | ☐ | Version 22+ with SAML 2.0 support |
| SP registered in test federation | ☐ | See [DFN-AAI Registration Guide](./dfn-aai-registration.md) |
| SAML metadata configured | ☐ | Entity ID matching registration |
| Attribute mappers configured | ☐ | See [eduGAIN Attribute Mapping](./keycloak-edugain-attributes.md) |
| Realm roles created | ☐ | student, instructor, staff, etc. |
| Test DNS resolution | ☐ | Public DNS for your domain |

#### Browser Tools

| Tool | Purpose | Installation |
|------|---------|--------------|
| [SAML Tracer](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/) | Inspect SAML assertions | Firefox Add-on |
| Browser DevTools | Network debugging | Built-in (F12) |
| Cookie Editor | Session inspection | Browser extension |

---

### Test User Accounts

#### DFN-AAI Test IdP Users

The DFN-AAI test federation provides test accounts with predictable attributes:

| Test User | eduPersonAffiliation | Expected Role | Notes |
|-----------|---------------------|---------------|-------|
| `testuser1` | `faculty` | `instructor` | Teaching staff |
| `testuser2` | `staff` | `staff` | Administrative staff |
| `testuser3` | `student` | `student` | Student user |
| `testuser4` | `member` | `member` | Basic member |
| `testuser5` | `affiliate` | `affiliate` | External affiliate |

> **Note:** Contact DFN-AAI support at `support@aai.dfn.de` for current test credentials and additional test accounts.

#### Test Attribute Values

When using test accounts, expect these attribute values:

```
mail: testuser[N]@test.aai.dfn.de
displayName: Test User [N]
eduPersonPrincipalName: testuser[N]@test.aai.dfn.de
eduPersonAffiliation: [faculty|staff|student|member|affiliate]
eduPersonScopedAffiliation: [affiliation]@test.aai.dfn.de
```

---

### Test Scenario 1: Authentication Flow

#### Objective

Verify that users can authenticate through the DFN-AAI test federation and Keycloak correctly processes the SAML assertion.

#### Test Steps

1. **Initiate Authentication**

   ```bash
   # Open browser to portal
   https://portal.education.example.org
   ```

2. **Select DFN-AAI Identity Provider**
   - Click "Login with DFN-AAI (Test)" or equivalent button
   - Verify redirect to DFN-AAI discovery service

3. **Select Test IdP**
   - Choose "DFN-AAI Test IdP" from the list
   - Verify redirect to test IdP login page

4. **Enter Test Credentials**
   - Username: `testuser1`
   - Password: (obtain from DFN-AAI support)

5. **Complete Authentication**
   - Verify redirect back to Keycloak
   - Verify redirect to portal
   - Verify user is logged in

#### Expected Results

| Check | Expected | Pass/Fail |
|------|----------|-----------|
| Redirect to discovery service | Yes | ☐ |
| Test IdP selectable | Yes | ☐ |
| Login succeeds | Yes | ☐ |
| Redirect to Keycloak | Yes | ☐ |
| Redirect to portal | Yes | ☐ |
| User session created | Yes | ☐ |

#### SAML Tracer Verification

Open SAML Tracer during authentication and verify:

1. **AuthnRequest** sent to IdP
   - Contains correct Entity ID
   - Contains correct ACS URL

2. **SAML Assertion** received
   - Signed correctly
   - Contains expected attributes
   - Subject confirmation matches

3. **Attribute Statement** contains:

   ```xml
   <saml2:Attribute Name="urn:mace:dir:attribute-def:mail">
     <saml2:AttributeValue>testuser1@test.aai.dfn.de</saml2:AttributeValue>
   </saml2:Attribute>
   <saml2:Attribute Name="urn:mace:dir:attribute-def:eduPersonAffiliation">
     <saml2:AttributeValue>faculty</saml2:AttributeValue>
   </saml2:Attribute>
   ```

---

### Test Scenario 2: Attribute Assertion Verification

#### Objective

Verify that all required eduGAIN attributes are received and correctly mapped to Keycloak user attributes.

#### Test Steps

1. **Authenticate as testuser1**
   - Complete authentication flow from Scenario 1
   - Note the SAML assertion ID for reference

2. **Capture SAML Assertion**
   - Use SAML Tracer to capture the assertion
   - Export/copy the full assertion XML

3. **Verify Received Attributes**

   | SAML Attribute | Expected Value | Received | Mapped |
   |----------------|----------------|----------|--------|
   | `mail` | `testuser1@test.aai.dfn.de` | ☐ | ☐ |
   | `displayName` | `Test User 1` | ☐ | ☐ |
   | `eduPersonPrincipalName` | `testuser1@test.aai.dfn.de` | ☐ | ☐ |
   | `eduPersonAffiliation` | `faculty` | ☐ | ☐ |
   | `eduPersonScopedAffiliation` | `faculty@test.aai.dfn.de` | ☐ | ☐ |

4. **Verify Keycloak User Attributes**

   ```bash
   # Access Keycloak Admin Console
   https://idp.education.example.org/admin/master/console/

   # Navigate to Users → testuser1@test.aai.dfn.de → Attributes
   ```

5. **Check Attribute Mapping**

   | Keycloak Attribute | Expected Value | Actual | Status |
   |--------------------|----------------|--------|--------|
   | `email` | `testuser1@test.aai.dfn.de` | | ☐ |
   | `firstName` | `Test` (or full displayName) | | ☐ |
   | `lastName` | `User 1` (if parsed) | | ☐ |
   | `username` | `testuser1@test.aai.dfn.de` | | ☐ |
   | `affiliation` | `faculty` | | ☐ |

#### Troubleshooting Missing Attributes

| Issue | Cause | Solution |
|-------|-------|----------|
| Attribute not in assertion | IdP not releasing | Contact IdP admin / check metadata |
| Attribute in assertion but not mapped | Mapper missing | Add attribute mapper in Keycloak |
| Attribute mapped incorrectly | Wrong attribute name | Verify mace vs OID format |
| Multi-value attribute shows only one | Mapper configuration | Enable multi-value support |

---

### Test Scenario 3: Role Mapping Validation

#### Objective

Verify that eduPersonAffiliation values are correctly converted to Keycloak realm roles.

#### Prerequisites

Ensure these realm roles exist in Keycloak:

| Role | Description | Required |
|------|-------------|----------|
| `student` | Student access | Yes |
| `instructor` | Teaching staff access | Yes |
| `staff` | Administrative access | Yes |
| `employee` | Employee access | Yes |
| `member` | Basic member access | Yes |
| `affiliate` | External affiliate access | Yes |
| `alumni` | Alumni access | Optional |
| `library` | Library-only access | Optional |

#### Test Matrix

Test each affiliation type:

##### Test 3.1: Faculty User (testuser1)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as testuser1 | Authentication succeeds |
| 2 | Check user roles | `instructor` role assigned |
| 3 | Verify access | Instructor-level resources accessible |

##### Test 3.2: Staff User (testuser2)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as testuser2 | Authentication succeeds |
| 2 | Check user roles | `staff` role assigned |
| 3 | Verify access | Staff-level resources accessible |

##### Test 3.3: Student User (testuser3)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as testuser3 | Authentication succeeds |
| 2 | Check user roles | `student` role assigned |
| 3 | Verify access | Student-level resources accessible |

#### Role Mapping Verification Script

```bash
#!/bin/bash
# verify-roles.sh - Verify role assignments for test users

KEYCLOAK_URL="https://idp.education.example.org"
REALM="opendesk"
ADMIN_USER="admin"
ADMIN_PASS="${ADMIN_PASSWORD}"

# Get admin token
TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASS}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

# Check roles for each test user
for user in "testuser1@test.aai.dfn.de" "testuser2@test.aai.dfn.de" "testuser3@test.aai.dfn.de"; do
  echo "=== Checking roles for ${user} ==="

  USER_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/users?username=${user}" \
    -H "Authorization: Bearer ${TOKEN}" | jq -r '.[0].id')

  curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/users/${USER_ID}/role-mappings/realm" \
    -H "Authorization: Bearer ${TOKEN}" | jq -r '.[] | .name'

  echo ""
done
```

#### Expected Role Mapping Results

| User | eduPersonAffiliation | Expected Roles |
|------|---------------------|----------------|
| testuser1 | faculty | instructor |
| testuser2 | staff | staff |
| testuser3 | student | student |
| testuser4 | member | member |
| testuser5 | affiliate | affiliate |

---

### Test Scenario 4: Just-in-Time Provisioning

#### Objective

Verify that new users are automatically created with correct profile information on first login.

#### Test Steps

1. **Verify User Does Not Exist**

   ```bash
   # Check user doesn't exist before test
   curl -s "https://idp.education.example.org/admin/realms/opendesk/users?username=testuser1@test.aai.dfn.de" \
     -H "Authorization: Bearer ${TOKEN}"
   # Should return empty array: []
   ```

2. **Perform First Login**
   - Login as testuser1 via DFN-AAI test federation
   - Complete authentication flow

3. **Verify User Created**

   ```bash
   # Check user exists after login
   curl -s "https://idp.education.example.org/admin/realms/opendesk/users?username=testuser1@test.aai.dfn.de" \
     -H "Authorization: Bearer ${TOKEN}"
   ```

4. **Verify User Profile**

   | Field | Expected Value | Actual | Status |
   |-------|----------------|--------|--------|
   | Username | `testuser1@test.aai.dfn.de` | | ☐ |
   | Email | `testuser1@test.aai.dfn.de` | | ☐ |
   | Email Verified | `true` | | ☐ |
   | First Name | `Test` | | ☐ |
   | Last Name | `User 1` | | ☐ |
   | Enabled | `true` | | ☐ |

5. **Verify Federation Link**

   ```bash
   # Check federated identity link
   curl -s "https://idp.education.example.org/admin/realms/opendesk/users/${USER_ID}/federated-identity" \
     -H "Authorization: Bearer ${TOKEN}"
   # Should show link to dfn-aai-test provider
   ```

#### JIT Provisioning Checklist

| Check | Status |
|-------|--------|
| User created on first login | ☐ |
| Username set correctly | ☐ |
| Email set and verified | ☐ |
| Name attributes populated | ☐ |
| Federation link created | ☐ |
| Roles assigned correctly | ☐ |
| User enabled by default | ☐ |

---

### Test Scenario 5: Logout Propagation

#### Objective

Verify that Single Logout (SLO) correctly terminates sessions across all services.

#### Prerequisites

- Backchannel logout configured (see [Backchannel Logout Guide](./backchannel-logout.md))
- All services support SAML logout

#### Test Steps

1. **Login to Multiple Services**
   - Login via DFN-AAI to portal
   - Access ILIAS (verify authenticated)
   - Access Moodle (verify authenticated)
   - Note session cookies for each service

2. **Initiate Logout**
   - Click logout in portal
   - Or navigate to: `https://portal.education.example.org/logout`

3. **Verify Global Logout**
   - Verify redirect to DFN-AAI logout endpoint
   - Verify redirect back to application

4. **Verify Session Termination**

   | Service | Session Terminated | Status |
   |---------|-------------------|--------|
   | Keycloak | Yes | ☐ |
   | Portal | Yes | ☐ |
   | ILIAS | Yes | ☐ |
   | Moodle | Yes | ☐ |
   | BigBlueButton | Yes | ☐ |
   | Nextcloud/OpenCloud | Yes | ☐ |

5. **Verify Re-authentication Required**
   - Try accessing each service
   - Verify redirect to login page

#### SAML Logout Flow Verification

Using SAML Tracer, verify the logout flow:

1. **LogoutRequest** sent to IdP
   - Contains correct NameID
   - Contains correct SessionIndex

2. **LogoutResponse** received
   - Status: Success

3. **Backchannel Logout** (if configured)
   - Logout requests sent to all SPs
   - All sessions terminated

#### Logout Test Script

```bash
#!/bin/bash
# test-logout.sh - Verify logout propagation

PORTAL_URL="https://portal.education.example.org"

echo "=== Testing Logout Propagation ==="

# 1. Check sessions before logout (requires admin access)
echo "1. Active sessions before logout:"
# Use Keycloak admin API to list sessions

# 2. Initiate logout
echo "2. Initiating logout..."
echo "   Open: ${PORTAL_URL}/logout"
echo "   Complete logout in browser"

# 3. Check sessions after logout
echo "3. Verify sessions terminated:"
echo "   - Try accessing: ${PORTAL_URL}/ilias"
echo "   - Try accessing: ${PORTAL_URL}/moodle"
echo "   - Should redirect to login"

echo ""
echo "Logout test complete."
```

---

### Comprehensive Test Checklist

Use this checklist to track overall testing progress:

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

#### Logout Tests

| Test | Description | Status |
|------|-------------|--------|
| LOGOUT-01 | Portal logout | ☐ |
| LOGOUT-02 | ILIAS session termination | ☐ |
| LOGOUT-03 | Moodle session termination | ☐ |
| LOGOUT-04 | BigBlueButton session termination | ☐ |
| LOGOUT-05 | Backchannel logout propagation | ☐ |
| LOGOUT-06 | Frontchannel logout propagation | ☐ |

---

### Troubleshooting Guide

#### Authentication Fails

| Symptom | Possible Cause | Solution |
|---------|---------------|----------|
| "No IdP found" | Metadata not loaded | Re-import DFN-AAI test metadata |
| "Invalid signature" | Certificate mismatch | Verify SP certificate in Keycloak |
| "ACS URL mismatch" | Wrong endpoint | Check Assertion Consumer Service URL |
| Redirect loop | Misconfigured redirect | Check Valid Redirect URIs in Keycloak |
| Timeout | Network connectivity | Check firewall rules |

#### Attributes Missing

| Symptom | Possible Cause | Solution |
|---------|---------------|----------|
| No attributes in assertion | IdP not releasing | Check IdP attribute release policy |
| Attributes in assertion but not mapped | Mapper missing | Add attribute mappers |
| Wrong attribute values | Mapper misconfiguration | Check attribute name format |
| Partial attributes | Some mappers failing | Check mapper execution order |

#### Role Assignment Fails

| Symptom | Possible Cause | Solution |
|---------|---------------|----------|
| No roles assigned | Role mapper missing | Add role import mapper |
| Wrong roles | Mapping logic error | Check role mapping script |
| Roles missing in realm | Roles not created | Create realm roles first |
| Duplicate role errors | Role already assigned | Use idempotent role assignment |

#### Logout Issues

| Symptom | Possible Cause | Solution |
|---------|---------------|----------|
| Session not terminated | SLO not supported | Enable backchannel logout |
| Partial logout | Some SPs not notified | Check all SP configurations |
| Logout loop | Misconfigured endpoints | Verify SingleLogoutService URLs |
| Timeout on logout | Network issues | Check backchannel connectivity |

---

### Test Evidence Collection

Collect the following evidence during testing:

#### Required Evidence Files

| File | Content | Location |
|------|---------|----------|
| `task-5-auth-test.log` | Authentication test results | `.sisyphus/evidence/` |
| `task-5-attributes.log` | Attribute assertion verification | `.sisyphus/evidence/` |
| `task-5-roles.log` | Role mapping validation | `.sisyphus/evidence/` |
| `task-5-logout.log` | Logout propagation test | `.sisyphus/evidence/` |

#### SAML Assertion Samples

Save sample SAML assertions for reference:

```bash
# Using SAML Tracer, export assertions for each test user:
# - testuser1-faculty-assertion.xml
# - testuser2-staff-assertion.xml
# - testuser3-student-assertion.xml
```

---

### Additional Resources

- **DFN-AAI Test Federation:** <https://www.aai.dfn.de/testumgebung/>
- **DFN-AAI Support:** [support@aai.dfn.de](mailto:support@aai.dfn.de)
- **eduGAIN Technical Profile:** <https://technical.edugain.org/>
- **Keycloak SAML Documentation:** <https://www.keycloak.org/docs/latest/server_admin/#saml-identity-providers>
- **SAML Tracer:** <https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/>

---

<a name="deutsch"></a>

## Deutsch

### Übersicht

Dieser Leitfaden bietet umfassende Verfahren zum Testen der openDesk Edu-Integration mit der DFN-AAI-Testföderationsumgebung. Das Testen mit der Testföderation ist vor der Produktionsbereitstellung zwingend erforderlich, um sicherzustellen:

- **Authentifizierungsabläufe** korrekt mit SAML 2.0 funktionieren
- **eduGAIN-Attribute** korrekt empfangen und zugeordnet werden
- **Rollenbasierter Zugriff** basierend auf eduPersonAffiliation zugewiesen wird
- **Just-in-Time-Bereitstellung** Benutzer mit korrekten Profilen erstellt
- **Single Logout** korrekt über alle Dienste propagiert

---

### Testföderationsinformationen

#### DFN-AAI Testföderations-Endpunkte

| Umgebung | Zweck | URL |
|----------|-------|-----|
| Testföderation | Metadaten | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml` |
| Testföderation | Discovery-Service | `https://discovery.aai.dfn.de/` |
| Testföderation | Test-IdP | `https://idp.test.aai.dfn.de/` |
| Testföderation | Support | `support@aai.dfn.de` |

#### Testföderationsmerkmale

| Funktion | Testföderation | Produktion |
|----------|----------------|------------|
| Zertifikate | Selbstsigniert erlaubt | CA-signiert erforderlich |
| Metadaten-Aktualisierung | Manuell | Automatisch |
| Benutzerkonten | Testkonten verfügbar | Echte Institutionskonten |
| Attributfreigabe | Vorhersehbare Testwerte | Institutionsabhängig |
| Registrierungszeit | 1-2 Werktage | 3-5 Werktage |

---

### Voraussetzungen für Tests

#### Systemanforderungen

| Anforderung | Status | Hinweise |
|-------------|--------|----------|
| Keycloak bereitgestellt | ☐ | Version 22+ mit SAML 2.0-Unterstützung |
| SP in Testföderation registriert | ☐ | Siehe [DFN-AAI Registrierungshandbuch](./dfn-aai-registration.md) |
| SAML-Metadaten konfiguriert | ☐ | Entity ID passend zur Registrierung |
| Attribut-Mapper konfiguriert | ☐ | Siehe [eduGAIN-Attributzuordnung](./keycloak-edugain-attributes.md) |
| Realm-Rollen erstellt | ☐ | student, instructor, staff, etc. |
| DNS-Auflösung getestet | ☐ | Öffentliches DNS für Ihre Domain |

#### Browser-Werkzeuge

| Werkzeug | Zweck | Installation |
|----------|------|--------------|
| [SAML Tracer](https://addons.mozilla.org/de/firefox/addon/saml-tracer/) | SAML-Assertions inspizieren | Firefox-Add-on |
| Browser-Entwicklertools | Netzwerk-Debugging | Eingebaut (F12) |
| Cookie-Editor | Sitzungsinspektion | Browser-Erweiterung |

---

### Testbenutzerkonten

#### DFN-AAI Test-IdP-Benutzer

Die DFN-AAI-Testföderation stellt Testkonten mit vorhersehbaren Attributen bereit:

| Testbenutzer | eduPersonAffiliation | Erwartete Rolle | Hinweise |
|--------------|---------------------|-----------------|----------|
| `testuser1` | `faculty` | `instructor` | Lehrpersonal |
| `testuser2` | `staff` | `staff` | Verwaltungspersonal |
| `testuser3` | `student` | `student` | Studienbenutzer |
| `testuser4` | `member` | `member` | Einfaches Mitglied |
| `testuser5` | `affiliate` | `affiliate` | Externer Partner |

> **Hinweis:** Kontaktieren Sie den DFN-AAI-Support unter `support@aai.dfn.de` für aktuelle Testzugangsdaten und zusätzliche Testkonten.

#### Testattributwerte

Bei Verwendung von Testkonten erwarten Sie diese Attributwerte:

```
mail: testuser[N]@test.aai.dfn.de
displayName: Test User [N]
eduPersonPrincipalName: testuser[N]@test.aai.dfn.de
eduPersonAffiliation: [faculty|staff|student|member|affiliate]
eduPersonScopedAffiliation: [affiliation]@test.aai.dfn.de
```

---

### Testszenario 1: Authentifizierungsablauf

#### Ziel

Verifizieren, dass Benutzer sich über die DFN-AAI-Testföderation authentifizieren können und Keycloak die SAML-Assertion korrekt verarbeitet.

#### Testschritte

1. **Authentifizierung initiieren**

   ```bash
   # Browser zum Portal öffnen
   https://portal.education.example.org
   ```

2. **DFN-AAI-Identitätsanbieter auswählen**
   - Klicken Sie auf "Mit DFN-AAI (Test) anmelden" oder entsprechenden Button
   - Weiterleitung zum DFN-AAI-Discovery-Service verifizieren

3. **Test-IdP auswählen**
   - Wählen Sie "DFN-AAI Test IdP" aus der Liste
   - Weiterleitung zur Test-IdP-Anmeldeseite verifizieren

4. **Testzugangsdaten eingeben**
   - Benutzername: `testuser1`
   - Passwort: (vom DFN-AAI-Support erhalten)

5. **Authentifizierung abschließen**
   - Weiterleitung zurück zu Keycloak verifizieren
   - Weiterleitung zum Portal verifizieren
   - Angemeldeten Benutzer verifizieren

#### Erwartete Ergebnisse

| Prüfung | Erwartet | Bestanden/Fehler |
|---------|----------|------------------|
| Weiterleitung zum Discovery-Service | Ja | ☐ |
| Test-IdP auswählbar | Ja | ☐ |
| Anmeldung erfolgreich | Ja | ☐ |
| Weiterleitung zu Keycloak | Ja | ☐ |
| Weiterleitung zum Portal | Ja | ☐ |
| Benutzersitzung erstellt | Ja | ☐ |

#### SAML-Tracer-Verifizierung

Öffnen Sie SAML Tracer während der Authentifizierung und verifizieren Sie:

1. **AuthnRequest** an IdP gesendet
   - Enthält korrekte Entity ID
   - Enthält korrekte ACS-URL

2. **SAML-Assertion** empfangen
   - Korrekt signiert
   - Enthält erwartete Attribute
   - Subject-Bestätigung stimmt überein

3. **Attribut-Anweisung** enthält:

   ```xml
   <saml2:Attribute Name="urn:mace:dir:attribute-def:mail">
     <saml2:AttributeValue>testuser1@test.aai.dfn.de</saml2:AttributeValue>
   </saml2:Attribute>
   <saml2:Attribute Name="urn:mace:dir:attribute-def:eduPersonAffiliation">
     <saml2:AttributeValue>faculty</saml2:AttributeValue>
   </saml2:Attribute>
   ```

---

### Testszenario 2: Attribut-Assertions-Verifizierung

#### Ziel

Verifizieren, dass alle erforderlichen eduGAIN-Attribute empfangen und korrekt auf Keycloak-Benutzerattribute abgebildet werden.

#### Testschritte

1. **Als testuser1 authentifizieren**
   - Authentifizierungsablauf aus Szenario 1 abschließen
   - SAML-Assertions-ID für Referenz notieren

2. **SAML-Assertion erfassen**
   - SAML Tracer verwenden, um die Assertion zu erfassen
   - Vollständiges Assertion-XML exportieren/kopieren

3. **Empfangene Attribute verifizieren**

   | SAML-Attribut | Erwarteter Wert | Empfangen | Zugeordnet |
   |---------------|-----------------|-----------|------------|
   | `mail` | `testuser1@test.aai.dfn.de` | ☐ | ☐ |
   | `displayName` | `Test User 1` | ☐ | ☐ |
   | `eduPersonPrincipalName` | `testuser1@test.aai.dfn.de` | ☐ | ☐ |
   | `eduPersonAffiliation` | `faculty` | ☐ | ☐ |
   | `eduPersonScopedAffiliation` | `faculty@test.aai.dfn.de` | ☐ | ☐ |

4. **Keycloak-Benutzerattribute verifizieren**

   ```bash
   # Keycloak-Admin-Konsole aufrufen
   https://idp.education.example.org/admin/master/console/

   # Navigieren zu Benutzer → testuser1@test.aai.dfn.de → Attribute
   ```

5. **Attributzuordnung prüfen**

   | Keycloak-Attribut | Erwarteter Wert | Tatsächlich | Status |
   |-------------------|-----------------|-------------|--------|
   | `email` | `testuser1@test.aai.dfn.de` | | ☐ |
   | `firstName` | `Test` (oder voller displayName) | | ☐ |
   | `lastName` | `User 1` (falls geparst) | | ☐ |
   | `username` | `testuser1@test.aai.dfn.de` | | ☐ |
   | `affiliation` | `faculty` | | ☐ |

#### Fehlerbehebung fehlender Attribute

| Problem | Ursache | Lösung |
|---------|---------|--------|
| Attribut nicht in Assertion | IdP gibt nicht frei | IdP-Admin kontaktieren / Metadaten prüfen |
| Attribut in Assertion aber nicht zugeordnet | Mapper fehlt | Attribut-Mapper in Keycloak hinzufügen |
| Attribut falsch zugeordnet | Falscher Attributname | Mace vs OID-Format verifizieren |
| Mehrwertiges Attribut zeigt nur einen Wert | Mapper-Konfiguration | Mehrwert-Unterstützung aktivieren |

---

### Testszenario 3: Rollenzuordnungs-Validierung

#### Ziel

Verifizieren, dass eduPersonAffiliation-Werte korrekt in Keycloak-Realm-Rollen konvertiert werden.

#### Voraussetzungen

Stellen Sie sicher, dass diese Realm-Rollen in Keycloak existieren:

| Rolle | Beschreibung | Erforderlich |
|-------|--------------|--------------|
| `student` | Studentenzugriff | Ja |
| `instructor` | Lehrpersonal-Zugriff | Ja |
| `staff` | Verwaltungszugriff | Ja |
| `employee` | Mitarbeiterzugriff | Ja |
| `member` | Basis-Mitgliedszugriff | Ja |
| `affiliate` | Externer Partner-Zugriff | Ja |
| `alumni` | Alumni-Zugriff | Optional |
| `library` | Nur-Bibliothek-Zugriff | Optional |

#### Testmatrix

Testen Sie jeden Zugehörigkeitstyp:

##### Test 3.1: Faculty-Benutzer (testuser1)

| Schritt | Aktion | Erwartetes Ergebnis |
|---------|--------|---------------------|
| 1 | Als testuser1 anmelden | Authentifizierung erfolgreich |
| 2 | Benutzerrollen prüfen | `instructor`-Rolle zugewiesen |
| 3 | Zugriff verifizieren | Instructor-Level-Ressourcen zugänglich |

##### Test 3.2: Staff-Benutzer (testuser2)

| Schritt | Aktion | Erwartetes Ergebnis |
|---------|--------|---------------------|
| 1 | Als testuser2 anmelden | Authentifizierung erfolgreich |
| 2 | Benutzerrollen prüfen | `staff`-Rolle zugewiesen |
| 3 | Zugriff verifizieren | Staff-Level-Ressourcen zugänglich |

##### Test 3.3: Student-Benutzer (testuser3)

| Schritt | Aktion | Erwartetes Ergebnis |
|---------|--------|---------------------|
| 1 | Als testuser3 anmelden | Authentifizierung erfolgreich |
| 2 | Benutzerrollen prüfen | `student`-Rolle zugewiesen |
| 3 | Zugriff verifizieren | Student-Level-Ressourcen zugänglich |

#### Erwartete Rollenzuordnungsergebnisse

| Benutzer | eduPersonAffiliation | Erwartete Rollen |
|----------|---------------------|------------------|
| testuser1 | faculty | instructor |
| testuser2 | staff | staff |
| testuser3 | student | student |
| testuser4 | member | member |
| testuser5 | affiliate | affiliate |

---

### Testszenario 4: Just-in-Time-Bereitstellung

#### Ziel

Verifizieren, dass neue Benutzer bei der ersten Anmeldung automatisch mit korrekten Profilinformationen erstellt werden.

#### Testschritte

1. **Verifizieren, dass Benutzer nicht existiert**

   ```bash
   # Prüfen, dass Benutzer vor Test nicht existiert
   curl -s "https://idp.education.example.org/admin/realms/opendesk/users?username=testuser1@test.aai.dfn.de" \
     -H "Authorization: Bearer ${TOKEN}"
   # Sollte leeres Array zurückgeben: []
   ```

2. **Erstanmeldung durchführen**
   - Als testuser1 über DFN-AAI-Testföderation anmelden
   - Authentifizierungsablauf abschließen

3. **Benutzererstellung verifizieren**

   ```bash
   # Prüfen, dass Benutzer nach Anmeldung existiert
   curl -s "https://idp.education.example.org/admin/realms/opendesk/users?username=testuser1@test.aai.dfn.de" \
     -H "Authorization: Bearer ${TOKEN}"
   ```

4. **Benutzerprofil verifizieren**

   | Feld | Erwarteter Wert | Tatsächlich | Status |
   |------|-----------------|-------------|--------|
   | Benutzername | `testuser1@test.aai.dfn.de` | | ☐ |
   | E-Mail | `testuser1@test.aai.dfn.de` | | ☐ |
   | E-Mail verifiziert | `true` | | ☐ |
   | Vorname | `Test` | | ☐ |
   | Nachname | `User 1` | | ☐ |
   | Aktiviert | `true` | | ☐ |

5. **Föderationslink verifizieren**

   ```bash
   # Föderierten Identitätslink prüfen
   curl -s "https://idp.education.example.org/admin/realms/opendesk/users/${USER_ID}/federated-identity" \
     -H "Authorization: Bearer ${TOKEN}"
   # Sollte Link zu dfn-aai-test-Anbieter zeigen
   ```

#### JIT-Bereitstellungs-Checkliste

| Prüfung | Status |
|---------|--------|
| Benutzer bei Erstanmeldung erstellt | ☐ |
| Benutzername korrekt gesetzt | ☐ |
| E-Mail gesetzt und verifiziert | ☐ |
| Namensattribute ausgefüllt | ☐ |
| Föderationslink erstellt | ☐ |
| Rollen korrekt zugewiesen | ☐ |
| Benutzer standardmäßig aktiviert | ☐ |

---

### Testszenario 5: Logout-Propagation

#### Ziel

Verifizieren, dass Single Logout (SLO) Sitzungen über alle Dienste korrekt beendet.

#### Voraussetzungen

- Backchannel-Logout konfiguriert (siehe [Backchannel-Logout-Anleitung](./backchannel-logout.md))
- Alle Dienste unterstützen SAML-Logout

#### Testschritte

1. **Bei mehreren Diensten anmelden**
   - Über DFN-AAI am Portal anmelden
   - ILIAS aufrufen (authentifiziert verifizieren)
   - Moodle aufrufen (authentifiziert verifizieren)
   - Sitzungs-Cookies für jeden Dienst notieren

2. **Logout initiieren**
   - Im Portal auf Abmelden klicken
   - Oder navigieren zu: `https://portal.education.example.org/logout`

3. **Globales Logout verifizieren**
   - Weiterleitung zum DFN-AAI-Logout-Endpunkt verifizieren
   - Weiterleitung zurück zur Anwendung verifizieren

4. **Sitzungsbeendigung verifizieren**

   | Dienst | Sitzung beendet | Status |
   |--------|-----------------|--------|
   | Keycloak | Ja | ☐ |
   | Portal | Ja | ☐ |
   | ILIAS | Ja | ☐ |
   | Moodle | Ja | ☐ |
   | BigBlueButton | Ja | ☐ |
   | Nextcloud/OpenCloud | Ja | ☐ |

5. **Erneute Authentifizierung erforderlich verifizieren**
   - Versuchen, jeden Dienst aufzurufen
   - Weiterleitung zur Anmeldeseite verifizieren

---

### Umfassende Test-Checkliste

Verwenden Sie diese Checkliste, um den gesamten Testfortschritt zu verfolgen:

#### Authentifizierungstests

| Test | Beschreibung | Status |
|------|--------------|--------|
| AUTH-01 | Basisanmeldung über Test-IdP | ☐ |
| AUTH-02 | Anmeldung mit Faculty-Konto | ☐ |
| AUTH-03 | Anmeldung mit Staff-Konto | ☐ |
| AUTH-04 | Anmeldung mit Student-Konto | ☐ |
| AUTH-05 | Anmeldung mit Member-Konto | ☐ |
| AUTH-06 | Anmeldung mit Affiliate-Konto | ☐ |
| AUTH-07 | Behandlung fehlgeschlagener Anmeldung | ☐ |
| AUTH-08 | Sitzungs-Timeout-Behandlung | ☐ |

#### Attributtests

| Test | Beschreibung | Status |
|------|--------------|--------|
| ATTR-01 | Mail-Attribut empfangen | ☐ |
| ATTR-02 | DisplayName-Attribut empfangen | ☐ |
| ATTR-03 | eduPersonPrincipalName empfangen | ☐ |
| ATTR-04 | eduPersonAffiliation empfangen | ☐ |
| ATTR-05 | eduPersonScopedAffiliation empfangen | ☐ |
| ATTR-06 | Mehrwertige Affiliations | ☐ |
| ATTR-07 | Attributzuordnung zu Keycloak | ☐ |

#### Rollenzuordnungstests

| Test | Beschreibung | Status |
|------|--------------|--------|
| ROLE-01 | Faculty → Instructor-Zuordnung | ☐ |
| ROLE-02 | Staff → Staff-Zuordnung | ☐ |
| ROLE-03 | Student → Student-Zuordnung | ☐ |
| ROLE-04 | Member → Member-Zuordnung | ☐ |
| ROLE-05 | Affiliate → Affiliate-Zuordnung | ☐ |
| ROLE-06 | Mehrfach-Rollenzuweisung | ☐ |
| ROLE-07 | Rollenbasierte Zugriffskontrolle | ☐ |

#### Bereitstellungstests

| Test | Beschreibung | Status |
|------|--------------|--------|
| PROV-01 | Ersterstellung des Benutzers | ☐ |
| PROV-02 | Benutzerprofil-Ausfüllung | ☐ |
| PROV-03 | Föderationslink-Erstellung | ☐ |
| PROV-04 | Wiedererkennung bei nachfolgender Anmeldung | ☐ |
| PROV-05 | Attributsynchronisation bei Anmeldung | ☐ |

#### Logout-Tests

| Test | Beschreibung | Status |
|------|--------------|--------|
| LOGOUT-01 | Portal-Logout | ☐ |
| LOGOUT-02 | ILIAS-Sitzungsbeendigung | ☐ |
| LOGOUT-03 | Moodle-Sitzungsbeendigung | ☐ |
| LOGOUT-04 | BigBlueButton-Sitzungsbeendigung | ☐ |
| LOGOUT-05 | Backchannel-Logout-Propagation | ☐ |
| LOGOUT-06 | Frontchannel-Logout-Propagation | ☐ |

---

### Fehlerbehebungsleitfaden

#### Authentifizierung fehlgeschlagen

| Symptom | Mögliche Ursache | Lösung |
|---------|------------------|--------|
| "Kein IdP gefunden" | Metadaten nicht geladen | DFN-AAI-Testmetadaten neu importieren |
| "Ungültige Signatur" | Zertifikatsabweichung | SP-Zertifikat in Keycloak verifizieren |
| "ACS-URL-Abweichung" | Falscher Endpunkt | Assertion Consumer Service URL prüfen |
| Weiterleitungsschleife | Fehlkonfigurierte Weiterleitung | Gültige Weiterleitungs-URIs in Keycloak prüfen |
| Timeout | Netzwerkkonnektivität | Firewall-Regeln prüfen |

#### Attribute fehlen

| Symptom | Mögliche Ursache | Lösung |
|---------|------------------|--------|
| Keine Attribute in Assertion | IdP gibt nicht frei | IdP-Attributfreigaberichtlinie prüfen |
| Attribute in Assertion aber nicht zugeordnet | Mapper fehlt | Attribut-Mapper hinzufügen |
| Falsche Attributwerte | Mapper-Fehlkonfiguration | Attributnamensformat prüfen |
| Teilweise Attribute | Einige Mapper fehlerhaft | Mapper-Ausführungsreihenfolge prüfen |

#### Rollenzuweisung fehlgeschlagen

| Symptom | Mögliche Ursache | Lösung |
|---------|------------------|--------|
| Keine Rollen zugewiesen | Rollen-Mapper fehlt | Rollenimport-Mapper hinzufügen |
| Falsche Rollen | Zuordnungslogikfehler | Rollenzuordnungsskript prüfen |
| Rollen im Realm fehlen | Rollen nicht erstellt | Realm-Rollen zuerst erstellen |
| Doppelte Rollenfehler | Rolle bereits zugewiesen | Idempotente Rollenzuweisung verwenden |

#### Logout-Probleme

| Symptom | Mögliche Ursache | Lösung |
|---------|------------------|--------|
| Sitzung nicht beendet | SLO nicht unterstützt | Backchannel-Logout aktivieren |
| Teilweises Logout | Einige SPs nicht benachrichtigt | Alle SP-Konfigurationen prüfen |
| Logout-Schleife | Fehlkonfigurierte Endpunkte | SingleLogoutService-URLs verifizieren |
| Timeout bei Logout | Netzwerkprobleme | Backchannel-Konnektivität prüfen |

---

### Testnachweiserhebung

Sammeln Sie während des Testens folgende Nachweise:

#### Erforderliche Nachweisdateien

| Datei | Inhalt | Speicherort |
|-------|--------|-------------|
| `task-5-auth-test.log` | Authentifizierungstestergebnisse | `.sisyphus/evidence/` |
| `task-5-attributes.log` | Attribut-Assertions-Verifizierung | `.sisyphus/evidence/` |
| `task-5-roles.log` | Rollenzuordnungs-Validierung | `.sisyphus/evidence/` |
| `task-5-logout.log` | Logout-Propagationstest | `.sisyphus/evidence/` |

---

### Zusätzliche Ressourcen

- **DFN-AAI Testföderation:** <https://www.aai.dfn.de/testumgebung/>
- **DFN-AAI-Support:** [support@aai.dfn.de](mailto:support@aai.dfn.de)
- **eduGAIN Technisches Profil:** <https://technical.edugain.org/>
- **Keycloak SAML-Dokumentation:** <https://www.keycloak.org/docs/latest/server_admin/#saml-identity-providers>
- **SAML Tracer:** <https://addons.mozilla.org/de/firefox/addon/saml-tracer/>

---

**Verwandte Dokumentation:**

- [DFN-AAI Service Provider Registration Guide](./dfn-aai-registration.md)
- [eduGAIN Attribute Mapping for Keycloak](./keycloak-edugain-attributes.md)
- [Backchannel Logout Guide](./backchannel-logout.md)
- [Shibboleth IdP Integration](./shibboleth-idp-integration.md)

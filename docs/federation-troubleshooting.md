<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Federation Troubleshooting Guide / Föderations-Fehlersuche

[English](#english) | [Deutsch](#deutsch)

---

<a name="english"></a>

## English

This guide provides solutions for common issues when configuring DFN-AAI / eduGAIN federation support in openDesk Edu.

---

### Table of Contents

1. [Metadata Generation Issues](#metadata-issues)
2. [Authentication Failures](#auth-failures)
3. [Attribute Mapping Problems](#attribute-problems)
4. [Certificate Issues](#cert-issues)
5. [Network & Connectivity](#network-issues)
6. [Role Assignment Problems](#role-problems)
7. [Session & Logout Issues](#session-issues)

---

### Metadata Generation Issues {#metadata-issues}

#### Problem: Metadata generation fails with "Config file not found"

**Symptoms:**

```bash
$ python3 saml-metadata-generator.py -c config.yaml -e dev
Error: Configuration file not found: config.yaml
```

**Solution:**

1. Ensure you copied the example config:

   ```bash
   cp scripts/saml-metadata-generator/saml-metadata-generator-config.yaml.example \
      scripts/saml-metadata-generator/saml-metadata-generator-config.yaml
   ```

2. Verify the file exists:

   ```bash
   ls -la scripts/saml-metadata-generator/saml-metadata-generator-config.yaml
   ```

3. Run from the correct directory or use absolute path:

   ```bash
   python3 scripts/saml-metadata-generator/saml-metadata-generator.py \
     -c /absolute/path/to/config.yaml -e dev
   ```

---

#### Problem: Metadata XML validation fails

**Symptoms:**

```bash
$ xmllint --noout metadata.xml
metadata.xml:45: error: Element '{...}EntityDescriptor': Invalid content.
```

**Solution:**

1. Check that all required fields are present in config:
   - `organization.name`
   - `organization.url`
   - `contacts` array with at least one technical contact
   - `environments.dev.entityId`
2. Verify certificate paths are correct:

   ```bash
   ls -la /etc/certs/saml-sp-signing.crt
   ```

3. Ensure certificates are in PEM format:

   ```bash
   head -1 /etc/certs/saml-sp-signing.crt
   # Should output: -----BEGIN CERTIFICATE-----
   ```

---

#### Problem: Metadata doesn't contain required DFN-AAI attributes

**Symptoms:**

- DFN-AAI registration rejected
- Missing attributes in generated metadata XML

**Solution:**

1. Check `requested_attributes` section in config:

   ```yaml
   requested_attributes:
     - name: mail
       required: true
     - name: displayName
       required: true
     - name: eduPersonPrincipalName
       required: true
     - name: eduPersonAffiliation
       required: true
     - name: eduPersonTargetedID
       required: true
   ```

2. Regenerate metadata:

   ```bash
   python3 scripts/saml-metadata-generator/saml-metadata-generator.py \
     -c config.yaml -e dev -o metadata.xml
   ```

3. Verify attributes are present:

   ```bash
   grep -A 3 "AttributeConsumingService" metadata.xml
   ```

---

### Authentication Failures {#auth-failures}

#### Problem: "Invalid SAML response" error

**Symptoms:**

- Users see "Invalid SAML response" when logging in
- Keycloak logs show: `Invalid SAML assertion`

**Solution:**

1. Check system time synchronization:

   ```bash
   timedatectl status
   # NTP should be active
   ```

2. Verify certificate validity:

   ```bash
   openssl x509 -in /etc/certs/saml-sp-signing.crt -noout -dates
   ```

3. Check Keycloak IdP configuration:

   ```bash
   kcadm.sh get identity-provider/instances/dfn-aai -r opendesk
   ```

4. Verify metadata URL is accessible:

   ```bash
    curl -I https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml
    # Should return HTTP 200
   ```

---

#### Problem: "User not found" on first login

**Symptoms:**

- First-time federation users cannot log in
- Keycloak logs: `Could not find user with attribute...`

**Solution:**

1. Check that user provisioning is enabled:

   ```bash
   kcadm.sh get identity-provider/instances/dfn-aai -r opendesk -q enabled=true
   ```

2. Verify attribute mappers are configured:

   ```bash
   kcadm.sh list identity-provider/instances/dfn-aai/mappers -r opendesk
   ```

3. Check that required attributes are being received:
   - Enable Keycloak debug logging
   - Check SAML assertion contents
4. Ensure `eduPersonTargetedID` mapper is configured correctly

---

#### Problem: Discovery service not showing

**Symptoms:**

- No institution selector appears
- Login redirects directly to wrong IdP

**Solution:**

1. Check federation discovery URL in config:

   ```bash
   grep discoveryUrl helmfile/environments/default/federation.yaml.gotmpl
   ```

2. Verify discovery service is enabled in Keycloak:

   ```bash
   kcadm.sh get identity-provider/instances/dfn-aai -r opendesk | grep -i discovery
   ```

3. Clear browser cache and cookies
4. Check browser console for JavaScript errors

---

### Attribute Mapping Problems {#attribute-problems}

#### Problem: Email not mapped correctly

**Symptoms:**

- User email is empty or incorrect
- Account creation fails due to missing email

**Solution:**

1. Check email mapper configuration:

   ```bash
   kcadm.sh get identity-provider/instances/dfn-aai/mappers -r opendesk \
     -q name=email-mapper
   ```

2. Verify attribute name matches DFN-AAI spec:

   ```json
   {
     "config": {
       "attribute": "urn:mace:dir:attribute-def:mail",
       "user.attribute": "email"
     }
   }
   ```

3. Test with SAML Tracer browser extension to see actual attributes
4. Check IdP is sending the attribute

---

#### Problem: eduPersonAffiliation not received

**Symptoms:**

- Users have no roles assigned
- Affiliation mapper shows no data

**Solution:**

1. Check IdP is configured to release eduPersonAffiliation
2. Verify attribute URN is correct:

   ```bash
   kcadm.sh get identity-provider/instances/dfn-aai/mappers -r opendesk \
     -q name=affiliation-mapper
   # Should show: "attribute": "urn:mace:dir:attribute-def:eduPersonAffiliation"
   ```

3. Contact IdP administrator to verify attribute release policy
4. Check DFN-AAI metadata for attribute requirements

---

#### Problem: Multiple affiliations cause issues

**Symptoms:**

- User has conflicting roles
- Role assignment fails or is inconsistent

**Solution:**

1. Check role mapper handles arrays:

   ```javascript
   // Verify role mapper script handles multiple affiliations
   var affiliation = user.getAttribute('affiliation');
   if (!affiliation) {
       affiliation = [];
   }
   ```

2. Review role assignment logic in `saml-role-mapper.js`
3. Consider implementing primary affiliation preference
4. Test with multi-affiliation test users

---

### Certificate Issues {#cert-issues}

#### Problem: "Certificate expired" error

**Symptoms:**

- All federation logins fail
- Keycloak logs: `Certificate has expired`

**Solution:**

1. Check certificate expiration:

   ```bash
   openssl x509 -in /etc/certs/saml-sp-signing.crt -noout -enddate
   ```

2. Generate new certificate:

   ```bash
   openssl req -newkey rsa:2048 -nodes -keyout saml-sp-signing.key \
     -out saml-sp-signing.crt -days 365 -x509
   ```

3. Update certificate in Keycloak:

   ```bash
   kcadm.sh update identity-provider/instances/dfn-aai -r opendesk \
     -s 'config.publicCert="new-cert-data"'
   ```

4. Regenerate SP metadata with new certificate

---

#### Problem: "Invalid signature" on SAML messages

**Symptoms:**

- SAML assertions rejected
- Error: `Signature validation failed`

**Solution:**

1. Verify signature algorithm matches:
   - DFN-AAI requires RSA-SHA256 or stronger
2. Check certificate chain is complete
3. Ensure both SP and IdP use compatible algorithms:

   ```json
   {
     "config": {
       "signatureAlgorithm": "RSA_SHA256"
     }
   }
   ```

4. Check system time (clock skew can cause signature failures)

---

### Network & Connectivity {#network-issues}

#### Problem: Cannot reach IdP metadata URL

**Symptoms:**

- Metadata download fails
- Error: `Connection timeout`

**Solution:**

1. Check firewall rules:

   ```bash
   sudo iptables -L -n | grep 443
   ```

2. Test connectivity:

   ```bash
    curl -v https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml
   ```

3. Check DNS resolution:

   ```bash
   nslookup www.aai.dfn.de
   ```

4. Verify proxy settings if behind corporate firewall

---

#### Problem: SAML assertion timeout

**Symptoms:**

- Login takes too long
- "Assertion expired" error

**Solution:**

1. Check network latency to IdP
2. Verify IdP response time
3. Increase timeout in Keycloak config if needed
4. Consider caching IdP metadata locally

---

### Role Assignment Problems {#role-problems}

#### Problem: User gets wrong roles

**Symptoms:**

- Student gets instructor role
- Faculty gets student role

**Solution:**

1. Check affiliation value from IdP:
   - Use SAML Tracer to see actual attribute value
2. Verify role mapper mapping logic:

   ```javascript
   switch (aff.toLowerCase()) {
       case 'faculty':
       case 'teacher':
           rolesToGrant.push('instructor');
           break;
       // ...
   }
   ```

3. Ensure role names match Keycloak realm roles
4. Check for case sensitivity issues

---

#### Problem: Roles not granted on first login

**Symptoms:**

- User created but no roles assigned
- Role mapper script doesn't execute

**Solution:**

1. Verify role mapper is attached to IdP:

   ```bash
   kcadm.sh get identity-provider/instances/dfn-aai/mappers -r opendesk \
     -q name=role-mapper
   ```

2. Check mapper type is "script"
3. Ensure script has correct permissions
4. Review Keycloak logs for script errors

---

### Session & Logout Issues {#session-issues}

#### Problem: Session persists after logout

**Symptoms:**

- User logs out but can still access services
- Back button shows logged-in state

**Solution:**

1. Check backchannel logout is enabled
2. Verify session timeout settings
3. Clear browser cache and cookies
4. Check service-specific session configuration

---

#### Problem: Logout fails for some services

**Symptoms:**

- Portal logs out but Moodle still active
- Incomplete logout chain

**Solution:**

1. Check each service's SLO endpoint
2. Verify logout request is being sent
3. Check service logs for logout errors
4. Review network connectivity to services

---

### Quick Reference Commands

```bash
# Check Keycloak IdP status
kcadm.sh get identity-provider/instances/dfn-aai -r opendesk

# List all mappers
kcadm.sh list identity-provider/instances/dfn-aai/mappers -r opendesk

# Test metadata URL
curl -I https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml

# Check certificate validity
openssl x509 -in /etc/certs/saml-sp-signing.crt -noout -dates

# Validate metadata XML
xmllint --noout metadata.xml

# Test SAML assertion (requires SAML Tracer extension)
# Install: https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/
```

---

### Getting Help

If you cannot resolve an issue:

1. **Check DFN-AAI Support**: Email `support@aai.dfn.de`
2. **Review Logs**: Check Keycloak, service, and system logs
3. **Test with Test Federation**: Always test with DFN-AAI test federation first
4. **Use SAML Tracer**: Capture and analyze SAML messages
5. **Community**: Ask in openDesk Edu community channels

---

<a name="deutsch"></a>

## Deutsch

Diese Anleitung bietet Lösungen für häufige Probleme bei der Konfiguration der DFN-AAI / eduGAIN-Föderation in openDesk Edu.

---

### Inhaltsverzeichnis

1. [Metadatengenerierungs-Probleme](#metadata-issues)
2. [Authentifizierungsfehler](#auth-failures)
3. [Attribut-Mapping-Probleme](#attribute-problems)
4. [Zertifikatsprobleme](#cert-issues)
5. [Netzwerk & Konnektivität](#network-issues)
6. [Rollen-Zuordnungsprobleme](#role-problems)
7. [Sitzungs- und Abmeldeprobleme](#session-issues)

---

### Metadatengenerierungs-Probleme {#metadata-issues}

#### Problem: Metadatengenerierung schlägt fehl mit „Konfigurationsdatei nicht gefunden"

**Symptome:**

```bash
$ python3 saml-metadata-generator.py -c config.yaml -e dev
Error: Configuration file not found: config.yaml
```

**Lösung:**

1. Stellen Sie sicher, dass Sie die Beispielkonfiguration kopiert haben:

   ```bash
   cp scripts/saml-metadata-generator/saml-metadata-generator-config.yaml.example \
      scripts/saml-metadata-generator/saml-metadata-generator-config.yaml
   ```

2. Überprüfen Sie, ob die Datei existiert:

   ```bash
   ls -la scripts/saml-metadata-generator/saml-metadata-generator-config.yaml
   ```

3. Führen Sie den Befehl aus dem korrekten Verzeichnis aus oder verwenden Sie einen absoluten Pfad:

   ```bash
   python3 scripts/saml-metadata-generator/saml-metadata-generator.py \
     -c /absoluter/pfad/zur/config.yaml -e dev
   ```

---

#### Problem: Metadaten-XML-Validierung schlägt fehl

**Symptome:**

```bash
$ xmllint --noout metadata.xml
metadata.xml:45: error: Element '{...}EntityDescriptor': Invalid content.
```

**Lösung:**

1. Prüfen Sie, ob alle Pflichtfelder in der Konfiguration vorhanden sind:
   - `organization.name`
   - `organization.url`
   - `contacts`-Array mit mindestens einem technischen Kontakt
   - `environments.dev.entityId`
2. Überprüfen Sie die Zertifikatspfade:

   ```bash
   ls -la /etc/certs/saml-sp-signing.crt
   ```

3. Stellen Sie sicher, dass die Zertifikate im PEM-Format vorliegen:

   ```bash
   head -1 /etc/certs/saml-sp-signing.crt
   # Sollte ausgeben: -----BEGIN CERTIFICATE-----
   ```

---

#### Problem: Metadaten enthalten nicht die erforderlichen DFN-AAI-Attribute

**Symptome:**

- DFN-AAI-Registrierung abgelehnt
- Fehlende Attribute in der generierten Metadaten-XML

**Lösung:**

1. Prüfen Sie den Abschnitt `requested_attributes` in der Konfiguration:

   ```yaml
   requested_attributes:
     - name: mail
       required: true
     - name: displayName
       required: true
     - name: eduPersonPrincipalName
       required: true
     - name: eduPersonAffiliation
       required: true
     - name: eduPersonTargetedID
       required: true
   ```

2. Generieren Sie die Metadaten neu:

   ```bash
   python3 scripts/saml-metadata-generator/saml-metadata-generator.py \
     -c config.yaml -e dev -o metadata.xml
   ```

3. Überprüfen Sie, ob die Attribute vorhanden sind:

   ```bash
   grep -A 3 "AttributeConsumingService" metadata.xml
   ```

---

### Authentifizierungsfehler {#auth-failures}

#### Problem: Fehler „Ungültige SAML-Antwort"

**Symptome:**

- Benutzer sehen „Ungültige SAML-Antwort" bei der Anmeldung
- Keycloak-Protokolle zeigen: `Invalid SAML assertion`

**Lösung:**

1. Überprüfen Sie die Zeitsynchronisation des Systems:

   ```bash
   timedatectl status
   # NTP sollte aktiv sein
   ```

2. Überprüfen Sie die Zertifikatsgültigkeit:

   ```bash
   openssl x509 -in /etc/certs/saml-sp-signing.crt -noout -dates
   ```

3. Prüfen Sie die Keycloak-IdP-Konfiguration:

   ```bash
   kcadm.sh get identity-provider/instances/dfn-aai -r opendesk
   ```

4. Überprüfen Sie, ob die Metadaten-URL erreichbar ist:

   ```bash
   curl -I https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml
   # Sollte HTTP 200 zurückgeben
   ```

---

#### Problem: „Benutzer nicht gefunden" bei erster Anmeldung

**Symptome:**

- Erstanmeldung von Föderationsbenutzern schlägt fehl
- Keycloak-Protokolle: `Could not find user with attribute...`

**Lösung:**

1. Prüfen Sie, ob die Benutzerbereitstellung aktiviert ist:

   ```bash
   kcadm.sh get identity-provider/instances/dfn-aai -r opendesk -q enabled=true
   ```

2. Überprüfen Sie, ob Attribut-Mapper konfiguriert sind:

   ```bash
   kcadm.sh list identity-provider/instances/dfn-aai/mappers -r opendesk
   ```

3. Prüfen Sie, ob die erforderlichen Attribute empfangen werden:
   - Aktivieren Sie das Keycloak-Debug-Logging
   - Überprüfen Sie den Inhalt der SAML-Assertion
4. Stellen Sie sicher, dass der `eduPersonTargetedID`-Mapper korrekt konfiguriert ist

---

#### Problem: Discovery-Service wird nicht angezeigt

**Symptome:**

- Kein Institutionsauswähler erscheint
- Anmeldung leitet direkt zum falschen IdP weiter

**Lösung:**

1. Prüfen Sie die Föderations-Discovery-URL in der Konfiguration:

   ```bash
   grep discoveryUrl helmfile/environments/default/federation.yaml.gotmpl
   ```

2. Überprüfen Sie, ob der Discovery-Service in Keycloak aktiviert ist:

   ```bash
   kcadm.sh get identity-provider/instances/dfn-aai -r opendesk | grep -i discovery
   ```

3. Leeren Sie den Browser-Cache und die Cookies
4. Prüfen Sie die Browserkonsole auf JavaScript-Fehler

---

### Attribut-Mapping-Probleme {#attribute-problems}

#### Problem: E-Mail nicht korrekt gemappt

**Symptome:**

- Benutzer-E-Mail ist leer oder falsch
- Kontoerstellung schlägt fehl aufgrund fehlender E-Mail

**Lösung:**

1. Prüfen Sie die E-Mail-Mapper-Konfiguration:

   ```bash
   kcadm.sh get identity-provider/instances/dfn-aai/mappers -r opendesk \
     -q name=email-mapper
   ```

2. Überprüfen Sie, ob der Attributname der DFN-AAI-Spezifikation entspricht:

   ```json
   {
     "config": {
       "attribute": "urn:mace:dir:attribute-def:mail",
       "user.attribute": "email"
     }
   }
   ```

3. Testen Sie mit der SAML-Tracer-Browsererweiterung, um die tatsächlichen Attribute zu sehen
4. Prüfen Sie, ob der IdP das Attribut sendet

---

#### Problem: eduPersonAffiliation nicht empfangen

**Symptome:**

- Benutzer haben keine Rollen zugewiesen
- Zugehörigkeits-Mapper zeigt keine Daten

**Lösung:**

1. Prüfen Sie, ob der IdP so konfiguriert ist, dass er eduPersonAffiliation freigibt
2. Überprüfen Sie die Attribut-URN:

   ```bash
   kcadm.sh get identity-provider/instances/dfn-aai/mappers -r opendesk \
     -q name=affiliation-mapper
   # Sollte anzeigen: "attribute": "urn:mace:dir:attribute-def:eduPersonAffiliation"
   ```

3. Kontaktieren Sie den IdP-Administrator, um die Attributfreigaberichtlinie zu überprüfen
4. Prüfen Sie die DFN-AAI-Metadaten auf Attributanforderungen

---

#### Problem: Mehrere Zugehörigkeiten verursachen Probleme

**Symptome:**

- Benutzer hat widersprüchliche Rollen
- Rollenzuweisung schlägt fehl oder ist inkonsistent

**Lösung:**

1. Prüfen Sie, ob der Rollen-Mapper Arrays verarbeitet:

   ```javascript
   // Überprüfen Sie, ob der Rollen-Mapper mehrere Zugehörigkeiten verarbeitet
   var affiliation = user.getAttribute('affiliation');
   if (!affiliation) {
       affiliation = [];
   }
   ```

2. Überprüfen Sie die Rollenzuweisungslogik in `saml-role-mapper.js`
3. Erwägen Sie die Implementierung einer bevorzugten primären Zugehörigkeit
4. Testen Sie mit Benutzern mit mehreren Zugehörigkeiten

---

### Zertifikatsprobleme {#cert-issues}

#### Problem: Fehler „Zertifikat abgelaufen"

**Symptome:**

- Alle Föderationsanmeldungen schlagen fehl
- Keycloak-Protokolle: `Certificate has expired`

**Lösung:**

1. Prüfen Sie das Zertifikatsablaufdatum:

   ```bash
   openssl x509 -in /etc/certs/saml-sp-signing.crt -noout -enddate
   ```

2. Generieren Sie ein neues Zertifikat:

   ```bash
   openssl req -newkey rsa:2048 -nodes -keyout saml-sp-signing.key \
     -out saml-sp-signing.crt -days 365 -x509
   ```

3. Aktualisieren Sie das Zertifikat in Keycloak:

   ```bash
   kcadm.sh update identity-provider/instances/dfn-aai -r opendesk \
     -s 'config.publicCert="neue-zertifikatsdaten"'
   ```

4. Generieren Sie die SP-Metadaten mit dem neuen Zertifikat neu

---

#### Problem: „Ungültige Signatur" bei SAML-Nachrichten

**Symptome:**

- SAML-Assertions abgelehnt
- Fehler: `Signature validation failed`

**Lösung:**

1. Überprüfen Sie, ob der Signaturalgorithmus übereinstimmt:
   - DFN-AAI erfordert RSA-SHA256 oder stärker
2. Prüfen Sie, ob die Zertifikatskette vollständig ist
3. Stellen Sie sicher, dass SP und IdP kompatible Algorithmen verwenden:

   ```json
   {
     "config": {
       "signatureAlgorithm": "RSA_SHA256"
     }
   }
   ```

4. Überprüfen Sie die Systemzeit (Zeitabweichung kann Signaturfehler verursachen)

---

### Netzwerk & Konnektivität {#network-issues}

#### Problem: IdP-Metadaten-URL nicht erreichbar

**Symptome:**

- Metadaten-Download schlägt fehl
- Fehler: `Connection timeout`

**Lösung:**

1. Prüfen Sie die Firewall-Regeln:

   ```bash
   sudo iptables -L -n | grep 443
   ```

2. Testen Sie die Konnektivität:

   ```bash
   curl -v https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml
   ```

3. Prüfen Sie die DNS-Auflösung:

   ```bash
   nslookup www.aai.dfn.de
   ```

4. Überprüfen Sie die Proxy-Einstellungen, falls sich das System hinter einer Corporate-Firewall befindet

---

#### Problem: SAML-Assertion-Timeout

**Symptome:**

- Anmeldung dauert zu lange
- Fehler „Assertion abgelaufen"

**Lösung:**

1. Prüfen Sie die Netzwerklatenz zum IdP
2. Überprüfen Sie die IdP-Antwortzeit
3. Erhöhen Sie gegebenenfalls das Timeout in der Keycloak-Konfiguration
4. Erwägen Sie das lokale Caching der IdP-Metadaten

---

### Rollen-Zuordnungsprobleme {#role-problems}

#### Problem: Benutzer erhält falsche Rollen

**Symptome:**

- Studierende erhalten Dozentenrolle
- Lehrende erhalten Studentenrolle

**Lösung:**

1. Prüfen Sie den Zugehörigkeitswert vom IdP:
   - Verwenden Sie SAML Tracer, um den tatsächlichen Attributwert zu sehen
2. Überprüfen Sie die Rollen-Mapper-Zuordnungslogik:

   ```javascript
   switch (aff.toLowerCase()) {
       case 'faculty':
       case 'teacher':
           rolesToGrant.push('instructor');
           break;
       // ...
   }
   ```

3. Stellen Sie sicher, dass die Rollennamen mit den Keycloak-Realm-Rollen übereinstimmen
4. Prüfen Sie auf Probleme mit Groß-/Kleinschreibung

---

#### Problem: Rollen bei erster Anmeldung nicht zugewiesen

**Symptome:**

- Benutzer erstellt, aber keine Rollen zugewiesen
- Rollen-Mapper-Skript wird nicht ausgeführt

**Lösung:**

1. Überprüfen Sie, ob der Rollen-Mapper an den IdP angebunden ist:

   ```bash
   kcadm.sh get identity-provider/instances/dfn-aai/mappers -r opendesk \
     -q name=role-mapper
   ```

2. Prüfen Sie, ob der Mapper-Typ „script" ist
3. Stellen Sie sicher, dass das Skript die korrekten Berechtigungen hat
4. Überprüfen Sie die Keycloak-Protokolle auf Skriptfehler

---

### Sitzungs- und Abmeldeprobleme {#session-issues}

#### Problem: Sitzung bleibt nach Abmeldung bestehen

**Symptome:**

- Benutzer meldet sich ab, kann aber weiterhin auf Dienste zugreifen
- Zurück-Button zeigt angemeldeten Zustand

**Lösung:**

1. Prüfen Sie, ob Backchannel-Abmeldung aktiviert ist
2. Überprüfen Sie die Sitzungs-Timeout-Einstellungen
3. Leeren Sie den Browser-Cache und die Cookies
4. Prüfen Sie die dienstspezifische Sitzungskonfiguration

---

#### Problem: Abmeldung schlägt für einige Dienste fehl

**Symptome:**

- Portal meldet sich ab, aber Moodle bleibt aktiv
- Unvollständige Abmeldekette

**Lösung:**

1. Prüfen Sie den SLO-Endpunkt jedes Dienstes
2. Überprüfen Sie, ob die Abmeldeanforderung gesendet wird
3. Prüfen Sie die Dienstprotokolle auf Abmeldefehler
4. Überprüfen Sie die Netzwerkkonnektivität zu den Diensten

---

### Schnellreferenz-Befehle

```bash
# Keycloak-IdP-Status prüfen
kcadm.sh get identity-provider/instances/dfn-aai -r opendesk

# Alle Mapper auflisten
kcadm.sh list identity-provider/instances/dfn-aai/mappers -r opendesk

# Metadaten-URL testen
curl -I https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml

# Zertifikatsgültigkeit prüfen
openssl x509 -in /etc/certs/saml-sp-signing.crt -noout -dates

# Metadaten-XML validieren
xmllint --noout metadata.xml

# SAML-Assertion testen (erfordert SAML-Tracer-Erweiterung)
# Installieren: https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/
```

---

### Hilfe erhalten

Wenn Sie ein Problem nicht lösen können:

1. **DFN-AAI-Support kontaktieren**: E-Mail an `support@aai.dfn.de`
2. **Protokolle überprüfen**: Keycloak-, Dienst- und Systemprotokolle prüfen
3. **Mit Testföderation testen**: Immer zuerst mit der DFN-AAI-Testföderation testen
4. **SAML Tracer verwenden**: SAML-Nachrichten erfassen und analysieren
5. **Community**: In den openDesk Edu-Community-Kanälen nachfragen

---

*Zuletzt aktualisiert: 2026-04-12*

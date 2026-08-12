<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Technische und Organisatorische Maßnahmen (TOM)
## openDesk Edu – Kubernetes-Cluster im Rechenzentrum einer Bildungseinrichtung

> **⚠️ Rechtlicher Hinweis / Legal Disclaimer**
>
> Dieses Dokument ist **keine rechtlich geprüfte Vorlage**. Es dient ausschließlich als **Beispiel / Template** und ist auf die spezifischen Bedürfnisse und rechtlichen Anforderungen der jeweiligen Institution anzupassen.
>
> Es wird ausdrücklich empfohlen, die Einrichtung der Rechtsabteilung (Rechtsberatung / Datenschutzbeauftragter) vor deren Verwendung zur Prüfung und Validierung vorzulegen.
>
> Die openDesk-Edu-Community übernimmt keine Haftung für die rechtliche Korrektheit, Vollständigkeit oder Eignung dieses Dokuments für konkrete Einsatzzwecke.
>
> ---
>
> **⚠️ Hinweis zur Anonymisierung**
> Diese Fassung wurde für die öffentliche Bereitstellung im openDesk-Edu-Repository erstellt.
> Alle organisationsspezifischen Angaben (Name der Einrichtung, Standort, Kontaktdaten, interne Systeme,
> Netzwerk-Kennungen, Personenzahlen) wurden entfernt oder durch Platzhalter ersetzt.
>
> Serve dient als **Vorlage**, die von Bildungseinrichtungen an die eigene Organisation angepasst werden muss.
> Alle Werte in `[eckigen Klammern]` sind Platzhalter und vor Verwendung zu ersetzen.

---

**Verantwortlich:**
[Name der Bildungseinrichtung] – Rechenzentrum (RZ)

**Datum:** [TT.MM.JJJJ]
**Version:** 1.0 – anonymisierte Vorlage
**Gültig für:** openDesk Edu auf einem Kubernetes-Cluster (K3s) im Rechenzentrum der Einrichtung

---

*Dieses Dokument beschreibt die technischen und organisatorischen Maßnahmen, die gemäß **Artikel 32 DSGVO** umgesetzt worden sind, um ein angemessenes Schutzniveau für die verarbeiteten personenbezogenen Daten zu gewährleisten.*

---

## 1. Einleitung

Die Technischen und Organisatorischen Maßnahmen (TOM) sind gemäß Art. 32 Abs. 1 lit. a-d DSGVO umgesetzt, um ein dem Risiko angemessenes Schutzniveau für die Verarbeitung personenbezogener Daten im Rahmen von openDesk Edu sicherzustellen.

### 1.1 Risikobasierte Herangehensweise

Die Maßnahmen werden regelmäßig auf ihre Angemessenheit geprüft und an technologische Weiterentwicklungen, Kosten der Umsetzung und Art, Umfang und Umstände sowie die Eintrittswahrscheinlichkeit und Schwere des Risikos für die Rechte und Freiheiten natürlicher Personen angepasst.

---

## 2. Vertraulichkeit

### 2.1 Zugriffskontrolle (Zutrittskontrolle)

| Maßnahme | Status | Beschreibung |
|----------|--------|--------------|
| **Räumliche Zutrittsbeschränkung** | ✅ Umgesetzt | Das Rechenzentrum ist nur befugten Personen zugänglich (Türverriegelung, Transpondersystem) |
| **Zutrittsprotokollierung** | ✅ Umgesetzt | Der Zugang zum Rechenzentrum wird protokolliert (Transponder-Logfiles) |
| **Videoüberwachung** | ⚠️ Teilweise | [Optional] Eingangsbereich wird überwacht, Datenrechentisch nicht erfasst |
| **Gästeregistrierung** | ✅ Umgesetzt | Externe Dienstleister und Gäste werden dokumentiert und begleitet |

**Dokumentation:**
- [Name der Einrichtung] Rechenzentrum: [Beschreibung der Zutrittsregelung]
- Verfahrensbeschreibung Besucherzugang: `[Link/Datei]`

---

### 2.2 Authentifizierung und Berechtigung

| Maßnahme | Status | Beschreibung |
|----------|--------|--------------|
| **Single Sign-On (SSO)** | ✅ Umgesetzt | openid-connect (Keycloak / OIDC) für alle Dienste |
| **Multi-Faktor-Authentifizierung** | ✅ Umgesetzt | Webbasierte Dienste erfordern 2FA (z. B. WebAuthn / TOTP) |
| **Passwort-Richtlinie** | ✅ Umgesetzt | Mindestens [X] Zeichen, Gültigkeit [Y] Tage, keine Wiederverwendung |
| **Berechtigungskonzept nach Prinzip der geringsten Privilegien** | ✅ Umgesetzt | Rollenbasierte Zugriffsrechte, Administrator-Schreibschutz |
| **Regelmäßige Überprüfung der Berechtigungen** | ✅ Umgesetzt | Mindestens jährliche Auditierung aller Systemzugriffe |

**Technische Details:**
- IdP: `[Keycloak Version]` mit LDAP-Anbindung an `[Active Directory / LDAP]`
- 2FA-Methoden: `[WebAuthn, TOTP, SMS]`
- Passwort-Rotation: `[Automatisch alle 90 Tage]`

---

### 2.3 Datenverschleierung (bei Übertragung und Speicherung)

| Maßnahme | Status | Beschreibung |
|----------|--------|--------------|
| **TLS 1.3 / ALPN (https)** | ✅ Umgesetzt | Alle externen Verbindungen sind TLS-verschlüsselt (Let's Encrypt, Wildcard-Zertifikate) |
| **internes Netzwerk** | ⚠️ Teilweise | [Optional] Verschlüsselung zwischen Komponenten via mTLS oder IPsec |
| **Speicherverschlüsselung** | ✅ Umgesetzt | Server-seitige Festplattenverschlüsselung (LUKS / dm-crypt) |
| **Datenbankverschlüsselung** | ⚠️ Optional | [Optional] At-Rest-Verschlüsselung sensibler Datenbankfelder (z. B. E-Mail-Adressen) |
| **Backup-Verschlüsselung** | ✅ Umgesetzt | Backups sind verschlüsselt gespeichert (GPG-Key, AES-256) |

**Zertifikate:**
- Wildcard-Zertifikat: `*.opendesk.[domain.de]`
- Aussteller: Let's Encrypt / DigiCert / `[specifizieren]`
- Gültigkeit: Automatische Verlängerung (ACME-Client)

---

### 2.4 Protokollierung

| Maßnahme | Status | Beschreibung |
|----------|--------|--------------|
| **Zugriffsprotokoll** | ✅ Umgesetzt | Logfiles auf allen Systemdiensten (nginx, Traefik, Keycloak, SOGo) |
| **Anmeldeprotokoll** | ✅ Umgesetzt | Erfassung von IP, Zeitstempel, Benutzerkonto (bei Erfolgen und Fehlversuchen) |
| **Löschung fehlerhafter Anmeldeversuche nach X Fehlversuchen** | ✅ Umgesetzt | Kontosperrung nach 5 Fehlversuchen für [Y] Minuten |
| **Konsistente Zeitbasis** | ✅ Umgesetzt | Alle Systeme werden via NTP mit Zentralzeit synchronisiert |
| **Log-Rotation und Aufbewahrung** | ✅ Umgesetzt | Logs werden [X] Tage aufbewahrt, danach sicher gelöscht |
| **SIEM / Log-Analyse** | ⚠️ Optional | [Optional] Export zu ZS/Graylog/Formitarif, Warnungen bei ungewöhnlichen Mustern |

---

### 2.5 Datenübermittlung und Offenlegung

| Maßnahme | Status | Beschreibung |
|----------|--------|--------------|
| **Gesetzliche Aufbewahrungsfristen** | ✅ Umgesetzt | Automatische Löschung abgelaufener Datenfristen [spezifizieren] |
| **Protection Against Data Leakage** | ✅ Umgesetzt | Keine offenen USB-Speicher auf Servern, Festplatten werden bei Entsorgung physisch vernichtet |
| **Zugriffskontrolle bei Datenexport** | ✅ Umgesetzt | Export- und Download-Funktionen sind authentifiziert und protokolliert |
| **Fremddienste / Cloud-Dienste** | ⚠️ Geprüft | [Optional] Nutzung von Cloud-Diensten nur nach Sicherheitsprüfung und AV-Vereinbarung |

---

## 3. Integrität

### 3.1 Speichereinheiten

| Maßnahme | Status | Beschreibung |
|----------|--------|--------------|
| **RAID / Replikation** | ✅ Umgesetzt | Ceph mit Replikationsfaktor 3 (Redundanz, Konsistenz) |
| **Integritätsprüfung** | ✅ Umgesetzt | Regelmäßige Scrubs in Ceph, md5/sha256 für Backups |
| **Read-Only-Mounts** | ⚠️ Teilweise | [Optional] Wichtige Konfigurationen sind read-only gemountet (chmod 644) |
| **Viren-/Malware-Schutz** | ⚠️ Optional | [Optional] ClamAV für Uploads (noch keine starke Infektionsgefahr) |

---

### 3.2 Nutzungskontrolle

| Maßnahme | Status | Beschreibung |
|----------|--------|--------------|
| **Session-Management** | ✅ Umgesetzt | Web-Sessions timeout nach [X] Minuten Inaktivität |
| **Session-Invalidierung** | ✅ Umgesetzt | SSO-Logout löst Logout auf allen verbundenen Diensten aus |
| **Genehmigung von Datenexporten** | ⚠️ Geprüft | [Optional] Massenexporte erfordern Administrator- oder DSB-Absegnung |
| **Umfassende Audit-Logs** | ✅ Umgesetzt | ALLE Datenzugriffe werden protokolliert und können nachverfolgt werden |

---

### 3.3 Getrennte Speicherung von Entwicklungs- und Produktionsdaten

| Maßnahme | Status | Beschreibung |
|----------|--------|--------------|
| **Isolierte Entwicklungsumgebung** | ✅ Umgesetzt | Entwickler arbeiten nur auf staging.opendesk.[de], keine Produktionsdaten |
| **Keine Kopie von Produktionsdaten in Entwicklung** | ✅ Umgesetzt | Entwicklung nutzt synthetische Testdaten, keine echten Nutzerdaten |
| **Getrennte Datenbank-Schemas** | ✅ Umgesetzt | Verschiedene Cluster für staging und live |

---

### 3.4 Backup und Recovery

| Maßnahme | Status | Beschreibung |
|----------|--------|--------------|
| **Tägliche Backups** | ✅ Umgesetzt | Vollständige Backups täglich um [Uhrzeit] (Ceph RBD / Snapshots) |
| **Geografische Redundanz (Off-site-Sicherung)** | ✅ Umgesetzt | Backups werden an `[Standort B]` übertragen |
| **Wiederherstellungs-Test** | ✅ Umgesetzt | Mindestens halbjährlicher Recovery-Test, dokumentiert |
| **Backup-Verschlüsselung** | ✅ Umgesetzt | GPG-verschlüsselt mit mindestens 2 admin-Schlüsseln |
| **Aufbewahrungsfrist** | ✅ Umgesetzt | Backups werden [X] Tage aufbewahrt, danach sicher gelöscht |

**Raster-Backup-Plan:**
| Typ | Rhythmus | Aufbewahrt | Standort |
|-----|----------|-----------|----------|
| Inkrementelles Backup | Täglich | 7 Tage | Lokal (Ceph) |
| Vollständiges Backup | Weekly | 4 Wochen | Lokal + Off-site |
| Langzeitarchiv | Monthly | 12 Monate | Off-site-Infrastruktur |

---

## 4. Verfügbarkeit

### 4.1 Backup und Wiederherstellung

*Siehe Abschnitt 3.4 Backup und Recovery*

---

### 4.2 Redundanz und Ausfallsicherheit

| Maßnahme | Status | Beschreibung |
|----------|--------|--------------|
| **Cluster-Hochverfügbarkeit** | ✅ Umgesetzt | K3s mit 3+ Control-Plane-Nodes (Hochverfügbarkeit der API-Server) |
| **Speicherredundanz** | ✅ Umgesetzt | Ceph Replikationsfaktor 3, Ausfall von 2 Knoten tolerierbar |
| **Application Redundancy** | ✅ Umgesetzt | Multi-Replica-Pods mittels Deployments, Health Checks liveness/readiness |
| **Load-Balancing** | ✅ Umgesetzt | Traefik / nginx als Ingress, Verteilung auf alle Worker-Nodes |
| **USV (Unterbrechungsfreie Stromversorgung)** | ✅ Umgesetzt | USV für alle Cluster-Knoten, autonomer Betrieb [X] Minuten |
| **Netzwerkredundanz** | ⚠️ Geprüft | [Optional] Dual-Homing, mehrere ISP-Anbindungen (BGP-Loadbalancing) |
| **Disaster Recovery Plan** | ✅ Umgesetzt | Dokumentierter DR-Plan, regelmäßige Übungen (mindestens jährlich) |

**SLAs / Zielwerte:**
- Verfügbarkeit: `[X.X] %` (entspricht [Y] Stunden Ausfall pro Jahr)
- RTO (Recovery Time Objective): `[X]` Stunden
- RPO (Recovery Point Objective): `[Y]` Minuten

---

### 4.3 Organisatorische Maßnahmen

| Maßnahme | Status | Beschreibung |
|----------|--------|--------------|
| **Schulung der Mitarbeiter** | ✅ Umgesetzt | Datenschutz-Schulung bei Aufnahme, jährliche Auffrischung |
| **Betriebsanleitungen** | ✅ Umgesetzt | SOPs für alle relevanten Tätigkeiten (Notfallplan, Virenbefall, Datenpannen) |
| **Datenschutzbeauftragter** | ✅ Umgesetzt | Benannter Datenschutzbeauftragter der Einrichtung, kontaktfähig |
| **Meldeverfahren bei Datenpannen** | ✅ Umgesetzt | Meldung an DSB innerhalb [X] Stunden, an BfDI bei Risiken binnen 72 h |
| **Auftragsverarbeitungsverträge (AVV)** | ✅ Umgesetzt | Bei Nutzung externer Dienstleister sind AVV geschlossen |
| **Verarbeitungsverzeichnis (VVT)** | ✅ Umgesetzt | Vorhanden und aktuell (siehe: `[Link]`) |
| **DSFA (Datenschutzfolgenabschätzung)** | ✅ Umgesetzt | Durchgeführt und dokumentiert (siehe: `[Link]`) |

---

## 5. Zertifizierungen und Audits

| Maßnahme | Status | Beschreibung |
|----------|--------|--------------|
| **ISO 27001** | ⚠️ Optional | [Optional] Zertifizierung des Rechenzentrums |
| **BSI-IT-Grundschutz** | ✅ Umgesetzt | Audit nach BSI-Grundschutz, Testschonung für openDesk Edu |
| **Penetrationstests** | ✅ Umgesetzt | Regelmäßige Pentests und Security-Audits durch interne/externe Experten |
| **Compliance-Reporting** | ✅ Umgesetzt | Jährlicher Sicherheitsbericht an die Leitung der Einrichtung |

---

## 6. Dokumentation und Referenzen

### 6.1 Interne Dokumente

| Dokument | Stand |
|----------|-------|
| Verarbeitungsverzeichnis (VVT) | `[Link/Datei]` |
| Datenschutzfolgenabschätzung (DSFA) | `[Link/Datei]` |
| Sicherheitskonzept | `[Link/Datei]` |
| Notfallplan | `[Link/Datei]` |
| SOP Datenpanne-Meldung | `[Link/Datei]` |

---

### 6.2 Externe Referenzen

| Dokument | Beschreibung |
|----------|-------------|
| BSI IT-Grundschutz-Kataloge | BSI 100-3, 100-4 (Sicherheitsmaßnahmen) |
| Art. 32 DSGVO | Technische und organisatorische Maßnahmen |
| LDSG [Bundesland] | Landesdatenschutzgesetz |
| Anlage zu § 9 BDSG | TOM für öffentliche Stellen |

---

## 7. Gültigkeit und Aktualisierung

Dieses Dokument wurde erstellt am `[Datum]` und ist gültig bis auf Widerruf oder Aktualisierung.

**Nächste Überprüfung:** `[Datum]` (mindestens jährlich)

**Verantwortliche Person:** `[Name, Position, Kontakt]`

---

*Letzte Aktualisierung: `[TT.MM.JJJJ]`*

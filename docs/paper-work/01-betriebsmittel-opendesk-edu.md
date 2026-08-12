<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Betriebsmittel-Beschreibung: openDesk Edu

> **⚠️ Rechtlicher Hinweis**
> Dieses Dokument ist eine **anonymisierte Vorlage** und muss an die spezifischen Anforderungen der jeweiligen Institution angepasst werden. Es basiert auf:
> - **HBDI-Bericht zu Microsoft 365 (2025-11-15, S. 79, Absätze 3173-3180)** – Klassifizierung von Office-Suiten als *Betriebsmittel*
> - **BayLfD-Vorlage (Modul 5: Betriebsmittel "Videokonferenzsystem")** – Standardisierte Betriebsmittel-Beschreibung
> - **DSGVO / BDSG / LDSG** – Datenschutzrechtliche Rahmenbedingungen
>
> **Es ersetzt keine rechtliche Beratung.** Vor Nutzung durch **DSB/Rechtsabteilung** prüfen lassen.

---

## 1. Allgemeine Angaben

| Feld | Inhalt |
|------|--------|
| **Bezeichnung des Betriebsmittels** | openDesk Edu (kollaborative Office-Suite) |
| **Version** | [z. B. openDesk CE 2026] |
| **Aktenzeichen** | [internes Aktenzeichen, z. B. BM-2026-EDU-001] |
| **Stand** | [TT.MM.JJJJ] |
| **Verantwortlicher** | [Name der Bildungseinrichtung] – Rechenzentrum (RZ) |
| **Anschrift** | [Postadresse der Einrichtung] |
| **Kontakt** | [E-Mail, Telefon des RZ] |
| **Datenschutzbeauftragter (DSB)** | [Name, Kontaktdaten] |
| **Betreiber** | Rechenzentrum (RZ) der Einrichtung |
| **DSB des Betreibers** | Siehe oben |

---

## 2. Klassifizierung als Betriebsmittel

### 2.1 Rechtliche Grundlagen
Gemäß **Hessischer Beauftragter für Datenschutz und Informationsfreiheit (HBDI)** im **[Bericht zu Microsoft 365 (2025-11-15, S. 79, Absätze 3173-3180)](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)**:

> *"Der Einsatz eines M365-Produkts für sich genommen stellt **keine Verarbeitungstätigkeit** im Sinne von Art. 30 DSGVO dar. Es handelt sich vielmehr um ein **technisches Hilfs- oder Betriebsmittel**, mit dessen Unterstützung unterschiedliche Verarbeitungstätigkeiten durchgeführt werden können."*

**Folgerung:**
- openDesk Edu ist eine **kollaborative Office-Suite** (Dateispeicher, E-Mail, Kalender, Chat, Videokonferenz) → **analog zu Microsoft 365**
- **openDesk Edu ist ein Betriebsmittel** → **Kein VVT (Verarbeitungsverzeichnis) für openDesk Edu selbst**
- **Verarbeitungstätigkeiten** (z. B. "E-Mail-Kommunikation", "Online-Lehre") werden **mithilfe von openDesk Edu** durchgeführt und sind **separat im VVT zu dokumentieren**

### 2.2 Abgrenzung
**Nicht von dieser Beschreibung umfasst:**
- Andere IT-Systeme der Einrichtung (z. B. SAP, HR-Systeme)
- Externe Cloud-Dienste (AWS, Azure, Google Cloud) → **nicht genutzt** (On-Premises-Betrieb)
- Individuelle Nutzerendgeräte (Laptops, Smartphones)

---

## 3. Eigenschaften des Betriebsmittels

### 3.1 Kurzdarstellung
openDesk Edu ist eine **souveräne, On-Premises Office-Suite** für Bildungseinrichtungen.
**Zweck:** Bereitstellung eines **digitalen Arbeitsplatzes** für Forschung, Lehre und Verwaltung mit:
- **openCloud** (Dateispeicher & Kollaboration, Nextcloud-basiert)
- **SOGo** (E-Mail & Kalender, Groupware)
- **Jitsi** (Videokonferenzen, WebRTC)
- **Element/Matrix** (Messenger, E2EE)
- **Portal** (Selbstservice für Nutzer:innen)

**Betriebsmodell:** Eigenbetrieb auf **Kubernetes (K3s)** im Rechenzentrum der Einrichtung.

### 3.2 Ausführliche Eigenschaftsdarstellung

| **Kriterium** | **Beschreibung** |
|--------------|------------------|
| **Hersteller** | Open-Source-Community (Eigenployment) |
| **Lizenz** | Apache-2.0 / AGPL (je nach Komponente) |
| **Betriebssystem** | Linux (z. B. Debian/Ubuntu) |
| **Virtualisierung** | [z. B. Proxmox VE, VMware, KVM] |
| **Container-Orchestrierung** | Kubernetes (K3s, Lightweight) |
| **Storage** | Ceph (Replikationsfaktor 3) oder ZFS |
| **Netzwerk** | Isoliertes VLAN, keine direkten Internet-Zugriffe auf Node-IPs |
| **Standort** | On-Premises im Rechenzentrum der Einrichtung |
| **Skalierung** | [Anzahl] Knoten, [Hardware-Spezifikationen] |

### 3.3 Komplexität
- ☒ **Hoch** – Mehrere Komponenten (openCloud, SOGo, Jitsi, Element), integrative Architektur, hohe Sicherheitsanforderungen
- ☐ Niedrig

**Begründung:**
- Integration verschiedener Dienste (E-Mail, Chat, Videokonferenz, Dateispeicher)
- Hohe Anforderungen an Datenschutz (DSGVO, LDSG) und Sicherheit (BSI IT-Grundschutz)
- Eigenbetrieb erfordert umfassende Administratoren-Kenntnisse

### 3.4 Notwendigkeit und Verhältnismäßigkeit

| **Aspekt** | **Begründung** |
|------------|----------------|
| **Notwendigkeit** | Souveräne digitale Arbeitsplätze für Forschung/Lehre/Verwaltung sind für moderne Bildungseinrichtungen unverzichtbar. |
| **Verhältnismäßigkeit** | On-Premises-Betrieb vermeidet Abhängigkeiten von externen Anbietern und ermöglicht volle Datenhoheit. Alternativen (z. B. lokale Einzelinstallationen) wären weniger Effizient. |
| **Datenschutz** | Eigenbetrieb ermöglicht **volle Kontrolle** über Datenverarbeitung (keine Drittlandübermittlung, keine externe Auftragsverarbeitung). |

---

## 4. Technische Architektur

### 4.1 Komponenten

| **Komponente** | **Zweck** | **Technische Basis** | **Datenkategorien (Betriebsmittelspezifisch)** |
|----------------|-----------|----------------------|-----------------------------------------------|
| **openCloud** | Dateispeicher, Kollaboration, Synchronisation | Nextcloud | Metadaten (Dateiname, Größe, Berechtigungen), Freigabelinks |
| **SOGo** | E-Mail, Kalender, Kontakte | SOGo Groupware | Metadaten (E-Mail-Header, Kalendereinträge) |
| **Jitsi** | Videokonferenzen, Chat | Jitsi Meet (WebRTC) | Metadaten (Meeting-ID, Teilnehmerliste, Dauer) |
| **Element/Matrix** | Messenger, Gruppenchat | Matrix-Protokoll | Metadaten (Nutzername, Raummitgliedschaften) |
| **Portal** | Selbstservice (Nutzerverwaltung) | Keycloak / Custom UI | Metadaten (Nutzerprofile, Rollen) |
| **Kubernetes (K3s)** | Container-Orchestrierung | Rancher K3s | Systemlogs, Pod-Metriken |
| **Ceph/ZFS** | Storage | Ceph (RBD) oder ZFS | Storage-Metriken, Replikationsstatus |
| **Shibboleth** | Authentifizierung (SSO) | Shibboleth SP | SAML-Attribute (Affiliation, E-Mail, Name) |
| **IdM-Anbindung** | User-Provisionierung | REST-API | Nutzerstammdaten (Benutzername, Rollen) |

### 4.2 Datenflüsse

```
┌───────────────────────┐
│   Nutzer:in            │
└───────────┬───────────┘
            │ (HTTPS/TLS 1.3)
            ▼
┌───────────────────────┐
│   Ingress (NGINX)      │◄── Firewall (isoliertes VLAN)
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│   Shibboleth SP        │◄── Lokale IdP (SAML 2.0)
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│   Kubernetes (K3s)     │
│  ┌─────────┐           │
│  │ SOGo     │◄──┐      │
│  └─────────┘   │      │
│  ┌─────────┐   │      │
│  │ Jitsi    │◄──┘      │
│  └─────────┘           │
│  ┌─────────┐           │
│  │ Element  │           │
│  └─────────┘           │
│  ┌─────────┐           │
│  │ openCloud│           │
│  └─────────┘           │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│   Ceph/ZFS Storage     │
└───────────────────────┘
```

### 4.3 On-Premises-Betrieb
✅ **Alle Daten verbleiben im Rechenzentrum der Einrichtung.**
✅ **Keine Nutzung externer Cloud-Dienste** (AWS, Azure, Google Cloud).
✅ **Keine Drittlandübermittlung.**

**Ausnahmen:**
- **Container-Images:** Werden aus offiziellen Quellen (Docker Hub, openDesk-Registry) bezogen und **lokal gecacht** (Registry-Mirror).
- **Upstream-Updates:** Werden vor Deployment **lokal gespiegelt, geprüft und signiert** (z. B. Cosign, Notary).
- **Fallback-IdP:** Bei Ausfall der lokalen IdP kann die **DFN-AAI** (Server in der EU) als Fallback genutzt werden.

---

## 5. Freigabe von nutzenden Verarbeitungen

### 5.1 Freigegebene Verarbeitungen
openDesk Edu darf für folgende **Verarbeitungstätigkeiten** genutzt werden (unter Einhaltung der jeweiligen Rechtsgrundlagen):

| **Verarbeitungstätigkeit** | **Rechtsgrundlage** | **Datenkategorien** | **Betroffene** |
|----------------------------|---------------------|---------------------|----------------|
| Bereitstellung digitaler Arbeitsplätze | Art. 6 Abs. 1 lit. e DSGVO i.V.m. LDSG | Stammdaten, Authentifizierungsdaten | Mitarbeitende, Studierende |
| E-Mail-Kommunikation (SOGo) | Art. 6 Abs. 1 lit. e DSGVO | E-Mail-Inhalte, Metadaten | Nutzer:innen, Empfänger:innen |
| Dateispeicherung/Kollaboration (openCloud) | Art. 6 Abs. 1 lit. e DSGVO | Dateiinhalte, Metadaten, Freigabelinks | Nutzer:innen |
| Videokonferenzen (Jitsi) | Art. 6 Abs. 1 lit. e DSGVO | Audio/Video-Streams, Chat-Nachrichten | Teilnehmer:innen |
| Messenger-Dienste (Element) | Art. 6 Abs. 1 lit. e DSGVO | Nachrichteninhalte, Gruppenmitgliedschaften | Nutzer:innen |
| Online-Lehre | Art. 6 Abs. 1 lit. e DSGVO | Lehrmaterialien, Teilnehmerdaten | Lehrende, Studierende |
| Forschungsdaten-Kollaboration | Art. 6 Abs. 1 lit. e DSGVO | Forschungsdaten (keine sensiblen Daten i.S.v. Art. 9 DSGVO) | Forschende |

### 5.2 Nicht freigegebene Verarbeitungen
openDesk Edu **darf nicht** genutzt werden für:

- **Besondere Kategorien personenbezogener Daten (Art. 9 Abs. 1 DSGVO):**
  - Gesundheitsdaten
  - Rassische oder ethnische Herkunft
  - Politische Meinungen
  - Gewerkschaftszugehörigkeit
  - Biometrische Daten (außer für Authentifizierung)
  - Sexuelle Orientierung
- **Strafrechtliche Daten (Art. 10 DSGVO):** Verarbeitung von Daten über strafrechtliche Verurteilungen
- **Großangelegte Videoüberwachung öffentlich zugänglicher Bereiche** (z. B. Campus-Überwachung)
- **Automatisierte Entscheidungen mit rechtlicher Wirkung** (Art. 22 DSGVO) ohne menschliche Kontrolle
- **Profiling ohne Rechtsgrundlage** (z. B. Verhaltensanalyse von Nutzer:innen)

### 5.3 Verarbeitungen mit Einzelfallprüfung
Für folgende Verarbeitungen ist eine **individuelle Risikobewertung (DSFA) erforderlich**:
- Verarbeitung von **pseudonymisierten Forschungsdaten** mit Re-Identifizierungsrisiko
- Nutzung von **KI-Funktionen** (z. B. Chat-Bots, intelligente Suche) → **DSFA nach Art. 35 DSGVO**
- **Langfristige Speicherung** von sensiblen Inhalten (z. B. Prüfungsunterlagen)

---

## 6. Kategorien personenbezogener Daten

### 6.1 Betriebsmittelspezifische Daten
*(Daten, die durch den Betrieb von openDesk Edu selbst anfallen – unabhängig von der Nutzung)*

| **Kategorie** | **Beispiele** | **Speicherdauer** | **Rechtsgrundlage** |
|---------------|--------------|-------------------|---------------------|
| **Authentifizierungsdaten** | SAML-Attribute (Affiliation, E-Mail, Name), Session-IDs | Session-Dauer + 24 h | Art. 6 Abs. 1 lit. e DSGVO |
| **Systemlogs** | Zugriffsprotokolle, Fehlerlogs, Kubernetes-Events | 30 Tage (90 Tage für Sicherheitslogs) | Art. 6 Abs. 1 lit. f DSGVO |
| **Performance-Daten** | CPU/RAM-Auslastung, Storage-Metriken | 30 Tage | Art. 6 Abs. 1 lit. f DSGVO |
| **Metadaten (technisch)** | IP-Adressen (pseudonymisiert nach 7 Tagen), Nutzeragenten | 7 Tage (pseudonymisiert) | Art. 6 Abs. 1 lit. f DSGVO |

### 6.2 Nutzerspezifische Daten
*(Daten, die durch die Nutzung der einzelnen Komponenten anfallen – ab तरफ der Verarbeitungstätigkeiten)*

| **Komponente** | **Datenkategorien** | **Verantwortung** |
|----------------|---------------------|--------------------|
| **openCloud** | Dateiinhalte, Metadaten (Name, Größe, Berechtigungen), Freigabelinks | Nutzer:in / Verarbeitungstätigkeit |
| **SOGo** | E-Mail-Inhalte, Anhangsdaten, Kalendereinträge, Kontakte | Nutzer:in / Verarbeitungstätigkeit |
| **Jitsi** | Audio/Video-Streams, Chat-Nachrichten, Meeting-Metadaten | Nutzer:in / Verarbeitungstätigkeit |
| **Element** | Nachrichteninhalte, Gruppenmitgliedschaften, Profilbilder | Nutzer:in / Verarbeitungstätigkeit |

---

## 7. Kategorien betroffener Personen

| **Gruppe** | **Beschreibung** | **Rolle** |
|------------|------------------|-----------|
| **Mitarbeitende** | Wissenschaftliche und administrative Mitarbeitende (inkl. studentische Hilfskräfte) | Nutzer:innen |
| **Studierende** | Eingeschriebene Studierende aller Fachbereiche | Nutzer:innen |
| **Externe Gäste** | Kooperationspartner:innen, Gastwissenschaftler:innen | Nutzer:innen |
| **Systemadministrator:innen** | IT-Personal mit Admin-Rechten auf K3s/Virtualisierung | Verwaltungspersonal |
| **Support-Mitarbeitende** | First-Level-Support (Helpdesk) | Verwaltungspersonal |
| **DSB / Compliance** | Datenschutzbeauftragte:r, Rechtsabteilung | Aufsicht |

---

## 8. Technische und organisatorische Maßnahmen (TOM)

### 8.1 Übersicht
Die TOM für openDesk Edu entsprechen den Anforderungen aus **Art. 32 DSGVO** und **BSI IT-Grundschutz (Kritikalität: hoch)**.

| **Kategorie** | **Maßnahme** | **Status** | **Verantwortlich** | **Referenz** |
|---------------|--------------|------------|--------------------|--------------|
| **Vertraulichkeit** | Zutrittskontrolle (RZ: Chipkarte + PIN) | ✅ | RZ | BSI ISI 1.2 |
|  | Zugriffskontrolle (RBAC, MFA für Admins) | ✅ | RZ | BSI ISI 1.3 |
|  | Verschlüsselung (TLS 1.3, AES-256 für Storage/Backups) | ✅ | RZ | BSI ISI 3.3 |
| **Integrität** | Ceph-Replikation (Faktor 3), RAID/ZFS | ✅ | RZ | BSI ISI 4.1 |
|  | Prüfsummen (SHA-256), Backup-Verifizierung | ✅ | RZ | BSI ISI 4.2 |
| **Verfügbarkeit** | Cluster-HA (3 Control-Plane-Nodes) | ✅ | RZ | BSI ISI 5.1 |
|  | USV, Georedundanz (Backup-Standort) | ✅ | RZ | BSI ISI 5.2 |
|  | Disaster Recovery (RTO ≤ 4 h, RPO ≤ 1 h) | ✅ | RZ | BSI ISI 5.3 |
| **Protokollierung** | Zentrale Logs (Loki/ELK), SIEM (Wazuh) | ✅ | RZ | BSI ISI 6.1 |
|  | Audit-Logs (K8s, Shibboleth), Immutable Logs (WORM) | ✅ | RZ | BSI ISI 6.2 |
| **Organisatorisch** | Schulungen (jährlich für Admin-Personal) | ✅ | RZ | BSI ISI 7.1 |
|  | Incident-Response-Plan, Meldepflichten (Art. 33/34 DSGVO) | ✅ | RZ | BSI ISI 7.2 |
|  | Vier-Augen-Prinzip für Admin-Aktionen | ✅ | RZ | BSI ISI 7.3 |

### 8.2 Detaillierte TOM

#### 8.2.1 Authentifizierung und Zugriffskontrolle
- **Single Sign-On (SSO):** Shibboleth SP (SAML 2.0) mit lokaler IdP
- **Attribute:** `eduPersonAffiliation`, `eduPersonScopedAffiliation`, `mail`, `displayName`
- **Multi-Faktor-Authentifizierung (MFA):** Pflicht für Admin-Zugriffe (TOTP via Keycloak/PrivacyIDEA)
- **Session-Timeout:** 8 Stunden Inaktivität → Automatische Abmeldung
- **Privileged Access Management (PAM):** Admin-Zugriffe nur über **Bastion-Host** mit Audit-Logging
- **Just-in-Time (JIT) Access:** Temporäre Admin-Rechte via **Teleport/Vault** (geplant)

#### 8.2.2 Verschlüsselung
- **In Transit:** TLS 1.3 für alle externen Zugriffe (cert-manager mit öffentlicher/interne CA)
- **At Rest:** AES-256 für Ceph-RBD-Volumes, ZFS-Encryption
- **Backups:** AES-256-Verschlüsselung, Schlüssel separiert (HSM/Offline)
- **Zertifikatsmanagement:** Automatisierte Rotation (cert-manager)

#### 8.2.3 Netzwerksicherheit
- **Isoliertes VLAN:** Kein direkter Internet-Zugriff auf Node-IPs
- **Firewall-Regeln:** Strenge Regeln auf Host- und Node-Ebene (nur HTTPS/443, interne APIs)
- **DMZ:** Externe Dienste (Ingress, Shibboleth) in separater Netzwerkzone
- **DDoS-Schutz:** Rate-Limiting auf Ingress-Controller (NGINX/Traefik) und Firewall

#### 8.2.4 Kubernetes-Sicherheit
- **Hardening:** CIS-Benchmark-konforme Konfiguration
- **Pod Security:** Pod Security Admission (PSA), Network Policies
- **RBAC:** Rollenbasierte Zugriffskontrolle (Least Privilege)
- **Service Accounts:** Dedizierte Accounts mit minimalen Rechten

#### 8.2.5 Backup und Disaster Recovery
- **Strategie:** Tägliche inkrementelle + wöchentliche Voll-Backups
- **RPO/RTO:** Recovery Point Objective ≤ 1 h, Recovery Time Objective ≤ 4 h
- **Backup-Ziele:** Backup-Server (VMs), Objekt-Speicher (S3-kompatibel) für openCloud/SOGo
- **Georedundanz:** Backups auf zwei physisch getrennte Standorte
- **Rollback-Tests:** Wöchentliche Tests der Wiederherstellung (automatisiert)
- **Notfall-Instanz:** Separate DR-Instanz für IdM-Kompromittierung (optional)

#### 8.2.6 Protokollierung und Monitoring
- **Zentrale Logs:** Loki oder ELK-Stack für alle Anwendungs- und Systemlogs
- **SIEM:** Wazuh oder Graylog für Sicherheitslogs (K8s-Audit, Shibboleth, IdM, Firewall)
- **Monitoring:** Grafana + Prometheus + Thanos für Performance-Metriken
- **Alerting:** Alertmanager für kritische Ereignisse (Ausfälle, Sicherheitsvorfälle)
- **Log-Retention:** 30 Tage (Anwendungslogs), 90 Tage (Sicherheitslogs)
- **Pseudonymisierung:** IP-Adressen in Logs werden nach **7 Tagen pseudonymisiert**

---

## 9. Datenschutz-Folgenabschätzung (DSFA)

### 9.1 Ausgangsrisiko
- **ohne TOM:** Hoch (due to sensitive data processing, large user base, complex architecture)
- **mit TOM:** Niedrig bis Mittel (after implementation of all measures)

### 9.2 Restrisiko
| **Risiko** | **Bewertung** | **Maßnahmen zur Minimierung** |
|------------|---------------|-------------------------------|
| Zero-Day-Exploits in openDesk-Komponenten | Niedrig | CVE-Monitoring, schnelles Patchen, Netzwerk-Segmentierung |
| Social Engineering (Phishing) | Niedrig | Regelmäßige Schulungen, MFA, Awareness-Kampagnen |
| Hardware-Ausfall | Niedrig | Georedundanz, regelmäßige DR-Tests |
| Menschliches Versagen (Fehlkonfiguration) | Niedrig | Vier-Augen-Prinzip, Change-Management, automatisierte Tests |

---

## 10. Verantwortlichkeiten

| **Rolle** | **Aufgaben** | **Kontakt** |
|-----------|--------------|-------------|
| **Verantwortlicher (RZ-Leitung)** | Gesamtverantwortung, Freigabe von Änderungen | [Name, E-Mail] |
| **Technischer Verantwortlicher** | Betrieb, Wartung, TOM-Umsetzung | [Name, E-Mail] |
| **Datenschutzbeauftragter (DSB)** | Datenschutz-Compliance, Audits, Beratung | [Name, E-Mail] |
| **IT-Sicherheit** | Sicherheitsüberwachung, Incident-Response | [Name, E-Mail] |
| **Backup-Team** | Backup-Strategie, Wiederherstellungstests | [Name, E-Mail] |

---

## 11. Anlagen und Verweise

| **Nr.** | **Bezeichnung** | **Quelle** |
|---------|-----------------|------------|
| A1 | Risikoanalyse openDesk Edu | Intern (RZ) |
| A2 | Technisches Rollen- und Berechtigungskonzept | Intern (RZ) |
| A3 | Kryptokonzept (Verschlüsselung) | Intern (RZ) |
| A4 | Protokollierungskonzept | Intern (RZ) |
| A5 | Löschkonzept | Intern (RZ) |
| A6 | BSI IT-Grundschutz-Kompendium | [BSI](https://www.bsi.bund.de/DE/Themen/ITGrundschutz/itgrundschutzkompendium_node.html) |
| A7 | HBDI-Bericht zu Microsoft 365 (2025-11-15) | [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf) |

---

## 12. Änderungshistorie

| **Datum** | **Änderung** | **Verantwortlich** |
|-----------|--------------|--------------------|
| [TT.MM.JJJJ] | Erstellung der Vorlage | openDesk Edu Contributors |
| [TT.MM.JJJJ] | Anpassung an [Institution] | [Name] |

---

## 13. Freigabe

| **Rolle** | **Name** | **Datum** | **Unterschrift** |
|-----------|----------|-----------|------------------|
| Verantwortlicher (RZ-Leitung) | [Name] | [Datum] | _______________ |
| Datenschutzbeauftragter (DSB) | [Name] | [Datum] | _______________ |

---

*Letzte Aktualisierung: 12.08.2026*

<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Verarbeitungsverzeichnis (VVT) – openDesk Edu
## Anonymisierte und generalisierte Fassung

> **⚠️ Hinweis zur Anonymisierung**
> Diese Fassung wurde für die öffentliche Bereitstellung im openDesk-Edu-Repository erstellt.
> Alle organisationsspezifischen Angaben (Name der Einrichtung, Standort, Kontaktdaten, interne Systeme,
> Netzwerk-Kennungen, Personenzahlen) wurden entfernt oder durch Platzhalter ersetzt.
>
> Sie dient als **Vorlage**, die von Bildungseinrichtungen an die eigene Organisation angepasst werden muss.
> Alle Werte in `[eckigen Klammern]` sind Platzhalter und vor Verwendung zu ersetzen.

---

**Verantwortlich:**
[Name der Bildungseinrichtung] – Rechenzentrum (RZ)

**Datum:** [TT.MM.JJJJ]
**Version:** 1.0 – anonymisierte Vorlage
**Gilt für:** Einführung von openDesk Edu auf einem Kubernetes-Cluster (K3s) im Rechenzentrum der Einrichtung

---

*Dieses Dokument erfüllt die gesetzliche Pflicht nach **Artikel 30 der Datenschutz-Grundverordnung (DSGVO)**. Es beschreibt für alle Interessierten verständlich, welche Daten im Rahmen von openDesk Edu verarbeitet werden und warum.*

---

## 1. Verantwortlicher und Datenschutzbeauftragter

| Feld | Inhalt |
|------|--------|
| **Verantwortlicher** | [Name der Bildungseinrichtung] – Rechenzentrum (RZ) |
| **Vertreten durch** | [Leitung RZ / IT-Verantwortliche:r] |
| **Kontakt** | [E-Mail-Adresse des Helpdesk], [Telefonnummer] |
| **Datenschutzbeauftragter (DSB)** | Datenschutzbeauftragte:r der Einrichtung |
| **DSB-Kontakt** | [E-Mail-Adresse des DSB] |
| **Technischer Ansprechpartner** | [Name, Abteilung Zentrale Systeme] |

---

## 2. Systemübersicht

### 2.1 Infrastruktur
- **Betriebssystem:** Virtualisierungsplattform (z. B. Proxmox VE)
- **Kubernetes:** K3s (Lightweight Kubernetes von Rancher)
- **Storage:** Ceph (Replikationsfaktor 3) oder ZFS
- **Netzwerk:** Isoliertes VLAN (kein direkter Internet-Zugriff auf Node-IPs)
- **Standort:** On-Premises im Rechenzentrum der Einrichtung

### 2.2 openDesk Edu-Komponenten
| Komponente | Zweck | Datenkategorien |
|------------|-------|-----------------|
| **openCloud** | Dateispeicher & Kollaboration | Dateiinhalte, Metadaten, Freigabelinks |
| **SOGo** | E-Mail & Kalender | E-Mail-Inhalte, Kontakte, Kalendereinträge |
| **Jitsi** | Videokonferenzen | Audio/Video-Streams, Chat-Nachrichten |
| **Element/Matrix** | Messenger | Nachrichteninhalte, Gruppenmitgliedschaften |
| **Portal** | Selbstservice-Portal | Nutzerprofile, Anmeldedaten |

### 2.3 Authentifizierung
- **Methode:** Shibboleth (SAML 2.0)
- **IdP:** lokale Shibboleth-IdP der Einrichtung
- **Attribute:** `eduPersonAffiliation`, `eduPersonScopedAffiliation`, `mail`, `displayName`
- **Domänen:** getrennte Nutzergruppen bzw. Subdomains für Beschäftigte und Studierende

---

## 3. Verarbeitungszwecke

### 3.1 Wofür werden Daten verarbeitet?

*In diesem Abschnitt wird beschrieben, wofür openDesk die Daten nutzt. Dies nennt man im Datenschutzrecht „Verarbeitungszwecke". Die gesetzliche Grundlage dafür ist die Datenschutz-Grundverordnung (DSGVO).*

| Nr. | Zweck (einfach erklärt) | Rechtsgrundlage | Welche Daten? | Wer ist betroffen? |
|-----|-------|-----------------|-----------------------------------|------------|
| 1 | Bereitstellung eines souveränen digitalen Arbeitsplatzes (openDesk Edu) für Forschung, Lehre und Verwaltung | Art. 6 Abs. 1 lit. e DSGVO i.V.m. dem Landesdatenschutzgesetz (LDSG) des jeweiligen Bundeslandes – öffentlich-rechtliche Aufgabe | Account-Daten, Authentifizierungsdaten, Nutzungsdaten | Angehörige der Einrichtung (Mitarbeitende, Studierende, externe Gäste) |
| 2 | Identitätsmanagement und Single-Sign-On (Shibboleth) | Art. 6 Abs. 1 lit. e DSGVO | SAML-Attribute (Affiliation, E-Mail, Name), Session-Daten | Alle Nutzer:innen |
| 3 | Automatisierte User-Provisionierung (REST-API an zentrales IdM) | Art. 6 Abs. 1 lit. e DSGVO | Account-Informationen (Benutzername, Rollen, Status) | Alle Nutzer:innen |
| 4 | Bereitstellung von Dateispeicher (openCloud) | Art. 6 Abs. 1 lit. e DSGVO | Dateiinhalte, Metadaten (Name, Größe, Berechtigungen), Freigabelinks | Nutzer:innen |
| 5 | Bereitstellung von E-Mail- und Kalenderdiensten (SOGo) | Art. 6 Abs. 1 lit. e DSGVO | E-Mail-Inhalte, Anhangsdaten, Kalendereinträge, Kontakte | Nutzer:innen |
| 6 | Bereitstellung von Videokonferenzdiensten (Jitsi) | Art. 6 Abs. 1 lit. e DSGVO | Audio-/Video-Streams, Chat-Nachrichten, Meeting-Metadaten (Teilnehmer, Dauer) | Nutzer:innen |
| 7 | Bereitstellung von Messenger-Diensten (Element/Matrix) | Art. 6 Abs. 1 lit. e DSGVO | Nachrichteninhalte, Gruppenmitgliedschaften, Profilbilder | Nutzer:innen |
| 8 | System-Überwachung: Damit alles läuft und Fehler schnell behoben werden können (Monitoring) | Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse an Betriebssicherheit und Störungsbehebung) | Systemlogs, Zugriffsprotokolle, Performance-Daten (IP-Adressen werden nach 7 Tagen unkenntlich gemacht) | Nutzer:innen (indirekt) |
| 9 | Backup und Recovery | Art. 6 Abs. 1 lit. e DSGVO | Alle oben genannten Daten (verschlüsselt) | Nutzer:innen |
| 10 | Disaster Recovery (Notfall-Instanz) | Art. 6 Abs. 1 lit. e DSGVO | Alternative E-Mail-Adressen (für Notfallbenachrichtigung), Nutzerstammdaten | Nutzer:innen |

### 3.2 Sekundäre Verarbeitungszwecke

| Nr. | Zweck | Rechtsgrundlage |
|-----|-------|-----------------|
| 11 | Statistische Auswertung der Nutzung (anonymisiert/aggregiert) | Art. 6 Abs. 1 lit. e DSGVO |
| 12 | Fehleranalyse und Incident-Management | Art. 6 Abs. 1 lit. f DSGVO |
| 13 | Sicherheitsanalysen (SIEM) | Art. 6 Abs. 1 lit. f DSGVO |
| 14 | Kapazitätsplanung und Ressourcenoptimierung | Art. 6 Abs. 1 lit. e DSGVO |

---

## 4. Welche personenbezogenen Daten werden verarbeitet?

*Personenbezogene Daten sind alle Informationen, die sich auf eine identifizierte oder identifizierbare natürliche Person beziehen – zum Beispiel Name, E-Mail-Adresse, IP-Adresse.*

| Kategorie | Was bedeutet das? | Beispiele | Wie sensibel sind diese Daten? |
|----------|-------------|----------|-------------------|
| **Stammdaten** | Informationen, die eine Person eindeutig identifizieren | Name, E-Mail-Adresse, Benutzername, Matrikelnummer (Studierende), Personalnummer (Mitarbeitende) | Normal |
| **Anmelde-Daten** | Informationen, die genutzt werden, um sich anzumelden (Authentifizierung) | Session-IDs, SAML-Tokens, Angaben zur Zugehörigkeit (Student/Mitarbeiter) | Hoch |
| **Nutzungs-Daten** | Informationen darüber, wann und wie jemand die Dienste nutzt | Wann wurde eingeloggt? Welche Dienste wurden genutzt? Wie lange wurde gearbeitet? IP-Adressen werden nach 7 Tagen unkenntlich gemacht | Niedrig |
| **Inhaltsdaten** | Die eigentlichen Inhalte, die Nutzer erstellen, hochladen oder speichern | Dateien (Dokumente, Fotos, Videos), E-Mails, Kalendereinträge, Chat-Nachrichten, Videoaufzeichnungen | Hoch |
| **Metadaten** | Technische Informationen zu den Inhalten (nicht die Inhalte selbst) | Wann wurde eine Datei erstellt? Wie groß ist sie? Wer darf sie sehen? Wurde sie geteilt? | Mittel |
| **Kommunikationsdaten** | Informationen über die Kommunikation | Wer hat mit wem kommuniziert? Wann? Wurde eine Nachricht gelesen? | Hoch |
| **Log-Daten** | System- und Anwendungslogs | Fehlerprotokolle, Zugriffslogs, API-Aufrufe, Kubernetes-Events | Niedrig |
| **Technische Daten** | Daten, die für den Betrieb der Systeme wichtig sind | Wie stark werden die Server belastet? Wie viel Speicher wird genutzt? Wie viel Datenverkehr ist da? | Niedrig |

---

## 5. Betroffene Personen

| Gruppe | Beschreibung | Anzahl (ca.) | datenschutzrechtliche Rolle |
|--------|-------------|--------------|------------------------------|
| **Mitarbeitende der Einrichtung** | Wissenschaftliche und administrative Mitarbeitende (inkl. studentische Hilfskräfte) | ~[Anzahl] | Nutzer:innen |
| **Studierende** | Eingeschriebene Studierende (alle Fachbereiche) | ~[Anzahl] | Nutzer:innen |
| **Externe Gäste** | Kooperationspartner:innen, Gastwissenschaftler:innen | ~[Anzahl] | Nutzer:innen |
| **Systemadministrator:innen (RZ)** | IT-Personal mit Admin-Rechten auf Kubernetes/der Virtualisierungsplattform | ~[Anzahl] | Verwaltungspersonal |
| **Support-Mitarbeitende** | First-Level-Support (Helpdesk) | ~[Anzahl] | Verwaltungspersonal |
| **Datenschutzbeauftragter (DSB)** | Interne/Externe Stelle für Datenschutz | 1 | Aufsichtsrolle |

---

## 6. Empfänger oder Kategorien von Empfängern

### 6.1 Interne Empfänger

| Empfänger | Abteilung | Zweck | Datenkategorien | Rechtsgrundlage |
|-----------|----------|-------|-----------------|-----------------|
| **RZ – Abteilung Zentrale Systeme** | RZ | Systembetrieb, Support, Incident-Management | Stammdaten, Authentifizierungsdaten, Log-Daten, Metadaten | Art. 6 Abs. 1 lit. e DSGVO |
| **RZ – IT-Sicherheit** | RZ | Sicherheitsüberwachung, Vorfallsbearbeitung | Log-Daten, Zugriffsprotokolle (pseudonymisiert), Sicherheitsereignisse | Art. 6 Abs. 1 lit. f DSGVO |
| **Datenschutzbeauftragter (DSB)** | Stabsstelle Datenschutz | Datenschutzaufsicht, Audit, Beratung | Metadaten zu Verarbeitungen (keine Inhaltsdaten) | Art. 39 DSGVO |
| **Rechtsabteilung / Compliance** | Verwaltung | Rechtliche Prüfung, Compliance | Metadaten, aggregierte Statistiken | Art. 6 Abs. 1 lit. e DSGVO |
| **Fachbereichs-IT-Administrator:innen** | Fachbereiche | Lokale Supportaufgaben | Stammdaten, Metadaten (für Nutzerverwaltung) | Art. 6 Abs. 1 lit. e DSGVO |

### 6.2 Externe Empfänger

| Empfänger | Typ | Zweck | Datenkategorien | Rechtsgrundlage | Vertragliche Absicherung |
|-----------|-----|-------|-----------------|-----------------|--------------------------|
| **Nationale akademische Föderation (z. B. DFN-AAI)** | Föderations-IdP | Fallback-Authentifizierung (falls lokale IdP nicht verfügbar) | SAML-Attribute (`eduPersonAffiliation`, `mail`, `displayName`) | Art. 6 Abs. 1 lit. b DSGVO (Vertrag) | Föderations-Nutzungsvertrag |
| **Lokale Shibboleth-IdP der Einrichtung** | IdP-Betreiber | Primäre Authentifizierung | SAML-Attribute (siehe oben) | Art. 6 Abs. 1 lit. e DSGVO | Interner Betrieb |
| **Backup-Anbieter (falls extern)** | Auftragsverarbeiter | Datensicherung | Verschlüsselte Backups (alle Daten) | Art. 28 DSGVO | AV-Vertrag mit technischen und organisatorischen Maßnahmen (TOM) |
| **Aufsichtsbehörde (zuständige Datenschutzaufsicht)** | Aufsichtsbehörde | Anfragen im Rahmen der Aufsicht | Fallabhängig (nur anonymisierte Daten) | Art. 6 Abs. 1 lit. c DSGVO (rechtliche Verpflichtung) | – |
| **Strafverfolgungsbehörden** | Staatliche Stelle | Anfragen im Rahmen von Ermittlungen | Fallabhängig | Landesrechtliche Vorschriften i.V.m. StPO | Richterliche Anordnung |

> **Hinweis zu externen IdPs:**
> - Primär wird die **lokale Shibboleth-IdP der Einrichtung** genutzt.
> - Falls die lokale IdP ausfällt, kann als **Fallback eine nationale akademische Föderation (z. B. DFN-AAI)** genutzt werden. In diesem Fall werden **nur die für die Authentifizierung notwendigen Attribute** übermittelt.
> - **Keine dauerhafte Übermittlung** von Daten an externe IdPs – die Authentifizierung erfolgt **pro Session**.

---

## 7. Übermittlung in Drittländer

| Land | Empfänger | Datenkategorien | Vorhanden? | Safeguards |
|-------|-----------|-----------------|------------|--------------|
| **Keine** | – | – | ❌ | – |

### Begründung:
✅ **Keine Übermittlung in Drittländer**, da:
1. **On-Premises-Betrieb:** Der **Kubernetes-Cluster läuft ausschließlich auf Servern im Rechenzentrum der Einrichtung**.
2. **Keine Public-Cloud-Nutzung:** Es werden **keine Dienste von AWS, Azure, Google Cloud oder ähnlichen Anbietern** genutzt.
3. **Externe Abhängigkeiten:**
   - **Container-Images:** Werden aus **offiziellen Quellen** (z. B. Docker Hub Official Images, openDesk-Registry) bezogen und **lokal auf einem Registry-Mirror** im Rechenzentrum gecacht.
   - **Upstream-Updates:** Werden vor dem Deployment **lokal gespiegelt, geprüft und signiert** (z. B. über **Cosign** oder **Notary**).
   - **Akademische Föderation (z. B. DFN-AAI):** Falls als Fallback-IdP genutzt, erfolgt die Datenübermittlung **innerhalb der EU** (Server in Deutschland/EU).
4. **Datenhoheit:** Alle Daten verbleiben **ausschließlich auf Servern der Einrichtung**.

---

## 8. Geplante Löschfristen

### 8.1 Nutzerbezogene Daten

| Datenkategorie | Löschfrist | Verantwortlich | Methode | Automatisiert? |
|----------------|------------|----------------|---------|---------------|
| **Nutzerkonten** | 6 Monate nach Beendigung der Zugehörigkeit (Studium/Anstellung/Gaststatus) | RZ – IdM-Team | Automatisierte Deprovisionierung via IdM | ✅ |
| **Dateien (openCloud)** | 30 Tage nach Löschung durch Nutzer:in (Papierkorb) | Nutzer:in / System | Automatische Bereinigung | ✅ |
| **E-Mails (SOGo)** | 30 Tage nach Löschung durch Nutzer:in | Nutzer:in / System | Automatische Bereinigung | ✅ |
| **Kalendereinträge (SOGo)** | 30 Tage nach Löschung durch Nutzer:in | Nutzer:in / System | Automatische Bereinigung | ✅ |
| **Chat-Nachrichten (Element)** | 30 Tage nach Löschung durch Nutzer:in | Nutzer:in / System | Automatische Bereinigung | ✅ |
| **Freigabelinks (openCloud)** | 7 Tage nach Ablauf (Standard) oder manuelle Löschung | Nutzer:in / System | Automatische/manuelle Löschung | ✅ |

### 8.2 System- und Log-Daten

| Datenkategorie | Löschfrist | Verantwortlich | Methode | Automatisiert? |
|----------------|------------|----------------|---------|---------------|
| **Anwendungslogs (openCloud, SOGo, Jitsi, Element)** | 30 Tage | RZ – Monitoring-Team | Automatische Löschung (Loki/Grafana) | ✅ |
| **Sicherheitslogs (K8s-Audit, Shibboleth, IdM, SIEM)** | 90 Tage | RZ – IT-Sicherheit | Automatische Löschung (Wazuh/Graylog) | ✅ |
| **Systemlogs (K3s, Virtualisierungsplattform, Storage)** | 30 Tage | RZ – Systemadministration | Automatische Löschung | ✅ |
| **Session-Daten (Authentifizierung)** | 24 Stunden nach Abmeldung | System | Automatische Löschung | ✅ |
| **Pseudonymisierte IP-Adressen in Logs** | 7 Tage nach Erfassung | System | Automatische Pseudonymisierung | ✅ |

### 8.3 Backups

| Backup-Typ | Retention | Verantwortlich | Methode | Verschlüsselung |
|------------|-----------|----------------|---------|----------------|
| **Tägliche inkrementelle Backups** | 30 Tage | RZ – Backup-Team | Backup-Server / Objekt-Speicher | ✅ (AES-256) |
| **Wöchentliche Voll-Backups** | 12 Monate | RZ – Backup-Team | Backup-Server | ✅ (AES-256) |
| **Monatliche Archiv-Backups** | 7 Jahre | RZ – Backup-Team | Langzeitarchiv (z. B. Tape) | ✅ (AES-256) |
| **Disaster-Recovery-Backups** | 30 Tage | RZ – Backup-Team | Separater Storage (georedundant) | ✅ (AES-256) |

> **Hinweis zu Backups:**
> - Backups werden **automatisch verschlüsselt** (AES-256).
> - Der **Schlüssel** wird separat aufbewahrt (Hardware Security Module oder offline).
> - **Rollback-Tests** finden **wöchentlich** statt (RTO ≤ 4 h, RPO ≤ 1 h).
> - **Löschung:** Backups werden nach Fristablauf **automatisch gelöscht** (keine manuelle Intervention).

### 8.4 Alternative E-Mail-Adressen (für Disaster Recovery)

| Datenkategorie | Löschfrist | Verantwortlich | Methode |
|----------------|------------|----------------|---------|
| **Alternative E-Mail-Adressen (Notfallkontakte)** | Löschung mit Ende der Zugehörigkeit + 6 Monate | RZ – IdM-Team | Automatisierte Löschung |

> **Hinweis:**
> - Alternative E-Mail-Adressen werden **nur für den Notfall** (DR-Szenario: IdM-Kompromittierung) erfasst.
> - Die Erhebung erfolgt **freiwillig** mit Einwilligung der Betroffenen.
> - Die Daten werden **verschlüsselt** gespeichert und **nicht für andere Zwecke** genutzt.

---

## 9. Technische und organisatorische Maßnahmen (TOM) gem. Art. 32 DSGVO

### 9.1 Infrastruktur-Sicherheit (On-Premises)

| Maßnahme | Beschreibung | Umsetzungsstatus | Verantwortlich |
|----------|-------------|------------------|----------------|
| **On-Premises-Betrieb** | Kubernetes-Cluster auf Servern im **Rechenzentrum der Einrichtung** | ✅ | RZ |
| **Physische Sicherheit** | Zugang zum Rechenzentrum nur mit **Zutrittskontrolle** (Chipkarte + PIN), Videoüberwachung, Alarmierung | ✅ | RZ |
| **Netzwerk-Segmentierung** | **Isoliertes VLAN** für den Kubernetes-Cluster (kein direkter Internet-Zugriff auf Node-IPs) | ✅ | RZ |
| **Firewall-Regeln** | Strenge **Regeln auf Firewall-Ebene** an den Hosts und Nodes (nur HTTPS/443, interne APIs) | ✅ | RZ |
| **Demilitarisierte Zone (DMZ)** | Externe Dienste (Ingress, Shibboleth) in separater Netzwerkzone | ✅ | RZ |
| **Kubernetes-Hardening** | CIS-Benchmark-konforme Konfiguration (Pod Security Admission, Network Policies, RBAC) | ✅ | RZ |
| **Storage-Verschlüsselung** | **Ceph-RBD-Volumes** mit AES-256-Verschlüsselung (oder ZFS-Encryption) | ✅ | RZ |
| **Datenverschlüsselung in Ruhe** | Alle **Persistent Volumes (PVs)** verschlüsselt | ✅ | RZ |
| **TLS-Verschlüsselung** | **HTTPS für alle externen Zugriffe** (cert-manager mit öffentlicher CA oder interner CA der Einrichtung) | ✅ | RZ |
| **Zertifikatsmanagement** | Automatisierte Zertifikatsrotation (cert-manager) | ✅ | RZ |
| **DDoS-Schutz** | **Rate-Limiting** auf Ingress-Controller (NGINX/Traefik) und Firewall | ✅ | RZ |

### 9.2 Zugriffskontrolle und Authentifizierung

| Maßnahme | Beschreibung | Umsetzungsstatus | Verantwortlich |
|----------|-------------|------------------|----------------|
| **Rollenbasierte Zugriffskontrolle (RBAC)** | Kubernetes-RBAC + **openDesk-spezifische Rollen** (Admin, Nutzer:in, Gast, Auditor) | ✅ | RZ |
| **Shibboleth-Integration** | Authentifizierung über **Shibboleth SP** (SAML 2.0) mit lokaler IdP | ✅ | RZ |
| **IdM-Anbindung** | Automatisierte **User-Provisionierung/Deprovisionierung** via REST-API an das **zentrale Identity-Management (IdM)** | ✅ | RZ |
| **Attribut-Mapping** | **Strikte Beschränkung** auf notwendige Attribute (`eduPersonAffiliation`, `mail`, `displayName`, `scopedAffiliation`) | ✅ | RZ |
| **Multi-Faktor-Authentifizierung (MFA)** | **Pflicht für Admin-Zugriffe** (z. B. TOTP via Keycloak oder PrivacyIDEA) | ✅ | RZ |
| **Session-Timeout** | Automatische Abmeldung nach **8 Stunden Inaktivität** (konfigurierbar) | ✅ | RZ |
| **Privileged Access Management (PAM)** | Admin-Zugriffe nur über **Bastion-Host** mit **Audit-Logging** | ✅ | RZ |
| **Just-in-Time (JIT) Access** | Temporäre Admin-Rechte via **Teleport** oder **Vault** | ⚠️ (geplant) | RZ |
| **Service-Account-Management** | Dedizierte **Service-Accounts** für Anwendungskomponenten mit minimalen Rechten | ✅ | RZ |

### 9.3 Logging, Monitoring und SIEM

| Maßnahme | Beschreibung | Umsetzungsstatus | Verantwortlich |
|----------|-------------|------------------|----------------|
| **Zentrale Log-Sammlung** | **Loki** oder **ELK-Stack** für alle Anwendungs- und Systemlogs | ✅ | RZ |
| **SIEM-Integration** | **Wazuh** oder **Graylog** für Sicherheitslogs (K8s-Audit, Shibboleth, IdM, Firewall) | ✅ | RZ – IT-Sicherheit |
| **Monitoring** | **Grafana + Prometheus + Thanos** für Performance-Metriken | ✅ | RZ |
| **Alerting** | **Alertmanager** für kritische Ereignisse (z. B. Ausfälle, Sicherheitsvorfälle, hohe CPU/RAM-Auslastung) | ✅ | RZ |
| **Log-Retention** | 30 Tage für Anwendungslogs, **90 Tage für Sicherheitslogs** | ✅ | RZ |
| **Pseudonymisierung** | **IP-Adressen in Logs werden nach 7 Tagen pseudonymisiert** | ✅ | RZ |
| **Immutable Logs** | Logs werden **unveränderbar** gespeichert (Write-Once-Read-Many, WORM) | ✅ | RZ |
| **Audit-Logs** | **Komplette Protokollierung** aller Admin-Aktionen (K8s-Audit-Logs, Shibboleth-Logs) | ✅ | RZ |

### 9.4 Backup und Recovery

| Maßnahme | Beschreibung | Umsetzungsstatus | Verantwortlich |
|----------|-------------|------------------|----------------|
| **Backup-Strategie** | **Tägliche inkrementelle + wöchentliche Voll-Backups** (RPO: **1 Stunde**, RTO: **4 Stunden**) | ✅ | RZ |
| **Backup-Ziele** | **Backup-Server** für VM-Backups, **Objekt-Speicher (S3-kompatibel)** für Objektdaten (openCloud, SOGo) | ✅ | RZ |
| **Verschlüsselte Backups** | **Alle Backups mit AES-256 verschlüsselt** (Schlüssel gesondert verwahrt) | ✅ | RZ |
| **Georedundanz** | Backups auf **zwei physisch getrennte Standorte** | ✅ | RZ |
| **Rollback-Tests** | **Wöchentliche Tests** der Backup-Wiederherstellung (automatisiert) | ✅ | RZ |
| **Disaster Recovery (DR)** | **Notfall-Instanz** auf separater Hardware (für IdM-Kompromittierung) | ⚠️ (optional) | RZ |
| **DR-Testing** | **Jährlicher DR-Test** mit Dokumentation | ⚠️ (geplant) | RZ |

### 9.5 Datenschutz-spezifische Maßnahmen

| Maßnahme | Beschreibung | Umsetzungsstatus | Verantwortlich |
|----------|-------------|------------------|----------------|
| **Datenminimierung** | **Nur notwendige Attribute** aus dem IdM werden synchronisiert (keine unnötigen personenbezogenen Daten) | ✅ | RZ |
| **Zweckbindung** | Daten werden **ausschließlich für die berechtigten Zwecke** (siehe Kap. 3) verarbeitet | ✅ | RZ |
| **Pseudonymisierung** | IP-Adressen in Logs werden **automatisch nach 7 Tagen pseudonymisiert** | ✅ | RZ |
| **Löschkonzept** | **Automatisierte Löschung** von Daten nach Fristablauf (siehe Kap. 8) | ✅ | RZ |
| **Rechte der Betroffenen** | **Selbstservice-Portal** für Datenauskunft, Löschung, Berichtigung | ⚠️ (geplant) | RZ |
| **Datenschutz-Folgenabschätzung (DSFA)** | Vorliegendes Dokument als Grundlage | ✅ | RZ / DSB |
| **Privacy by Design** | Datenschutz bei **Systemdesign** berücksichtigt (z. B. Verschlüsselung, RBAC) | ✅ | RZ |
| **Privacy by Default** | Datenschutzfreundliche **Standard-Einstellungen** (z. B. keine öffentliche Freigabe) | ✅ | RZ |

### 9.6 Organisatorische Maßnahmen

| Maßnahme | Beschreibung | Umsetzungsstatus | Verantwortlich |
|----------|-------------|------------------|----------------|
| **DSB-Einbindung** | **Regelmäßige Abstimmung** mit dem Datenschutzbeauftragten (vierteljährlich) | ✅ | RZ / DSB |
| **Datenschutzschulungen** | **Jährliche Schulungen** für Admin-Personal (Pflicht) | ✅ | RZ |
| **Incident-Response-Plan** | **Definierter Prozess** für Datenschutzvorfälle (inkl. Meldepflichten) | ✅ | RZ |
| **Meldepflichten (Art. 33/34 DSGVO)** | **Automatisierte Benachrichtigung** des DSB bei Vorfällen innerhalb von 72 Stunden | ✅ | RZ |
| **Verträge mit Auftragsverarbeitern** | **AV-Verträge** für externe Dienstleister (falls vorhanden, z. B. Backup-Anbieter) | ✅ | Rechtsabteilung |
| **Dokumentation** | **Betriebsdokumentation**, **Sicherheitskonzept**, **VVT** (dieses Dokument), **DSFA** | ✅ | RZ |
| **Interne Audits** | **Jährliche Überprüfung** der TOM und des VVT | ✅ | RZ – IT-Sicherheit |
| **Externe Audits** | **DSB-Prüfung** alle 2 Jahre | ✅ | DSB |
| **Compliance mit BSI IT-Grundschutz** | **BSI-Grundschutz-Zertifizierung** (angestrebt) | ⚠️ (in Arbeit) | RZ |

---

## 10. Verarbeitungsaktivitäten im Detail

### 10.1 Nutzerverwaltung (IdM + Shibboleth)

| **Feld** | **Wert** |
|----------|----------|
| **Verarbeitungszweck** | Authentifizierung und Autorisierung der Nutzer:innen |
| **Rechtsgrundlage** | Art. 6 Abs. 1 lit. e DSGVO i.V.m. Landesdatenschutzgesetz (LDSG) |
| **Datenkategorien** | Benutzername, E-Mail, Affiliation (`staff`/`student`), SAML-Attribute (`eduPersonAffiliation`, `eduPersonScopedAffiliation`, `displayName`, `mail`) |
| **Betroffene** | Alle Nutzer:innen (Mitarbeitende, Studierende, Gäste) |
| **Empfänger** | Shibboleth-IdP (Einrichtung), openDesk-Dienste (openCloud, SOGo, Jitsi, Element), Admin-Team (bei Support) |
| **Speicherdauer** | Solange Nutzer:in aktiv + **6 Monate Nachfrist** |
| **Sicherheitsmaßnahmen** | TLS 1.3, RBAC, Session-Timeout (8 h), MFA für Admins, Audit-Logging |
| **Risikobewertung** | **Mittel** (Authentifizierungsdaten sind sensibel, aber gut geschützt) |
| **DSFA-Pflicht** | ❌ (keine hohe Risikobewertung) |

### 10.2 openCloud (Dateispeicher)

| **Feld** | **Wert** |
|----------|----------|
| **Verarbeitungszweck** | Bereitstellung von Cloud-Speicher für Dateien (Kollaboration, Backup, Synchronisation) |
| **Rechtsgrundlage** | Art. 6 Abs. 1 lit. e DSGVO |
| **Datenkategorien** | Dateiinhalte, Metadaten (Name, Größe, Besitzer, Berechtigungen, Versionierung), Freigabelinks |
| **Betroffene** | Alle Nutzer:innen |
| **Empfänger** | Nutzer:innen, Admin-Team (bei Support), Freigabeempfänger:innen (bei geteilten Links) |
| **Speicherdauer** | Bis zur Löschung durch Nutzer:in + **30 Tage (Papierkorb)** |
| **Sicherheitsmaßnahmen** | Verschlüsselung in Ruhe (AES-256), TLS 1.3, RBAC, Quotenregelung, Freigabelinks mit Ablaufdatum |
| **Risikobewertung** | **Hoch** (mögliche sensitive Inhalte wie Forschungsdaten, personenbezogene Dokumente) |
| **DSFA-Pflicht** | ✅ (ja, aufgrund hochsensibler Daten) |

### 10.3 SOGo (E-Mail & Kalender)

| **Feld** | **Wert** |
|----------|----------|
| **Verarbeitungszweck** | Bereitstellung von E-Mail- und Kalenderdiensten |
| **Rechtsgrundlage** | Art. 6 Abs. 1 lit. e DSGVO |
| **Datenkategorien** | E-Mail-Inhalte, Anhangsdaten, Kalendereinträge, Kontakte, E-Mail-Header (Absender, Empfänger, Betreff) |
| **Betroffene** | Alle Nutzer:innen |
| **Empfänger** | Nutzer:innen, E-Mail-Empfänger:innen (intern/extern), Admin-Team (bei Support) |
| **Speicherdauer** | Bis zur Löschung durch Nutzer:in |
| **Sicherheitsmaßnahmen** | TLS 1.3 (SMTP/IMAP), Spam-Filter (Rspamd), Virenscanner (ClamAV), Quotenregelung, DKIM/SPF/DMARC |
| **Risikobewertung** | **Hoch** (kommunikationsbezogene Daten, möglicherweise sensible Inhalte) |
| **DSFA-Pflicht** | ✅ (ja) |

### 10.4 Jitsi (Videokonferenzen)

| **Feld** | **Wert** |
|----------|----------|
| **Verarbeitungszweck** | Bereitstellung von Videokonferenzdiensten für Meetings, Lehre, Kollaboration |
| **Rechtsgrundlage** | Art. 6 Abs. 1 lit. e DSGVO |
| **Datenkategorien** | Audio-/Video-Streams (Echtzeit, **keine Aufzeichnung** im Standard), Chat-Nachrichten, Meeting-Metadaten (Teilnehmer:innen, Dauer, Raumname) |
| **Betroffene** | Nutzer:innen, Meeting-Teilnehmer:innen |
| **Empfänger** | Meeting-Teilnehmer:innen |
| **Speicherdauer** | **Keine Aufzeichnung** (Standard), Chat-Nachrichten: **30 Tage** |
| **Sicherheitsmaßnahmen** | Ende-zu-Ende-Verschlüsselung (E2EE) für Meetings, Passwortschutz, Wartelobby, TLS 1.3, Rate-Limiting |
| **Risikobewertung** | **Hoch** (Echtzeit-Kommunikation, möglicherweise sensible Gespräche) |
| **DSFA-Pflicht** | ✅ (ja) |

### 10.5 Element/Matrix (Messenger)

| **Feld** | **Wert** |
|----------|----------|
| **Verarbeitungszweck** | Bereitstellung von Messenger-Diensten für interne Kommunikation |
| **Rechtsgrundlage** | Art. 6 Abs. 1 lit. e DSGVO |
| **Datenkategorien** | Nachrichteninhalte, Gruppenmitgliedschaften, Profilinformationen (Name, Avatar), Reaktions-Emojis, Dateianhänge |
| **Betroffene** | Nutzer:innen |
| **Empfänger** | Chat-Teilnehmer:innen, Admin-Team (bei Support) |
| **Speicherdauer** | Bis zur Löschung durch Nutzer:in |
| **Sicherheitsmaßnahmen** | E2EE (Matrix Olm/Megolm), Server-seitige Verschlüsselung, RBAC, Spam-Schutz |
| **Risikobewertung** | **Hoch** (private Kommunikation) |
| **DSFA-Pflicht** | ✅ (ja) |

### 10.6 Monitoring & Logging (Grafana, Prometheus, Loki, Alertmanager)

| **Feld** | **Wert** |
|----------|----------|
| **Verarbeitungszweck** | Betriebssicherheit, Fehleranalyse, Performance-Monitoring, Sicherheitsüberwachung |
| **Rechtsgrundlage** | Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse an stabilem Betrieb) |
| **Datenkategorien** | Systemlogs (K3s, Virtualisierungsplattform, Storage), Anwendungslogs (openCloud, SOGo, Jitsi, Element), Zugriffsprotokolle, Performance-Metriken (CPU, RAM, Storage), **pseudonymisierte IP-Adressen** |
| **Betroffene** | Nutzer:innen (indirekt über IP/Session-Daten) |
| **Empfänger** | RZ – Monitoring-Team, RZ – IT-Sicherheit |
| **Speicherdauer** | **30 Tage** (Anwendungslogs), **90 Tage** (Sicherheitslogs) |
| **Sicherheitsmaßnahmen** | Zugriffsbeschränkung (nur Admin-Team), Pseudonymisierung (IP-Adressen nach 7 Tagen), Immutable Logs (WORM) |
| **Risikobewertung** | **Niedrig** (keine Inhaltsdaten, Pseudonymisierung) |
| **DSFA-Pflicht** | ❌ (nein) |

### 10.7 Backup und Recovery

| **Feld** | **Wert** |
|----------|----------|
| **Verarbeitungszweck** | Datensicherung und Wiederherstellung im Störungsfall |
| **Rechtsgrundlage** | Art. 6 Abs. 1 lit. e DSGVO |
| **Datenkategorien** | **Verschlüsselte Kopien** aller Nutzerdaten (openCloud, SOGo, Jitsi-Logs, Element-Nachrichten) |
| **Betroffene** | Alle Nutzer:innen |
| **Empfänger** | RZ – Backup-Team (im Störungsfall) |
| **Speicherdauer** | **30 Tage** (täglich), **12 Monate** (wöchentlich), **7 Jahre** (monatlich) |
| **Sicherheitsmaßnahmen** | AES-256-Verschlüsselung, Schlüssel gesondert verwahrt (HSM), Georedundanz |
| **Risikobewertung** | **Mittel** (Backups sind verschlüsselt, aber bei Schlüsselverlust nicht wiederherstellbar) |
| **DSFA-Pflicht** | ❌ (nein, da verschlüsselt und zugriffsbeschränkt) |

### 10.8 Disaster Recovery (Notfall-Instanz)

| **Feld** | **Wert** |
|----------|----------|
| **Verarbeitungszweck** | Bereitstellung einer Notfall-Instanz bei Kompromittierung des zentralen IdM |
| **Rechtsgrundlage** | Art. 6 Abs. 1 lit. e DSGVO |
| **Datenkategorien** | **Alternative E-Mail-Adressen** (für Notfallbenachrichtigung), Nutzerstammdaten (Name, Affiliation), verschlüsselte Backups |
| **Betroffene** | Alle Nutzer:innen (freiwillige Angabe) |
| **Empfänger** | RZ – DR-Team |
| **Speicherdauer** | Solange Nutzer:in aktiv + **6 Monate** |
| **Sicherheitsmaßnahmen** | **Verschlüsselung**, Zugriff nur im Notfall, manuelle Freigabe durch RZ-Leitung |
| **Risikobewertung** | **Mittel** (sensible E-Mail-Adressen, aber freiwillig und verschlüsselt) |
| **DSFA-Pflicht** | ❌ (nein) |

---

## 11. Risikobewertung

### 11.1 Risikoeinschätzung nach DSGVO

| **Risikoklasse** | **Beschreibung** | **Beispiele im openDesk-Kontext** |
|------------------|------------------|------------------------------------|
| **Niedrig** | Unwahrscheinlich, dass eine Verarbeitung zu einem Risiko für Rechte/Freiheiten führt | Pseudonymisierte Log-Daten, aggregierte Statistiken |
| **Mittel** | Verarbeitung könnte zu einem Risiko führen, aber Maßnahmen reduzieren dies | Nutzerstammdaten, Authentifizierungsdaten |
| **Hoch** | Verarbeitung führt wahrscheinlich zu einem hohen Risiko | Inhaltsdaten (E-Mails, Dateien, Nachrichten), Echtzeit-Kommunikation |

### 11.2 Risikomatrix

| **Risiko** | **Eintritts-wahrscheinlichkeit** | **Schadens-ausmaß** | **Risikostufe** | **Maßnahmen** | **Restrisiko** |
|------------|-------------------------------|-------------------|---------------|---------------|----------------|
| **Unautorisierter Zugriff auf Nutzerdaten (z. B. Dateien, E-Mails)** | Niedrig | Sehr Hoch | **Hoch** | RBAC, MFA, Firewall, Verschlüsselung, Audit-Logging | Mittel |
| **Datenverlust durch Hardware-Ausfall** | Mittel | Hoch | **Hoch** | Backups (RPO 1 h, RTO 4 h), Georedundanz, Rollback-Tests | Niedrig |
| **Sicherheitslücke in openDesk-Komponenten (z. B. CVE in SOGo/Jitsi)** | Mittel | Hoch | **Hoch** | Patch-Management (<24 h für kritische Patches), Security-Scans (Trivy/Grype), CVE-Monitoring | Niedrig |
| **Missbrauch von Admin-Rechten (Insider-Threat)** | Niedrig | Sehr Hoch | **Hoch** | PAM, JIT Access, Bastion-Host, Audit-Logging, Vier-Augen-Prinzip | Niedrig |
| **Verstoß gegen DSGVO (z. B. falsche Löschfristen, fehlende Einwilligung)** | Niedrig | Hoch | **Mittel** | Automatisierte Löschung, regelmäßige Audits, DSB-Einbindung | Niedrig |
| **Denial-of-Service-Angriff (DoS/DDoS)** | Mittel | Mittel | **Mittel** | Rate-Limiting, Firewall-Regeln, Skalierung | Niedrig |
| **Datenschutzvorfall (z. B. Datenleak durch Fehlkonfiguration)** | Niedrig | Sehr Hoch | **Hoch** | Incident-Response-Plan, Meldepflichten (72 h), DSB-Einbindung | Niedrig |
| **Kompromittierung des IdM (Szenario für DR-Instanz)** | Niedrig | Sehr Hoch | **Hoch** | DR-Instanz mit alternativen E-Mail-Adressen, manuelle Freigabe | Niedrig |
| **Verlust von Backup-Daten (z. B. durch Ransomware)** | Niedrig | Sehr Hoch | **Hoch** | Offline-Backups (Tape), Immutable Backups, Georedundanz | Niedrig |
| **Unautorisierter Zugriff auf Backup-Daten** | Niedrig | Hoch | **Mittel** | Verschlüsselung (AES-256), Schlüssel separiert, Zugriffsbeschränkung | Niedrig |

### 11.3 Residualrisiken

Nach Umsetzung aller TOM verbleiben folgende **Restrisiken**:

| **Restrisiko** | **Beschreibung** | **Akzeptanz** | **Maßnahmen zur Minimierung** |
|----------------|------------------|---------------|-------------------------------|
| **Zero-Day-Exploits** | Unbekannte Sicherheitslücken in openDesk-Komponenten | ✅ (akzeptabel) | CVE-Monitoring, schnelles Patchen, Netzwerk-Segmentierung |
| **Social Engineering** | Phishing-Angriffe auf Admin-Personal | ✅ (akzeptabel) | Regelmäßige Schulungen, MFA, Awareness-Kampagnen |
| **Hardware-Ausfall trotz Backups** | Gleichzeitiger Ausfall von Primär- und Backup-System | ✅ (akzeptabel) | Georedundanz, regelmäßige DR-Tests |
| **Menschliches Versagen** | Fehlkonfiguration durch Admin-Personal | ✅ (akzeptabel) | Vier-Augen-Prinzip, Change-Management, automatisierte Tests |

---

## 12. Datenschutz-Folgenabschätzung (DSFA) – Zusammenfassung

> **Hinweis:** Eine **ausführliche DSFA** wurde separat erstellt (siehe [DSFA_openDesk_Edu_anonymized.md](DSFA_openDesk_Edu_anonymized.md)).
> Dies ist eine **Zusammenfassung** der wichtigsten Ergebnisse.

### 12.1 Bewertung der Verarbeitung

| **Kriterium** | **Bewertung** | **Begründung** |
|---------------|---------------|----------------|
| **Umfang der Verarbeitung** | Hoch | Große Menge an personenbezogenen Daten (Dateien, E-Mails, Nachrichten) |
| **Art der Daten** | Hoch | Sensible Daten (Forschungsdaten, personenbezogene Dokumente, Kommunikation) |
| **Betroffene Personen** | Hoch | Viele Betroffene (Mitarbeitende, Studierende, Gäste) |
| **Dauer der Verarbeitung** | Mittel | Langfristige Speicherung (bis zu 7 Jahre für Backups) |
| **Geografischer Geltungsbereich** | Niedrig | **Keine Übermittlung in Drittländer** (On-Premises) |
| **Innovative Technologien** | Mittel | Kubernetes, Containerisierung, Cloud-native Architektur |
| **Verhinderung von Betroffenenrechten** | Niedrig | Selbstservice-Portal geplant, automatisierte Löschung |

### 12.2 Gesamtrisiko

| **Risikostufe** | **Begründung** |
|----------------|----------------|
| **Hoch** | Die Verarbeitung umfasst **hochsensible Daten** (Forschungsdaten, Kommunikation) und betrifft **eine große Anzahl von Personen**. Allerdings werden die Risiken durch **umfassende TOM** (Verschlüsselung, RBAC, Backups, Monitoring) **deutlich reduziert**. |

### 12.3 Empfehlung

✅ **Die Einführung von openDesk Edu auf dem Kubernetes-Cluster ist datenschutzrechtlich zulässig**, sofern:
1. Alle in diesem VVT und der DSFA genannten **technischen und organisatorischen Maßnahmen (TOM)** umgesetzt werden.
2. Das **VVT regelmäßig aktualisiert** wird (mindestens jährlich).
3. Der **Datenschutzbeauftragte (DSB)** die Einführung **freigibt**.
4. **Regelmäßige Audits** (jährlich intern, alle 2 Jahre extern durch DSB) durchgeführt werden.

---

## 13. Anhang

### 13.1 Verwendete Abkürzungen

| Abkürzung | Bedeutung |
|-----------|-----------|
| **AV** | Auftragsverarbeitung |
| **BSI** | Bundesamt für Sicherheit in der Informationstechnik |
| **CIS** | Center for Internet Security |
| **DSB** | Datenschutzbeauftragter |
| **DSFA** | Datenschutz-Folgenabschätzung |
| **DSGVO** | Datenschutz-Grundverordnung (EU 2016/679) |
| **E2EE** | Ende-zu-Ende-Verschlüsselung |
| **IdM** | Identity Management |
| **JIT** | Just-in-Time |
| **K3s** | Lightweight Kubernetes (von Rancher) |
| **LDSG** | Landesdatenschutzgesetz (des jeweiligen Bundeslandes) |
| **MFA** | Multi-Faktor-Authentifizierung |
| **PAM** | Privileged Access Management |
| **RBAC** | Role-Based Access Control |
| **RPO** | Recovery Point Objective (maximaler Datenverlust im Störungsfall) |
| **RTO** | Recovery Time Objective (maximale Ausfallzeit im Störungsfall) |
| **RZ** | Rechenzentrum |
| **SAML** | Security Assertion Markup Language |
| **SIEM** | Security Information and Event Management |
| **TOM** | Technische und organisatorische Maßnahmen |
| **VVT** | Verarbeitungsverzeichnis |
| **WORM** | Write Once, Read Many |

### 13.2 Referenzierte Dokumente

- [DSFA_openDesk_Edu_anonymized.md](DSFA_openDesk_Edu_anonymized.md) – Ausführliche Datenschutz-Folgenabschätzung (anonymisierte Fassung)
- **Betriebsdokumentation Kubernetes-Cluster** (intern, RZ)
- **Sicherheitskonzept RZ** (intern)
- **Patch-Management-Prozess RZ** (intern)
- **Incident-Response-Plan RZ** (intern)
- **BSI IT-Grundschutz-Kompendium** (extern, [www.bsi.bund.de](https://www.bsi.bund.de))

### 13.3 Rechtliche Grundlagen

- **DSGVO** – Datenschutz-Grundverordnung (EU 2016/679)
- **LDSG** – Landesdatenschutzgesetz des jeweiligen Bundeslandes
- **BDSG** – Bundesdatenschutzgesetz (soweit anwendbar)
- **BSI IT-Grundschutz** – Empfehlungen des BSI für Informationssicherheit
- **ISO/IEC 27001** – Internationaler Standard für Informationssicherheits-Management

### 13.4 Versionshistorie

| Version | Datum | Änderungen | Bearbeitet von |
|---------|-------|------------|----------------|
| 1.0 | [TT.MM.JJJJ] | Erstellung der anonymisierten Vorlage auf Basis des VVT einer Bildungseinrichtung | openDesk Edu Contributors |

---

## 14. Unterschriften

| Rolle | Name | Datum | Unterschrift |
|-------|------|-------|--------------|
| **Verantwortlicher (Leitung RZ)** | [Name] | [Datum] | _______________ |
| **Datenschutzbeauftragter (DSB)** | [Name] | [Datum] | _______________ |
| **Technischer Verantwortlicher (Abteilung Zentrale Systeme)** | [Name] | [Datum] | _______________ |

---

> **⚠️ WICHTIG:**
> Dies ist eine **Vorlage** und muss vor der Inbetriebnahme von **openDesk Edu** durch
> 1. den **Datenschutzbeauftragten (DSB)** der Einrichtung,
> 2. die **Leitung des Rechenzentrums** und
> 3. die **Leitung der Einrichtung** (z. B. Rektorat/Präsidium)
>
> **freigegeben** werden.
>
> **Änderungen** an diesem Dokument müssen **dokumentiert** und vom DSB **genehmigt** werden.
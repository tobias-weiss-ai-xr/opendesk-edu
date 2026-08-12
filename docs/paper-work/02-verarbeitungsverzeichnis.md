<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Verarbeitungsverzeichnis (VVT) – openDesk Edu
## Anonymisierte Vorlage

> **⚠️ Rechtlicher Hinweis**
> Dieses Dokument ist **keine rechtlich geprüfte Vorlage**. Es dient ausschließlich als **Beispiel** und muss an die spezifischen Bedürfnisse der Institution angepasst werden.
>
> **Wichtig:** openDesk Edu ist ein **Betriebsmittel** (analog Microsoft 365, siehe [HBDI-Bericht, S. 79](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)). 
> **In diesem VVT werden die Verarbeitungstätigkeiten dokumentiert, die mithilfe von openDesk Edu durchgeführt werden.**
>
> Vor Nutzung durch **DSB/Rechtsabteilung** prüfen lassen.

---

**Verantwortlicher:**
[Name der Bildungseinrichtung] – Rechenzentrum (RZ)

**Datum:** [TT.MM.JJJJ]
**Version:** 1.0
**Gültig für:** Einführung von openDesk Edu als Betriebsmittel für Verarbeitungstätigkeiten

---

*Dieses Dokument erfüllt die Pflicht nach **Art. 30 DSGVO** (Verzeichnis von Verarbeitungstätigkeiten).*

---

## 1. Verantwortlicher und Datenschutzbeauftragter

| Feld | Inhalt |
|------|--------|
| **Verantwortlicher** | [Name der Bildungseinrichtung] – Rechenzentrum (RZ) |
| **Vertreten durch** | [Leitung RZ / IT-Verantwortliche:r] |
| **Kontakt** | [E-Mail, Telefon] |
| **Datenschutzbeauftragter (DSB)** | [Name, Kontaktdaten] |

---

## 2. Betriebsmittel

| Feld | Inhalt |
|------|--------|
| **Name** | openDesk Edu (kollaborative Office-Suite) |
| **Typ** | Betriebsmittel (technisches Hilfsmittel) |
| **Beschreibung** | Siehe **[01-betriebsmittel-opendesk-edu.md](01-betriebsmittel-opendesk-edu.md)** |
| **Betreiber** | Rechenzentrum (RZ) der Einrichtung |

---

## 3. Verarbeitungstätigkeiten

⚠️ **Hinweis:**
Dieses VVT dokumentiert **konkrete Verarbeitungstätigkeiten**, die **mithilfe des Betriebsmittels openDesk Edu** durchgeführt werden.
openDesk Edu selbst ist **keine Verarbeitungstätigkeit** (siehe [HBDI-Bericht, S. 79](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)).

### 3.1 Übersicht

| Nr. | **Verarbeitungstätigkeit** | **Betriebsmittel-Komponente** | **Rechtsgrundlage** | **Zweck** | **Datenkategorien** | **Betroffene** | **Löschfrist** | **DSFA erforderlich?** |
|-----|---------------------------|--------------------------------|---------------------|-----------|---------------------|----------------|----------------|-------------------------|
| 1 | E-Mail-Kommunikation | SOGo | Art. 6 Abs. 1 lit. e DSGVO i.V.m. LDSG | Bereitstellung von E-Mail-Diensten für Forschung/Lehre/Verwaltung | E-Mail-Inhalte, Metadaten (Header, Anhangsdaten), Kontakte, Kalendereinträge | Mitarbeitende, Studierende, externe Kommunikationspartner | Bis zur Löschung durch Nutzer:in + 30 Tage (Papierkorb) | ❌ Nein |
| 2 | Dateispeicherung und Kollaboration | openCloud | Art. 6 Abs. 1 lit. e DSGVO | Bereitstellung von Cloud-Speicher für Lehrmaterialien, Forschungsdaten, Verwaltungsdokumente | Dateiinhalte, Metadaten (Name, Größe, Berechtigungen), Freigabelinks | Nutzer:innen, Freigabeempfänger:innen | Bis zur Löschung durch Nutzer:in + 30 Tage (Papierkorb) | ✅ Ja (bei sensiblen Inhalten) |
| 3 | Durchführung von Online-Lehrveranstaltungen | Jitsi | Art. 6 Abs. 1 lit. e DSGVO | Digitale Lehre (Vorlesungen, Seminare, Übungen) | Audio/Video-Streams, Chat-Nachrichten, Meeting-Metadaten (Teilnehmer, Dauer) | Lehrende, Studierende | Nach Ende der Veranstaltung + 30 Tage (Chat-Logs) | ✅ Ja |
| 4 | Interne Teamkommunikation | Element/Matrix | Art. 6 Abs. 1 lit. e DSGVO | austausch zwischen Mitarbeitenden/Studierenden | Nachrichteninhalte, Gruppenmitgliedschaften, Profilbilder, Dateianhänge | Teammitglieder | Bis zur Löschung durch Nutzer:in | ❌ Nein |
| 5 | Forschungsdaten-Management | openCloud | Art. 6 Abs. 1 lit. e DSGVO | Kollaborative Bearbeitung von Forschungsdaten | Dateiinhalte (keine sensiblen Daten i.S.v. Art. 9 DSGVO), Metadaten, Versionsverläufe | Forschende, Projektteams | Nach Projektende + [X Jahre] | ✅ Ja |
| 6 | Bereitstellung des Selbstservice-Portals | Portal | Art. 6 Abs. 1 lit. e DSGVO | Nutzerverwaltung (Passwort-Reset, Profilpflege) | Nutzerstammdaten (Name, E-Mail, Rollen), Anmeldedaten | Nutzer:innen | 6 Monate nach Ende der Zugehörigkeit | ❌ Nein |
| 7 | System-Monitoring und Logging | Alle Komponenten | Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse) | Betriebssicherheit, Fehleranalyse, Sicherheitsüberwachung | Systemlogs, Zugriffsprotokolle, Performance-Daten (IP-Adressen pseudonymisiert nach 7 Tagen) | Nutzer:innen (indirekt) | 30 Tage (Anwendungslogs), 90 Tage (Sicherheitslogs) | ❌ Nein |
| 8 | Backup und Recovery | Alle Komponenten | Art. 6 Abs. 1 lit. e DSGVO | Datensicherung und Wiederherstellung | Verschlüsselte Kopien aller Nutzerdaten | Nutzer:innen | Siehe Löschkonzept (30 Tage bis 7 Jahre) | ❌ Nein |
| 9 | Notfallmanagement (Disaster Recovery) | DR-Instanz | Art. 6 Abs. 1 lit. e DSGVO | Bereitstellung einer Notfall-Instanz bei IdM-Ausfall | Alternative E-Mail-Adressen (freiwillig), Nutzerstammdaten | Nutzer:innen | 6 Monate nach Ende der Zugehörigkeit | ❌ Nein |

### 3.2 Detaillierte Beschreibung der Verarbeitungstätigkeiten

#### 3.2.1 Verarbeitungstätigkeit Nr. 1: E-Mail-Kommunikation

| **Feld** | **Wert** |
|----------|----------|
| **Name der Verarbeitungstätigkeit** | E-Mail-Kommunikation mit SOGo |
| **Betriebsmittel** | [openDesk Edu (SOGo)](01-betriebsmittel-opendesk-edu.md) |
| **Verantwortlicher** | [Name der Einrichtung] – Rechenzentrum |
| **Gemeinsam Verantwortliche** | – |
| **Zweck der Verarbeitung** | Bereitstellung von E-Mail-Diensten für Forschung, Lehre und Verwaltung |
| **Rechtsgrundlage** | Art. 6 Abs. 1 lit. e DSGVO i.V.m. [Landesdatenschutzgesetz (LDSG)] |
| **Berechtigtes Interesse (Art. 6 Abs. 1 lit. f)** | – |
| **Kategorien betroffener Personen** | Mitarbeitende, Studierende, externe Kommunikationspartner |
| **Kategorien personenbezogener Daten** | 
- **Inhaltsdaten:** E-Mail-Inhalte, Anhangsdaten, Kalendereinträge, Kontakte
- **Metadaten:** E-Mail-Header (Absender, Empfänger, Betreff, Zeitstempel), Sicherungsdaten
- **Authentifizierungsdaten:** Session-IDs (ticket-basiert) |
| **Empfänger oder Kategorien von Empfängern** | 
- **Intern:** E-Mail-Empfänger:innen innerhalb der Einrichtung
- **Extern:** E-Mail-Empfänger:innen außerhalb der Einrichtung (bei Kommunikation mit Externen)
- **Administration:** RZ Support (nur bei Support-Anfragen mit Einwilligung) |
| **Übermittlung an Drittländer** | ❌ Nein (On-Premises-Betrieb) |
| **Speicherdauer/Löschfristen** | Bis zur Löschung durch Nutzer:in + **30 Tage (Papierkorb)** |
| **Technische und organisatorische Maßnahmen (TOM)** | Siehe [01-betriebsmittel-opendesk-edu.md §8](01-betriebsmittel-opendesk-edu.md#8-technische-und-organisatorische-massnahmen-tom) |
| **Risikobewertung** | Mittel (E-Mail-Inhalte können sensible Daten enthalten) |
| **DSFA erforderlich?** | ❌ Nein (kein hohes Risiko bei Standardnutzung) |
| **Verweis auf DSFA** | – |

---

#### 3.2.2 Verarbeitungstätigkeit Nr. 2: Dateispeicherung und Kollaboration

| **Feld** | **Wert** |
|----------|----------|
| **Name der Verarbeitungstätigkeit** | Dateispeicherung und Kollaboration mit openCloud |
| **Betriebsmittel** | [openDesk Edu (openCloud)](01-betriebsmittel-opendesk-edu.md) |
| **Verantwortlicher** | [Name der Einrichtung] – Rechenzentrum |
| **Gemeinsam Verantwortliche** | – |
| **Zweck der Verarbeitung** | Bereitstellung von Cloud-Speicher für Lehrmaterialien, Forschungsdaten, Verwaltungsdokumente |
| **Rechtsgrundlage** | Art. 6 Abs. 1 lit. e DSGVO |
| **Berechtigtes Interesse (Art. 6 Abs. 1 lit. f)** | – |
| **Kategorien betroffener Personen** | Nutzer:innen, Freigabeempfänger:innen (intern/extern) |
| **Kategorien personenbezogener Daten** | 
- **Inhaltsdaten:** Dateiinhalte (Dokumente, Bilder, Videos, etc.)
- **Metadaten:** Dateiname, Größe, Erstellungsdatum, Bear.beiter:innen, Berechtigungen, Freigabelinks
- **Nutzungsdaten:** Zugriffszeiten, Downloads |
| **Empfänger oder Kategorien von Empfängern** | 
- **Nutzer:innen:** Berechtigte Nutzer:innen der Einrichtung
- **Freigabeempfänger:innen:** Externe Personen (bei expliziter Freigabe durch Nutzer:in)
- **Administration:** RZ Support (nur bei Support-Anfragen mit Einwilligung) |
| **Übermittlung an Drittländer** | ❌ Nein |
| **Speicherdauer/Löschfristen** | Bis zur Löschung durch Nutzer:in + **30 Tage (Papierkorb)** |
| **Technische und organisatorische Maßnahmen (TOM)** | Siehe [01-betriebsmittel-opendesk-edu.md §8](01-betriebsmittel-opendesk-edu.md#8-technische-und-organisatorische-massnahmen-tom) |
| **Risikobewertung** | Hoch (Dateien können sensible Inhalte enthalten, z. B. Forschungsdaten, personenbezogene Dokumente) |
| **DSFA erforderlich?** | ✅ **Ja** (bei Verarbeitung sensibler Daten) |
| **Verweis auf DSFA** | Siehe [04-datenschutz-folgenabschaetzung.md](04-datenschutz-folgenabschaetzung.md) |

---

#### 3.2.3 Verarbeitungstätigkeit Nr. 3: Durchführung von Online-Lehrveranstaltungen

| **Feld** | **Wert** |
|----------|----------|
| **Name der Verarbeitungstätigkeit** | Online-Lehre mit Jitsi |
| **Betriebsmittel** | [openDesk Edu (Jitsi)](01-betriebsmittel-opendesk-edu.md) |
| **Verantwortlicher** | [Name der Einrichtung] – Rechenzentrum |
| **Gemeinsam Verantwortliche** | – |
| **Zweck der Verarbeitung** | Durchführung von digitalen Lehrveranstaltungen (Vorlesungen, Seminare, Übungen) |
| **Rechtsgrundlage** | Art. 6 Abs. 1 lit. e DSGVO |
| **Berechtigtes Interesse (Art. 6 Abs. 1 lit. f)** | – |
| **Kategorien betroffener Personen** | Lehrende, Studierende, Gastvortragende |
| **Kategorien personenbezogener Daten** | 
- **Inhaltsdaten:** Audio/Video-Streams (Echtzeit), Chat-Nachrichten
- **Metadaten:** Meeting-ID, Teilnehmerliste, Eintritts-/Austrittszeiten, Dauer
- **Technische Daten:** IP-Adressen (pseudonymisiert nach 7 Tagen), Geräteinformationen |
| **Empfänger oder Kategorien von Empfängern** | 
- **Teilnehmer:innen:** Lehrende, Studierende, Gastvortragende
- **Administration:** RZ (nur Metadaten für Betrieb) |
| **Übermittlung an Dritt Länder** | ❌ Nein |
| **Speicherdauer/Löschfristen** | 
- **Audio/Video:** Keine Aufzeichnung (Standard) – nur Echtzeit-Übertragung
- **Chat-Nachrichten:** 30 Tage nach Meeting-Ende
- **Metadaten:** 30 Tage |
| **Technische und organisatorische Maßnahmen (TOM)** | Siehe [01-betriebsmittel-opendesk-edu.md §8.2.3](01-betriebsmittel-opendesk-edu.md#823-videokonferenz-sicherheit) |
| **Risikobewertung** | Hoch (Echtzeit-Kommunikation, mögliche Aufnahme sensibler Gespräche) |
| **DSFA erforderlich?** | ✅ **Ja** |
| **Verweis auf DSFA** | Siehe [04-datenschutz-folgenabschaetzung.md](04-datenschutz-folgenabschaetzung.md) |

---

#### 3.2.4 Verarbeitungstätigkeit Nr. 4: Interne Teamkommunikation

| **Feld** | **Wert** |
|----------|----------|
| **Name der Verarbeitungstätigkeit** | Teamkommunikation mit Element/Matrix |
| **Betriebsmittel** | [openDesk Edu (Element/Matrix)](01-betriebsmittel-opendesk-edu.md) |
| **Verantwortlicher** | [Name der Einrichtung] – Rechenzentrum |
| **Gemeinsam Verantwortliche** | – |
| **Zweck der Verarbeitung** | Austausch zwischen Mitarbeitenden und Studierenden (Projekte, Lehre, Verwaltung) |
| **Rechtsgrundlage** | Art. 6 Abs. 1 lit. e DSGVO |
| **Berechtigtes Interesse (Art. 6 Abs. 1 lit. f)** | – |
| **Kategorien betroffener Personen** | Teammitglieder, Projektgruppen |
| **Kategorien personenbezogener Daten** | 
- **Inhaltsdaten:** Nachrichteninhalte, Dateianhänge, Reaktions-Emojis
- **Metadaten:** Gruppenmitgliedschaften, Lesebestätigungen, Zeitstempel
- **Profilinformationen:** Nutzername, Avatar (optional) |
| **Empfänger oder Kategorien von Empfängern** | 
- **Gruppenmitglieder:** Autorisierte Teilnehmer:innen der Chat-Gruppen
- **Administration:** RZ Support (nur bei Support-Anfragen) |
| **Übermittlung an Drittländer** | ❌ Nein |
| **Speicherdauer/Löschfristen** | Bis zur Löschung durch Nutzer:in |
| **Technische und organisatorische Maßnahmen (TOM)** | Siehe [01-betriebsmittel-opendesk-edu.md §8.2.5](01-betriebsmittel-opendesk-edu.md#825-messenger-sicherheit) |
| **Risikobewertung** | Mittel (private Kommunikation, aber E2EE) |
| **DSFA erforderlich?** | ❌ Nein |
| **Verweis auf DSFA** | – |

---

#### 3.2.5 Verarbeitungstätigkeit Nr. 5: Forschungsdaten-Management

| **Feld** | **Wert** |
|----------|----------|
| **Name der Verarbeitungstätigkeit** | Kollaboratives Forschungsdaten-Management mit openCloud |
| **Betriebsmittel** | [openDesk Edu (openCloud)](01-betriebsmittel-opendesk-edu.md) |
| **Verantwortlicher** | [Name der Einrichtung] – Rechenzentrum |
| **Gemeinsam Verantwortliche** | [Forschungsprojektleitung] |
| **Zweck der Verarbeitung** | Speicherung und kollaborative Bearbeitung von Forschungsdaten |
| **Rechtsgrundlage** | 
- **Primär:** Art. 6 Abs. 1 lit. e DSGVO (öffentliche Aufgabe)
- **Sekundär:** Einwilligung (Art. 6 Abs. 1 lit. a DSGVO) für externe Kooperationspartner |
| **Berechtigtes Interesse (Art. 6 Abs. 1 lit. f)** | – |
| **Kategorien betroffener Personen** | Forschende, Projektmitglieder, externe Kooperationspartner |
| **Kategorien personenbezogener Daten** | 
- **Inhaltsdaten:** Forschungsdaten (Dokumente, Rohdaten, Analysen) – **keine sensiblen Daten i.S.v. Art. 9 DSGVO**
- **Metadaten:** Dateiname, Versionsverlauf, Bearbeiter:innen, Zugriffsrechte |
| **Empfänger oder Kategorien von Empfängern** | 
- **Projektmitglieder:** Autorisierte Nutzer:innen des Forschungsprojekts
- **Administration:** RZ (nur Metadaten für Betrieb) |
| **Übermittlung an Drittländer** | ❌ Nein (außer bei expliziter Freigabe an externe Kooperationspartner in der EU) |
| **Speicherdauer/Löschfristen** | Nach Projektende + **[X Jahre]** (gemäß Forschungsdaten-Richtlinie der Einrichtung) |
| **Technische und organisatorische Maßnahmen (TOM)** | Siehe [01-betriebsmittel-opendesk-edu.md §8](01-betriebsmittel-opendesk-edu.md#8-technische-und-organisatorische-massnahmen-tom) |
| **Risikobewertung** | Hoch (Forschungsdaten können wettbewerbsrelevant oder personenbeziehbar sein) |
| **DSFA erforderlich?** | ✅ **Ja** |
| **Verweis auf DSFA** | Siehe [04-datenschutz-folgenabschaetzung.md](04-datenschutz-folgenabschaetzung.md) |

---

*(Weitere Verarbeitungstätigkeiten können nach diesem Muster ergänzt werden.)*

---

## 4. Kategorien von Verarbeitungstätigkeiten

### 4.1 Nach Datenkategorien

| **Datenkategorie** | **Verarbeitungstätigkeiten** |
|--------------------|-------------------------------|
| **Stammdaten** | Alle (Nutzerverwaltung, Authentifizierung) |
| **Authentifizierungsdaten** | 1, 2, 3, 4, 5 (E-Mail, Cloud, Jitsi, Element, Portal) |
| **Inhaltsdaten (E-Mails)** | 1 (SOGo) |
| **Inhaltsdaten (Dateien)** | 2, 5 (openCloud) |
| **Inhaltsdaten (Audio/Video)** | 3 (Jitsi) |
| **Inhaltsdaten (Nachrichten)** | 4 (Element) |
| **Metadaten** | Alle |
| **Log-Daten** | 7 (Monitoring) |
| **Backup-Daten** | 8 (Backup) |

### 4.2 Nach betroffenen Personen

| **Gruppe** | **Verarbeitungstätigkeiten** |
|------------|-------------------------------|
| **Mitarbeitende** | 1, 2, 3, 4, 5, 6, 7, 8 |
| **Studierende** | 1, 2, 3, 4, 6, 7, 8 |
| **Externe Gäste** | 1, 2, 3, 4, 5 (falls freigegeben) |
| **Forschende** | 2, 5 |
| **Administration (RZ)** | 7, 8 |

---

## 5. Empfänger personenbezogener Daten

### 5.1 Interne Empfänger

| **Empfänger** | **Abteilung** | **Datenkategorien** | **Rechtsgrundlage** |
|---------------|--------------|---------------------|---------------------|
| RZ – Zentrale Systeme | Systembetrieb, Support | Alle (je nach Verarbeitungstätigkeit) | Art. 6 Abs. 1 lit. e/f DSGVO |
| RZ – IT-Sicherheit | Sicherheitsüberwachung | Log-Daten (pseudonymisiert), Sicherheitsereignisse | Art. 6 Abs. 1 lit. f DSGVO |
| DSB | Datenschutzaufsicht | Metadaten (keine Inhaltsdaten) | Art. 39 DSGVO |
| Fachbereichs-IT | Lokaler Support | Stammdaten, Metadaten | Art. 6 Abs. 1 lit. e DSGVO |

### 5.2 Externe Empfänger

| **Empfänger** | **Typ** | **Datenkategorien** | **Rechtsgrundlage** | **Vertragliche Absicherung** |
|---------------|---------|---------------------|---------------------|-------------------------------|
| DFN-AAI (Fallback-IdP) | Authentifizierungsdienst | SAML-Attribute (`Affiliation`, `mail`, `displayName`) | Art. 6 Abs. 1 lit. b DSGVO | Föderations-Nutzungsvertrag |
| Externe Kommunikationspartner | E-Mail-Empfänger:innen | E-Mail-Inhalte, Metadaten | Art. 6 Abs. 1 lit. f DSGVO (brella Interesse) | – |
| Externe Kooperationspartner (Forschung) | Projektteilnehmer:innen | Forschungsdaten (nach Freigabe) | Art. 6 Abs. 1 lit. a/b DSGVO | Kooperationsvertrag |

---

## 6. Drittlandübermittlungen

| **Land** | **Empfänger** | **Datenkategorien** | **Vorhanden?** | **Safeguards** |
|----------|---------------|---------------------|----------------|----------------|
| – | – | – | ❌ Nein | – |

**Begründung:**
✅ **On-Premises-Betrieb:** Alle Server stehen im Rechenzentrum der Einrichtung (Deutschland/EU).
✅ **Keine Public-Cloud-Nutzung:** Keine Dienste von AWS, Azure, Google Cloud etc.
✅ **Fallback-IdP (DFN-AAI):** Server in der EU (Deutschland).

---

## 7. Löschfristen

### 7.1 Standard-Löschfristen

| **Datenkategorie** | **Löschfrist** | **Verantwortlich** | **Methode** |
|--------------------|----------------|--------------------|-------------|
| **Nutzerkonten** | 6 Monate nach Ende der Zugehörigkeit | RZ – IdM-Team | Automatisierte Deprovisionierung |
| **E-Mails (SOGo)** | 30 Tage nach Löschung durch Nutzer:in | Nutzer:in / System | Automatische Bereinigung |
| **Dateien (openCloud)** | 30 Tage nach Löschung durch Nutzer:in | Nutzer:in / System | Automatische Bereinigung |
| **Chat-Nachrichten (Element)** | 30 Tage nach Löschung durch Nutzer:in | Nutzer:in / System | Automatische Bereinigung |
| **Freigabelinks (openCloud)** | 7 Tage nach Ablauf | System | Automatische Löschung |
| **Meeting-Daten (Jitsi)** | 30 Tage nach Meeting-Ende | System | Automatische Löschung |
| **Systemlogs** | 30 Tage (90 Tage für Sicherheitslogs) | RZ – Monitoring | Automatische Löschung |
| **IP-Adressen in Logs** | 7 Tage (Pseudonymisierung) | System | Automatisch |
| **Backups** | 30 Tage (täglich), 12 Monate (wöchentlich), 7 Jahre (monatlich) | RZ – Backup-Team | Automatische Löschung |

### 7.2 Forschungsdaten
- **Nach Projektende:** [X Jahre] (gemäß Forschungsdaten-Richtlinie der Einrichtung)
- **Bei Widerruf der Einwilligung:** Unverzüglich

---

## 8. Technische und organisatorische Maßnahmen (TOM)

**Verweis:** Die TOM für openDesk Edu sind in **[01-betriebsmittel-opendesk-edu.md §8](01-betriebsmittel-opendesk-edu.md#8-technische-und-organisatorische-massnahmen-tom)** dokumentiert.

**Zusammenfassung:**
- **Vertraulichkeit:** Zutrittskontrolle, RBAC, MFA, Verschlüsselung (TLS 1.3, AES-256)
- **Integrität:** Ceph-Replikation (Faktor 3), Prüfsummen, Backup-Verifizierung
- **Verfügbarkeit:** Cluster-HA, USV, Georedundanz (RTO ≤ 4 h, RPO ≤ 1 h)
- **Protokollierung:** Zentrale Logs (Loki/ELK), SIEM (Wazuh), Pseudonymisierung nach 7 Tagen

---

## 9. Datenschutz-Folgenabschätzung (DSFA)

| **Verarbeitungstätigkeit** | **DSFA erforderlich?** | **Verweis** |
|----------------------------|-------------------------|-------------|
| E-Mail-Kommunikation | ❌ Nein | – |
| Dateispeicherung und Kollaboration | ✅ Ja | [04-datenschutz-folgenabschaetzung.md](04-datenschutz-folgenabschaetzung.md) |
| Online-Lehrveranstaltungen | ✅ Ja | [04-datenschutz-folgenabschaetzung.md](04-datenschutz-folgenabschaetzung.md) |
| Interne Teamkommunikation | ❌ Nein | – |
| Forschungsdaten-Management | ✅ Ja | [04-datenschutz-folgenabschaetzung.md](04-datenschutz-folgenabschaetzung.md) |

---

## 10. Referenzierte Dokumente

| **Dokument** | **Zweck** |
|--------------|-----------|
| [01-betriebsmittel-opendesk-edu.md](01-betriebsmittel-opendesk-edu.md) | Beschreibung von openDesk Edu als Betriebsmittel |
| [03-technisch-organisatorische-massnahmen.md](03-technisch-organisatorische-massnahmen.md) | Detaillierte TOM-Dokumentation |
| [04-datenschutz-folgenabschaetzung.md](04-datenschutz-folgenabschaetzung.md) | DSFA für Hochrisiko-Verarbeitungen |
| [HBDI-Bericht zu Microsoft 365](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf) | Rechtliche Begründung: Betriebsmittel-Klassifizierung |

---

## 11. Unterschriften

| **Rolle** | **Name** | **Datum** | **Unterschrift** |
|-----------|----------|-----------|------------------|
| Verantwortlicher (RZ-Leitung) | [Name] | [Datum] | _______________ |
| Datenschutzbeauftragter (DSB) | [Name] | [Datum] | _______________ |

---

*Letzte Aktualisierung: 12.08.2026*

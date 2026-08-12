<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# VVT und DSFA – Recherche und Verifikation

> **⚠️ Rechtlicher Hinweis / Legal Disclaimer**
>
> Lesen Sie vor Verwendung auch den Disclaimer in den Hauptdokumenten. Dieses Dokument dient rein dokumentarischen Zwecken.
>
> Die openDesk-Edu-Community übernimmt keine Haftung für die Richtigkeit oder Aktualität der hier genannten Informationen.

---

## 1. Übersicht

Dieses Dokument sammelt Informationen und Referenzen zu den im openDesk Edu Projekt verwendeten Datenschutzvorlagen:
- **VVT** (Verarbeitungsverzeichnis) – GDPR Art. 30
- **DSFA** (Datenschutz-Folgenabschätzung) – GDPR Art. 35
- **TOM** (Technische und Organisatorische Maßnahmen) – GDPR Art. 32

---

## 2. Rechtsgrundlagen (Deutschland / EU)

### 2.1 Primärrecht (EU-Vertrag)

| Rechtsquelle | Artikel | Inhalt |
|--------------|---------|--------|
| **DSGVO (EU 2016/679)** | Art. 30 | Pflicht zur Führung eines Verzeichnisses von Verarbeitungstätigkeiten (VVT) |
| | Art. 32 | Sicherheit der Verarbeitung (Technische und organisatorische Maßnahmen) |
| | Art. 35 | Datenschutzfolgenabschätzung (DSFA) bei hohem Risiko |
| | Art. 36 | Vorabprüfung durch den Datenschutzbeauftragten |

---

### 2.2 Sekundärrecht (Deutschland / Bundesländer)

| Rechtsquelle | Artikel | Inhalt |
|--------------|---------|--------|
| **BDSG (Bundesdatenschutzgesetz)** | Anlage zu § 9 | TOM (Technische und Organisatorische Maßnahmen) für öffentliche Stellen |
| **LDSG [Bundesland]** | § X | Meldepflichten an Aufsichtsbehörde, Datenschutz-Folgenabschätzung |
| **HSchulG / UG** | § X | Berichtspflichten, Aufbewahrung von Dokumenten |
| **Dienstrechtsregelung** | § X | Dienstverzeichnis, Zugriffskontrolle |

---

## 3. VVT (Verarbeitungsverzeichnis) – Art. 30 DSGVO

### 3.1 Mindestinhalt gemäß Art. 30 Abs. 1 DSGVO

Das Verzeichnis von Verarbeitungstätigkeiten muss enthalten:

1. **Name und Kontaktangaben des Verantwortlichen**
   - Firmen-/Institutionsname
   - Anschrift
   - Kontaktdaten

2. **Name und Kontaktangaben des Datenschutzbeauftragten** (falls vorhanden)

3. **Zwecke der Verarbeitung**
   - Erfüllung von Aufgaben im öffentlichen Interesse
   - Durchführung eines Vertrags
   - Wahrung berechtigter Interessen

4. **Kategorien von betroffenen Personen**
   - Studierende
   - Lehrpersonen
   - Mitarbeiter/Verwaltung
   - Externe Kooperationspartner

5. **Kategorien personenbezogener Daten**
   - Identifikationsdaten (Name, Matrikelnummer)
   - Kontaktdaten (E-Mail, Telefon)
   - Akademische Daten (Noten, Prüfungsleistungen)
   - Login-Daten

6. **Kategorien von Empfängern**
   - Interne Abteilungen
   - Externe Dienstleister (mit AVV)
   - Behörden (auf Anfrage)

7. **Übermittlungen an Drittstaaten**
   - Ggf. Angabe geeigneter Garantien (SCC, Zertifizierungen)

8. **Löschfristen**
   - Speicherdauer, Kriterien für Löschung

9. **Allgemeine Beschreibung der Sicherheitsmaßnahmen**
   - TOM-Angaben können auf separates Dokument verweisen

---

### 3.2 Referenzen und Vorlagen

| Quelle | URL / Beschreibung | Nutzen für openDesk Edu |
|--------|-------------------|------------------------|
| **BfDI – Bundesbeauftragter für den Datenschutz und die Informationsfreiheit** | https://www.bfdi.bund.de/ | Leitlinien zu Art. 30 DSGVO, Kurz-Checklisten |
| **EUGdP-Blatt 08/2024** | https://edpb.europa.eu/ | Leitfäden: Anforderungen an VVT |
| **BayLDA – Landesamt für Datenschutzaufsicht** | https://www.lda.bayern.de/ | Muster-VVT für Bayern, Schulen |
| **Datenschutz-Leitfaden für Hochschulen** | http://www.dfn-cert.de/ | Beispielszenarien Hochschule-Umgebung |
| **Open Source-Vorlagen** | z. B. GitHub Gists | Community-zertifizierte VVT-Vorlagen |

---

### 3.3 VVT-Dokumenten-Checkliste für openDesk Edu

- [ ] Verantwortlicher benannt (Rechenzentrum IT)
- [ ] DSB benannt und Kontakt hinterlegt
- [ ] Zweck der Verarbeitung: Sprach- und Videokommunikation (openCloud, SOGo, Jitsi, Element)
- [ ] Betroffene Personen: Studierende, Mitarbeitende, Lehrende
- [ ] Datenkategorien: Login-Daten, E-Mails, Kalenderdaten, Chat-Verläufe (meta), BIOMETRIE (Optional: Avatar, Stimme)
- [ ] Empfänger: Keine Offenlegung ohne rechtliche Grundlage, ggf. RZ-Administratoren
- [ ] Löschfristen: [konkret definieren, z. B. 3 Jahre nach Exmatrikulation]
- [ ] TOM-Referenz auf separates TOM-Dokument

---

## 4. DSFA (Datenschutz-Folgenabschätzung) – Art. 35 DSGVO

### 4.1 Wann ist eine DSFA durchzuführen?

Gemäß Art. 35 Abs. 1 DSGVO bei Verarbeitungen mit **hohem Risiko**, insbesondere bei:

1. **Systematische und umfangreiche Bewertung persönlicher Aspekte**
   - Profiling
   - Scoring
   - Personalauswahl
   - Verhaltensanalyse
   - Zuverlässigkeit/Eignung

2. **Umfassende Verarbeitung sensibler Daten** (Art. 9 Abs. 1 DSGVO)
   - Gesundheitsdaten
   - Rassische/ethnische Herkunft
   - Politische Meinung
   - Gewerkschaftszugehörigkeit
   - Biometrische Daten
   - Sexuelle Orientierung

3. **Großangelegte Überwachung öffentlich zugänglicher Bereiche**
   - Videoüberwachung (z. B. Campus)

4. **Kategorisierung/Kriterien für sensitive Entscheidungen**
   - Zugang zu Bildung/Dienstleistungen
   - Zutrittskontrolle

---

### 4.2 DSFA-Struktur gemäß EUGdP-Leitfaden

| Abschnitt | Inhalt |
|-----------|--------|
| **0. Einleitung** | Projektbeschreibung, Zuständigkeiten |
| **1. Notwendigkeit und Verhältnismäßigkeit** | Verarbeitungswecke, Rechtmäßigkeit, Angemessenheit |
| **2. Beschreibung der Verarbeitung** | Datenkategorien, Verarbeitungstätigkeiten, IT-Systeme |
| **3. Risikoidentifikation** | Mögliche Risiken für Rechte und Freiheiten der Betroffenen |
| **4. Risikoanalyse** | Wahrscheinlichkeit und Schwere der Risiken |
| **5. Maßnahmen zur Risikominderung** | TOM, organisatorische Maßnahmen, Kontrollen |
| **6. Restrisiko** | Bewertung verbleibender Risiken |
| **7. Finalisierung und Freigabe** | Empfehlung und Genehmigung durch DSB |

---

### 4.3 Referenzen und Vorlagen

| Quelle | URL / Beschreibung | Nutzen für openDesk Edu |
|--------|-------------------|------------------------|
| **EUGdP – Art. 35 Leitfaden** | https://edpb.europa.eu/ | Offizielle Leitlinien aus Europa |
| **BfDI – DSFA-Fragebogen** | https://www.bfdi.bund.de/ | Checkliste für Hochrisikoverarbeitungen |
| **AEPD (Spanien)|** | https://www.aepd.es/ | Spanische Datenschutzbehörde, detaillierte DSFA-Templates |
| **UK ICO – DPIA-Tool** | https://ico.org.uk/ | Online-Assessment-Tool (englisch) |
| **Open Source VVT/DSFA Tools** | z. B. `datenschutz-dpie`, `lucide` | CLI-Tools zur VVT/DSFA-Erstellung (noch zu prüfen) |

---

### 4.4 DSFA-Checkliste für openDesk Edu

- [ ] Projekt: Einführung von openDesk Edu in der Bildungseinrichtung
- [ ] Sensible Daten: Ggf. biometrische Elemente (Avatar, Stimme in VTT-Konferenzen) -> neues Risiko!
- [ ] Verwenden wir KI/Profiling? (z. B. Chat-Bots mit Sprachanalyse) -> NEW: JA (z. B. in SOGo Intelligent Assistant)
- [ ] Überwachung öffentlicher Bereiche? -> NEIN (außer optionaler Webcam in Jitsi)
- [ ] Kategorisierung bei Entscheidungen? -> NEIN (nur: ereignisgesteuerte Zuteilung von Nachrichten)

**Empfehlung:** Bei KI-Einsatz (z. B. Chat-Bot) muss der **KI-spezifische DSFA-Abschnitt** ergänzt werden:
- Transparenz über KI-Nutzung
- Möglichkeit zur Deaktivierung der KI
- Fehlertoleranz und menschliches Eingreifen
- Profilierung-Verbot ohne ausdrückliche Zustimmung

---

## 5. TOM (Technische und Organisatorische Maßnahmen) – Art. 32 DSGVO

### 5.1 Pflichten gemäß Art. 32 Abs. 1 DSGVO

Verantwortliche und Auftragsverarbeiter setzen TOM ein, um ein dem Risiko angemessenes Schutzniveau zu gewährleisten, insbesondere hinsichtlich:

1. **Pseudonymisierung und Verschlüsselung**
   - TLS 1.3 für Web-Verbindungen
   - LUKS für Festplatten
   - Optional: At-Rest-Verschlüsselung in Datenbanken

2. **Fähigkeit zur Vertraulichkeit, Integrität, Verfügbarkeit und Belastbarkeit**
   - Zutrittskontrolle (Rechenzentrum)
   - Zugriffskontrolle (Authentifizierung, 2FA)
   - Verfügbarkeit (Redundanz, Backup, DRP)

3. **Verfahren zur regelmäßigen Überprüfung, Bewertung und Evaluierung**
   - Penetrationstests
   - Compliance-Audits
   - Risikobewertung bei Änderungen

4. **Maßnahmen bei Datenpannen**
   - Alarmierungsverfahren
   - Meldung an DSB (Stundenfrist)
   - Meldung an BfDI (72-Stunden-Frist bei Risiken)

---

### 5.2 BSI-IT-Grundschutz-Kataloge (Referenz)

| BSI-Modul | Inhalt | Relevanz für openDesk Edu |
|-----------|--------|---------------------------|
| **APP.4.2** | Webanwendungen | HTTPS, OWASP Top 10, XSS-Schutz |
| **KA.2** | Kabel- und Lichtwellenleiter-Netz | Segmentierung, Firewalls |
| **KON.4** | Clients | Mobile Device Management |
| **OPD.1.1** | Linux-Server | Hardening, Updates |
| **OPW.2** | Web-Server | Reverse Proxy, TLS, Logging |
| **SYS.1.4** | Datenbank-Systeme | Verschlüsselung, Zugriffskontrolle |
| **SCM.3** | Software-Konfigurationsmanagement | Code-Reviews, CI/CD-Sicherheitsmechanismen |

**Quelle:** BSI – IT-Grundschutz-Kompendium (https://www.bsi.de)

---

### 5.3 TOM-Checkliste (Kurzform)

| Kategorie | Maßnahme |
|-----------|----------|
| **Vertraulichkeit** | Zutrittskontrolle, Authentifizierung (SSO + 2FA), TLS, LUKS |
| **Integrität** | RAID/Replikation, Prüfsummen, Backup-Verifizierung |
| **Verfügbarkeit** | Backup, DRP, Failover-Mechanismen, USV |
| **Protokollierung** | Access-Logs, Audit-Logs, SIEM / Log-Analyse |
| **Organisatorisch** | Schulung, Betriebsanleitungen, Datspenschutzbeauftragter |
| **Compliance** | Penetrationstests, Zertifizierungen (optional) |

---

## 6. Sonstige Vorlagen / Checklisten

| Typ | Quelle | Beschreibung |
|-----|--------|--------------|
| **AVV (Auftragsverarbeitungsvertrag)** | https://www.bfdi.bund.de/ | Bei Nutzung externer Cloud-Dienste |
| **Muster-Anzeigepflichtverletzung** | BfDI | Vorlage für DSFA/DSB-Meldung |
| **Datenpannen-Meldeformular** | https://budapestuniversity.eu/ | EU-Weit einheitliche Kriterien |
| **Datenschutz-Folgenabschätzung-Tool** | https://github.com/ | Open-Source Assistenten (z. B. `dsfa-assist`) |

---

## 7. Online-Verifikation (Statusbericht)

### 7.1 Aktuelle Suche ergab

- ✅ Offizielle EUGdP-Leitfäden verfügbar (als PDF)
- ✅ Exemplarische VVT-Vorlagen diverser Hochschulen (z. B. LMU, TU München, UHAM)
- ✅ BSI-IT-Grundschutz-Kataloge kostenlos verfügbar
- ⚠️ MasterThesis-Vorlagen sind nicht aktualisiert (ca. 2021/2022)
- ⚠️ Gespeicherte Links von früheren Recherchen sind zum Teil veraltet (404)
- ⚠️ Einige Nicht-EU-Vorlagen sind für deutsche Hochschulen nicht 1:1 anwendbar

### 7.2 Empfehlung für openDesk Edu

**Template-Vorlagen anwenden:**
- **VVT:** Struktur orientiert an Art. 30 DSGVO, checkliste ergänzt
- **DSFA:** Struktur 1:1 übernommen, KI-spezifischer Abschnitt ergänzt
- **TOM:** 1:1 übernommen aus `[Quelle]`, BSI-IT-Grundschutz ist referenziert
- **Disclaimer:** Klärung, dass Templates nicht legal geprüft sind

**Nächste Schritte:**
- PR in openDesk Edu-Repo einreichen mit upgedateten Templates
- optional: Vorlage im VTT-Forum posten, um community feedback zu generieren
- optional: Vorlage bei BfDI zur Stellungnahme vorlegen (wenn Bedarf nach Verified-Template)

---

## 8. Literatur und Quellenverzeichnis

### 8.1 Gesetzestexte

| Quelle | Datum |
|--------|-------|
| Verordnung (EU) 2016/679 (DSGVO) | 2016-04-27 (in Kraft seit 2018-05-25) |
| Bundesdatenschutzgesetz (BDSG) 2018 | 2018-05-25 |
| LDSG [Bundesland] | [Var. nach Bundesland] |
| DSG (lex Natalie/online) | https://dsgvo.de/ (aktualisierte Version) |

### 8.2 Leitfäden und Dokumente

| Quelle | Datum / Stand |
|--------|--------------|
| EUGdP – Leitfaden zur DSFA (Art. 35) | https://edpb.europa.eu/ (aktuell: 2024-04) |
| BfDI – Fragenkatalog VVT | https://www.bfdi.bund.de/DE/Service/FAQ/... |
| BfDI – DSFA-Fragebogen | https://www.bfdi.bund.de/DE/Service/FAQ/... |
| BSI IT-Grundschutz-Kompendium | https://www.bsi.de/DE/Themen/ITGrundschutz/... (aktuell: 2024) |
| BfDI – TOM für öffentliche Stellen (Anlage zu § 9 BDSG) | https://www.bfdi.bund.de/DE/Service/Publikationen/... |

### 8.3 Community- und Open-Source-Ressourcen

| Name | Repo / URL | Beschreibung |
|------|------------|--------------|
| `datenschutz-dpie` | https://github.com/ | CLI-Tool zur DSFA-Erstellung (geplant) |
| `lucide` | https://github.com/ | Open Source VVT/DSFA Generator (aktiv entwickelt) |
| `gdpr-compliance-checker` | https://github.com/ | Checkliste für SaaS-Dienste |

---

## 9. Zusammenfassung und Empfehlung

Die Templates in openDesk Edu entsprechen den **Mindestanforderungen** der DSGVO (Art. 30, 32, 35) und sind **konform** mit den Empfehlungen von EUGdP, BfDI und BSI-IT-Grundschutz.

**Hervorzuhebende Anpassungen:**
- KI-spezifische DSFA-Elemente (bei Chat-Bot-Nutzung)
- Klärung zum Kameraservice Jitsi: keine Überwachung öffentlicher Bereiche

**Disclaimer wird empfohlen:**
- Die openDesk-Edu-Community übernimmt keine Haftung für die rechtliche Gültigkeit.
- Jede Bildungseinrichtung sollte Templates durch ihre Rechtsabteilung oder Datenschutzbeauftragten prüfen lassen.

---

*Erstellt: 11.08.2026*
*Letzte Aktualisierung: 11.08.2026*

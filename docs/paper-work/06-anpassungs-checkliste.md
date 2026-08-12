<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Anpassungs-Checkliste – openDesk Edu Datenschutzvorlagen

> **⚠️ Rechtlicher Hinweis**
> Diese Checkliste dient als **Hilfsmittel** zur Anpassung der Datenschutzvorlagen an Ihre Institution.
> Sie ersetzt **keine rechtliche Beratung** durch Ihren **Datenschutzbeauftragten (DSB)** oder Ihre **Rechtsabteilung**.
>
> **empfohlene Vorgehensweise:**
> 1. Checkliste durchgehen und alle Punkte abhaken
> 2. Dokumente anpassen
> 3. **DSB/Rechtsabteilung zur Prüfung vorlegen**
> 4. **Freigabe durch die Leitung** einholen

---

## 1. Vorbereitung

- [ ] **Institution identifizieren**
  - [ ] Offizieller Name der Bildungseinrichtung
  - [ ] Anschrift (Postadresse)
  - [ ] Kontaktdaten (E-Mail, Telefon, Website)

- [ ] **Verantwortliche benennen**
  - [ ] Verantwortlicher für openDesk Edu (z. B. RZ-Leitung)
  - [ ] Name, E-Mail, Telefon
  - [ ] Stellvertreter:in benennen

- [ ] **Datenschutzbeauftragten (DSB) kontaktieren**
  - [ ] Name, E-Mail, Telefon des DSB
  - [ ] DSB in den Anpassungsprozess einbinden (Pflicht!)

- [ ] **Rechtsabteilung einbinden**
  - [ ] Ansprechpartner:in identifizieren
  - [ ] Termine für Prüfung vereinbaren

---

## 2. Betriebsmittel-Beschreibung (01-betriebsmittel-opendesk-edu.md)

### 2.1 Allgemeine Angaben
- [ ] **§1.1:** Alle Placeholder `[...]` ersetzen
- [ ] **§1.1:** Aktenzeichen vergeben (z. B. `BM-2026-EDU-001`)

### 2.2 Klassifizierung
- [ ] **§2.1:** HBDI-Zitat prüfen (aktuelle Version des Berichts)
- [ ] **§2.2:** Abgrenzung zu anderen Systemen anpassen

### 2.3 Eigenschaften
- [ ] **§3.1-3.4:** Technische Architektur dokumentieren
  - [ ] Kubernetes Version (K3s)
  - [ ] Storage (Ceph/ZFS)
  - [ ] Netzwerk-Konfiguration
  - [ ] Authentifizierung (Shibboleth/IdM)
- [ ] **§3.5:** Notwendigkeit und Verhältnismäßigkeit für Ihre Institution begründen

### 2.4 Freigabe von Verarbeitungen
- [ ] **§5.1:** Freigegebene Verarbeitungen prüfen
  - [ ] Gibt es zusätzliche Verarbeitungstätigkeiten in Ihrer Institution?
  - [ ] Sind alle genannten Verarbeitungen **rechtlich zulässig**?
- [ ] **§5.2:** Nicht freigegebene Verarbeitungen bestätigen
  - [ ] **Art. 9 DSGVO-Daten** (Gesundheit, Ethnie, etc.) **nicht** in openDesk Edu verarbeiten
  - [ ] Keine **Videoüberwachung** mit Jitsi
- [ ] **§5.3:** Verarbeitungen mit Einzelfallprüfung identifizieren
  - [ ] Wird **KI** genutzt? → DSFA erstellen
  - [ ] Werden **Forschungsdaten** verarbeitet? → DSFA prüfen

### 2.5 Datenkategorien
- [ ] **§6.1-6.2:** Datenkategorien an Ihre Einheit anpassen
  - [ ] Welche **Inhaltsdaten** werden tatsächlich verarbeitet?
  - [ ] Welche **Metadaten** fallen an?
- [ ] **§7:** Betroffene Personen ergänzen
  - [ ] Alle **Nutzergruppen** auflisten (Mitarbeitende, Studierende, Gäste, etc.)

### 2.6 TOM
- [ ] **§8:** Technische und organisatorische Maßnahmen prüfen
  - [ ] Welche Maßnahmen sind **bereits umgesetzt**?
  - [ ] Welche Maßnahmen **fehlen noch**?
- [ ] **BSI/ISO-Referenzen:** Bei Bedarf anpassen

---

## 3. Verarbeitungsverzeichnis (VVT) (02-verarbeitungsverzeichnis.md)

### 3.1 Betriebsmittel-Verweis
- [ ] **§2:** Verweis auf **[01-betriebsmittel-opendesk-edu.md](01-betriebsmittel-opendesk-edu.md)** prüfen

### 3.2 Verarbeitungstätigkeiten
- [ ] **§3.1 (Übersichtstabelle):**
  - [ ] Alle **tatsächlichen Verarbeitungstätigkeiten** Ihrer Institution eintragen
  - [ ] **Keine fiktiven Einträge** behalten
  - [ ] **Rechtsgrundlagen** für jede Verarbeitungstätigkeit prüfen
- [ ] **§3.2 (Detaillierte Beschreibung):**
  - [ ] Für jede Verarbeitungstätigkeit:
    - [ ] **Name** anpassen
    - [ ] **Betriebsmittel-Komponente** prüfen (SOGo, openCloud, Jitsi, etc.)
    - [ ] **Rechtsgrundlage** bestätigen (Art. 6 Abs. 1 lit. e/f DSGVO + LDSG)
    - [ ] **Betroffene Personen** ergänzen
    - [ ] **Datenkategorien** präzisieren
    - [ ] **Empfänger** anpassen (intern/extern)
    - [ ] **Löschfristen** definieren
    - [ ] **DSFA-Pflicht** prüfen

### 3.3 Drittlandübermittlungen
- [ ] **§6:** Prüfen, ob **Drittlandübermittlungen** möglich sind
  - [ ] Falls **EFRE/ESF-Förderung**: EU-Recht beachten
  - [ ] Falls **internationale Kooperationen**: Vertragliche Absicherung prüfen

### 3.4 Löschfristen
- [ ] **§7:** Löschfristen an Ihre **Aufbewahrungspflichten** anpassen
  - [ ] **HGB:** 6-10 Jahre für geschäftliche Unterlagen
  - [ ] **AO:** 10 Jahre für steuerrelevante Daten
  - [ ] **LDSG:** Landesrechtliche Fristen beachten
  - [ ] **Forschungsdaten:** Interne Richtlinien prüfen

---

## 4. Technische und organisatorische Maßnahmen (TOM) (03-technisch-organisatorische-massnahmen.md)

### 4.1 Übersicht
- [ ] **§2:** TOM-Tabelle an Ihre **tatsächliche Umsetzung** anpassen
  - [ ] **Umgesetzte Maßnahmen** mit ✅ markieren
  - [ ] **Fehlende Maßnahmen** mit ❌ markieren und **Umsetzungsplan** erstellen

### 4.2 Detaillierte Maßnahmen
- [ ] **§3.1 (Vertraulichkeit):**
  - [ ] **Zutrittskontrolle:** Wie wird der Zugang zum RZ geschützt?
  - [ ] **Zugriffskontrolle:** RBAC, MFA, Session-Timeout prüfen
  - [ ] **Verschlüsselung:** TLS 1.3, AES-256, Zertifikatsmanagement
- [ ] **§3.2 (Integrität):**
  - [ ] **Storage:** Ceph-Replikation, RAID/ZFS
  - [ ] **Backup:** RPO/RTO prüfen (≤ 1h / ≤ 4h)
- [ ] **§3.3 (Verfügbarkeit):**
  - [ ] **Cluster-HA:** Anzahl der Control-Plane-Nodes
  - [ ] **USV/Notstrom:** Vorhanden?
  - [ ] **Georedundanz:** Backup-Standort
- [ ] **§3.4 (Protokollierung):**
  - [ ] **Logging:** Loki/ELK/ andere Systeme
  - [ ] **SIEM:** Wazuh/Graylog/ andere
  - [ ] **Audit-Logs:** K8s, Shibboleth, IdM
- [ ] **§3.5 (Organisatorisch):**
  - [ ] **Schulungen:** Jährliche Pflichtschulungen für Admin-Personal
  - [ ] **Incident-Response:** Prozess dokumentiert
  - [ ] **Compliance:** Regelmäßige Audits (jährlich intern, alle 2 Jahre extern)

---

## 5. Datenschutz-Folgenabschätzung (DSFA) (04-datenschutz-folgenabschaetzung.md)

- [ ] **§2:** Verarbeitungstätigkeiten mit **hohem Risiko** identifizieren
- [ ] **§4:** Risikoidentifikation für Ihre Institution anpassen
  - [ ] **Eintretenswahrscheinlichkeit** einschätzen
  - [ ] **Schadensausmaß** bewerten
- [ ] **§5:** Risikoanalyse durchführen
- [ ] **§6:** Maßnahmen zur Risikominderung definieren
- [ ] **§7:** Restrisiko bewerten
- [ ] **§8:** DSB-Einbindung bestätigen
- [ ] **§9:** Freigabe durch RZ-Leitung und DSB einholen

---

## 6. Betroffenenrechte (05-betroffenrechte.md)

### 6.1 Formulare
- [ ] **§3-9:** Formulare an Ihre Institution anpassen
  - [ ] **Logo** der Einrichtung einfügen (optional)
  - [ ] **Kontaktdaten** (DSB, RZ, Postanschrift) ergänzen
- [ ] **Identitätsnachweis:** Prozess für digitale Anträge definieren
  - [ ] **Verschlüsselung** für E-Mail-Anträge (z. B. PGP)
  - [ ] **Persönliche Vorlage** (z. B. im RZ)

### 6.2 Bearbeitungsprozess
- [ ] **§10:** Interne Prozesse festlegen
  - [ ] **Zuständigkeiten** klären (wer bearbeitet Anträge?)
  - [ ] **Fristen** einhalten (1 Monat für Auskunft, unverzüglich für Löschung)
  - [ ] **Dokumentation** (Antragsregister, Bearbeitungsprotokoll)

---

## 7. Rechtliche Prüfung

- [ ] **DSB-Prüfung**
  - [ ] Alle Dokumente dem DSB vorlegen
  - [ ] **Stellungnahme** des DSB einholen
  - [ ] **Anpassungen** umsetzen

- [ ] **Rechtsabteilung-Prüfung**
  - [ ] **Landesdatenschutzgesetz (LDSG)** prüfen
  - [ ] **Hochschulgesetz / Schulgesetz** beachten
  - [ ] **Dienstvereinbarungen** einhalten

- [ ] **Management-Freigabe**
  - [ ] Freigabe durch **RZ-Leitung**
  - [ ] Freigabe durch **Leitung der Einrichtung** (z. B. Rektorat)

---

## 8. Umsetzung

### 8.1 Schulungen
- [ ] **Admin-Personal schulen** (TOM, VVT, DSFA)
- [ ] **Nutzer:innen informieren** (Datenschutzhinweise, Betroffenenrechte)
- [ ] **Dokumentation der Schulungen** (Teilnehmerlisten, Inhalte)

### 8.2 Monitoring
- [ ] **Regelmäßige Überprüfung** der TOM (jährlich)
- [ ] **Audits** durchführen (intern alle 12 Monate, extern alle 24 Monate)
- [ ] **Vorfälle dokumentieren** (Incident-Response-Plan)

### 8.3 Aktualisierung
- [ ] **Jährliche Überprüfung** aller Dokumente
- [ ] **Bei IT-Änderungen** (z. B. neue Komponente, Update) → TOM/VVT anpassen
- [ ] **Bei Gesetzesänderungen** → VVT/DSFA prüfen

---

## 9. Dokumentenhistorie

| **Datum** | **Version** | **Änderung** | **Verantwortlich** | **Status** |
|-----------|-------------|--------------|--------------------|------------|
| [TT.MM.JJJJ] | 1.0 | Initialisierung (Vorlage) | openDesk Edu Contributors | ✅ |
| [TT.MM.JJJJ] | 1.1 | Anpassung an [Institution] | [Name] | ☐ |
| [TT.MM.JJJJ] | 1.2 | DSB-Prüfung | [DSB-Name] | ☐ |
| [TT.MM.JJJJ] | 1.3 | Freigabe | [RZ-Leitung] | ☐ |

---

## 10. Verantwortlichkeiten

| **Aufgabe** | **Verantwortlich** | **Frist** | **Status** |
|-------------|--------------------|-----------|------------|
| Anpassung der Vorlagen | IT-Verantwortliche:r | 2-4 Wochen | ☐ |
| Prüfung durch DSB | Datenschutzbeauftragte:r | 2 Wochen | ☐ |
| Rechtliche Prüfung | Rechtsabteilung | 2 Wochen | ☐ |
| Freigabe | RZ-Leitung + Einrichtung-Leitung | 1 Woche | ☐ |
| Schulungen durchführen | RZ | 1 Monat nach Freigabe | ☐ |
| Jährliche Audit-Durchführung | IT-Sicherheit | Alle 12 Monate | ☐ |

---

## 11. Nützliche Links

| **Ressource** | **Beschreibung** | **Link** |
|---------------|------------------|----------|
| **HBDI – M365-Bericht** | Begründung: M365 = Betriebsmittel | [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf) |
| **BayLfD – Betriebsmittel-Vorlage** | Muster für Betriebsmittel-Beschreibung | [Website](https://www.datenschutz-bayern.de/dsfa/5-1-2_BM-VKS-Beschreibung-Bsp.pdf) |
| **BayLfD – DSFA-Leitfaden** | Anforderungen an DSFA | [Website](https://www.datenschutz-bayern.de/dsfa/) |
| **BSI IT-Grundschutz** | Sicherheitsstandards | [BSI](https://www.bsi.bund.de/DE/Themen/ITGrundschutz/itgrundschutz_node.html) |
| **DSGVO-Text** | Verordnung (EU) 2016/679 | [EUR-Lex](https://eur-lex.europa.eu/legal-content/DE/TXT/?uri=CELEX%3A32016R0679) |
| **Liste aller Landesdatenschutzbeauftragten** | Kontakte der Aufsichtsbehörden | [BfDI](https://www.bfdi.bund.de/DE/Service/Landesbeauftragte/landesbeauftragte_node.html) |

---

## 12. Häufige Fehler (Checkliste)

❌ **Nicht machen:**
- [ ] **Betriebsmittel als Verarbeitungstätigkeit dokumentieren** (openDesk Edu ≠ VVT-Eintrag)
- [ ] **Platzhalter `[...]` nicht ersetzen** (alle Dokumente müssen vollständig sein)
- [ ] **DSB nicht einbinden** (Pflicht nach DSGVO!)
- [ ] **Rechtsgrundlagen nicht prüfen** (Art. 6 DSGVO + LDSG)
- [ ] **TOM nicht umsetzen** (Art. 32 DSGVO ist Pflicht!)
- [ ] **DSFA für Hochrisiko-Verarbeitungen vergessen** (Art. 35 DSGVO)
- [ ] **Löschfristen nicht definieren** (Art. 30 Abs. 1 lit. g DSGVO)
- [ ] **Drittlandübermittlungen nicht dokumentieren** (Art. 44-49 DSGVO)

✅ **Lösung:**
- [ ] **Betriebsmittel-Beschreibung (01-...) erstellen**
- [ ] **VVT für Verarbeitungstätigkeiten (02-...) ausfüllen**
- [ ] **Alle Platzhalter ersetzen**
- [ ] **DSB/Rechtsabteilung einbinden**
- [ ] **TOM umsetzen und dokumentieren**
- [ ] **DSFA für Hochrisiko-Verarbeitungen durchführen**
- [ ] **Löschfristen definieren und einhalten**

---

*Letzte Aktualisierung: 12.08.2026*

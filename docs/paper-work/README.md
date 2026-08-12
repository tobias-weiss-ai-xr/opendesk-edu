<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Paper Work – Datenschutzvorlagen

> **⚠️ Rechtlicher Hinweis / Legal Disclaimer**
>
> Die in diesem Verzeichnis enthaltenen Dokumente sind **keine rechtlich geprüften Vorlagen**. Sie dienen ausschließlich als **Beispiele / Templates** und müssen an die spezifischen Bedürfnisse und rechtlichen Anforderungen der jeweiligen Institution angepasst werden.
>
> Es wird ausdrücklich empfohlen, die Dokumente vor Nutzung durch die **Rechtsabteilung** und den **Datenschutzbeauftragten (DSB)** prüfen zu lassen.
>
> Die openDesk-Edu-Community übernimmt keine Haftung für die rechtliche Korrektheit, Vollständigkeit oder Eignung dieser Dokumente.

---

## Struktur

Dieses Verzeichnis enthält **anonymisierte Vorlagen** für den Datenschutz bei openDesk Edu. Die Dokumente basieren auf:

- **HBDI-Bericht zu Microsoft 365 (2025-11-15, S. 79, 3173-3180)** – Klassifizierung von Office-Suiten als *Betriebsmittel* (nicht als Verarbeitungstätigkeit)
- **BayLfD-Vorlagen** – Standardisierte Beschreibung von Betriebsmitteln und Verarbeitungstätigkeiten
- **DSGVO (Artt. 30, 32, 35)** – Verarbeitungsverzeichnis, TOM, DSFA

---

## Dokumente

| Datei | Typ | Zweck | Rechtsgrundlage |
|-------|-----|-------|-----------------|
| **[01-betriebsmittel-opendesk-edu.md](01-betriebsmittel-opendesk-edu.md)** | Betriebsmittel-Beschreibung | openDesk Edu als *technisches Hilfsmittel* (analog M365) | HBDI-Einschätzung |
| **[02-verarbeitungsverzeichnis.md](02-verarbeitungsverzeichnis.md)** | Verarbeitungsverzeichnis (VVT) | Dokumentation konkreter Verarbeitungstätigkeiten *mit* openDesk Edu | Art. 30 DSGVO |
| **[03-technisch-organisatorische-massnahmen.md](03-technisch-organisatorische-massnahmen.md)** | TOM-Dokumentation | Sicherheitsmaßnahmen nach Art. 32 DSGVO | Art. 32 DSGVO |
| **[04-datenschutz-folgenabschaetzung.md](04-datenschutz-folgenabschaetzung.md)** | DSFA | Risikobewertung für Hochrisiko-Verarbeitungen | Art. 35 DSGVO |
| **[05-betroffenrechte.md](05-betroffenrechte.md)** | Formular | Antrag auf Auskunft/Löschung (Artt. 15, 17 DSGVO) | Artt. 15, 17, 20, 21 DSGVO |

---

## Rechtliche Einordnung

### openDesk Edu als Betriebsmittel
Gemäß **HBDI (Hessischer Beauftragter für Datenschutz und Informationsfreiheit)** im **[Bericht zu Microsoft 365 (2025-11-15, S. 79, Absätze 3173-3180)](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)**:

> *"Der Einsatz eines M365-Produkts für sich genommen stellt **keine Verarbeitungstätigkeit** im Sinne von Art. 30 DSGVO dar. Es handelt sich vielmehr um ein **technisches Hilfs- oder Betriebsmittel**, mit dessen Unterstützung unterschiedliche Verarbeitungstätigkeiten durchgeführt werden können."*

**Folgerung für openDesk Edu:**
- openDesk Edu ist eine **kollaborative Office-Suite** (Dateispeicher, E-Mail, Kalender, Chat, Videokonferenz) → **analog zu M365**
- **openDesk Edu selbst ist ein Betriebsmittel** → **Kein VVT für openDesk Edu möglich**
- **Verarbeitungstätigkeiten** (z. B. "E-Mail-Versand", "Online-Lehre") werden **mithilfe von openDesk Edu** durchgeführt → **Diese sind im VVT zu dokumentieren**

### Praktische Umsetzung
1. **Betriebsmittel-Beschreibung** (01-betriebsmittel-opendesk-edu.md)
   - Technische und organisatorische Beschreibung von openDesk Edu
   - Sicherheitsmaßnahmen (TOM)
   - Verantwortlichkeiten
2. **Verarbeitungsverzeichnis (VVT)** (02-verarbeitungsverzeichnis.md)
   - Dokumentation **konkreter Verarbeitungstätigkeiten** (z. B. "Durchführung von Online-Prüfungen mit Jitsi")
   - **Verweis auf die Betriebsmittel-Beschreibung** (Spalte "Betriebsmittel")

---

## Anwendungsfall

Die Vorlagen richten sich an:
- 🏛️ Hochschulen und Universitäten
- 🏫 Schulen (Landesschulbehörden)
- 🏢 Öffentliche Verwaltung mit eigener IT

---

## Vorbereitung

### Benötigte Informationen
- Name und Anschrift der Institution
- Kontaktdaten des **Datenschutzbeauftragten (DSB)**
- Verantwortliche für openDesk Edu (RZ/IT)
- Datenkategorien (z. B. Matrikelnummern, E-Mails)
- Technische Details (Serverstandort, Backups, Verschlüsselung)

### Rechtliche Anforderungen
- **Landesdatenschutzgesetz (LDSG)** des Bundeslands
- **Hochschulgesetz / Schulgesetz** (falls zutreffend)
- Bestehende **Dienstvereinbarungen** oder **Betriebsvereinbarungen**

---

## Schritt-für-Schritt

### 1. Betriebsmittel beschreiben
- [ ] **01-betriebsmittel-opendesk-edu.md** anpassen
- [ ] Technische Infrastruktur dokumentieren (K3s, Ceph, Shibboleth, etc.)
- [ ] TOM (Sicherheitsmaßnahmen) ergänzen

### 2. Verarbeitungstätigkeiten identifizieren
- [ ] **Welche konkreten Verarbeitungen** werden mit openDesk Edu durchgeführt?
  - Beispiele: E-Mail-Kommunikation, Online-Lehre, Forschungsdaten-Kollaboration
- [ ] **Rechtsgrundlagen** prüfen (Art. 6 Abs. 1 DSGVO)

### 3. VVT erstellen
- [ ] **02-verarbeitungsverzeichnis.md** ausfüllen
- [ ] **Verweis auf Betriebsmittel-Beschreibung** (01-...) einfügen

### 4. DSFA durchführen (falls erforderlich)
- [ ] **Risikobewertung** für Hochrisiko-Verarbeitungen (z. B. KI-Nutzung, sensiblen Daten)
- [ ] **04-datenschutz-folgenabschaetzung.md** ausfüllen

### 5. TOM dokumentieren
- [ ] **03-technisch-organisatorische-massnahmen.md** anpassen
- [ ] **BSI IT-Grundschutz** oder **ISO 27001** als Referenz nutzen

### 6. Review und Freigabe
- [ ] **DSB** einbinden
- [ ] **Rechtsabteilung** prüfen lassen
- [ ] **Leitung der Einrichtung** genehmigen lassen

---

## Qualitätssicherung

### Vor Verwendung prüfen
- [ ] Alle Platzhalter `[...]` ersetzt
- [ ] Kontaktdaten korrekt
- [ ] DSB benennt und kontaktiert
- [ ] Datenkategorien an tatsächlichen Betrieb angepasst
- [ ] Ländergesetze (LDSG, HSchulG) berücksichtigt
- [ ] Dokumente durch DSB/Rechtsabteilung geprüft

### Regelmäßige Updates
- 🗓️ **Jährlich** alle Dokumente aktualisieren
- 🗓️ Bei **IT-Änderungen** (z. B. neue Komponente) TOM/VVT anpassen
- 🗓️ Bei **neuen Gesetzen** VVT/DSFA prüfen

---

## Häufige Fragen (FAQ)

**F: Muss für openDesk Edu ein VVT erstellt werden?**
A: ❌ Nein. openDesk Edu ist ein **Betriebsmittel** (wie M365). Stattdessen sind die **Verarbeitungstätigkeiten**, die mit openDesk Edu durchgeführt werden, im VVT zu dokumentieren.

**F: Wo ist der Unterschied zwischen Betriebsmittel und Verarbeitungstätigkeit?**
A: 
- **Betriebsmittel** = Werkzeug (z. B. openDesk Edu, M365)
- **Verarbeitungstätigkeit** = Konkrete Nutzung des Werkzeugs (z. B. "E-Mail schreiben mit SOGo")

**F: Wann ist eine DSFA erforderlich?**
A: Bei **Hochrisiko-Verarbeitungen** (z. B. großflächige Profiling, Gesundheitsdaten, Videoüberwachung). Siehe **BayLfD Blacklist** oder **Art. 35 DSGVO**.

**F: Können die Vorlagen 1:1 übernommen werden?**
A: ❌ Nein. Die Templates sind **Beispiele** und müssen an die Institution angepasst werden. **DSB/Rechtsabteilung einbinden!**

---

## Landespezifische Hinweise

Die folgenden Aufsichtsbehörden und Ressourcen sind für die Umsetzung der Datenschutzvorlagen in den jeweiligen Bundesländern relevant:

| Bundesland | Zuständige Behörde | Besonderheiten | Link |
|------------|--------------------|----------------|------|
| **Bayern** | Bayerisches Landesamt für Datenschutzaufsicht (BayLfD) | DSFA Blacklist für öffentliche Stellen, Modulare DSFA-Vorlagen | [www.datenschutz-bayern.de](https://www.datenschutz-bayern.de) |
| **Hessen** | Hessischer Beauftragter für Datenschutz und Informationsfreiheit (HBDI) | M365-Bericht (Betriebsmittel-Klassifizierung), Praxisnah | [datenschutz.hessen.de](https://datenschutz.hessen.de) |
| **Nordrhein-Westfalen** | Landesbeauftragte für Datenschutz und Informationsfreiheit NRW (LDI NRW) | Spezifische Leitfäden für Hochschulen | [www.ldi.nrw.de](https://www.ldi.nrw.de) |
| **Baden-Württemberg** | Landesbeauftragter für den Datenschutz und die Informationsfreiheit (LfDI BW) | Muster-VVT für Schulen/Hochschulen | [www.baden-wuerttemberg.datenschutz.de](https://www.baden-wuerttemberg.datenschutz.de) |
| **Niedersachsen** | Landesbeauftragte für den Datenschutz Niedersachsen (LfD Niedersachsen) | Empfehlungen für E-Learning | [www.lfd.niedersachsen.de](https://www.lfd.niedersachsen.de) |
| **Andere Bundesländer** | [Liste aller Landesdatenschutzbeauftragten](https://www.bfdi.bund.de/DE/Service/Landesbeauftragte/landesbeauftragte_node.html) | – | – |

**Hinweis:** Prüfen Sie die **Landesdatenschutzgesetze (LDSG)** und **Hochschulgesetze** Ihres Bundeslandes, da diese zusätzliche Anforderungen enthalten können.

---

## Referenzen
|--------|--------------|------|
| **HBDI – M365-Bericht (2025-11-15)** | Begründung: M365 = Betriebsmittel (S. 79, 3173-3180) | [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf) |
| **BayLfD – Betriebsmittel-Vorlage** | Muster für Betriebsmittel-Beschreibung (Modul 5) | [Website](https://www.datenschutz-bayern.de/dsfa/) |
| **BayLfD – VVT-Vorlagen** | Muster für Verarbeitungsverzeichnisse (Modul 1) | [Website](https://www.datenschutz-bayern.de/dsfa/) |
| **DSGVO** | Verordnung (EU) 2016/679 | [EUR-Lex](https://eur-lex.europa.eu/legal-content/DE/TXT/?uri=CELEX%3A32016R0679) |
| **BSI IT-Grundschutz** | Sicherheitsstandards für öffentliche Stellen | [BSI](https://www.bsi.bund.de/DE/Themen/ITGrundschutz/itgrundschutz_node.html) |

---

## Verwandte Dokumente

- **[INFRASTRUCTURE.md](../INFRASTRUCTURE.md)** – Technische Infrastruktur-Beschreibung (K3s, Ceph, Netzwerk)
- **[helmfile/](../helmfile/)** – Kubernetes-Konfiguration für openDesk Edu

---

## Kontakt

**Bei rechtlichen Fragen:**
- **Rechtsabteilung** der Institution
- **Datenschutzbeauftragter (DSB)** der Institution
- **Landesaufsichtsbehörde** (z. B. HBDI, BayLfD, LDI NRW)

---

## Lizenz

Apache-2.0

---

*Letzte Aktualisierung: 12.08.2026*

<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Datenschutz-Folgenabschätzung (DSFA)
## Einführung von openDesk Edu auf einem Kubernetes-Cluster (K3s) im Rechenzentrum einer Bildungseinrichtung

> **⚠️ Hinweis zur Anonymisierung**
> Diese Fassung wurde für die öffentliche Bereitstellung im openDesk-Edu-Repository erstellt.
> Alle organisationsspezifischen Angaben (Name der Einrichtung, Standort, Kontaktdaten, interne Systeme,
> Netzwerk-Kennungen, Personenzahlen) wurden entfernt oder durch Platzhalter ersetzt.
>
> Sie dient als **Vorlage**, die von Bildungseinrichtungen an die eigene Organisation angepasst werden muss.
> Alle Werte in `[eckigen Klammern]` sind Platzhalter und vor Verwendung zu ersetzen.

**gem. Art. 35 DSGVO**

**Verantwortlicher:**
[Name der Bildungseinrichtung] – Rechenzentrum (RZ)

**Datum:** [TT.MM.JJJJ]
**Version:** 1.0 – anonymisierte Vorlage
**Gültig für:** Einführung von openDesk Edu (openCloud, SOGo, Jitsi, Element, Portal) auf einem eigenen Kubernetes-Cluster (K3s)

---

## Inhaltsverzeichnis

1. [Einleitung](#1-einleitung)
   - [1.1 Zweck der DSFA](#11-zweck-der-dsfa)
   - [1.2 Geltungsbereich](#12-geltungsbereich)
   - [1.3 Projektbeschreibung](#13-projektbeschreibung)
2. [Beschreibung der Verarbeitung](#2-beschreibung-der-verarbeitung)
   - [2.1 Verarbeitungszwecke](#21-verarbeitungszwecke)
   - [2.2 Art und Umfang der Daten](#22-art-und-umfang-der-daten)
   - [2.3 Betroffene Personen](#23-betroffene-personen)
   - [2.4 Verarbeitungsvorgänge](#24-verarbeitungsvorgänge)
3. [Notwendigkeit und Verhältnis der Verarbeitung](#3-notwendigkeit-und-verhältnis-der-verarbeitung)
4. [Risikobewertung](#4-risikobewertung)
   - [4.1 Risikoidentifikation](#41-risikoidentifikation)
   - [4.2 Risikoanalyse](#42-risikoanalyse)
   - [4.3 Risikobewertung](#43-risikobewertung)
5. [Geplante Maßnahmen zur Risikominderung](#5-geplante-maßnahmen-zur-risikominderung)
6. [Restrisiken](#6-restrisiken)
7. [Schlussfolgerung und Freigabe](#7-schlussfolgerung-und-freigabe)
8. [Anhang](#8-anhang)

---

## 1. Einleitung

### 1.1 Zweck der DSFA

Diese **Datenschutz-Folgenabschätzung (DSFA)** gem. **Art. 35 DSGVO** analysiert und bewertet die **Risiken für die Rechte und Freiheiten natürlicher Personen**, die mit der Einführung von **openDesk Edu** auf einem **Kubernetes-Cluster (K3s)** im **Rechenzentrum einer Bildungseinrichtung** verbunden sind.

Die DSFA dient als **Grundlage für die Entscheidung**, ob die Einführung von openDesk Edu:
- **datenschutzrechtlich zulässig** ist,
- **zusätzliche Schutzmaßnahmen** erfordert,
- **vor der Einführung genehmigt** werden muss.

### 1.2 Geltungsbereich

| **Aspekt** | **Gültigkeit** |
|------------|----------------|
| **System** | openDesk Edu (openCloud, SOGo, Jitsi, Element, Portal) |
| **Infrastruktur** | Kubernetes-Cluster (K3s) auf Servern im Rechenzentrum |
| **Betreiber** | Rechenzentrum (RZ) der Einrichtung |
| **Nutzer:innen** | Mitarbeitende, Studierende, externe Gäste |
| **Zeitraum** | Dauer des Betriebs (Pilot und produktiv) |
| **Rechtliche Grundlage** | DSGVO, Landesdatenschutzgesetz (LDSG), BSI IT-Grundschutz |

### 1.3 Projektbeschreibung

#### 1.3.1 Hintergrund

Die Einrichtung evaluiert die Einführung von **openDesk Edu** als **souveräne Alternative** zu kommerziellen Cloud-Diensten (z. B. Microsoft 365, Google Workspace). Ziel ist die Bereitstellung eines **datenschutzkonformen, selbstbetriebenen digitalen Arbeitsplatzes** für:
- **Forschung** (Kollaboration, Forschungsdatenmanagement),
- **Lehre** (Materialien, Videokonferenzen, Kommunikation),
- **Verwaltung** (Dokumentenmanagement, E-Mail, Terminplanung).

#### 1.3.2 Infrastruktur

| **Komponente** | **Technologie** | **Standort** | **Betreiber** |
|----------------|----------------|--------------|---------------|
| **Virtualisierung** | Virtualisierungsplattform (z. B. Proxmox VE) | Rechenzentrum der Einrichtung | RZ |
| **Kubernetes** | K3s (Lightweight Kubernetes) | On-Premises | RZ |
| **Storage** | Ceph (Replikationsfaktor 3) oder ZFS | RZ | RZ |
| **Netzwerk** | Isoliertes VLAN | RZ | RZ |
| **Authentifizierung** | Shibboleth (SAML 2.0) mit lokaler IdP | RZ | RZ |
| **IdM-Anbindung** | Zentrales Identity-Management (IdM) | RZ | RZ |
| **Backup** | Backup-Server + S3-kompatibler Objekt-Speicher | RZ | RZ |

#### 1.3.3 openDesk Edu-Komponenten

| **Komponente** | **Zweck** | **Datenverarbeitung** | **Risikostufe** |
|----------------|-----------|----------------------|----------------|
| **openCloud** | Dateispeicher & Kollaboration | Dateiinhalte, Metadaten, Freigabelinks | Hoch |
| **SOGo** | E-Mail & Kalender | E-Mail-Inhalte, Kontakte, Kalendereinträge | Hoch |
| **Jitsi** | Videokonferenzen | Audio/Video-Streams, Chat-Nachrichten | Hoch |
| **Element/Matrix** | Messenger | Nachrichteninhalte, Gruppenmitgliedschaften | Hoch |
| **Portal** | Selbstservice-Portal | Nutzerprofile, Anmeldedaten | Mittel |
| **Monitoring** | Betriebssicherheit | Logs, Metriken, Alerts | Niedrig |

#### 1.3.4 Pilotierung und Rollout

Die Einführung erfolgt in **drei Stufen** (orientiert an einem typischen Pilotierungskonzept):
1. **Stufe 1 (IT-nahe Einführung):** Rechenzentrum und zentrale IT-Bereiche – **4-6 Wochen**
2. **Stufe 2 (Verwaltung):** Verwaltungsbereiche – **8-10 Wochen**
3. **Stufe 3 (Fachbereiche & zentrale Einrichtungen):** ausgewählte Fachbereiche und Einrichtungen – **10-12 Wochen**

Nach erfolgreichem Pilot wird openDesk Edu **einrichtungsweit** eingeführt.

---

## 2. Beschreibung der Verarbeitung

### 2.1 Verarbeitungszwecke

| **Nr.** | **Verarbeitungszweck** | **Rechtsgrundlage** | **Notwendigkeit** |
|---------|------------------------|---------------------|------------------|
| 1 | Bereitstellung eines souveränen digitalen Arbeitsplatzes | Art. 6 Abs. 1 lit. e DSGVO i.V.m. Landesdatenschutzgesetz (LDSG) | Hoch (Hochschulbetrieb) |
| 2 | Authentifizierung und Autorisierung (Shibboleth) | Art. 6 Abs. 1 lit. e DSGVO | Hoch (Sicherheit) |
| 3 | Automatisierte User-Provisionierung (IdM-Anbindung) | Art. 6 Abs. 1 lit. e DSGVO | Hoch (Benutzerfreundlichkeit) |
| 4 | Dateispeicher und Kollaboration (openCloud) | Art. 6 Abs. 1 lit. e DSGVO | Hoch (Forschung & Lehre) |
| 5 | E-Mail- und Kalenderdienste (SOGo) | Art. 6 Abs. 1 lit. e DSGVO | Hoch (Kommunikation) |
| 6 | Videokonferenzen (Jitsi) | Art. 6 Abs. 1 lit. e DSGVO | Hoch (Lehre & Meetings) |
| 7 | Messenger-Dienste (Element/Matrix) | Art. 6 Abs. 1 lit. e DSGVO | Mittel (Kommunikation) |
| 8 | Monitoring und Logging (Grafana, Prometheus, Loki) | Art. 6 Abs. 1 lit. f DSGVO | Hoch (Betriebssicherheit) |
| 9 | Backup und Recovery | Art. 6 Abs. 1 lit. e DSGVO | Hoch (Datensicherung) |
| 10 | Disaster Recovery (Notfall-Instanz) | Art. 6 Abs. 1 lit. e DSGVO | Mittel (Notfallvorsorge) |

### 2.2 Art und Umfang der Daten

#### 2.2.1 Kategorien personenbezogener Daten

| **Kategorie** | **Beschreibung** | **Beispiele** | **Sensibilitätsstufe** | **Verarbeitungs-häufigkeit** |
|---------------|------------------|---------------|------------------------|-----------------------------|
| **Stammdaten** | Identifikationsdaten der Nutzer:innen | Name, E-Mail, Benutzername, Matrikelnummer, Personalnummer, Affiliation (`staff`/`student`) | Normal | Einmalig (bei Anmeldung) |
| **Authentifizierungsdaten** | Daten für den Zugriff | Session-IDs, SAML-Tokens, SAML-Attribute (`eduPersonAffiliation`, `eduPersonScopedAffiliation`) | Hoch | Bei jedem Login |
| **Nutzungsdaten** | Daten zur Nutzung der Dienste | Login-Zeitstempel, IP-Adressen (pseudonymisiert), genutzte Dienste, Session-Dauer | Niedrig | Kontinuierlich |
| **Inhaltsdaten** | Von Nutzer:innen erstellte Inhalte | Dateien (Dokumente, Bilder, Videos), E-Mails, Kalendereinträge, Chat-Nachrichten, Video-Streams | **Sehr Hoch** | Kontinuierlich |
| **Metadaten** | Technische Informationen | Dateigrößen, Zeitstempel, Berechtigungen, Versionierung, Freigabelinks | Mittel | Kontinuierlich |
| **Kommunikationsdaten** | Daten aus Kommunikationsdiensten | Chatverläufe, Meeting-Protokolle, Teilnehmerlisten, E-Mail-Header | Hoch | Kontinuierlich |
| **Log-Daten** | System- und Anwendungslogs | Fehlerprotokolle, Zugriffslogs, API-Aufrufe, Kubernetes-Events | Niedrig | Kontinuierlich |

#### 2.2.2 Datenvolumen

> **Hinweis:** Die Werte sind **Platzhalter** und müssen anhand der tatsächlichen Nutzer:innenzahl der Einrichtung ermittelt werden.

| **Datenkategorie** | **Geschätztes Volumen (pro Nutzer:in)** | **Gesamtvolumen (bei [Anzahl] Nutzer:innen)** |
|---------------------|-----------------------------------------|-----------------------------------------------|
| **Stammdaten** | ~1 KB | ~[Volumen] |
| **Authentifizierungsdaten** | ~5 KB (Session) | ~[Volumen] |
| **Dateien (openCloud)** | [Speicherquote] pro Nutzer:in | ~[Volumen] |
| **E-Mails (SOGo)** | [Speicherquote] pro Nutzer:in | ~[Volumen] |
| **Chat-Nachrichten (Element)** | ~[Volumen] | ~[Volumen] |
| **Logs (Anwendung)** | ~[Volumen]/Tag | ~[Volumen]/Tag |
| **Logs (Sicherheit)** | ~[Volumen]/Tag | ~[Volumen]/Tag |
| **Backups** | ~[Volumen] (täglich, inkrementell) | ~[Volumen]/Tag |

> **Anmerkungen:**
> - Die **Speicherquoten** orientieren sich an üblichen Hochschul-Angeboten (z. B. 50 GB pro Nutzer:in).
> - **Backups** werden komprimiert und verschlüsselt gespeichert.
> - **Logs** werden nach 30 Tagen (Anwendung) bzw. 90 Tagen (Sicherheit) gelöscht.

### 2.3 Betroffene Personen

| **Gruppe** | **Beschreibung** | **Anzahl (ca.)** | **Datenumfang** | **Besonderheiten** |
|------------|------------------|------------------|-----------------|--------------------|
| **Mitarbeitende** | Wissenschaftliche und administrative Mitarbeitende | ~[Anzahl] | Hoch (Forschungsdaten, E-Mails) | Langfristige Nutzung |
| **Studierende** | Eingeschriebene Studierende (alle Fachbereiche) | ~[Anzahl] | Mittel (Lehrmaterialien, E-Mails) | Wechselnde Nutzung |
| **Externe Gäste** | Kooperationspartner:innen, Gastwissenschaftler:innen | ~[Anzahl] | Hoch (Forschungsdaten) | Temporäre Nutzung |
| **Admin-Personal (RZ)** | IT-Mitarbeitende mit Admin-Rechten | ~[Anzahl] | Niedrig (nur Systemdaten) | Zugriff auf alle Daten |
| **Support-Mitarbeitende** | First-Level-Support (Helpdesk) | ~[Anzahl] | Niedrig (nur Metadaten) | Zugriff auf Nutzerdaten bei Support |

**Gesamtzahl betroffener Personen:** **~[Anzahl]**

### 2.4 Verarbeitungsvorgänge

#### 2.4.1 Datenflüsse

```mermaid
graph TD
    A[Nutzer:in] -->|Login| B[Shibboleth SP]
    B -->|SAML-Request| C[IdP (zentrales IdM / RZ)]
    C -->|SAML-Response| B
    B -->|Auth-Token| D[openDesk Portal]
    D -->|Provisionierung| E[openDesk-Komponenten]
    E --> F[openCloud]
    E --> G[SOGo]
    E --> H[Jitsi]
    E --> I[Element/Matrix]
    F -->|Daten| J[Storage: Ceph/ZFS]
    G -->|Daten| J
    H -->|Daten| J
    I -->|Daten| J
    J -->|Backup| K[Backup-Server]
    J -->|Backup| L[Objekt-Speicher]
    E -->|Logs| M[Loki/ELK]
    E -->|Metrics| N[Prometheus]
    M -->|SIEM| O[Wazuh/Graylog]
    N -->|Visualisierung| P[Grafana]
    O -->|Alerts| Q[Alertmanager]
```

#### 2.4.2 Verarbeitungsstufen

| **Stufe** | **Verantwortlicher** | **Verarbeitungsaktivität** | **Datenkategorien** | **Speicherdauer** |
|-----------|---------------------|---------------------------|----------------------|-------------------|
| **1. Anmeldung** | RZ (IdM-Team) | Nutzer:innen werden im IdM angelegt und mit openDesk synchronisiert | Stammdaten, Authentifizierungsdaten | Bis zur Löschung + 6 Monate |
| **2. Authentifizierung** | RZ (Shibboleth-Team) | Nutzer:in authentifiziert sich über Shibboleth | Authentifizierungsdaten, Session-Daten | 24 Stunden |
| **3. Nutzung der Dienste** | Nutzer:in | Nutzer:in nutzt openCloud, SOGo, Jitsi, Element | Inhaltsdaten, Metadaten, Kommunikationsdaten | Bis zur Löschung durch Nutzer:in |
| **4. Monitoring** | RZ (Monitoring-Team) | System- und Anwendungslogs werden gesammelt | Log-Daten, Nutzungsdaten | 30 Tage (Anwendung), 90 Tage (Sicherheit) |
| **5. Backup** | RZ (Backup-Team) | Daten werden verschlüsselt gesichert | Alle Daten (verschlüsselt) | 30 Tage (täglich), 12 Monate (wöchentlich), 7 Jahre (monatlich) |
| **6. Löschung** | RZ (IdM-Team) | Daten werden nach Fristablauf automatisch gelöscht | Alle Daten | Gemäß Löschkonzept |

---

## 3. Notwendigkeit und Verhältnis der Verarbeitung

### 3.1 Notwendigkeit der Verarbeitung

| **Verarbeitungszweck** | **Notwendigkeit** | **Begründung** |
|------------------------|------------------|----------------|
| **Bereitstellung digitaler Arbeitsplätze** | **Hoch** | Die Einrichtung ist als öffentliche Hochschule verpflichtet, ihren Angehörigen **moderne, datenschutzkonforme IT-Infrastrukturen** zur Verfügung zu stellen (Hochschulgesetz des Landes). |
| **Authentifizierung und Autorisierung** | **Hoch** | Ohne sichere Authentifizierung ist der **Schutz vor unautorisiertem Zugriff** nicht gewährleistet. |
| **Dateispeicher (openCloud)** | **Hoch** | **Forschungsdaten** und Lehrmaterialien müssen **sicher und kollaborativ** gespeichert werden können. |
| **E-Mail & Kalender (SOGo)** | **Hoch** | Kommunikation und Terminplanung sind **Kern des Hochschulbetriebs**. |
| **Videokonferenzen (Jitsi)** | **Mittel** | **Lehre und Meetings** erfordern eine datenschutzkonforme Alternative zu kommerziellen Diensten. |
| **Messenger (Element/Matrix)** | **Mittel** | **Interne Kommunikation** muss sicher und ohne externe Abhängigkeiten möglich sein. |
| **Monitoring und Logging** | **Hoch** | **Betriebssicherheit** und **Störungsbehebung** erfordern die Protokollierung von Systemaktivitäten. |
| **Backup und Recovery** | **Hoch** | **Datenverlust** muss verhindert werden (Compliance mit dem Landesdatenschutzgesetz). |

### 3.2 Verhältnis der Verarbeitung (Art. 5 Abs. 1 lit. c DSGVO)

| **Grundsatz** | **Umsetzung in openDesk Edu** | **Nachweis** |
|---------------|--------------------------------|--------------|
| **Zweckbindung** | Daten werden **ausschließlich für die in Kap. 2.1 genannten Zwecke** verarbeitet. | VVT, DSFA, Nutzungsbedingungen |
| **Datenminimierung** | Es werden **nur die notwendigen Attribute** aus dem IdM synchronisiert (z. B. `eduPersonAffiliation`, `mail`). | IdM-Anbindung, Attribut-Mapping |
| **Speicherbegrenzung** | Daten werden **automatisch nach Fristablauf gelöscht** (siehe Kap. 8 im VVT). | Löschkonzept, Automatisierungsskripte |
| **Richtigkeit** | Nutzer:innen können ihre **Stammdaten über das IdM selbst korrigieren**. | Selbstservice-Portal (geplant) |
| **Integrität und Vertraulichkeit** | Daten werden **verschlüsselt** (in Ruhe und auf Transport) und durch **RBAC geschützt**. | TOM-Katalog (Kap. 9 im VVT) |

### 3.3 Interessensabwägung (Art. 6 Abs. 1 lit. f DSGVO)

Für Verarbeitungen, die auf **berechtigtem Interesse** basieren (z. B. Monitoring), wurde eine **Interessensabwägung** durchgeführt:

| **Verarbeitungszweck** | **Interesse des Verantwortlichen** | **Interesse der Betroffenen** | **Abwägungsergebnis** |
|------------------------|-----------------------------------|--------------------------------|------------------------|
| **Monitoring (Logs, Metriken)** | Betriebssicherheit, Störungsbehebung, Kapazitätsplanung | Datenschutz (keine Inhaltsdaten, Pseudonymisierung) | ✅ **Überwiegt** (Maßnahmen: Pseudonymisierung, kurze Speicherfristen) |
| **Sicherheitsanalysen (SIEM)** | Erkennung von Sicherheitsvorfällen, Schutz vor Angriffen | Datenschutz (pseudonymisierte Daten) | ✅ **Überwiegt** (Maßnahmen: Zugriffsbeschränkung, kurze Speicherfristen) |
| **Backup und Recovery** | Schutz vor Datenverlust | Datenschutz (verschlüsselte Backups) | ✅ **Überwiegt** (Maßnahmen: Verschlüsselung, Georedundanz) |

---

## 4. Risikobewertung

### 4.1 Risikoidentifikation

Die Risikobewertung basiert auf der **DSGVO-Risikomatrix** und berücksichtigt:
1. **Eintrittswahrscheinlichkeit** (niedrig, mittel, hoch),
2. **Schadensausmaß** (niedrig, mittel, hoch, sehr hoch),
3. **Risikostufe** (niedrig, mittel, hoch).

#### 4.1.1 Identifizierte Risiken

| **ID** | **Risiko** | **Kategorie** | **Betroffene Daten** | **Betroffene Personen** |
|--------|-----------|---------------|----------------------|--------------------------|
| R01 | Unautorisierter Zugriff auf Nutzerdaten (z. B. durch Hacking) | Sicherheit | Inhaltsdaten, Stammdaten | Alle Nutzer:innen |
| R02 | Datenverlust durch Hardware-Ausfall | Verfügbarkeit | Alle Daten | Alle Nutzer:innen |
| R03 | Sicherheitslücke in openDesk-Komponenten (CVE) | Sicherheit | Alle Daten | Alle Nutzer:innen |
| R04 | Missbrauch von Admin-Rechten (Insider-Threat) | Sicherheit | Alle Daten | Alle Nutzer:innen |
| R05 | Verstoß gegen DSGVO (z. B. falsche Löschfristen) | Compliance | Alle Daten | Alle Nutzer:innen |
| R06 | Denial-of-Service-Angriff (DoS/DDoS) | Verfügbarkeit | Systemdaten | Alle Nutzer:innen |
| R07 | Datenschutzvorfall (z. B. Datenleak) | Compliance | Inhaltsdaten, Stammdaten | Alle Nutzer:innen |
| R08 | Kompromittierung des IdM (Notfall-Szenario) | Verfügbarkeit | Authentifizierungsdaten | Alle Nutzer:innen |
| R09 | Verlust von Backup-Daten (z. B. durch Ransomware) | Verfügbarkeit | Alle Daten | Alle Nutzer:innen |
| R10 | Unautorisierter Zugriff auf Backup-Daten | Vertraulichkeit | Alle Daten | Alle Nutzer:innen |
| R11 | Überschreitung der Speicherquoten (Datenverlust) | Verfügbarkeit | Inhaltsdaten | Alle Nutzer:innen |
| R12 | Fehlkonfiguration der Freigabelinks (öffentlicher Zugriff) | Vertraulichkeit | Inhaltsdaten | Nutzer:innen mit Freigaben |
| R13 | Missbrauch von Videokonferenzen (z. B. Meeting-Bombing) | Sicherheit | Kommunikationsdaten | Meeting-Teilnehmer:innen |
| R14 | Nicht-DSGVO-konforme Dritte (z. B. externe IdPs) | Compliance | Authentifizierungsdaten | Alle Nutzer:innen |

### 4.2 Risikoanalyse

#### 4.2.1 Bewertung nach Eintrittswahrscheinlichkeit und Schadensausmaß

| **ID** | **Risiko** | **Eintritts-wahrscheinlichkeit** | **Schadens-ausmaß** | **Risikostufe (vor Maßnahmen)** |
|--------|-----------|-------------------------------|-------------------|----------------------------------|
| R01 | Unautorisierter Zugriff auf Nutzerdaten | Niedrig | Sehr Hoch | **Hoch** |
| R02 | Datenverlust durch Hardware-Ausfall | Mittel | Hoch | **Hoch** |
| R03 | Sicherheitslücke in openDesk-Komponenten | Mittel | Hoch | **Hoch** |
| R04 | Missbrauch von Admin-Rechten | Niedrig | Sehr Hoch | **Hoch** |
| R05 | Verstoß gegen DSGVO | Niedrig | Hoch | **Mittel** |
| R06 | Denial-of-Service-Angriff | Mittel | Mittel | **Mittel** |
| R07 | Datenschutzvorfall | Niedrig | Sehr Hoch | **Hoch** |
| R08 | Kompromittierung des IdM | Niedrig | Sehr Hoch | **Hoch** |
| R09 | Verlust von Backup-Daten | Niedrig | Sehr Hoch | **Hoch** |
| R10 | Unautorisierter Zugriff auf Backup-Daten | Niedrig | Hoch | **Mittel** |
| R11 | Überschreitung der Speicherquoten | Niedrig | Mittel | **Niedrig** |
| R12 | Fehlkonfiguration der Freigabelinks | Niedrig | Hoch | **Mittel** |
| R13 | Missbrauch von Videokonferenzen | Niedrig | Mittel | **Niedrig** |
| R14 | Nicht-DSGVO-konforme Dritte | Niedrig | Hoch | **Mittel** |

#### 4.2.2 Bewertung der Verarbeitung an sich

Gemäß **Art. 35 Abs. 1 DSGVO** ist eine DSFA **pflichtig**, wenn die Verarbeitung:
- **aufgrund ihrer Art, ihres Umfangs, ihrer Umstände und ihrer Zwecke** voraussichtlich ein **hohes Risiko** für die Rechte und Freiheiten natürlicher Personen mit sich bringt.

| **Kriterium (Art. 35 Abs. 3 DSGVO)** | **Zutreffend?** | **Begründung** |
|--------------------------------------|----------------|----------------|
| **Systematische und umfassende Bewertung persönlicher Aspekte** | ❌ | Keine automatisierte Bewertung (z. B. Profiling) |
| **Automatisierte Entscheidung mit Rechtswirkung** | ❌ | Keine automatisierten Entscheidungen |
| **Systematische Überwachung öffentlich zugänglicher Bereiche** | ❌ | Keine Überwachung |
| **Verarbeitung besonderer Kategorien (Art. 9 DSGVO)** | ⚠️ | **Möglich**: Forschungsdaten, Gesundheitsdaten (z. B. Medizin) |
| **Verarbeitung von Daten über strafrechtliche Verurteilungen (Art. 10 DSGVO)** | ❌ | Keine Verarbeitung von Straftaten |
| **Großflächige Verarbeitung von Standortdaten** | ❌ | Keine Standortverarbeitung |
| **Großflächige Verarbeitung von Kinder- oder Schutzbedürftigendaten** | ❌ | Studierende in der Regel volljährig (> 16 Jahre) |
| **Innovative Technologien** | ✅ | **Kubernetes, Containerisierung, Cloud-native Architektur** |
| **Großflächige Verarbeitung (viele Betroffene)** | ✅ | **~[Anzahl] Betroffene** |
| **Systematische Überwachung von Betroffenen** | ⚠️ | **Teilweise**: Monitoring von Systemaktivitäten (aber pseudonymisiert) |
| **Verarbeitung in großem Umfang sensibler Daten** | ✅ | **Inhaltsdaten (Dateien, E-Mails, Nachrichten)** |

**➡️ Ergebnis:** Die Verarbeitung erfüllt **mehrere Kriterien für eine DSFA-Pflicht**, insbesondere:
1. **Großflächige Verarbeitung sensibler Daten** (Inhaltsdaten),
2. **Innovative Technologien** (Kubernetes, Containerisierung),
3. **Mögliche Verarbeitung besonderer Kategorien** (Forschungsdaten).

**➡️ Eine DSFA ist daher pflichtig und wurde mit diesem Dokument erfüllt.**

### 4.3 Risikobewertung (nach Maßnahmen)

Nach Umsetzung der in **Kap. 5** beschriebenen Maßnahmen sinkt das Risiko wie folgt:

| **ID** | **Risiko** | **Risikostufe (vor Maßnahmen)** | **Maßnahmen** | **Risikostufe (nach Maßnahmen)** |
|--------|-----------|----------------------------------|---------------|------------------------------------|
| R01 | Unautorisierter Zugriff auf Nutzerdaten | Hoch | Verschlüsselung, RBAC, MFA, Firewall, Audit-Logging | **Mittel** |
| R02 | Datenverlust durch Hardware-Ausfall | Hoch | Backups (RPO 1 h, RTO 4 h), Georedundanz, Rollback-Tests | **Niedrig** |
| R03 | Sicherheitslücke in openDesk-Komponenten | Hoch | Patch-Management (<24 h), Security-Scans, CVE-Monitoring | **Niedrig** |
| R04 | Missbrauch von Admin-Rechten | Hoch | PAM, JIT Access, Bastion-Host, Audit-Logging, Vier-Augen-Prinzip | **Niedrig** |
| R05 | Verstoß gegen DSGVO | Mittel | Automatisierte Löschung, regelmäßige Audits, DSB-Einbindung | **Niedrig** |
| R06 | Denial-of-Service-Angriff | Mittel | Rate-Limiting, Firewall-Regeln, Skalierung | **Niedrig** |
| R07 | Datenschutzvorfall | Hoch | Incident-Response-Plan, Meldepflichten (72 h), DSB-Einbindung | **Niedrig** |
| R08 | Kompromittierung des IdM | Hoch | DR-Instanz mit alternativen E-Mail-Adressen, manuelle Freigabe | **Niedrig** |
| R09 | Verlust von Backup-Daten | Hoch | Offline-Backups (Tape), Immutable Backups, Georedundanz | **Niedrig** |
| R10 | Unautorisierter Zugriff auf Backup-Daten | Mittel | Verschlüsselung (AES-256), Schlüssel separiert, Zugriffsbeschränkung | **Niedrig** |
| R11 | Überschreitung der Speicherquoten | Niedrig | Quotenregelung, automatische Benachrichtigung | **Niedrig** |
| R12 | Fehlkonfiguration der Freigabelinks | Mittel | Standardmäßige Ablaufdauer (7 Tage), Admin-Prüfung | **Niedrig** |
| R13 | Missbrauch von Videokonferenzen | Niedrig | Passwortschutz, Wartelobby, E2EE | **Niedrig** |
| R14 | Nicht-DSGVO-konforme Dritte | Mittel | Nur lokale IdP, Föderations-IdP mit Vertrag | **Niedrig** |

---

## 5. Geplante Maßnahmen zur Risikominderung

### 5.1 Technische Maßnahmen

#### 5.1.1 Infrastruktur-Sicherheit

| **Maßnahme** | **Beschreibung** | **Verantwortlich** | **Umsetzungsstatus** | **Risikoreduktion** |
|--------------|------------------|-------------------|----------------------|---------------------|
| **On-Premises-Betrieb** | Kubernetes-Cluster auf Servern im **Rechenzentrum der Einrichtung** (keine Public Cloud) | RZ | ✅ | Hoch |
| **Physische Sicherheit** | Zugang zum Rechenzentrum mit **Zutrittskontrolle** (Chipkarte + PIN), Videoüberwachung, Alarmierung | RZ | ✅ | Hoch |
| **Netzwerk-Segmentierung** | **Isoliertes VLAN** für den Kubernetes-Cluster (kein direkter Internet-Zugriff auf Node-IPs) | RZ | ✅ | Hoch |
| **Firewall-Regeln** | Strenge **Firewall-Regeln** (nur HTTPS/443, interne APIs) | RZ | ✅ | Hoch |
| **DMZ für externe Dienste** | Externe Dienste (Ingress, Shibboleth) in separater Netzwerkzone | RZ | ✅ | Hoch |
| **Kubernetes-Hardening** | CIS-Benchmark-konforme Konfiguration (Pod Security Admission, Network Policies, RBAC) | RZ | ✅ | Hoch |
| **Storage-Verschlüsselung** | **Ceph-RBD-Volumes** mit AES-256-Verschlüsselung | RZ | ✅ | Hoch |
| **Datenverschlüsselung in Ruhe** | Alle **Persistent Volumes (PVs)** verschlüsselt | RZ | ✅ | Hoch |
| **TLS-Verschlüsselung** | **HTTPS für alle externen Zugriffe** (cert-manager mit öffentlicher CA oder interner CA) | RZ | ✅ | Hoch |
| **Zertifikatsmanagement** | Automatisierte Zertifikatsrotation (cert-manager) | RZ | ✅ | Mittel |
| **DDoS-Schutz** | **Rate-Limiting** auf Ingress-Controller (NGINX/Traefik) und Firewall | RZ | ✅ | Mittel |

#### 5.1.2 Zugriffskontrolle und Authentifizierung

| **Maßnahme** | **Beschreibung** | **Verantwortlich** | **Umsetzungsstatus** | **Risikoreduktion** |
|--------------|------------------|-------------------|----------------------|---------------------|
| **RBAC (Kubernetes + openDesk)** | Rollenbasierte Zugriffskontrolle mit minimalen Rechten | RZ | ✅ | Hoch |
| **Shibboleth-Integration** | Authentifizierung über **Shibboleth SP** (SAML 2.0) mit lokaler IdP | RZ | ✅ | Hoch |
| **IdM-Anbindung** | Automatisierte **User-Provisionierung/Deprovisionierung** via REST-API | RZ | ✅ | Hoch |
| **Attribut-Minimierung** | **Nur notwendige Attribute** (`eduPersonAffiliation`, `mail`, `displayName`) | RZ | ✅ | Hoch |
| **MFA für Admin-Zugriffe** | **Pflicht für Admin-Zugriffe** (TOTP via Keycloak/PrivacyIDEA) | RZ | ✅ | Hoch |
| **Session-Timeout** | Automatische Abmeldung nach **8 Stunden Inaktivität** | RZ | ✅ | Mittel |
| **Privileged Access Management (PAM)** | Admin-Zugriffe nur über **Bastion-Host** mit Audit-Logging | RZ | ✅ | Hoch |
| **Just-in-Time (JIT) Access** | Temporäre Admin-Rechte via Teleport/Vault | RZ | ⚠️ (geplant) | Hoch |
| **Service-Account-Management** | Dedizierte **Service-Accounts** mit minimalen Rechten | RZ | ✅ | Mittel |

#### 5.1.3 Datenschutz in den Anwendungskomponenten

| **Komponente** | **Maßnahme** | **Verantwortlich** | **Umsetzungsstatus** | **Risikoreduktion** |
|----------------|--------------|-------------------|----------------------|---------------------|
| **openCloud** | **Verschlüsselung in Ruhe**, RBAC, Quotenregelung, Freigabelinks mit Ablauf (7 Tage) | RZ | ✅ | Hoch |
| **SOGo** | TLS (SMTP/IMAP), Spam-Filter (Rspamd), Virenscanner (ClamAV), DKIM/SPF/DMARC | RZ | ✅ | Hoch |
| **Jitsi** | **E2EE für Meetings**, Passwortschutz, Wartelobby, Rate-Limiting | RZ | ✅ | Hoch |
| **Element/Matrix** | **E2EE (Olm/Megolm)**, Server-seitige Verschlüsselung, Spam-Schutz | RZ | ✅ | Hoch |
| **Portal** | RBAC, Session-Timeout, Audit-Logging | RZ | ✅ | Mittel |

#### 5.1.4 Logging, Monitoring und SIEM

| **Maßnahme** | **Beschreibung** | **Verantwortlich** | **Umsetzungsstatus** | **Risikoreduktion** |
|--------------|------------------|-------------------|----------------------|---------------------|
| **Zentrale Log-Sammlung** | **Loki** oder **ELK-Stack** für alle Anwendungs- und Systemlogs | RZ | ✅ | Hoch |
| **SIEM-Integration** | **Wazuh** oder **Graylog** für Sicherheitslogs (K8s-Audit, Shibboleth, IdM) | RZ – IT-Sicherheit | ✅ | Hoch |
| **Monitoring** | **Grafana + Prometheus + Thanos** für Performance-Metriken | RZ | ✅ | Mittel |
| **Alerting** | **Alertmanager** für kritische Ereignisse (Ausfälle, Sicherheitsvorfälle) | RZ | ✅ | Mittel |
| **Log-Retention** | 30 Tage (Anwendungslogs), **90 Tage (Sicherheitslogs)** | RZ | ✅ | Hoch |
| **Pseudonymisierung** | **IP-Adressen in Logs werden nach 7 Tagen pseudonymisiert** | RZ | ✅ | Hoch |
| **Immutable Logs** | Logs werden **unveränderbar** gespeichert (WORM) | RZ | ✅ | Hoch |
| **Audit-Logs** | **Komplette Protokollierung** aller Admin-Aktionen | RZ | ✅ | Hoch |

#### 5.1.5 Backup und Recovery

| **Maßnahme** | **Beschreibung** | **Verantwortlich** | **Umsetzungsstatus** | **Risikoreduktion** |
|--------------|------------------|-------------------|----------------------|---------------------|
| **Backup-Strategie** | **Tägliche inkrementelle + wöchentliche Voll-Backups** (RPO: 1 h, RTO: 4 h) | RZ | ✅ | Hoch |
| **Backup-Ziele** | **Backup-Server** für VM-Backups, **S3-kompatibler Objekt-Speicher** für Objektdaten | RZ | ✅ | Hoch |
| **Verschlüsselte Backups** | **Alle Backups mit AES-256 verschlüsselt** (Schlüssel gesondert verwahrt) | RZ | ✅ | Hoch |
| **Georedundanz** | Backups auf **zwei physisch getrennte Standorte** | RZ | ✅ | Hoch |
| **Rollback-Tests** | **Wöchentliche Tests** der Backup-Wiederherstellung | RZ | ✅ | Hoch |
| **Disaster Recovery (DR)** | **Notfall-Instanz** auf separater Hardware (für IdM-Kompromittierung) | RZ | ⚠️ (optional) | Hoch |
| **Offline-Backups** | **Tape-Backups** für Langzeitarchivierung (7 Jahre) | RZ | ✅ | Hoch |
| **Immutable Backups** | Backups sind **unveränderbar** (WORM) | RZ | ✅ | Hoch |

### 5.2 Organisatorische Maßnahmen

#### 5.2.1 Prozesse und Richtlinien

| **Maßnahme** | **Beschreibung** | **Verantwortlich** | **Umsetzungsstatus** | **Risikoreduktion** |
|--------------|------------------|-------------------|----------------------|---------------------|
| **Incident-Response-Plan** | Definierter Prozess für **Datenschutzvorfälle** (inkl. Meldepflichten nach 72 Stunden) | RZ | ✅ | Hoch |
| **Patch-Management** | **Kritische Patches <24 Stunden**, nicht-kritische Patches <3 Monate | RZ | ✅ | Hoch |
| **Change-Management** | Alle Änderungen müssen **dokumentiert und genehmigt** werden | RZ | ✅ | Hoch |
| **Vier-Augen-Prinzip** | Kritische Änderungen müssen von **zwei Personen genehmigt** werden | RZ | ✅ | Hoch |
| **Datenschutzschulungen** | **Jährliche Schulungen** für Admin-Personal (Pflicht) | RZ | ✅ | Mittel |
| **DSB-Einbindung** | **Regelmäßige Abstimmung** mit dem Datenschutzbeauftragten (vierteljährlich) | RZ / DSB | ✅ | Mittel |

#### 5.2.2 Compliance und Audits

| **Maßnahme** | **Beschreibung** | **Verantwortlich** | **Umsetzungsstatus** | **Risikoreduktion** |
|--------------|------------------|-------------------|----------------------|---------------------|
| **Interne Audits** | **Jährliche Überprüfung** der TOM und des VVT | RZ – IT-Sicherheit | ✅ | Hoch |
| **Externe Audits** | **DSB-Prüfung** alle 2 Jahre | DSB | ✅ | Hoch |
| **BSI IT-Grundschutz** | **Zertifizierung nach BSI IT-Grundschutz** (angestrebt) | RZ | ⚠️ (in Arbeit) | Hoch |
| **Dokumentation** | **Betriebsdokumentation**, **Sicherheitskonzept**, **VVT**, **DSFA** | RZ | ✅ | Hoch |
| **Verträge mit Auftragsverarbeitern** | **AV-Verträge** für externe Dienstleister (falls vorhanden) | Rechtsabteilung | ✅ | Hoch |

---

## 6. Restrisiken

Nach Umsetzung aller Maßnahmen verbleiben folgende **Restrisiken**:

| **ID** | **Restrisiko** | **Beschreibung** | **Eintritts-wahrscheinlichkeit** | **Schadens-ausmaß** | **Risikostufe** | **Akzeptanz** | **Maßnahmen zur weiteren Minimierung** |
|--------|----------------|------------------|-------------------------------|-------------------|---------------|---------------|---------------------------------------|
| RR01 | **Zero-Day-Exploits** | Unbekannte Sicherheitslücken in openDesk-Komponenten | Niedrig | Sehr Hoch | **Mittel** | ✅ | CVE-Monitoring, schnelles Patchen, Netzwerk-Segmentierung |
| RR02 | **Social Engineering** | Phishing-Angriffe auf Admin-Personal | Niedrig | Hoch | **Mittel** | ✅ | Regelmäßige Schulungen, MFA, Awareness-Kampagnen |
| RR03 | **Hardware-Ausfall trotz Backups** | Gleichzeitiger Ausfall von Primär- und Backup-System | Niedrig | Sehr Hoch | **Mittel** | ✅ | Georedundanz, regelmäßige DR-Tests |
| RR04 | **Menschliches Versagen** | Fehlkonfiguration durch Admin-Personal | Niedrig | Hoch | **Mittel** | ✅ | Vier-Augen-Prinzip, Change-Management, automatisierte Tests |
| RR05 | **Externe IdP-Kompromittierung** | Kompromittierung des Föderations-IdP (Fallback) | Sehr Niedrig | Hoch | **Niedrig** | ✅ | Nur lokale IdP als Primär, Föderations-IdP nur als Fallback |
| RR06 | **Rechtliche Änderungen** | Neue Datenschutzvorschriften (z. B. EU Data Act) | Niedrig | Mittel | **Niedrig** | ✅ | Regelmäßige Rechtsprüfung durch die Rechtsabteilung |

### 6.1 Bewertung der Restrisiken

| **Risikostufe** | **Akzeptanz** | **Begründung** |
|----------------|---------------|----------------|
| **Niedrig** | ✅ **Akzeptabel** | Keine weiteren Maßnahmen erforderlich |
| **Mittel** | ✅ **Akzeptabel** | Maßnahmen zur Minimierung sind implementiert |
| **Hoch** | ❌ **Nicht akzeptabel** | Keine Restrisiken dieser Stufe gefunden |

**➡️ Alle Restrisiken sind akzeptabel und erfordern keine weiteren Maßnahmen.**

---

## 7. Schlussfolgerung und Freigabe

### 7.1 Zusammenfassung der Risikobewertung

| **Aspekt** | **Bewertung** |
|------------|---------------|
| **Verarbeitungszwecke** | Rechtmäßig (Art. 6 Abs. 1 lit. e DSGVO, Art. 6 Abs. 1 lit. f DSGVO) |
| **Datenkategorien** | Teilweise hochsensibel (Inhaltsdaten, Kommunikationsdaten) |
| **Betroffene Personen** | Großer Kreis (~[Anzahl] Personen) |
| **Risikostufe (vor Maßnahmen)** | Hoch |
| **Risikostufe (nach Maßnahmen)** | **Niedrig bis Mittel** |
| **Restrisiken** | Akzeptabel |

### 7.2 Empfehlung

✅ **Die Einführung von openDesk Edu auf dem Kubernetes-Cluster ist datenschutzrechtlich zulässig**, wenn:

1. **Alle in dieser DSFA und im VVT beschriebenen technischen und organisatorischen Maßnahmen (TOM) umgesetzt** werden.
2. **Das Verarbeitungsverzeichnis (VVT) regelmäßig aktualisiert** wird (mindestens jährlich).
3. **Der Datenschutzbeauftragte (DSB) die Einführung freigibt**.
4. **Regelmäßige Audits** (jährlich intern, alle 2 Jahre extern durch DSB) durchgeführt werden.
5. **Die Restrisiken akzeptiert** werden (siehe Kap. 6).

### 7.3 Freigabe

| **Rolle** | **Name** | **Datum** | **Freigabe** | **Unterschrift** |
|-----------|----------|-----------|--------------|------------------|
| **Verantwortlicher (Leitung RZ)** | [Name] | [Datum] | ✅ Ja / ❌ Nein | _______________ |
| **Datenschutzbeauftragter (DSB)** | [Name] | [Datum] | ✅ Ja / ❌ Nein | _______________ |
| **Technischer Verantwortlicher (Abteilung Zentrale Systeme)** | [Name] | [Datum] | ✅ Ja / ❌ Nein | _______________ |
| **Rechtsabteilung (Recht, Compliance, Datenschutz)** | [Name] | [Datum] | ✅ Ja / ❌ Nein | _______________ |

### 7.4 Gültigkeit

- **Gültig ab:** [Datum]
- **Gültig bis:** [Datum + 2 Jahre] (oder bis zur nächsten Überarbeitung)
- **Nächste Überprüfung:** [Datum + 1 Jahr]

---

## 8. Anhang

### 8.1 Verwendete Abkürzungen

| Abkürzung | Bedeutung |
|-----------|-----------|
| **AV** | Auftragsverarbeitung |
| **BSI** | Bundesamt für Sicherheit in der Informationstechnik |
| **CIS** | Center for Internet Security |
| **CVE** | Common Vulnerabilities and Exposures |
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
| **RPO** | Recovery Point Objective |
| **RTO** | Recovery Time Objective |
| **RZ** | Rechenzentrum |
| **SAML** | Security Assertion Markup Language |
| **SIEM** | Security Information and Event Management |
| **TOM** | Technische und organisatorische Maßnahmen |
| **VVT** | Verarbeitungsverzeichnis |
| **WORM** | Write Once, Read Many |

### 8.2 Referenzierte Dokumente

- [VVT_openDesk_Edu_anonymized.md](VVT_openDesk_Edu_anonymized.md) – Verarbeitungsverzeichnis (anonymisierte Fassung)
- **Betriebsdokumentation Kubernetes-Cluster** (intern, RZ)
- **Sicherheitskonzept RZ** (intern)
- **Patch-Management-Prozess RZ** (intern)
- **Incident-Response-Plan RZ** (intern)
- **BSI IT-Grundschutz-Kompendium** ([www.bsi.bund.de](https://www.bsi.bund.de))
- **DSGVO** ([EUR-Lex](https://eur-lex.europa.eu/legal-content/DE/TXT/?uri=CELEX:32016R0679))

### 8.3 Rechtliche Grundlagen

- **Datenschutz-Grundverordnung (DSGVO)** – Verordnung (EU) 2016/679
- **Landesdatenschutzgesetz (LDSG)** des jeweiligen Bundeslandes
- **Bundesdatenschutzgesetz (BDSG)** – soweit anwendbar
- **Hochschulgesetz des Landes** – Aufgaben der Hochschule
- **BSI IT-Grundschutz** – Empfehlungen für Informationssicherheit
- **ISO/IEC 27001** – Internationaler Standard für Informationssicherheits-Management

### 8.4 Glossar

| Begriff | Definition |
|---------|------------|
| **K3s** | Lightweight Kubernetes-Distribution von Rancher, optimiert für Produktionsumgebungen mit begrenzten Ressourcen. |
| **Proxmox VE** | Open-Source-Virtualisierungsplattform für Enterprise-Umgebungen (basierend auf KVM und LXC). |
| **Ceph** | Verteiltes Storage-System mit hoher Skalierbarkeit und Replikation. |
| **Shibboleth** | Open-Source-Software für **Föderiertes Identity Management** (SAML 2.0). |
| **openCloud** | Nextcloud-basierte Dateispeicherkomponente von openDesk. |
| **SOGo** | Open-Source-Groupware (E-Mail, Kalender, Kontakte). |
| **Jitsi** | Open-Source-Videokonferenzlösung. |
| **Element/Matrix** | Dezentraler Messenger (Matrix-Protokoll). |

### 8.5 Versionshistorie

| Version | Datum | Änderungen | Bearbeitet von |
|---------|-------|------------|----------------|
| 1.0 | [TT.MM.JJJJ] | Erstellung der anonymisierten Vorlage auf Basis der DSFA einer Bildungseinrichtung | openDesk Edu Contributors |

---

> **⚠️ WICHTIG:**
> - Dieses Dokument ist eine **Vorlage** und muss vor der Inbetriebnahme von **openDesk Edu** durch den **Datenschutzbeauftragten (DSB)** der Einrichtung **freigegeben** werden.
> - **Änderungen** an diesem Dokument müssen **dokumentiert** und vom DSB **genehmigt** werden.
> - Die DSFA muss **alle 2 Jahre** oder bei **wesentlichen Änderungen** (z. B. neue Komponenten, geänderte Datenflüsse) **überarbeitet** werden.
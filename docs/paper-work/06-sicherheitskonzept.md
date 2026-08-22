<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Sicherheitskonzept: openDesk Edu

> **⚠️ Rechtlicher Hinweis**
> Dieses Dokument ist eine **anonymisierte Vorlage** und muss an die spezifischen Anforderungen der jeweiligen Institution angepasst werden.
> Es basiert auf:
> - **BSI IT-Grundschutz** – Modulare Sicherheitskonzepte, Bausteine (z. B. OPS.1.1.5, APP.4.4, SYS.1.1)
> - **ISO/IEC 27001** – Informationssicherheits-Managementsysteme
> - **Modulare Sicherheitsarchitektur** – gängiger Standard öffentlicher Einrichtungen
> - **DSGVO Art. 32** – Technisch-organisatorische Maßnahmen
>
> Die Abschnitte 6 (Zugriffskontrolle), 7 (Logging & Monitoring) und 8 (Incident Management)
> sind die typischen Integrationspunkte in das übergeordnete **Modulare Sicherheitskonzept**
> der jeweiligen Einrichtung.
>
> Vor Nutzung durch **IT-Sicherheit / Rechenzentrum / Rechtsabteilung** prüfen lassen.

---

**Verantwortlicher:**
[Name der Einrichtung] – Rechenzentrum (RZ)

**Datum:** [TT.MM.JJJJ]
**Version:** 1.0 – Entwurf

---

## 1. Einleitung

### 1.1 Zweck
Dieses Dokument beschreibt ein **modulares Sicherheitskonzept** für den Betrieb von
**openDesk Edu** in einer Bildungseinrichtung oder öffentlichen Verwaltung.

Es ergänzt das übergeordnete **Modulare Sicherheitskonzept der Einrichtung** und
definiert die openDesk-spezifischen Sicherheitsmaßnahmen, Verantwortlichkeiten und Prozesse.

### 1.2 Geltungsbereich
- **System:** openDesk Edu (Portal, Keycloak, openCloud, SOGo, Element/Matrix, Etherpad, XWiki, …)
- **Externe Dienste:** BigBlueButton (Videokonferenzen) – sofern extern betrieben
- **Infrastruktur:** Kubernetes-Cluster des Rechenzentrums, On-Premises
- **Betriebsphasen:** Pilotbetrieb, Produktivbetrieb

### 1.3 Bezug zu übergeordneten Dokumenten
| Dokument | Ort | Zweck |
|----------|-----|-------|
| Modulares Sicherheitskonzept der Einrichtung | zentrales ISMS | Rahmenbedingungen, übergeordnete Maßnahmen |
| Betriebsmittel-Beschreibung openDesk Edu | paper-work | openDesk Edu als technisches Hilfsmittel |
| Verarbeitungsverzeichnis (VVT) | paper-work | Verarbeitungstätigkeiten (Art. 30 DSGVO) |
| TOM-Dokumentation | paper-work | Technisch-organisatorische Maßnahmen (Art. 32) |
| Datenschutz-Folgenabschätzung (DSFA) | paper-work | Hochrisiko-Verarbeitungen (Art. 35) |

---

## 2. Sicherheitsziele und Schutzniveau

### 2.1 Schutzziele
| Schutzziel | Anforderung |
|------------|-------------|
| **Vertraulichkeit** | Unbefugte dürfen keine personenbezogenen Daten lesen oder verändern |
| **Integrität** | Daten müssen vollständig und unverändert erhalten bleiben |
| **Verfügbarkeit** | Dienste stehen den berechtigten Nutzern zur Verfügung |
| **Nachvollziehbarkeit** | Sicherheitsrelevante Ereignisse werden protokolliert |

### 2.2 Schutzniveau
Das angestrebte Schutzniveau orientiert sich am **BSI IT-Grundschutz** (Standard-Schutzbedarf bis Hoch).

> **Grundschutzfähigkeit** des Betreibers (z. B. BSI IT-Grundschutz, ISO 27001 oder C5)
> wird vorausgesetzt bzw. ist Voraussetzung für den Betrieb.

---

## 3. Schutzbedarfsfeststellung

| Datenkategorie | Vertraulichkeit | Integrität | Verfügbarkeit | Einstufung |
|----------------|-----------------|------------|---------------|------------|
| Nutzerkonten, Passworthashes | hoch | hoch | mittel | **hoch** |
| Dateien, Dokumente | mittel–hoch | hoch | mittel | **mittel–hoch** |
| E-Mail, Kalender, Kontakte | hoch | hoch | mittel | **hoch** |
| Chat-Nachrichten (Matrix) | mittel | hoch | mittel | **mittel** |
| Technische Logs | mittel | hoch | niedrig | **mittel** |
| Konfiguration, Secrets | hoch | hoch | mittel | **hoch** |

---

## 4. Sicherheitsarchitektur

### 4.1 Komponenten-Übersicht

| Komponente | Zweck | Sicherheitsrelevantes |
|------------|-------|------------------------|
| **Keycloak** | Identität, SSO (OIDC/SAML) | Token, Realm-Konfiguration, LDAP-Sync |
| **Portal** | Zentraler Zugang | Session-Management, Dienste-Katalog |
| **openCloud** | Dateiablage | Datenbestand, Sharing, Virenschutz |
| **SOGo** | E-Mail, Kalender, Kontakte | Inhalte, Transport-Verschlüsselung |
| **Element/Matrix** | Messenger | Nachrichten, Brücken |
| **Etherpad** | Kollaboratives Editieren | Inhalte |
| **XWiki** | Wissensmanagement | Inhalte, Rechte |
| **BigBlueButton** *(extern)* | Videokonferenzen | Meeting-Daten, Aufzeichnungen |

### 4.2 Netzwerkarchitektur
- **Multi-Tenant-Namespaces** mit **NetworkPolicies**
- **TLS** für alle externen Zugriffe (Let's Encrypt / institutionelle CA, automatisierte Rotation)
- **Ingress** über zentralen Controller (z. B. HAProxy/nginx) mit TLS-Terminierung
- **Segmentierung** interner Dienste (DB, Storage, App getrennt)

### 4.3 Mandantentrennung
- Getrennte Kubernetes-Namespaces pro Zielgruppe/Tenant
- Getrennte Storage-Klassen und Backup-Schedules
- Eigene Keycloak-Clients pro Dienst und Tenant
- Netzwerk-Isolation über NetworkPolicies

---

## 5. Maßnahmen-Katalog (Übersicht)

| Bereich | Maßnahme | Umsetzung |
|---------|----------|-----------|
| **Identität** | Zentrale Authentifizierung via Keycloak | Implementiert |
| **Föderation** | Shibboleth/SAML für DFN-AAI/eduGAIN (od. ä.) | Implementiert |
| **Transport** | TLS für alle externen Zugriffe | Implementiert |
| **Speicher** | Verschlüsselung in Ruhe (Storage-Backend) | Implementiert |
| **Backup** | k8up, tägliche Sicherung, Retention 30 Tage | Implementiert |
| **Monitoring** | Grafana/Prometheus, Alertmanager | Implementiert |
| **Logging** | Zentrales Logging (Log-Aufbewahrung) | Implementiert |
| **Patch-Management** | Patch-Tuesday-Zyklus, kritische Patches < 48 h | Implementiert |
| **Secrets** | Secrets nie in Git, Kubernetes Secrets | Implementiert |
| **Audit** | Regelmäßige Sicherheitsüberprüfung | Geplant |

---

## 6. Zugriffskontrolle

*Integrationspunkt 1 in das Modulare Sicherheitskonzept der Einrichtung.*

### 6.1 Benutzerauthentifizierung
- Zentrale Authentifizierung über **Keycloak** (OIDC/SAML)
- Föderation über institutionelles IdP (z. B. Shibboleth)
- Keine lokalen Benutzerkonten in Fachanwendungen (wenn möglich)

### 6.2 Rollen und Rechte
| Rolle | Beschreibung | Berechtigungen |
|-------|--------------|----------------|
| **Nutzer** | Standardnutzer | Eigene Daten, freigegebene Ressourcen |
| **KeyUser** | Ansprechpartner in Organisationseinheit | Zusätzliche Freigaben |
| **Administrator** | Systemadministration | Voller Zugriff auf Konfiguration |
| **Auditor** | Prüfung | Lesezugriff auf Logs |

### 6.3 Berechtigungsvergabe
- **Need-to-know-Prinzip**: minimale Berechtigungen
- **Trennung der Funktionen**: Admin ≠ Nutzer-Datenzugriff
- Regelmäßige **Berechtigungsprüfung**
- **Deprovisionierung** bei Austritt/Exmatrikulation automatisiert

---

## 7. Logging und Monitoring

*Integrationspunkt 2 in das Modulare Sicherheitskonzept der Einrichtung.*

### 7.1 Zweck der Protokollierung
Die Protokollierung erfolgt nur zur Erreichung definierter Ziele:

1. **Identifikation von Problemen** – Abweichungen zu Betriebsstandards, Betriebsstörungen
2. **Identifikation von Sicherheitsproblemen** – Detektion von Vorfällen
3. **Einhaltung datenschutzrechtlicher Vorgaben** – Nachweisbarkeit, Protokollauswertung im IKS

### 7.2 Protokollierte Ereignisse
| Kategorie | Ereignisse |
|-----------|------------|
| **Authentifizierung** | Login-Erfolge/-Fehlschläge, Token-Ausstellung |
| **Autorisierung** | Berechtigungsänderungen, Admin-Aktionen |
| **Datenzugriff** | Zugriff auf sensible Dateien/Postfächer |
| **System** | Starts, Abstürze, Konfigurationsänderungen |
| **Netzwerk** | Zugriffe von außen, Anomalien |

### 7.3 Monitoring-Kennzahlen
| Kategorie | Items |
|-----------|-------|
| **Verfügbarkeit** | Service-/Modul-Verfügbarkeit |
| **Ressourcen** | CPU, Speicher, RAM je Service |
| **Nutzung** | Konferenzen, aktive Nutzer, Zugriffe |
| **Sicherheit** | SIEM-Überwachung, CERT |
| **Zertifikate** | Ablauf-Management |

### 7.4 Tools
| Tool | Zweck |
|------|-------|
| Grafana | Visualisierung von Metriken |
| Prometheus / Thanos | Metrik-Erfassung und Langzeitspeicherung |
| Alertmanager | Alarmierung |
| Zentrales Log-Management (Loki/ELK o. ä.) | Log-Sammlung und -Analyse |
| SIEM (optional) | Sicherheitsrelevante Korrelation |

---

## 8. Incident Management

*Integrationspunkt 3 in das Modulare Sicherheitskonzept der Einrichtung.*

### 8.1 Prozess
Standardisierter Umgang mit Sicherheitsvorfällen, ITIL-angelehnt:

**Identifikation → Erfassung → Kategorisierung → Priorisierung → Untersuchung/Diagnose → Lösung/Wiederherstellung → Abschluss**

### 8.2 Eskalationswege
| Stufe | Eskalation | Reaktionszeit |
|-------|------------|---------------|
| **P1 – Kritisch** | IT-Sicherheit, Leitung, ggf. CERT | < 2 Stunden (24/7) |
| **P2 – Dringend** | IT-Sicherheit | < 4 Stunden (Geschäftszeiten) |
| **P3 – Normal** | Support-Team | < 2 Werktage |
| **P4 – Wartung** | Planung | < 1 Woche |

### 8.3 Notfallkonzept
- Automatisierte tägliche Backups (k8up)
- Disaster-Recovery-Instanz (falls vorgesehen)
- **RPO:** < 1 Stunde, **RTO:** < 4 Stunden (Soll-Werte)
- Dokumentierter Wiederherstellungsprozess inkl. regelmäßigem DR-Test

### 8.4 Reporting
- Vorfälle dokumentieren und auswerten
- Lessons Learned nach jedem Incident
- Bericht an IT-Sicherheit / Leitung

---

## 9. Patch- und Update-Management

| Patch-Typ | Frist |
|-----------|-------|
| **Kritische Sicherheitspatches** (CERT) | schnellstmöglich, < 48 h |
| **Nicht-kritische Patches** | innerhalb definierter Zeit (z. B. 3 Monate) |
| **Geplante Releases** | Wartungsfenster, Ankündigung |

**Werkzeuge:** Cluster-Management, Container-Registry-Mirror, Helm/Helmfile-Upgrades

---

## 10. Backups und Wiederanlauf

| Aspekt | Festlegung |
|--------|------------|
| **Werkzeug** | k8up (restic) |
| **Ziel** | S3-kompatibles Speicher-Backend (getrennt je Tenant) |
| **Häufigkeit** | Täglich inkrementell, monatlich voll |
| **Retention** | 30 Tage (je nach Anforderung anpassbar) |
| **Restore-Test** | Regelmäßig (mind. monatlich) |
| **RPO / RTO** | RPO < 1 h, RTO < 4 h (Soll-Werte) |

---

## 11. Verantwortlichkeiten

| Funktion | Verantwortung |
|----------|---------------|
| **IT-Sicherheit** | Sicherheitskonzept, Incident Management, Audit |
| **Datenschutzbeauftragter (DSB)** | VVT, DSFA, Kontrolle TOM |
| **Rechenzentrum / Betrieb** | Patch-Management, Monitoring, Backups |
| **Fachverantwortliche** | Berechtigungen, Freigaben |
| **Verwaltungsleitung** | Freigabe, Eskalation |

---

## 12. Regelmäßige Überprüfung

| Prüfung | Turnus | Verantwortlich |
|---------|--------|----------------|
| Sicherheitskonzept-Review | jährlich / bei wesentlichen Änderungen | IT-Sicherheit |
| Zugriffsrechte-Review | quartalsweise | Fachverantwortliche |
| Backup-Restore-Test | monatlich | Betrieb |
| Compliance-Checkliste (BSI/ISO) | jährlich / pro Betriebsphase | IT-Sicherheit |
| Penetrationstest / Audit | regelmäßig | extern/intern |

---

## 13. Anpassungs-Checkliste

- [ ] Institution und Verantwortliche eintragen
- [ ] Schutzbedarfsfeststellung an eigene Datenbestände anpassen
- [ ] Schutzniveau mit Modularem Sicherheitskonzept der Einrichtung abgleichen
- [ ] Komponenten-Liste an tatsächlichen Stack anpassen
- [ ] Netzwerkarchitektur (IP-Bereiche, VLANs) ergänzen
- [ ] Keycloak/IdP-Verantwortliche benennen
- [ ] Berechtigungsmatrix mit Rollen der Einrichtung abgleichen
- [ ] Log-Aufbewahrungsfristen festlegen
- [ ] Eskalationswege und Kontaktdaten eintragen
- [ ] RPO/RTO-Ziele mit Betrieb abstimmen
- [ ] DR-Prozess und Testintervall festlegen
- [ ] Review-Turnus und Verantwortliche bestätigen
- [ ] Freigabe durch IT-Sicherheit und Leitung einholen

---

## Anhang

### A. Referenzierte Dokumente
| Dokument | Rechtsgrundlage/Zweck |
|----------|-----------------------|
| BSI IT-Grundschutz Kompendium | Bausteine OPS.1.1.5, APP.4.4, SYS.1.1 u. a. |
| ISO/IEC 27001 | ISMS-Anforderungen |
| DSGVO Art. 32 | Technisch-organisatorische Maßnahmen |
| Modulares Sicherheitskonzept der Einrichtung | Rahmenbedingungen |

### B. Änderungshistorie
| Version | Datum | Änderung |
|---------|-------|----------|
| 1.0 | [TT.MM.JJJJ] | Initiale Fassung |

<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Technische und organisatorische Maßnahmen (TOM)
## openDesk Edu – On-Premises-Betrieb

> **⚠️ Rechtlicher Hinweis**
> Dieses Dokument ist eine **anonymisierte Vorlage** und muss an die spezifischen Anforderungen der jeweiligen Institution angepasst werden.
> Es basiert auf:
> - **Art. 32 DSGVO** (Sicherheit der Verarbeitung)
> - **BSI IT-Grundschutz** (Modulare Sicherheitskonzepte)
> - **ISO/IEC 27001** (Informationssicherheits-Managementsysteme)
>
> Vor Nutzung durch **DSB/Rechtsabteilung** prüfen lassen.

---

**Verantwortlicher:**
[Name der Bildungseinrichtung] – Rechenzentrum (RZ)

**Datum:** [TT.MM.JJJJ]
**Version:** 1.0

---

*Dieses Dokument beschreibt die **technischen und organisatorischen Maßnahmen (TOM)** nach **Art. 32 DSGVO** für den Betrieb von openDesk Edu.*

---

## 1. Einleitung

### 1.1 Ziel
Sicherstellung eines **dem Risiko angemessenen Schutzniveaus** für personenbezogene Daten, die im Rahmen von openDesk Edu verarbeitet werden.

**Rechtsgrundlagen:**
- **Art. 32 DSGVO** – Sicherheit der Verarbeitung
- **Art. 28 DSGVO** – Auftragsverarbeitung (falls externe Dienstleister beteiligt)
- **BSI IT-Grundschutz** – Empfehlungen für öffentliche Stellen
- **[Landesdatenschutzgesetz (LDSG)]** – Landesrechtliche Vorgaben

### 1.2 Geltungsbereich
Diese TOM gelten für:
- **Alle openDesk Edu-Komponenten** (openCloud, SOGo, Jitsi, Element, Portal)
- **Die zugrundeliegende Infrastruktur** (K3s, Ceph, Shibboleth, IdM-Anbindung)
- **Alle Administrator:innen und Nutzer:innen** von openDesk Edu

---

## 2. Übersicht der TOM

| **Kategorie** | **Maßnahme** | **Status** | **Verantwortlich** | **Referenz (BSI/ISO)** |
|---------------|--------------|------------|--------------------|------------------------|
| **Vertraulichkeit** | Zutrittskontrolle (RZ) | ✅ | RZ | BSI ISI 1.2 |
|  | Zugriffskontrolle (RBAC, MFA) | ✅ | RZ | BSI ISI 1.3 |
|  | Verschlüsselung (TLS, AES-256) | ✅ | RZ | BSI ISI 3.3 |
|  | Pseudonymisierung (IP-Adressen) | ✅ | RZ | BSI ISI 1.7 |
| **Integrität** | Ceph-Replikation (Faktor 3) | ✅ | RZ | BSI ISI 4.1 |
|  | Prüfsummen (SHA-256) | ✅ | RZ | BSI ISI 4.2 |
|  | Backup-Verifizierung | ✅ | RZ | BSI ISI 4.3 |
| **Verfügbarkeit** | Cluster-HA (3 Control-Plane-Nodes) | ✅ | RZ | BSI ISI 5.1 |
|  | USV | ✅ | RZ | BSI ISI 5.2 |
|  | Georedundanz (Backup-Standort) | ✅ | RZ | BSI ISI 5.3 |
| **Protokollierung** | Zentrale Logs (Loki/ELK) | ✅ | RZ | BSI ISI 6.1 |
|  | SIEM (Wazuh) | ✅ | RZ | BSI ISI 6.2 |
|  | Audit-Logs (K8s, Shibboleth) | ✅ | RZ | BSI ISI 6.3 |
| **Organisatorisch** | Schulungen (jährlich) | ✅ | RZ | BSI ISI 7.1 |
|  | Incident-Response-Plan | ✅ | RZ | BSI ISI 7.2 |
|  | Vier-Augen-Prinzip | ✅ | RZ | BSI ISI 7.3 |

---

## 3. Detaillierte Maßnahmen

---

### 3.1 Vertraulichkeit

#### 3.1.1 Physische Sicherheit
| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **Zutrittskontrolle** | Zugang zum RZ nur mit Chipkarte + PIN | ✅ | RZ |
| **Videoüberwachung** | Überwachung der RZ-Zugänge | ✅ | RZ |
| **Alarmanlage** | Einbruchschutz | ✅ | RZ |
| **Brandschutz** | Rauchmelder, Löschsysteme | ✅ | RZ |
| **Notfallplan** | Definierte Prozesse für Notfälle (Brand, Einbruch) | ✅ | RZ |

#### 3.1.2 Logische Zugriffskontrolle
| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **Single Sign-On (SSO)** | Shibboleth SP (SAML 2.0) mit lokaler IdP | ✅ | RZ |
| **Attribut-Mapping** | Beschränkung auf notwendige Attribute: `eduPersonAffiliation`, `mail`, `displayName`, `scopedAffiliation` | ✅ | RZ |
| **Multi-Faktor-Authentifizierung (MFA)** | Pflicht für Admin-Zugriffe (TOTP via Keycloak/PrivacyIDEA) | ✅ | RZ |
| **Session-Timeout** | Automatische Abmeldung nach **8 Stunden Inaktivität** | ✅ | RZ |
| **RBAC (Role-Based Access Control)** | Kubernetes-RBAC + openDesk-spezifische Rollen (Admin, Nutzer:in, Gast, Auditor) | ✅ | RZ |
| **Privileged Access Management (PAM)** | Admin-Zugriffe nur über **Bastion-Host** mit Audit-Logging | ✅ | RZ |
| **Just-in-Time (JIT) Access** | Temporäre Admin-Rechte via Teleport/Vault | ⚠️ Geplant | RZ |
| **Service Accounts** | Dedizierte Accounts für Anwendungen mit minimalen Rechten | ✅ | RZ |

#### 3.1.3 Verschlüsselung
| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **TLS 1.3** | Verschlüsselung aller externen Zugriffe (HTTPS) | ✅ | RZ |
| **Zertifikatsmanagement** | Automatisierte Rotation via cert-manager (öffentliche/interne CA) | ✅ | RZ |
| **Storage-Verschlüsselung** | AES-256 für Ceph-RBD-Volumes | ✅ | RZ |
| **ZFS-Encryption** | Alternative zu Ceph (AES-256) | ✅ | RZ |
| **Backup-Verschlüsselung** | AES-256 für alle Backups, Schlüssel separiert (HSM/Offline) | ✅ | RZ |

#### 3.1.4 Pseudonymisierung und Datensparsamkeit
| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **Pseudonymisierung von IP-Adressen** | IP-Adressen in Logs werden nach **7 Tagen** pseudonymisiert | ✅ | RZ |
| **Datenminimierung** | Nur notwendige Attribute aus IdM synchronisiert | ✅ | RZ |
| **Zweckbindung** | Daten werden nur für dokumentierte Zwecke verarbeitet | ✅ | RZ |

---

### 3.2 Integrität

#### 3.2.1 Speicherschutz
| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **Ceph-Replikation** | Replikationsfaktor 3 (Daten auf 3 physischen Servern) | ✅ | RZ |
| **RAID/ZFS** | Redundante Speicherung | ✅ | RZ |
| **Prüfsummen** | SHA-256 für alle gespeicherten Daten | ✅ | RZ |
| **Backup-Verifizierung** | Automatische Prüfung der Backup-Integrität | ✅ | RZ |

#### 3.2.2 Nutzungskontrolle
| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **RBAC** | Rollenbasierte Berechtigungen (Least Privilege) | ✅ | RZ |
| **Network Policies** | Kubernetes-Netzwerkrichtlinien zur Isolation von Pods | ✅ | RZ |
| **Quotenregelung** | Speicher- und CPU-Limits für Nutzer:innen | ✅ | RZ |

---

### 3.3 Verfügbarkeit

#### 3.3.1 Hochverfügbarkeit
| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **Kubernetes-HA** | 3 Control-Plane-Nodes für Ausfallsicherheit | ✅ | RZ |
| **Worker-Nodes** | [Anzahl] Worker-Nodes für Lastverteilung | ✅ | RZ |
| **Load Balancing** | NGINX/Traefik als Ingress-Controller | ✅ | RZ |

#### 3.3.2 Stromversorgung
| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **USV** | Unterbrechungsfreie Stromversorgung für kritische Systeme | ✅ | RZ |
| **Notstromaggregat** | Backup-Stromversorgung für RZ | ⚠️ Optional | RZ |

#### 3.3.3 Backup und Disaster Recovery
| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **Backup-Strategie** | Tägliche inkrementelle + wöchentliche Voll-Backups | ✅ | RZ |
| **RPO/RTO** | Recovery Point Objective (RPO) ≤ **1 Stunde**, Recovery Time Objective (RTO) ≤ **4 Stunden** | ✅ | RZ |
| **Backup-Ziele** | Backup-Server (VMs), Objekt-Speicher (S3-kompatibel) für openCloud/SOGo | ✅ | RZ |
| **Verschlüsselung** | Alle Backups mit AES-256 verschlüsselt | ✅ | RZ |
| **Georedundanz** | Backups auf **zwei physisch getrennte Standorte** | ✅ | RZ |
| **Rollback-Tests** | Wöchentliche Tests der Backup-Wiederherstellung (automatisiert) | ✅ | RZ |
| **Disaster Recovery (DR)** | Notfall-Instanz auf separater Hardware (für IdM-Kompromittierung) | ⚠️ Optional | RZ |
| **DR-Testing** | Jährlicher DR-Test mit Dokumentation | ⚠️ Geplant | RZ |

---

### 3.4 Protokollierung und Monitoring

#### 3.4.1 Logging
| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **Zentrale Log-Sammlung** | Loki oder ELK-Stack für alle Anwendungs- und Systemlogs | ✅ | RZ |
| **Anwendungslogs** | Logs für openCloud, SOGo, Jitsi, Element | ✅ | RZ |
| **Systemlogs** | K3s, Virtualisierungsplattform, Storage | ✅ | RZ |
| **Sicherheitslogs** | K8s-Audit-Logs, Shibboleth-Logs, IdM-Logs, Firewall-Logs | ✅ | RZ |
| **Log-Retention** | 30 Tage (Anwendungslogs), **90 Tage (Sicherheitslogs)** | ✅ | RZ |
| **Immutable Logs** | Logs werden unveränderbar gespeichert (Write-Once-Read-Many, WORM) | ✅ | RZ |

#### 3.4.2 SIEM (Security Information and Event Management)
| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **SIEM-System** | Wazuh oder Graylog für Sicherheitsanalysen | ✅ | RZ – IT-Sicherheit |
| **Echtzeit-Überwachung** | Monitoring von Sicherheitsereignissen (z. B. Brian-Force-Angriffe) | ✅ | RZ |
| **Alerting** | Benachrichtigung bei kritischen Ereignissen (z. B. multiple fehlgeschlagene Logins) | ✅ | RZ |

#### 3.4.3 Audit-Logging
| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **K8s-Audit-Logs** | Protokollierung aller Admin-Aktionen (z. B. `kubectl` Befehle) | ✅ | RZ |
| **Shibboleth-Audit-Logs** | Protokollierung aller Authentifizierungsversuche | ✅ | RZ |
| **IdM-Audit-Logs** | Protokollierung aller Nutzerverwaltung-Aktionen | ✅ | RZ |

---

### 3.5 Organisatorische Maßnahmen

#### 3.5.1 Schulungen und Awareness
| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **Datenschutzschulungen** | Jährliche Pflichtschulungen für Admin-Personal | ✅ | RZ |
| **IT-Sicherheitsschulungen** | Regelmäßige Schulungen zu Sicherheitsthemen (z. B. Phishing) | ✅ | RZ |
| **Awareness-Kampagnen** | Sensibilisierung der Nutzer:innen (z. B. sichere Passwörter) | ✅ | RZ |

#### 3.5.2 Incident-Response
| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **Incident-Response-Plan** | Definierter Prozess für Datenschutzvorfälle | ✅ | RZ |
| **Meldepflichten (Art. 33/34 DSGVO)** | Automatisierte Benachrichtigung des DSB bei Vorfällen innerhalb von **72 Stunden** | ✅ | RZ |
| **Vorfallsdokumentation** | Dokumentation aller Sicherheitsvorfälle | ✅ | RZ |
| **Nachbereitung** | Analyse und Verbesserungsmaßnahmen nach Vorfällen | ✅ | RZ |

#### 3.5.3 Compliance und Audits
| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **DSB-Einbindung** | Regelmäßige Abstimmung mit dem Datenschutzbeauftragten (vierteljährlich) | ✅ | RZ / DSB |
| **Interne Audits** | Jährliche Überprüfung der TOM und des VVT | ✅ | RZ – IT-Sicherheit |
| **Externe Audits** | DSB-Prüfung alle **2 Jahre** | ✅ | DSB |
| **Compliance-Check** | Regelmäßige Prüfung gegen DSGVO, LDSG, BSI IT-Grundschutz | ✅ | RZ |

---

### 3.6 Netzwerksicherheit

| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **Isoliertes VLAN** | Kein direkter Internet-Zugriff auf K3s-Node-IPs | ✅ | RZ |
| **Firewall-Regeln** | Strenge Regeln auf Host- und Node-Ebene (nur HTTPS/443, interne APIs) | ✅ | RZ |
| **DMZ** | Externe Dienste (Ingress, Shibboleth) in separater Netzwerkzone | ✅ | RZ |
| **DDoS-Schutz** | Rate-Limiting auf Ingress-Controller (NGINX/Traefik) und Firewall | ✅ | RZ |
| **VPN** | Sichere Fernwartung für Admin-Personal | ✅ | RZ |

---

### 3.7 Kubernetes-Sicherheit

| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **CIS-Benchmark** | K3s-Konfiguration nach CIS-Benchmark | ✅ | RZ |
| **Pod Security Admission (PSA)** | Durchsetzung von Sicherheitsrichtlinien für Pods | ✅ | RZ |
| **Network Policies** | Isolation von Pods nach Bedarf (z. B. Datenbank-Pods) | ✅ | RZ |
| **Image-Pull-Policies** | Nur vertrauenswürdige Container-Images (offizielle Quellen, lokale Mirrors) | ✅ | RZ |
| **Image-Scanning** | Automatisiertes Scannen auf Schwachstellen (Trivy/Grype) | ✅ | RZ |
| **Patch-Management** | Regelmäßige Updates (< **24 Stunden** für kritische Patches) | ✅ | RZ |

---

### 3.8 Applikationssicherheit

| **Maßnahme** | **Beschreibung** | **Umsetzung** | **Verantwortlich** |
|--------------|------------------|---------------|--------------------|
| **HTTPS-Only** | Erzwingen von HTTPS für alle externa Zugriffe | ✅ | RZ |
| **OWASP Top 10** | Schutz vor häufigen Web-Schwachstellen (XSS, SQLi, CSRF) | ✅ | RZ |
| **Input-Validation** | Validierung aller Nutzerinputs (openCloud, SOGo, Portal) | ✅ | RZ |
| **Spam- und Virus-Schutz** | Rspamd (SOGo), ClamAV (E-Mail-Anhänge) | ✅ | RZ |
| **E2EE (Element)** | Ende-zu-Ende-Verschlüsselung für Messenger-Nachrichten | ✅ | RZ |
| **E2EE (Jitsi)** | Optionale Ende-zu-Ende-Verschlüsselung für Meetings | ⚠️ Optional | RZ |

---

## 4. Verantwortlichkeiten

| **Rolle** | **Aufgaben** | **Kontakt** |
|-----------|--------------|-------------|
| **RZ-Leitung** | Gesamtverantwortung, Budget, Freigabe von Änderungen | [Name, E-Mail] |
| **IT-Sicherheit** | Sicherheitsüberwachung, Incident-Response | [Name, E-Mail] |
| **K3s-Administrator:innen** | Betrieb des Kubernetes-Clusters | [Name, E-Mail] |
| **Storage-Administrator:innen** | Betrieb von Ceph/ZFS | [Name, E-Mail] |
| **Backup-Team** | Backup-Strategie, Wiederherstellungstests | [Name, E-Mail] |
| **DSB** | Datenschutz-Compliance, Audits, Beratung | [Name, E-Mail] |

---

## 5. Referenzierte Dokumente

| **Dokument** | **Zweck** |
|--------------|-----------|
| [01-betriebsmittel-opendesk-edu.md](01-betriebsmittel-opendesk-edu.md) | Beschreibung von openDesk Edu als Betriebsmittel |
| [02-verarbeitungsverzeichnis.md](02-verarbeitungsverzeichnis.md) | Verarbeitungsverzeichnis (VVT) |
| [BSI IT-Grundschutz-Kompendium](https://www.bsi.bund.de/DE/Themen/ITGrundschutz/itgrundschutzkompendium_node.html) | Sicherheitsstandards |
| [ISO/IEC 27001](https://www.iso.org/isoiec-27001-information-security.html) | Informationssicherheits-Management |

---

## 6. Anhang: Checklisten

### 6.1 TOM-Checkliste (Kurzform)

- [ ] Zutrittskontrolle (RZ) implementiert
- [ ] Zugriffskontrolle (RBAC, MFA) aktiviert
- [ ] Verschlüsselung (TLS 1.3, AES-256) konfiguriert
- [ ] backups (täglich + wöchentlich)ingerichtet
- [ ] Georedundanz (Backup-Standort) vorhanden
- [ ] Rollback-Tests (wöchentlich) durchgeführt
- [ ] SIEM (Wazuh) betriebsbereit
- [ ] Pseudonymisierung (IP-Adressen) aktiviert
- [ ] Schulungen (jährlich) für Admin-Personal
- [ ] Incident-Response-Plan dokumentiert
- [ ] DSB eingebunden (vierteljährlich)

---

## 7. Unterschriften

| **Rolle** | **Name** | **Datum** | **Unterschrift** |
|-----------|----------|-----------|------------------|
| RZ-Leitung | [Name] | [Datum] | _______________ |
| IT-Sicherheit | [Name] | [Datum] | _______________ |
| Datenschutzbeauftragter (DSB) | [Name] | [Datum] | _______________ |

---

*Letzte Aktualisierung: 12.08.2026*

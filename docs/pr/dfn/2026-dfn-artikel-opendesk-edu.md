---
SPDX-License-Identifier: AGPL-3.0
---

# Offen. Austauschbar. Unabhängig. openDesk Edu: Ein Ökosystem für digitale Hochschulinfrastruktur

*Warum ein modulares Open-Source-Ökosystem den Betrieb digitaler Dienste an Hochschulen vereinfacht – und wie der Wechsel von Microsoft 365 gelingen kann, ohne sich in neue Abhängigkeiten zu begeben.*

---

![openDesk Edu – Lead Image](images/readme-lead-image.svg)
*openDesk Edu bündelt Bildungsdienste als austauschbare Komponenten in einem gemeinsamen Ökosystem – betrieben von Hochschulen für Hochschulen.*

---

## Die Herausforderung: Wachsende Anforderungen, begrenzte Ressourcen

Die digitale Infrastruktur an Hochschulen ist in den letzten Jahren stetig gewachsen. Moodle und ILIAS für Lernmanagement, Nextcloud für Dateifreigabe, SOGo oder Grommunio für E-Mail und Kalender, Etherpad für kollaboratives Arbeiten, JupyterHub für datengetriebene Lehre – die Liste bewährter Open-Source-Anwendungen ist lang und wird kontinuierlich länger.

Doch dieser Erfolg bringt eine Herausforderung mit sich: Jeder Dienst benötigt eine eigene Authentifizierung, ein eigenes Backup-Konzept, eigene Wartungsroutinen. Die Betriebskosten skalieren linear mit der Anzahl der Dienste, während die personellen Ressourcen an vielen Rechenzentren begrenzt sind. Vor diesem Hintergrund ist die Attraktivität integrierter Lösungen wie Microsoft 365 nachvollziehbar: Ein Dienst, ein Login, ein Vertrag – scheinbar einfacher zu betreiben als ein heterogenes Ökosystem.

Die Kehrseite dieser Entscheidung ist bekannt: proprietäre Formate, fehlende Kontrolle über die Datenhaltung, Abhängigkeit von einem einzigen Anbieter und dessen Lizenzpolitik. DFN-Mitglieder, die diesen Weg gegangen sind, berichten von steigenden Kosten bei nachlassender Flexibilität. Und der Wechsel zurück – oder zu einer anderen Lösung – ist teuer und aufwändig.

## Was openDesk Edu anders macht

openDesk Edu verfolgt einen grundlegend anderen Ansatz. Statt eine weitere Plattform zu schaffen, die alle Funktionen in sich vereint, entsteht ein **Ökosystem austauschbarer Komponenten**. Jede Anwendung bleibt eigenständig, wird aber über gemeinsame Infrastrukturdienste integriert: zentrale Authentifizierung über Keycloak, einheitliches Monitoring mit Prometheus und Grafana, automatisierte Backups über den Kubernetes-Operator k8up mit Restic.

Technisch basiert openDesk Edu auf Kubernetes (K3s) und containerisierten Diensten. Das ermöglicht es, Anwendungen unabhängig voneinander zu betreiben, zu aktualisieren und auszutauschen – ohne die Plattform als Ganzes zu berühren. Wer SOGo als Groupware bevorzugt, kann Grommunio einsetzen; wer Moodle statt ILIAS nutzen möchte, tauscht das Lernmanagement-System aus. Voraussetzung ist die Unterstützung offener Standards: SAML 2.0 oder OIDC für die Authentifizierung, standardisierte Protokolle für den Datenaustausch.

openDesk Edu baut auf **openDesk CE** auf – der Community Edition, die bereits in mehreren Bundesländern produktiv im Einsatz ist. In Baden-Württemberg nutzt das Landesmedienzentrum (LMZ) openDesk CE für den digitalen Arbeitsplatz von Lehrkräften, in Schleswig-Holstein ist openDesk CE Teil der Open-Source-Strategie des Landes. openDesk Edu erweitert diese Basis um Dienste, die spezifisch für den Hochschulbetrieb benötigt werden.

## Der Mehrwert für Hochschulen

Die zentrale Authentifizierung über Keycloak mit SAML 2.0 und OIDC – eine Integration der DFN-AAI ist in Vorbereitung – vereinfacht die Benutzerverwaltung erheblich. Neue Studierende werden einmal angelegt und haben sofort Zugang zu allen Diensten. Der Aufwand für die Administration sinkt, die Sicherheit steigt, weil Passwörter zentral verwaltet werden.

Das einheitliche Monitoring in Grafana gibt Administratoren einen vollständigen Überblick über den Zustand aller Dienste. Statt sich in verschiedene Dashboards einzuarbeiten, reicht ein Blick auf eine zentrale Übersicht. Das spart Zeit bei der Fehlersuche und ermöglicht eine frühzeitige Erkennung von Engpässen.

Die automatisierte Backup-Lösung mit k8up und Restic sichert täglich inkrementell alle Daten auf ein S3-kompatibles Ziel. Auch bei einem Totalausfall eines Knotens lassen sich alle Dienste zuverlässig wiederherstellen. Die Konfiguration erfolgt deklarativ über Kubernetes-Ressourcen und ist damit versionierbar und auditierbar.

## Betriebserfahrung aus Marburg

Am HRZ der Universität Marburg läuft openDesk Edu aktuell auf einem K3s-Cluster mit neun Knoten. Der produktionsnahe Testbetrieb umfasst 28 Dienste, darunter Lernmanagement-Systeme (Moodle, ILIAS), Kollaborationsdienste (Nextcloud/OpenCloud, Etherpad, Jitsi, Collabora), Groupware (SOGo), Forschungsinfrastruktur (JupyterHub, RStudio, Dask) sowie verschiedene Spezialdienste wie Overleaf, XWiki und Zammad.

Eine zentrale Erkenntnis der Testphase: Der Betrieb einer integrierten Plattform mit gemeinsamer Authentifizierung und Monitoring ist effizienter als der Betrieb vieler einzelner Dienste mit jeweils eigener Infrastruktur. Die Anfälligkeit für Konfigurationsfehler sinkt, weil zentrale Einstellungen einmal definiert und von allen Diensten genutzt werden. Gleichzeitig bleibt die Flexibilität erhalten, neue Dienste zu integrieren oder bestehende auszutauschen, ohne die Plattform umbauen zu müssen.

Eine interaktive Übersicht aller integrierten Dienste ist auf [landscape.opendesk-edu.org](https://landscape.opendesk-edu.org/) verfügbar.

## Warum der Wechsel zu Nextcloud allein nicht reicht

Ein häufig gewählter erster Schritt aus dem Microsoft-Ökosystem ist die Einführung von Nextcloud als zentraler Dateiablage. Das ist ein wichtiger und richtiger Schritt – aber er löst das grundlegende Problem nicht: Die Abhängigkeit von einem einzelnen Anbieter bleibt bestehen, nur die Lizenz wechselt von proprietär zu Open Source. Die Migration bleibt aufwändig, die Schnittstellen sind oft anbieterspezifisch, und der nächste Wechsel ist kaum weniger schmerzhaft.

openDesk Edu setzt hier einen Schritt früher an: Statt eine Plattform durch eine andere zu ersetzen, entsteht eine **Infrastruktur für den Betrieb beliebiger Dienste**. Die Plattform selbst ist der gemeinsame Rahmen – Authentifizierung, Monitoring, Backup, Deployment. Die Dienste darin sind austauschbar. Das reduziert das Risiko von Fehlentscheidungen, weil keine Komponente so eng an die Plattform gebunden ist, dass ein späterer Austausch prohibitiv teuer wäre.

## Einladung zur Mitarbeit

openDesk Edu versteht sich als offene Initiative – nicht als fertiges Produkt. Hochschulen sind eingeladen, von Anfang an mitzugestalten:

- **Testen und Evaluieren**: Interessierte Hochschulen können Unterstützung bei der Einrichtung einer Demo-Umgebung erhalten.
- **Betriebserfahrungen teilen**: Wer openDesk Edu bereits testet, kann seine Erfahrungen in die Weiterentwicklung einfließen lassen.
- **Code beitragen**: Neue Helm-Charts für bislang nicht integrierte Dienste, Bugfixes und Verbesserungen sind jederzeit willkommen.
- **Anforderungen einbringen**: Welche Dienste fehlen? Welche Integrationen sind wichtig? Die Community definiert die Roadmap gemeinsam.

Die Community organisiert sich über quartalsweise Community-of-Practice-Calls; Termine werden im [opendesk-edu-cop-Repository](https://gitlab.com/opendesk-edu/opendesk-edu-cop) veröffentlicht. Der gesamte Quellcode ist auf GitLab unter [gitlab.com/opendesk-edu](https://gitlab.com/opendesk-edu) verfügbar und steht unter der Apache-2.0- bzw. AGPL-3.0-Lizenz.

---

## Quick Facts

| **Kategorie** | **Details** |
|---------------|------------|
| **Lizenz** | Apache 2.0 / AGPL 3.0 (je nach Komponente) |
| **Basis** | openDesk CE (Community Edition) |
| **Technologie** | Kubernetes (K3s), Helm, Ceph CSI, Restic / k8up |
| **Authentifizierung** | Keycloak (SAML 2.0 + OIDC); DFN-AAI-Integration in Vorbereitung |
| **Monitoring** | Prometheus + Grafana |
| **Backup** | k8up (inkrementell, Restic, S3-kompatibel) |
| **Status** | Erprobungsphase am HRZ Marburg |
| **Dienste** | 28+ integrierte Komponenten ([Übersicht](https://landscape.opendesk-edu.org/)) |

---

**Projekt-Links:**
[opendesk-edu.org](https://opendesk-edu.org/en) · [landscape.opendesk-edu.org](https://landscape.opendesk-edu.org/) · [gitlab.com/opendesk-edu](https://gitlab.com/opendesk-edu) · [docs.opendesk.eu](https://docs.opendesk.eu)

---

## Für die Redaktion

**Zielgruppe:** IT-Entscheider an Hochschulen (CIOs, Leiter Rechenzentren), Systemadministratoren, DFN-Mitglieder

**Platzierungsvorschläge:**
- **Aufmacher:** Fokus auf Ökosystem-Ansatz und digitale Souveränität als strategische Entscheidung
- **Fachbeitrag:** Architektur und Betriebserfahrungen aus der Praxis
- **Interview-Format:** Gespräch mit Tobias Weiß (HRZ Marburg) zu Umsetzung und Lessons Learned

**Bildmaterial (Druckqualität):**
- `images/readme-lead-image.svg` – Titelbild (Vektor, skalierbar)
- `images/opendesk-portal2.png` – Portal-Screenshot (1920×1080)
- `images/opendesk-edu-ilias-integration.gif` – ILIAS SSO-Integration (animiert)
- `images/grafana.png` – Grafana-Dashboard
- [landscape.opendesk-edu.org](https://landscape.opendesk-edu.org/) – Interaktive Übersicht des Ökosystems

**Weiterführende Links:**
- [Offener Brief (PAK DiGS / GI e.V.)](https://pak-digs.gi.de/mitteilung/offener-brief-an-den-herrn-bundesminister-fuer-digitales-und-staatsmodernisierung-bmds-digitale-souveraenitaet-an-hochschulen-dringender-handlungsbedarf-fuer-eine-faire-marktsituation-opendesk-vs-microsoft)
- [Baden-Württemberg: Digitaler Arbeitsplatz für Lehrkräfte](https://www.baden-wuerttemberg.de/de/service/presse/pressemitteilung/pid/digitaler-arbeitsplatz-fuer-lehrkraefte-wird-nun-mit-opendesk-umgesetzt-1)
- [Schleswig-Holstein: Linux+1 Open-Source-Strategie](https://www.schleswig-holstein.de/DE/landesregierung/themen/digitalisierung/linux-plus1)
- [CLT26-Vortrag: „Bequem oder souverän? openDesk für Hochschulen"](https://media.ccc.de/v/clt26-131-bequem-oder-souveran-opendesk-fur-hochschulen)
- [Diskussion auf opencode.de](https://discourse.opencode.de/t/opendesk-edu-offenes-oekosystem-fuer-hochschulen-mitmachen-und-mitgestalten/5625)

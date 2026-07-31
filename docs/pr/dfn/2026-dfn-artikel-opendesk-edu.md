---
SPDX-License-Identifier: AGPL-3.0
---

# Offen. Austauschbar. Unabhängig. openDesk Edu: Ein Ökosystem für digitale Hochschulinfrastruktur

*Warum ein modulares Open-Source-Ökosystem den Betrieb digitaler Dienste an Hochschulen vereinfachen kann – und worauf es beim Wechsel von Microsoft 365 ankommt, um neue Abhängigkeiten zu vermeiden.*

---

![openDesk Edu – Lead Image](images/readme-lead-image.svg)
*openDesk Edu bündelt Bildungsdienste als austauschbare Komponenten in einem gemeinsamen Ökosystem – betrieben von Hochschulen für Hochschulen.*

---

## Die Herausforderung: Wachsende Anforderungen, begrenzte Ressourcen

Die digitale Infrastruktur an Hochschulen ist in den letzten Jahren stetig gewachsen. Moodle und ILIAS für Lernmanagement, Nextcloud für Dateifreigabe, SOGo oder Grommunio für E-Mail und Kalender, Etherpad für kollaboratives Arbeiten, JupyterHub für datengetriebene Lehre – die Liste bewährter Open-Source-Anwendungen ist lang und wird kontinuierlich länger.

Doch dieser Erfolg bringt eine Herausforderung mit sich: Jeder Dienst benötigt eine eigene Authentifizierung, ein eigenes Backup-Konzept, eigene Wartungsroutinen. Die Betriebskosten skalieren mit der Anzahl der Dienste, während die personellen Ressourcen vielerorts begrenzt sind. Die Rechenzentren leisten hier oft viel Arbeit – sie sind in vielen Themen mit an Bord, halten den Laden am Laufen, wissen oft genau, was die Nutzenden brauchen und wie sie arbeiten. Vor diesem Hintergrund ist die Attraktivität integrierter Lösungen wie Microsoft 365 nachvollziehbar: Ein Dienst, ein Login, ein Vertrag – scheinbar einfacher zu betreiben als ein heterogenes Ökosystem.

Die Kehrseite dieser Entscheidung ist bekannt: proprietäre Formate, fehlende Kontrolle über die Datenhaltung, Abhängigkeit von einem einzigen Anbieter und dessen Lizenzpolitik. DFN-Mitglieder, die diesen Weg gegangen sind, berichten von steigenden Kosten bei nachlassender Flexibilität.

openDesk Edu ist ein Angebot an Hochschulen, die diesen Schritt gehen möchten – nicht die Behauptung, dass es für alle der richtige Weg ist. Jede Hochschule hat eigene Rahmenbedingungen, eigene Historie, eigene Prioritäten. Das Projekt versteht sich als Werkzeugkasten, nicht als Dogma.

## Was openDesk Edu anders macht

openDesk Edu verfolgt einen anderen Ansatz: Statt eine weitere Plattform zu schaffen, die alle Funktionen in sich vereint, entsteht ein **Ökosystem austauschbarer Komponenten**. Jede Anwendung bleibt eigenständig, wird aber über gemeinsame Infrastrukturdienste integriert: zentrale Authentifizierung über Keycloak, einheitliches Monitoring mit Prometheus und Grafana, automatisierte Backups über den Kubernetes-Operator k8up mit Restic.

Technisch basiert openDesk Edu auf Kubernetes (K3s) und containerisierten Diensten. Das ermöglicht es, Anwendungen unabhängig voneinander zu betreiben, zu aktualisieren und auszutauschen – ohne die zugrundeliegende Infrastruktur jedes Mal anpassen zu müssen. Wer SOGo als Groupware bevorzugt, kann Grommunio einsetzen; wer Moodle statt ILIAS nutzen möchte, tauscht das Lernmanagement-System aus. Voraussetzung ist die Unterstützung offener Standards: SAML 2.0 oder OIDC für die Authentifizierung, standardisierte Protokolle für den Datenaustausch.

openDesk Edu baut auf der **Vanilla-Version von openDesk** auf – also der Basis, die sowohl die Community Edition als auch die Enterprise Edition umfasst und die in mehreren Bundesländern im Einsatz ist. In Baden-Württemberg nutzt das Landesmedienzentrum (LMZ) openDesk für den digitalen Arbeitsplatz von Lehrkräften, in Schleswig-Holstein ist openDesk Teil der Open-Source-Strategie des Landes. openDesk Edu erweitert diese Basis um Dienste, die spezifisch für den Hochschulbetrieb benötigt werden.

## Der Mehrwert für Hochschulen

Die zentrale Authentifizierung über Keycloak mit SAML 2.0 und OIDC – eine Integration der DFN-AAI ist in Vorbereitung – vereinfacht die Benutzerverwaltung: Neue Studierende werden einmal angelegt und haben Zugang zu den angebundenen Diensten. Der Aufwand für die Administration sinkt, die Sicherheit steigt, weil Passwörter zentral verwaltet werden.

Das einheitliche Monitoring in Grafana gibt Administratoren einen Überblick über den Zustand der Dienste. Statt sich in verschiedene Dashboards einzuarbeiten, reicht ein Blick auf eine zentrale Übersicht. Das spart Zeit bei der Fehlersuche und ermöglicht eine frühzeitige Erkennung von Engpässen.

Die automatisierte Backup-Lösung mit k8up und Restic sichert täglich inkrementell Daten auf ein S3-kompatibles Ziel. Auch bei einem Totalausfall eines Knotens lassen sich die Dienste wiederherstellen. Die Konfiguration erfolgt deklarativ über Kubernetes-Ressourcen und ist damit versionierbar und auditierbar.

## Betriebserfahrung aus Marburg

Am HRZ der Universität Marburg läuft openDesk Edu aktuell auf einem K3s-Cluster mit neun Knoten. Der produktionsnahe Testbetrieb umfasst 28 Dienste, darunter Lernmanagement-Systeme (Moodle, ILIAS), Kollaborationsdienste (Nextcloud/OpenCloud, Etherpad, Jitsi, Collabora), Groupware (SOGo), Forschungsinfrastruktur (JupyterHub, RStudio, Dask) sowie verschiedene Spezialdienste wie Overleaf, XWiki und Zammad.

Eine Beobachtung aus der Testphase: Der Betrieb mit gemeinsamer Authentifizierung und Monitoring reduziert den Aufwand für wiederkehrende Konfigurationsarbeiten – Admins müssen zentrale Einstellungen nur einmal definieren. Gleichzeitig bleibt die Flexibilität erhalten, neue Dienste zu integrieren oder bestehende auszutauschen.

Eine interaktive Übersicht aller integrierten Dienste ist auf [landscape.opendesk-edu.org](https://landscape.opendesk-edu.org/) verfügbar.

## Warum der Wechsel zu Nextcloud allein nicht reicht

Ein häufig gewählter erster Schritt aus dem Microsoft-Ökosystem ist die Einführung von Nextcloud als zentraler Dateiablage. Das ist ein wichtiger und richtiger Schritt. Vielerorts funktioniert das hervorragend – Nextcloud ist eine ausgereifte Plattform, die viele Anforderungen abdeckt.

openDesk Edu adressiert eine Frage, die danach kommt: Was ist mit den Diensten, die Nextcloud nicht abbildet – Lernmanagement, Groupware, Videokonferenz, Forschungsumgebungen? Für jede dieser Aufgaben gibt es bewährte Open-Source-Lösungen. openDesk Edu bietet eine gemeinsame Infrastruktur, um diese Dienste zusammenzuführen, ohne sie an die Plattform zu binden. Wer Nextcloud durch OpenCloud ersetzen möchte, kann das. Wer Moodle statt ILIAS einsetzt, tauscht das Lernmanagement-System aus. Die Plattform selbst ist der gemeinsame Rahmen – Authentifizierung, Monitoring, Backup, Deployment. Die Dienste darin bleiben austauschbar.

## Einladung – auf unterschiedlichen Wegen

### Was wir bisher gelernt haben

Die Rückmeldungen der ersten Gespräche haben uns gezeigt: Es gibt gute Gründe, aus der Distanz zu beobachten. Das tagesgeschäft bindet – und zwar völlig zu Recht. Wer den Betrieb am Laufen hält, hat nicht automatisch Kapazität, sich in neue Plattformen einzuarbeiten. Dass Rechenzentren ihre vorhandenen Dienste zuverlässig betreiben, ist die Voraussetzung dafür, dass Projekte wie dieses überhaupt denkbar sind.

Wir haben auch gelernt, dass die Frage „Ist das etwas für uns?" nicht von allein beantwortet wird und dass Skepsis gegenüber neuen Plattformen berechtigt ist. Deshalb setzen wir auf konkret erfahrbare Ergebnisse statt auf Versprechen: Wer neugierig geworden ist, kann sich eine Demo-Umgebung ansehen, die Code-Repositories durchstöbern oder einen Blick in die Architektur-Dokumentation werfen.

### Beteiligung, die zum eigenen Tempo passt

Beteiligung an openDesk Edu kann unterschiedlich aussehen. Die Erfahrung zeigt, dass die hilfreichsten Beiträge oft von denen kommen, die zunächst nur eine Frage hatten oder eine Unsicherheit geteilt haben:

- **Nachfragen und Zweifel teilen**: Wer sich fragt, ob das eigene Rechenzentrum überhaupt zu openDesk Edu passt, spricht damit oft ein Thema an, das auch andere beschäftigt. Diese Fragen helfen, das Projekt verständlicher zu machen.
- **Von den eigenen Realitäten erzählen**: Jede Hochschule hat eigene Rahmenbedingungen – historisch gewachsene Infrastruktur, spezifische Anforderungen, knappe Ressourcen. Diese Geschichten sind nicht „nur" lokale Besonderheiten, sondern zeigen dem Projekt, wo die Praxis von der Theorie abweicht.
- **Einzelfragen stellen statt alles entscheiden**: Es muss nicht jede Stimme zu jeder Entscheidung gehört werden. Aber: Wer eine konkrete Frage hat – zu einem Dienst, zur Authentifizierung, zum Betrieb – kann sie jederzeit stellen, ohne sich vorher in das gesamte Projekt einarbeiten zu müssen.

Wer sich stärker einbringen möchte, kann Code beitragen, Helm-Charts beisteuern oder bei der Weiterentwicklung der Roadmap mitwirken. Das ist willkommen, aber keine Voraussetzung.

Die Community organisiert sich über quartalsweise Community-of-Practice-Calls; Termine werden im [opendesk-edu-cop-Repository](https://gitlab.com/opendesk-edu/opendesk-edu-cop) veröffentlicht. Der gesamte Quellcode ist auf GitLab unter [gitlab.com/opendesk-edu](https://gitlab.com/opendesk-edu) verfügbar und steht unter der Apache-2.0- bzw. AGPL-3.0-Lizenz.

---

## Quick Facts

| **Kategorie** | **Details** |
|---------------|------------|
| **Lizenz** | Apache 2.0 / AGPL 3.0 (je nach Komponente) |
| **Basis** | openDesk (Vanilla-Version, CE und EE) |
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

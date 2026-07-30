---
SPDX-License-Identifier: AGPL-3.0
---

# Offen. Austauschbar. Unabhängig. openDesk Edu: Ein Ökosystem für Bildungsdienste

*Wie ein modulares Open-Source-Ökosystem den Betrieb von Lernplattformen, Groupware und Kollaborationstools an Hochschulen vereinfacht – und warum der Wechsel von Microsoft 365 zu Nextcloud allein nicht reicht.*

*Von Tobias Weiß – Veröffentlicht: Juli 2026*

---

![openDesk Edu – Lead Image](images/readme-lead-image.svg)
*Von Hochschulen für Hochschulen: openDesk Edu bündelt Bildungsdienste als austauschbare Komponenten in einem gemeinsamen Ökosystem.*

---

## Digitale Lehre braucht mehr als einzelne Tools

An deutschen Hochschulen herrscht ein paradoxer Zustand. Einerseits gibt es einen wachsenden Katalog bewährter Open-Source-Anwendungen für Lehre und Forschung: Moodle und ILIAS für Lernmanagement, Nextcloud für Dateifreigabe, SOGo oder Grommunio für E-Mail und Kalender, Etherpad für kollaboratives Schreiben, JupyterHub für datengetriebene Lehre. Andererseits betreibt fast jede Hochschule diese Dienste isoliert – mit eigenem Single Sign-On, eigenem Backup-Konzept, eigener Wartung. Die Folge: Doppelter Aufwand, hohe Personalkosten und Sicherheitsrisiken durch heterogene, oft veraltete Installationen.

Die Versuchung ist groß, dieses Problem mit einer kommerziellen Gesamtlösung zu lösen. Microsoft 365 bietet genau dies: eine integrierte Plattform, die scheinbar alles abdeckt. Doch der Preis ist die Abhängigkeit – von proprietären Formaten, von einem einzigen Anbieter, von dessen Lizenzmodell und Roadmap. Der Wechsel zurück ist teuer, oft unmöglich. Und der Wechsel zu einer einzelnen Open-Source-Alternative löst das Problem nicht zwangsläufig: Wer Nextcloud als zentrale Plattform einführt, tauscht eine Abhängigkeit gegen eine andere. Die neue Lösung mag quelloffen sein, aber die Migration bleibt schmerzhaft, die Schnittstellen sind proprietär, und die nächste Alternative ist ebenso schwer zu erreichen.

Was Hochschulen brauchen, ist keine neue Plattform, sondern ein **Ökosystem**, in dem jede Komponente austauschbar ist.

## Ausgangspunkt: Der Offene Brief

Die Idee dazu ist nicht aus dem Nichts entstanden. Im Herbst 2024 veröffentlichten der Präsidiumsarbeitskreis „Digitale Souveränität" der Gesellschaft für Informatik (GI), die Arbeitskreise „Open Source Software" und „Datenschutz und IT-Sicherheit" sowie der ZKI e.V. einen [Offenen Brief an den Bundesminister für Digitales und Staatsmodernisierung](https://pak-digs.gi.de/mitteilung/offener-brief-an-den-herrn-bundesminister-fuer-digitales-und-staatsmodernisierung-bmds-digitale-souveraenitaet-an-hochschulen-dringender-handlungsbedarf-fuer-eine-faire-marktsituation-opendesk-vs-microsoft). Darin formulierten die Unterzeichner den Handlungsbedarf klar: Der Markt für digitale Arbeitsplätze an Hochschulen sei verzerrt, weil Microsoft 365 durch volumenbasierte Bildungslizenzen de facto zum Standard geworden sei – und Wettbewerber, insbesondere Open-Source-Angebote, dadurch strukturell benachteiligt würden.

Dieser Brief war der Auslöser für openDesk Edu. Das Projekt nimmt die dort beschriebene Problematik auf und liefert eine konkrete technische Antwort: eine freie, modulare, hochschulspezifische Plattform, die den Wechsel aus dem Microsoft-Ökosystem nicht durch eine neue Abhängigkeit ersetzt, sondern durch Wahlfreiheit.

## Was openDesk Edu anders macht

openDesk Edu baut auf **openDesk CE** auf – der Community Edition, die bereits in mehreren Bundesländern produktiv eingesetzt wird. In Baden-Württemberg nutzt das Landesmedienzentrum (LMZ) openDesk CE für den digitalen Arbeitsplatz von Lehrkräften, in Schleswig-Holstein bildet openDesk CE einen Baustein der Open-Source-Strategie [„Linux+1"](https://www.schleswig-holstein.de/DE/landesregierung/themen/digitalisierung/linux-plus1). openDesk Edu erweitert diese Basis gezielt um Lernmanagement-Systeme, Forschungsinfrastruktur und weitere Dienste, die im Hochschulbetrieb benötigt werden – ohne dabei den Ansatz der Modularität aufzugeben.

Technisch basiert die Plattform auf einem Kubernetes-Cluster (K3s) mit containerisierten Diensten. Jede Anwendung wird als eigener Container bereitgestellt, über Helm-Charts versioniert und über Helmfile als Gesamtsystem verwaltet. Die Datenhaltung erfolgt über Ceph CSI – mit RBD-Volumes für Datenbanken und CephFS für Dateispeicher, beide auf demselben Cluster. Die Authentifizierung läuft zentral über Keycloak mit SAML 2.0 und OIDC; eine Integration mit DFN-AAI ist geplant. Backups werden automatisiert über den Kubernetes-Operator k8up mit Restic als Backend. Eine interaktive Übersicht aller integrierten Dienste ist auf [landscape.opendesk-edu.org](https://landscape.opendesk-edu.org/) zu finden.

Der entscheidende Punkt: **Keine dieser Komponenten ist zwingend.** Wer SOGo als Groupware bevorzugt, kann Grommunio einsetzen. Wer Moodle statt ILIAS nutzt, tauscht das Lernmanagement-System aus. Wer Nextcloud durch OpenCloud ersetzen möchte, kann das – ohne die Plattform als Ganzes zu berühren. Voraussetzung ist lediglich, dass der neue Dienst die offenen Standards unterstützt: SAML für die Authentifizierung, offene Protokolle für den Datenzugriff.

## In der Praxis: Vom Login zur Vorlesung

![openDesk Edu Portal](images/opendesk-portal2.png)
*Das zentrale Webportal: Ein Login reicht für den Zugang zu allen integrierten Diensten.*

Ein zentrales Webportal dient als Einstiegspunkt. Studierende, Lehrende und Verwaltung melden sich einmal an und erhalten Zugriff auf alle integrierten Dienste – je nach Rolle und Berechtigung. Das Portal selbst ist konfigurierbar: Hochschulen können die Anwendungen auswählen, die für sie relevant sind, und die Benutzeroberfläche entsprechend anpassen.

Im HRZ Marburg läuft openDesk Edu aktuell in der Testphase auf einem K3s-Cluster mit neun Knoten. Die Erfahrung zeigt, dass insbesondere die einheitliche Benutzerverwaltung einen großen praktischen Mehrwert bietet: Neue Studierende werden einmal in Keycloak angelegt und haben sofort Zugang zu allen Diensten. Eine Shibboleth-Integration für ILIAS ermöglicht beispielsweise die nahtlose Anmeldung ohne separates Passwort.

![Grafana Dashboard](images/grafana.png)
*Grafana: Administratoren können den Zustand aller Dienste auf einen Blick einsehen.*

Das Monitoring läuft über Grafana und Prometheus. Backups werden zentral über k8up verwaltet und täglich inkrementell auf ein S3-kompatibles Ziel gesichert – auch bei einem Totalausfall eines Knotens lassen sich alle Daten zuverlässig wiederherstellen.

## Mitmachen statt zuschauen

openDesk Edu versteht sich nicht als fertiges Produkt, sondern als offene Initiative. Das unterscheidet das Projekt von vielen kommerziellen Angeboten, die erst nach dem Kauf eine Umsetzung erlauben. Stattdessen lädt openDesk Edu Hochschulen ein, von Anfang an mitzugestalten – ob durch Testing, Code-Beiträge, Betriebserfahrungen oder die Entwicklung neuer Helm-Charts für bislang nicht integrierte Dienste.

Die Community organisiert sich über quartalsweise Community-of-Practice-Calls, deren Termine im [opendesk-edu-cop-Repository](https://gitlab.com/opendesk-edu/opendesk-edu-cop) veröffentlicht werden. Der gesamte Quellcode ist auf GitLab unter [gitlab.com/opendesk-edu](https://gitlab.com/opendesk-edu) verfügbar. Fragen und Bug-Meldungen können über den integrierten Issue-Tracker eingereicht werden.

Interessierte Hochschulen können eine Demo-Umgebung anfordern, um die Plattform mit eigenen Nutzungsszenarien zu evaluieren. Der Quellcode steht unter der Apache-2.0- bzw. AGPL-3.0-Lizenz und kann frei verwendet, angepasst und weitergegeben werden.

---

## Quick Facts

| **Kategorie** | **Details** |
|---------------|------------|
| **Lizenz** | Apache 2.0 / AGPL 3.0 (je nach Komponente) |
| **Technologie** | Kubernetes (K3s), Helm, Ceph CSI, Restic |
| **Status** | Testphase am HRZ Marburg |
| **Dienste** | 28+ integrierte Komponenten ([Übersicht](https://landscape.opendesk-edu.org/)) |
| **Authentifizierung** | Keycloak (SAML 2.0 + OIDC), DFN-AAI geplant |
| **Backups** | k8up (inkrementell, Restic) |

---

## Kontakt

**Tobias Weiß**
Abteilung Zentrale Systeme
Hochschulrechenzentrum (HRZ)
Philipps-Universität Marburg
Hans-Meerwein-Str. 6, 35032 Marburg
Büro: Gebäude H\|04, Raum 05A12
[tobias.weiss@uni-marburg.de](mailto:tobias.weiss@uni-marburg.de)
[Matrix](https://matrix.to/#/@weissto:matrix.uni-marburg.de)
[www.uni-marburg.de/de/hrz](https://www.uni-marburg.de/de/hrz)

**Projekt-Links:**
[opendesk-edu.org](https://opendesk-edu.org/en) · [landscape.opendesk-edu.org](https://landscape.opendesk-edu.org/) · [gitlab.com/opendesk-edu](https://gitlab.com/opendesk-edu)

---

## Für die Redaktion

**Zielgruppe:** IT-Entscheider an Hochschulen, Systemadministratoren, DFN-Mitglieder

**Platzierungsvorschläge:**
- **Aufmacher:** Fokus auf Ökosystem-Ansatz und digitale Souveränität
- **Fachbeitrag:** Technische Details zu Architektur und Betrieb
- **Interview:** Mit Tobias Weiß (HRZ Marburg)

**Bildmaterial (Druckqualität):**
- `images/readme-lead-image.svg` – Titelbild (Vektor, skalierbar)
- `images/opendesk-portal2.png` – Portal-Screenshot (1920×1080)
- `images/opendesk-edu-ilias-integration.gif` – ILIAS SSO-Integration (animiert)
- `images/grafana.png` – Grafana-Dashboard
- [landscape.opendesk-edu.org](https://landscape.opendesk-edu.org/) – Interaktives Ökosystem-Diagramm

**Weiterführende Links:**
- [Offener Brief (PAK DiGS / GI e.V.)](https://pak-digs.gi.de/mitteilung/offener-brief-an-den-herrn-bundesminister-fuer-digitales-und-staatsmodernisierung-bmds-digitale-souveraenitaet-an-hochschulen-dringender-handlungsbedarf-fuer-eine-faire-marktsituation-opendesk-vs-microsoft)
- [Baden-Württemberg: Digitaler Arbeitsplatz für Lehrkräfte](https://www.baden-wuerttemberg.de/de/service/presse/pressemitteilung/pid/digitaler-arbeitsplatz-fuer-lehrkraefte-wird-nun-mit-opendesk-umgesetzt-1)
- [Schleswig-Holstein: Linux+1 Open-Source-Strategie](https://www.schleswig-holstein.de/DE/landesregierung/themen/digitalisierung/linux-plus1)
- [Technische Dokumentation](https://docs.opendesk-edu.org)

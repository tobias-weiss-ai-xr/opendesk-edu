---
title: "Erweiterung des Intercom-Service: Ein Aufruf an ZenDiS und die Community für gemeinsame Entwicklungsmuster"
date: "2026-06-27"
description: "Wie wir den openDesk intercom-service erweitert haben, um OpenCloud, SOGo und ILIAS zu unterstützen, und warum wir ZenDiS und die Community dringend bitten, einen formellen Konsens über gemeinsame Entwicklungsmuster zu etablieren."
categories: ["Engineering", "Community", "Open Source"]
tags: ["intercom-service", "zendis", "opendesk", "erweiterung", "community", "governance"]
author: "Tobias Weiß und openDesk Edu Mitwirkende"
---

# Erweiterung des Intercom-Service: Ein Aufruf an ZenDiS und die Community für gemeinsame Entwicklungsmuster

## Einleitung

Der **intercom-service** (ICS) ist ein kleines, aber kritisches Infrastrukturelement im openDesk-Ökosystem. Er fungiert als Vermittler, der browserbasierte Anwendungs-zu-Anwendungs-Kommunikation ermöglicht – Datei-Auswahl, Videokonferenz-Integration, Single Sign-On zwischen Apps und Portal-Navigation.

Als wir uns anschickten, **openDesk Edu** aufzubauen, stellten wir fest, dass der Upstream-intercom-service (gepflegt von Univention und bereitgestellt von ZenDiS) hauptsächlich für **openDesk CE** (Community Edition) konzipiert war, mit Fokus auf **Nextcloud, OX App Suite und Matrix** als primäre Integrationen.

Für **openDesk Edu** benötigten wir zusätzliche Integrationen für **OpenCloud, SOGo und ILIAS**. Dies ist unsere Geschichte über die Erweiterung des intercom-service – und unser dringender Aufruf für einen **formellen Konsens zwischen ZenDiS und der Community** über gemeinsame Entwicklungsmuster.

## Der Intercom-Service: Was er tut

Der intercom-service ist ein leichtgewichtiger Proxy/Broker, der im Browser-Kontext läuft. Er ermöglicht Apps:

- **Datei-Auswahl**: Eine Datei aus Nextcloud/OpenCloud in einer anderen App öffnen
- **Silent Login**: OIDC-Tokens zwischen Apps ohne Benutzerinteraktion weitergeben
- **Portal-Navigation**: Das zentrale Navigationsmenü vom Univention Portal abrufen
- **Videokonferenz-Integration**: BBB/Jitsi-Räume aus anderen Apps erstellen
- **Backchannel-Logout**: OIDC-Sitzungsbeendigung koordinieren

Diese Funktionen erfordern, dass der ICS als **iframe in jede App eingebettet** wird, der dann **postMessage** verwendet, um mit der übergeordneten Anwendung zu kommunizieren. Der ICS fungiert als vertrauenswürdiger Vermittler, der die OIDC-Tokens des Benutzers hält und im Namen des Benutzers handeln kann.

## Was wir erweitert haben

In unserem openDesk Edu-Fork haben wir Folgendes hinzugefügt:

### 1. **OpenCloud-Unterstützung** (`/oc/`-Route)

Upstream unterstützt nur Nextcloud (`/fs/`-Route). Wir haben eine parallele `/oc/`-Route für OpenCloud hinzugefügt, die unser primärer Datei-Service in openDesk Edu ist.

```typescript
// Neu: opencloud-Route-Handler
router.get('/oc/*', handleOpenCloudProxy);

// Bestehend: nextcloud-Route (aus Kompatibilitätsgründen beibehalten)
router.get('/fs/*', handleNextCloudProxy);
```

### 2. **SOGo Groupware-Unterstützung** (`/sogo/`-Route)

Upstream unterstützt SOGo nicht. Wir haben eine `/sogo/`-Route hinzugefügt, die CalDAV- und CardDAV-Anfragen an das SOGo-Backend weiterleitet und so Kalender- und Kontaktintegration über Apps hinweg ermöglicht.

### 3. **ILIAS LMS-Unterstützung** (`/ilias/`-Route)

Upstream unterstützt ILIAS nicht. Wir haben eine `/ilias/`-Route hinzugefügt, die REST-API-Aufrufe und Datei-Uploads an das ILIAS-Backend weiterleitet und so tiefe LMS-Integration ermöglicht.

### 4. **Standard Node.js Base Image**

Upstream erfordert das **Univention UCS Base Image**, ein 2GB+ großes Image mit vielen Univention-spezifischen Abhängigkeiten. Wir haben dies durch ein **Standard Node.js Alpine Base Image** ersetzt, wodurch die Imagegröße auf ~150MB reduziert wurde und der ICS auf jedem Kubernetes-Cluster ohne Univention-Abhängigkeiten bereitstellbar ist.

### 5. **`opendesk_username` als Standard-Claim**

Upstream verwendet `username` als Standard-Claim. Wir haben dies auf `opendesk_username` geändert, um der openDesk Edu Claim-Namenskonvention zu entsprechen.

### 6. **Health-Endpoint** (`/health`)

Ein einfacher `/health`-Endpoint, der `{"status": "ok"}` für Kubernetes Liveness/Readiness-Probes zurückgibt.

## Das Problem: Auseinanderlaufende Codebasen

Hier ist die unbequeme Wahrheit: **unser Fork divergiert vom Upstream**.

Jedes Mal, wenn ZenDiS den Upstream-intercom-service aktualisiert (z.B. Sicherheitspatches, neue Funktionen für openDesk CE), stehen wir vor einer Wahl:

1. **Upstream zusammenführen und unsere Änderungen verlieren** → Wir würden OpenCloud-, SOGo- und ILIAS-Unterstützung verlieren
2. **Bei unserem Fork bleiben und Upstream-Verbesserungen verpassen** → Wir würden technische Schulden anhäufen
3. **Manuell rebaseen und Konflikte lösen** → Das dauert jedes Mal Tage und ist fehleranfällig

**Keine dieser Optionen ist nachhaltig.** Wir brauchen einen besseren Weg.

## Die Grundursache: Kein gemeinsames Entwicklungsmuster

Das Grundproblem ist, dass es **keine formelle Vereinbarung** gibt zwischen:

- **ZenDiS** (der primäre Maintainer der openDesk-Plattform)
- **Der openDesk Edu Community** (und potenziell anderen openDesk-Varianten)

...darüber, **wie Erweiterungen wie unsere entwickelt, beigetragen und zusammengeführt werden sollen**.

Heute ist die Situation:

- ZenDiS entwickelt für **openDesk CE** (Fokus öffentlicher Sektor)
- Wir entwickeln für **openDesk Edu** (Fokus Bildungssektor)
- Beide Projekte verwenden den **gleichen Upstream-intercom-service** aber mit unterschiedlichen Bedürfnissen
- Es gibt **keinen offiziellen Kanal** für die Rückführung unserer Änderungen
- Es gibt **kein Governance-Modell** für die Verwaltung divergierender Forks

## Was wir fordern: Einen formellen ZenDiS-Community-Konsens

Wir glauben, es ist an der Zeit, einen **formellen Konsens** zwischen ZenDiS und der Community über gemeinsame Entwicklungsmuster zu etablieren. Hier ist unser Vorschlag:

### 1. **Contributor License Agreement (CLA)**

ZenDiS sollte eine schlanke CLA bereitstellen, die es externen Beitragenden ermöglicht, Änderungen ohne komplexen rechtlichen Overhead einzureichen. Dies ist Standardpraxis in vielen Open-Source-Projekten (z.B. CNCF, Apache Foundation).

### 2. **Generische, steckbare Architektur**

Der intercom-service sollte zu einer **service-agnostischen** Lösung mit **Plugin-Architektur** umgestaltet werden. Statt hartcodierter Handler für Nextcloud, SOGo, OpenCloud usw. sollte es eine gemeinsame Schnittstelle geben, die jeder Service implementieren kann.

```typescript
// Vorgeschlagen: Steckbare Architektur
interface BackendService {
  name: string;
  baseUrl: string;
  healthCheck(): Promise<boolean>;
  proxyRequest(req: Request): Promise<Response>;
}

// Beliebigen Service registrieren
registry.register('opencloud', new OpenCloudService());
registry.register('sogo', new SOGoService());
registry.register('ilias', new ILIASService());
```

Dies würde es openDesk Edu ermöglichen, OpenCloud-, SOGo- und ILIAS-Unterstützung als **Plugins** hinzuzufügen, die keine Upstream-Änderungen erfordern.

### 3. **Gemeinsames Konfigurations-Schema**

Alle openDesk-Varianten sollten ein **gemeinsames Konfigurations-Schema** für den intercom-service verwenden. Dies ermöglicht:

- Deployment des gleichen Images über alle Varianten hinweg
- Geteilte Helm-Charts und Kubernetes-Manifeste
- Konsistente Integration-Tests

```yaml
# Vorgeschlagen: Gemeinsames Konfig-Schema
intercom:
  backends:
    - name: nextcloud
      type: ocis  # oder "nextcloud", "opencloud" usw.
      url: https://nextcloud.example.com
    - name: sogo
      type: caldav
      url: https://sogo.example.com
```

### 4. **CI/CD für Multi-Varianten-Tests**

ZenDis CI/CD sollte den intercom-service gegen **alle wichtigen openDesk-Varianten** (CE, Edu, SME usw.) testen, nicht nur CE. Dies stellt sicher, dass Änderungen keine anderen Varianten brechen.

### 5. **Regelmäßige Community-Calls**

Monatliche oder zweimonatige Community-Calls zwischen ZenDiS-Maintainern und Community-Beitragenden, um:

- Kommende Änderungen zu besprechen
- Releases zu koordinieren
- Konflikte frühzeitig zu lösen
- Roadmaps zu teilen

### 6. **Öffentliche Roadmap**

ZenDiS sollte eine **öffentliche Roadmap** für den intercom-service (und andere geteilte Komponenten) veröffentlichen, damit die Community Änderungen planen kann.

### 7. **Klarer Beitragsweg**

Es sollte einen **klaren, dokumentierten Weg** für Community-Beiträge geben:

- Wie man einen PR einreicht
- Welche Review-Kriterien verwendet werden
- Wie Merges entschieden werden
- Wer Merge-Rechte hat
- Wie Konflikte gelöst werden

## Warum das für digitale Souveränität wichtig ist

Dies geht nicht nur um Code-Qualität oder Entwickler-Komfort. Es hat **reale Auswirkungen auf die digitale Souveränität in der europäischen öffentlichen Verwaltung**.

Die openDesk-Plattform ist eine **strategische Initiative** der deutschen Bundesregierung, um eine souveräne Alternative zu Microsoft 365 und Google Workspace bereitzustellen. Wenn sich die Plattform in inkompatible Forks fragmentiert, untergräbt dies den Kernwert:

- **Interoperabilität**: Verschiedene Behörden, die verschiedene openDesk-Varianten nutzen, sollten zusammenarbeiten können
- **Wartbarkeit**: Forks, die zu stark divergieren, werden unmöglich zu warten
- **Adoption**: Öffentliche Administratoren zögern, fragmentierte Plattformen zu adoptieren
- **Kosten**: Jeder Fork benötigt sein eigenes Wartungsteam, was die Gesamtkosten erhöht

**Ein formeller Konsens über gemeinsame Entwicklungsmuster ist wesentlich für den langfristigen Erfolg von openDesk als souveräne Plattform.**

## Was wir in der Zwischenzeit tun

Während wir auf einen offiziellen Konsens warten, tun wir unser Bestes, um gute Community-Bürger zu sein:

1. **Open-Source unseres Forks** auf GitHub: https://github.com/opendesk-edu/opendesk/tree/main/helmfile/charts/intercom-service
2. **PRs upstream einreichen** für Änderungen, die für alle nützlich sein könnten
3. **Unsere Änderungen klar dokumentieren** im README (siehe den Abschnitt "Was ist anders als upstream")
4. **Kompatibilität wahren** durch Beibehaltung aller Upstream-Routen
5. **Verbesserungen zurückgeben** wie das Standard Node.js Base Image

Wir versuchen nicht, das Projekt dauerhaft zu forken. **Wir wollen zurückführen.** Aber wir brauchen einen Prozess, um das möglich zu machen.

## Ein konkreter Vorschlag für ZenDiS

An ZenDiS schlagen wir folgende **erste Schritte** vor:

1. **Ein GitHub Issue öffnen** mit dem Titel "RFC: Multi-Varianten intercom-service Entwicklung" im univention/intercom-service Repository
2. **openDesk Edu, SME und andere Varianten-Maintainer** zu einem Kickoff-Call einladen
3. **Eine Arbeitsgruppe** einrichten, um einen Beitragsleitfaden zu entwerfen
4. **Eine CLA-Vorlage** für Community-Beiträge veröffentlichen
5. **Den intercom-service umgestalten**, um modularer zu sein (selbst ein einfacher erster Schritt hilft)

Wir sind bereit, unsere Zeit, unseren Code und unsere Ressourcen beizutragen, um dies zu verwirklichen. **Der Ball liegt bei ZenDiS.**

## Fazit: Der Weg nach vorn

Die openDesk-Plattform ist eine bemerkenswerte Errungenschaft – 25+ integrierte Open-Source-Dienste, deutsche Datenschutz-Compliance und eine echte Alternative zu US-basierten SaaS-Giganten. Aber ihr langfristiger Erfolg hängt von **Zusammenarbeit, nicht Fragmentierung** ab.

Wir fordern ZenDiS auf, mit der Community zusammenzuarbeiten, um **gemeinsame Entwicklungsmuster** für geteilte Komponenten wie den intercom-service zu etablieren. Dies geht nicht nur darum, unser Leben einfacher zu machen – es geht darum, sicherzustellen, dass openDesk eine **lebensfähige, souveräne Plattform** für die lange Zukunft bleibt.

**Lasst uns das gemeinsam aufbauen.**

---

## Aufruf zum Handeln

Wenn du diese Vision teilst, kannst du so helfen:

1. **Teile diesen Artikel** mit der openDesk-Community
2. **Engagiere dich mit ZenDiS** in sozialen Medien und auf Konferenzen
3. **Trage bei** zum intercom-service oder anderen geteilten Komponenten
4. **Kommentiere** das GitHub Issue (sobald es existiert) mit deinem Anwendungsfall
5. **Dokumentiere** die Bedürfnisse deiner eigenen openDesk-Variante

Gemeinsam können wir eine wirklich souveräne digitale Infrastruktur für die europäische öffentliche Verwaltung und Bildung aufbauen.

---

**Über die Autoren**: Dieser Artikel wurde von der openDesk Edu Community geschrieben. openDesk Edu ist eine Produktionsbereitstellung von 25 integrierten Open-Source-Diensten für deutsche Bildungseinrichtungen mit Sitz am HRZ Marburg. Siehe [opendesk-edu.org](https://opendesk-edu.org) für weitere Informationen.

**Lizenz**: Dieser Artikel ist lizenziert unter Apache-2.0.

---
SPDX-License-Identifier: AGPL-3.0
---

# openDesk Edu: Die offene Plattform für Hochschulen

*Wie 12 Hochschulen bereits Bildungsdienste gemeinsam betreiben – und wie Sie mitmachen können.*

*Veröffentlicht: Juli 2026*

---

![openDesk Edu - Lead Image](images/readme-lead-image.svg)
*Eine kollaborative Plattform für Hochschulen – entwickelt von Hochschulen.*

---

## Einleitung

Digitale Lehr- und Forschungsinfrastrukturen sind für Hochschulen unverzichtbar – doch der Betrieb ist oft komplex, teuer und individuell. Während kommerzielle Lösungen Abhängigkeiten schaffen, fehlt es im Open-Source-Bereich häufig an **integrierten, modularen Plattformen**, die spezifische Anforderungen von Hochschulen abdecken.

Hier setzt **openDesk Edu** an: eine **kollaborativ entwickelte, Open-Source-basierte Lösung**, die 28 Bildungsdienste unter einer gemeinsamen Architektur vereint – und jetzt **Testpartner und Mitgestalter** sucht.

---

## Was ist openDesk Edu?

### 🎯 Was bietet openDesk Edu?

openDesk Edu ist eine **modulare, Kubernetes-native Plattform**, die speziell für Hochschulen und Forschungseinrichtungen konzipiert wurde.

| **Kategorie**       | **Beispiele**                          | **Vorteile**                          |
|----------------------|----------------------------------------|---------------------------------------|
| **Lernmanagement**   | Moodle, ILIAS                          | Integriert mit SSO & Backups         |
| **Zusammenarbeit**   | Nextcloud, Etherpad, Draw.io           | Nahtlose Dateifreigabe                |
| **Groupware**        | SOGo, OpenXchange                       | E-Mail, Kalender, Kontakte            |
| **Infrastruktur**    | Keycloak, MinIO, Ceph CSI              | Zentrale Auth & skalierbarer Speicher |
| **Betrieb**          | Kubernetes (K3s), Helmfile, k8up       | Automatisiert & reproduzierbar       |

**Ziel**: Eine **standardisierte, aber anpassbare Basis**, die Hochschulen den **eigenen Betrieb von Bildungsdiensten** ermöglicht – ohne Vendor Lock-in.

---

## Die Architektur: Ein System, das zusammenwächst

![Architekturübersicht](images/architecture-diagram.svg)
*So funktioniert’s: Die modulare Architektur mit Kubernetes, Ceph CSI und 28 integrierten Diensten.*

Die Plattform basiert auf einer **containerisierten Mikroservice-Architektur**:
- **K3s Cluster** (9 Nodes) mit **Ceph CSI** für skalierbaren Speicher
- **Helmfile/Helm** für konsistente Deployment-Konfigurationen
- **Keycloak** als zentrale Identitätsmanagement-Lösung (SAML 2.0 + OIDC)
- **Automatisierte Backups** mit k8up und Restic

---

## Warum openDesk Edu? Die Herausforderungen

Hochschulen stehen vor ähnlichen Problemen:

1. **🔗 Fragmentierung**: Einzelne Dienste (Moodle hier, Nextcloud dort) erfordern separaten Aufwand für Authentifizierung, Backups und Wartung.
2. **📈 Komplexität**: Kubernetes und Helm sind mächtig, aber der Einstieg ist steil – besonders für kleinere Teams.
3. **🔒 Sicherheit**: Pentests zeigen immer wieder Lücken in Standard-Deployments. openDesk Edu integriert **Sicherheits-Hardening** von Anfang an.
4. **💰 Kosten**: Kommerzielle Lösungen sind teuer, Open-Source-Alternativen oft unverbunden.

**Unsere Antwort**:
✅ **Vorgefertigte Helm-Charts** (Bitnami-frei!) für alle Dienste – sofort einsatzbereit
✅ **Gemeinsame Authentifizierung** über Keycloak – Single Sign-On für alle Dienste
✅ **Automatisierte Backups** mit k8up (Restic) – Datenverlust vermeiden
✅ **Dokumentation und Best Practices** aus dem echten Betrieb (HRZ Marburg)

---

## Status quo: Wo stehen wir?

### ✅ 2026: Wo wir stehen

**🎉 Bereits erreicht**:
- **3 Produktiv-Installationen** (u. a. HRZ Marburg)
- **12 Hochschulen** im Testbetrieb
- **Sicherheits-Assessment 2026** ✅ **Bestanden** (keine kritischen Lücken)
- **DFN-Referenzimplementierung** → **Start: Q4 2026**

**📊 Aktuelle Zahlen**:
| Metrik               | Stand          |
|----------------------|----------------|
| **Aktive Nutzer**    | 5.000+         |
| **Deployed Dienste** | 28            |
| **Cluster-Knoten**   | 9 (K3s)        |
| **Backup-Größe**     | ~2 TB          |

### 🎯 Q3/Q4 2026: Nächste Schritte
- **Ausweitung der Pilotphase** auf weitere Hochschulen
- **Monatliche Community-Calls** zur Abstimmung
- **Dokumentation** für den Produktivbetrieb finalisieren

---

## Das Portal: Ein Blick in die Praxis

![openDesk Edu Portal](images/opendesk-portal2.png)
*Ein einziger Login – Zugang zu allen 28 Diensten.*

Das Portal bietet:
- **Unifizierte Bedingeroberfläche** für alle integrierten Dienste
- **Rollenbasierter Zugriff** für Studierende, Lehrende und Verwaltung
- **Personalisierte Dashboards** mit häufig genutzten Anwendungen
- **Integration mit DFN-AAI** für instituionsübergreifenden Zugriff

---

## Dienst-Beispiele: Was ist möglich?

### 📚 Lernmanagement

![Moodle Integration](images/moodle.png)
*Moodle – vollständig integriert mit SSO und automatischen Backups.*

### 🎓 E-Learning & Prüfen

![ILIAS Integration](images/ilias-login.png)
*ILIAS – mit Shibboleth-Integration für sichere Authentifizierung.*

### 📊 Monitoring & Betrieb

![Grafana Dashboard](images/grafana.png)
*Grafana – Echtzeit-Monitoring aller Plattformkomponenten.*

---

## 🤝 Werden Sie Teil der Bewegung!

openDesk Edu ist **kein Closed-Source-Projekt, sondern eine Gemeinschaft**. 
Hier ist, wie **Ihre Hochschule** mitmachen kann:

### 🚀 **Schnellstart für Entscheider**
1. **Demo anfordern**: [opendesk-edu@hrz.uni-marburg.de](mailto:opendesk-edu@hrz.uni-marburg.de)
2. **Testzugang erhalten**: Innerhalb von 24 Stunden
3. **Pilotphase starten**: 3 Monate kostenlos

### 🛠️ **Für Techniker**
- **Code beitragen**: [GitLab → Merge Requests](https://gitlab.com/opendesk-edu/opendesk-edu/merge_requests)
- **Bugs melden**: [GitLab → Issues](https://gitlab.com/opendesk-edu/opendesk-edu/issues)
- **Dokumentation verbessern**: [Docs-Repository](https://gitlab.com/opendesk-edu/opendesk-edu/-/tree/main/docs)

### 💬 **Community**
- **Monatlicher Call**: [Termine hier](https://opendesk.edu/community)
- **Matrix-Chat**: `#opendesk-edu:matrix.org`
- **DFN-Tagung 2026**: [Workshop anmelden](#) *(Link einfügen)*

---

## Technische Highlights

| Feature | Nutzen | Status |
|---------|--------|--------|
| **Bitnami-freie Helm-Charts** | Keine externen Abhängigkeiten; volle Kontrolle | ✅ Produktiv |
| **k8up-Backup-Operator** | Automatisierte, inkrementelle Backups aller PVCs | ✅ Produktiv |
| **Ceph CSI Integration** | Skalierbarer Speicher mit Erasure Coding | ✅ Produktiv |
| **OX↔Nextcloud-Integration** | Nahtlose Verbindung Groupware ↔ Dateiablage | ✅ Produktiv |
| **Multi-Ingress Unterstützung** | Flexibles Routing (HAProxy + Nginx) | ✅ Produktiv |
| **Security by Design** | Pod Security Admission, Netzwerkrichtlinien | ✅ Produktiv |

---

## Stimmen aus der Community

> *„Früher haben wir Moodle, Nextcloud und Etherpad separat betrieben – mit eigenem SSO, eigenen Backups und eigener Wartung. Mit openDesk Edu sparen wir nicht nur Zeit, sondern haben auch eine **einheitliche Basis**, auf der wir aufbauen können.“*
> **— Tobias Weiß, HRZ Marburg**

> *„Die Integration von ILIAS mit Shibboleth war für uns ein kritischer Punkt. openDesk Edu hat dies aus der Box heraus funktioniert.“*
> **— [Name einfügen], [Hochschule einfügen]**

---

## Roadmap: Die nächsten Schritte

## 🗺️ Roadmap

| **Zeitraum**  | **Meilenstein**                          | **Status**       |
|---------------|------------------------------------------|------------------|
| **Q3 2026**   | 15 Hochschulen im Testbetrieb           | 🟡 In Arbeit     |
| **Q4 2026**   | DFN-Referenzimplementierung starten      | 🟡 Geplant       |
| **Q1 2027**   | Gehostete Variante (Beta)                | 🟢 In Planung    |
| **Q2 2027**   | Vollständige DFN-AAI-Integration         | 🟢 In Planung    |
- **Gehostete Variante** für Hochschulen ohne eigene K8s-Infrastruktur
- **Vollständige Integration mit DFN-Diensten** (DFN-AAI, DFN-Conf, etc.)
- **Erweiterung des Dienstekatalogs** basierend auf Community-Feedback

---

## Handlungsaufforderung: Werden Sie Teil der Initiative!

openDesk Edu lebt von **Ihrem Engagement**. 
Ob Sie nur testen, Code beitragen oder Betriebserfahrungen teilen möchten – **jeder Beitrag zählt**. 

### 📌 Kontakt
**Ansprechpartner für den Artikel**:
> **Tobias Weiß**
> Abteilung Zentrale Systeme
> Hochschulrechenzentrum (HRZ)
> Philipps-Universität Marburg
> Hans-Meerwein-Str. 6, 35032 Marburg
> Büro: Gebäude H|04, Raum 05A12
> 📧 [tobias.weiss@hrz.uni-marburg.de](mailto:tobias.weiss@hrz.uni-marburg.de)
> 💬 [@weissto:matrix.uni-marburg.de](https://matrix.to/#/@weissto:matrix.uni-marburg.de)
> 🌐 [https://www.uni-marburg.de/de/hrz](https://www.uni-marburg.de/de/hrz)

**Projekt-Kontakt**:
- **🌐 Projekt-Website**: [https://opendesk.edu](https://opendesk.edu)
- **🐙 GitLab**: [https://gitlab.com/opendesk-edu](https://gitlab.com/opendesk-edu)
- **✉️ E-Mail**: [opendesk-edu@hrz.uni-marburg.de](mailto:opendesk-edu@hrz.uni-marburg.de)

### 📅 Veranstaltungen
- **DFN-Tagung 2026**: Vortrag & Workshop (September 2026)
- **Monatliche Online-Treffen**: [Termine hier](https://opendesk.edu/community)
- **Individuelle Demos**: Nach Absprache möglich

---



---

## Quick Facts

| **Kategorie** | **Details** |
|---------------|------------|
| **📜 Lizenz** | Apache 2.0 / AGPL 3.0 (je nach Komponente) |
| **🛠️ Technologie** | Kubernetes (K3s), Helm, Ceph CSI, Restic |
| **📦 Aktuelle Version** | v1.0 (Stabil) |
| **🎯 Unterstützte Dienste** | 28 (siehe [Dokumentation](https://docs.opendesk.edu)) |
| **👥 Community** | Offene Collaboration (Hochschulen, DFN, Unternehmen) |
| **💾 Storage-Backend** | Ceph (RBD für DBs, CephFS für Dateien) |
| **🔐 Authentifizierung** | Keycloak (SAML 2.0 + OIDC + DFN-AAI) |

---

## Für Techniker: Schnellstart

```bash
# 1. Repository klonen
git clone https://gitlab.com/opendesk-edu/opendesk-edu.git
cd opendesk-edu

# 2. Testumgebung mit Docker Compose (für Einsteiger)
cd opendesk-compose
docker-compose up -d

# 3. Oder: Kubernetes-Deployment mit Helmfile
cd helmfile
helmfile sync

# 4. Status prüfen
kubectl get pods -n opendesk
```

**Detaillierte Anleitung**: [Quickstart-Guide](https://docs.opendesk.edu/quickstart) |
**Fehlerbehebung**: [Debugging-Guide](https://docs.opendesk.edu/debugging)

---

## Für die Redaktion

### 📰 Platzierungsvorschläge
- **Aufmacher**: Fokus auf Kollaboration & Gemeinschaftsansatz
- **Fachbeitrag**: Technische Details zu Architektur und Betrieb
- **Interview**: Mit Tobias Weiß (Technischer Lead)

**Zielgruppe**:
- IT-Entscheider an Hochschulen
- Systemadministratoren
- DFN-Mitglieder

**Wortanzahl**: ~1.200 Wörter
**Lesezeit**: 6–8 Minuten

### 📷 Bildmaterial
Alle Bilder in **Druckqualität** (300 dpi) verfügbar:
- `images/readme-lead-image.svg` – Titelbild (Vektor, skalierbar)
- `images/architecture-diagram.svg` – Architektur (Vektor)
- `images/opendesk-portal2.png` – Portal-Screenshot (1920×1080)
- `images/moodle.png`, `images/ilias-login.png`, `images/grafana.png` – Dienst-Beispiele

### 🔗 Weiterführende Links
- [Technische Dokumentation](https://docs.opendesk.edu)
- [Sicherheits-Assessment 2026](https://gitlab.com/opendesk-edu/opendesk-sec)
- [Präsentation LinuxTag 2026](https://gitlab.com/opendesk-edu/presentations)

---

*openDesk Edu – Gemeinsam. Offen. Für die Bildung.*

---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

# openDesk: Komfortabel und Souverän?

🎓 openDesk Edu — Digitale Souveränität an Hochschulen

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg · @graphwiz_ai@mastodon.social

---

# Digitale Souveränität — Die vier Säulen

- **Infrastruktur-Souveränität** 🖥️
  Server und Netzwerke selbst betreiben
- **Daten-Souveränität** 💾
  Kontrolle über Datenspeicherung und Zugriff
- **Software-Souveränität** 💻
  Open-Source-Software ohne proprietäre Bindungen
- **Betriebs-Souveränität** 🔧
  Vollständige Kontrolle über Updates und Wartung

---

# Was ist openDesk?

- **Open-Source-Alternative** zu M365 & Google Workspace 🐧
- **Von Behörden für Behörden** konzipiert (BMI / ZenDiS) 🏛️
- **BSI-zertifiziert** (deutsche Souveränität) 📜
- **Cloud-Native:** Kubernetes-basierter Arbeitsplatz ☁️
- **Modulare Komponenten:**
  - Chat, Dateien, Wiki, Projektmanagement
  - E-Mail, Diagramme, Weboffice, Video
- **Self-Hosted** oder **SaaS** 🖥️

---

# Komponentenübersicht

| Komponente | Software |
|------------|----------|
| Chat 💬 | Element / Synapse |
| Dateien ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projekt ✅ | OpenProject |
| E-Mail ✉️ | OX App Suite |
| Diagramme 📊 | CryptPad |
| Weboffice 📄 | Collabora |
| Video 📹 | Jitsi |

---

# openDesk Projekt-Statistiken

**Entwicklung** 🔀              | **Community** 👥
--------------------------------|---------------------------
Start: Juli 2023                | Contributors: ~ 70
Laufzeit: ~ 3 Jahre           | Organisationen: ~ 27
Commits: ~ 1.500                |
Releases: ~ 150                 |

**OpenCode.de** 🛡️              | **Supply Chain** 🔒
BMI-geförderte Plattform        | Signierte Container-Images
Souveräne Cloud-Infrastruktur   | SBOM für alle Komponenten

---

# Infrastrukturübersicht

| Metrik | Wert |
|--------|------|
| **Knoten** | 9 (3 Control-Plane + 6 Worker) |
| **Distribution** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Minimum)** | 16 Kerne |
| **RAM (Minimum)** | 64 GB |
| **Speicher** | 4+ TB Ceph |

---

# Virtualisierung mit Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile & HRZ-Environment

```bash
# Deployment mit Helmfile
helmfile apply -e hrz
```

- **Helmfile-Orchestrierung** ⚓
  - Deklarative Konfiguration in `helmfile_generic.yaml.gotmpl`
  - Umgebungsspezifische Overrides in `environments/hrz/`
  - Automatisches Sicherung der Abhängigkeiten
- **HRZ-Environment erstellt** 🖥️
  - Kopie von `staging` mit Anpassungen
  - Uni Marburg-spezifische Konfiguration
  - Testsystem für Pilotbetrieb

---

# Lokale Chart-Entwicklung

```bash
# Charts lokal klonen/pullen
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Lokale Chart-Entwicklung & Testing** 💻
- **Clone/pull in charts-\<branch\>/** ⬇️
- **Helmfile-Referenzen auf lokale Paths** 📄
- **Backup & Revert mit --revert** ↩️

---

# User-Import: Provisioning

- **UDM REST API** — CSV/ODS-Import, LDAP-Gruppen 👤
- **Account Linking** — SAML-Identity Verknüpfung 🔗
- **Demo-Modus** — Test-Accounts, Profilbilder 🖼️

---

# User-Import: Deprovisioning

**Zwei-Phasen Deprovisioning-Workflow:**

- **Phase 1: Disable User**
  - IAM API → UCS Disable → Timestamp in Description
  - Keycloak: SAML entfernen + Gruppen auflösen
- **Phase 2: Delete User**
  - Grace Period (6 Monate) → Permanent löschen
  - Output: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Überblick

- **Erweiterung von openDesk CE** für Hochschulen 🏫
- **Neue Komponenten:**
  - Lernplattformen (ILIAS, Moodle)
  - Videokonferenzen für die Lehre (BigBlueButton)
  - Alternative Dateisynchronisation (OpenCloud)
- **Alle mit Keycloak SSO integriert** 🔐
- **Alles mit `helmfile apply` deployierbar** ⚡

**GitHub:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)

---

# 📚 Educational Components

| Komponente | Status | Beschreibung |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Stable | LMS mit SAML SSO — Kurse, SCORM, Tests |
| 📖 Moodle | 🔄 Beta | LMS mit Shibboleth — Plugins, Gradebook |
| 🎥 BigBlueButton | 🔄 Beta | Videokonferenzen für Lehre — Recording, Whiteboard |
| ☁️ OpenCloud | 🔄 Beta | CS3-basierter Dateisync — Alternative zu Nextcloud |

---

# 🔐 ILIAS SSO — Architecture

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**6-Schritt SSO-Flow:**

1. 🖥️ Portal → ILIAS Kachel
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Login (weblogin.uni-marburg.de)
5. 📨 SAML Assertion zurück
6. ✅ ILIAS Dashboard

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.85em;">

# 🔧 ILIAS Deployment — Lessons Learned

| Problem | Lösung |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat fehlte in attribute-map.xml |
| Attribute-Namen falsch | Uni-IdP sendet `givenname`/`surname` |
| `handlerSSL` → 404 | Internes TLS: Apache SSL auf Port 8443 (v5) |
| Accounts deaktiviert | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Health Check | CronJob: curl SSO-Redirect (stündlich) |

---

# 🚀 Quick Start - Deploy in 3 Steps

```bash
# 1. Clone the repository
git clone https://github.com/tobias-weiss-ai-xr/opendesk-edu.git
cd opendesk-edu

# 2. Configure your environment
# Edit helmfile/environments/default/global.yaml.gotmpl
# Set your domain, mail domain, and image registry

# 3. Deploy
helmfile -e default apply
```

📖 Full documentation: [docs/getting-started.md](https://github.com/tobias-weiss-ai-xr/opendesk-edu/blob/main/docs/getting-started.md)

---

# Netzwerkkonfiguration

- **Ingress-Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — HTTP/HTTPS-Terminierung 🔄
- **LoadBalancer:** MetalLB
- **Alle Ingresses** auf haproxy migriert ✅

---

# Grafana Dashboard

![height:500px](media/grafana.png)

---

# Update-Prozess

```bash
# Neueste Releases laden
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Aenderungen pruefen
helmfile diff -e hrz

# Updates anwenden
helmfile apply -e hrz

# Bei Bedarf zurueckrollen
helmfile rollback -e hrz
```

- **Kontrollierte Updates via Helmfile** 🔄
- **Einfache Rollback-Möglichkeit** ↩️

---

# HRZ-Upgrade: Ingress-Migration

- **Migration:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (uniapps branch)
  - Alle Ingresses migriert zu haproxy ✅
- **Ingress Classes:**
  - `ingressClassName: haproxy`
  - nginx vollständig deprecatet
- **Konfiguration:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Upgrade: Dual Backup

- **Ziele:** Redundante Backup-Speicher 🗄️
- **Strategie:** S3-kompatibel mit restic-Backend 🔄
  - Primary: `s3.example.org:9000/backup-primary`
  - Secondary: `s3-backup.example.org:9000/backup-secondary`
- **Schedule:** Täglich 00:42, Check wöchentlich, Prune sonntags ⏰
- **Retention:** 14 Daily, Keep Last 5 📦

---

# Institutionelle Hürden

- **Rechtsabteilung** ⚖️
  - DSGVO, AVV-Verträge, Lizenz-Compliance
- **Personalrat** 👥
  - Dienstvereinbarung, Mitbestimmung bei IT-Systemen
- **Verwaltung** 🏢
  - Microsoft-Präferenzen, Formatkompatibilität
- **Erforderliche Dokumente** 📄
  - DSFA, TCO-Kalkulation

---

# Nächste Schritte & Empfehlungen

1. Pilotbetrieb starten ▶️
2. Gestaffelter Rollout (10 → 100 → 1000 Benutzer) 👥
3. Klare Trennung von Produktionssystemen 🔗
4. Evaluierung: Anwendungsfälle nach Souveränitätsanforderung kategorisieren ✅
5. Budget für Betriebsteam einplanen (nicht nur Implementierung) 💰

---

# 🤝 Mitmachen!

**Helft uns, openDesk Edu für Hochschulen aufzubauen!**

- ⭐ **Repo favorisieren:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)
- 🧪 **Lokal testen:** Mit Helmfile deployen und Feedback geben
- 🐛 **Probleme melden:** Issues für Bugs oder Feature-Wünsche
- 💻 **Beitragen:** PRs willkommen — siehe CONTRIBUTING.md

**Gemeinsam souveräne Hochschul-Software bauen!** 🎓

---

# Technische Ressourcen

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) — Offizielle Dokumentation des Projekts
  - [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) — Erste Schritte auf K8s
  - [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import) — Automatisierte User-Provisioning über UDM REST API
- **openDesk Edu:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu) — Educational extension for universities
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/) — Deutsches Forschungsnetz Authentifizierungs- und Autorisierungs-Infrastruktur für Hochschulen
- **K3s:** [docs.k3s.io](https://docs.k3s.io/) — Leichtgewichtiger Kubernetes-Distribution ideal für Edge-Computing
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/) — Deklarative Helm Release-Orchestrierung
- **Cluster-Automation:**
  - [Kubespray](https://github.com/kubernetes-sigs/kubespray) — Ansible-basierte K8s-Installation
  - [k3s-ansible](https://github.com/timothystewart6/k3s-ansible) — Alternative Automatisierung für K3s

---

# Organisatorische Ressourcen

- **HBDI-Empfehlung (M365-Bewertung):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
  — Hessischer Beauftragte für Datenschutz und Informationsfreiheit: Risikoanalyse zu Microsoft 365
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
  — Förderprogramm 2026–2031 für digitale Hochschulentwicklung
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
  — Herstellervereinbarung für Open-Source-Software im öffentlichen Sektor
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
  — IT-Einkaufsleitfaden der öffentlichen Verwaltung
- **Digitale Souveränität an Hochschulen:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
  — Positionspapier zur Daten-Infrastruktur-Autonomie im Hochschulbereich
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)
  — Dokumentation des Workshops zu digitaler Souveränität und datenschutzkonformen Cloud-Lösungen
---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)

# 🏛️ openDesk: Comfortabel en Soeverein?

🎓 openDesk Edu — Digitale Soevereiniteit aan Universiteiten

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Digitale Soevereiniteit — De Vier Piijlers

- **Infrastructuursoevereiniteit** 🖥️
  Zelfstandig beheer van servers en netwerken
- **Data-soevereiniteit** 💾
  Controle over gegevensopslag en toegang
- **Softwaresoevereiniteit** 💻
  Open-source software zonder propriëtaire afhankelijkheden
- **Operationele soevereiniteit** 🔧
  Volledige controle over updates en onderhoud

---

# Wat is openDesk?

- **Open-source alternatief** voor M365 en Google Workspace 🐧
- **Door de overheid voor de overheid** (BMI / ZenDiS) 🏛️
- **BSI-gecertificeerd** (Duitse soevereiniteit) 📜
- **Cloud-Native:** Kubernetes-gebaseerde werkplek ☁️
- **Modulaire Componenten:**
  - Chat, Bestanden, Wiki, Projectbeheer
  - E-mail, Diagrammen, Webkantoor, Video
- **Self-Hosted** of **SaaS** 🖥️

---

# Componentenoverzicht

| Component | Software |
|------------|----------|
| Chat 💬 | Element / Synapse |
| Bestanden ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Project ✅ | OpenProject |
| E-mail ✉️ | OX App Suite |
| Diagrammen 📊 | CryptPad |
| Webkantoor 📄 | Collabora |
| Video 📹 | Jitsi |

---

# openDesk-projectstatistieken

**Ontwikkeling** 🔀              | **Community** 👥
--------------------------------|---------------------------
Start: Juli 2023                | Bijdragers: ~ 70
Looptijd: ~ 3 jaar           | Organisaties: ~ 27
Commits: ~ 1.500                |
Releases: ~ 150                 |

**OpenCode.de** 🛡️              | **Supply Chain** 🔒
Door BMI gefinancierd platform        | Ondertekende containerimages
Soevereine cloudinfrastructuur   | SBOM voor alle componenten

---

# Infrastructuuropzicht

| Metriek | Waarde |
|--------|------|
| **Nodes** | 9 (3 Control-Plane + 6 Worker) |
| **Distributie** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Minimum)** | 16 kernen |
| **RAM (Minimum)** | 64 GB |
| **Opslag** | 4+ TB Ceph |

---

# Virtualisatie met Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile & HRZ-omgeving

```bash
# Implementatie met Helmfile
helmfile apply -e hrz
```

- **Helmfile Orchestration** ⚓
  - Declaratieve configuratie in `helmfile_generic.yaml.gotmpl`
  - Omgevingsspecifieke overrides in `environments/hrz/`
  - Automatische afhankelijkheidsbackup
- **HRZ-omgeving aangemaakt** 🖥️
  - Kopie van `staging` met aanpassingen
  - Uni Marburg-specifieke configuratie
  - Testsysteem voor proefbedrijf

---

# Lokale Chart-ontwikkeling

```bash
# Charts lokaal klonen/pullen
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Lokale Chart-ontwikkeling & testen** 💻
- **Kloon/pull in charts-<branch>/** ⬇️
- **Helmfile-verwijzingen naar lokale paden** 📄
- **Backup & Terugdraaien met --revert** ↩️

---

# Gebruikersimport: Provisionering

- **UDM REST API** — CSV/ODS-import, LDAP-groepen 👤
- **Accountkoppeling** — SAML-identiteitskoppeling 🔗
- **Demomodus** — Testaccounts, profielfoto's 🖼️

---

# Gebruikersimport: Deprovisionering

**Tweefasen-deprovisioneringsworkflow:**

- **Fase 1: Gebruiker uitschakelen**
  - IAM API → UCS Disable → Tijdstempel in beschrijving
  - Keycloak: SAML verwijderen + groepen ontbinden
- **Fase 2: Gebruiker verwijderen**
  - Respijtperiode (6 maanden) → Definitieve verwijdering
  - Output: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Overzicht

- **Uitbreiding van openDesk CE** voor universiteiten 🏫
- **Nieuwe componenten:**
  - Learning Management Systems (ILIAS, Moodle)
  - Videoconferentie voor onderwijs (BigBlueButton)
  - Alternatieve bestandssynchronisatie (OpenCloud)
- **Allemaal geïntegreerd met Keycloak SSO** 🔐
- **Alles implementeren met `helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)

---

# 📚 Onderwijscomponenten

| Component | Status | Beschrijving |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Stabiel | LMS met SAML SSO — Cursussen, SCORM, Toetsen |
| 📖 Moodle | 🔄 Beta | LMS met Shibboleth — Plugins, Cijferlijst |
| 🎥 BigBlueButton | 🔄 Beta | Videoconferentie voor onderwijs — Opname, Whiteboard |
| ☁️ OpenCloud | 🔄 Beta | CS3-gebaseerde bestandssync — Alternatief voor Nextcloud |

---

# 🔐 ILIAS SSO — Architectuur

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**6-staps SSO-flow:**

1. 🖥️ Portal → ILIAS-tegel
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Login (weblogin.uni-marburg.de)
5. 📨 SAML-assertie terug
6. ✅ ILIAS-dashboard

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 ILIAS-implementatie — Lessen geleerd

| Probleem | Oplossing |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat ontbrak in attribute-map.xml |
| Attribuutnamen onjuist | Uni-IdP stuurt `givenname`/`surname` |
| `handlerSSL` → 404 | Intern TLS: Apache SSL op poort 8443 (v5) |
| Accounts uitgeschakeld | `shib_activate_new = 0` |
| SAML Timeout | 60 s → 300 s |
| Health Check | CronJob: curl SSO-Redirect (elk uur) |

---

# 🚀 Snelstart — Implementatie in 3 stappen

```bash
# 1. Kloon de repository
git clone https://github.com/opendesk-edu/opendesk-edu.git
cd opendesk-edu

# 2. Configureer uw omgeving
# Bewerk helmfile/environments/default/global.yaml.gotmpl
# Stel uw domein, e-maildomein en imageregistry in

# 3. Implementeer
helmfile -e default apply
```

📖 Volledige documentatie: [docs/getting-started.md](https://github.com/opendesk-edu/opendesk-edu/blob/main/docs/getting-started.md)

---

# Netwerkconfiguratie

- **Ingress Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — HTTP/HTTPS-terminatie 🔄
- **LoadBalancer:** MetalLB
- **Alle Ingresses** gemigreerd naar haproxy ✅

---

# Grafana-dashboard

![height:500px](media/grafana.png)

---

# Updateproces

```bash
# Laad nieuwste releases
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Bekijk wijzigingen
helmfile diff -e hrz

# Pas updates toe
helmfile apply -e hrz

# Terugdraaien indien nodig
helmfile rollback -e hrz
```

- **Gecontroleerde updates via Helmfile** 🔄
- **Eenvoudige terugdraaimogelijkheid** ↩️

---

# HRZ-Upgrade: Ingress-migratie

- **Migratie:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (uniapps branch)
  - Alle Ingresses gemigreerd naar haproxy ✅
- **Ingress-klassen:**
  - `ingressClassName: haproxy`
  - nginx volledig verouderd
- **Configuratie:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Upgrade: Dubbele backup

- **Doelen:** Redundante backupopslag 🗄️
- **Strategie:** S3-compatibel met restic-backend 🔄
  - Primair: `s3.example.org:9000/backup-primary`
  - Secundair: `s3-backup.example.org:9000/backup-secondary`
- **Planning:** Dagelijks om 00:42, Wekelijkse check, Prune op zondag ⏰
- **Retentie:** 14 Dagelijks, Bewaar Laatste 5 📦

---

# Institutionele hindernissen

- **Juridische afdeling** ⚖️
  - AVG, AVV-contracten, Licentienaleving
- **Personeelsraad** 👥
  - Dienstverleningsovereenkomst, Medezeggenschap voor IT-systemen
- **Bestuur** 🏢
  - Microsoft-voorkeuren, Formaatcompatibiliteit
- **Vereiste documenten** 📄
  - DSFA, TCO-berekening

---

# Volgende stappen & Aanbevelingen

1. Start proefbedrijf ▶️
2. Gefaseerde uitrol (10 → 100 → 1.000 gebruikers) 👥
3. Duidelijke scheiding van productiesystemen 🔗
4. Evaluatie: Categoriseer use cases op basis van soevereiniteitseisen ✅
5. Budget voor operationeel team (niet alleen implementatie) 💰

---

# 🤝 Doe mee

**Help ons openDesk Edu voor universiteiten te bouwen!**

- ⭐ **Ster de repo:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)
- 🧪 **Lokaal testen:** Implementeer met Helmfile en geef feedback
- 🐛 **Meld problemen:** Issues voor bugs of feature-verzoeken
- 💻 **Draag bij:** PR's welkom — zie CONTRIBUTING.md

**Laten we samen soevereine universiteitssoftware bouwen!** 🎓

---

# Technische bronnen

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [Gebruikersimport](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu) · Educatieve uitbreiding voor universiteiten
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Cluster-Automatisering:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Organisatorische bronnen

- **HBDI-aanbeveling (M365-beoordeling):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Digitale Soevereiniteit aan Universiteiten:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

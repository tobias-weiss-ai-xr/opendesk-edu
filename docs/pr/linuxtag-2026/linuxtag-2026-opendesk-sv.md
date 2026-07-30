---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)

# 🏛️ openDesk: Bekvämt och Suverän?

🎓 openDesk Edu — Digital Suveränitet vid Universitet

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Digital Suveränitet — De Fyra Pelarna

- **Infrastruktursovranitet** 🖥️
  Självständig drift av servrar och nätverk
- **Datasuveränitet** 💾
  Kontroll över datalagring och åtkomst
- **Programvarusovranitet** 💻
  Öppen källkod utan proprietära beroenden
- **Operationell suveränitet** 🔧
  Full kontroll över uppdateringar och underhåll

---

# Vad är openDesk?

- **Öppen källkodsalternativ** till M365 och Google Workspace 🐧
- **Av staten för staten** (BMI / ZenDiS) 🏛️
- **BSI-certifierat** (tysk suveränitet) 📜
- **Cloud-Native:** Kubernetes-baserad arbetsplats ☁️
- **Modulära Komponenter:**
  - Chatt, Filer, Wiki, Projektledning
  - E-post, Diagram, Webbkontor, Video
- **Self-Hosted** eller **SaaS** 🖥️

---

# Komponentöversikt

| Komponent | Programvara |
|------------|----------|
| Chatt 💬 | Element / Synapse |
| Filer ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projekt ✅ | OpenProject |
| E-post ✉️ | OX App Suite |
| Diagram 📊 | CryptPad |
| Webbkontor 📄 | Collabora |
| Video 📹 | Jitsi |

---

# openDesk-projektstatistik

**Utveckling** 🔀              | **Gemenskap** 👥
--------------------------------|---------------------------
Start: Juli 2023                | Bidragsgivare: ~ 70
Löptid: ~ 3 år           | Organisationer: ~ 27
Commits: ~ 1 500                |
Versioner: ~ 150                 |

**OpenCode.de** 🛡️              | **Leveranskedja** 🔒
BMI-finansierad plattform        | Signerade containeravbildningar
Suverän molninfrastruktur   | SBOM för alla komponenter

---

# Infrastrukturöversikt

| Mått | Värde |
|--------|------|
| **Noder** | 9 (3 Control-Plane + 6 Worker) |
| **Distribution** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Minimum)** | 16 kärnor |
| **RAM (Minimum)** | 64 GB |
| **Lagring** | 4+ TB Ceph |

---

# Virtualisering med Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile & HRZ-miljö

```bash
# Distribution med Helmfile
helmfile apply -e hrz
```

- **Helmfile-orchestrering** ⚓
  - Deklarativ konfiguration i `helmfile_generic.yaml.gotmpl`
  - Miljöspecifika åsidosättningar i `environments/hrz/`
  - Automatisk beroendebackup
- **HRZ-miljö skapad** 🖥️
  - Kopia av `staging` med anpassningar
  - Uni Marburg-specifik konfiguration
  - Testsystem för provdrift

---

# Lokal Chart-utveckling

```bash
# Klona/hämta Charts lokalt
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Lokal Chart-utveckling & testning** 💻
- **Klona/hämta i charts-<branch>/** ⬇️
- **Helmfile-referenser till lokala sökvägar** 📄
- **Backup & Återställning med --revert** ↩️

---

# Användarimport: Etablering

- **UDM REST API** — CSV/ODS-import, LDAP-grupper 👤
- **Kontokoppling** — SAML-identitetskoppling 🔗
- **Demoläge** — Testkonton, profilbilder 🖼️

---

# Användarimport: Avetablering

**Tvåfasig avetableringsprocess:**

- **Fas 1: Inaktivera användare**
  - IAM API → UCS Disable → Tidsstämpel i beskrivning
  - Keycloak: Ta bort SAML + upplös grupper
- **Fas 2: Radera användare**
  - Grace-period (6 månader) → Permanent radering
  - Output: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Översikt

- **Utökning av openDesk CE** för universitet 🏫
- **Nya komponenter:**
  - Lärandeplattformar (ILIAS, Moodle)
  - Videokonferens för undervisning (BigBlueButton)
  - Alternativ filsynchronisering (OpenCloud)
- **Alla integrerade med Keycloak SSO** 🔐
- **Distribuera allt med `helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)

---

# 📚 Utbildningskomponenter

| Komponent | Status | Beskrivning |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Stabil | LMS med SAML SSO — Kurser, SCORM, Prov |
| 📖 Moodle | 🔄 Beta | LMS med Shibboleth — Pluginprogram, Betygsbok |
| 🎥 BigBlueButton | 🔄 Beta | Videokonferens för undervisning — Inspelning, Whiteboard |
| ☁️ OpenCloud | 🔄 Beta | CS3-baserad filsynk — Alternativ till Nextcloud |

---

# 🔐 ILIAS SSO — Arkitektur

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**6-stegs SSO-flöde:**

1. 🖥️ Portal → ILIAS-panel
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Inloggning (weblogin.uni-marburg.de)
5. 📨 SAML-assertion tillbaka
6. ✅ ILIAS-instrumentpanel

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 ILIAS-distribution — Lärdomar

| Problem | Lösning |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat saknades i attribute-map.xml |
| Fel attributnamn | Uni-IdP skickar `givenname`/`surname` |
| `handlerSSL` → 404 | Intern TLS: Apache SSL på port 8443 (v5) |
| Konton inaktiverade | `shib_activate_new = 0` |
| SAML-timeout | 60 s → 300 s |
| Hälsokontroll | CronJob: curl SSO-Redirect (varje timme) |

---

# 🚀 Snabbstart — Distribution i 3 steg

```bash
# 1. Klona repot
git clone https://github.com/opendesk-edu/opendesk-edu.git
cd opendesk-edu

# 2. Konfigurera din miljö
# Redigera helmfile/environments/default/global.yaml.gotmpl
# Ange din domän, e-postdomän och imageregistry

# 3. Distribuera
helmfile -e default apply
```

📖 Fullständig dokumentation: [docs/getting-started.md](https://github.com/opendesk-edu/opendesk-edu/blob/main/docs/getting-started.md)

---

# Nätverkskonfiguration

- **Ingress Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — HTTP/HTTPS-terminering 🔄
- **LoadBalancer:** MetalLB
- **Alla Ingressar** migrerade till haproxy ✅

---

# Grafana-instrumentpanel

![height:500px](media/grafana.png)

---

# Uppdateringsprocess

```bash
# Ladda senaste versionerna
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Granska ändringar
helmfile diff -e hrz

# Verkställ uppdateringar
helmfile apply -e hrz

# Återställ vid behov
helmfile rollback -e hrz
```

- **Kontrollerade uppdateringar via Helmfile** 🔄
- **Enkel återställningsmöjlighet** ↩️

---

# HRZ-Upgrade: Ingress-migrering

- **Migrering:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (uniapps-gren)
  - Alla Ingressar migrerade till haproxy ✅
- **Ingress-klasser:**
  - `ingressClassName: haproxy`
  - nginx helt föråldrad
- **Konfiguration:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Upgrade: Dubbel backup

- **Mål:** Redundant backuplagring 🗄️
- **Strategi:** S3-kompatibel med restic-backend 🔄
  - Primär: `s3.example.org:9000/backup-primary`
  - Sekundär: `s3-backup.example.org:9000/backup-secondary`
- **Schemaläggning:** Dagligen kl 00:42, Veckokontroll, Prune på söndagar ⏰
- **Bevarande:** 14 dagliga, Behåll de senaste 5 📦

---

# Institutionella hinder

- **Juridiska avdelningen** ⚖️
  - GDPR, AVV-avtal, Licenftereening
- **Personalrådet** 👥
  - Tjänsteavtal, Medbestämmande för IT-system
- **Administrationen** 🏢
  - Microsoft-preferenser, Formatkompatibilitet
- **Obligatoriska dokument** 📄
  - DSFA, TCO-kalkyl

---

# Nästa steg & Rekommendationer

1. Starta provdrift ▶️
2. Trådvis utrullning (10 → 100 → 1 000 användare) 👥
3. Tydlig separation från produktionssystem 🔗
4. Utvärdering: Kategorisera användningsfall efter suveränitetskrav ✅
5. Budget för driftsteam (inte bara implementering) 💰

---

# 🤝 Engagera dig

**Hjälp oss bygga openDesk Edu för universitet!**

- ⭐ **Stjärnmärk repot:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)
- 🧪 **Testa lokalt:** Distribuera med Helmfile och ge feedback
- 🐛 **Rapportera problem:** Issues för buggar eller funktionsförfrågningar
- 💻 **Bidra:** PRs välkomna — se CONTRIBUTING.md

**Låt oss bygga suverän programvara för universitet tillsammans!** 🎓

---

# Tekniska resurser

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Distributionsguide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [Användarimport](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu) · Utbildningstillägg för universitet
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Klusterautomatisering:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Organisationella resurser

- **HBDI-rekommendation (M365-bedömning):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Digital Suveränitet vid Universitet:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

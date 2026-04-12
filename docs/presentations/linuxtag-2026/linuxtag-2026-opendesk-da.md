---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)




# 🏛️ openDesk: Komfortabel og Suveræn?

🎓 openDesk Edu — Digital Suverænitet på Universiteterne

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Digital Suverænitet — De Fire Søjler

- **Infrastruktur Suverænitet** 🖥️
  Drift af servere og netværk uafhængigt
- **Data Suverænitet** 💾
  Kontrol over datalagring og adgang
- **Software Suverænitet** 💻
  Open-source software uden proprietære afhængigheder
- **Drifts Suverænitet** 🔧
  Fuld kontrol over opdateringer og vedligeholdelse

---

# Hvad er openDesk?

- **Open-source alternativ** til M365 & Google Workspace 🐧
- **Af regering for regering** (BMI / ZenDiS) 🏛️
- **BSI-certificeret** (tysk suverænitet) 📜
- **Cloud-Native:** Kubernetes-baseret arbejdsplads ☁️
- **Modulære Komponenter:**
  - Chat, Filer, Wiki, Projektstyring
  - E-mail, Diagrammer, Webkontor, Video
- **Self-Hosted** eller **SaaS** 🖥️

---

# Komponentoversigt

| Komponent | Software |
|------------|----------|
| Chat 💬 | Element / Synapse |
| Filer ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projekt ✅ | OpenProject |
| E-mail ✉️ | OX App Suite |
| Diagrammer 📊 | CryptPad |
| Webkontor 📄 | Collabora |
| Video 📹 | Jitsi |

---

# openDesk Projektstatistik

**Udvikling** 🔀              | **Fællesskab** 👥
--------------------------------|---------------------------
Start: juli 2023               | Bidragydere: ~ 70
Løbetid: ~ 3 år              | Organisationer: ~ 27
Commits: ~ 1.500                |
Udgivelser: ~ 150               |

**OpenCode.de** 🛡️              | **Forsyningskæde** 🔒
BMI-finansieret platform    | Signede container-images
Suveræn cloud-infrastruktur   | SBOM for alle komponenter

---

# Infrastrukturoversigt

| Metrik | Værdi |
|--------|-------|
| **Noder** | 9 (3 Control-Plane + 6 Worker) |
| **Distribution** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Minimum)** | 16 kerner |
| **RAM (Minimum)** | 64 GB |
| **Lagring** | 4+ TB Ceph |

---

# Virtualisering med Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile & HRZ-Miljø

```bash
# Deployment med Helmfile
helmfile apply -e hrz
```

- **Helmfile Orkestrering** ⚓
  - Deklarativ konfiguration i `helmfile_generic.yaml.gotmpl`
  - Miljøspecifikke overskrivninger i `environments/hrz/`
  - Automatisk afhængighedsbackup
- **HRZ-Miljø oprettet** 🖥️
  - Kopi af `staging` med tilpasninger
  - Uni Marburg-specifik konfiguration
  - Testsystem for pilotlinje

---

# Lokal Chart-udvikling

```bash
# Klon/træk charts lokalt
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Lokal Chart-udvikling & Test** 💻
- **Klon/træk i charts-<branch>/** ⬇️
- **Helmfile-referencer til lokale stier** 📄
- **Backup & Tilbagetrækning med --revert** ↩️

---

# Bruger-Import: Provisionering

- **UDM REST API** — CSV/ODS-import, LDAP-grupper 👤
- **Kontoforbinding** — SAML-identitetsforbindelse 🔗
- **Demotilstand** — Testkonti, profilbilleder 🖼️

---

# Bruger-Import: Deprovisionering

**Tofase-deprovisioneringsworkflow:**

- **Fase 1: Deaktiver Bruger**
  - IAM API → UCS Disable → Tidsstempel i Beskrivelse
  - Keycloak: Fjern SAML + opløs grupper
- **Fase 2: Slet Bruger**
  - Grace-periode (6 måneder) → Permanent sletning
  - Output: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Oversigt

- **Udvidelse af openDesk CE** til universiteter 🏫
- **Nye Komponenter:**
  - Læringssystemer (ILIAS, Moodle)
  - Videokonferencer til undervisning (BigBlueButton)
  - Alternativ filsynchronization (OpenCloud)
- **Alt integreret med Keycloak SSO** 🔐
- **Deploy alt med `helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)

---

# 📚 Uddannelseskomponenter

| Komponent | Status | Beskrivelse |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Stabil | LMS med SAML SSO — Kurser, SCORM, Tests |
| 📖 Moodle | 🔄 Beta | LMS med Shibboleth — Plugins, Karakterskala |
| 🎥 BigBlueButton | 🔄 Beta | Videokonferencer til undervisning — Optagelse, Tavle |
| ☁️ OpenCloud | 🔄 Beta | CS3-baseret filsynkronisering — Alternativ til Nextcloud |

---

# 🔐 ILIAS SSO — Arkitektur

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**6-trins SSO-flow:**

1. 🖥️ Portal → ILIAS-tile
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Login (weblogin.uni-marburg.de)
5. 📨 SAML Assertion tilbage
6. ✅ ILIAS Dashboard

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 ILIAS Deployment — Erfaringer

| Problem | Løsning |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat mangler i attribute-map.xml |
| Attributnavne forkerte | Uni-IdP sender `givenname`/`surname` |
| `handlerSSL` → 404 | Intern TLS: Apache SSL på port 8443 (v5) |
| Konti deaktiveret | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Sundhedstjek | CronJob: curl SSO-Redirect (timeligt) |

---

# 🚀 Quick Start — Deploy i 3 Trin

```bash
# 1. Klon repository
git clone https://github.com/opendesk-edu/deployment.git
cd opendesk-edu

# 2. Konfigurer dit miljø
# Rediger helmfile/environments/default/global.yaml.gotmpl
# Indstil dit domæne, maildomæne og image-registry

# 3. Deploy
helmfile -e default apply
```

📖 Fuld dokumentation: [docs/getting-started.md](https://github.com/opendesk-edu/deployment/blob/main/docs/getting-started.md)

---

# Netværkskonfiguration

- **Ingress Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — HTTP/HTTPS-terminering 🔄
- **LoadBalancer:** MetalLB
- **Alle Ingresses** migreret til haproxy ✅

---

# Grafana Dashboard

![height:500px](media/grafana.png)

---

# Opdateringsproces

```bash
# Indlæs nyeste udgivelser
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Gennemgå ændringer
helmfile diff -e hrz

# Anvend opdateringer
helmfile apply -e hrz

# Tilbagetrækning om nødvendigt
helmfile rollback -e hrz
```

- **Kontrollerede opdateringer via Helmfile** 🔄
- **Nem tilbagetrækningsmulighed** ↩️

---

# HRZ-Opgradering: Ingress-migration

- **Migration:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (uniapps branch)
  - Alle Ingresses migreret til haproxy ✅
- **Ingress-klasser:**
  - `ingressClassName: haproxy`
  - nginx fuldt udfaset
- **Konfiguration:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Opgradering: Dobbelt Backup

- **Mål:** Redundant Backiplagring 🗄️
- **Strategi:** S3-kompatibel med restic-backend 🔄
  - Primær: `s3.example.org:9000/backup-primary`
  - Sekundær: `s3-backup.example.org:9000/backup-secondary`
- **Planlægning:** Dagligt kl. 00:42, Tjek ugentligt, Oprydning søndage ⏰
- **Retention:** 14 Daglige, Behold de sidste 5 📦

---

# Institutionelle Hindringer

- **Juridisk Afdeling** ⚖️
  - GDPR, AVV-kontrakter, Licensoverholdelse
- **Personaleråd** 👥
  - Serviceaftale, Medbestemmelse for IT-systemer
- **Administration** 🏢
  - Microsoft-præferencer, Formatkompatibilitet
- **Påkrævede Dokumenter** 📄
  - DSFA, TCO-beregning

---

# Næste Trin & Anbefalinger

1. Start pilotlinje ▶️
2. Trinvis udrulning (10 → 100 → 1000 brugere) 👥
3. Tydelig adskillelse fra produktionssystemer 🔗
4. Evaluering: Kategoriser brugsscenarier efter suverænitetkrav ✅
5. Budget til driftsteam (ikke kun implementering) 💰

---

# 🤝 Vær Med!

**Hjælp os med at bygge openDesk Edu til universiteter!**

- ⭐ **Star repositoriet:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)
- 🧪 **Test lokalt:** Deploy med Helmfile og giv feedback
- 🐛 **Rapporter problemer:** Issues for fejl eller feature requests
- 💻 **Bidrag:** PRs er velkomne — se CONTRIBUTING.md

**Lad os bygge suveræn universitetssoftware sammen!** 🎓

---

# Tekniske Ressourcer

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment) · Uddannelsesudvidelse til universiteter
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Cluster-Automatisering:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Organisationelle Ressourcer

- **HBDI-anbefaling (M365-vurdering):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Digital Suverænitet på Universiteter:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

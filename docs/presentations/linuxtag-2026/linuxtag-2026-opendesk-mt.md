---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)

# 🏛️ openDesk: Komdu u Suveren?

🎓 openDesk Edu — Sovranità Diġitali fl-Universitajiet

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Sovranità Diġitali — L-Erba' Pileri

- **Sovranità ta' Infrastruttura** 🖥️
  Toperajiet servers u netwerks indipendentement
- **Sovranità tad-Dejta** 💾
  Kontroll fuq l-iskartjar tad-dejta u l-aċċess
- **Sovranità tas-Softwer** 💻
  Softwer open-source mingħajr dipendenzi proprietarji
- **Sovranità Operazzjonali** 🔧
  Kontroll sħiħ fuq l-aġġornamenti u l-manutenzjoni

---

# X'inhu openDesk?

- **Alternattiva open-source** għal M365 u Google Workspace 🐧
- **Minn Gvern għal Gvern** (BMI / ZenDiS) 🏛️
- **Iċċertifikat mill-BSI** (sovranità Ġermaniża) 📜
- **Cloud-Native:** Post tax-xogħol bbażata fuq Kubernetes ☁️
- **Komponenti Modulari:**
  - Chat, Fajls, Wiki, Ġestjoni tal-proġetti
  - Email, Djagrami, Uffiċċju web, Vidjo
- **Self-Hosted** jew **SaaS** 🖥️

---

# Panorama tal-Komponenti

| Komponent | Softwer |
|------------|----------|
| Chat 💬 | Element / Synapse |
| Fajls ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Proġett ✅ | OpenProject |
| Email ✉️ | OX App Suite |
| Djagrami 📊 | CryptPad |
| Uffiċċju web 📄 | Collabora |
| Vidjo 📹 | Jitsi |

---

# Statistika tal-Proġett openDesk

**Żvilupp** 🔀              | **Komunità** 👥
--------------------------------|---------------------------
Bidu: Lulju 2023                | Kontributuri: ~ 70
Durata: ~ 3 snin           | Organizzazzjonijiet: ~ 27
Commits: ~ 1,500                |
Releases: ~ 150                 |

**OpenCode.de** 🛡️              | **Katina tal-Forniment** 🔒
Pjattaformfinanzjata mill-BMI        | Immaġini ta' kontenitur iffirmati
Infrastruttura cloud sovran   | SBOM għall-komponenti kollha

---

# Panorama tal-Infrastruttura

| Metrika | Valur |
|--------|------|
| **Nodi** | 9 (3 Control-Plane + 6 Worker) |
| **Distribuzzjoni** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Minimu)** | 16 cores |
| **RAM (Minimu)** | 64 GB |
| **Storjaġ** | 4+ TB Ceph |

---

# Virtualizzazzjoni b'Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile u Ambjent HRZ

```bash
# Deployment b'Helmfile
helmfile apply -e hrz
```

- **Orkestrazzjoni Helmfile** ⚓
  - Konfigurazzjoni deklarativa f'`helmfile_generic.yaml.gotmpl`
  - Override speċifiċi għall-ambjent f'`environments/hrz/`
  - Backup awtomatiku tad-dipendenzi
- **Ambjent HRZ maħluq** 🖥️
  - Kopja ta' `staging` b'adattamenti
  - Konfigurazzjoni speċifika għal Uni Marburg
  - Sistema tat-test għall-operazzjoni pilota

---

# Żvilupp Lokali tal-Charts

```bash
# Clone/pull charts lokalment
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Żvilupp u Ttestjar Lokali tal-Charts** 💻
- **Clone/pull f'charts-<branch>/** ⬇️
- **Referenzi Helmfile għal paths lokali** 📄
- **Backup u Revert b'--revert** ↩️

---

# User-Import: Provisioning

- **UDM REST API** — Import CSV/ODS, gruppi LDAP 👤
- **Linking tal-Kontijiet** — Linking tal-identità SAML 🔗
- **Modalità Demo** — Kontijiet tat-test, ritratti tal-profil 🖼️

---

# User-Import: Deprovisioning

**Fluss tax-Xogħol ta' Deprovisioning fi Żewġ Fażijiet:**

- **Fażi 1: Idiżattiva l-Utent**
  - IAM API → UCS Disable → Timestamp fil-Deskrizzjoni
  - Keycloak: Neħħi SAML + xolji l-gruppi
- **Fażi 2: Ħassar l-Utent**
  - Perjodu ta' grazzja (6 xhur) → Ħassar permanenti
  - Output: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Panorama

- **Estensjoni ta' openDesk CE** għall-universitajiet 🏫
- **Komponenti Ġodda:**
  - Sistemi ta' Ġestjoni tal-Learnimg (ILIAS, Moodle)
  - Konferenzi bil-Vidjo għat-tagħlim (BigBlueButton)
  - Sinkronizzazzjoni Alternattiva tal-Fajls (OpenCloud)
- **Kollox integrat ma' Keycloak SSO** 🔐
- **Tiddistattja kollox b'`helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)

---

# 📚 Komponenti Edukattivi

| Komponent | Status | Deskrizzjoni |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Stabbli | LMS b'SSO SAML — Korsijiet, SCORM, Testijiet |
| 📖 Moodle | 🔄 Beta | LMS b'Shibboleth — Plugins, Gradebook |
| 🎥 BigBlueButton | 🔄 Beta | Konferenzi bil-vidjo għat-tagħlim — Rekording, Whiteboard |
| ☁️ OpenCloud | 🔄 Beta | Sinkronizzazzjoni fajls ibbażata fuq CS3 — Alternattiva għal Nextcloud |

---

# 🔐 ILIAS SSO — Arkitettura

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**Fluss SSO f'6 Passi:**

1. 🖥️ Portal → ILIAS tile
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Login (weblogin.uni-marburg.de)
5. 📨 SAML Assertion lura
6. ✅ ILIAS Dashboard

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 ILIAS Deployment — Lezzjonijiet Mitfugħa

| Problema | Soluzzjoni |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat nieqes f'attribute-map.xml |
| Isem tal-attributi mhux korrett | Uni-IdP jibgħat `givenname`/`surname` |
| `handlerSSL` → 404 | TLS intern: Apache SSL fuq port 8443 (v5) |
| Kontijiet diżattivati | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Health Check | CronJob: curl SSO-Redirect (kull siegħa) |

---

# 🚀 Quick Start - Tiddejjaq f'3 Passi

```bash
# 1. Ikkopja r-repożitorju
git clone https://github.com/opendesk-edu/opendesk-edu.git
cd opendesk-edu

# 2. Konfigura l-ambjent tiegħek
# Editja helmfile/environments/default/global.yaml.gotmpl
# Issettja d-dominju tiegħek, dominju tal-mail, u reġistru tal-immaġini

# 3. Tiddistattja
helmfile -e default apply
```

📖 Dokumentazzjoni sħiħa: [docs/getting-started.md](https://github.com/opendesk-edu/opendesk-edu/blob/main/docs/getting-started.md)

---

# Konfigurazzjoni tan-Netwerk

- **Ingress Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — HTTP/HTTPS termination 🔄
- **LoadBalancer:** MetalLB
- **L-Ingresses kollha** miggrotta għal haproxy ✅

---

# Dashboard Grafana

![height:500px](media/grafana.png)

---

# Proċess ta' Aġġornament

```bash
# Tgħaddi l-aħħar releases
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Ikkontrolla l-bidliet
helmfile diff -e hrz

# Tapplika l-aġġornamenti
helmfile apply -e hrz

# Rollback jekk meħtieġ
helmfile rollback -e hrz
```

- **Aġġornamenti kkontrollati permezz ta' Helmfile** 🔄
- **Kapaċità faċli ta' rollback** ↩️

---

# HRZ-Upgrade: Migrazzjoni tal-Ingress

- **Migrazzjoni:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (branch uniapps)
  - L-Ingresses kollha miggrotta għal haproxy ✅
- **Klassijiet Ingress:**
  - `ingressClassName: haproxy`
  - nginx fullament deprekat
- **Konfigurazzjoni:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Upgrade: Backup Dupli

- **Għanijiet:** Storage Backup Redundant 🗄️
- **Strateġija:** Kompatibbli ma' S3 b'backend restic 🔄
  - Primarju: `s3.example.org:9000/backup-primary`
  - Sekondarju: `s3-backup.example.org:9000/backup-secondary`
- **Skeda:** Kuljum fis-00:42, Check kull ġimgħa, Prune nhar il-ħadd ⏰
- **Ritenzjoni:** 14 Kuljum, Żomm l-Aħħar 5 📦

---

# Ostakli Istituzzjonali

- **Dipartiment Legali** ⚖️
  - GDPR, kuntratti AVV, konformità tal-liċenzji
- **Kunsill tal-Impjegati** 👥
  - Ftehim tas-servizz, Kodeterminazzjoni għas-sistemi IT
- **Amministrazzjoni** 🏢
  - Preferenzi għal Microsoft, kompatibilità tal-format
- **Dokumenti Meħtieġa** 📄
  - DSFA, kalkolu TCO

---

# Passi Suċċessivi u Rakkomandazzjonijiet

1. Ibda l-operazzjoni pilota ▶️
2. Rollout f'fażijiet (10 → 100 → 1000 utent) 👥
3. Separazzjoni ċara mis-sistemi tal-produzzjoni 🔗
4. Evalwazzjoni: Kategorizza l-użi skont ir-rekwiżiti tas-sovranità ✅
5. Baġit għat-tim tal-operazzjonijiet (mhux biss implimentazzjoni) 💰

---

# 🤝 Ikkontribwixxi

**Għinuna nibnu openDesk Edu għall-universitajiet!**

- ⭐ **Istar il-repo:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)
- 🧪 **Ittestja lokament:** Tiddistattja b'Helmfile u ġib feedback
- 🐛 **Irrapporta problemi:** Issues għal bugs jew rikjesti ta' funzjonijiet
- 💻 **Ikkontribwixxi:** PRs mistiedna — ara CONTRIBUTING.md

**Nibnu softwer universitarju sovran flimkien!** 🎓

---

# Riżorsi Tekniċi

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu) · Estensjoni edukattiva għall-universitajiet
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Cluster-Automation:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Riżorsi Organizzattivi

- **Rakkomandazzjoni HBDI (Valutazzjoni M365):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Sovranità Diġitali fl-Universitajiet:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

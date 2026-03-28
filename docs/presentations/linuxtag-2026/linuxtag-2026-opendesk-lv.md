---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

# openDesk: Ērts un Suverēns?

🎓 openDesk Edu — Digitālā Suverenitāte Universitātēs

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg · [https://mastodon.social/@graphwiz_ai](https://mastodon.social/@graphwiz_ai)

---

# Digitālā Suverenitāte — Četri Pīlāri

- **Infrastruktūras Suverenitāte** 🖥️
  Serveru un tīklu neatkarīga ekspluatācija
- **Datu Suverenitāte** 💾
  Kontrole pār datu glabāšanu un piekļuvi
- **Programmatūras Suverenitāte** 💻
  Atvērtā pirmkoda programmatūra bez īpašniekprogrammatūras atkarībām
- **Ekspluatācijas Suverenitāte** 🔧
  Pilnīga kontrole pār atjauninājumiem un uzturēšanu

---

# Kas ir openDesk?

- **Atvērtā pirmkoda alternatīva** M365 un Google Workspace 🐧
- **Valdības veidota valdībai** (BMI / ZenDiS) 🏛️
- **BSI sertificēta** (Vācijas suverenitāte) 📜
- **Mākoņiem balstīta:** Kubernetes bāzēta darba vieta ☁️
- **Modulārie komponenti:**
  - Čats, faili, wiki, projekta vadība
  - E-pasts, diagrammas, tīmekļa birojs, video
- **Pašhostēts** vai **SaaS** 🖥️

---

# Komponentu Pārskats

| Komponents | Programmatūra |
|------------|----------|
| Čats 💬 | Element / Synapse |
| Faili ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projekts ✅ | OpenProject |
| E-pasts ✉️ | OX App Suite |
| Diagrammas 📊 | CryptPad |
| Tīmekļa birojs 📄 | Collabora |
| Video 📹 | Jitsi |

---

# openDesk Projekta Statistika

**Izstrāde** 🔀              | **Kopiena** 👥
--------------------------------|---------------------------
Sākums: 2023. gada jūlijs       | Līdzautori: ~ 70
Ilgums: ~ 3 gadi              | Organizācijas: ~ 27
Commit'i: ~ 1,500              |
Laidieni: ~ 150                |

**OpenCode.de** 🛡️              | **Piegādes ķēde** 🔒
BMI finansēta platforma       | Parakstīti konteineru attēli
Suverēna mākoņu infrastruktūra | SBOM visiem komponentiem

---

# Infrastruktūras Pārskats

| Rādītājs | Vērtība |
|--------|------|
| **Mezgli** | 9 (3 Vadības plakne + 6 Darba) |
| **Distribūcija** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Minimums)** | 16 kodoli |
| **RAM (Minimums)** | 64 GB |
| **Glabātuve** | 4+ TB Ceph |

---

# Virtualizācija ar Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile un HRZ-Vide

```bash
# Izvietošana ar Helmfile
helmfile apply -e hrz
```

- **Helmfile Orkestrācija** ⚓
  - Deklaratīva konfigurācija `helmfile_generic.yaml.gotmpl`
  - Videi specifiski pārraksti `environments/hrz/`
  - Automātiska atkarību dublēšana
- **HRZ-Vide izveidota** 🖥️
  - `staging` kopija ar pielāgojumiem
  - Marburgas universitātes specifiska konfigurācija
  - Testu sistēma pilotu ekspluatācijai

---

# Vietējā Chart Izstrāde

```bash
# Klonēt/pullēt chartus vietēji
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Vietējā Chart Izstrāde un Testēšana** 💻
- **Klonēt/pullēt charts-<branch>/** ⬇️
- **Helmfile atsauces uz vietējiem ceļiem** 📄
- **Dublēšana un Atgriešana ar --revert** ↩️

---

# Lietotāju Importēšana: Nodalīšana

- **UDM REST API** — CSV/ODS importēšana, LDAP grupas 👤
- **Kontu Saistīšana** — SAML identitātes saistīšana 🔗
- **Demonstrācijas Režīms** — Testa konti, profilu bildes 🖼️

---

# Lietotāju Importēšana: Atnodalīšana

**Divu posmu atnodalīšanas darbplūsma:**

- **1. Posms: Lietotāja Atspējošana**
  - IAM API → UCS Atspējošana → Laika zīmogs aprakstā
  - Keycloak: Noņemt SAML + izformēt grupas
- **2. Posms: Lietotāja Dzēšana**
  - Pārejas periods (6 mēneši) → Pastāvīga dzēšana
  - Izvade: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Pārskats

- **openDesk CE paplašinājums** universitātēm 🏫
- **Jauni Komponenti:**
  - Mācību vadības sistēmas (ILIAS, Moodle)
  - Video konferences mācībām (BigBlueButton)
  - Alternatīva failu sinhronizācija (OpenCloud)
- **Visi integrēti ar Keycloak SSO** 🔐
- **Izvietot visu ar `helmfile apply`** ⚡

**GitHub:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)

---

# 📚 Izglītības Komponenti

| Komponents | Statuss | Apraksts |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Stabils | LMS ar SAML SSO — Kursi, SCORM, Testi |
| 📖 Moodle | 🔄 Beta | LMS ar Shibboleth — Spraudņi, Atzīmju grāmata |
| 🎥 BigBlueButton | 🔄 Beta | Video konferences mācībām — Ierakstīšana, Tāfele |
| ☁️ OpenCloud | 🔄 Beta | CS3 bāzēta failu sinhronizācija — Alternatīva Nextcloud |

---

# 🔐 ILIAS SSO — Arhitektūra

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**6-soļu SSO plūsma:**

1. 🖥️ Portāls → ILIAS flīze
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Pieteikšanās (weblogin.uni-marburg.de)
5. 📨 SAML apgalvojums atpakaļ
6. ✅ ILIAS Dashboard

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.85em;">

# 🔧 ILIAS Izvietošana — Iemācītās Pamācības

| Problēma | Risinājums |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat trūkst attribute-map.xml |
| Atribūtu nosaukumi nepareizi | Uni-IdP sūta `givenname`/`surname` |
| `handlerSSL` → 404 | Iekšējais TLS: Apache SSL portā 8443 (v5) |
| Konti atspējoti | `shib_activate_new = 0` |
| SAML Noildze | 60s → 300s |
| Veselības Pārbaude | CronJob: curl SSO-Redirect (ik stundu) |

---

# 🚀 Ātrs Sākums - Izvietot 3 soļos

```bash
# 1. Klonēt repozitoriju
git clone https://github.com/tobias-weiss-ai-xr/opendesk-edu.git
cd opendesk-edu

# 2. Konfigurēt savu vidi
# Rediģēt helmfile/environments/default/global.yaml.gotmpl
# Iestatīt savu domēnu, pasta domēnu un attēlu reģistru

# 3. Izvietot
helmfile -e default apply
```

📖 Pilna dokumentācija: [docs/getting-started.md](https://github.com/tobias-weiss-ai-xr/opendesk-edu/blob/main/docs/getting-started.md)

---

# Tīkla Konfigurācija

- **Ingress kontrolieris:** haproxy-ingress
- **Reversais Proxys:** Traefik — HTTP/HTTPS pārtraukšana 🔄
- **LoadBalancer:** MetalLB
- **Visi Ingress'i** migrēti uz haproxy ✅

---

# Grafana Dashboard

![height:500px](media/grafana.png)

---

# Atjaunināšanas Process

```bash
# Ielādēt jaunākos laidienus
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Pārskatīt izmaiņas
helmfile diff -e hrz

# Pieņemt atjauninājumus
helmfile apply -e hrz

# Atsaukt, ja nepieciešams
helmfile rollback -e hrz
```

- **Kontrolēti atjauninājumi caur Helmfile** 🔄
- **Viegla atsaukšanas iespēja** ↩️

---

# HRZ-Atjaunināšana: Ingress Migrācija

- **Migrācija:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (uniapps zars)
  - Visi Ingress'i migrēti uz haproxy ✅
- **Ingress Klases:**
  - `ingressClassName: haproxy`
  - nginx pilnībā novecojis
- **Konfigurācija:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Atjaunināšana: Dubultā Dublēšana

- **Mērķi:** Redundanta dublēšanas glabātuve 🗄️
- **Stratēģija:** S3 savietojama ar restic backend 🔄
  - Primārā: `s3.example.org:9000/backup-primary`
  - Sekundārā: `s3-backup.example.org:9000/backup-secondary`
- **Grafiks:** Katru dienu 00:42, Pārbaude katru nedēļu, Tīrīšana svētdienās ⏰
- **Uzglabāšana:** 14 Dienas, Paturēt Pēdējos 5 📦

---

# Institucionālās Šķēršļi

- **Juridiskā Nodaļa** ⚖️
  - GDPR, AVV līgumi, Licenciju atbilstība
- **Darbinieku Padome** 👥
  - Pakalpojumu līgums, Lēmumu pieņemšana IT sistēmām
- **Administrācija** 🏢
  - Microsoft preferences, Formātu savietojamība
- **Nepieciešamie Dokumenti** 📄
  - DSFA, TCO aprēķins

---

# Nākamie Soļi un Ieteikumi

1. Sākt pilotu ekspluatāciju ▶️
2. Graduāla ieviešana (10 → 100 → 1000 lietotāju) 👥
3. Skaidra atdalīšana no produkcijas sistēmām 🔗
4. Novērtējums: Kategorizēt lietojuma gadījumus pēc suverenitātes prasībām ✅
5. Budžets ekspluatācijas komandai (ne tikai ieviešanai) 💰

---

# 🤝 Pievienojieties!

**Palīdziet mums veidot openDesk Edu universitātēm!**

- ⭐ **Zvaigznot repo:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)
- 🧪 **Testēt vietēji:** Izvietot ar Helmfile un sniegt atsauksmes
- 🐛 **Ziņot par problēmām:** Issues kļūdām vai funkciju pieprasījumiem
- 💻 **Piedalīties:** PRs ir laipni gaidīti — skatīt CONTRIBUTING.md

**Kopā veidosim suverēnas universitāšu programmatūru!** 🎓

---

# Tehniskie Resursi

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu) · Izglītības paplašinājums universitātēm
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Cluster-Automatizācija:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Organizatoriskie Resursi

- **HBDI Ieteikums (M365 Novērtējums):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it_node.html)
- **Digitālā Suverenitāte Universitātēs:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

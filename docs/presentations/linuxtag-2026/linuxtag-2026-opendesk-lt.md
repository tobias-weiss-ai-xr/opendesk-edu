---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)




# 🏛️ openDesk: Patogus ir Suverenas?

🎓 openDesk Edu — Skaitmeninė Suvereneta Universitetuose

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Skaitmeninė Suvereneta — Keturi Stulpai

- **Infrastruktūros Suvereneta** 🖥️
  Savarankiškas serverių ir tinklų valdymas
- **Duomenų Suvereneta** 💾
  Kontrolė duomenų saugojimo ir prieigos
- **Programinės įrangos Suvereneta** 💻
  Atvirojo kodo programinė įranga be nuosavybinių priklausomybių
- **Operacinė Suvereneta** 🔧
  Visiškas kontrolė atnaujinimų ir priežiūros

---

# Kas yra openDesk?

- **Atvirojo kodo alternatyva** M365 ir Google Workspace 🐧
- **Vyriausybės sukurta vyriausybei** (BMI / ZenDiS) 🏛️
- **BSI sertifikuota** (Vokietijos suvereneta) 📜
- **Debesimis pagrįsta:** Kubernetes pagrindo darbo vieta ☁️
- **Moduliniai komponentai:**
  - Pokalbiai, failai, wiki, projekto valdymas
  - El. paštas, diagramos, žiniatinklio biuras, vaizdo skambučiai
- **Savarankiškai veikiantis** arba **SaaS** 🖥️

---

# Komponentų Apžvalga

| Komponentas | Programinė įranga |
|------------|----------|
| Pokalbiai 💬 | Element / Synapse |
| Failai ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projektas ✅ | OpenProject |
| El. paštas ✉️ | OX App Suite |
| Diagramos 📊 | CryptPad |
| Žiniatinklio biuras 📄 | Collabora |
| Vaizdas 📹 | Jitsi |

---

# openDesk Projekto Statistika

**Vystymas** 🔀              | **Bendruomenė** 👥
--------------------------------|---------------------------
Pradžia: 2023 m. liepa         | Contributoriai: ~ 70
Trukmė: ~ 3 metai             | Organizacijos: ~ 27
Commit'ai: ~ 1,500             |
Leidimai: ~ 150                |

**OpenCode.de** 🛡️              | **Tiekimo Grandinė** 🔒
BMI finansuojama platforma    | Pasirašyti konteinerių atvaizdai
Suvereni debesų infrastruktūra | SBOM visiems komponentams

---

# Infrastruktūros Apžvalga

| Rodiklis | Reikšmė |
|--------|------|
| **Mazgai** | 9 (3 Valdymo plokštė + 6 Darbuotojai) |
| **Distribucija** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Mažiausias)** | 16 branduolių |
| **RAM (Mažiausias)** | 64 GB |
| **Saugykla** | 4+ TB Ceph |

---

# Virtualizacija su Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile ir HRZ-Aplinka

```bash
# Diegimas su Helmfile
helmfile apply -e hrz
```

- **Helmfile Orkestracija** ⚓
  - Deklaratyvi konfigūracija `helmfile_generic.yaml.gotmpl`
  - Aplinkai specifiniai pakeitimai `environments/hrz/`
  - Automatinis priklausomybių atsarginis kopijavimas
- **HRZ-Aplinka sukurta** 🖥️
  - `staging` kopija su pakeitimais
  - Marburgo universiteto specifinė konfigūracija
  - Bandomoji sistema bandomajam naudojimui

---

# Vietinis Diagramų Vystymas

```bash
# Klonuoti/pullinti diagramas vietoje
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Vietinis Diagramų Vystymas ir Testavimas** 💻
- **Klonuoti/pullinti į charts-<branch>/** ⬇️
- **Helmfile nuorodos į vietinius kelius** 📄
- **Atsarginė kopija ir Grįžimas su --revert** ↩️

---

# Vartotojų Importavimas: Teikimas

- **UDM REST API** — CSV/ODS importavimas, LDAP grupės 👤
- **Paskyrų Susiejimas** — SAML identiteto susiejimas 🔗
- **Demonstracinis Režimas** — Testinės paskyros, profilio nuotraukos 🖼️

---

# Vartotojų Importavimas: Atimimas

**Dviejų Etapų Atėmimo Darbo Eiga:**

- **1 Etapas: Vartotojo Išjungimas**
  - IAM API → UCS Išjungimas → Laiko žyma aprašyme
  - Keycloak: Pašalinti SAML + išskaidyti grupes
- **2 Etapas: Vartotojo Ištrynimas**
  - Perėjimo Laikotarpis (6 mėnesiai) → Visam laikui trynimas
  - Rezultatas: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Apžvalga

- **openDesk CE plėtinys** universitetams 🏫
- **Nauji Komponentai:**
  - Mokymosi Valdymo Sistemos (ILIAS, Moodle)
  - Vaizdo Konferencijos Mokymams (BigBlueButton)
  - Alternatyvus Failų Sinchronizavimas (OpenCloud)
- **Visi integruoti su Keycloak SSO** 🔐
- **Viską įdiegti su `helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)

---

# 📚 Švietimo Komponentai

| Komponentas | Būsena | Aprašymas |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Stabilus | LMS su SAML SSO — Kursai, SCORM, Testai |
| 📖 Moodle | 🔄 Beta | LMS su Shibboleth — Papildiniai, Pažymių knyga |
| 🎥 BigBlueButton | 🔄 Beta | Vaizdo konferencijos mokymams — Įrašymas, Baltoji lenta |
| ☁️ OpenCloud | 🔄 Beta | CS3 pagrindo failų sinchronizavimas — Alternatyva Nextcloud |

---

# 🔐 ILIAS SSO — Architektūra

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**6-žingsnių SSO srautas:**

1. 🖥️ Portadas → ILIAS plytelė
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Prisijungimas (weblogin.uni-marburg.de)
5. 📨 SAML teiginys grįžta
6. ✅ ILIAS Skydelis

**Stackas:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 ILIAS Diegimas — Išmoktos Pamokos

| Problema | Sprendimas |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat trūksta attribute-map.xml |
| Atributų pavadinimai neteisingi | Uni-IdP siunčia `givenname`/`surname` |
| `handlerSSL` → 404 | Vidinis TLS: Apache SSL portu 8443 (v5) |
| Paskyros išjungtos | `shib_activate_new = 0` |
| SAML Laikas baigėsi | 60s → 300s |
| Sveikatos Patikra | CronJob: curl SSO-Peradresavimas (kas valandą) |

---

# 🚀 Greitas Pradėjimas - Diegti per 3 žingsnius

```bash
# 1. Klonuoti saugyklą
git clone https://github.com/opendesk-edu/deployment.git
cd opendesk-edu

# 2. Konfigūruoti savo aplinką
# Redaguoti helmfile/environments/default/global.yaml.gotmpl
# Nustatyti savo domeną, pašto domeną ir atvaizdų registrį

# 3. Diegti
helmfile -e default apply
```

📖 Pilna dokumentacija: [docs/getting-started.md](https://github.com/opendesk-edu/deployment/blob/main/docs/getting-started.md)

---

# Tinklo Konfigūracija

- **Ingress Valdiklis:** haproxy-ingress
- **Atvirkštinis Proxy:** Traefik — HTTP/HTTPS terminavimas 🔄
- **LoadBalancer:** MetalLB
- **Visi Ingress'ai** migruoti į haproxy ✅

---

# Grafana Skydelis

![height:500px](media/grafana.png)

---

# Atnaujinimo Procesas

```bash
# Įkelti naujausius leidimus
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Peržiūrėti pakeitimus
helmfile diff -e hrz

# Taikyti atnaujinimus
helmfile apply -e hrz

# Grąžinti, jei reikia
helmfile rollback -e hrz
```

- **Valdomi atnaujinimai per Helmfile** 🔄
- **Lengva grąžinimo galimybė** ↩️

---

# HRZ-Atnaujinimas: Ingress Migracija

- **Migracija:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (uniapps šaka)
  - Visi Ingress'ai migruoti į haproxy ✅
- **Ingress Klasės:**
  - `ingressClassName: haproxy`
  - nginx visiškai nebenaudojamas
- **Konfigūracija:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Atnaujinimas: Dvigubas Atsarginis Kopijavimas

- **Tikslai:** Atsarginė Kopijos Saugykla su Redundancija 🗄️
- **Strategija:** S3 suderinama su restic backend'u 🔄
  - Pirminis: `s3.example.org:9000/backup-primary`
  - Antrinis: `s3-backup.example.org:9000/backup-secondary`
- **Tvarkaraštis:** Kasdien 00:42, Patikra kas savaitę, Valymas sekmadieniais ⏰
- **Saugojimas:** 14 Kasdieninių, Laikyti Paskutinius 5 📦

---

# Institucinės Klūtys

- **Teisės Skyrius** ⚖️
  - GDPR, AVV sutartys, Licencijų atitiktis
- **Darbuotojų Taryba** 👥
  - Paslaugų sutartis, Bendras sprendimas IT sistemoms
- **Administracija** 🏢
  - Microsoft preferencijos, Formatų suderinamumas
- **Reikalingi Dokumentai** 📄
  - DSFA, TCO skaičiavimas

---

# Tolesni Žingsniai ir Rekomendacijos

1. Pradėti bandomąjį naudojimą ▶️
2. Etapinis įdiegimas (10 → 100 → 1000 vartotojų) 👥
3. Aiškus atskyrimas nuo gamybinių sistemų 🔗
4. Vertinimas: Kategorizuoti naudojimo atvejus pagal suvereneto reikalavimus ✅
5. Biudžetas operacijų komandai (ne tik įgyvendinimui) 💰

---

# 🤝 Prisijunkite!

**Padėkite mums kurti openDesk Edu universitetams!**

- ⭐ **Pažymėti saugyklą:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)
- 🧪 **Testuoti vietoje:** Diegti su Helmfile ir teikti atsiliepimą
- 🐛 **Pranešti apie problemas:** Issues klaidoms ar funkcijų užklausoms
- 💻 **Prisidėti:** PRs laukiami — žr. CONTRIBUTING.md

**Kurkime suverenias universitetų programas kartu!** 🎓

---

# Techniniai Ištekliai

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment) · Švietimo plėtinys universitetams
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Cluster-Automatizavimas:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Organizaciniai Ištekliai

- **HBDI Rekomendacija (M365 Vertinimas):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Skaitmeninė Suvereneta Universitetuose:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

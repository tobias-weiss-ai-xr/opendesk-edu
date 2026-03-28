---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

# openDesk: Mugav ja Suveräänne?

🎓 openDesk Edu — Digitaalne Suveräänsus Ülikoolides

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg · [https://mastodon.social/@graphwiz_ai](https://mastodon.social/@graphwiz_ai)

---

# Digitaalne Suveräänsus — Neli Sammast

- **Infrastruktuuri Suveräänsus** 🖥️
  Serverite ja võrkude iseseisev haldamine
- **Andmesuveräänsus** 💾
  Andmete salvestuse ja juurdepääsu kontroll
- **Tarkvara Suveräänsus** 💻
  Avatud lähtekoodiga tarkvara omalaadsete sõltuvusteta
- **Töötluse Suveräänsus** 🔧
  Täielik kontroll uuenduste ja hoolduse üle

---

# Mis on openDesk?

- **Avatud lähtekoodiga alternatiiv** M365-le ja Google Workspace'ile 🐧
- **Valitsusest Valitsusele** (BMI / ZenDiS) 🏛️
- **BSI sertifikaat** (Saksa suveräänsus) 📜
- **Cloud-Native:** Kubernetesil põhinev töökoht ☁️
- **Modulaarsed Komponendid:**
  - Vestlus, Failid, Wiki, Projektijuhtimine
  - E-post, Diagrammid, Veebi kontor, Video
- **Self-Hosted** või **SaaS** 🖥️

---

# Komponentide Ülevaade

| Komponent | Tarkvara |
|------------|----------|
| Vestlus 💬 | Element / Synapse |
| Failid ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projektid ✅ | OpenProject |
| E-post ✉️ | OX App Suite |
| Diagrammid 📊 | CryptPad |
| Veebi kontor 📄 | Collabora |
| Video 📹 | Jitsi |

---

# openDesk Projekti Statistika

**Arendus** 🔀              | **Kogukond** 👥
--------------------------------|---------------------------
Algus: Juuli 2023               | Kaastöölised: ~ 70
Kestus: ~ 3 aastat           | Organisatsioonid: ~ 27
Commit'id: ~ 1 500              |
Väljalasked: ~ 150              |

**OpenCode.de** 🛡️              | **Varustusahel** 🔒
BMI rahastatud platvorm        | Allkirjastatud konteineripildid
Suveräänne pilveinfrastruktuur   | SBOM kõigi komponentide jaoks

---

# Infrastruktuuri Ülevaade

| Näitaja | Väärtus |
|--------|------|
| **Sõlmed** | 9 (3 Control-Plane + 6 Worker) |
| **Distributsioon** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Miinimum)** | 16 tuuma |
| **RAM (Miinimum)** | 64 GB |
| **Salvestus** | 4+ TB Ceph |

---

# Virtualiseerimine Proxmoxiga

![height:500px](media/proxmox.png)

---

# Helmfile & HRZ-Keskkond

```bash
# Paigaldus Helmfile'iga
helmfile apply -e hrz
```

- **Helmfile Orkestratsioon** ⚓
  - Deklaratiivne konfiguratsioon failis `helmfile_generic.yaml.gotmpl`
  - Keskkonnaspetsiifilised ülekirjutused failis `environments/hrz/`
  - Automaatne sõltuvuste varukoopia
- **Loodud HRZ-Keskkond** 🖥️
  - `staging` koopia kohandustega
  - Marburgi Ülikooli-spetsiifiline konfiguratsioon
  - Testisüsteem pilootkäivituseks

---

# Kohalik Chart-ide Arendus

```bash
# Chart-ide kloonimine/tõmbamine kohapeal
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Kohalik chart-ide arendus ja testimine** 💻
- **Kloonimine/tõmbamine kataloogis charts-<branch>/** ⬇️
- **Helmfile viited kohalikele teedele** 📄
- **Varukoopia ja taastamine võtmega --revert** ↩️

---

# Kasutajate Import: Ettevalmistus

- **UDM REST API** — CSV/ODS import, LDAP grupid 👤
- **Konto Sidumine** — SAML identiteedi sidumine 🔗
- **Demo Režiim** — Testkontod, profiilipildid 🖼️

---

# Kasutajate Import: Mahavõtmine

**Kaheetapiline Mahavõtmise Töövoog:**

- **Etapp 1: Kasutaja Keelamine**
  - IAM API → UCS Keelamine → Ajatempel Kirjelduses
  - Keycloak: SAML eemaldamine + gruppide laialisaatmine
- **Etapp 2: Kasutaja Kustutamine**
  - Ajapiirang (6 kuud) → Püsiv kustutamine
  - Väljund: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Ülevaade

- **openDesk CE laiendus** ülikoolidele 🏫
- **Uued Komponendid:**
  - Õppimishaldussüsteemid (ILIAS, Moodle)
  - Videokonverentsid õppetööks (BigBlueButton)
  - Alternatiivne Failide Sünkroonimine (OpenCloud)
- **Kõik integreeritud Keycloak SSO-ga** 🔐
- **Paigalda kõik käsuga `helmfile apply`** ⚡

**GitHub:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)

---

# 📚 Hariduslikud Komponendid

| Komponent | Staatus | Kirjeldus |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Stabiilne | LMS SAML SSO-ga — Kursused, SCORM, Testid |
| 📖 Moodle | 🔄 Beta | LMS Shibboleth'ga — Pistikprogrammid, Hindekiri |
| 🎥 BigBlueButton | 🔄 Beta | Videokonverentsid õppetööks — Salvestus, Valge tahvel |
| ☁️ OpenCloud | 🔄 Beta | CS3-põhine failide sünkroonimine — Alternatiiv Nextcloud'ile |

---

# 🔐 ILIAS SSO — Arhitektuur

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**6-astmeline SSO Voog:**

1. 🖥️ Portal → ILIAS tile
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Login (weblogin.uni-marburg.de)
5. 📨 SAML Assertion back
6. ✅ ILIAS Dashboard

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.85em;">

# 🔧 ILIAS Paigaldus — Kogemused

| Probleem | Lahendus |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat puudub failis attribute-map.xml |
| Vale atribuutide nimed | Uni-IdP saadab `givenname`/`surname` |
| `handlerSSL` → 404 | Sisemine TLS: Apache SSL pordil 8443 (v5) |
| Kontod keelatud | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Health Check | CronJob: curl SSO-Redirect (iga tund) |

---

# 🚀 Kiire Alustus - Paigaldus 3 Sammuga

```bash
# 1. Kloonige hoidla
git clone https://github.com/tobias-weiss-ai-xr/opendesk-edu.git
cd opendesk-edu

# 2. Konfigureerige oma keskkond
# Redigeerige helmfile/environments/default/global.yaml.gotmpl
# Määrake oma domeen, e-posti domeen ja pildi registrik

# 3. Paigaldus
helmfile -e default apply
```

📖 Täielik dokumentatsioon: [docs/getting-started.md](https://github.com/tobias-weiss-ai-xr/opendesk-edu/blob/main/docs/getting-started.md)

---

# Võrgu Konfiguratsioon

- **Ingress Controller:** haproxy-ingress
- **Pöördproxy:** Traefik — HTTP/HTTPS lõpetamine 🔄
- **LoadBalancer:** MetalLB
- **Kõik Ingressid** migreeritud haproxy-le ✅

---

# Grafana Juhtpaneel

![height:500px](media/grafana.png)

---

# Uuendamise Protsess

```bash
# Laadige uusimad väljalasked
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Vaadake üle muudatused
helmfile diff -e hrz

# Rakendage uuendused
helmfile apply -e hrz

# Taastage vajadusel
helmfile rollback -e hrz
```

- **Kontrollitud uuendused Helmfile'i kaudu** 🔄
- **Lihtne tagasipööramise võimalus** ↩️

---

# HRZ-Uuendus: Ingressi Migratsioon

- **Migratsioon:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (haru uniapps)
  - Kõik Ingressid migreeritud haproxy-le ✅
- **Ingressi Klassid:**
  - `ingressClassName: haproxy`
  - nginx täielikult aegunud
- **Konfiguratsioon:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Uuendus: Topelt-Varukoopia

- **Eesmärgid:** Redundantne Varukoopia Salvestus 🗄️
- **Strateegia:** S3-ühilduv restic backendiga 🔄
  - Peamine: `s3.example.org:9000/backup-primary`
  - Varu: `s3-backup.example.org:9000/backup-secondary`
- **Ajakava:** Iga päev kell 00:42, Nädalane kontroll, Puhastamine pühapäeviti ⏰
- **Säilitamine:** 14 päeva, Viimased 5 alles hoia 📦

---

# Institutsionaalsed Takistused

- **Juriidiline Osakond** ⚖️
  - GDPR, AVV lepingud, Litsentsi vastavus
- **Töötajate Nõukogu** 👥
  - Teenuse leping, Kaasotsustamine IT süsteemide puhul
- **Administratsioon** 🏢
  - Microsofti eelistused, Vormingute ühilduvus
- **Nõutavad Dokumendid** 📄
  - DSFA, TCO arvutus

---

# Järgmised Sammud & Soovitused

1. Alustage pilootkäivitust ▶️
2. Astmeliselt juurutamine (10 → 100 → 1000 kasutajat) 👥
3. Selge eraldamine tootmissüsteemidest 🔗
4. Hindamine: Kategoriseerige kasutusjuhtumid suveräänsuse nõuete järgi ✅
5. Eelarve operatiivmeeskonnale (mitte ainult realiseerimisele) 💰

---

# 🤝 Lõppige Kaasa!

**Aidake meil ehitada openDesk Edu ülikoolidele!**

- ⭐ **Tähistage repo:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)
- 🧪 **Testige kohapeal:** Paigaldage Helmfile'iga ja andke tagasisidet
- 🐛 **Teatage probleeme:** Issues vigadele või funktsioonisoovidele
- 💻 **Panustage:** PR-d on teretulnud — vaadake CONTRIBUTING.md

**Ehitagem koos suveräänset ülikooli tarkvara!** 🎓

---

# Tehnilised Ressursid

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu) · Hariduslik laiendus ülikoolidele
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Cluster-Automation:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Organisatoorsed Ressursid

- **HBDI Soovitus (M365 Hindamine):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Digitaalne Suveräänsus Ülikoolides:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

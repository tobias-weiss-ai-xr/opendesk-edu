---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)

# 🏛️ openDesk: Udoben in Suveren?

🎓 openDesk Edu — Digitalna Suverenost na Univerzah

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Digitalna Suverenost — Štirji Stebri

- **Infrastrukturna Suverenost** 🖥️
  Neodvisno obratovanje strežnikov in omrežij
- **Podatkovna Suverenost** 💾
  Nadzor nad shranjevanjem in dostopom do podatkov
- **Programska Suverenost** 💻
  Odprtokodna programska oprema brez lastniških odvisnosti
- **Operativna Suverenost** 🔧
  Popoln nadzor nad posodobitvami in vzdrževanjem

---

# Kaj je openDesk?

- **Odprtokodna alternativa** za M365 in Google Workspace 🐧
- **Od vlade za vlado** (BMI / ZenDiS) 🏛️
- **BSI-certificiran** (nemška suverenost) 📜
- **Oblačno-Nativen:** Kubernetes-based delovno okolje ☁️
- **Modulrne Komponente:**
  - Klepet, Datoteke, Wiki, Upravljanje projektov
  - E-pošta, Diagrami, Spletni pisarniški program, Video
- **Self-Hosted** ali **SaaS** 🖥️

---

# Pregled Komponent

| Komponenta | Programska oprema |
|------------|-------------------|
| Klepet 💬 | Element / Synapse |
| Datoteke ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projekt ✅ | OpenProject |
| E-pošta ✉️ | OX App Suite |
| Diagrami 📊 | CryptPad |
| Spletni pisarniški program 📄 | Collabora |
| Video 📹 | Jitsi |

---

# Statistike Projekta openDesk

**Razvoj** 🔀                    | **Skupnost** 👥
---------------------------------|---------------------------
Začetek: Julij 2023               | Sodelujoči: ~ 70
Trajanje: ~ 3 leta             | Organizacije: ~ 27
Commiti: ~ 1.500                 |
Izdaje: ~ 150                    |

**OpenCode.de** 🛡️              | **Oskrbovalna Vrsta** 🔒
Platforma, financirana z BMI   | Podpisane slike vsebnikov
Suverena oblakna infrastruktura  | SBOM za vse komponente

---

# Pregled Infrastrukture

| Metrika | Vrednost |
|---------|----------|
| **Vozlišča** | 9 (3 Control-Plane + 6 Worker) |
| **Distribucija** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Minimum)** | 16 jeder |
| **RAM (Minimum)** | 64 GB |
| **Shramba** | 4+ TB Ceph |

---

# Virtualizacija z Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile in HRZ-Okolje

```bash
# Namestitev z Helmfile
helmfile apply -e hrz
```

- **Helmfile Orkestracija** ⚓
  - Deklarativna konfiguracija v `helmfile_generic.yaml.gotmpl`
  - Specifična preglasitev okolja v `environments/hrz/`
  - Samodejna varnostna kopija odvisnosti
- **HRZ-Okolje ustvarjeno** 🖥️
  - Kopija `staging` s prilagoditvami
  - Konfiguracija, specifična za Uni Marburg
  - Testni sistem za pilotno obratovanje

---

# Lokalni Razvoj Chartov

```bash
# Kloniranje/pull chartov lokalno
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Lokalni Razvoj in Testiranje Chartov** 💻
- **Kloniranje/pull v charts-<branch>/** ⬇️
- **Helmfile sklici na lokalne poti** 📄
- **Varnostna kopija in Povrat z --revert** ↩️

---

# Uvoz Uporabnikov: Zagotavljanje

- **UDM REST API** — CSV/ODS uvoz, LDAP skupine 👤
- **Povezovanje Računov** — povezovanje SAML identitete 🔗
- **Demo Način** — testni računi, profilne slike 🖼️

---

# Uvoz Uporabnikov: Odstranjevanje

**Dvo-fazni Postopek Odstranjevanja:**

- **Faza 1: Onemogočitev Uporabnika**
  - IAM API → UCS Disable → Časovni žig v Opisu
  - Keycloak: Odstranitev SAML + razpustitev skupin
- **Faza 2: Brisanje Uporabnika**
  - Čakalna doba (6 mesecev) → Trajno brisanje
  - Izhod: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Pregled

- **Razširitev openDesk CE** za univerze 🏫
- **Nove Komponente:**
  - Sistemi za Upravljanje Učenja (ILIAS, Moodle)
  - Videokonferenca za Poučevanje (BigBlueButton)
  - Alternativna Sinhronizacija Datotek (OpenCloud)
- **Vse integrirano z Keycloak SSO** 🔐
- **Namestite vse z `helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)

---

# 📚 Izobraževalne Komponente

| Komponenta | Stanje | Opis |
|------------|--------|------|
| 📖 ILIAS | ✅ Stabilen | LMS s SAML SSO — Tečaji, SCORM, Testi |
| 📖 Moodle | 🔄 Beta | LMS s Shibboleth — Vtičniki, Dnevnik ocen |
| 🎥 BigBlueButton | 🔄 Beta | Videokonferenca za poučevanje — Snemanje, Bela tabla |
| ☁️ OpenCloud | 🔄 Beta | Sinhronizacija datotek na osnovi CS3 — Alternativa za Nextcloud |

---

# 🔐 ILIAS SSO — Arhitektura

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**6-korakni SSO Potek:**

1. 🖥️ Portal → ILIAS ploščica
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Prijava (weblogin.uni-marburg.de)
5. 📨 SAML Assertion nazaj
6. ✅ ILIAS Nadzorna plošča

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 Namestitev ILIAS — Izkustvene Ugotovitve

| Težava | Rešitev |
|--------|---------|
| `Wrong Login or Password` | V attribute-map.xml manjka SAML NameFormat |
| Napačna imena atributov | Uni-IdP pošilja `givenname`/`surname` |
| `handlerSSL` → 404 | Notranji TLS: Apache SSL na vratih 8443 (v5) |
| Računi onemogočeni | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Preverjanje Zdravja | CronJob: curl SSO-Redirect (urno) |

---

# 🚀 Hitri Začetek - Namestitev v 3 korakih

```bash
# 1. Klonirajte repozitorij
git clone https://github.com/opendesk-edu/opendesk-edu.git
cd opendesk-edu

# 2. Konfigurirajte svoje okolje
# Uredite helmfile/environments/default/global.yaml.gotmpl
# Nastavite svojo domeno, e-poštno domeno in register slik

# 3. Namestite
helmfile -e default apply
```

📖 Popolna dokumentacija: [docs/getting-started.md](https://github.com/opendesk-edu/opendesk-edu/blob/main/docs/getting-started.md)

---

# Omrežna Konfiguracija

- **Ingress Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — HTTP/HTTPS zaključek 🔄
- **LoadBalancer:** MetalLB
- **Vsi Ingressi** migrirani na haproxy ✅

---

# Grafana Nadzorna Plošča

![height:500px](media/grafana.png)

---

# Postopek Posodobitve

```bash
# Naložite najnovejše izdaje
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Pregled sprememb
helmfile diff -e hrz

# Uporabi posodobitve
helmfile apply -e hrz

# Vračanje, če je potrebno
helmfile rollback -e hrz
```

- **Nadzorovane posodobitve preko Helmfile** 🔄
- **Enostavna možnost vračanja** ↩️

---

# HRZ-Posodobitev: Migracija Ingressa

- **Migracija:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (veja uniapps)
  - Vsi Ingressi migrirani na haproxy ✅
- **Razredi Ingressa:**
  - `ingressClassName: haproxy`
  - nginx je popolnoma zastarel
- **Konfiguracija:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Posodobitev: Dvojna Varnostna Kopija

- **Cilji:** Redundantno Shranjevanje Varnostnih Kopij 🗄️
- **Strategija:** S3-združljivo z restic zaledjem 🔄
  - Primarno: `s3.example.org:9000/backup-primary`
  - Sekundarno: `s3-backup.example.org:9000/backup-secondary`
- **Razpored:** Dnevno ob 00:42, Tedenski pregled, Čiščenje v nedeljo ⏰
- **Ohranjanje:** 14 dnevno, Ohrani zadnjih 5 📦

---

# Institucionalne Ovire

- **Pravni Oddelek** ⚖️
  - GDPR, AVV pogodbe, Skladnost z licencami
- **Svet Zaposlenih** 👥
  - Servisni dogovor, Soupravljanje IT sistemov
- **Administracija** 🏢
  - Preference Microsoft, Združljivost formatov
- **Zahtevani Dokumenti** 📄
  - DSFA, TCO izračun

---

# Naslednji Koraki in Priporočila

1. Začnite pilotno obratovanje ▶️
2. Postopna uvedba (10 → 100 → 1000 uporabnikov) 👥
3. Jasna ločitev od produkcijskih sistemov 🔗
4. Ocenjevanje: Kategorizirajte primere uporabe po zahtevah suverenosti ✅
5. Proračun za operativno ekipo (ne le za implementacijo) 💰

---

# 🤝 Vključite se

**Pomagajte nam graditi openDesk Edu za univerze!**

- ⭐ **Dajte zvezdico repozitoriju:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)
- 🧪 **Preizkusite lokalno:** Namestite z Helmfile in posredujte povratne informacije
- 🐛 **Prijavite težave:** Issues za hrošče ali zahteve za funkcionalnosti
- 💻 **Prispevajte:** PR-ji so dobrodošli — glejte CONTRIBUTING.md

**Zgradimo skupaj suvereno univerzitetno programsko opremo!** 🎓

---

# Tehnični Viri

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Vodnik-za-Namestitev](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [Uvoz-Uporabnikov](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu) · Izobraževalna razširitev za univerze
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Avtomatizacija-Clusterja:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Organizacijski Viri

- **HBDI Priporočilo (M365 Ocenjevanje):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Digitalna Suverenost na Univerzah:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

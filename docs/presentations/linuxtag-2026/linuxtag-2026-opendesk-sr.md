---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)

# 🏛️ openDesk: Udoban i Suverenan?

🎓 openDesk Edu — Digitalna Suverenost na Univerzitetima

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Digitalna Suverenost — Četiri Stupa

- **Suverenost Infrastrukture** 🖥️
  Samostalno upravljanje serverima i mrežama
- **Suverenost Podataka** 💾
  Kontrola nad skladištenjem i pristupom podacima
- **Suverenost Softvera** 💻
  Open-source softver bez vlasničkih zavisnosti
- **Operativna Suverenost** 🔧
  Potpuna kontrola nad ažuriranjima i održavanjem

---

# Šta je openDesk?

- **Open-source alternativa** za M365 i Google Workspace 🐧
- **Od vlade za vladu** (BMI / ZenDiS) 🏛️
- **BSI sertifikovan** (nemačka suverenost) 📜
- **Cloud-Native:** Kubernetes-based radno okruženje ☁️
- **Modularne Komponente:**
  - Chat, Fajlovi, Wiki, Upravljanje projektima
  - Email, Dijagrami, Web kancelarija, Video
- **Self-Hosted** ili **SaaS** 🖥️

---

# Pregled Komponenti

| Komponenta | Softver |
|------------|----------|
| Chat 💬 | Element / Synapse |
| Fajlovi ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projekat ✅ | OpenProject |
| Email ✉️ | OX App Suite |
| Dijagrami 📊 | CryptPad |
| Web kancelarija 📄 | Collabora |
| Video 📹 | Jitsi |

---

# Statistike Projekta openDesk

**Razvoj** 🔀              | **Zajednica** 👥
--------------------------------|---------------------------
Početak: Jul 2023                | Kontributora: ~ 70
Trajanje: ~ 3 godine           | Organizacija: ~ 27
Commit-a: ~ 1,500                |
Release-ova: ~ 150                 |

**OpenCode.de** 🛡️              | **Lanac Snabdevanja** 🔒
Platforma finansirana od strane BMI        | Potpisane kontejnerske slike
Suverena cloud infrastruktura   | SBOM za sve komponente

---

# Pregled Infrastrukture

| Metrika | Vrednost |
|--------|------|
| **Čvorovi** | 9 (3 Control-Plane + 6 Worker) |
| **Distribucija** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Minimum)** | 16 jezgara |
| **RAM (Minimum)** | 64 GB |
| **Skladište** | 4+ TB Ceph |

---

# Virtualizacija sa Proxmox-om

![height:500px](media/proxmox.png)

---

# Helmfile i HRZ-Okruženje

```bash
# Deployment sa Helmfile-om
helmfile apply -e hrz
```

- **Helmfile Orkestracija** ⚓
  - Deklarativna konfiguracija u `helmfile_generic.yaml.gotmpl`
  - Preklapanja specifična za okruženje u `environments/hrz/`
  - Automatsko pravljenje rezerve zavisnosti
- **HRZ-Okruženje kreirano** 🖥️
  - Kopija `staging`-a sa prilagođavanjima
  - Konfiguracija specifična za Uni Marburg
  - Test sistem za pilot rad

---

# Lokalni Razvoj Chart-ova

```bash
# Clone/pull chart-ova lokalno
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Lokalni Razvoj i Testiranje Chart-ova** 💻
- **Clone/pull u charts-<branch>/** ⬇️
- **Helmfile reference ka lokalnim putanjama** 📄
- **Rezervna kopija i Vraćanje sa --revert** ↩️

---

# User-Import: Provisioning

- **UDM REST API** — CSV/ODS uvoz, LDAP grupe 👤
- **Povezivanje Naloga** — SAML povezivanje identiteta 🔗
- **Demo Režim** — Test nalozi, profilne slike 🖼️

---

# User-Import: Deprovisioning

**Radni tok Deprovisioning-a u Dve Faze:**

- **Faza 1: Onemogući Korisnika**
  - IAM API → UCS Disable → Timestamp u Opisu
  - Keycloak: Ukloni SAML + rastvori grupe
- **Faza 2: Obriši Korisnika**
  - Period milosti (6 meseci) → Trajno brisanje
  - Izlaz: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Pregled

- **Proširenje openDesk CE** za univerzitete 🏫
- **Nove Komponente:**
  - Sistemi za Upravljanje Učenjem (ILIAS, Moodle)
  - Video Konferencije za Nastavu (BigBlueButton)
  - Alternativna Sinhronizacija Fajlova (OpenCloud)
- **Sve integrisano sa Keycloak SSO** 🔐
- **Deploy sve sa `helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)

---

# 📚 Obrazovne Komponente

| Komponenta | Status | Opis |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Stabilan | LMS sa SAML SSO — Kursevi, SCORM, Testovi |
| 📖 Moodle | 🔄 Beta | LMS sa Shibboleth — Plugini, Dnevnik ocena |
| 🎥 BigBlueButton | 🔄 Beta | Video konferencije za nastavu — Snimanje, Bela tabla |
| ☁️ OpenCloud | 🔄 Beta | CS3-based sinhronizacija fajlova — Alternativa za Nextcloud |

---

# 🔐 ILIAS SSO — Arhitektura

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**SSO Tok od 6 Koraka:**

1. 🖥️ Portal → ILIAS tile
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Login (weblogin.uni-marburg.de)
5. 📨 SAML Assertion nazad
6. ✅ ILIAS Dashboard

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 ILIAS Deployment — Poučene Lekcije

| Problem | Rešenje |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat nedostaje u attribute-map.xml |
| Imena atributa netačna | Uni-IdP šalje `givenname`/`surname` |
| `handlerSSL` → 404 | Interna TLS: Apache SSL na portu 8443 (v5) |
| Nalozi onemogućeni | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Health Check | CronJob: curl SSO-Redirect (svakog sata) |

---

# 🚀 Quick Start - Deploy u 3 Koraka

```bash
# 1. Kloniraj repozitorijum
git clone https://github.com/opendesk-edu/opendesk-edu.git
cd opendesk-edu

# 2. Konfiguriši svoje okruženje
# Uredi helmfile/environments/default/global.yaml.gotmpl
# Podesi svoj domen, mail domen i image registry

# 3. Deploy
helmfile -e default apply
```

📖 Kompletna dokumentacija: [docs/getting-started.md](https://github.com/opendesk-edu/opendesk-edu/blob/main/docs/getting-started.md)

---

# Konfiguracija Mreže

- **Ingress Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — HTTP/HTTPS terminacija 🔄
- **LoadBalancer:** MetalLB
- **Svi Ingress-i** migrirani na haproxy ✅

---

# Grafana Dashboard

![height:500px](media/grafana.png)

---

# Proces Ažuriranja

```bash
# Učitaj najnovije release-ove
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Pregledaj promene
helmfile diff -e hrz

# Primeni ažuriranja
helmfile apply -e hrz

# Rollback ako je potrebno
helmfile rollback -e hrz
```

- **Kontrolisana ažuriranja preko Helmfile-a** 🔄
- **Lako vraćanje (rollback)** ↩️

---

# HRZ-Upgrade: Ingres Migracija

- **Migracija:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (uniapps grana)
  - Svi Ingress-i migrirani na haproxy ✅
- **Ingress Klase:**
  - `ingressClassName: haproxy`
  - nginx potpuno ukinut
- **Konfiguracija:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Upgrade: Dupli Backup

- **Ciljevi:** Redundantno Backup Skladište 🗄️
- **Strategija:** S3-kompatibilno sa restic backend-om 🔄
  - Primarni: `s3.example.org:9000/backup-primary`
  - Sekundarni: `s3-backup.example.org:9000/backup-secondary`
- **Raspored:** Dnevno u 00:42, Provera nedeljno, Prune nedeljom ⏰
- **Zadržavanje:** 14 Dnevno, Zadrži Poslednjih 5 📦

---

# Institucionalne Prepreke

- **Pravni Odeljak** ⚖️
  - GDPR, AVV ugovori, Usaglašenost licenci
- **Veće Zaposlenih** 👥
  - Ugovor o usluzi, Sudelovanje za IT sisteme
- **Administracija** 🏢
  - Microsoft preferencije, Kompatibilnost formata
- **Potrebni Dokumenti** 📄
  - DSFA, TCO proračun

---

# Naredni Koraci i Preporuke

1. Pokreni pilot rad ▶️
2. Postepeni rollout (10 → 100 → 1000 korisnika) 👥
3. Jasno razdvajanje od produkcionih sistema 🔗
4. Evaluacija: Kategorizuj slučajeve upotrebe prema zahtevima suverenosti ✅
5. Budžet za operativni tim (ne samo implementacija) 💰

---

# 🤝 Uključi Se

**Pomozite nam da izgradimo openDesk Edu za univerzitete!**

- ⭐ **Staruj repo:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)
- 🧪 **Testiraj lokalno:** Deploy sa Helmfile i pruži povratne informacije
- 🐛 **Prijavi probleme:** Issues za greške ili zahteve za funkcionalnosti
- 💻 **Doprinesi:** PR-i su dobrodošli — pogledaj CONTRIBUTING.md

**Zajedno gradimo suvereni univerzitetski softver!** 🎓

---

# Tehnički Resursi

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu) · Obrazovno proširenje za univerzitete
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Cluster-Automation:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Organizacioni Resursi

- **HBDI Preporuka (M365 Procena):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Digitalna Suverenost na Univerzitetima:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

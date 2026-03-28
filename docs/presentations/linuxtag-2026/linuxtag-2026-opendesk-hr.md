---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

# openDesk: Udoban i Suverenan?

🎓 openDesk Edu — Digitalna Suverenost na Sveučilištima

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg · [https://mastodon.social/@graphwiz_ai](https://mastodon.social/@graphwiz_ai)

---

# Digitalna Suverenost — Četiri Stupa

- **Suverenost Infrastrukture** 🖥️
  Neovisno upravljanje poslužiteljima i mrežama
- **Suverenost Podataka** 💾
  Kontrola nad pohranom i pristupom podataka
- **Suverenost Softvera** 💻
  Softver otvorenog koda bez vlasničkih ovisnosti
- **Operativna Suverenost** 🔧
  Potpuna kontrola nad nadogradnjama i održavanjem

---

# Što je openDesk?

- **Otvorenokodna alternativa** za M365 & Google Workspace 🐧
- **Od Vlade za Vladu** (BMI / ZenDiS) 🏛️
- **BSI certificiran** (njemačka suverenost) 📜
- **Cloud-Native:** Kubernetes radno okruženje ☁️
- **Modularne Komponente:**
  - Chat, Datoteke, Wiki, Upravljanje projektima
  - E-pošta, Dijagrami, Web ured, Video
- **Self-Hosted** ili **SaaS** 🖥️

---

# Pregled Komponenti

| Komponenta | Softver |
|------------|----------|
| Chat 💬 | Element / Synapse |
| Datoteke ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projekti ✅ | OpenProject |
| E-pošta ✉️ | OX App Suite |
| Dijagrami 📊 | CryptPad |
| Web ured 📄 | Collabora |
| Video 📹 | Jitsi |

---

# Statistike Projekta openDesk

**Razvoj** 🔀              | **Zajednica** 👥
--------------------------------|---------------------------
Početak: Srpanj 2023            | Suradnici: ~ 70
Trajanje: ~ 3 godine         | Organizacije: ~ 27
Commits: ~ 1.500                |
Izdanja: ~ 150                  |

**OpenCode.de** 🛡️              | **Lanac Opreme** 🔒
Platforma financirana od BMI    | Potpisane slike kontejnera
Suverena cloud infrastruktura     | SBOM za sve komponente

---

# Pregled Infrastrukture

| Mjera | Vrijednost |
|--------|------|
| **Čvorovi** | 9 (3 Control-Plane + 6 Worker) |
| **Distribucija** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Minimum)** | 16 jezgri |
| **RAM (Minimum)** | 64 GB |
| **Pohrana** | 4+ TB Ceph |

---

# Virtualizacija s Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile & HRZ-Okruženje

```bash
# Implementacija s Helmfile
helmfile apply -e hrz
```

- **Helmfile Orkestracija** ⚓
  - Deklarativna konfiguracija u `helmfile_generic.yaml.gotmpl`
  - Zamjene specifične za okruženje u `environments/hrz/`
  - Automatska sigurnosna kopija ovisnosti
- **Stvoreno HRZ-Okruženje** 🖥️
  - Kopija `staging` s prilagodbama
  - Konfiguracija specifična za Sveučilište Marburg
  - Testni sustav za pilotni rad

---

# Lokalni Razvoj Chart-ova

```bash
# Kloniranje/povlačenje chart-ova lokalno
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Lokalni razvoj i testiranje chart-ova** 💻
- **Kloniranje/povlačenje u charts-<branch>/** ⬇️
- **Helmfile reference na lokalne putanje** 📄
- **Sigurnosna kopija i vraćanje s --revert** ↩️

---

# Uvoz Korisnika: Opremanje

- **UDM REST API** — CSV/ODS uvoz, LDAP grupe 👤
- **Povezivanje Računa** — SAML povezivanje identiteta 🔗
- **Demo Način** — Testni računi, profilne slike 🖼️

---

# Uvoz Korisnika: Poništavanje Opremanja

**Radni Postupak Poništavanja u Dvije Faze:**

- **Faza 1: Onemogućivanje Korisnika**
  - IAM API → UCS Onemogućavanje → Vremenska oznaka u Opisu
  - Keycloak: Uklanjanje SAML + raspuštanje grupa
- **Faza 2: Brisanje Korisnika**
  - Razdoblje čekanja (6 mjeseci) → Trajno brisanje
  - Izlaz: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Pregled

- **Proširenje openDesk CE** za sveučilišta 🏫
- **Nove Komponente:**
  - Sustavi za Upravljanje Učenjem (ILIAS, Moodle)
  - Videokonferencije za Nastavu (BigBlueButton)
  - Alternativna Sinkronizacija Datoteka (OpenCloud)
- **Sve integrirano s Keycloak SSO** 🔐
- **Implementacija svega s `helmfile apply`** ⚡

**GitHub:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)

---

# 📚 Obrazovne Komponente

| Komponenta | Status | Opis |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Stabilno | LMS sa SAML SSO — Tečajevi, SCORM, Testovi |
| 📖 Moodle | 🔄 Beta | LMS sa Shibboleth — Dodaci, Dnevnik ocjena |
| 🎥 BigBlueButton | 🔄 Beta | Videokonferencije za nastavu — Snimanje, Bijela ploča |
| ☁️ OpenCloud | 🔄 Beta | Sinkronizacija datoteka temeljena na CS3 — Alternativa za Nextcloud |

---

# 🔐 ILIAS SSO — Arhitektura

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**SSO Tijek od 6 Koraka:**

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

# 🔧 ILIAS Implementacija — Pouke

| Problem | Rješenje |
|---------|---------|
| `Wrong Login or Password` | Nedostaje SAML NameFormat u attribute-map.xml |
| Netočna imena atributa | Uni-IdP šalje `givenname`/`surname` |
| `handlerSSL` → 404 | Interni TLS: Apache SSL na portu 8443 (v5) |
| Računi onemogućeni | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Health Check | CronJob: curl SSO-Redirect (svaki sat) |

---

# 🚀 Brzi Početak - Implementacija u 3 Koraka

```bash
# 1. Klonirajte repozitorij
git clone https://github.com/tobias-weiss-ai-xr/opendesk-edu.git
cd opendesk-edu

# 2. Konfigurirajte svoje okruženje
# Uredite helmfile/environments/default/global.yaml.gotmpl
# Postavite svoju domenu, mail domenu i registar slika

# 3. Implementacija
helmfile -e default apply
```

📖 Potpuna dokumentacija: [docs/getting-started.md](https://github.com/tobias-weiss-ai-xr/opendesk-edu/blob/main/docs/getting-started.md)

---

# Mrežna Konfiguracija

- **Ingress Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — HTTP/HTTPS terminacija 🔄
- **LoadBalancer:** MetalLB
- **Svi Ingress-ovi** migrirani na haproxy ✅

---

# Grafana Nadzorna Ploča

![height:500px](media/grafana.png)

---

# Proces Nadogradnje

```bash
# Učitavanje najnovijih izdanja
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Pregled promjena
helmfile diff -e hrz

# Primjena nadogradnji
helmfile apply -e hrz

# Vraćanje ako je potrebno
helmfile rollback -e hrz
```

- **Kontrolirane nadogradnje putem Helmfile** 🔄
- **Jednostavno vraćanje** ↩️

---

# HRZ-Nadogradnja: Ingress Migracija

- **Migracija:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (grana uniapps)
  - Svi Ingress-ovi migrirani na haproxy ✅
- **Ingress Klase:**
  - `ingressClassName: haproxy`
  - nginx potpuno ukinut
- **Konfiguracija:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Nadogradnja: Dvostruko Sigurnosno Kopiranje

- **Ciljevi:** Redundantno Spremište Sigurnosnih Kopija 🗄️
- **Strategija:** S3 kompatibilno s restic backend-om 🔄
  - Primarno: `s3.example.org:9000/backup-primary`
  - Sekundarno: `s3-backup.example.org:9000/backup-secondary`
- **Raspored:** Dnevno u 00:42, Tjedna provjera, Čišćenje nedjeljom ⏰
- **Zadržavanje:** 14 Dnevnih, Zadrži zadnjih 5 📦

---

# Institucionalne Prepreke

- **Pravni Odjel** ⚖️
  - GDPR, AVV ugovori, Usklađenost s licencijama
- **Vijeće Zaposlenika** 👥
  - Sporazum o uslugama, Suodlučivanje za IT sustave
- **Uprava** 🏢
  - Microsoft preferencije, Kompatibilnost formata
- **Potrebni Dokumenti** 📄
  - DSFA, TCO izračun

---

# Sljedeći Koraci & Preporuke

1. Pokretanje pilotnog rada ▶️
2. Postupno uvođenje (10 → 100 → 1000 korisnika) 👥
3. Jasno odvajanje od produkcijskih sustava 🔗
4. Evaluacija: Kategorizacija slučajeva uporabe prema zahtjevima suverenosti ✅
5. Budžet za operativni tim (ne samo za implementaciju) 💰

---

# 🤝 Uključite se!

**Pomozite nam izgraditi openDesk Edu za sveučilišta!**

- ⭐ **Starajte repo:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)
- 🧪 **Testirajte lokalno:** Implementirajte s Helmfile i dajte povratne informacije
- 🐛 **Prijavite probleme:** Issues za greške ili zahtjeve za značajkama
- 💻 **Doprinesite:** PR-ovi su dobrodošli — pogledajte CONTRIBUTING.md

**Zajedno izgradimo suvereni sveučilišni softver!** 🎓

---

# Tehnički Resursi

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu) · Obrazovno proširenje za sveučilišta
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Cluster-Automation:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Organizacijski Resursi

- **HBDI Preporuka (M365 Procjena):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Digitalna Suverenost na Sveučilištima:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

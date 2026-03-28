---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

# openDesk: Pohodlný a Suverénny?

🎓 openDesk Edu — Digitálna Suverenita na Univerzitách

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg · [https://mastodon.social/@graphwiz_ai](https://mastodon.social/@graphwiz_ai)

---

# Digitálna Suverenita — Štyri Piliere

- **Infraštruktúrna Suverenita** 🖥️
  Nezávislé prevádzkovanie serverov a sietí
- **Dátová Suverenita** 💾
  Kontrola nad ukladaním a prístupom k dátam
- **Softvérová Suverenita** 💻
  Open-source softvér bez proprietárnych závislostí
- **Operačná Suverenita** 🔧
  Kompletná kontrola nad aktualizáciami a údržbou

---

# Čo je openDesk?

- **Open-source alternatíva** k M365 a Google Workspace 🐧
- **Od vlády pre vládu** (BMI / ZenDiS) 🏛️
- **BSI-certifikovaný** (nemecká suverenita) 📜
- **Cloud-Natívny:** Kubernetes-based pracovné prostredie ☁️
- **Modulárne Komponenty:**
  - Chat, Súbory, Wiki, Správa projektov
  - E-mail, Diagramy, Webová kancelária, Video
- **Self-Hosted** alebo **SaaS** 🖥️

---

# Prehľad Komponentov

| Komponent | Softvér |
|-----------|---------|
| Chat 💬 | Element / Synapse |
| Súbory ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projekt ✅ | OpenProject |
| E-mail ✉️ | OX App Suite |
| Diagramy 📊 | CryptPad |
| Webová kancelária 📄 | Collabora |
| Video 📹 | Jitsi |

---

# Štatistiky Projektu openDesk

**Vývoj** 🔀                   | **Komunita** 👥
--------------------------------|---------------------------
Začiatok: Júl 2023               | Prispievatelia: ~ 70
Doba trvania: ~ 3 roky        | Organizácie: ~ 27
Commity: ~ 1 500                 |
Vydania: ~ 150                   |

**OpenCode.de** 🛡️              | **Dodávateľský Reťazec** 🔒
Platforma financovaná BMI       | Podpísané kontajnerové obrazy
Suverénna cloudová infraštruktúra | SBOM pre všetky komponenty

---

# Prehľad Infraštruktúry

| Metrika | Hodnota |
|---------|---------|
| **Uzly** | 9 (3 Control-Plane + 6 Worker) |
| **Distribúcia** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Minimum)** | 16 jadier |
| **RAM (Minimum)** | 64 GB |
| **Úložisko** | 4+ TB Ceph |

---

# Virtualizácia cez Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile a HRZ-Prostredie

```bash
# Nasadenie cez Helmfile
helmfile apply -e hrz
```

- **Helmfile Orchestrácia** ⚓
  - Deklaratívna konfigurácia v `helmfile_generic.yaml.gotmpl`
  - Prostredie-specifické prepisy v `environments/hrz/`
  - Automatický backup závislostí
- **HRZ-Prostredie vytvorené** 🖥️
  - Kópia `staging` s úpravami
  - Konfigurácia špecifická pre Uni Marburg
  - Testovací systém pre pilotnú prevádzku

---

# Lokálny Vývoj Chartov

```bash
# Klonovanie/pull chartov lokálne
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Lokálny Vývoj a Testovanie Chartov** 💻
- **Klonovanie/pull v charts-<branch>/** ⬇️
- **Helmfile referencie na lokálne cesty** 📄
- **Záloha a Návrat pomocou --revert** ↩️

---

# Import Používateľov: Zabezpečovanie

- **UDM REST API** — CSV/ODS import, LDAP skupiny 👤
- **Prepojenie Účtov** — prepojenie SAML identity 🔗
- **Demo Režim** — testovacie účty, profilové obrázky 🖼️

---

# Import Používateľov: Odstraňovanie

**Dvojfázový Pracovný Postup Odstraňovania:**

- **Fáza 1: Deaktivácia Používateľa**
  - IAM API → UCS Disable → Časová známka v Popise
  - Keycloak: Odstránenie SAML + rozpustenie skupín
- **Fáza 2: Vymazanie Používateľa**
  - Časť prepnutia (6 mesiacov) → Trvalé vymazanie
  - Výstup: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Prehľad

- **Rozšírenie openDesk CE** pre univerzity 🏫
- **Nové Komponenty:**
  - Systémy na Správu Učenia (ILIAS, Moodle)
  - Videokonferencie na Vyučovanie (BigBlueButton)
  - Alternatívna Synchronizácia Súborov (OpenCloud)
- **Všetko integrované s Keycloak SSO** 🔐
- **Nasadenie všetkého pomocou `helmfile apply`** ⚡

**GitHub:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)

---

# 📚 Vzdelávacie Komponenty

| Komponent | Stav | Popis |
|-----------|------|------|
| 📖 ILIAS | ✅ Stabilný | LMS so SAML SSO — Kurzy, SCORM, Testy |
| 📖 Moodle | 🔄 Beta | LMS so Shibboleth — Pluginy, Knižka známok |
| 🎥 BigBlueButton | 🔄 Beta | Videokonferencie na vyučovanie — Nahrávanie, Biela tabuľa |
| ☁️ OpenCloud | 🔄 Beta | Synchronizácia súborov na báze CS3 — Alternatíva k Nextcloudu |

---

# 🔐 ILIAS SSO — Architektúra

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**6-krokový SSO Proces:**

1. 🖥️ Portál → ILIAS dlaždice
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Prihlásenie (weblogin.uni-marburg.de)
5. 📨 SAML Assertion späť
6. ✅ ILIAS Dashboard

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.85em;">

# 🔧 Nasadenie ILIAS — Skúsenosti

| Problém | Riešenie |
|---------|----------|
| `Wrong Login or Password` | Chýba SAML NameFormat v attribute-map.xml |
| Nesprávne názvy atribútov | Uni-IdP posiela `givenname`/`surname` |
| `handlerSSL` → 404 | Interný TLS: Apache SSL na porte 8443 (v5) |
| Účty deaktivované | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Kontrola Zdravia | CronJob: curl SSO-Redirect (každú hodinu) |

---

# 🚀 Rýchly Štart - Nasadenie v 3 krokoch

```bash
# 1. Klonujte repozitár
git clone https://github.com/tobias-weiss-ai-xr/opendesk-edu.git
cd opendesk-edu

# 2. Nakonfigurujte svoje prostredie
# Upravte helmfile/environments/default/global.yaml.gotmpl
# Nastavte svoju doménu, e-mailovú doménu a registr obrazov

# 3. Nasaďte
helmfile -e default apply
```

📖 Kompletná dokumentácia: [docs/getting-started.md](https://github.com/tobias-weiss-ai-xr/opendesk-edu/blob/main/docs/getting-started.md)

---

# Sieťová Konfigurácia

- **Ingress Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — HTTP/HTTPS ukončenie 🔄
- **LoadBalancer:** MetalLB
- **Všetky Ingressy** migrované na haproxy ✅

---

# Grafana Dashboard

![height:500px](media/grafana.png)

---

# Proces Aktualizácie

```bash
# Načítanie najnovších vydaní
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Prehľad zmien
helmfile diff -e hrz

# Aplikácia aktualizácií
helmfile apply -e hrz

# Návrat späť v prípade potreby
helmfile rollback -e hrz
```

- **Riadené aktualizácie cez Helmfile** 🔄
- **Jednoduchá možnosť návratu** ↩️

---

# HRZ-Aktualizácia: Migrácia Ingressu

- **Migrácia:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (vetva uniapps)
  - Všetky Ingressy migrované na haproxy ✅
- **Triedy Ingressu:**
  - `ingressClassName: haproxy`
  - nginx úplne zastaraný
- **Konfigurácia:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Aktualizácia: Duálny Backup

- **Ciele:** Redundantné Zálohovanie Úložiska 🗄️
- **Stratégia:** S3-kompatibilná s restic backendom 🔄
  - Primárny: `s3.example.org:9000/backup-primary`
  - Sekundárny: `s3-backup.example.org:9000/backup-secondary`
- **Plán:** Denne o 00:42, Týždenná kontrola, Čistenie v nedeľu ⏰
- **Uchovanie:** 14 denných, Ponechať posledných 5 📦

---

# Inštitucionálne Prekážky

- **Právne Oddelenie** ⚖️
  - GDPR, AVV zmluvy, Súlad s licenciami
- **Zamestnanecká Rada** 👥
  - Servisná dohoda, Spolurozhodovanie o IT systémoch
- **Administratíva** 🏢
  - Preferencie Microsoft, Kompatibilita formátov
- **Vyžadované Dokumenty** 📄
  - DSFA, TCO výpočet

---

# Ďalšie Kroky a Odporúčania

1. Spustenie pilotnej prevádzky ▶️
2. Postupné nasadenie (10 → 100 → 1000 používateľov) 👥
3. Jasné oddelenie od produkčných systémov 🔗
4. Hodnotenie: Kategorizácia prípadov použitia podľa požiadaviek na suverenitu ✅
5. Rozpočet pre prevádzkový tím (nielen implementáciu) 💰

---

# 🤝 Zapojte sa!

**Pomôžte nám budovať openDesk Edu pre univerzity!**

- ⭐ **Dajte repozitáru hviezdičku:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)
- 🧪 **Testujte lokálne:** Nasaďte pomocou Helmfile a poskytnite spätnú väzbu
- 🐛 **Nahlaste problémy:** Issues pre chyby alebo požiadavky na funkcie
- 💻 **Prispievajte:** PRs sú vítané — pozri CONTRIBUTING.md

**Budujme spolu suverénny univerzitný softvér!** 🎓

---

# Technické Zdroje

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Sprievodca-Nasadením](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [Import-Používateľov](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu) · Vzdelávacie rozšírenie pre univerzity
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Automatizácia-Clusteru:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Organizačné Zdroje

- **HBDI Odporúčanie (M365 Hodnotenie):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Digitálna Suverenita na Univerzitách:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

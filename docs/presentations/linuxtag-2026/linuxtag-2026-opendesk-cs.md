---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)




# 🏛️ openDesk: Pohodlný a Suverénní?

🎓 openDesk Edu — Digitální Suverenita na Univerzitách

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Digitální Suverenita — Čtyři Pilíře

- **Infrastrukturní Suverenita** 🖥️
  Nezávislý provoz serverů a sítí
- **Datová Suverenita** 💾
  Kontrola nad ukládáním a přístupem k datům
- **Softwarová Suverenita** 💻
  Open-source software bez proprietárních závislostí
- **Provozní Suverenita** 🔧
  Úplná kontrola nad aktualizacemi a údržbou

---

# Co je openDesk?

- **Open-source alternativa** k M365 a Google Workspace 🐧
- **Od vlády pro vládu** (BMI / ZenDiS) 🏛️
- **BSI certifikovaný** (německá suverenita) 📜
- **Cloud-Native:** Pracovní prostředí založené na Kubernetes ☁️
- **Modulární Komponenty:**
  - Chat, Soubory, Wiki, Projektový management
  - E-mail, Diagramy, Webová kancelář, Video
- **Self-Hosted** nebo **SaaS** 🖥️

---

# Přehled Komponent

| Komponenta | Software |
|------------|----------|
| Chat 💬 | Element / Synapse |
| Soubory ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projekt ✅ | OpenProject |
| E-mail ✉️ | OX App Suite |
| Diagramy 📊 | CryptPad |
| Webová kancelář 📄 | Collabora |
| Video 📹 | Jitsi |

---

# Statistiky Projektu openDesk

**Vývoj** 🔀              | **Komunita** 👥
--------------------------------|---------------------------
Začátek: červenec 2023         | Přispěvatelé: ~ 70
Délka trvání: ~ 3 roky       | Organizace: ~ 27
Commity: ~ 1 500               |
Vydání: ~ 150                  |

**OpenCode.de** 🛡️              | **Dodavatelský řetězec** 🔒
Platforma financovaná BMI  | Podepsané obrazy kontejnerů
Suverénní cloudová infrastruktura   | SBOM pro všechny komponenty

---

# Přehled Infrastruktury

| Metrika | Hodnota |
|---------|---------|
| **Uzly** | 9 (3 Control-Plane + 6 Worker) |
| **Distribuce** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Minimum)** | 16 jader |
| **RAM (Minimum)** | 64 GB |
| **Úložiště** | 4+ TB Ceph |

---

# Virtualizace s Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile & HRZ-Prostředí

```bash
# Nasazení s Helmfile
helmfile apply -e hrz
```

- **Orchestrace přes Helmfile** ⚓
  - Deklarativní konfigurace v `helmfile_generic.yaml.gotmpl`
  - Přepsání specifická pro prostředí v `environments/hrz/`
  - Automatická záloha závislostí
- **HRZ-Prostředí vytvořeno** 🖥️
  - Kopie `staging` s úpravami
  - Konfigurace specifická pro Uni Marburg
  - Testovací systém pro pilotní provoz

---

# Lokální Vývoj Chartů

```bash
# Naklonuj/stáhni charty lokálně
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Lokální vývoj a testování chartů** 💻
- **Klonuj/stáhni do charts-<branch>/** ⬇️
- **Helmfile odkazy na lokální cesty** 📄
- **Záloha a obnova s --revert** ↩️

---

# Import Uživatelů: Provisioning

- **UDM REST API** — import CSV/ODS, LDAP skupiny 👤
- **Propojení účtů** — SAML propojení identit 🔗
- **Demo režim** — testovací účty, profilové obrázky 🖼️

---

# Import Uživatelů: Deprovisioning

**Dvoustupňový pracovní postup deprovisioningu:**

- **Fáze 1: Deaktivace uživatele**
  - IAM API → UCS Disable → Časová značka v popisu
  - Keycloak: Odebrat SAML + rozpustit skupiny
- **Fáze 2: Smazání uživatele**
  - Prodleva (6 měsíců) → Trvalé smazání
  - Výstup: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Přehled

- **Rozšíření openDesk CE** pro univerzity 🏫
- **Nové Komponenty:**
  - Systémy pro řízení výuky (ILIAS, Moodle)
  - Videoconference pro výuku (BigBlueButton)
  - Alternativní synchronizace souborů (OpenCloud)
- **Vše integrováno s Keycloak SSO** 🔐
- **Nasaďte vše pomocí `helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)

---

# 📚 Vzdělávací Komponenty

| Komponenta | Stav | Popis |
|------------|------|-------|
| 📖 ILIAS | ✅ Stabilní | LMS se SAML SSO — Kurzy, SCORM, Testy |
| 📖 Moodle | 🔄 Beta | LMS se Shibboleth — Pluginy, Klasifikace |
| 🎥 BigBlueButton | 🔄 Beta | Videoconferencing pro výuku — Nahrávání, Tabule |
| ☁️ OpenCloud | 🔄 Beta | Synchronizace souborů na bázi CS3 — Alternativa k Nextcloud |

---

# 🔐 ILIAS SSO — Architektura

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**6krokový SSO tok:**

1. 🖥️ Portál → ILIAS dlaždice
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Přihlášení (weblogin.uni-marburg.de)
5. 📨 SAML Assertion zpět
6. ✅ ILIAS Dashboard

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 Nasazení ILIAS — Zkušenosti

| Problém | Řešení |
|---------|--------|
| `Wrong Login or Password` | SAML NameFormat chybí v attribute-map.xml |
| Nesprávné názvy atributů | Uni-IdP odesílá `givenname`/`surname` |
| `handlerSSL` → 404 | Interní TLS: Apache SSL na portu 8443 (v5) |
| Účty deaktivovány | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Zdravotní kontrola | CronJob: curl SSO-Redirect (každou hodinu) |

---

# 🚀 Rychlý Start — Nasazení ve 3 krocích

```bash
# 1. Naklonuj repozitář
git clone https://github.com/opendesk-edu/deployment.git
cd opendesk-edu

# 2. Nakonfigurujte své prostředí
# Upravte helmfile/environments/default/global.yaml.gotmpl
# Nastavte svou doménu, e-mailovou doménu a registr obrazů

# 3. Nasaďte
helmfile -e default apply
```

📖 Plná dokumentace: [docs/getting-started.md](https://github.com/opendesk-edu/deployment/blob/main/docs/getting-started.md)

---

# Konfigurace Sítě

- **Ingress Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — HTTP/HTTPS ukončení 🔄
- **LoadBalancer:** MetalLB
- **Všechny Ingressy** migrovány na haproxy ✅

---

# Grafana Dashboard

![height:500px](media/grafana.png)

---

# Proces Aktualizace

```bash
# Načti nejnovější vydání
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Zkontroluj změny
helmfile diff -e hrz

# Použij aktualizace
helmfile apply -e hrz

# Návrat zpět v případě potřeby
helmfile rollback -e hrz
```

- **Kontrolované aktualizace přes Helmfile** 🔄
- **Snadná možnost návratu** ↩️

---

# HRZ-Aktualizace: Migrace Ingress

- **Migrace:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (větev uniapps)
  - Všechny Ingressy migrovány na haproxy ✅
- **Třídy Ingress:**
  - `ingressClassName: haproxy`
  - nginx plně zastaralý
- **Konfigurace:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Aktualizace: Duální Záloha

- **Cíl:** Redundantní zálohovací úložiště 🗄️
- **Strategie:** S3 kompatibilní s restic backendem 🔄
  - Primární: `s3.example.org:9000/backup-primary`
  - Sekundární: `s3-backup.example.org:9000/backup-secondary`
- **Plán:** Denně v 00:42, Kontrola týdně, Úklid v neděli ⏰
- **Retence:** 14 Denních, Zachovat posledních 5 📦

---

# Institucionální Překážky

- **Právní oddělení** ⚖️
  - GDPR, AVV smlouvy, Dodržování licencí
- **Zaměstnanecká rada** 👥
  - Služební smlouva, Spolurozhodování o IT systémech
- **Správa** 🏢
  - Preference Microsoftu, Kompatibilita formátů
- **Vyžadované Dokumenty** 📄
  - DSFA, TCO výpočet

---

# Další Kroky & Doporučení

1. Zahájit pilotní provoz ▶️
2. Postupné nasazení (10 → 100 → 1000 uživatelů) 👥
3. Jasné oddělení od produkčních systémů 🔗
4. Hodnocení: Kategorizace případů užití podle požadavků na suverenitu ✅
5. Rozpočet na provozní tým (nejen na implementaci) 💰

---

# 🤝 Zapojte se!

**Pomozte nám stavět openDesk Edu pro univerzity!**

- ⭐ **Dejte hvězdičku repozitáři:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)
- 🧪 **Testujte lokálně:** Nasaďte pomocí Helmfile a poskytněte zpětnou vazbu
- 🐛 **Hlaste problémy:** Issue pro chyby nebo požadavky na funkce
- 💻 **Přispívejte:** PR jsou vítány — viz CONTRIBUTING.md

**Postavme společně suverénní univerzitní software!** 🎓

---

# Technické Zdroje

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment) · Vzdělávací rozšíření pro univerzity
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Automatizace Clusteru:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Organizační Zdroje

- **Doporučení HBDI (hodnocení M365):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Digitální Suverenita na Univerzitách:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

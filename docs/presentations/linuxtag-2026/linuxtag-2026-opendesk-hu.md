---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)




# 🏛️ openDesk: Kényelmes és Szuverén?

🎓 openDesk Edu — Digitális Szuverenitás az Egyetemeken

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Digitális Szuverenitás — A Négy Pillér

- **Infrastrukturális Szuverenitás** 🖥️
  Szerverek és hálózatok független üzemeltetése
- **Adatszuverenitás** 💾
  Adattárolás és hozzáférés feletti ellenőrzés
- **Szoftverszuverenitás** 💻
  Nyílt forráskódú szoftver tulajdonosi függőségek nélkül
- **Operatív Szuverenitás** 🔧
  Teljes felügyelet a frissítések és karbantartás felett

---

# Mi az az openDesk?

- **Nyílt forráskódú alternatíva** az M365-höz és a Google Workspace-hez 🐧
- **Kormánytól a kormánynak** (BMI / ZenDiS) 🏛️
- **BSI-tanúsítvány** (német szuverenitás) 📜
- **Felhő-natív:** Kubernetes-alapú munkahely ☁️
- **Moduláris Komponensek:**
  - Chat, Fájlok, Wiki, Projektmenedzsment
  - E-mail, Diagramok, Webes iroda, Videó
- **Self-Hosted** vagy **SaaS** 🖥️

---

# Komponens Áttekintés

| Komponens | Szoftver |
|-----------|----------|
| Chat 💬 | Element / Synapse |
| Fájlok ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projekt ✅ | OpenProject |
| E-mail ✉️ | OX App Suite |
| Diagramok 📊 | CryptPad |
| Webes iroda 📄 | Collabora |
| Videó 📹 | Jitsi |

---

# openDesk Projekt Statisztikák

**Fejlesztés** 🔀              | **Közösség** 👥
--------------------------------|---------------------------
Kezdés: 2023. július             | Közreműködők: ~ 70
Futamidő: ~ 3 év             | Szervezetek: ~ 27
Commitok: ~ 1 500                |
Kiadások: ~ 150                  |

**OpenCode.de** 🛡️              | **Ellátási Lánc** 🔒
BMI által finanszírozott platform | Aláírt konténerképek
Szuverén felhőinfrastruktúra     | SBOM minden komponenshez

---

# Infrastruktúra Áttekintés

| Metrika | Érték |
|---------|-------|
| **Csomópontok** | 9 (3 Control-Plane + 6 Worker) |
| **Disztribúció** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Minimum)** | 16 mag |
| **RAM (Minimum)** | 64 GB |
| **Tárhely** | 4+ TB Ceph |

---

# Virtualizáció Proxmox-szal

![height:500px](media/proxmox.png)

---

# Helmfile és HRZ-Környezet

```bash
# Telepítés Helmfile-lel
helmfile apply -e hrz
```

- **Helmfile Orchestráció** ⚓
  - Deklaratív konfiguráció a `helmfile_generic.yaml.gotmpl` fájlban
  - Környezet-specifikus felülbírálások az `environments/hrz/` könyvtárban
  - Automatikus függőségi biztonsági mentés
- **HRZ-Környezet létrehozva** 🖥️
  - A `staging` másolata módosításokkal
  - Uni Marburg-specifikus konfiguráció
  - Tesztrendszer a pilot üzemeltetéshez

---

# Helyi Chart Fejlesztés

```bash
# Chart-ok helyi klónozása/pull-olása
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Helyi Chart Fejlesztés és Tesztelés** 💻
- **Klónozás/pull a charts-<branch>/** könyvtárba ⬇️
- **Helmfile hivatkozások helyi útvonalakra** 📄
- **Biztonsági Mentés és Visszaállítás --revert segítségével** ↩️

---

# Felhasználó-importálás: Létesítés

- **UDM REST API** — CSV/ODS importálás, LDAP csoportok 👤
- **Fiók Összekapcsolás** — SAML identitás összekapcsolás 🔗
- **Demo Mód** — Tesztfiókok, profilképek 🖼️

---

# Felhasználó-importálás: Lekészítés

**Kétfázisos Lekészítési Munkafolyamat:**

- **1. Fázis: Felhasználó Letiltása**
  - IAM API → UCS Disable → Időbélyeg a Leírásban
  - Keycloak: SAML eltávolítása + csoportok feloszlása
- **2. Fázis: Felhasználó Törlése**
  - Türelmi időszak (6 hónap) → Végleges törlés
  - Kimenet: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Áttekintés

- **Az openDesk CE kiterjesztése** egyetemek számára 🏫
- **Új Komponensek:**
  - Tanuláskezelő Rendszerek (ILIAS, Moodle)
  - Oktatási Videókonferencia (BigBlueButton)
  - Alternatív Fájlszinkronizáció (OpenCloud)
- **Mind integrálva Keycloak SSO-val** 🔐
- **Mindent telepíts `helmfile apply` paranccsal** ⚡

**GitHub:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)

---

# 📚 Oktatási Komponensek

| Komponens | Állapot | Leírás |
|-----------|---------|--------|
| 📖 ILIAS | ✅ Stabil | LMS SAML SSO-val — Kurzusok, SCORM, Tesztek |
| 📖 Moodle | 🔄 Béta | LMS Shibboleth-szel — Bővítmények, Osztályozókönyv |
| 🎥 BigBlueButton | 🔄 Béta | Oktatási videókonferencia — Felvétel, Tábla |
| ☁️ OpenCloud | 🔄 Béta | CS3-alapú fájlszinkronizáció — Nextcloud alternatíva |

---

# 🔐 ILIAS SSO — Architektúra

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**6 Lépéses SSO Folyamat:**

1. 🖥️ Portál → ILIAS csempe
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Bejelentkezés (weblogin.uni-marburg.de)
5. 📨 SAML Assertion visszatérés
6. ✅ ILIAS Irányítópult

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 ILIAS Telepítés — Tapasztalatok

| Probléma | Megoldás |
|----------|----------|
| `Wrong Login or Password` | SAML NameFormat hiányzik az attribute-map.xml-ből |
| Helytelen attribútumnevek | Uni-IdP `givenname`/`surname`-t küld |
| `handlerSSL` → 404 | Belső TLS: Apache SSL a 8443-as porton (v5) |
| Fiókok letiltva | `shib_activate_new = 0` |
| SAML Időtúllépés | 60s → 300s |
| Állapotellenőrzés | CronJob: curl SSO-Redirect (óránként) |

---

# 🚀 Gyors Kezdés - Telepítés 3 Lépésben

```bash
# 1. Klónozd a repozitóriumot
git clone https://github.com/opendesk-edu/deployment.git
cd opendesk-edu

# 2. Konfiguráld a környezetedet
# Szerkeszd a helmfile/environments/default/global.yaml.gotmpl fájlt
# Állítsd be a domainedet, e-mail domainedet és a képregisztrációt

# 3. Telepíts
helmfile -e default apply
```

📖 Teljes dokumentáció: [docs/getting-started.md](https://github.com/opendesk-edu/deployment/blob/main/docs/getting-started.md)

---

# Hálózati Konfiguráció

- **Ingress Controller:** haproxy-ingress
- **Fordított Proxy:** Traefik — HTTP/HTTPS lezárás 🔄
- **LoadBalancer:** MetalLB
- **Minden Ingress** migrálva a haproxy-ra ✅

---

# Grafana Irányítópult

![height:500px](media/grafana.png)

---

# Frissítési Folyamat

```bash
# Legújabb kiadások betöltése
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Változások áttekintése
helmfile diff -e hrz

# Frissítések alkalmazása
helmfile apply -e hrz

# Visszagördítés ha szükséges
helmfile rollback -e hrz
```

- **Helmfile-en keresztüli vezérelt frissítések** 🔄
- **Egyszerű visszagördítési lehetőség** ↩️

---

# HRZ-Frissítés: Ingress Migráció

- **Migráció:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (uniapps ág)
  - Minden Ingress migrálva a haproxy-ra ✅
- **Ingress Osztályok:**
  - `ingressClassName: haproxy`
  - nginx teljesen elavult
- **Konfiguráció:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Frissítés: Kettős Biztonsági Mentés

- **Célok:** Redundáns Biztonsági Mentés Tárolás 🗄️
- **Stratégia:** S3-kompatibilis restic backend-del 🔄
  - Elsődleges: `s3.example.org:9000/backup-primary`
  - Másodlagos: `s3-backup.example.org:9000/backup-secondary`
- **Ütemezés:** Napi 00:42-kor, Heti ellenőrzés, Vasárnap takarítás ⏰
- **Megőrzés:** 14 napi, Az utolsó 5 megtartása 📦

---

# Intézményi Akadályok

- **Jogi Osztály** ⚖️
  - GDPR, AVV szerződések, Licenc-megfelelés
- **Személyzeti Tanács** 👥
  - Szolgáltatási megállapodás, IT rendszerek közös döntéshozatala
- **Adminisztráció** 🏢
  - Microsoft preferenciák, Formátum-kompatibilitás
- **Szükséges Dokumentumok** 📄
  - DSFA, TCO számítás

---

# Következő Lépések és Javaslatok

1. Pilot üzemeltetés indítása ▶️
2. Lépcsőzetes bevezetés (10 → 100 → 1000 felhasználó) 👥
3. Egyértelmű elválasztás a termelési rendszerektől 🔗
4. Értékelés: Használati esetek kategorizálása szuverenitási követelmények szerint ✅
5. Költségvetés az üzemeltetői csapat számára (nem csak a megvalósításra) 💰

---

# 🤝 Csatlakozz!

**Segíts nekünk az openDesk Edu felépítésében az egyetemek számára!**

- ⭐ **Starold a repót:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)
- 🧪 **Tesztelj helyben:** Telepíts Helmfile-lel és küldj visszajelzést
- 🐛 **Jelents hibákat:** Issue-kat hibákhoz vagy funkciókéréshez
- 💻 **Közreműködés:** PR-k szívesen látottak — lásd CONTRIBUTING.md

**Építsünk együtt szuverén egyetemi szoftvert!** 🎓

---

# Technikai Erőforrások

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Telepítési-Útmutató](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [Felhasználó-importálás](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment) · Oktatási kiterjesztés egyetemek számára
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Klaszter-Automatizáció:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Szervezeti Erőforrások

- **HBDI Ajánlás (M365 Értékelés):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Digitális Szuverenitás az Egyetemeken:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

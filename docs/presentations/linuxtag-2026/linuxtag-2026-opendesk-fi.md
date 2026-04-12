---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)




# 🏛️ openDesk: Mukavuudekko ja Suvereeni?

🎓 openDesk Edu — Digitaalinen Suvereniteetti Yliopistoissa

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Digitaalinen Suvereniteetti — Neljä Pilaria

- **Infrastruktuurisuvereniteetti** 🖥️
  Palvelimien ja verkkojen itsenäinen ylläpito
- **Datasuvereniteetti** 💾
  Hallinta tiedon tallennuksesta ja käytöstä
- **Ohjelmistosuvereniteetti** 💻
  Avoimen lähdekoodin ohjelmistot ilman omistusoikeudellisia riippuvuuksia
- **Käyttösuvereniteetti** 🔧
  Täysi hallinta päivityksistä ja ylläpidosta

---

# Mikä on openDesk?

- **Avoimen lähdekoodin vaihtoehto** M365:lle ja Google Workspacelle 🐧
- **Hallinnon hallinnalle** (BMI / ZenDiS) 🏛️
- **BSI-sertifioitu** (saksalainen suvereniteetti) 📜
- **Cloud-Native:** Kubernetes-pohjainen työympäristö ☁️
- **Modulaariset Komponentit:**
  - Chat, Tiedostot, Wiki, Projektinhallinta
  - Sähköposti, Kaaviot, Web-toimisto, Video
- **Self-Hosted** tai **SaaS** 🖥️

---

# Komponenttiyhteenveto

| Komponentti | Ohjelmisto |
|-------------|------------|
| Chat 💬 | Element / Synapse |
| Tiedostot ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projektihallinta ✅ | OpenProject |
| Sähköposti ✉️ | OX App Suite |
| Kaaviot 📊 | CryptPad |
| Web-toimisto 📄 | Collabora |
| Video 📹 | Jitsi |

---

# openDesk-projektin tilastot

**Kehitys** 🔀              | **Yhteisö** 👥
--------------------------------|---------------------------
Aloitettu: heinäkuu 2023        | Avustajia: ~ 70
Kesto: ~ 3 vuotta             | Organisaatioita: ~ 27
Commitit: ~ 1 500               |
Julkaisut: ~ 150                |

**OpenCode.de** 🛡️              | **Toimitusketju** 🔒
BMI-rahoitettu alusta       | Allekirjoitetut container-kuvat
Suvereeni cloud-infrastruktuuri   | SBOM kaikille komponenteille

---

# Infrastruktuurin yhteenveto

| Mittari | Arvo |
|---------|------|
| **Solmut** | 9 (3 Control-Plane + 6 Worker) |
| **Jakelu** | K3s v1.32.3 |
| **Käyttöjärjestelmä** | Debian 12 |
| **CPU (Vähintään)** | 16 ydintä |
| **RAM (Vähintään)** | 64 GB |
| **Tallennustila** | 4+ TB Ceph |

---

# Virtualisointi Proxmoxilla

![height:500px](media/proxmox.png)

---

# Helmfile & HRZ-ympäristö

```bash
# Julkaisu Helmfilella
helmfile apply -e hrz
```

- **Helmfile-orkestrointi** ⚓
  - Deklaratiivinen konfiguraatio tiedostossa `helmfile_generic.yaml.gotmpl`
  - Ympäristökohtaiset ylikirjoitukset hakemistossa `environments/hrz/`
  - Automaattinen riippuvuuskopio
- **HRZ-ympäristö luotu** 🖥️
  - `staging`-ympäristön kopio mukautuksin
  - Uni Marburg -kohtainen konfiguraatio
  - Testijärjestelmä pilottikäyttöä varten

---

# Paikallinen Chart-kehitys

```bash
# Kloonaa/nouda chartit paikallisesti
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Paikallinen Chart-kehitys ja testaus** 💻
- **Kloonaa/nouda hakemistoon charts-<branch>/** ⬇️
- **Helmfile-viittaukset paikallisiin polkuihin** 📄
- **Varmuuskopio ja palautus --revert-parametrilla** ↩️

---

# Käyttäjätuonti: Provisionointi

- **UDM REST API** — CSV/ODS-tuonti, LDAP-ryhmät 👤
- **Tilien yhdistäminen** — SAML-identiteetin linkitys 🔗
- **Demotila** — Testitilit, profiilikuvat 🖼️

---

# Käyttäjätuonti: Deprovisionointi

**Kaksivaiheinen deprovisionointityönkulku:**

- **Vaihe 1: Käyttäjän poistaminen käytöstä**
  - IAM API → UCS Disable → Aikaleima kuvauksessa
  - Keycloak: Poista SAML + pura ryhmät
- **Vaihe 2: Käyttäjän poistaminen**
  - Armonaika (6 kuukautta) → Pysyvä poisto
  - Tuloste: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Yhteenveto

- **openDesk CE:n laajennus** yliopistoille 🏫
- **Uudet Komponentit:**
  - Oppimisalustat (ILIAS, Moodle)
  - Videokonferenssit opetukseen (BigBlueButton)
  - Vaihtoehtoinen tiedostosynkronointi (OpenCloud)
- **Kaikki integroitu Keycloak SSO:n kanssa** 🔐
- **Julkaise kaikki komennolla `helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)

---

# 📚 Koulutuskomponentit

| Komponentti | Tila | Kuvaus |
|-------------|------|--------|
| 📖 ILIAS | ✅ Vakaa | LMS SAML SSO:lla — Kurssit, SCORM, Testit |
| 📖 Moodle | 🔄 Beta | LMS Shibbolethilla — Lisäosat, Arvosanakirja |
| 🎥 BigBlueButton | 🔄 Beta | Videokonferenssit opetukseen — Tallennus, Valkotaulu |
| ☁️ OpenCloud | 🔄 Beta | CS3-pohjainen tiedostosynkronointi — Vaihtoehto Nextcloudille |

---

# 🔐 ILIAS SSO — Arkkitehtuuri

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**6-vaiheinen SSO-vuo:**

1. 🖥️ Portaali → ILIAS-tiili
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Kirjautuminen (weblogin.uni-marburg.de)
5. 📨 SAML-vahvistus takaisin
6. ✅ ILIAS-hallintapaneeli

**Pino:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 ILIAS-julkaisu — Kokemuksia

| Ongelma | Ratkaisu |
|---------|----------|
| `Wrong Login or Password` | SAML NameFormat puuttuu tiedostosta attribute-map.xml |
| Määreiden nimet väärin | Uni-IdP lähettää `givenname`/`surname` |
| `handlerSSL` → 404 | Sisäinen TLS: Apache SSL portissa 8443 (v5) |
| Tilit poistettu käytöstä | `shib_activate_new = 0` |
| SAML-aikakatkaisu | 60s → 300s |
| Terveystarkistus | CronJob: curl SSO-uudelleenohjaus (tunneittain) |

---

# 🚀 Pikaohje — Julkaise 3 vaiheessa

```bash
# 1. Kloonaa repositorio
git clone https://github.com/opendesk-edu/deployment.git
cd opendesk-edu

# 2. Määritä ympäristösi
# Muokkaa helmfile/environments/default/global.yaml.gotmpl
# Aseta verkkotunnuksesi, sähköpostiverkkotunnuksesi ja imagerekisterisi

# 3. Julkaise
helmfile -e default apply
```

📖 Täysi dokumentaatio: [docs/getting-started.md](https://github.com/opendesk-edu/deployment/blob/main/docs/getting-started.md)

---

# Verkkokonfiguraatio

- **Ingress-kontrolleri:** haproxy-ingress
- **Käänteinen välityspalvelin:** Traefik — HTTP/HTTPS-päättäminen 🔄
- **LoadBalancer:** MetalLB
- **Kaikki Ingressit** siirretty haproxy:hin ✅

---

# Grafana-hallintapaneeli

![height:500px](media/grafana.png)

---

# Päivitysprosessi

```bash
# Lataa uusimmat julkaisut
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Tarkista muutokset
helmfile diff -e hrz

# Ota päivitykset käyttöön
helmfile apply -e hrz

# Palauta tarvittaessa
helmfile rollback -e hrz
```

- **Hallitut päivitykset Helmfilen kautta** 🔄
- **Helppo palautusmahdollisuus** ↩️

---

# HRZ-päivitys: Ingress-siirto

- **Siirto:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (uniapps-haara)
  - Kaikki Ingressit siirretty haproxy:hin ✅
- **Ingress-luokat:**
  - `ingressClassName: haproxy`
  - nginx kokonaan poistettu käytöstä
- **Konfiguraatio:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-päivitys: Kaksoisvarmuuskopio

- **Tavoite:** Redundantti varmuuskopiointitallennus 🗄️
- **Strategia:** S3-yhteensopiva restic-taustajärjestelmä 🔄
  - Ensisijainen: `s3.example.org:9000/backup-primary`
  - Toissijainen: `s3-backup.example.org:9000/backup-secondary`
- **Ajoitus:** Päivittäin klo 00:42, Tarkistus viikoittain, Puhdistus sunnuntaisin ⏰
- **Säilytys:** 14 päivittäistä, säilytä viimeiset 5 📦

---

# Institutionaaliset esteet

- **Oikeusosasto** ⚖️
  - GDPR, AVV-sopimukset, Lisenssien noudattaminen
- **Henkilöstöneuvosto** 👥
  - Palvelusopimus, IT-järjestelmien osallistava päätöksenteko
- **Hallinto** 🏢
  - Microsoft-ehdottomuudet, Formaattiyhteensopivuus
- **Vaaditut asiakirjat** 📄
  - DSFA, TCO-laskelma

---

# Seuraavat askeleet ja suositukset

1. Aloita pilotikäyttö ▶️
2. Portaittainen käyttöönotto (10 → 100 → 1000 käyttäjää) 👥
3. Selkeä erottaminen tuotantojärjestelmistä 🔗
4. Arviointi: Luokittele käyttötapaukset suvereniteettivaatimusten mukaan ✅
5. Budjetointi käyttötiimille (ei vain toteutukselle) 💰

---

# 🤝 Tule mukaan!

**Auta meitä rakentamaan openDesk Edu yliopistoille!**

- ⭐ **Starra repo:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)
- 🧪 **Testaa paikallisesti:** Julkaise Helmfilella ja anna palautetta
- 🐛 **Raportoi ongelmia:** Issueita bugeille tai ominaisuustoiveille
- 💻 **Osallistu:** PR:t ovat tervetulleita — katso CONTRIBUTING.md

**Rakennetaan yhdessä suvereenia yliopisto-ohjelmistoa!** 🎓

---

# Tekniset resurssit

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment) · Koulutulaajennus yliopistoille
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Klusteriautomaatio:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Organisaatooriset resurssit

- **HBDI-suositus (M365-arviointi):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Digitaalinen suvereniteetti yliopistoissa:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)




# 🏛️ openDesk: Comfortáilteach agus Sábhárlacht?

🎓 openDesk Edu — Sábhárlacht Dhigiteach in Ollscoileanna

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Sábhárlacht Dhigiteach — Na Ceithre Cholún

- **Sábhárlacht Bhonagair** 🖥️
  Freastalaithe agus líonraí a oibriú go neamhspleách
- **Sábhárlacht Sonraí** 💾
  Rialú ar stóráil agus rochtain sonraí
- **Sábhárlacht Bhogearraí** 💻
  Bogearraí foinse oscailte gan spleáchais phríobháideacha
- **Sábhárlacht Oibriúcháin** 🔧
  Rialú iomlán ar nuashonruithe agus cothabháil

---

# Cad é openDesk?

- **Rogha foinse oscailte** do M365 agus Google Workspace 🐧
- **Ag an Rialtas don Rialtas** (BMI / ZenDiS) 🏛️
- **Deimhnithe ag BSI** (sábhárlacht na Gearmáine) 📜
- **Bunaithe ar scamall:** Ionad oibre bunaithe ar Kubernetes ☁️
- **Comhpháirteanna modúlacha:**
  - Comhrá, Comhaid, Vicipéid, Bainistíocht tionscadail
  - Ríomhphost, Léaráidí, Oifig gréasáin, Fís
- **Óstáilte féin** nó **SaaS** 🖥️

---

# Forbhreathnú na gComhpháirteanna

| Comhpháireann | Bogearraí |
|------------|----------|
| Comhrá 💬 | Element / Synapse |
| Comhaid ☁️ | Nextcloud |
| Vicipéid 📖 | XWiki |
| Tionscadal ✅ | OpenProject |
| Ríomhphost ✉️ | OX App Suite |
| Léaráidí 📊 | CryptPad |
| Oifig gréasáin 📄 | Collabora |
| Fís 📹 | Jitsi |

---

# Staitisticí Tionscadail openDesk

**Forbairt** 🔀              | **Pobal** 👥
--------------------------------|---------------------------
Tús: Iúil 2023               | Rannpháirtitheoirí: ~ 70
Fad: ~ 3 bliana              | Eagraíochtaí: ~ 27
Commitanna: ~ 1,500           |
Eisiúintí: ~ 150              |

**OpenCode.de** 🛡️              | **Slabhra Soláthair** 🔒
 ardán maoinithe ag BMI     | Íomhánna coimeádáin sínithe
 Bonagair scamall sábháilte  | SBOM do gach comhpháireann

---

# Forbhreathnú Bonagair

| Tomhas | Luach |
|--------|------|
| **Nóidíní** | 9 (3 Rialaithe + 6 Oibrithe) |
| **Dáileadh** | K3s v1.32.3 |
| **Córas** | Debian 12 |
| **CPU (Íoslaghad)** | 16 croí |
| **RAM (Íoslaghad)** | 64 GB |
| **Stóráil** | 4+ TB Ceph |

---

# Fíorú le Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile agus Timpeallacht HRZ

```bash
# Seoladh le Helmfile
helmfile apply -e hrz
```

- **Orceadrú Helmfile** ⚓
  - Cumraíocht fhógrach i `helmfile_generic.yaml.gotmpl`
  - Sárú sonrach don timpeallacht i `environments/hrz/`
  - Cúltaca spleáchais uathoibríoch
- **Timpeallacht HRZ cruthaithe** 🖥️
  - Cóip de `staging` le coigeartuithe
  - Cumraíocht shonrach don Ollscoil Marburg
  - Córas tástála don oibriú píolóta

---

# Forbairt Chart Áitiúil

```bash
# Clónáil/pull chartanna go háitiúil
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Forbairt agus Tástáil Chart Áitiúil** 💻
- **Clónáil/pull i charts-<branch>/** ⬇️
- **Tagairtí Helmfile do chosáin áitiúla** 📄
- **Cúltaca agus Aisghairm le --revert** ↩️

---

# Iompórtáil Úsáideoirí: Soláthar

- **UDM REST API** — Iompórtáil CSV/ODS, grúpaí LDAP 👤
- **Nascadh Cuntais** — Nascadh aitheantais SAML 🔗
- **Mód Taispeána** — Cuntais tástála, grianghraif phróifíle 🖼️

---

# Iompórtáil Úsáideoirí: Dísholáthar

**Próiseas Dísholáthair dhá chéim:**

- **1ú Céim: Úsáideoir a Dhíchumasú**
  - IAM API → UCS Dhíchumasú → Stampa ama sa tuairisc
  - Keycloak: SAML a bhaint + grúpaí a scaipeadh
- **2ú Céim: Úsáideoir a Scriosadh**
  - Tréimhse grá (6 mhí) → Scriosadh buan
  - Aschur: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Forbhreathnú

- **Síneadh openDesk CE** do ollscoileanna 🏫
- **Comhpháirteanna Nua:**
  - Córais Bainistíochta Foghlama (ILIAS, Moodle)
  - Comhdhálacha Físe don Mhúinteoireacht (BigBlueButton)
  - Sync Comhad Malartach (OpenCloud)
- **Gach ceann integráilte le Keycloak SSO** 🔐
- **Gach rud a sheoladh le `helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)

---

# 📚 Comhpháirteanna Oideachaisúla

| Comhpháireann | Stádas | Cur Síos |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Cobhsaí | LMS le SAML SSO — Cúrsaí, SCORM, Tástálacha |
| 📖 Moodle | 🔄 Beta | LMS le Shibboleth — Breiseáin, Leabhar Grád |
| 🎥 BigBlueButton | 🔄 Beta | Comhdhálacha físe don mhúinteoireacht — Taifeadadh, Fán Bán |
| ☁️ OpenCloud | 🔄 Beta | Sync comhad bunaithe ar CS3 — Rogha eile do Nextcloud |

---

# 🔐 ILIAS SSO — Ailtireacht

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**Próiseas SSO 6 chéim:**

1. 🖥️ Portál → Téil ILIAS
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Logáil isteach (weblogin.uni-marburg.de)
5. 📨 Dearbhú SAML ar ais
6. ✅ Painéal ILIAS

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 Seoladh ILIAS — Ceachtanna Foghlamtha

| Fadhb | Réiteach |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat in easnamh in attribute-map.xml |
| Ainmneanna tréithe mícheart | Uni-IdP a sheolann `givenname`/`surname` |
| `handlerSSL` → 404 | TLS inmheánach: Apache SSL ar phort 8443 (v5) |
| Cuntais díchumasaithe | `shib_activate_new = 0` |
| Teorainn ama SAML | 60s → 300s |
| Seiceáil Sláinte | CronJob: curl Atreo-SSO (go uair an chloig) |

---

# 🚀 Tús Tapa - Seoladh i 3 Chéim

```bash
# 1. Clónáil an stór
git clone https://github.com/opendesk-edu/deployment.git
cd opendesk-edu

# 2. Cumraigh do thimpeallacht
# Cuir in eagar helmfile/environments/default/global.yaml.gotmpl
# Socraigh do fearann, fearann ríomhphoist, agus reigistear íomhánna

# 3. Seoladh
helmfile -e default apply
```

📖 Doiciméadú iomlán: [docs/getting-started.md](https://github.com/opendesk-edu/deployment/blob/main/docs/getting-started.md)

---

# Cumraíocht Líonra

- **Rialaitheoir Ingress:** haproxy-ingress
- **Seachfhreastalaí:** Traefik — Críochú HTTP/HTTPS 🔄
- **LoadBalancer:** MetalLB
- **Gach Ingress** aistrithe go haproxy ✅

---

# Painéal Grafana

![height:500px](media/grafana.png)

---

# Próiseas Nuashonraithe

```bash
# Luchtaigh eisiúintí is déanaí
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Athbhreithniú na n-athruithe
helmfile diff -e hrz

# Cuir na nuashonruithe i bhfeidhm
helmfile apply -e hrz

# Aisghairm más gá
helmfile rollback -e hrz
```

- **Nuashonruithe rialaithe tríd an Helmfile** 🔄
- **Cumais aisghairm éasca** ↩️

---

# Uasghrádú HRZ: Aistriú Ingress

- **Aistriú:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (brainse uniapps)
  - Gach Ingress aistrithe go haproxy ✅
- **Aicmeanna Ingress:**
  - `ingressClassName: haproxy`
  - nginx as feidhm go hiomlán
- **Cumraíocht:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# Uasghrádú HRZ: Cúltaca Dúbailte

- **Spriocanna:** Stóráil chúltaca iomadúil 🗄️
- **Straitéis:** Comhoiriúnach le SAML le cúl-taic restic 🔄
  - Bunscoth: `s3.example.org:9000/backup-primary`
  - Tánaisteach: `s3-backup.example.org:9000/backup-secondary`
- - **Sceideal:** Laethúil ag 00:42, Seiceáil seachtainiúil, Glanadh Dé Domhnaigh ⏰
- **Coinníoll:** 14 Laethúil, Coinneáil na 5 deireanacha 📦

---

# Bacainní Institiúideacha

- **Roinn Dlí** ⚖️
  - GDPR, conarthaí AVV, Comhlíonadh ceadúnas
- **Comhairle na dFostaithe** 👥
  - Comhaontú seirbhíse, Comhchinneáil do chórais IT
- **Riarachán** 🏢
  - Roghanna Microsoft, Comhoiriúnacht formáidí
- **Doiciméid Riachtanacha** 📄
  - DSFA, Ríomh TCO

---

# Chéad Chéimeanna Eile agus Moltaí

1. Tús a chur le hoibriú píolóta ▶️
2. Roll-amach céim ar chéim (10 → 100 → 1000 úsáideoir) 👥
3. Dealú soiléir ó chórais táirgeachta 🔗
4. Measúnú: Catagóirigh cásanna úsáide de réir riachtanais sábhárlachta ✅
5. Buiséad do fhoireann oibriúcháin (ní hamháin cur i bhfeidhm) 💰

---

# 🤝 Bí páirteach!

**Cabhraigh linn openDesk Edu a thógáil do ollscoileanna!**

- ⭐ **Réalt an stór:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)
- 🧪 **Tástáil go háitiúil:** Seoladh le Helmfile agus tabhair aiseolas
- 🐛 **Tuairiscigh fadhbanna:** Issues le haghaidh fabhtanna nó iarratais ghnéithe
- 💻 **Rannchuidiú:** PRs fáilte — féach CONTRIBUTING.md

**Déanamis bogearraí ollscoile sábháilte le chéile!** 🎓

---

# Acmhainní Teicniúla

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment) · Síneadh oideachaisúil do ollscoileanna
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Uathoibriú Cluster:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Acmhainní Eagraíocha

- **Moladh HBDI (Measúnú M365):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it_node.html)
- **Sábhárlacht Dhigiteach in Ollscoileanna:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

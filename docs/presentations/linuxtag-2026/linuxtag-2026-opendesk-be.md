---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)




# 🏛️ openDesk: Зручны і Суверэнны?

🎓 openDesk Edu — Лічбовая Суверэнасць ва Ўніверсітэтах

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Лічбовая Суверэнасць — Чатыры Слупы

- **Суверэнітэт Інфраструктуры** 🖥️
  Самастойнае кіраванне серверамі і сеткамі
- **Суверэнітэт Дадзеных** 💾
  Кантроль над захоўваннем і доступам да дадзеных
- **Суверэнітэт ПА** 💻
  Open-source ПА без уласніцкіх залежнасцей
- **Аперацыйны Суверэнітэт** 🔧
  Поўны кантроль над абнаўленнямі і абслугоўваннем

---

# Што такое openDesk?

- **Open-source альтэрнатыва** для M365 і Google Workspace 🐧
- **Ад урада для ўрада** (BMI / ZenDiS) 🏛️
- **Сертыфікавана BSI** (нямецкі суверэнітэт) 📜
- **Cloud-Native:** Працоўнае асяроддзе на базе Kubernetes ☁️
- **Модульныя Кампаненты:**
  - Чат, Файлы, Wiki, Кіраванне праектамі
  - Email, Дыяграмы, Web-офіс, Відэа
- **Self-Hosted** або **SaaS** 🖥️

---

# Агляд Кампанентаў

| Кампанент | ПА |
|------------|----------|
| Чат 💬 | Element / Synapse |
| Файлы ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Праект ✅ | OpenProject |
| Email ✉️ | OX App Suite |
| Дыяграмы 📊 | CryptPad |
| Web-офіс 📄 | Collabora |
| Відэа 📹 | Jitsi |

---

# Статыстыка Праекту openDesk

**Распрацоўка** 🔀              | **Супольнасць** 👥
--------------------------------|---------------------------
Пачатак: Ліпень 2023                | Удзельнікаў: ~ 70
Працягласць: ~ 3 гады           | Арганізацый: ~ 27
Камітаў: ~ 1,500                |
Рэлізаў: ~ 150                 |

**OpenCode.de** 🛡️              | **Ланцуг Пастаўак** 🔒
Платформа, фінансаваная BMI        | Падпісаныя вобразы кантэйнераў
Суверэнная воблачнае інфраструктура   | SBOM для ўсіх кампанентаў

---

# Агляд Інфраструктуры

| Метрыка | Значэнне |
|--------|------|
| **Вузлы** | 9 (3 Control-Plane + 6 Worker) |
| **Дыстрыбутыў** | K3s v1.32.3 |
| **АС** | Debian 12 |
| **CPU (Мінімум)** | 16 ядраў |
| **RAM (Мінімум)** | 64 ГБ |
| **Сховішча** | 4+ ТБ Ceph |

---

# Віртуалізацыя з Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile і HRZ-Асяроддзе

```bash
# Разгортанне з дапамогай Helmfile
helmfile apply -e hrz
```

- **Аркестрацыя Helmfile** ⚓
  - Дэкларатыўная канфігурацыя ў `helmfile_generic.yaml.gotmpl`
  - Перавызначэнні для канкрэтнага асяроддзя ў `environments/hrz/`
  - Аўтаматычнае рэзервовае капіяванне залежнасцей
- **HRZ-Асяроддзе створана** 🖥️
  - Копія `staging` з адаптацыямі
  - Канфігурацыя для Uni Marburg
  - Тэставая сістэма для пілотнай эксплуатацыі

---

# Лакальная Распрацоўка Chart-аў

```bash
# Кланаванне/pull chart-аў лакальна
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Лакальная распрацоўка і тэсціраванне Chart-аў** 💻
- **Clone/pull у charts-<branch>/** ⬇️
- **Спасылкі Helmfile на лакальныя шляхі** 📄
- **Рэзервовае капіраванне і адкат з дапамогай --revert** ↩️

---

# User-Import: Provisioning

- **UDM REST API** — Імпарт CSV/ODS, LDAP групы 👤
- **Прывязка Абліковых Запісаў** — Прывязка SAML-ідэнтычнасці 🔗
- **Дэма-рэжым** — Тэставыя абліковыя запісы, фота профілю 🖼️

---

# User-Import: Deprovisioning

**Двухфазны Рабочы Працэс Deprovisioning:**

- **Фаза 1: Адключэнне Карыстальніка**
  - IAM API → UCS Disable → Timestamp у Апісанні
  - Keycloak: Выдаліць SAML + распусціць групы
- **Фаза 2: Выдаленне Карыстальніка**
  - Перыяд чакання (6 месяцаў) → Пастаяннае выдаленне
  - Вывад: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Агляд

- **Пашырэнне openDesk CE** для ўніверсітэтаў 🏫
- **Новыя Кампаненты:**
  - Сістэмы Кіравання Навучаннем (ILIAS, Moodle)
  - Відэаканферэнцыі для Навучання (BigBlueButton)
  - Альтэрнатыўная Сінхранізацыя Файлаў (OpenCloud)
- **Усё інтэгравана з Keycloak SSO** 🔐
- **Разгарнуць усё з дапамогай `helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)

---

# 📚 Адукацыйныя Кампаненты

| Кампанент | Статус | Апісанне |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Стабільны | LMS з SAML SSO — Курсы, SCORM, Тэсты |
| 📖 Moodle | 🔄 Бэта | LMS з Shibboleth — Плагіны, Заліковая кніжка |
| 🎥 BigBlueButton | 🔄 Бэта | Відэаканферэнцыі для навучання — Запіс, Дошка |
| ☁️ OpenCloud | 🔄 Бэта | Сінхранізацыя файлаў на базе CS3 — Альтэрнатыва Nextcloud |

---

# 🔐 ILIAS SSO — Архітэктура

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**SSA Паток з 6 Крокаў:**

1. 🖥️ Портал → ILIAS tile
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Уваход (weblogin.uni-marburg.de)
5. 📨 SAML Assertion назад
6. ✅ ILIAS Dashboard

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 ILIAS Deployment — Вынікі з Досведу

| Праблема | Рашэнне |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat адсутнічае ў attribute-map.xml |
| Неправільныя імёны атрыбутаў | Uni-IdP адпраўляе `givenname`/`surname` |
| `handlerSSL` → 404 | Унутраны TLS: Apache SSL на порце 8443 (v5) |
| Абліковыя запісы адключаныя | `shib_activate_new = 0` |
| SAML Тайм-аўт | 60с → 300с |
| Health Check | CronJob: curl SSO-Redirect (штогадзіну) |

---

# 🚀 Quick Start — Разгарнуць за 3 Крокі

```bash
# 1. Кланаванне рэпазіторыя
git clone https://github.com/opendesk-edu/deployment.git
cd opendesk-edu

# 2. Наладзьце сваё асяроддзе
# Адрэдагуйце helmfile/environments/default/global.yaml.gotmpl
# Укажыце свой дамен, паштовы дамен і рэестр вобразаў

# 3. Разгарніце
helmfile -e default apply
```

📖 Поўная дакументацыя: [docs/getting-started.md](https://github.com/opendesk-edu/deployment/blob/main/docs/getting-started.md)

---

# Канфігурацыя Сеткі

- **Ingress Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — HTTP/HTTPS завяршэнне 🔄
- **LoadBalancer:** MetalLB
- **Усе Ingress-ы** міграваныя на haproxy ✅

---

# Grafana Dashboard

![height:500px](media/grafana.png)

---

# Працэс Абнаўлення

```bash
# Загрузіць апошнія рэлізы
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Праглядзець змены
helmfile diff -e hrz

# Ужыць абнаўленні
helmfile apply -e hrz

# Адкат пры неабходнасці
helmfile rollback -e hrz
```

- **Кантролюемыя абнаўленні праз Helmfile** 🔄
- **Лёгкі адкат** ↩️

---

# HRZ-Upgrade: Міграцыя Ingress

- **Міграцыя:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (галіна uniapps)
  - Усе Ingress-ы міграваныя на haproxy ✅
- **Класы Ingress:**
  - `ingressClassName: haproxy`
  - nginx цалкам састарэў
- **Канфігурацыя:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Upgrade: Двайное Рэзервовае Капіяванне

- **Мэты:** Рэзервовае Сховішча з Лішкам 🗄️
- **Стратэгія:** S3-сумяшчальнае з restic бэкендам 🔄
  - Першаснае: `s3.example.org:9000/backup-primary`
  - Другаснае: `s3-backup.example.org:9000/backup-secondary`
- **Расклад:** Штодзённа а 00:42, Праверка штотыдзень, Ачыстка ў нядзелю ⏰
- **Захаванне:** 14 Штодзённых, Захаваць Апошнія 5 📦

---

# Інстытуцыйныя Перашкоды

- **Юрыдычны Аддзел** ⚖️
  - GDPR, AVV кантракты, Выкананне ліцэнзій
- **Савет Працоўнікаў** 👥
  - Пагадненне аб паслугах, Супрацоўніцтва ў IT-сістэмах
- **Адміністрацыя** 🏢
  - Перавагі Microsoft, Сумяшчальнасць фарматаў
- **Неабходныя Дакументы** 📄
  - DSFA, разлік TCO

---

# Наступныя Крокі і Рэкамендацыі

1. Пачаць пілотную эксплуатацыю ▶️
2. Паэтапнае ўкараненне (10 → 100 → 1000 карыстальнікаў) 👥
3. Яўнае аддзяленне ад прадакшн-сістэм 🔗
4. Ацэнка: Класіфікаваць выпадкі выкарыстання па патрабаваннях суверэнітэту ✅
5. Бюджэт на аперацыйную каманду (не толькі ўкараненне) 💰

---

# 🤝 Далучайцеся!

**Дапамажыце нам стварыць openDesk Edu для ўніверсітэтаў!**

- ⭐ **Пастаўце зорку рэпазіторыя:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)
- 🧪 **Тэсціруйце лакальна:** Разгарніце з дапамогай Helmfile і дайце водгук
- 🐛 **Паведамляйце аб праблемах:** Issues для багаў або запытаў функцый
- 💻 **Унесіце свой уклад:** PR-ы вітаюцца — гл. CONTRIBUTING.md

**Стварым суверэннае ўніверсітэцкае ПА разам!** 🎓

---

# Тэхнічныя Рэсурсы

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment) · Адукацыйнае пашырэнне для ўніверсітэтаў
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Cluster-Automation:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Арганізацыйныя Рэсурсы

- **Рэкамендацыя HBDI (Ацэнка M365):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Лічбовая Суверэнасць ва Ўніверсітэтах:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

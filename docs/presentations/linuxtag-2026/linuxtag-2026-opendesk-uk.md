---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)




# 🏛️ openDesk: Зручний та Суверенний?

🎓 openDesk Edu — Цифрова Суверенність в Університетах

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Цифрова Суверенність — Чотири Стовпи

- **Суверенітет Інфраструктури** 🖥️
  Самостійне управління серверами та мережами
- **Суверенітет Даних** 💾
  Контроль над зберіганням та доступом до даних
- **Суверенітет ПЗ** 💻
  Open-source ПЗ без власницьких залежностей
- **Операційний Суверенітет** 🔧
  Повний контроль над оновленнями та обслуговуванням

---

# Що таке openDesk?

- **Open-source альтернатива** для M365 та Google Workspace 🐧
- **Від уряду для уряду** (BMI / ZenDiS) 🏛️
- **Сертифіковано BSI** (німецький суверенітет) 📜
- **Cloud-Native:** Робоче середовище на базі Kubernetes ☁️
- **Модульні Компоненти:**
  - Чат, Файли, Wiki, Управління проектами
  - Email, Діаграми, Web-офіс, Відео
- **Self-Hosted** або **SaaS** 🖥️

---

# Огляд Компонентів

| Компонент | ПЗ |
|------------|----------|
| Чат 💬 | Element / Synapse |
| Файли ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Проект ✅ | OpenProject |
| Email ✉️ | OX App Suite |
| Діаграми 📊 | CryptPad |
| Web-офіс 📄 | Collabora |
| Відео 📹 | Jitsi |

---

# Статистика Проєкту openDesk

**Розробка** 🔀              | **Спільнота** 👥
--------------------------------|---------------------------
Початок: Липень 2023                | Контриб'юторів: ~ 70
Тривалість: ~ 3 роки           | Організацій: ~ 27
Комітів: ~ 1,500                |
Релізів: ~ 150                 |

**OpenCode.de** 🛡️              | **Ланцюг Постачання** 🔒
Платформа, фінансована BMI        | Підписані образи контейнерів
Суверенна хмарна інфраструктура   | SBOM для всіх компонентів

---

# Огляд Інфраструктури

| Метрика | Значення |
|--------|------|
| **Вузли** | 9 (3 Control-Plane + 6 Worker) |
| **Дистрибутив** | K3s v1.32.3 |
| **ОС** | Debian 12 |
| **CPU (Мінімум)** | 16 ядер |
| **RAM (Мінімум)** | 64 ГБ |
| **Сховище** | 4+ ТБ Ceph |

---

# Віртуалізація з Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile та HRZ-Середовище

```bash
# Розгортання за допомогою Helmfile
helmfile apply -e hrz
```

- **Оркестрація Helmfile** ⚓
  - Декларативна конфігурація в `helmfile_generic.yaml.gotmpl`
  - Перевизначення для конкретного середовища в `environments/hrz/`
  - Автоматичне резервне копіювання залежностей
- **HRZ-Середовище створено** 🖥️
  - Копія `staging` з адаптаціями
  - Конфігурація для Uni Marburg
  - Тестова система для пілотної експлуатації

---

# Локальна Розробка Chart-ів

```bash
# Клонування/pull chart-ів локально
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Локальна розробка та тестування Chart-ів** 💻
- **Clone/pull в charts-<branch>/** ⬇️
- **Посилання Helmfile на локальні шляхи** 📄
- **Резервне копіювання та відкат за допомогою --revert** ↩️

---

# User-Import: Provisioning

- **UDM REST API** — Імпорт CSV/ODS, LDAP групи 👤
- **Прив'язка Облікових Записів** — Прив'язка SAML-ідентичності 🔗
- **Демо-режим** — Тестові облікові записи, фото профілю 🖼️

---

# User-Import: Deprovisioning

**Двофазний Робочий Процес Deprovisioning:**

- **Фаза 1: Вимкнення Користувача**
  - IAM API → UCS Disable → Timestamp в Описі
  - Keycloak: Видалити SAML + розпустити групи
- **Фаза 2: Видалення Користувача**
  - Період очікування (6 місяців) → Постійне видалення
  - Вивід: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Огляд

- **Розширення openDesk CE** для університетів 🏫
- **Нові Компоненти:**
  - Системи Управління Навчанням (ILIAS, Moodle)
  - Відеоконференції для Навчання (BigBlueButton)
  - Альтернативна Синхронізація Файлів (OpenCloud)
- **Все інтегровано з Keycloak SSO** 🔐
- **Розгорнути все за допомогою `helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)

---

# 📚 Освітні Компоненти

| Компонент | Статус | Опис |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Стабільний | LMS з SAML SSO — Курси, SCORM, Тести |
| 📖 Moodle | 🔄 Бета | LMS з Shibboleth — Плагіни, Залікова книжка |
| 🎥 BigBlueButton | 🔄 Бета | Відеоконференції для навчання — Запис, Дошка |
| ☁️ OpenCloud | 🔄 Бета | Синхронізація файлів на базі CS3 — Альтернатива Nextcloud |

---

# 🔐 ILIAS SSO — Архітектура

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**SSO Потік з 6 Кроків:**

1. 🖥️ Портал → ILIAS tile
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Вхід (weblogin.uni-marburg.de)
5. 📨 SAML Assertion назад
6. ✅ ILIAS Dashboard

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 ILIAS Deployment — Висновки з Досвіду

| Проблема | Рішення |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat відсутній в attribute-map.xml |
| Неправильні імена атрибутів | Uni-IdP надсилає `givenname`/`surname` |
| `handlerSSL` → 404 | Внутрішній TLS: Apache SSL на порту 8443 (v5) |
| Облікові записи вимкнено | `shib_activate_new = 0` |
| SAML Тайм-аут | 60с → 300с |
| Health Check | CronJob: curl SSO-Redirect (щогодини) |

---

# 🚀 Quick Start — Розгорнути за 3 Кроки

```bash
# 1. Клонуйте репозиторій
git clone https://github.com/opendesk-edu/deployment.git
cd opendesk-edu

# 2. Налаштуйте своє середовище
# Відредагуйте helmfile/environments/default/global.yaml.gotmpl
# Вкажіть ваш домен, поштовий домен та реєстр образів

# 3. Розгорніть
helmfile -e default apply
```

📖 Повна документація: [docs/getting-started.md](https://github.com/opendesk-edu/deployment/blob/main/docs/getting-started.md)

---

# Конфігурація Мережі

- **Ingress Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — HTTP/HTTPS завершення 🔄
- **LoadBalancer:** MetalLB
- **Всі Ingress-и** мігровані на haproxy ✅

---

# Grafana Dashboard

![height:500px](media/grafana.png)

---

# Процес Оновлення

```bash
# Завантажити останні релізи
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Переглянути зміни
helmfile diff -e hrz

# Застосувати оновлення
helmfile apply -e hrz

# Відкат за потреби
helmfile rollback -e hrz
```

- **Контрольовані оновлення через Helmfile** 🔄
- **Легкий відкат** ↩️

---

# HRZ-Upgrade: Міграція Ingress

- **Міграція:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (гілка uniapps)
  - Всі Ingress-и мігровані на haproxy ✅
- **Класи Ingress:**
  - `ingressClassName: haproxy`
  - nginx повністю застарів
- **Конфігурація:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Upgrade: Двоїсте Резервне Копіювання

- **Цілі:** Резервне Сховище з Надмірністю 🗄️
- **Стратегія:** S3-сумісне з restic бекендом 🔄
  - Первинне: `s3.example.org:9000/backup-primary`
  - Вторинне: `s3-backup.example.org:9000/backup-secondary`
- **Розклад:** Щодня о 00:42, Перевірка щотижня, Чищення в неділю ⏰
- **Зберігання:** 14 Щоденних, Зберегти Останні 5 📦

---

# Інституційні Перешкоди

- **Юридичний Відділ** ⚖️
  - GDPR, AVV контракти, Дотримання ліцензій
- **Рада Працівників** 👥
  - Угода про послуги, Співучасть в IT-системах
- **Адміністрація** 🏢
  - Переваги Microsoft, Сумісність форматів
- **Необхідні Документи** 📄
  - DSFA, розрахунок TCO

---

# Наступні Кроки та Рекомендації

1. Розпочати пілотну експлуатацію ▶️
2. Поетапне впровадження (10 → 100 → 1000 користувачів) 👥
3. Чітке відокремлення від продакшн-систем 🔗
4. Оцінка: Класифікувати випадки використання за вимогами суверенітету ✅
5. Бюджет на операційну команду (не лише впровадження) 💰

---

# 🤝 Долучайтеся!

**Допоможіть нам створити openDesk Edu для університетів!**

- ⭐ **Поставте зірку репозиторію:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)
- 🧪 **Тестуйте локально:** Розгорніть за допомогою Helmfile та надайте відгук
- 🐛 **Повідомляйте про проблеми:** Issues для багів або запитів функцій
- 💻 **Внесіть свій внесок:** PR-и вітаються — див. CONTRIBUTING.md

**Створімо суверенне університетське ПЗ разом!** 🎓

---

# Технічні Ресурси

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment) · Освітнє розширення для університетів
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Cluster-Automation:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Організаційні Ресурси

- **Рекомендація HBDI (Оцінка M365):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Цифрова Суверенність в Університетах:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

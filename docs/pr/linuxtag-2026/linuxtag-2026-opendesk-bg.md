---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)

# 🏛️ openDesk: Удобен и Суверенен?

🎓 openDesk Edu — Дигитален Суверенитет в Университетите

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Дигитален Суверенитет — Четирите Стълба

- **Суверенитет на Инфраструктурата** 🖥️
  Самостоятелно управление на сървъри и мрежи
- **Суверенитет на Данните** 💾
  Контрол върху съхранението и достъпа до данни
- **Суверенитет на Софтуера** 💻
  Софтуер с отворен код без собственически зависимости
- **Оперативен Суверенитет** 🔧
  Пълен контрол върху актуализациите и поддръжката

---

# Какво е openDesk?

- **Алтернатива с отворен код** на M365 & Google Workspace 🐧
- **От Правителството за Правителството** (BMI / ZenDiS) 🏛️
- **Сертифицирано от BSI** (германски суверенитет) 📜
- **Cloud-Native:** Работно място на база Kubernetes ☁️
- **Модулни Компоненти:**
  - Чат, Файлове, Wiki, Управление на проекти
  - Имейл, Диаграми, Уеб офис, Видео
- **Self-Hosted** или **SaaS** 🖥️

---

# Преглед на Компонентите

| Компонент | Софтуер |
|------------|----------|
| Чат 💬 | Element / Synapse |
| Файлове ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Проекти ✅ | OpenProject |
| Имейл ✉️ | OX App Suite |
| Диаграми 📊 | CryptPad |
| Уеб офис 📄 | Collabora |
| Видео 📹 | Jitsi |

---

# Статистика на Проекта openDesk

**Разработка** 🔀              | **Общност** 👥
--------------------------------|---------------------------
Старт: Юли 2023                 | Сътрудници: ~ 70
Продължителност: ~ 3 години  | Организации: ~ 27
Commits: ~ 1 500                |
Издания: ~ 150                  |

**OpenCode.de** 🛡️              | **Верига на Доставките** 🔒
Платформа с финансиране от BMI  | Подписани образи на контейнери
Суверенна облачна инфраструктура | SBOM за всички компоненти

---

# Преглед на Инфраструктурата

| Показател | Стойност |
|--------|------|
| **Възли** | 9 (3 Control-Plane + 6 Worker) |
| **Дистрибуция** | K3s v1.32.3 |
| **ОС** | Debian 12 |
| **CPU (Минимум)** | 16 ядра |
| **RAM (Минимум)** | 64 GB |
| **Съхранение** | 4+ TB Ceph |

---

# Виртуализация с Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile & HRZ-Среда

```bash
# Разполагане с Helmfile
helmfile apply -e hrz
```

- **Оркестрация с Helmfile** ⚓
  - Декларативна конфигурация в `helmfile_generic.yaml.gotmpl`
  - Замествания специфични за средата в `environments/hrz/`
  - Автоматично архивиране на зависимости
- **Създадена HRZ-Среда** 🖥️
  - Копие на `staging` с корекции
  - Конфигурация специфична за Университет Marburg
  - Тестова система за пилотна експлоатация

---

# Локална Разработка на Chart-ове

```bash
# Клониране/изтегляне на chart-ове локално
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Локална разработка и тестване на chart-ове** 💻
- **Клониране/изтегляне в charts-<branch>/** ⬇️
- **Препратки на Helmfile към локални пътища** 📄
- **Архивиране и възстановяване с --revert** ↩️

---

# Внос на Потребители: Осигуряване

- **UDM REST API** — Внос CSV/ODS, LDAP групи 👤
- **Свързване на Профили** — Свързване на SAML идентичност 🔗
- **Демо Режим** — Тестови профили, снимки на профила 🖼️

---

# Внос на Потребители: Оттегляне на Осигуряването

**Работен Процес за Оттегляне в Две Фази:**

- **Фаза 1: Деактивиране на Потребител**
  - IAM API → UCS Деактивиране → Отпечатък на времето в Описанието
  - Keycloak: Премахване на SAML + разпускане на групи
- **Фаза 2: Изтриване на Потребител**
  - Период на благодат (6 месеца) → Постоянно изтриване
  - Резултат: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Преглед

- **Разширение на openDesk CE** за университети 🏫
- **Нови Компоненти:**
  - Системи за Управление на Обучението (ILIAS, Moodle)
  - Видеоконференции за Преподаване (BigBlueButton)
  - Алтернативна Синхронизация на Файлове (OpenCloud)
- **Всички интегрирани с Keycloak SSO** 🔐
- **Разполагане на всичко с `helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)

---

# 📚 Образователни Компоненти

| Компонент | Статус | Описание |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Стабилен | LMS с SAML SSO — Курсове, SCORM, Тестове |
| 📖 Moodle | 🔄 Beta | LMS с Shibboleth — Плъгини, Дневник на оценките |
| 🎥 BigBlueButton | 🔄 Beta | Видеоконференция за преподаване — Запис, Бяла дъска |
| ☁️ OpenCloud | 🔄 Beta | Синхронизация на файлове на база CS3 — Алтернатива на Nextcloud |

---

# 🔐 ILIAS SSO — Архитектура

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**SSO Процес в 6 Стъпки:**

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

<div style="font-size: 0.65em;">

# 🔧 Разполагане на ILIAS — Поуки

| Проблем | Решение |
|---------|---------|
| `Wrong Login or Password` | Липсва SAML NameFormat в attribute-map.xml |
| Неверни имена на атрибути | Uni-IdP изпраща `givenname`/`surname` |
| `handlerSSL` → 404 | Вътрешен TLS: Apache SSL на порт 8443 (v5) |
| Деактивирани профили | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Health Check | CronJob: curl SSO-Redirect (ежечасно) |

---

# 🚀 Бързо Начало - Разполагане в 3 Стъпки

```bash
# 1. Клонирайте хранилището
git clone https://github.com/opendesk-edu/opendesk-edu.git
cd opendesk-edu

# 2. Конфигурирайте вашата среда
# Редактирайте helmfile/environments/default/global.yaml.gotmpl
# Задайте вашия домейн, пощенски домейн и регистри на образи

# 3. Разполагане
helmfile -e default apply
```

📖 Пълна документация: [docs/getting-started.md](https://github.com/opendesk-edu/opendesk-edu/blob/main/docs/getting-started.md)

---

# Мрежова Конфигурация

- **Ingress Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — HTTP/HTTPS прекратяване 🔄
- **LoadBalancer:** MetalLB
- **Всички Ingress-и** мигрирани към haproxy ✅

---

# Grafana Табло

![height:500px](media/grafana.png)

---

# Процес на Актуализация

```bash
# Зареждане на последните издания
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Преглед на промените
helmfile diff -e hrz

# Прилагане на актуализациите
helmfile apply -e hrz

# Връщане при нужда
helmfile rollback -e hrz
```

- **Контролирани актуализации чрез Helmfile** 🔄
- **Лесно връщане** ↩️

---

# HRZ-Актуализация: Миграция на Ingress

- **Миграция:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (клон uniapps)
  - Всички Ingress-и мигрирани към haproxy ✅
- **Класове на Ingress:**
  - `ingressClassName: haproxy`
  - nginx напълно премахнат
- **Конфигурация:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Актуализация: Двойно Архивиране

- **Цели:** Резервно съхранение с излишъци 🗄️
- **Стратегия:** S3-съвместим с restic backend 🔄
  - Основен: `s3.example.org:9000/backup-primary`
  - Резервен: `s3-backup.example.org:9000/backup-secondary`
- **График:** Ежедневно в 00:42, Проверка седмично, Почистване в неделя ⏰
- **Съхранение:** 14 Дневни, Запазване на последните 5 📦

---

# Институционални Препятствия

- **Правен Отдел** ⚖️
  - GDPR, AVV договори, Спазване на лицензи
- **Съвет на Служителите** 👥
  - Споразумение за обслужване, Съучастие за ИТ системи
- **Администрация** 🏢
  - Предпочитания към Microsoft, Съвместимост на формати
- **Необходими Документи** 📄
  - DSFA, TCO изчисление

---

# Следващи Стъпки & Препоръки

1. Стартиране на пилотна експлоатация ▶️
2. Постепенно въвеждане (10 → 100 → 1000 потребителя) 👥
3. Ясно разделяне от производствени системи 🔗
4. Оценка: Категоризиране на случаите на употреба по изисквания за суверенитет ✅
5. Бюджет за операционен екип (не само за внедряване) 💰

---

# 🤝 Включете се

**Помогнете ни да изградим openDesk Edu за университетите!**

- ⭐ **Star хранилището:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)
- 🧪 **Тествайте локално:** Разполагайте с Helmfile и давайте обратна връзка
- 🐛 **Докладвайте проблеми:** Issues за бъгове или заявки за функционалности
- 💻 **Сътрудничете:** PR-та са добре дошли — вижте CONTRIBUTING.md

**Нека изградим заедно суверенен университетски софтуер!** 🎓

---

# Технически Ресурси

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu) · Образователно разширение за университети
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Cluster-Automation:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Организационни Ресурси

- **Препоръка на HBDI (Оценка на M365):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Дигитален Суверенитет в Университетите:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

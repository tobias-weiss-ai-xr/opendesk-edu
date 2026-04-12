---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)




# 🏛️ openDesk: Wygodny i Suwerenny?

🎓 openDesk Edu — Cyfrowa Suwerenność na Uniwersytetach

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Suwerenność Cyfrowa — Cztery Filary

- **Suwerenność Infrastrukturalna** 🖥️
  Niezależne zarządzanie serwerami i sieciami
- **Suwerenność Danych** 💾
  Kontrola nad przechowywaniem i dostępem do danych
- **Suwerenność Oprogramowania** 💻
  Oprogramowanie open-source bez zależności proprietarnych
- **Suwerenność Operacyjna** 🔧
  Pełna kontrola nad aktualizacjami i utrzymaniem

---

# Czym jest openDesk?

- **Otwarta alternatywa** dla M365 i Google Workspace 🐧
- **Przez rząd dla rządu** (BMI / ZenDiS) 🏛️
- **Certyfikowany przez BSI** (niemiecka suwerenność) 📜
- **Cloud-Native:** Oparte o Kubernetes środowisko pracy ☁️
- **Modułowe Komponenty:**
  - Czat, Pliki, Wiki, Zarządzanie projektami
  - E-mail, Diagramy, Biuro internetowe, Wideo
- **Self-Hosted** lub **SaaS** 🖥️

---

# Przegląd Komponentów

| Komponent | Oprogramowanie |
|-----------|----------------|
| Czat 💬 | Element / Synapse |
| Pliki ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projekt ✅ | OpenProject |
| E-mail ✉️ | OX App Suite |
| Diagramy 📊 | CryptPad |
| Biuro internetowe 📄 | Collabora |
| Wideo 📹 | Jitsi |

---

# Statystyki Projektu openDesk

| **Rozwój** 🔀              | **Społeczność** 👥
--------------------------------|---------------------------
Start: lipiec 2023             | Kontrybutorzy: ~ 70
Czas trwania: ~ 3 lata      | Organizacje: ~ 27
Commity: ~ 1 500               |
Wydania: ~ 150                 |

| **OpenCode.de** 🛡️          | **Łańcuch Dostaw** 🔒
Platforma finansowana przez BMI | Podpisane obrazy kontenerów
Suwerenna infrastruktura chmurowa | SBOM dla wszystkich komponentów

---

# Przegląd Infrastruktury

| Metryka | Wartość |
|---------|---------|
| **Węzły** | 9 (3 Control-Plane + 6 Worker) |
| **Dystrybucja** | K3s v1.32.3 |
| **System operacyjny** | Debian 12 |
| **CPU (Minimum)** | 16 rdzeni |
| **RAM (Minimum)** | 64 GB |
| **Magazyn danych** | 4+ TB Ceph |

---

# Wirtualizacja z Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile & Środowisko HRZ

```bash
# Wdrożenie z Helmfile
helmfile apply -e hrz
```

- **Orkiestracja Helmfile** ⚓
  - Konfiguracja deklaratywna w `helmfile_generic.yaml.gotmpl`
  - Nadpisywania specyficzne dla środowiska w `environments/hrz/`
  - Automatyczna kopia zapasowa zależności
- **Środowisko HRZ utworzone** 🖥️
  - Kopia `staging` z dostosowaniami
  - Konfiguracja specyficzna dla Uni Marburg
  - System testowy dla operacji pilotażowej

---

# Lokalny Rozwój Chartów

```bash
# Klonuj/pobierz charty lokalnie
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Lokalny rozwój i testowanie chartów** 💻
- **Klonuj/pobierz w charts-<branch>/** ⬇️
- **Referencje Helmfile do ścieżek lokalnych** 📄
- **Kopia zapasowa i przywracanie z --revert** ↩️

---

# Import Użytkowników: Provisioning

- **UDM REST API** — import CSV/ODS, grupy LDAP 👤
- **Łączenie kont** — łączenie tożsamości SAML 🔗
- **Tryb demo** — konta testowe, zdjęcia profilowe 🖼️

---

# Import Użytkowników: Deprovisioning

**Dwufazowy proces deprovisioningu:**

- **Faza 1: Dezaktywacja użytkownika**
  - IAM API → UCS Disable → Znacznik czasu w opisie
  - Keycloak: Usuń SAML + rozwiąż grupy
- **Faza 2: Usunięcie użytkownika**
  - Okres karencji (6 miesięcy) → Trwałe usunięcie
  - Wynik: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Przegląd

- **Rozszerzenie openDesk CE** dla uniwersytetów 🏫
- **Nowe Komponenty:**
  - Systemy zarządzania uczeniem (ILIAS, Moodle)
  - Konferencje wideo do nauczania (BigBlueButton)
  - Alternatywna synchronizacja plików (OpenCloud)
- **Wszystko zintegrowane z Keycloak SSO** 🔐
- **Wdrażaj wszystko za pomocą `helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)

---

# 📚 Komponenty Edukacyjne

| Komponent | Status | Opis |
|-----------|--------|------|
| 📖 ILIAS | ✅ Stabilny | LMS z SAML SSO — Kursy, SCORM, Testy |
| 📖 Moodle | 🔄 Beta | LMS z Shibboleth — Wtyczki, Dziennik ocen |
| 🎥 BigBlueButton | 🔄 Beta | Konferencje wideo do nauczania — Nagrywanie, Tablica |
| ☁️ OpenCloud | 🔄 Beta | Synchronizacja plików oparta na CS3 — Alternatywa dla Nextcloud |

---

# 🔐 ILIAS SSO — Architektura

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**6-etapowy przepływ SSO:**

1. 🖥️ Portal → kafel ILIAS
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Logowanie (weblogin.uni-marburg.de)
5. 📨 Potwierdzenie SAML z powrotem
6. ✅ Panel ILIAS

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 Wdrożenie ILIAS — Doświadczenia

| Problem | Rozwiązanie |
|---------|-------------|
| `Wrong Login or Password` | Brak SAML NameFormat w attribute-map.xml |
| Nieprawidłowe nazwy atrybutów | Uni-IdP wysyła `givenname`/`surname` |
| `handlerSSL` → 404 | Wewnętrzny TLS: Apache SSL na porcie 8443 (v5) |
| Konta wyłączone | `shib_activate_new = 0` |
| Timeout SAML | 60s → 300s |
| Sprawdzanie kondycji | CronJob: curl SSO-Redirect (co godzinę) |

---

# 🚀 Szybki Start — Wdrożenie w 3 krokach

```bash
# 1. Klonuj repozytorium
git clone https://github.com/opendesk-edu/deployment.git
cd opendesk-edu

# 2. Skonfiguruj swoje środowisko
# Edytuj helmfile/environments/default/global.yaml.gotmpl
# Ustaw swoją domenę, domenę pocztową i rejestr obrazów

# 3. Wdróż
helmfile -e default apply
```

📖 Pełna dokumentacja: [docs/getting-started.md](https://github.com/opendesk-edu/deployment/blob/main/docs/getting-started.md)

---

# Konfiguracja Sieci

- **Kontroler Ingress:** haproxy-ingress
- **Odwrócony proxy:** Traefik — kończenie HTTP/HTTPS 🔄
- **LoadBalancer:** MetalLB
- **Wszystkie Ingressy** zmigrowane do haproxy ✅

---

# Panel Grafana

![height:500px](media/grafana.png)

---

# Proces Aktualizacji

```bash
# Załaduj najnowsze wydania
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Przejrzyj zmiany
helmfile diff -e hrz

# Zastosuj aktualizacje
helmfile apply -e hrz

# Wycofaj w razie potrzeby
helmfile rollback -e hrz
```

- **Kontrolowane aktualizacje przez Helmfile** 🔄
- **Łatwa możliwość wycofania** ↩️

---

# Aktualizacja HRZ: Migracja Ingress

- **Migracja:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (gałąź uniapps)
  - Wszystkie Ingressy zmigrowane do haproxy ✅
- **Klasa Ingress:**
  - `ingressClassName: haproxy`
  - nginx całkowicie wycofany
- **Konfiguracja:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# Aktualizacja HRZ: Podwójna Kopia Zapasowa

- **Cel:** Redundantny magazyn kopii zapasowych 🗄️
- **Strategia:** Kompatybilny z S3 z backendem restic 🔄
  - Podstawowy: `s3.example.org:9000/backup-primary`
  - Zapasowy: `s3-backup.example.org:9000/backup-secondary`
- **Harmonogram:** Codziennie o 00:42, Sprawdzanie co tydzień, Czyszczenie w niedziele ⏰
- **Retencja:** 14 dziennych, Zachowaj ostatnie 5 📦

---

# Bariery Instytucjonalne

- **Dział Prawny** ⚖️
  - RODO, umowy AVV, Zgodność licencyjna
- **Rada Pracownicza** 👥
  - Umowa o świadczeniu usług, Współdecydowanie w sprawach systemów IT
- **Administracja** 🏢
  - Preferencje Microsoftu, Zgodność formatów
- **Wymagane Dokumenty** 📄
  - DSFA, Obliczenia TCO

---

# Następne Kroki i Rekomendacje

1. Rozpocznij operację pilotażową ▶️
2. Stopniowe wdrażanie (10 → 100 → 1000 użytkowników) 👥
3. Wyraźne oddzielenie od systemów produkcyjnych 🔗
4. Ocena: Kategoryzacja przypadków użycia według wymagań suwerenności ✅
5. Budżet na zespół operacyjny (nie tylko na wdrożenie) 💰

---

# 🤝 Zaangażuj się!

**Pomóż nam budować openDesk Edu dla uniwersytetów!**

- ⭐ **Oznacz repo gwiazdką:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)
- 🧪 **Testuj lokalnie:** Wdróż za pomocą Helmfile i wyślij opinię
- 🐛 **Zgłaszaj problemy:** Issue dla błędów lub propozycji funkcji
- 💻 **Kontrybuuj:** PR mile widziane — zobacz CONTRIBUTING.md

**Zbudujmy razem suwerenne oprogramowanie uniwersyteckie!** 🎓

---

# Zasoby Techniczne

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment) · Rozszerzenie edukacyjne dla uniwersytetów
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Automatyzacja Klastra:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Zasoby Organizacyjne

- **Rekomendacja HBDI (ocena M365):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Suwerenność Cyfrowa na Uniwersytetach:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

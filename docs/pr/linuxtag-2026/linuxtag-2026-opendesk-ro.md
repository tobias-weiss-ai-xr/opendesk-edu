---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)

# 🏛️ openDesk: Confortabil și Suveran?

🎓 openDesk Edu — Suveranitate Digitală în Universități

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Suveranitatea Digitală — Cele Patru Piloni

- **Suveranitatea Infrastructurii** 🖥️
  Operarea independentă a serverelor și rețelelor
- **Suveranitatea Datelor** 💾
  Controlul asupra stocării și accesului la date
- **Suveranitatea Software-ului** 💻
  Software open-source fără dependențe proprietare
- **Suveranitatea Operațională** 🔧
  Control complet asupra actualizărilor și întreținerii

---

# Ce este openDesk?

- **Alternativă open-source** la M365 și Google Workspace 🐧
- **De la Guvern pentru Guvern** (BMI / ZenDiS) 🏛️
- **Certificat BSI** (suveranitate germană) 📜
- **Cloud-Nativ:** Loc de muncă bazat pe Kubernetes ☁️
- **Componente Modulare:**
  - Chat, Fișiere, Wiki, Management de proiecte
  - E-mail, Diagrame, Birou web, Video
- **Self-Hosted** sau **SaaS** 🖥️

---

# Prezentare Generală a Componentelor

| Componentă | Software |
|------------|----------|
| Chat 💬 | Element / Synapse |
| Fișiere ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Proiect ✅ | OpenProject |
| E-mail ✉️ | OX App Suite |
| Diagrame 📊 | CryptPad |
| Birou web 📄 | Collabora |
| Video 📹 | Jitsi |

---

# Statistici ale Proiectului openDesk

**Dezvoltare** 🔀              | **Comunitate** 👥
--------------------------------|---------------------------
Început: Iulie 2023              | Contribuitori: ~ 70
Durata: ~ 3 ani               | Organizații: ~ 27
Commit-uri: ~ 1.500             |
Lansări: ~ 150                  |

**OpenCode.de** 🛡️              | **Lanț de aprovizionare** 🔒
Platformă finanțată de BMI    | Imagini container semnate
Infrastructură cloud suverană   | SBOM pentru toate componentele

---

# Prezentare Generală a Infrastructurii

| Metrice | Valoare |
|--------|---------|
| **Noduri** | 9 (3 Control-Plane + 6 Worker) |
| **Distribuție** | K3s v1.32.3 |
| **SO** | Debian 12 |
| **CPU (Minim)** | 16 nuclee |
| **RAM (Minim)** | 64 GB |
| **Stocare** | 4+ TB Ceph |

---

# Virtualizare cu Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile și Mediul HRZ

```bash
# Implementare cu Helmfile
helmfile apply -e hrz
```

- **Orchestrare Helmfile** ⚓
  - Configurație declarativă în `helmfile_generic.yaml.gotmpl`
  - Suprascrieri specifice mediului în `environments/hrz/`
  - Backup automat al dependențelor
- **Mediul HRZ creat** 🖥️
  - Copie a `staging` cu ajustări
  - Configurație specifică Uni Marburg
  - Sistem de testare pentru operarea pilot

---

# Dezvoltare Locală de Chart-uri

```bash
# Clonare/pull chart-uri local
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Dezvoltare și Testare Locală de Chart-uri** 💻
- **Clonare/pull în charts-<branch>/** ⬇️
- **Referințe Helmfile către căi locale** 📄
- **Backup și Revenire cu --revert** ↩️

---

# Importul Utilizatorilor: Aprovizionare

- **UDM REST API** — import CSV/ODS, grupuri LDAP 👤
- **Conectarea Conturilor** — conectare identitate SAML 🔗
- **Modul Demo** — conturi de testare, poze de profil 🖼️

---

# Importul Utilizatorilor: Deprovozionare

**Flux de lucru de Deprovozionare în Două Faze:**

- **Faza 1: Dezactivarea Utilizatorului**
  - IAM API → UCS Disable → Timestamp în Descriere
  - Keycloak: Eliminare SAML + dizolvare grupuri
- **Faza 2: Ștergerea Utilizatorului**
  - Perioadă de grație (6 luni) → Ștergere permanentă
  - Rezultat: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Prezentare Generală

- **Extensie a openDesk CE** pentru universități 🏫
- **Componente Noi:**
  - Sisteme de Management al Învățării (ILIAS, Moodle)
  - Videoconferințe pentru Predare (BigBlueButton)
  - Sincronizare Alternativă de Fișiere (OpenCloud)
- **Toate integrate cu Keycloak SSO** 🔐
- **Implementează totul cu `helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)

---

# 📚 Componente Educaționale

| Componentă | Stare | Descriere |
|------------|-------|-----------|
| 📖 ILIAS | ✅ Stabil | LMS cu SAML SSO — Cursuri, SCORM, Teste |
| 📖 Moodle | 🔄 Beta | LMS cu Shibboleth — Plugin-uri, Catalog note |
| 🎥 BigBlueButton | 🔄 Beta | Videoconferințe pentru predare — Înregistrare, Tablă albă |
| ☁️ OpenCloud | 🔄 Beta | Sincronizare fișiere bazată pe CS3 — Alternativă la Nextcloud |

---

# 🔐 ILIAS SSO — Arhitectură

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**Flux SSO în 6 Pași:**

1. 🖥️ Portal → dala ILIAS
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Autentificare (weblogin.uni-marburg.de)
5. 📨 SAML Assertion înapoi
6. ✅ Panou ILIAS

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 Implementare ILIAS — Lecții Învățate

| Problemă | Soluție |
|----------|---------|
| `Wrong Login or Password` | NameFormat SAML lipsă în attribute-map.xml |
| Nume de atribute incorecte | Uni-IdP trimite `givenname`/`surname` |
| `handlerSSL` → 404 | TLS intern: Apache SSL pe portul 8443 (v5) |
| Conturi dezactivate | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Verificare Sănătate | CronJob: curl SSO-Redirect (în fiecare oră) |

---

# 🚀 Începere Rapidă - Implementare în 3 Pași

```bash
# 1. Clonați depozitul
git clone https://github.com/opendesk-edu/opendesk-edu.git
cd opendesk-edu

# 2. Configurați mediul dumneavoastră
# Editați helmfile/environments/default/global.yaml.gotmpl
# Setați domeniul, domeniul de e-mail și registrul de imagini

# 3. Implementați
helmfile -e default apply
```

📖 Documentație completă: [docs/getting-started.md](https://github.com/opendesk-edu/opendesk-edu/blob/main/docs/getting-started.md)

---

# Configurație de Rețea

- **Ingress Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — terminare HTTP/HTTPS 🔄
- **LoadBalancer:** MetalLB
- **Toate Ingress-urile** migrate la haproxy ✅

---

# Panou Grafana

![height:500px](media/grafana.png)

---

# Procesul de Actualizare

```bash
# Încărcați cele mai recente lansări
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Revizuiți modificările
helmfile diff -e hrz

# Aplicați actualizările
helmfile apply -e hrz

# Revenire dacă este necesar
helmfile rollback -e hrz
```

- **Actualizări controlate prin Helmfile** 🔄
- **Capacitate ușoară de revenire** ↩️

---

# Actualizare HRZ: Migrare Ingress

- **Migrare:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (ramura uniapps)
  - Toate Ingress-urile migrate la haproxy ✅
- **Clase Ingress:**
  - `ingressClassName: haproxy`
  - nginx complet depreciat
- **Configurație:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# Actualizare HRZ: Backup Dublu

- **Obiective:** Stocare de Backup Redundantă 🗄️
- **Strategie:** Compatibil S3 cu backend restic 🔄
  - Principal: `s3.example.org:9000/backup-primary`
  - Secundar: `s3-backup.example.org:9000/backup-secondary`
- **Program:** Zilnic la 00:42, Verificare săptămânală, Curățare duminicile ⏰
- **Reținere:** 14 Zilnice, Păstrează Ultimele 5 📦

---

# Obstacole Instituționale

- **Departamentul Juridic** ⚖️
  - GDPR, contracte AVV, Conformitate licențe
- **Consiliul Personalului** 👥
  - Acord de servicii, Codeterminare pentru sisteme IT
- **Administrație** 🏢
  - Preferințe Microsoft, Compatibilitate formate
- **Documente Necesare** 📄
  - DSFA, Calcul TCO

---

# Pași Următori și Recomandări

1. Începeți operarea pilot ▶️
2. Derulare eșalonată (10 → 100 → 1000 utilizatori) 👥
3. Separare clară de sistemele de producție 🔗
4. Evaluare: Clasificați cazurile de utilizare după cerințele de suveranitate ✅
5. Buget pentru echipa de operațiuni (nu doar implementare) 💰

---

# 🤝 Implicați-vă

**Ajutați-ne să construim openDesk Edu pentru universități!**

- ⭐ **Dați un Star depozitului:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)
- 🧪 **Testați local:** Implementați cu Helmfile și oferiți feedback
- 🐛 **Raportați probleme:** Issues pentru bug-uri sau cerințe de funcționalități
- 💻 **Contribuiți:** PR-urile sunt binevenite — vedeți CONTRIBUTING.md

**Să construim împreună software universitar suveran!** 🎓

---

# Resurse Tehnice

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Ghid-de-Implementare](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [Import-Utilizatori](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu) · Extensie educațională pentru universități
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Automatizare-Cluster:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Resurse Organizaționale

- **Recomandarea HBDI (Evaluare M365):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Suveranitatea Digitală la Universități:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

# openDesk: Comodo e Sovrano?

🎓 openDesk Edu — Sovranità Digitale nelle Università

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg · [https://mastodon.social/@graphwiz_ai](https://mastodon.social/@graphwiz_ai)

---

# Sovranità Digitale — I Quattro Pilastri

- **Sovranità Infrastrutturale** 🖥️
  Gestione autonoma di server e reti
- **Sovranità dei Dati** 💾
  Controllo sull'archiviazione e l'accesso ai dati
- **Sovranità del Software** 💻
  Software open source senza dipendenze proprietarie
- **Sovranità Operativa** 🔧
  Controllo completo su aggiornamenti e manutenzione

---

# Cos'è openDesk?

- **Alternativa open source** a M365 e Google Workspace 🐧
- **Dal governo per il governo** (BMI / ZenDiS) 🏛️
- **Certificato BSI** (sovranità tedesca) 📜
- **Cloud-Native:** Postazione di lavoro basata su Kubernetes ☁️
- **Componenti Modulari:**
  - Chat, File, Wiki, Gestione progetti
  - E-mail, Diagrammi, Suite ufficio web, Video
- **Self-Hosted** o **SaaS** 🖥️

---

# Panoramica dei componenti

| Componente | Software |
|------------|----------|
| Chat 💬 | Element / Synapse |
| File ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Progetto ✅ | OpenProject |
| E-mail ✉️ | OX App Suite |
| Diagrammi 📊 | CryptPad |
| Suite ufficio web 📄 | Collabora |
| Video 📹 | Jitsi |

---

# Statistiche del progetto openDesk

**Sviluppo** 🔀              | **Comunità** 👥
--------------------------------|---------------------------
Inizio: Luglio 2023                | Contributori: ~ 70
Durata: ~ 3 anni           | Organizzazioni: ~ 27
Commit: ~ 1.500                |
Versioni: ~ 150                 |

**OpenCode.de** 🛡️              | **Catena di approvvigionamento** 🔒
Piattaforma finanziata dal BMI        | Immagini container firmate
Infrastruttura cloud sovrana   | SBOM per tutti i componenti

---

# Panoramica dell'infrastruttura

| Metrica | Valore |
|--------|------|
| **Nodi** | 9 (3 Control-Plane + 6 Worker) |
| **Distribuzione** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Minimo)** | 16 core |
| **RAM (Minimo)** | 64 GB |
| **Archiviazione** | 4+ TB Ceph |

---

# Virtualizzazione con Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile & Ambiente HRZ

```bash
# Distribuzione con Helmfile
helmfile apply -e hrz
```

- **Orchestrazione Helmfile** ⚓
  - Configurazione dichiarativa in `helmfile_generic.yaml.gotmpl`
  - Override specifici per ambiente in `environments/hrz/`
  - Backup automatico delle dipendenze
- **Ambiente HRZ creato** 🖥️
  - Copia di `staging` con adattamenti
  - Configurazione specifica per l'Università di Marburg
  - Sistema di test per il funzionamento pilota

---

# Sviluppo locale dei Chart

```bash
# Clonare/scaricare i Chart localmente
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Sviluppo e test locali dei Chart** 💻
- **Clone/download in charts-<branch>/** ⬇️
- **Riferimenti Helmfile ai percorsi locali** 📄
- **Backup e ripristino con --revert** ↩️

---

# Importazione utenti: Provisioning

- **API REST UDM** — Importazione CSV/ODS, gruppi LDAP 👤
- **Collegamento account** — Collegamento identità SAML 🔗
- **Modalità demo** — Account di test, foto profilo 🖼️

---

# Importazione utenti: Deprovisioning

**Flusso di deprovisioning in due fasi:**

- **Fase 1: Disabilitare l'utente**
  - API IAM → UCS Disable → Timestamp nella descrizione
  - Keycloak: Rimuovere SAML + sciogliere i gruppi
- **Fase 2: Eliminare l'utente**
  - Periodo di grazia (6 mesi) → Cancellazione permanente
  - Output: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Panoramica

- **Estensione di openDesk CE** per le università 🏫
- **Nuovi componenti:**
  - Piattaforme di e-learning (ILIAS, Moodle)
  - Videoconferenza per la didattica (BigBlueButton)
  - Sincronizzazione file alternativa (OpenCloud)
- **Tutti integrati con Keycloak SSO** 🔐
- **Distribuire tutto con `helmfile apply`** ⚡

**GitHub:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)

---

# 📚 Componenti educativi

| Componente | Stato | Descrizione |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Stabile | LMS con SAML SSO — Corsi, SCORM, Test |
| 📖 Moodle | 🔄 Beta | LMS con Shibboleth — Plugin, Registro voti |
| 🎥 BigBlueButton | 🔄 Beta | Videoconferenza per la didattica — Registrazione, Lavagna bianca |
| ☁️ OpenCloud | 🔄 Beta | Sincronizzazione file basata su CS3 — Alternativa a Nextcloud |

---

# 🔐 ILIAS SSO — Architettura

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**Flusso SSO in 6 passaggi:**

1. 🖥️ Portale → Riquadro ILIAS
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Login (weblogin.uni-marburg.de)
5. 📨 Assertion SAML di ritorno
6. ✅ Dashboard ILIAS

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.85em;">

# 🔐 Distribuzione ILIAS — Lezioni apprese

| Problema | Soluzione |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat mancante in attribute-map.xml |
| Nomi attributi errati | Uni-IdP invia `givenname`/`surname` |
| `handlerSSL` → 404 | TLS interno: Apache SSL sulla porta 8443 (v5) |
| Account disabilitati | `shib_activate_new = 0` |
| Timeout SAML | 60 s → 300 s |
| Controllo integrità | CronJob: curl SSO-Redirect (ogni ora) |

---

# 🚀 Avvio rapido — Distribuzione in 3 passaggi

```bash
# 1. Clonare il repository
git clone https://github.com/tobias-weiss-ai-xr/opendesk-edu.git
cd opendesk-edu

# 2. Configurare il proprio ambiente
# Modificare helmfile/environments/default/global.yaml.gotmpl
# Impostare dominio, dominio e-mail e registry delle immagini

# 3. Distribuire
helmfile -e default apply
```

📖 Documentazione completa: [docs/getting-started.md](https://github.com/tobias-weiss-ai-xr/opendesk-edu/blob/main/docs/getting-started.md)

---

# Configurazione di rete

- **Ingress Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — Terminazione HTTP/HTTPS 🔄
- **LoadBalancer:** MetalLB
- **Tutti gli Ingress** migrati a haproxy ✅

---

# Dashboard Grafana

![height:500px](media/grafana.png)

---

# Processo di aggiornamento

```bash
# Caricare le ultime versioni
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Verificare le modifiche
helmfile diff -e hrz

# Applicare gli aggiornamenti
helmfile apply -e hrz

# Ripristinare se necessario
helmfile rollback -e hrz
```

- **Aggiornamenti controllati tramite Helmfile** 🔄
- **Facile capacità di ripristino** ↩️

---

# HRZ-Upgrade: Migrazione Ingress

- **Migrazione:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (ramo uniapps)
  - Tutti gli Ingress migrati a haproxy ✅
- **Classi Ingress:**
  - `ingressClassName: haproxy`
  - nginx completamente deprecato
- **Configurazione:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Upgrade: Backup duale

- **Obiettivi:** Archiviazione backup ridondante 🗄️
- **Strategia:** Compatibile S3 con backend restic 🔄
  - Primario: `s3.example.org:9000/backup-primary`
  - Secondario: `s3-backup.example.org:9000/backup-secondary`
- **Pianificazione:** Giornaliero alle 00:42, Controllo settimanale, Pulizia domenica ⏰
- **Conservazione:** 14 giornalieri, Mantenere gli ultimi 5 📦

---

# Ostacoli istituzionali

- **Ufficio legale** ⚖️
  - GDPR, contratti AVV, Conformità licenze
- **Consiglio del personale** 👥
  - Accordo di servizio, Codeterminazione per i sistemi IT
- **Amministrazione** 🏢
  - Preferenze Microsoft, Compatibilità formati
- **Documenti richiesti** 📄
  - DSFA, Calcolo TCO

---

# Prossimi passi & Raccomandazioni

1. Avviare il funzionamento pilota ▶️
2. Distribuzione graduale (10 → 100 → 1.000 utenti) 👥
3. Chiara separazione dai sistemi di produzione 🔗
4. Valutazione: Categorizzare i casi d'uso in base ai requisiti di sovranità ✅
5. Budget per il team operativo (non solo l'implementazione) 💰

---

# 🤝 Partecipate!

**Aiutateci a costruire openDesk Edu per le università!**

- ⭐ **Mettete una stella al repo:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)
- 🧪 **Testare localmente:** Distribuire con Helmfile e fornire feedback
- 🐛 **Segnalare problemi:** Issue per bug o richieste di funzionalità
- 💻 **Contribuire:** PR benvenute — vedere CONTRIBUTING.md

**Costruiamo insieme software sovrano per le università!** 🎓

---

# Risorse tecniche

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Guida alla distribuzione](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [Importazione utenti](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu) · Estensione educativa per le università
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Automazione cluster:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Risorse organizzative

- **Raccomandazione HBDI (Valutazione M365):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Patto digitale dell'Assia per le università:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Sovranità digitale nelle università:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

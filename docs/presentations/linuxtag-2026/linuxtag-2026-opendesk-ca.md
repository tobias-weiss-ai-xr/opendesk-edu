---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

# openDesk: Còmode i Sobirà?

🎓 openDesk Edu — Sobirania Digital a les Universitats

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg · [https://mastodon.social/@graphwiz_ai](https://mastodon.social/@graphwiz_ai)

---

# Sobirania Digital — Els Quatre Pilars

- **Sobirania d'Infraestructura** 🖥️
  Operar servidors i xarxes de manera independent
- **Sobirania de Dades** 💾
  Control sobre l'emmagatzematge i accés a les dades
- **Sobirania de Programari** 💻
  Programari de codi obert sense dependències propietàries
- **Sobirania Operativa** 🔧
  Control complet sobre actualitzacions i manteniment

---

# Què és openDesk?

- **Alternativa de codi obert** a M365 i Google Workspace 🐧
- **Per al Govern per al Govern** (BMI / ZenDiS) 🏛️
- **Certificat pel BSI** (sobirania alemanya) 📜
- **Cloud-Native:** Entorn de treball basat en Kubernetes ☁️
- **Components Modulares:**
  - Chat, Fitxers, Wiki, Gestió de projectes
  - Correu, Diagramas, Ofimàtica web, Vídeo
- **Autoallotjat** o **SaaS** 🖥️

---

# Visió General de Components

| Component | Software |
|------------|----------|
| Chat 💬 | Element / Synapse |
| Fitxers ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projecte ✅ | OpenProject |
| Correu ✉️ | OX App Suite |
| Diagramas 📊 | CryptPad |
| Ofimàtica web 📄 | Collabora |
| Vídeo 📹 | Jitsi |

---

# Estadístiques del Projecte openDesk

**Desenvolupament** 🔀              | **Comunitat** 👥
--------------------------------|---------------------------
Inici: Juliol 2023                | Col·laboradors: ~ 70
Durada: ~ 3 anys           | Organitzacions: ~ 27
Commits: ~ 1,500                |
Releases: ~ 150                 |

**OpenCode.de** 🛡️              | **Cadena de Subministre** 🔒
Plataforma finançada pel BMI        | Imatges de contenidor signades
Infraestructura de núvol sobirà   | SBOM per a tots els components

---

# Visió General de la Infraestructura

| Mètrica | Valor |
|--------|------|
| **Nodes** | 9 (3 Control-Plane + 6 Worker) |
| **Distribució** | K3s v1.32.3 |
| **SO** | Debian 12 |
| **CPU (Mínim)** | 16 nuclis |
| **RAM (Mínim)** | 64 GB |
| **Emmagatzematge** | 4+ TB Ceph |

---

# Virtualització amb Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile i Entorn HRZ

```bash
# Desplegament amb Helmfile
helmfile apply -e hrz
```

- **Orquestració amb Helmfile** ⚓
  - Configuració declarativa a `helmfile_generic.yaml.gotmpl`
  - Anul·lacions específiques de l'entorn a `environments/hrz/`
  - Còpia de seguretat automàtica de dependències
- **Entorn HRZ creat** 🖥️
  - Còpia de `staging` amb ajustos
  - Configuració específica de la Uni Marburg
  - Sistema de prova per a l'operació pilot

---

# Desenvolupament Local de Charts

```bash
# Clonar/actualitzar charts localment
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Desenvolupament i Prova Local de Charts** 💻
- **Clonar/actualitzar a charts-<branch>/** ⬇️
- **Referències de Helmfile a camins locals** 📄
- **Còpia de seguretat i Reversió amb --revert** ↩️

---

# Importació d'Usuaris: Aprovisionament

- **UDM REST API** — Importació CSV/ODS, grups LDAP 👤
- **Vinculació de Comptes** — Vinculació d'identitat SAML 🔗
- **Mode Demo** — Comptes de prova, fotos de perfil 🖼️

---

# Importació d'Usuaris: Desaprovisionament

**Flux de Treball de Desaprovisionament en Dues Fases:**

- **Fase 1: Deshabilitar Usuari**
  - IAM API → UCS Disable → Marca de temps a la Descripció
  - Keycloak: Eliminar SAML + dissoldre grups
- **Fase 2: Eliminar Usuari**
  - Període de gràcia (6 mesos) → Eliminació permanent
  - Sortida: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Visió General

- **Extensió de openDesk CE** per a universitats 🏫
- **Nous Components:**
  - Sistemes de Gestió de l'Aprenentatge (ILIAS, Moodle)
  - Videoconferència per a l'Ensenyament (BigBlueButton)
  - Sincronització de Fitxers Alternativa (OpenCloud)
- **Tot integrat amb Keycloak SSO** 🔐
- **Desplegar tot amb `helmfile apply`** ⚡

**GitHub:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)

---

# 📚 Components Educatius

| Component | Estat | Descripció |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Estable | LMS amb SSO SAML — Cursos, SCORM, Proves |
| 📖 Moodle | 🔄 Beta | LMS amb Shibboleth — Plugins, Llibre de qualificacions |
| 🎥 BigBlueButton | 🔄 Beta | Videoconferència per a l'ensenyament — Gravació, Pissarra |
| ☁️ OpenCloud | 🔄 Beta | Sincronització de fitxers basada en CS3 — Alternativa al Nextcloud |

---

# 🔐 SSO d'ILIAS — Arquitectura

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**Flux SSO en 6 Passos:**

1. 🖥️ Portal → Mosaic d'ILIAS
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Inici de sessió (weblogin.uni-marburg.de)
5. 📨 Asserció SAML de tornada
6. ✅ Panell d'ILIAS

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.85em;">

# 🔧 Desplegament d'ILIAS — Lliçons Apreses

| Problema | Solució |
|---------|---------|
| `Wrong Login or Password` | NameFormat SAML absent a attribute-map.xml |
| Noms d'atributs incorrectes | Uni-IdP envia `givenname`/`surname` |
| `handlerSSL` → 404 | TLS intern: Apache SSL al port 8443 (v5) |
| Comptes deshabilitats | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Comprovació d'Estat | CronJob: curl SSO-Redirect (cada hora) |

---

# 🚀 Inici Ràpid - Desplegar en 3 Passos

```bash
# 1. Clonar el repositori
git clone https://github.com/tobias-weiss-ai-xr/opendesk-edu.git
cd opendesk-edu

# 2. Configura el teu entorn
# Edita helmfile/environments/default/global.yaml.gotmpl
# Estableix el teu domini, domini de correu i registre d'imatges

# 3. Desplegar
helmfile -e default apply
```

📖 Documentació completa: [docs/getting-started.md](https://github.com/tobias-weiss-ai-xr/opendesk-edu/blob/main/docs/getting-started.md)

---

# Configuració de Xarxa

- **Ingress Controller:** haproxy-ingress
- **Proxy Invers:** Traefik — Finalització HTTP/HTTPS 🔄
- **LoadBalancer:** MetalLB
- **Tots els Ingress migrats a haproxy** ✅

---

# Panell del Grafana

![height:500px](media/grafana.png)

---

# Procés d'Actualització

```bash
# Carregar les darreres versions
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Revisar canvis
helmfile diff -e hrz

# Aplicar actualitzacions
helmfile apply -e hrz

# Revertir si cal
helmfile rollback -e hrz
```

- **Actualitzacions controlades mitjançant Helmfile** 🔄
- **Capacitat de reversió senzilla** ↩️

---

# Actualització HRZ: Migració d'Ingress

- **Migració:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (branca uniapps)
  - Tots els Ingress migrats a haproxy ✅
- **Classes d'Ingress:**
  - `ingressClassName: haproxy`
  - nginx completament deprecado
- **Configuració:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# Actualització HRZ: Còpia de Seguretat Dual

- **Objectius:** Emmagatzematge de Còpia de Seguretat Redundant 🗄️
- **Estratègia:** Compatible amb S3 amb backend restic 🔄
  - Primari: `s3.example.org:9000/backup-primary`
  - Secundari: `s3-backup.example.org:9000/backup-secondary`
- **Programació:** Diàriament a les 00:42, Comprovació setmanal, Poda els diumenges ⏰
- **Retenció:** 14 Diaris, Mantenir els últims 5 📦

---

# Obstacles Institucionals

- **Departament Jurídic** ⚖️
  - RGPD, contractes AVV, Compliment de llicències
- **Consell de Personal** 👥
  - Acord de servei, Co-determinació per a sistemes TI
- **Administració** 🏢
  - Preferències per Microsoft, Compatibilitat de formats
- **Documents Requerits** 📄
  - DSFA, Càlcul de TCO

---

# Propers Passos i Recomanacions

1. Iniciar l'operació pilot ▶️
2. Desplegament escalonat (10 → 100 → 1000 usuaris) 👥
3. Separació clara dels sistemes de producció 🔗
4. Avaluació: Categoritzar els casos d'ús segons els requisits de sobirania ✅
5. Pressupost per a l'equip d'operacions (no només la implementació) 💰

---

# 🤝 Participa!

**Ajuda'ns a construir openDesk Edu per a les universitats!**

- ⭐ **Dona una estrella al repositori:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)
- 🧪 **Prova localment:** Desplega amb Helmfile i proporciona feedback
- 🐛 **Informa de problemes:** Issues per a errors o sol·licituds de funcionalitats
- 💻 **Contribueix:** PRs benvinguts — consulta CONTRIBUTING.md

**Construeixem programari universitari sobirà junts!** 🎓

---

# Recursos Tècnics

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Guia de Desplegament](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [Importació d'Usuaris](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu) · Extensió educativa per a universitats
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Automatització de Clústers:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Recursos Organitzatius

- **Recomanació HBDI (Avaluació M365):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Sobirania Digital a les Universitats:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)

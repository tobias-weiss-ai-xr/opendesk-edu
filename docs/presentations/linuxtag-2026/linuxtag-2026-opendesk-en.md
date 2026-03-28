---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

# openDesk: Comfortable and Sovereign?

🎓 openDesk Edu — Digital Sovereignty at Universities

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg · [https://mastodon.social/@graphwiz_ai](https://mastodon.social/@graphwiz_ai)

---

# Digital Sovereignty — The Four Pillars

- **Infrastructure Sovereignty** 🖥️
  Operate servers and networks independently
- **Data Sovereignty** 💾
  Control over data storage and access
- **Software Sovereignty** 💻
  Open-source software without proprietary dependencies
- **Operational Sovereignty** 🔧
  Complete control over updates and maintenance

---

# What is openDesk?

- **Open-source alternative** to M365 & Google Workspace 🐧
- **By Government for Government** (BMI / ZenDiS) 🏛️
- **BSI-certified** (German sovereignty) 📜
- **Cloud-Native:** Kubernetes-based workplace ☁️
- **Modular Components:**
  - Chat, Files, Wiki, Project management
  - Email, Diagrams, Web office, Video
- **Self-Hosted** or **SaaS** 🖥️

---

# Component Overview

| Component | Software |
|------------|----------|
| Chat 💬 | Element / Synapse |
| Files ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Project ✅ | OpenProject |
| Email ✉️ | OX App Suite |
| Diagrams 📊 | CryptPad |
| Web office 📄 | Collabora |
| Video 📹 | Jitsi |

---

# openDesk Project Statistics

**Development** 🔀              | **Community** 👥
--------------------------------|---------------------------
Start: July 2023                | Contributors: ~ 70
Runtime: ~ 3 years           | Organizations: ~ 27
Commits: ~ 1,500                |
Releases: ~ 150                 |

**OpenCode.de** 🛡️              | **Supply Chain** 🔒
BMI-funded platform        | Signed container images
Sovereign cloud infrastructure   | SBOM for all components

---

# Infrastructure Overview

| Metric | Value |
|--------|------|
| **Nodes** | 9 (3 Control-Plane + 6 Worker) |
| **Distribution** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Minimum)** | 16 cores |
| **RAM (Minimum)** | 64 GB |
| **Storage** | 4+ TB Ceph |

---

# Virtualization with Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile & HRZ-Environment

```bash
# Deployment with Helmfile
helmfile apply -e hrz
```

- **Helmfile Orchestration** ⚓
  - Declarative configuration in `helmfile_generic.yaml.gotmpl`
  - Environment-specific overrides in `environments/hrz/`
  - Automatic dependency backup
- **HRZ-Environment created** 🖥️
  - Copy of `staging` with adjustments
  - Uni Marburg-specific configuration
  - Test system for pilot operation

---

# Local Chart Development

```bash
# Clone/pull charts locally
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Local Chart Development & Testing** 💻
- **Clone/pull in charts-<branch>/** ⬇️
- **Helmfile references to local paths** 📄
- **Backup & Revert with --revert** ↩️

---

# User-Import: Provisioning

- **UDM REST API** — CSV/ODS import, LDAP groups 👤
- **Account Linking** — SAML identity linking 🔗
- **Demo Mode** — Test accounts, profile pictures 🖼️

---

# User-Import: Deprovisioning

**Two-Phase Deprovisioning Workflow:**

- **Phase 1: Disable User**
  - IAM API → UCS Disable → Timestamp in Description
  - Keycloak: Remove SAML + dissolve groups
- **Phase 2: Delete User**
  - Grace Period (6 months) → Permanent deletion
  - Output: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Overview

- **Extension of openDesk CE** for universities 🏫
- **New Components:**
  - Learning Management Systems (ILIAS, Moodle)
  - Video Conferencing for Teaching (BigBlueButton)
  - Alternative File Sync (OpenCloud)
- **All integrated with Keycloak SSO** 🔐
- **Deploy everything with `helmfile apply`** ⚡

**GitHub:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)

---

# 📚 Educational Components

| Component | Status | Description |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Stable | LMS with SAML SSO — Courses, SCORM, Tests |
| 📖 Moodle | 🔄 Beta | LMS with Shibboleth — Plugins, Gradebook |
| 🎥 BigBlueButton | 🔄 Beta | Video conferencing for teaching — Recording, Whiteboard |
| ☁️ OpenCloud | 🔄 Beta | CS3-based file sync — Alternative to Nextcloud |

---

# 🔐 ILIAS SSO — Architecture

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**6-Step SSO Flow:**

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

<div style="font-size: 0.85em;">

# 🔧 ILIAS Deployment — Lessons Learned

| Problem | Solution |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat missing in attribute-map.xml |
| Attribute names incorrect | Uni-IdP sends `givenname`/`surname` |
| `handlerSSL` → 404 | Internal TLS: Apache SSL on port 8443 (v5) |
| Accounts disabled | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Health Check | CronJob: curl SSO-Redirect (hourly) |

---

# 🚀 Quick Start - Deploy in 3 Steps

```bash
# 1. Clone the repository
git clone https://github.com/tobias-weiss-ai-xr/opendesk-edu.git
cd opendesk-edu

# 2. Configure your environment
# Edit helmfile/environments/default/global.yaml.gotmpl
# Set your domain, mail domain, and image registry

# 3. Deploy
helmfile -e default apply
```

📖 Full documentation: [docs/getting-started.md](https://github.com/tobias-weiss-ai-xr/opendesk-edu/blob/main/docs/getting-started.md)

---

# Network Configuration

- **Ingress Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — HTTP/HTTPS termination 🔄
- **LoadBalancer:** MetalLB
- **All Ingresses** migrated to haproxy ✅

---

# Grafana Dashboard

![height:500px](media/grafana.png)

---

# Update Process

```bash
# Load latest releases
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Review changes
helmfile diff -e hrz

# Apply updates
helmfile apply -e hrz

# Rollback if needed
helmfile rollback -e hrz
```

- **Controlled updates via Helmfile** 🔄
- **Easy rollback capability** ↩️

---

# HRZ-Upgrade: Ingress Migration

- **Migration:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (uniapps branch)
  - All Ingresses migrated to haproxy ✅
- **Ingress Classes:**
  - `ingressClassName: haproxy`
  - nginx fully deprecated
- **Configuration:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Upgrade: Dual Backup

- **Goals:** Redundant Backup Storage 🗄️
- **Strategy:** S3-compatible with restic backend 🔄
  - Primary: `s3.example.org:9000/backup-primary`
  - Secondary: `s3-backup.example.org:9000/backup-secondary`
- **Schedule:** Daily at 00:42, Check weekly, Prune Sundays ⏰
- **Retention:** 14 Daily, Keep Last 5 📦

---

# Institutional Hurdles

- **Legal Department** ⚖️
  - GDPR, AVV contracts, License compliance
- **Staff Council** 👥
  - Service agreement, Co-determination for IT systems
- **Administration** 🏢
  - Microsoft preferences, Format compatibility
- **Required Documents** 📄
  - DSFA, TCO calculation

---

# Next Steps & Recommendations

1. Start pilot operation ▶️
2. Staggered rollout (10 → 100 → 1000 users) 👥
3. Clear separation from production systems 🔗
4. Evaluation: Categorize use cases by sovereignty requirements ✅
5. Budget for operations team (not just implementation) 💰

---

# 🤝 Get Involved!

**Help us build openDesk Edu for universities!**

- ⭐ **Star the repo:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)
- 🧪 **Test locally:** Deploy with Helmfile and provide feedback
- 🐛 **Report issues:** Issues for bugs or feature requests
- 💻 **Contribute:** PRs welcome — see CONTRIBUTING.md

**Let's build sovereign university software together!** 🎓

---

# Technical Resources

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu) · Educational extension for universities
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Cluster-Automation:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Organizational Resources

- **HBDI Recommendation (M365 Assessment):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Digital Sovereignty at Universities:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)
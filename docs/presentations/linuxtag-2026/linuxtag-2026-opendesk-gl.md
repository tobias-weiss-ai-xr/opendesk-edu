---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

# openDesk: Cómodo e Soberano?

🎓 openDesk Edu — Soberanía Dixital nas Universidades

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg · [https://mastodon.social/@graphwiz_ai](https://mastodon.social/@graphwiz_ai)

---

# Soberanía Dixital — Os Catro Alicerces

- **Soberanía de Infraestrutura** 🖥️
  Operar servidores e redes de forma independente
- **Soberanía de Datos** 💾
  Control sobre o almacenamento e acceso aos datos
- **Soberanía de Software** 💻
  Software de código aberto sen dependencias propietarias
- **Soberanía Operativa** 🔧
  Control completo sobre actualizacións e mantemento

---

# Que é openDesk?

- **Alternativa de código aberto** a M365 e Google Workspace 🐧
- **Polo Goberno para o Goberno** (BMI / ZenDiS) 🏛️
- **Certificado polo BSI** (soberanía alemá) 📜
- **Cloud-Native:** Entorno de traballo baseado en Kubernetes ☁️
- **Componentes Modulares:**
  - Chat, Ficheiros, Wiki, Xestión de proxectos
  - Correo, Diagramas, Oficina web, Vídeo
- **Autoaloxado** ou **SaaS** 🖥️

---

# Visión Xeral de Componentes

| Componente | Software |
|------------|----------|
| Chat 💬 | Element / Synapse |
| Ficheiros ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Proxecto ✅ | OpenProject |
| Correo ✉️ | OX App Suite |
| Diagramas 📊 | CryptPad |
| Oficina web 📄 | Collabora |
| Vídeo 📹 | Jitsi |

---

# Estatísticas do Proxecto openDesk

**Desenvolvemento** 🔀              | **Comunidade** 👥
--------------------------------|---------------------------
Inicio: Xullo 2023                | Colaboradores: ~ 70
Duración: ~ 3 anos           | Organizacións: ~ 27
Commits: ~ 1,500                |
Releases: ~ 150                 |

**OpenCode.de** 🛡️              | **Cadea de Subministros** 🔒
Plataforma financiada polo BMI        | Imaxes de contedor asinadas
Infraestrutura de nube soberana   | SBOM para todos os componentes

---

# Visión Xeral da Infraestrutura

| Métrica | Valor |
|--------|------|
| **Nodos** | 9 (3 Control-Plane + 6 Worker) |
| **Distribución** | K3s v1.32.3 |
| **SO** | Debian 12 |
| **CPU (Mínimo)** | 16 núcleos |
| **RAM (Mínimo)** | 64 GB |
| **Almacenamento** | 4+ TB Ceph |

---

# Virtualización con Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile e Entorno HRZ

```bash
# Despregue con Helmfile
helmfile apply -e hrz
```

- **Orquestración con Helmfile** ⚓
  - Configuración declarativa en `helmfile_generic.yaml.gotmpl`
  - Anulacións específicas do entorno en `environments/hrz/`
  - Copia de seguranza automática de dependencias
- **Entorno HRZ creado** 🖥️
  - Copia de `staging` con axustes
  - Configuración específica da Uni Marburg
  - Sistema de proba para a operación piloto

---

# Desenvolvemento Local de Charts

```bash
# Clonar/actualizar charts localmente
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Desenvolvemento e Proba Local de Charts** 💻
- **Clonar/actualizar en charts-<branch>/** ⬇️
- **Referencias de Helmfile a rutas locais** 📄
- **Copia de seguranza e Reversión con --revert** ↩️

---

# Importación de Usuarios: Provisión

- **UDM REST API** — Importación CSV/ODS, grupos LDAP 👤
- **Vinculación de Contas** — Vinculación de identidade SAML 🔗
- **Modo Demo** — Contas de proba, fotos de perfil 🖼️

---

# Importación de Usuarios: Desprovisión

**Fluxo de Traballo de Desprovisión en Dúas Fases:**

- **Fase 1: Deshabilitar Usuario**
  - IAM API → UCS Disable → Marca de tempo na Descrición
  - Keycloak: Eliminar SAML + disolver grupos
- **Fase 2: Eliminar Usuario**
  - Período de gracia (6 meses) → Eliminación permanente
  - Saída: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Visión Xeral

- **Extensión de openDesk CE** para universidades 🏫
- **Novos Componentes:**
  - Sistemas de Xestión da Aprendizaxe (ILIAS, Moodle)
  - Videoconferencia para a Ensinanza (BigBlueButton)
  - Sincronización de Ficheiros Alternativa (OpenCloud)
- **Todo integrado con Keycloak SSO** 🔐
- **Despregar todo con `helmfile apply`** ⚡

**GitHub:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)

---

# 📚 Componentes Educativos

| Componente | Estado | Descrición |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Estábel | LMS con SSO SAML — Cursos, SCORM, Exames |
| 📖 Moodle | 🔄 Beta | LMS con Shibboleth — Plugins, Caderno de cualificacións |
| 🎥 BigBlueButton | 🔄 Beta | Videoconferencia para a ensinanza — Gravación, Pizarra |
| ☁️ OpenCloud | 🔄 Beta | Sincronización de ficheiros baseada en CS3 — Alternativa a Nextcloud |

---

# 🔐 SSO de ILIAS — Arquitectura

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**Fluxo SSO en 6 Pasos:**

1. 🖥️ Portal → Mosaico de ILIAS
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Inicio de sesión (weblogin.uni-marburg.de)
5. 📨 Aserción SAML de volta
6. ✅ Panel de ILIAS

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.85em;">

# 🔧 Despregue de ILIAS — Leccións Aprendidas

| Problema | Solución |
|---------|---------|
| `Wrong Login or Password` | NameFormat SAML ausente en attribute-map.xml |
| Nomes de atributos incorrectos | Uni-IdP envía `givenname`/`surname` |
| `handlerSSL` → 404 | TLS interno: Apache SSL no porto 8443 (v5) |
| Contas deshabilitadas | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Comprobación de Estado | CronJob: curl SSO-Redirect (cada hora) |

---

# 🚀 Inicio Rápido - Despregar en 3 Pasos

```bash
# 1. Clonar o repositorio
git clone https://github.com/tobias-weiss-ai-xr/opendesk-edu.git
cd opendesk-edu

# 2. Configura o teu entorno
# Edita helmfile/environments/default/global.yaml.gotmpl
# Establece o teu dominio, dominio de correo e rexistro de imaxes

# 3. Despregar
helmfile -e default apply
```

📖 Documentación completa: [docs/getting-started.md](https://github.com/tobias-weiss-ai-xr/opendesk-edu/blob/main/docs/getting-started.md)

---

# Configuración de Rede

- **Ingress Controller:** haproxy-ingress
- **Proxy Inverso:** Traefik — Finalización HTTP/HTTPS 🔄
- **LoadBalancer:** MetalLB
- **Todos os Ingress migrados a haproxy** ✅

---

# Panel de Grafana

![height:500px](media/grafana.png)

---

# Proceso de Actualización

```bash
# Cargar as últimas versións
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Revisar cambios
helmfile diff -e hrz

# Aplicar actualizacións
helmfile apply -e hrz

# Reverter se necesario
helmfile rollback -e hrz
```

- **Actualizacións controladas mediante Helmfile** 🔄
- **Capacidade de reversión sinxela** ↩️

---

# Actualización HRZ: Migración de Ingress

- **Migración:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (rama uniapps)
  - Todos os Ingress migrados a haproxy ✅
- **Clases de Ingress:**
  - `ingressClassName: haproxy`
  - nginx completamente deprecado
- **Configuración:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# Actualización HRZ: Copia de Seguranza Dual

- **Obxectivos:** Almacenamento de Copia de Seguranza Redundante 🗄️
- **Estratexia:** Compatible con S3 con backend restic 🔄
  - Primario: `s3.example.org:9000/backup-primary`
  - Secundario: `s3-backup.example.org:9000/backup-secondary`
- **Programación:** Diariamente ás 00:42, Revisión semanal, Limpieza os domingos ⏰
- **Retención:** 14 Diarios, Manter os últimos 5 📦

---

# Obstáculos Institucionais

- **Departamento Xurídico** ⚖️
  - RGPD, contratos AVV, Cumprimento de licenzas
- **Consello de Persoal** 👥
  - Acordo de servizo, Co-determinación para sistemas TI
- **Administración** 🏢
  - Preferencias por Microsoft, Compatibilidade de formatos
- **Documentos Requiridos** 📄
  - DSFA, Cálculo de TCO

---

# Próximos Pasos e Recomendacións

1. Iniciar a operación piloto ▶️
2. Despregue escalonado (10 → 100 → 1000 usuarios) 👥
3. Separación clara dos sistemas de produción 🔗
4. Avaliación: Categorizar os casos de uso segundo os requisitos de soberanía ✅
5. Orzamento para o equipo de operacións (non só a implementación) 💰

---

# 🤝 Participa!

**Axúdanos a construír openDesk Edu para as universidades!**

- ⭐ **Dálle unha estrela ao repositorio:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)
- 🧪 **Proba localmente:** Desprega con Helmfile e proporciona retroalimentación
- 🐛 **Informa de problemas:** Issues para erros ou solicitudes de funcionalidades
- 💻 **Contribúe:** PRs benvidos — consulta CONTRIBUTING.md

**Construímos software universitario soberano xuntos!** 🎓

---

# Recursos Técnicos

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Guía de Despregue](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [Importación de Usuarios](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu) · Extensión educativa para universidades
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Automatización de Clústeres:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Recursos Organizativos

- **Recomendación HBDI (Avaliación M365):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Soberanía Dixital nas Universidades:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)
